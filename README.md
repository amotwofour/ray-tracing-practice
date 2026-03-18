# Ray Tracing Practice

Simple C++ ray tracing practice project to help me practice. Following the Ray Tracing in One Weekend book.

## Project Structure

- `src/main.cpp`: program entry point
- `include/`: header files (`vec3.h`, `color.h`, `ray.h`)
- `CMakeLists.txt`: CMake build configuration

## Build And Run (CMake)

From the project root:

```bash
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

## Notes

- On Linux, the executable is `ray_tracing` (not `.exe`).
- Render output is written to `image.ppm`.
