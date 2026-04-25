#pragma once

#include "random_utils.cuh"
#include "ray.cuh"

struct Camera {
    Vec3 origin;
    Vec3 lower_left_corner;
    Vec3 horizontal;
    Vec3 vertical;
    Vec3 u;
    Vec3 v;
    float lens_radius;
};

__host__ inline Camera make_camera(int image_width, int image_height) {
    const float aspect_ratio = static_cast<float>(image_width) / static_cast<float>(image_height);
    const float vfov = 20.0f;
    const float theta = vfov * 3.1415926535897932385f / 180.0f;
    const float h = tanf(theta * 0.5f);

    const Vec3 lookfrom(13.0f, 2.0f, 3.0f);
    const Vec3 lookat(0.0f, 0.0f, 0.0f);
    const Vec3 vup(0.0f, 1.0f, 0.0f);

    const float focus_dist = 10.0f;
    const float defocus_angle = 0.6f;

    const float viewport_height = 2.0f * h * focus_dist;
    const float viewport_width = viewport_height * aspect_ratio;

    const Vec3 w = unit_vector(lookfrom - lookat);
    const Vec3 u = unit_vector(cross(vup, w));
    const Vec3 v = cross(w, u);

    const Vec3 horizontal = viewport_width * u;
    const Vec3 vertical = viewport_height * (-v);
    const Vec3 lower_left_corner = lookfrom - focus_dist * w - horizontal * 0.5f - vertical * 0.5f;

    const float defocus_radius = focus_dist * tanf((defocus_angle * 3.1415926535897932385f / 180.0f) * 0.5f);

    Camera cam{};
    cam.origin = lookfrom;
    cam.lower_left_corner = lower_left_corner;
    cam.horizontal = horizontal;
    cam.vertical = vertical;
    cam.u = u;
    cam.v = v;
    cam.lens_radius = defocus_radius;
    return cam;
}

__device__ inline Ray camera_get_ray(
    const Camera& cam,
    float s,
    float t,
    curandStatePhilox4_32_10_t* rng
) {
    const Vec3 disk_sample = random_in_unit_disk(rng);
    const Vec3 offset = (disk_sample.x * cam.lens_radius) * cam.u + (disk_sample.y * cam.lens_radius) * cam.v;
    const Vec3 origin = cam.origin + offset;
    const Vec3 direction = cam.lower_left_corner + s * cam.horizontal + t * cam.vertical - origin;
    return Ray(origin, direction);
}
