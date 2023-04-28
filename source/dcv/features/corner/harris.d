/**
Module implements $(LINK3 https://en.wikipedia.org/wiki/Corner_detection#The_Harris_.26_Stephens_.2F_Plessey_.2F_Shi.E2.80.93Tomasi_corner_detection_algorithms, Harris and Shi-Tomasi) corner detectors.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.features.corner.harris;

import std.experimental.allocator.gc_allocator;

import mir.math.common : fastmath;

import mir.ndslice;
import mir.rc;
import mir.algorithm.iteration : each;
import mir.ndslice.allocation;

import dcv.core.utils : emptyRCSlice, pool;
import dcv.imgproc.filter : calcPartialDerivatives;

import dplug.core;

@nogc nothrow:

/**
Calculate per-pixel corner impuls response using Harris corner detector.

Params:
    image       = Input image slice.
    winSize     = Window (square) size used in corner detection.
    k           = Sensitivity parameter defined in the algorithm.
    gauss       = Gauss sigma value used as window weighting parameter.
    prealloc    = Optional pre-allocated buffer for return response image.

Returns:
    Response matrix the same size of the input image, where each pixel represents
    corner response value - the bigger the value, more probably it represents the
    actual corner in the image.
 */
Slice!(RCI!T, 2LU, SliceKind.contiguous) harrisCorners(T, SliceKind inputKind)
(
    Slice!(T*, 2LU, inputKind) image,
    in uint winSize = 3,
    in float k = 0.64f,
    in float gauss = 0.84f,
    Slice!(RCI!T, 2LU, SliceKind.contiguous) prealloc = emptyRCSlice!(2, T)
)
in
{
    assert(!image.empty, "Empty image given.");
    assert(winSize % 2 != 0, "Kernel window size has to be odd.");
    assert(gauss > 0.0, "Gaussian sigma value has to be greater than 0.");
    assert(k > 0.0, "K value has to be greater than 0.");
}
do
{

    if (prealloc.shape != image.shape)
    {
        prealloc = uninitRCslice!T(image.shape);//uninitializedSlice!T(image.shape);
    }
    HarrisDetector detector;
    detector.k = k;
    return calcCorners(image, winSize, gauss, prealloc, detector);
}

/**
Calculate per-pixel corner impuls response using Shi-Tomasi corner detector.

Params:
    image       = Input image slice.
    winSize     = Window (square) size used in corner detection.
    gauss       = Gauss sigma value used as window weighting parameter.
    prealloc    = Optional pre-allocated buffer for return response image.

Returns:
    Response matrix the same size of the input image, where each pixel represents
    corner response value - the bigger the value, more probably it represents the
    actual corner in the image.
 */
Slice!(RCI!T, 2LU, SliceKind.contiguous) shiTomasiCorners(T, SliceKind inputKind)
(
    Slice!(T*, 2LU, inputKind) image,
    in uint winSize = 3,
    in float gauss = 0.84f,
    Slice!(RCI!T, 2LU, SliceKind.contiguous) prealloc = emptyRCSlice!(2, T)
)
in
{
    assert(!image.empty, "Empty image given.");
    assert(winSize % 2 != 0, "Kernel window size has to be odd.");
    assert(gauss > 0.0, "Gaussian sigma value has to be greater than 0.");
}
do
{
    if (prealloc.empty)
    {
        prealloc = uninitRCslice!T(image.shape); //uninitializedSlice!T(image.shape);
    }

    ShiTomasiDetector detector;
    return calcCorners(image, winSize, gauss, prealloc, detector);
}

unittest
{
    auto image = new float[9].sliced(3, 3);
    auto result = harrisCorners(image, 3, 0.64, 0.84);
    assert(result.shape == image.shape);
}

unittest
{
    import std.range : lockstep;

    auto image = new float[9].sliced(3, 3);
    auto resultBuffer = new double[9].sliced(3, 3);
    auto result = harrisCorners!(float, double)(image, 3, 0.64, 0.84, resultBuffer);
    assert(result.shape == image.shape);
    foreach (ref r1, ref r2; lockstep(result.flattened, resultBuffer.flattened))
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
    foreach (ref r1, ref r2; lockstep(result.flattened, resultBuffer.flattened))
    {
        assert(&r1 == &r2);
    }
}

@nogc nothrow @fastmath
{
    void calcCornersImpl(Window, Detector)(Window window, Detector detector)
    {
        import mir.algorithm.iteration : reduce;

        float[3] r = [0.0f, 0.0f, 0.0f];
        float winSqr = float(window.length!0);
        winSqr *= winSqr;

        r = reduce!sumResponse(r, window);

        r[0] = (r[0] / winSqr) * 0.5f;
        r[1] /= winSqr;
        r[2] = (r[2] / winSqr) * 0.5f;

        auto rv = detector(r[0], r[1], r[2]);
        if (rv > 0)
            window[$ / 2, $ / 2].a = rv;
    }

    float[3] sumResponse(Pack)(float[3] r, Pack pack)
    {
        auto gx = pack.b;
        auto gy = pack.c;
        return [r[0] + gx * gx, r[1] + gx * gy, r[2] + gy * gy];
    }
}

private:

struct HarrisDetector
{
    float k;

    @fastmath @nogc nothrow float opCall(float r1, float r2, float r3)
    {
        return (((r1 * r1) - (r2 * r3)) - k * ((r1 + r3) * r1 + r3));
    }
}

struct ShiTomasiDetector
{
    @fastmath @nogc nothrow float opCall(float r1, float r2, float r3)
    {
        import mir.math.common : sqrt;
        return ((r1 + r3) - sqrt((r1 - r3) * (r1 - r3) + r2 * r2));
    }
}

Slice!(RCI!OutputType, 2LU, SliceKind.contiguous) calcCorners(Detector, InputType, SliceKind inputKind, OutputType)
    (Slice!(InputType*, 2LU, inputKind) image, uint winSize, float gaussSigma,
    Slice!(RCI!OutputType, 2LU, SliceKind.contiguous) prealloc, Detector detector)
{
    import mir.ndslice.topology : zip, iota;

    // TODO: implement gaussian weighting!

    Slice!(RCI!InputType, 2, SliceKind.contiguous) fx, fy;
    calcPartialDerivatives(image, fx, fy);

    auto windowPack = zip(prealloc, fx.lightScope, fy.lightScope).windows(winSize, winSize);

    void worker(int i, int threadIndex) nothrow @nogc {
        auto windowRow = windowPack[i];
        windowRow.each!(win => calcCornersImpl(win, detector));
    }
    pool.parallelFor(cast(int)windowPack.length, &worker);

    return prealloc;
}
