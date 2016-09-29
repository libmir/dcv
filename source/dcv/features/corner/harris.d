/**
Module implements $(LINK3 https://en.wikipedia.org/wiki/Corner_detection#The_Harris_.26_Stephens_.2F_Plessey_.2F_Shi.E2.80.93Tomasi_corner_detection_algorithms, Harris and Shi-Tomasi) corner detectors.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.features.corner.harris;

import std.parallelism : parallel, taskPool, TaskPool;

import mir.ndslice;
import mir.ndslice.algorithm : ndEach, Yes;

import dcv.core.utils : emptySlice;
import dcv.imgproc.filter : calcPartialDerivatives;

/**
Calculate per-pixel corner impuls response using Harris corner detector.

Params:
    image = Input image slice.
    winSize = Window (square) size used in corner detection.
    k = Sensitivity parameter defined in the algorithm.
    gauss = Gauss sigma value used as window weighting parameter.
    prealloc = Optional pre-allocated buffer for return response image.

Returns:
    Response matrix the same size of the input image, where each pixel represents
    corner response value - the bigger the value, more probably it represents the
    actual corner in the image.
 */
Slice!(2, OutputType*) harrisCorners(InputType, OutputType = InputType)(Slice!(2,
        InputType*) image, in uint winSize = 3, in float k = 0.64f, in float gauss = 0.84f, Slice!(2,
        OutputType*) prealloc = emptySlice!(2, OutputType), TaskPool pool = taskPool)
in
{
    assert(!image.empty, "Empty image given.");
    assert(winSize % 2 != 0, "Kernel window size has to be odd.");
    assert(gauss > 0.0, "Gaussian sigma value has to be greater than 0.");
    assert(k > 0.0, "K value has to be greater than 0.");
}
body
{
    if (prealloc.shape != image.shape)
    {
        prealloc = uninitializedSlice!OutputType(image.shape);
    }
    HarrisDetector detector;
    detector.k = k;
    return calcCorners(image, winSize, gauss, prealloc, detector, pool);
}

/**
Calculate per-pixel corner impuls response using Shi-Tomasi corner detector.

Params:
    image = Input image slice.
    winSize = Window (square) size used in corner detection.
    gauss = Gauss sigma value used as window weighting parameter.
    prealloc = Optional pre-allocated buffer for return response image.

Returns:
    Response matrix the same size of the input image, where each pixel represents
    corner response value - the bigger the value, more probably it represents the
    actual corner in the image.
 */
Slice!(2, OutputType*) shiTomasiCorners(InputType, OutputType = InputType)(Slice!(2,
        InputType*) image, in uint winSize = 3, in float gauss = 0.84f, Slice!(2,
        OutputType*) prealloc = emptySlice!(2, OutputType), TaskPool pool = taskPool)
in
{
    assert(!image.empty, "Empty image given.");
    assert(winSize % 2 != 0, "Kernel window size has to be odd.");
    assert(gauss > 0.0, "Gaussian sigma value has to be greater than 0.");
}
body
{
    if (prealloc.shape != image.shape)
    {
        prealloc = uninitializedSlice!OutputType(image.shape);
    }

    ShiTomasiDetector detector;
    return calcCorners(image, winSize, gauss, prealloc, detector, pool);
}

unittest
{
    import std.algorithm.comparison : equal;

    auto image = new float[9].sliced(3, 3);
    auto result = harrisCorners(image, 3, 0.64, 0.84);
    assert(result.shape[].equal(image.shape[]));
}

unittest
{
    import std.algorithm.comparison : equal;
    import std.range : lockstep;

    auto image = new float[9].sliced(3, 3);
    auto resultBuffer = new double[9].sliced(3, 3);
    auto result = harrisCorners!(float, double)(image, 3, 0.64, 0.84, resultBuffer);
    assert(result.shape[].equal(image.shape[]));
    foreach (ref r1, ref r2; lockstep(result.byElement, resultBuffer.byElement))
    {
        assert(&r1 == &r2);
    }
}

unittest
{
    import std.algorithm.comparison : equal;

    auto image = new float[9].sliced(3, 3);
    auto result = shiTomasiCorners(image, 3, 0.84);
    assert(result.shape[].equal(image.shape[]));
}

unittest
{
    import std.algorithm.comparison : equal;
    import std.range : lockstep;

    auto image = new float[9].sliced(3, 3);
    auto resultBuffer = new double[9].sliced(3, 3);
    auto result = shiTomasiCorners!(float, double)(image, 3, 0.84, resultBuffer);
    assert(result.shape[].equal(image.shape[]));
    foreach (ref r1, ref r2; lockstep(result.byElement, resultBuffer.byElement))
    {
        assert(&r1 == &r2);
    }
}

private:

struct HarrisDetector
{
    float k;

    @nogc nothrow float opCall(float r1, float r2, float r3)
    {
        return (((r1 * r1) - (r2 * r3)) - k * ((r1 + r3) * r1 + r3));
    }
}

struct ShiTomasiDetector
{
    @nogc nothrow float opCall(float r1, float r2, float r3)
    {
        import std.math : sqrt;

        return ((r1 + r3) - sqrt((r1 - r3) * (r1 - r3) + r2 * r2));
    }
}

Slice!(2, OutputType*) calcCorners(Detector, InputType, OutputType)(Slice!(2, InputType*) image,
        uint winSize, float gaussSigma, Slice!(2, OutputType*) prealloc, Detector detector, TaskPool pool)
{
    // TODO: implement gaussian weighting!

    Slice!(2, InputType*) fx, fy;
    calcPartialDerivatives(image, fx, fy);

    auto windowPack = assumeSameStructure!("corners", "fx", "fy")(prealloc, fx, fy).windows(winSize, winSize);

    foreach (windowRow; pool.parallel(windowPack))
    {
        windowRow.ndEach!(win => calcCornersImpl(win, detector));
    }

    return prealloc;
}

@nogc nothrow
void calcCornersImpl(Window, Detector)(ref Window window, ref Detector detector)
{
    float r1 = 0.0f, r2 = 0.0f, r3 = 0.0f;
    float winSqr = float(window.length!0);
    winSqr *= winSqr;

    window.ndEach!((pack) { auto gx = pack.fx; auto gy = pack.fy; r1 += gx * gx; r2 += gx * gy; r3 += gy * gy;  });

    r1 = (r1 / winSqr) * 0.5;
    r2 /= winSqr;
    r3 = (r3 / winSqr) * 0.5;

    auto r = detector(r1, r2, r3);
    if (r > 0)
        window[$ / 2, $ / 2].corners = r;
}
