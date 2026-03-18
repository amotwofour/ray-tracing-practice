#ifndef COLOR_H
#define COLOR_H

#include "vec3.h"

#include <iostream>

// define color as an alias for vec3, 
// aka a 3D vector to represent RGB color values
using color = vec3;

void write_color(std::ostream &out, color pixel_color) {
    auto r = pixel_color.x();
    auto g = pixel_color.y();
    auto b = pixel_color.z();

    // tranlate [0,1] range to [0,255] range
    int ir = int(255.999 * r);
    int ig = int(255.999 * g);
    int ib = int(255.999 * b);

    out << ir << ' ' << ig << ' ' << ib << '\n';
}

#endif