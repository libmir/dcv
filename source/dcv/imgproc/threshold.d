/**
Image thresholding module.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.imgproc.threshold;

import mir.ndslice;
import mir.ndslice.algorithm : each;

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

Params:
    slice = Input slice.
    lowThresh = Lower threshold value.
    highThresh = Higher threshold value.
    prealloc = Optional pre-allocated slice buffer for output.

Note:
    Input and pre-allocated buffer slice, should be of same structure
    (i.e. have same strides). If prealloc buffer is not given, and is
    allocated anew, input slice memory must be contiguous.
*/
nothrow Slice!(N, OutputType*) threshold(OutputType, InputType, size_t N)(Slice!(N, InputType*) input,
        InputType lowThresh, InputType highThresh, Slice!(N, OutputType*) prealloc = emptySlice!(N, OutputType))
in
{
    //TODO: consider leaving upper value, and not setting it to 1.
    assert(lowThresh <= highThresh);
    assert(!input.empty);
}
body
{
    import std.math : approxEqual;
    import std.traits : isFloatingPoint, isNumeric;

    static assert(isNumeric!OutputType, "Invalid output type - has to be numeric.");

    if (prealloc.shape != input.shape)
    {
        prealloc = uninitializedSlice!OutputType(input.shape);
    }

    assert(input.structure.strides == prealloc.structure.strides,
            "Input slice structure does not match with resulting buffer.");

    static if (isFloatingPoint!OutputType)
        OutputType upvalue = 1.0;
    else
        OutputType upvalue = OutputType.max;

    auto p = zip!true(prealloc, input);

    if (lowThresh.approxEqual(highThresh))
    {
        p.each!((v)
        {
            v.a = cast(OutputType)(v.b <= lowThresh ? 0 : upvalue);
        });
    }
    else
    {
        p.each!((v)
        {
            v.a = cast(OutputType)(v.b >= lowThresh && v.b <= highThresh ? upvalue : 0);
        });
    }

    return prealloc;
}

/**
Convenience function for thresholding, where lower and upper bound values are the same.

Calls threshold(slice, thresh, thresh, prealloc)

Params:
    slice = Input slice.
    thresh = Threshold value - any value lower than this will be set to 0, and higher to 1.
    prealloc = Optional pre-allocated slice buffer for output.

Note:
    Input and pre-allocated buffer slice, should be of same structure
    (i.e. have same strides). If prealloc buffer is not given, and is
    allocated anew, input slice memory must be contiguous.
*/
nothrow Slice!(N, OutputType*) threshold(OutputType, InputType, size_t N)(Slice!(N, InputType*) slice,
        InputType thresh, Slice!(N, OutputType*) prealloc = emptySlice!(N, OutputType))
{
    return threshold!(OutputType, InputType, N)(slice, thresh, thresh, prealloc);
}
