#pragma once

#include <cstdint>

#include <curand_kernel.h>

#include "camera.cuh"
#include "scene.cuh"

__global__ void init_rng(curandStatePhilox4_32_10_t* states, int width, int height, uint64_t seed);

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
);
