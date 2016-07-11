/**
Module containts optical flow plotting functions.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.plot.opticalflow;

import std.experimental.ndslice;

/**
 * Draw color-coded optical flow.
 * 
 * params:
 * flow = Optical flow displacement vectors.
 * maxSize = Value which is considered to be the maximal
 * displacement value for color saturation. Default is 
 * 0, which gets reset in the algorithm to 10% of image 
 * diagonal length.
 * 
 * returns:
 * RGB image of color-coded optical flow.
 */
Slice!(3, ubyte*) colorCode(Slice!(3, float*) flow, float maxSize = 0)
{
    import std.math : sqrt;
    import std.array : array;
    import std.algorithm.iteration : map;

    import dcv.core.algorithm : ranged;
    import dcv.imgproc.color : hsv2rgb;

    if (maxSize == 0)
    {
        maxSize = (cast(float)(flow.length!0) ^^ 2 + cast(float)(flow.length!1) ^^ 2).sqrt;
        maxSize *= 0.1; // expect max flow displacement to be 10% of the diagonal
    }

    auto hsv = new float[flow.length!0 * flow.length!1 * 3].sliced(flow.length!0, flow.length!1, 3);

    foreach (r; 0 .. flow.length!0)
    {
        foreach (c; 0 .. flow.length!1)
        {
            import std.math : sqrt, atan2, PI;

            float fx = flow[r, c, 0];
            float fy = flow[r, c, 1];

            float rad = sqrt(fx * fx + fy * fy);
            float a = atan2(fy, fx) / PI;

            auto pix = hsv[r, c];
            pix[0] = a * 180.0f + 180.0f;
            pix[1] = rad;
            pix[2] = 1.0f;
        }
    }

    // Range saturation values
    auto rangedS = hsv[0 .. $, 0 .. $, 1].byElement.ranged(0.0f,
            maxSize) // range values from 0 to maxSize
    .map!(v => v / maxSize) // normalize values
    .array.sliced(hsv[0 .. $, 0 .. $, 0].shape);

    hsv[0 .. $, 0 .. $, 1][] = rangedS[];

    return hsv.hsv2rgb!ubyte;
}
