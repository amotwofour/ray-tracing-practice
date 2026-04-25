#ifndef CAMERA_H
#define CAMERA_H

#include "hittable.h"
#include "material.h"
#include "rtweekend.h"

#include <atomic>
#include <sstream>
#include <thread>
#include <vector>

class camera {
    public:
        double aspect_ratio = 1.0;
        int img_width = 100;
        int samples_per_pixel = 10;
        int max_depth = 10;

        double vfov = 90;
        point3 lookfrom = point3(0, 0, 0);
        point3 lookat = point3(0, 0, -1);
        vec3 vup = vec3(0, 1, 0);

        double defocus_angle = 0;
        double focus_dist = 10;

        void render(const hittable& world) {
        init();

        const unsigned int hw_threads = std::thread::hardware_concurrency();
        const unsigned int worker_count = hw_threads == 0 ? 4 : hw_threads;

        std::vector<std::string> row_data(image_height);
        std::atomic<int> next_row(0);
        std::atomic<int> finished_rows(0);

        std::vector<std::thread> workers;
        workers.reserve(worker_count);

        for (unsigned int t = 0; t < worker_count; ++t) {
            workers.emplace_back([&]() {
                while (true) {
                    const int j = next_row.fetch_add(1);
                    if (j >= image_height) {
                        break;
                    }

                    std::ostringstream row_stream;
                    for (int i = 0; i < img_width; i++) {
                        color pixel_color(0,0,0);
                        for (int sample = 0; sample < samples_per_pixel; sample++) {
                            ray r = get_ray(i, j);
                            pixel_color += ray_color(r, max_depth, world);
                        }
                        write_color(row_stream, pixel_samples_scale * pixel_color);
                    }

                    row_data[j] = row_stream.str();
                    const int rows_done = finished_rows.fetch_add(1) + 1;
                    if (rows_done % 10 == 0 || rows_done == image_height) {
                        std::clog << "\rScanlines remaining: " << (image_height - rows_done) << ' ' << std::flush;
                    }
                }
            });
        }

        for (auto& worker : workers) {
            worker.join();
        }

        std::cout << "P3\n" << img_width << ' ' << image_height << "\n255\n";
        for (const auto& row : row_data) {
            std::cout << row;
        }

        std::clog << "\rDone.                 \n";
    }

private:
    int image_height;
    double pixel_samples_scale;
    point3 center;
    point3 pixel00_loc;
    vec3 pixel_delta_u;
    vec3 pixel_delta_v;
    vec3 u, v, w;
    vec3 defocus_disk_u;
    vec3 defocus_disk_v;

    void init()
    {
        image_height = int(img_width / aspect_ratio);
        image_height = (image_height < 1) ? 1 : image_height;

        pixel_samples_scale = 1.0 / samples_per_pixel;

        center = lookfrom;

        auto theta = deg_to_rad(vfov);
        auto h = std::tan(theta / 2);
        auto viewport_height = 2 * h * focus_dist;
        auto viewport_width = viewport_height * (double(img_width) / image_height);

        w = unit_vector(lookfrom - lookat);
        u = unit_vector(cross(vup, w));
        v = cross(w, u);

        vec3 viewport_u = viewport_width * u;
        vec3 viewport_v = viewport_height * -v;

        pixel_delta_u = viewport_u / img_width;
        pixel_delta_v = viewport_v / image_height;

        auto viewport_upper_left = center - (focus_dist * w) - viewport_u / 2 - viewport_v / 2;
        pixel00_loc = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v);

        auto defocus_radius = focus_dist * std::tan(deg_to_rad(defocus_angle / 2));
        defocus_disk_u = u * defocus_radius;
        defocus_disk_v = v * defocus_radius;
    }

    ray get_ray(int i, int j) const {
        // construct a camera ray originating from the defocus disk and directed at a randomly
        // sampled point around the pixel location i, j.
        auto offset = sample_square();
        auto pixel_sample = pixel00_loc 
                          + ((i + offset.x()) * pixel_delta_u) 
                          + ((j + offset.y()) * pixel_delta_v);

        auto ray_origin = (defocus_angle <= 0) ? center : defocus_disk_sample();
        auto ray_direction = pixel_sample - ray_origin;

        return ray(ray_origin, ray_direction);
    }

    vec3 sample_square() const {
        return vec3(random_double() - 0.5, random_double() - 0.5, 0);
    }

    point3 defocus_disk_sample() const {
        auto p = random_in_unit_disk();

        return center + (p[0] * defocus_disk_u) + (p[1] * defocus_disk_v);
    }

    color ray_color(const ray &r, int depth, const hittable& world) const
    {
        if (depth <= 0) {
            return color(0, 0, 0);
        }

        hit_record rec;

        if (world.hit(r, interval(0.001, infinity), rec)) {
            ray scattered;
            color attenuation;

            if (rec.mat->scatter(r, rec, attenuation, scattered))
                return attenuation * ray_color(scattered, depth - 1, world);
            
            return color(0, 0, 0);
        }

        vec3 unit_direction = unit_vector(r.direction());
        auto a = 0.5 * (unit_direction.y() + 1.0);
        return (1.0 - a) * color(1.0, 1.0, 1.0) + a * color(0.5, 0.7, 1.0);
    }
};

#endif