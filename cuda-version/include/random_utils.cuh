#pragma once

#include <curand_kernel.h>

#include "vec3.cuh"

__device__ inline float random_float(curandStatePhilox4_32_10_t* state) {
    return curand_uniform(state);
}

__device__ inline Vec3 random_in_unit_sphere(curandStatePhilox4_32_10_t* state) {
    while (true) {
        const Vec3 p(
            2.0f * random_float(state) - 1.0f,
            2.0f * random_float(state) - 1.0f,
            2.0f * random_float(state) - 1.0f
        );
        if (length_squared(p) < 1.0f) {
            return p;
        }
    }
}

__device__ inline Vec3 random_unit_vector(curandStatePhilox4_32_10_t* state) {
    return unit_vector(random_in_unit_sphere(state));
}

__device__ inline Vec3 random_in_unit_disk(curandStatePhilox4_32_10_t* state) {
    while (true) {
        const Vec3 p(
            2.0f * random_float(state) - 1.0f,
            2.0f * random_float(state) - 1.0f,
            0.0f
        );
        if (dot(p, p) < 1.0f) {
            return p;
        }
    }
}
