# Ray Tracing Practice

Simple C++ ray tracing practice project to help me practice. Following the Ray Tracing in One Weekend book.

## Build and Run CPU Version(CMake):

```bash
cd cpu-version
cmake -S . -B build
cmake --build build
./build/ray_tracing > image.ppm
```

## Build And Run (Direct g++)

From the project root:

```bash
g++ -std=c++17 src/main.cpp -Iinclude -o ray_tracing
./ray_tracing > image.ppm
```

## Build and Run CUDA C++ Version(also CMake):

```bash
cd cuda-version
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

## Run

```bash
./build/cuda_ray_tracer
```

Optional args:

```bash
./build/cuda_ray_tracer [width] [samples_per_pixel] [max_depth] [output_file]
```

Example:

```bash
./build/cuda_ray_tracer 1200 256 32 image_cuda.ppm
```

## Notes

- On Linux, the executable is `ray_tracing` (not `.exe`).
- Render output is written to `image.ppm`.
