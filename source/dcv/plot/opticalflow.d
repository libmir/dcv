/**
   Module containts optical flow plotting functions.

   Copyright: Copyright Relja Ljubobratovic 2016.

   Authors: Relja Ljubobratovic

   License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
 */

module dcv.plot.opticalflow;

import dcv.core.types:RGB8, HSV;

import mir.ndslice.slice:Slice, sliced, SliceKind, Contiguous;
import mir.ndslice.algorithm;
import mir.ndslice.topology: as;

/**
   Draw color-coded optical flow.

   Params:
      flow = Optical flow displacement vectors.
      maxSize = Value which is considered to be the maximal
      displacement value for color saturation. Default is
      0, which gets reset in the algorithm to 10% of image
      diagonal length.

   Returns:
      RGB image of color-coded optical flow.
 */
auto colorCode(Slice!(Contiguous, [3], float*) flow, float maxSize = 0)
{
    import std.math:sqrt;
    import std.array:array;

    import dcv.core.algorithm:ranged;

    if (maxSize == 0)
    {
        maxSize  = (cast(float)(flow.length !0) ^^ 2 + cast(float)(flow.length !1) ^^ 2).sqrt;
        maxSize *= 0.1; // expect max flow displacement to be 10% of the diagonal
    }

    auto hsv = new HSV!float[flow.length !0 * flow.length !1].sliced(flow.length !0, flow.length !1);

    foreach (r; 0 .. flow.length !0)
    {
        foreach (c; 0 .. flow.length !1)
        {
            import std.math:sqrt, atan2, PI;

            float fx = flow[r, c, 0];
            float fy = flow[r, c, 1];

            float rad = sqrt(fx * fx + fy * fy);
            float a   = atan2(fy, fx) / PI;

            hsv[r, c].degrees = a * 180.0f + 180.0f;
            hsv[r, c].s       = rad;
            hsv[r, c].v       = 1.0f;
        }
    }

    return hsv.as!RGB8;
}

