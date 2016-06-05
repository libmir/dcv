module dcv.imgproc.threshold;


/**
 * Image thresholding module.
 * 
 * v0.1 norm:
 * threshold
 * adaptiveThreshold (threshold each pixel using it's neighbourhood as thresholding norm)
 */

import std.experimental.ndslice;

import dcv.core.utils : emptySlice;

/**
 * Clip slice values by a given threshold value.
 * 
 * TODO: consider leaving upper value, and not setting it to 1.
 * 
 * If any slice element has value in range between lower and 
 * upper threshold value, its output value is set to upper 
 * clipping value, otherwise to 0. If output value type is 
 * a floating point, upper clipping value is 1.0, otherwise 
 * its the maximal value for that type (e.g. for ubyte its 255, 
 * for float and double its 1.0).
 * 
 * If lower threshold bound is of the same value as higher, then
 * values are clipped from given value to 0.
 * 
 * Thresholding is supported for 1D, 2D and 3D slices.
 * 
 * params:
 * slice = Input slice.
 * lowThresh = Lower threshold value.
 * highThresh = Higher threshold value.
 * prealloc = Optional pre-allocated slice buffer for output.
 * 
 */
Slice!(N, V*) threshold(V, T, size_t N)
    (Slice!(N, T*) slice, T lowThresh, T highThresh, Slice!(N, V*) prealloc = emptySlice!(N, V))
in {
    assert(lowThresh <= highThresh);
    assert(!slice.empty);
} body {
    import std.array : uninitializedArray;
    import std.algorithm.iteration : reduce;
    import std.range : lockstep;
    import std.math : approxEqual;
    import std.traits : isFloatingPoint;

    if (prealloc.shape[] != slice.shape[]) {
        prealloc = uninitializedArray!(V[])(slice.shape[].reduce!"a*b").sliced(slice.shape);
    }

    static if (isFloatingPoint!V) {
        V upvalue = 1.0;
    } else {
        V upvalue = V.max;
    }

    pure nothrow @safe @nogc T cmp_l(ref T v) { return v <= lowThresh ? 0 : upvalue; }
    pure nothrow @safe @nogc T cmp_lu(ref T v) { return v >= lowThresh && v <= highThresh ? upvalue : 0; }

    T delegate (ref T v) pure nothrow @nogc @safe cmp;

    if (lowThresh.approxEqual(highThresh)) {
        cmp = &cmp_l;
    } else {
        cmp = &cmp_lu;
    }

    foreach(ref t, e; lockstep(prealloc.byElement, slice.byElement)) {
        static if (is(T==V)) 
            t = cmp(e); //(e >= lowThresh && e <= highThresh) ? e : cast(V)0;
        else
            t = cast(V)cmp(e);
    }

    return prealloc;
}

/**
 * Convenience function for thresholding, where lower and upper bound values are the same.
 * 
 * Calls threshold(slice, thresh, thresh, prealloc)
 * 
 * params:
 * slice = Input slice.
 * thresh = Threshold value - any value lower than this will be set to 0, and higher to 1.
 * prealloc = Optional pre-allocated slice buffer for output.
 * 
 */
Slice!(N, V*) threshold(V, T, size_t N)
    (Slice!(N, T*) slice, T thresh, Slice!(N, V*) prealloc = emptySlice!(N, V))
{
    return threshold!(V, T, N)(slice, thresh, thresh, prealloc);
}

