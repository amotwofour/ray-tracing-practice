#ifndef RTWEEKEND_H
#define RTWEEKEND_H

#include <cmath>
#include <limits>
#include <memory>
#include <iostream>

using std::make_shared;
using std::shared_ptr;

// const values

const double infinity = std::numeric_limits<double>::infinity();
const double pi = 3.1415926535897932385;

// util(s)

inline double deg_to_rad(double deg) {
    return deg * pi / 180.0;
}

// common headers

#include "ray.h"
#include "vec3.h"
#include "color.h"
#include "interval.h";

#endif