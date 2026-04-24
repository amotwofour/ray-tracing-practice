#ifndef COLOR_H
#define COLOR_H

#include "interval.h"
#include "vec3.h"

// define color as an alias for vec3, 
// aka a 3D vector to represent RGB color values
using color = vec3;

inline double linear_to_gamma(double lin_component) {
    if (lin_component > 0)
        return std::sqrt(lin_component);

    return 0;
}

void write_color(std::ostream &out, color pixel_color) {
    auto r = pixel_color.x();
    auto g = pixel_color.y();
    auto b = pixel_color.z();

    // linear to gamma transform for gamma 2
    r = linear_to_gamma(r);
    g = linear_to_gamma(g);
    b = linear_to_gamma(b);

    // tranlate [0,1] range to [0,255] range
    static const interval intensity(0.000, 0.999);
    int ir = int(256 * intensity.clamp(r));
    int ig = int(256 * intensity.clamp(g));
    int ib = int(256 * intensity.clamp(b));

    out << ir << ' ' << ig << ' ' << ib << '\n';
}

#endif