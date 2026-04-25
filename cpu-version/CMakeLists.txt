cmake_minimum_required(VERSION 3.10)
project(RayTracingPractice)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

add_executable(ray_tracing src/main.cpp)

target_include_directories(ray_tracing PRIVATE include)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
	target_compile_options(ray_tracing PRIVATE -O3 -march=native -flto)
	target_link_options(ray_tracing PRIVATE -flto)
endif()