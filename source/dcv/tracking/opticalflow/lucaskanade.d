module dcv.tracking.opticalflow.lucaskanade;

import std.math : PI, floor;

import dcv.core.image;
import dcv.imgproc.convolution;

import dcv.tracking.opticalflow.base;

public import dcv.imgproc.interpolate;

class LucasKanadeFlow : SparseOpticalFlow {

    public {
        float sigma = 0.84f;
        float[] cornerResponse;
        ulong iterationCount = 10;
    }

    /**
     * Lucas-Kanade optical flow algorithm implementation.
     * 
     * see:
     * dcv.features.corner
     * 
     * params:
     * f1 = First frame image.
     * f2 = Second frame image.
     * points = points which are tracked.
     * searchRegions = search region width and height for each point.
     * flow = displacement values preallocated array.
     * usePrevious = if algorithm should continue iterating by 
     * using presented values in the flow array, set this to true.
     */
    override float[2][] evaluate(inout Image f1, inout Image f2,
            in float[2][] points, in float[2][] searchRegions,
            float[2][] flow = null, bool usePrevious = false)
    in {
        assert(!f1.empty && !f2.empty && f1.size == f2.size && f1.channels == 1
                && f1.depth == f2.depth && f1.depth == BitDepth.BD_8);
        assert(points.length == searchRegions.length);
        if (usePrevious) {
            assert(flow !is null);
            assert(points.length == flow.length);
        }
    }
    body {
        import dcv.core.algorithm : ranged, ranged;
        import dcv.imgproc.interpolate : linear;
        import dcv.imgproc.filter;
        import dcv.core.utils : asType;

        import std.array : uninitializedArray;
        import std.range : lockstep;
        import std.array : array;
        import std.algorithm.iteration : map;

        const auto rows = f1.height;
        const auto cols = f1.width;
        const auto rl = cast(int)(rows - 1);
        const auto cl = cast(int)(cols - 1);
        const auto pointCount = points.length;

        if (!usePrevious) {
            flow = uninitializedArray!(float[2][])(pointCount);
            flow[] = [0.0f, 0.0f];
        }

        auto current = f1.sliced.reshape(f1.height, f1.width);
        auto next = f2.sliced.reshape(f2.height, f2.width);
        float gaussMul = 1.0f / (2.0f * PI * sigma);
        float gaussDel = 2.0f * (sigma ^^ 2);

        auto f1s = f1.asType!float.sliced!float.reshape(f1.height, f1.width);
        auto f2s = f2.asType!float.sliced!float.reshape(f1.height, f1.width);

        // TODO: implement masks
        auto fxs = f1s.conv(sobel!float(GradientDirection.DIR_X));
        auto fys = f1s.conv(sobel!float(GradientDirection.DIR_Y));

        cornerResponse.length = pointCount;

        foreach (ref f, ref resp, p, r; lockstep(flow, cornerResponse, points, searchRegions)) {
            import std.math : sqrt, exp;

            auto rb = cast(int)(p[0] - r[0] / 2.0f);
            auto re = cast(int)(p[0] + r[0] / 2.0f);
            auto cb = cast(int)(p[1] - r[1] / 2.0f);
            auto ce = cast(int)(p[1] + r[1] / 2.0f);

            rb = rb < 1 ? 1 : rb;
            re = re > rl ? rl : re;
            cb = cb < 1 ? 1 : cb;
            ce = ce > cl ? cl : ce;

            if (re - rb <= 0 || ce - cb <= 0) {
                continue;
            }

            float a1, a2, a3;
            float b1, b2;

            a1 = 0.0f;
            a2 = 0.0f;
            a3 = 0.0f;
            b1 = 0.0f;
            b2 = 0.0f;

            const auto rm = floor(cast(float) re - (r[0] / 2.0f));
            const auto cm = floor(cast(float) ce - (r[1] / 2.0f));

            foreach (iteration; 0 .. iterationCount) {
                foreach (i; rb .. re) {
                    foreach (j; cb .. ce) {

                        const float nx = cast(float) j + f[0];
                        const float ny = cast(float) i + f[1];

                        if (nx < 0.0f || nx > cast(float) ce || ny < 0.0f || ny > cast(float) re) {
                            continue;
                        }

                        // TODO: gaussian weighting produces errors - examine
                        float w = 1.0f; //gaussMul * exp(-((rm - cast(float)i)^^2 + (cm - cast(float)j)^^2) / gaussDel);

                        // TODO: consider subpixel precision for gradient sampling.
                        const float fx = fxs[i, j];
                        const float fy = fys[i, j];
                        const float ft = cast(float)(linear(next, ny, nx) - current[i, j]);

                        const float fxx = fx * fx;
                        const float fyy = fy * fy;
                        const float fxy = fx * fy;

                        a1 += w * fxx;
                        a2 += w * fxy;
                        a3 += w * fyy;

                        b1 += w * fx * ft;
                        b2 += w * fy * ft;
                    }
                }

                // TODO: consider resp normalization...
                resp = ((a1 + a3) - sqrt((a1 - a3) * (a1 - a3) + a2 * a2));

                auto d = (a1 * a3 - a2 * a2);

                if (d) {
                    d = 1.0f / d;
                    f[0] += (a2 * b2 - a3 * b1) * d;
                    f[1] += (a2 * b1 - a1 * b2) * d;
                }
            }
        }

        return flow;
    }

}
