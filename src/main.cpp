#include "color.h"
#include "vec3.h"

#include <iostream>

int main() {

    // define image width and height
    auto aspect_ratio = 16.0 / 9.0;
    int img_width = 400;

    int img_height = int(img_width / aspect_ratio);
    img_height = (img_height < 1) ? 1 : img_height;

    // a viewport width less than 1 is ok since it's a real value
    auto viewport_height = 2.0;
    auto viewport_width = viewport_height * (double(img_width) / img_height);

    // render the image
    std::cout << "P3\n" << img_width << ' ' << img_height << "\n255\n";

    for (int j = 0; j < img_height; j++) {
        std::clog << "\rScanlines remaining: " << (img_height - j) << std::flush;
        for (int i = 0; i < img_width; i++) {
            auto pixel_color = color(double(i) / (img_width - 1), double(j) / (img_height - 1), 0);
            write_color(std::cout, pixel_color);
        }
    }
    std::clog << "\nDone.\n";
}