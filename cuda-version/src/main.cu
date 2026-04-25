#include <cuda_runtime.h>

#include <fstream>
#include <iostream>
#include <random>
#include <string>
#include <vector>

#include <curand_kernel.h>

#include "camera.cuh"
#include "render.cuh"
#include "scene.cuh"

static float host_random_float(std::mt19937& rng, float min, float max) {
    std::uniform_real_distribution<float> dist(min, max);
    return dist(rng);
}

static float host_random_float(std::mt19937& rng) {
    return host_random_float(rng, 0.0f, 1.0f);
}

static void build_random_scene(std::vector<Material>& materials, std::vector<Sphere>& spheres) {
    std::mt19937 rng(1337u);

    materials.clear();
    spheres.clear();
    materials.reserve(512);
    spheres.reserve(512);

    auto push_material = [&](const Material& mat) {
        materials.push_back(mat);
        return static_cast<int>(materials.size() - 1);
    };

    const int ground_mat = push_material(Material{MAT_LAMBERTIAN, Vec3(0.5f, 0.5f, 0.5f), 0.0f, 1.0f});
    spheres.push_back(Sphere{Vec3(0.0f, -1000.0f, 0.0f), 1000.0f, ground_mat});

    for (int a = -11; a < 11; ++a) {
        for (int b = -11; b < 11; ++b) {
            const float choose_mat = host_random_float(rng);
            const Vec3 center(
                static_cast<float>(a) + 0.9f * host_random_float(rng),
                0.2f,
                static_cast<float>(b) + 0.9f * host_random_float(rng)
            );

            if (length(center - Vec3(4.0f, 0.2f, 0.0f)) <= 0.9f) {
                continue;
            }

            int mat_idx = -1;
            if (choose_mat < 0.8f) {
                const Vec3 albedo = Vec3(
                    host_random_float(rng) * host_random_float(rng),
                    host_random_float(rng) * host_random_float(rng),
                    host_random_float(rng) * host_random_float(rng)
                );
                mat_idx = push_material(Material{MAT_LAMBERTIAN, albedo, 0.0f, 1.0f});
            } else if (choose_mat < 0.95f) {
                const Vec3 albedo(
                    host_random_float(rng, 0.5f, 1.0f),
                    host_random_float(rng, 0.5f, 1.0f),
                    host_random_float(rng, 0.5f, 1.0f)
                );
                const float fuzz = host_random_float(rng, 0.0f, 0.5f);
                mat_idx = push_material(Material{MAT_METAL, albedo, fuzz, 1.0f});
            } else {
                mat_idx = push_material(Material{MAT_DIELECTRIC, Vec3(1.0f, 1.0f, 1.0f), 0.0f, 1.5f});
            }

            spheres.push_back(Sphere{center, 0.2f, mat_idx});
        }
    }

    const int mat1 = push_material(Material{MAT_DIELECTRIC, Vec3(1.0f, 1.0f, 1.0f), 0.0f, 1.5f});
    const int mat2 = push_material(Material{MAT_LAMBERTIAN, Vec3(0.4f, 0.2f, 0.1f), 0.0f, 1.0f});
    const int mat3 = push_material(Material{MAT_METAL, Vec3(0.7f, 0.6f, 0.5f), 0.0f, 1.0f});

    spheres.push_back(Sphere{Vec3(0.0f, 1.0f, 0.0f), 1.0f, mat1});
    spheres.push_back(Sphere{Vec3(-4.0f, 1.0f, 0.0f), 1.0f, mat2});
    spheres.push_back(Sphere{Vec3(4.0f, 1.0f, 0.0f), 1.0f, mat3});
}

static bool parse_int(const char* text, int& out) {
    try {
        out = std::stoi(text);
        return true;
    } catch (...) {
        return false;
    }
}

int main(int argc, char** argv) {
    int image_width = 1200;
    int samples_per_pixel = 256;
    int max_depth = 32;
    std::string output_file = "image_cuda.ppm";

    if (argc >= 2 && !parse_int(argv[1], image_width)) {
        std::cerr << "Invalid width argument\n";
        return 1;
    }
    if (argc >= 3 && !parse_int(argv[2], samples_per_pixel)) {
        std::cerr << "Invalid samples_per_pixel argument\n";
        return 1;
    }
    if (argc >= 4 && !parse_int(argv[3], max_depth)) {
        std::cerr << "Invalid max_depth argument\n";
        return 1;
    }
    if (argc >= 5) {
        output_file = argv[4];
    }

    if (image_width < 64) {
        image_width = 64;
    }
    if (samples_per_pixel < 1) {
        samples_per_pixel = 1;
    }
    if (max_depth < 1) {
        max_depth = 1;
    }

    const float aspect_ratio = 16.0f / 9.0f;
    const int image_height = static_cast<int>(image_width / aspect_ratio);

    std::clog << "Rendering " << image_width << "x" << image_height
              << " spp=" << samples_per_pixel << " depth=" << max_depth << "\n";

    std::vector<Material> materials;
    std::vector<Sphere> spheres;
    build_random_scene(materials, spheres);

    Camera cam = make_camera(image_width, image_height);

    Sphere* d_spheres = nullptr;
    Material* d_materials = nullptr;
    uint8_t* d_image = nullptr;
    curandStatePhilox4_32_10_t* d_rng_states = nullptr;

    const size_t sphere_bytes = spheres.size() * sizeof(Sphere);
    const size_t material_bytes = materials.size() * sizeof(Material);
    const size_t image_bytes = static_cast<size_t>(image_width) * static_cast<size_t>(image_height) * 3u;
    const size_t rng_bytes = static_cast<size_t>(image_width) * static_cast<size_t>(image_height) * sizeof(curandStatePhilox4_32_10_t);

    cudaMalloc(&d_spheres, sphere_bytes);
    cudaMalloc(&d_materials, material_bytes);
    cudaMalloc(&d_image, image_bytes);
    cudaMalloc(&d_rng_states, rng_bytes);

    cudaMemcpy(d_spheres, spheres.data(), sphere_bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_materials, materials.data(), material_bytes, cudaMemcpyHostToDevice);

    const dim3 block(16, 16);
    const dim3 grid((image_width + block.x - 1) / block.x, (image_height + block.y - 1) / block.y);

    init_rng<<<grid, block>>>(d_rng_states, image_width, image_height, 1337ULL);
    cudaDeviceSynchronize();

    render_kernel<<<grid, block>>>(
        d_image,
        image_width,
        image_height,
        samples_per_pixel,
        max_depth,
        cam,
        d_spheres,
        static_cast<int>(spheres.size()),
        d_materials,
        d_rng_states
    );
    cudaDeviceSynchronize();

    std::vector<uint8_t> image(image_bytes);
    cudaMemcpy(image.data(), d_image, image_bytes, cudaMemcpyDeviceToHost);

    std::ofstream out(output_file, std::ios::binary);
    out << "P3\n" << image_width << ' ' << image_height << "\n255\n";

    for (int j = 0; j < image_height; ++j) {
        for (int i = 0; i < image_width; ++i) {
            const int idx = (j * image_width + i) * 3;
            out << static_cast<int>(image[idx + 0]) << ' '
                << static_cast<int>(image[idx + 1]) << ' '
                << static_cast<int>(image[idx + 2]) << '\n';
        }
    }

    out.close();

    cudaFree(d_rng_states);
    cudaFree(d_image);
    cudaFree(d_materials);
    cudaFree(d_spheres);

    std::clog << "Wrote " << output_file << "\n";
    return 0;
}
