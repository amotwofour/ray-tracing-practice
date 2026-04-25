#include "render.cuh"

__device__ Vec3 ray_color(
    Ray ray,
    const Sphere* spheres,
    int sphere_count,
    const Material* materials,
    int max_depth,
    curandStatePhilox4_32_10_t* rng
) {
    Vec3 throughput(1.0f, 1.0f, 1.0f);

    for (int depth = 0; depth < max_depth; ++depth) {
        HitRecord rec;
        if (world_hit(spheres, sphere_count, ray, 0.001f, 1e30f, rec)) {
            const Material& mat = materials[rec.material_idx];
            Ray scattered;
            Vec3 attenuation;
            if (!scatter(mat, ray, rec, rng, attenuation, scattered)) {
                return Vec3(0.0f, 0.0f, 0.0f);
            }
            throughput = throughput * attenuation;
            ray = scattered;
            continue;
        }

        const Vec3 unit_dir = unit_vector(ray.direction);
        const float a = 0.5f * (unit_dir.y + 1.0f);
        const Vec3 sky = (1.0f - a) * Vec3(1.0f, 1.0f, 1.0f) + a * Vec3(0.5f, 0.7f, 1.0f);
        return throughput * sky;
    }

    return Vec3(0.0f, 0.0f, 0.0f);
}

__global__ void init_rng(curandStatePhilox4_32_10_t* states, int width, int height, uint64_t seed) {
    const int x = blockIdx.x * blockDim.x + threadIdx.x;
    const int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= width || y >= height) {
        return;
    }

    const int idx = y * width + x;
    curand_init(seed, idx, 0, &states[idx]);
}

__global__ void render_kernel(
    uint8_t* image,
    int width,
    int height,
    int samples_per_pixel,
    int max_depth,
    Camera cam,
    const Sphere* spheres,
    int sphere_count,
    const Material* materials,
    curandStatePhilox4_32_10_t* rng_states
) {
    const int x = blockIdx.x * blockDim.x + threadIdx.x;
    const int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= width || y >= height) {
        return;
    }

    const int idx = y * width + x;
    curandStatePhilox4_32_10_t local_rng = rng_states[idx];

    Vec3 color_sum(0.0f, 0.0f, 0.0f);
    for (int s = 0; s < samples_per_pixel; ++s) {
        const float u = (static_cast<float>(x) + random_float(&local_rng)) / static_cast<float>(width - 1);
        const float v = (static_cast<float>(y) + random_float(&local_rng)) / static_cast<float>(height - 1);

        const Ray r = camera_get_ray(cam, u, v, &local_rng);
        color_sum += ray_color(r, spheres, sphere_count, materials, max_depth, &local_rng);
    }

    rng_states[idx] = local_rng;

    const float scale = 1.0f / static_cast<float>(samples_per_pixel);
    float r = sqrtf(fmaxf(0.0f, color_sum.x * scale));
    float g = sqrtf(fmaxf(0.0f, color_sum.y * scale));
    float b = sqrtf(fmaxf(0.0f, color_sum.z * scale));

    r = fminf(r, 0.999f);
    g = fminf(g, 0.999f);
    b = fminf(b, 0.999f);

    const int out_idx = idx * 3;
    image[out_idx + 0] = static_cast<uint8_t>(256.0f * r);
    image[out_idx + 1] = static_cast<uint8_t>(256.0f * g);
    image[out_idx + 2] = static_cast<uint8_t>(256.0f * b);
}
