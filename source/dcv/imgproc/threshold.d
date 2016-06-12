/**
Image thresholding module.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.imgproc.threshold;

/*
v0.1 norm:
threshold
adaptiveThreshold (threshold each pixel using it's neighbourhood as thresholding norm)
*/

import std.experimental.ndslice;

import dcv.core.utils : emptySlice;

/**
Clip slice values by a given threshold value.

If any slice element has value in range between lower and 
upper threshold value, its output value is set to upper 
clipping value, otherwise to 0. If output value type is 
a floating point, upper clipping value is 1.0, otherwise 
its the maximal value for that type (e.g. for ubyte its 255, 
for float and double its 1.0).

If lower threshold bound is of the same value as higher, then
values are clipped from given value to 0.

Thresholding is supported for 1D, 2D and 3D slices.

params:
slice = Input slice.
lowThresh = Lower threshold value.
highThresh = Higher threshold value.
prealloc = Optional pre-allocated slice buffer for output.
*/
Slice!(N, OutputType*) threshold(OutputType, InputType, size_t N)
    (Slice!(N, InputType*) slice, InputType lowThresh, InputType highThresh, Slice!(N, OutputType*) prealloc = emptySlice!(N, OutputType))
in {

    //TODO: consider leaving upper value, and not setting it to 1.
    assert(lowThresh <= highThresh);
    assert(!slice.empty);
} body {
    import std.array : uninitializedArray;
    import std.algorithm.iteration : reduce;
    import std.range : lockstep;
    import std.math : approxEqual;
    import std.traits : isFloatingPoint;

    if (prealloc.shape[] != slice.shape[]) {
        prealloc = uninitializedArray!(OutputType[])(slice.shape[].reduce!"a*b").sliced(slice.shape);
    }

    static if (isFloatingPoint!OutputType) {
        OutputType upvalue = 1.0;
    } else {
        OutputType upvalue = OutputType.max;
    }

    pure nothrow @safe @nogc InputType cmp_l(ref InputType v) { return v <= lowThresh ? 0 : upvalue; }
    pure nothrow @safe @nogc InputType cmp_lu(ref InputType v) { return v >= lowThresh && v <= highThresh ? upvalue : 0; }

    InputType delegate (ref InputType v) pure nothrow @nogc @safe cmp;

    if (lowThresh.approxEqual(highThresh)) {
        cmp = &cmp_l;
    } else {
        cmp = &cmp_lu;
    }

    foreach(ref t, e; lockstep(prealloc.byElement, slice.byElement)) {
        static if (is(InputType==OutputType)) 
            t = cmp(e); //(e >= lowThresh && e <= highThresh) ? e : cast(OutputType)0;
        else
            t = cast(OutputType)cmp(e);
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
Slice!(N, OutputType*) threshold(OutputType, InputType, size_t N)
    (Slice!(N, InputType*) slice, InputType thresh, Slice!(N, OutputType*) prealloc = emptySlice!(N, OutputType))
{
    return threshold!(OutputType, InputType, N)(slice, thresh, thresh, prealloc);
}

