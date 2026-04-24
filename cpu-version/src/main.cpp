#include "rtweekend.h"
#include "hittable_list.h"
#include "sphere.h"

color ray_color(const ray& r, const hittable& world) {
    hit_record rec;
    if (world.hit(r, 0, infinity, rec)) {
        return 0.5 * (rec.normal + color(1,1,1));
    }

    vec3 unit_direction = unit_vector(r.direction());
    auto a = 0.5*(unit_direction.y() + 1.0);
    return (1.0-a)*color(1.0, 1.0, 1.0) + a*color(0.5, 0.7, 1.0);
}

int main() {

    // define image width and height
    auto aspect_ratio = 16.0 / 9.0;
    int img_width = 400;

    int img_height = int(img_width / aspect_ratio);
    img_height = (img_height < 1) ? 1 : img_height;

    // world

    hittable_list world;
    world.add(make_shared<sphere>(point3(0, 0, -1), 0.5));
    world.add(make_shared<sphere>(point3(0, -100.5, -1), 100));

    // a viewport width less than 1 is ok since it's a real value
    auto focal_length = 1.0;
    auto viewport_height = 2.0;
    auto viewport_width = viewport_height * (double(img_width) / img_height);
    auto camera_center = point3(0, 0, 0);

    // calc vectors across horizontal and down vertical viewport
    auto viewport_u = vec3(viewport_width, 0, 0);
    auto viewport_v = vec3(0, -viewport_height, 0);

    // calc horizontal and vertical delta vectors
    auto pixel_del_u = viewport_u / img_width;
    auto pixel_del_v = viewport_v / img_height;

    // calc location upper left pixel
    auto viewport_upper_left = camera_center - vec3(0, 0, focal_length) - viewport_u/2 - viewport_v/2;
    auto pixel00_loc = viewport_upper_left + 0.5 * (pixel_del_u + pixel_del_v);

    // render the image
    std::cout << "P3\n" << img_width << ' ' << img_height << "\n255\n";

    for (int j = 0; j < img_height; j++) {
        std::clog << "\rScanlines remaining: " << (img_height - j) << std::flush;
        for (int i = 0; i < img_width; i++) {
            auto pixel_center = pixel00_loc + (i * pixel_del_u) + (j * pixel_del_v);
            auto ray_direction = pixel_center - camera_center;
            ray r(camera_center, ray_direction);
            
            color pixel_color = ray_color(r, world);
            write_color(std::cout, pixel_color);
        }
    }
    std::clog << "\nDone.\n";
}