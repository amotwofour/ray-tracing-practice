cmake_minimum_required(VERSION 3.10)
project(RayTracingPractice)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(ray_tracing src/main.cpp)

target_include_directories(ray_tracing PRIVATE include)