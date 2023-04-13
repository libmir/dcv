/*
Copyright (c) 2021- Ferhat Kurtulmuş
Boost Software License - Version 1.0 - August 17th, 2003
*/

module dcv.measure.ellipse;

import dcv.measure.moments;

import std.math;

struct Ellipse {
    double angle;
    double center_x; // locally computed with ellipseFit. One may need to add BoundingBox.x for global coord
    double center_y; // locally computed with ellipseFit. One may need to add BoundingBox.y for glıbal coord
    double major;
    double minor;
}

/** fit an ellipse to a binary region. Useful for determining the orientation

Params:
    moments = raw moments  

Returns struct Ellipse
*/
Ellipse ellipseFit(M)(auto ref M moments) @nogc nothrow
{
    import std.math.traits : isNaN;
    const double center_x = moments.m10/moments.m00;
    const double center_y = moments.m01/moments.m00;
    
    // central moments
    const double a = moments.m20/moments.m00 - center_x*center_x + 1.0/12.0;
    const double b = 2*(moments.m11/moments.m00 - center_x*center_y);
    const double c = moments.m02/moments.m00 - center_y*center_y + 1.0/12.0;

    assert(!a.isNaN, "a is nan. There should be problem with the value of moments.m00 (area)");
    assert(!b.isNaN, "b is nan. There should be problem with the value of moments.m00 (area)");
    assert(!c.isNaN, "c is nan. There should be problem with the value of moments.m00 (area)");

    const double theta = 0.5*atan(b/(a-c)) + (a<c)*PI/2;

    const double axis1 = sqrt(8*(a+c-sqrt(b*b+(a-c)*(a-c))))/2.0;
    const double axis2 = sqrt(8*(a+c+sqrt(b*b+(a-c)*(a-c))))/2.0;

    double orientation;
    if (axis1 == axis2)
        orientation = 0;
    else
    {
        orientation = -theta;
        if (abs(orientation) > PI_2)
            orientation = PI - abs(orientation);
    }
    
    return Ellipse(orientation, center_x + 1, center_y + 1, 2*axis2, 2*axis1);
}