#pragma once

#include "random_utils.cuh"
#include "ray.cuh"

enum MaterialType : int {
    MAT_LAMBERTIAN = 0,
    MAT_METAL = 1,
    MAT_DIELECTRIC = 2
};

struct Material {
    int type;
    Vec3 albedo;
    float fuzz;
    float refraction_index;
};

struct Sphere {
    Vec3 center;
    float radius;
    int material_idx;
};

struct HitRecord {
    Vec3 p;
    Vec3 normal;
    float t;
    bool front_face;
    int material_idx;
};

__device__ inline void set_face_normal(HitRecord& rec, const Ray& ray, const Vec3& outward_normal) {
    rec.front_face = dot(ray.direction, outward_normal) < 0.0f;
    rec.normal = rec.front_face ? outward_normal : -outward_normal;
}

__device__ inline bool hit_sphere(const Sphere& sphere, const Ray& ray, float t_min, float t_max, HitRecord& rec) {
    const Vec3 oc = sphere.center - ray.origin;
    const float a = length_squared(ray.direction);
    const float h = dot(ray.direction, oc);
    const float c = length_squared(oc) - sphere.radius * sphere.radius;
    const float discriminant = h * h - a * c;

    if (discriminant < 0.0f) {
        return false;
    }

    const float sqrtd = sqrtf(discriminant);

    float root = (h - sqrtd) / a;
    if (root <= t_min || root >= t_max) {
        root = (h + sqrtd) / a;
        if (root <= t_min || root >= t_max) {
            return false;
        }
    }

    rec.t = root;
    rec.p = ray.at(rec.t);
    const Vec3 outward_normal = (rec.p - sphere.center) / sphere.radius;
    set_face_normal(rec, ray, outward_normal);
    rec.material_idx = sphere.material_idx;
    return true;
}

__device__ inline bool world_hit(
    const Sphere* spheres,
    int sphere_count,
    const Ray& ray,
    float t_min,
    float t_max,
    HitRecord& rec
) {
    HitRecord temp;
    bool hit_anything = false;
    float closest = t_max;

    for (int i = 0; i < sphere_count; ++i) {
        if (hit_sphere(spheres[i], ray, t_min, closest, temp)) {
            hit_anything = true;
            closest = temp.t;
            rec = temp;
        }
    }

    return hit_anything;
}

__device__ inline float schlick_reflectance(float cosine, float ref_idx) {
    float r0 = (1.0f - ref_idx) / (1.0f + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0f - r0) * powf(1.0f - cosine, 5.0f);
}

__device__ inline bool scatter(
    const Material& mat,
    const Ray& ray_in,
    const HitRecord& rec,
    curandStatePhilox4_32_10_t* rng,
    Vec3& attenuation,
    Ray& scattered
) {
    if (mat.type == MAT_LAMBERTIAN) {
        Vec3 scatter_direction = rec.normal + random_unit_vector(rng);
        if (length_squared(scatter_direction) < 1e-8f) {
            scatter_direction = rec.normal;
        }
        scattered = Ray(rec.p, scatter_direction);
        attenuation = mat.albedo;
        return true;
    }

    if (mat.type == MAT_METAL) {
        const Vec3 reflected = reflect(unit_vector(ray_in.direction), rec.normal);
        scattered = Ray(rec.p, reflected + mat.fuzz * random_unit_vector(rng));
        attenuation = mat.albedo;
        return dot(scattered.direction, rec.normal) > 0.0f;
    }

    attenuation = Vec3(1.0f, 1.0f, 1.0f);
    const float ri = rec.front_face ? (1.0f / mat.refraction_index) : mat.refraction_index;

    const Vec3 unit_dir = unit_vector(ray_in.direction);
    const float cos_theta = fminf(dot(-unit_dir, rec.normal), 1.0f);
    const float sin_theta = sqrtf(1.0f - cos_theta * cos_theta);

    const bool cannot_refract = ri * sin_theta > 1.0f;
    Vec3 direction;

    if (cannot_refract || schlick_reflectance(cos_theta, ri) > random_float(rng)) {
        direction = reflect(unit_dir, rec.normal);
    } else {
        direction = refract(unit_dir, rec.normal, ri);
    }

    scattered = Ray(rec.p, direction);
    return true;
}
