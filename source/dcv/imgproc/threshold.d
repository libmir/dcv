/**
Image thresholding module.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.imgproc.threshold;

import mir.ndslice, mir.rc;
import mir.algorithm.iteration : each;
import mir.ndslice.allocation;

import std.experimental.allocator.gc_allocator;

import dcv.core.utils : emptyRCSlice;

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
    input = Input slice.
    lowThresh   = Lower threshold value.
    highThresh  = Higher threshold value.
    prealloc    = Optional pre-allocated slice buffer for output.

Note:
    Input and pre-allocated buffer slice, should be of same structure
    (i.e. have same strides). If prealloc buffer is not given, and is
    allocated anew, input slice memory must be contiguous.
*/
nothrow Slice!(RCI!OutputType, 2, Contiguous) threshold(OutputType, InputType, size_t N, SliceKind kind)
(
    Slice!(InputType*, N, kind) input,
    InputType lowThresh,
    InputType highThresh,
    bool inverse = false,
    Slice!(RCI!OutputType, 2, Contiguous) prealloc = emptyRCSlice!(2, OutputType)
)
in
{
    //TODO: consider leaving upper value, and not setting it to 1.
    assert(lowThresh <= highThresh);
    assert(!input.empty);
}
do
{
    import std.math.operations : isClose;
    import std.traits : isFloatingPoint, isNumeric;

    static assert(isNumeric!OutputType, "Invalid output type - has to be numeric.");

    if (prealloc.shape != input.shape)
    {
        prealloc = uninitRCslice!OutputType(input.shape); //uninitializedSlice!OutputType(input.shape);
    }

    assert(input.structure.strides == prealloc.structure.strides,
            "Input slice structure does not match with resulting buffer.");

    static if (isFloatingPoint!OutputType){
        immutable OutputType upvalue = inverse?0.0:1.0;
        immutable OutputType downvalue = inverse?1.0:0.0;
    }else{
        immutable OutputType upvalue   = inverse ? 0 : OutputType.max;
        immutable OutputType downvalue = inverse ? OutputType.max : 0;
    }

    auto p = zip!true(prealloc, input);

    if (lowThresh.isClose(highThresh))
    {
        p.each!((v)
        {
            v.a = cast(OutputType)(v.b <= lowThresh ? downvalue : upvalue);
        });
    }
    else
    {
        p.each!((v)
        {
            v.a = cast(OutputType)(v.b >= lowThresh && v.b <= highThresh ? upvalue : downvalue);
        });
    }

    return prealloc;
}

/**
Convenience function for thresholding, where lower and upper bound values are the same.

Calls threshold(slice, thresh, thresh, prealloc)

Params:
    input       = Input slice.
    thresh      = Threshold value - any value lower than this will be set to 0, and higher to 1.
    prealloc    = Optional pre-allocated slice buffer for output.

Note:
    Input and pre-allocated buffer slice, should be of same structure
    (i.e. have same strides). If prealloc buffer is not given, and is
    allocated anew, input slice memory must be contiguous.
*/
nothrow Slice!(RCI!OutputType, 2, Contiguous) threshold(OutputType, InputType, size_t N, SliceKind kind)
(
    Slice!(InputType*, N, kind) input,
    InputType thresh,
    bool inverse = false,
    Slice!(RCI!OutputType, 2, Contiguous) prealloc = emptyRCSlice!(2, OutputType)
)
{
    return threshold!(OutputType)(input, thresh, thresh, inverse, prealloc);
}

enum THR_INVERSE = true;

/** Return threshold value based on Otsu’s method.

Params:
    hist = Input histogram.
*/
int getOtsuThresholdValue(alias N = size_t)(int[N] hist) @nogc nothrow
{
    // Based on: https://github.com/scikit-image/scikit-image/blob/602d94d35d3a04e6b66583c3a1a355bfbe381224/skimage/filters/thresholding.py#L371
    
    import mir.ndslice.topology : as, iota, retro;
    import mir.ndslice.allocation : rcslice;
    import std.range: std_iota = iota;
    import std.array : staticArray;
    import mir.algorithm.iteration : maxIndex, each;
    import std.algorithm.iteration: cumulativeFold;
    import std.math.traits : isNaN;
    import std.stdio;
    
    
    auto binCenters = std_iota!int(N).staticArray!N.as!int.rcslice;
    
    auto weight1 = cumulativeFold!"a + b"(hist[], 0).staticArray!N.as!float.rcslice;
    auto weight2 = cumulativeFold!"a + b"(hist[].retro, 0).staticArray!N.as!float.rcslice.retro;
    

    auto counts = hist.as!float.rcslice;

    auto mult = counts * binCenters;

    auto csmult = cumulativeFold!"a + b"(mult, 0.0).staticArray!N.as!float.rcslice;
    
    auto mean1 = csmult / weight1;

    auto csmult2 = cumulativeFold!"a + b"(mult.retro, 0.0).staticArray!N.as!float.rcslice;
    
    auto mean2 = (csmult2 / weight2.retro).retro.rcslice;
    mean2.each!((ref v){if(v.isNaN) v=cast(float)(N-1); });
    
    auto variance12 = weight1[0..$-1] * weight2[1..$] * (mean1[0..$-1] - mean2[1..$]) ^^ 2;
    
    auto idx = cast(ulong)variance12.maxIndex[0];
    
    
    return binCenters[idx];
}