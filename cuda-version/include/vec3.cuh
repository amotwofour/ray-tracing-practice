#pragma once

#include <cmath>

struct Vec3 {
    float x;
    float y;
    float z;

    __host__ __device__ Vec3() : x(0.0f), y(0.0f), z(0.0f) {}
    __host__ __device__ Vec3(float x_, float y_, float z_) : x(x_), y(y_), z(z_) {}

    __host__ __device__ Vec3 operator-() const { return Vec3(-x, -y, -z); }
    __host__ __device__ Vec3& operator+=(const Vec3& v) {
        x += v.x;
        y += v.y;
        z += v.z;
        return *this;
    }
    __host__ __device__ Vec3& operator*=(float t) {
        x *= t;
        y *= t;
        z *= t;
        return *this;
    }
    __host__ __device__ Vec3& operator/=(float t) {
        const float inv = 1.0f / t;
        x *= inv;
        y *= inv;
        z *= inv;
        return *this;
    }
};

__host__ __device__ inline Vec3 operator+(const Vec3& a, const Vec3& b) { return Vec3(a.x + b.x, a.y + b.y, a.z + b.z); }
__host__ __device__ inline Vec3 operator-(const Vec3& a, const Vec3& b) { return Vec3(a.x - b.x, a.y - b.y, a.z - b.z); }
__host__ __device__ inline Vec3 operator*(const Vec3& a, const Vec3& b) { return Vec3(a.x * b.x, a.y * b.y, a.z * b.z); }
__host__ __device__ inline Vec3 operator*(float t, const Vec3& v) { return Vec3(t * v.x, t * v.y, t * v.z); }
__host__ __device__ inline Vec3 operator*(const Vec3& v, float t) { return t * v; }
__host__ __device__ inline Vec3 operator/(const Vec3& v, float t) { return (1.0f / t) * v; }

__host__ __device__ inline float dot(const Vec3& a, const Vec3& b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
__host__ __device__ inline Vec3 cross(const Vec3& a, const Vec3& b) {
    return Vec3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    );
}

__host__ __device__ inline float length_squared(const Vec3& v) { return dot(v, v); }
__host__ __device__ inline float length(const Vec3& v) { return sqrtf(length_squared(v)); }
__host__ __device__ inline Vec3 unit_vector(const Vec3& v) { return v / length(v); }

__host__ __device__ inline Vec3 reflect(const Vec3& v, const Vec3& n) {
    return v - 2.0f * dot(v, n) * n;
}

__host__ __device__ inline Vec3 refract(const Vec3& uv, const Vec3& n, float etai_over_etat) {
    const float cos_theta = fminf(dot(-uv, n), 1.0f);
    const Vec3 r_out_perp = etai_over_etat * (uv + cos_theta * n);
    const Vec3 r_out_parallel = -sqrtf(fabsf(1.0f - length_squared(r_out_perp))) * n;
    return r_out_perp + r_out_parallel;
}
