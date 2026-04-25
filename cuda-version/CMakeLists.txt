cmake_minimum_required(VERSION 3.18)
project(CudaRayTracer LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES native)
endif()

add_executable(cuda_ray_tracer
    src/main.cu
    src/render.cu
)

target_include_directories(cuda_ray_tracer PRIVATE include)

set_target_properties(cuda_ray_tracer PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
)

target_compile_options(cuda_ray_tracer PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:--use_fast_math>
)
