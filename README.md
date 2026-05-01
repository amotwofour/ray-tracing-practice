# Ray Tracing Practice

Simple C++ ray tracing practice project to help me practice. Following the Ray Tracing in One Weekend book.

## Build and Run CPU Version(CMake):

```bash
cd cpu-version
cmake -S . -B build # build like this if building for first time
cmake --build build
./build/ray_tracing > image.ppm
```

## Build And Run (Direct g++)

From the cpu-version directory:

```bash
g++ -std=c++17 src/main.cpp -Iinclude -o ray_tracing
./ray_tracing > image.ppm
```

## Build and Run GPU Version(cargo):

```bash
cd gpu-version
cargo build
cargo run
```

## Notes

- On Linux, the executable is `ray_tracing` (not `.exe`).
- Render output for cpu version is written to `image.ppm`. You can try using the python renderer in this repo or just upload the ppm to a ppm viewer online.
