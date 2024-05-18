/**
Module contains color format convertion operations.
$(DL Module contains:
    $(DD 
            $(LINK2 #rgb2gray,rgb2gray)
            $(LINK2 #gray2rgb,gray2rgb)
            $(LINK2 #rgb2hsv,rgb2hsv)
            $(LINK2 #hsv2rgb,hsv2rgb)
            $(LINK2 #rgb2yuv,rgb2yuv)
            $(LINK2 #yuv2rgb,yuv2rgb)
    )
)
Copyright: Copyright Relja Ljubobratovic 2016.
Authors: Relja Ljubobratovic
License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.imgproc.color;

/*
TODO: redesign functions - one function to iterate, separated format convertions as template alias. 
Consider grouping color convertion routines into one function.
v0.1 norm:
rgb2gray vice versa (done)
hsv2rgb -||-
hls2rgb -||-
lab2rgb -||-
luv2rgb -||-
luv2rgb -||-
bayer2rgb -||-
*/
import std.traits : isFloatingPoint, isNumeric;
import std.array : staticArray;
import mir.math.common : fastmath;

import mir.ndslice.slice;
import mir.rc;
import mir.ndslice.topology;
import mir.ndslice.chunks;

import mir.ndslice.allocation;

import dcv.core.utils;

/**
RGB to Grayscale convertion strategy.
*/
enum Rgb2GrayConvertion
{
    MEAN, /// Mean the RGB values and assign to gray.
    LUMINANCE_PRESERVE /// Use luminance preservation (0.2126R + 0.715G + 0.0722B). 
}

/**
Convert RGB image to grayscale.
Params:
    input = Input image. Should have 3 channels, represented as R, G and B
        respectively in that order.
    prealloc = Pre-allocated buffer, where grayscale image will be copied. Default
    argument is an empty slice, where new data is allocated and returned. If given 
    slice is not of corresponding shape(range.shape[0], range.shape[1]), it is 
    discarded and allocated anew.
    conv = Convertion strategy - mean, or luminance preservation.
Returns:
    Returns grayscale version of the given RGB image, of the same size.
Note:
    Input and pre-allocated slices' strides must be identical.
*/
@nogc nothrow
Slice!(RCI!V, 2, SliceKind.contiguous) rgb2gray(V)(Slice!(V*, 3, SliceKind.contiguous) input, Slice!(RCI!V, 2, SliceKind.contiguous) prealloc = emptyRCSlice!(2, V),
        Rgb2GrayConvertion conv = Rgb2GrayConvertion.LUMINANCE_PRESERVE) pure
{
    return rgbbgr2gray!(false, V)(input, prealloc, conv);
}

unittest
{
    import std.math : approxEqual;

    auto rgb = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3].staticArray[].sliced(2, 2, 3);

    auto gray = rgb.rgb2gray;
    assert(gray.flattened[] == [0, 1, 2, 3].staticArray[]);
}

/**
Convert BGR image to grayscale.
Same as rgb2gray, but follows swapped channels if luminance preservation
is chosen as convertion strategy.
Params:
    input = Input image. Should have 3 channels, represented as B, G and R
        respectively in that order.
    prealloc = Pre-allocated range, where grayscale image will be copied. Default
    argument is an empty slice, where new data is allocated and returned. If given 
    slice is not of corresponding shape(range.shape[0], range.shape[1]), it is 
    discarded and allocated anew.
    conv = Convertion strategy - mean, or luminance preservation.
Returns:
    Returns grayscale version of the given BGR image, of the same size.
Note:
    Input and pre-allocated slices' strides must be identical.
*/
@nogc nothrow
Slice!(RCI!V, 2, SliceKind.contiguous) bgr2gray(V)(Slice!(V*, 3LU, SliceKind.contiguous) input, Slice!(RCI!V, 2, SliceKind.contiguous) prealloc = emptyRCSlice!(2, V),
        Rgb2GrayConvertion conv = Rgb2GrayConvertion.LUMINANCE_PRESERVE) pure
{
    return rgbbgr2gray!(true, V)(input, prealloc, conv);
}

unittest
{
    import mir.algorithm.iteration: equal;
    import mir.math.common: approxEqual;
    import std: isClose;

    auto rgb = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3].staticArray[].sliced(2, 2, 3).as!ubyte.rcslice;

    auto gray = rgb.lightScope.bgr2gray;
    assert(gray.flattened[] == [0, ubyte(1), 2, 3].staticArray[].sliced.as!ubyte[]);
}

@nogc nothrow
private Slice!(RCI!V, 2LU, SliceKind.contiguous) rgbbgr2gray(bool isBGR, V)(Slice!(V*, 3LU, SliceKind.contiguous) input, Slice!(RCI!V, 2LU, SliceKind.contiguous) prealloc = emptyRCSlice!(2, V),
        Rgb2GrayConvertion conv = Rgb2GrayConvertion.LUMINANCE_PRESERVE) pure
in
{
    assert(!input.empty, "Input image is empty.");
}
do
{
    if (prealloc.shape != input.shape[0 .. 2])
        prealloc = uninitRCslice!V(input.shape[0], input.shape[1]);

    auto rgb = staticPack!3(input);

    assert(rgb.strides == prealloc.strides,
            "Input image and pre-allocated buffer strides are not identical.");

    auto pack = zip!true(rgb, prealloc);
    alias PT = DeepElementType!(typeof(pack));

    if (conv == Rgb2GrayConvertion.MEAN)
        pack.each!(rgb2grayImplMean!PT);
    else
        static if (isBGR)
            pack.each!(bgr2grayImplLuminance!(PT));
        else
            pack.each!(rgb2grayImplLuminance!(PT));

    return prealloc;
}

/**
Convert gray image to RGB.
Uses grayscale value and assigns it's value
to each of three channels for the RGB image version.
Params:
    input = Grayscale image, to be converted to the RGB.
    prealloc = Pre-allocated range, where RGB image will be copied. Default
    argument is an empty slice, where new data is allocated and returned. If given 
    slice is not of corresponding shape(range.shape[0], range.shape[1], 3), it is 
    discarded and allocated anew.
Returns:
    Returns RGB version of the given grayscale image.
Note:
    Input and pre-allocated slices' strides must be identical.
*/
import mir.algorithm.iteration: each;

@nogc nothrow
Slice!(RCI!V, 3, SliceKind.contiguous) gray2rgb(V)(Slice!(V*, 2, SliceKind.contiguous) input, Slice!(RCI!V, 3, SliceKind.contiguous) prealloc = emptyRCSlice!(3, V)) pure
{
    Slice!(RCI!V, 3, SliceKind.contiguous) rgb;
    if (input.shape != prealloc.shape[0 .. 2])
    {
        rgb = uninitRCslice!V(input.shape[0], input.shape[1], 3);//uninitSlice!(V, 3)(input.length!0, input.length!1, input.length!2);
        
    }

    //assert(rgb.strides == input.strides,
    //        "Input and pre-allocated slices' strides are not identical.");

    auto pack = zip(input.flattened, rgb.flattened.blocks(3));
    alias PT = DeepElementType!(typeof(pack));

    pack.each!(gray2rgbImpl!PT);

    return rgb;
}

unittest
{
    import mir.algorithm.iteration: equal;
    import mir.math.common: approxEqual;
    ubyte[4] gr = [0, 1, 2, 3];
    auto gray = gr[].sliced(2, 2);

    auto rgb = gray.gray2rgb;

    ubyte[12] rb = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3];
    assert(rgb.flattened[] == rb[].sliced[]);
}

/**
Convert RGB image to HSV color format.
If HSV is represented as floating point, H is 
represented as 0-360 (degrees), S and V are 0.0-1.0.
If is integral, S, and V are 0-100.
Depending on the RGB (input) type, values are treated in the
algorithm to be ranged as 0-255 for ubyte, 0-65535 for ushort, 
and 0-1 for floating point types.
Params:
    input = RGB image, which gets converted to HSV.
    prealloc = Pre-allocated range, where HSV image will be copied. Default
    argument is an empty slice, where new data is allocated and returned. If given 
    slice is not of corresponding shape(range.shape[0], range.shape[1], 3), it is 
    discarded and allocated anew.
Returns:
    Returns HSV verion of the given RGB image.
Note:
    Input and pre-allocated slices' strides must be identical.
*/
@nogc nothrow
Slice!(RCI!R, 3LU, SliceKind.contiguous) rgb2hsv(R, V)(Slice!(V*, 3LU, SliceKind.contiguous) input, Slice!(RCI!R, 3LU, SliceKind.contiguous) prealloc = emptyRCSlice!(3, R)) pure
        if (isNumeric!R && isNumeric!V)
in
{
    static assert(R.max >= 360, "Invalid output type for HSV (R.max >= 360)");
    assert(input.length!2 == 3, "Invalid channel count.");
}
do
{
    if (prealloc.shape != input.shape)
        prealloc = uninitRCslice!R(input.shape);

    assert(input.strides == prealloc.strides,
            "Input image and pre-allocated buffer strides are not identical.");

    auto pack = zip!true(input.flattened.blocks(3), prealloc.flattened.blocks(3));
    pack.each!(rgb2hsvImpl!(DeepElementType!(typeof(pack))));

    return prealloc;
}

unittest
{
    // value comparison based on results from http://www.rapidtables.com/convert/color/rgb-to-hsv.htm
    auto rgb2hsvTest(RGBTypeA, HSVTypeA)(RGBTypeA rgb, HSVTypeA expectedHSV)
    {
        import std.conv : to;
        import std.math.operations : isClose;

        import mir.algorithm.iteration : all;
        
        import std.traits : isIntegral;

        alias RGBType = DeepElementType!(RGBTypeA);
        alias HSVType = DeepElementType!(HSVTypeA);
        
        static if(isIntegral!HSVType){
            assert(rgb[].sliced(1, 1, 3).rgb2hsv!HSVType.flattened[] == expectedHSV[]);
        }else{
            auto computed = rgb[].sliced(1, 1, 3).rgb2hsv!HSVType.lightScope;
            auto expected = expectedHSV[].sliced(1, 1, 3);

            assert(zip(computed, expected).all!(pair => isClose(pair.a, pair.b, 1e-2)), 
                computed.to!string ~ " should close to " ~ expected.to!string);
        }
        
    }

    rgb2hsvTest([ubyte(255), ubyte(0), ubyte(0)].staticArray!(ubyte, 3), [ushort(0), 100, 100].staticArray!(ushort, 3));
    rgb2hsvTest([ubyte(255), ubyte(0), ubyte(0)].staticArray!(ubyte, 3), [float(0), 1.0f, 1.0f].staticArray!(float, 3)); // test float result

    // test same input values as above for 16-bit and 32-bit images
    rgb2hsvTest([ushort.max, 0, 0].staticArray!(ushort, 3), [0, 100, 100].staticArray!(ushort, 3));
    rgb2hsvTest([1.0f, 0.0f, 0.0f].staticArray!(float, 3), [0, 100, 100].staticArray!(ushort, 3));

    rgb2hsvTest([ubyte(0), 255, 0].staticArray!(ubyte, 3), [120, 100, 100].staticArray!(ushort, 3));
    rgb2hsvTest([ubyte(0), 0, 255].staticArray!(ubyte, 3), [240, ushort(100), 100].staticArray!(ushort, 3));
    rgb2hsvTest([ubyte(122), 158, 200].staticArray!(ubyte, 3), [float(212.0f), 0.39f, 0.784f].staticArray!(float, 3));
}

/**
Convert HSV image to RGB color format.
If HSV is represented in floating point, H is 0-360 degrees, S and V is 0.0-1.0. 
If it's of integral type, S and V values are in 0-100 range.
Output range values are based on the output type cast - ubyte will
range RGB values to be 0-255, ushort 0-65535, and floating types
0.0-1.0. Other types are not supported.
Params:
    input = HSV image, which gets converted to RGB.
    prealloc = Pre-allocated range, where RGB image will be copied. Default
    argument is an empty slice, where new data is allocated and returned. If given 
    slice is not of corresponding shape(range.shape[0], range.shape[1], 3), it is 
    discarded and allocated anew.
Returns:
    Returns RGB verion of the given HSV image.
Note:
    Input and pre-allocated slices' strides must be identical.
*/
@nogc nothrow
Slice!(RCI!R, 3LU, SliceKind.contiguous) hsv2rgb(R, V)(Slice!(V*, 3LU, SliceKind.contiguous) input, Slice!(RCI!R, 3LU, SliceKind.contiguous) prealloc = emptyRCSlice!(3, R)) pure
        if (isNumeric!R && isNumeric!V)
in
{
    assert(input.length!2 == 3, "Invalid channel count.");
}
do
{
    if (prealloc.shape != input.shape)
        prealloc = uninitRCslice!R(input.shape);

    assert(input.strides == prealloc.strides,
            "Input image and pre-allocated buffer strides are not identical.");

    auto pack = zip!true(input.flattened.blocks(3), prealloc.flattened.blocks(3));
    pack.each!(hsv2rgbImpl!(DeepElementType!(typeof(pack))));

    return prealloc;
}

unittest
{
    // value comparison based on results from http://www.rapidtables.com/convert/color/hsv-to-rgb.htm
    auto hsv2rgbTest(HSVTypeA, RGBTypeA)(HSVTypeA hsv, RGBTypeA expectedRgb)
    {
        import mir.algorithm.iteration: equal;
        import mir.math.common: approxEqual;
        import std.traits : isIntegral;
        import std.conv : to;
        import std.math.operations : isClose;
        import mir.algorithm.iteration : all;

        alias RGBType = DeepElementType!(RGBTypeA);

        static if(isIntegral!RGBType){
            auto computed = hsv[].sliced(1, 1, 3).hsv2rgb!RGBType;
            auto expected = expectedRgb[].sliced(1, 1, 3);
            assert(zip(computed, expected).all!(pair => isClose(pair.a, pair.b, 1.0)), 
                "computed " ~ computed.to!string ~ " should be close to " ~ "expected" ~ expected.to!string);
        }else{
            assert(
                hsv[].sliced(1, 1, 3).hsv2rgb!RGBType.lightScope.equal!approxEqual(expectedRgb[].sliced(1, 1, 3)));
        }

    }

    import mir.random.variable;
    import mir.random.engine;

    auto gen = Random(unpredictableSeed);

    foreach (i; 0 .. 10)
    {
        // test any value with value of 0, should give rgb [0, 0, 0]
        hsv2rgbTest([uniformVar!ushort(0, 359)(gen), uniformVar!ushort(0, 99)(gen), 0].staticArray!(ushort,3), [0, 0, 0].staticArray!(ubyte,3));
    }

    hsv2rgbTest([0, 0, 100].staticArray!(ushort,3), [255, 255, 255].staticArray!(ubyte,3));
    hsv2rgbTest([150, 50, 100].staticArray!(ushort,3), [127, 255, 191].staticArray!(ubyte,3));
    hsv2rgbTest([150, 50, 80].staticArray!(ushort,3), [101, 203, 152].staticArray!(ubyte,3));

    hsv2rgbTest([0.0f, 0.0f, 1.0f].staticArray!(float,3), [255, 255, 255].staticArray!(ubyte,3));
    hsv2rgbTest([150.0f, 0.5f, 1.0f].staticArray!(float,3), [127, 255, 191].staticArray!(ubyte,3));
    hsv2rgbTest([150.0f, 0.5f, 0.8f].staticArray!(float,3), [102, 204, 153].staticArray!(ubyte,3));

    hsv2rgbTest([0, 0, 100].staticArray!(ushort,3), [65535, 65535, 65535].staticArray!(ushort,3));
    hsv2rgbTest([150, 50, 100].staticArray!(ushort,3), [32767, 65535, 49151].staticArray!(ushort,3));
    hsv2rgbTest([150, 50, 80].staticArray!(ushort,3), [26213, 52427, 39320].staticArray!(ushort,3));

    hsv2rgbTest([0.0f, 0.0f, 1.0f].staticArray!(float,3), [1.0f, 1.0f, 1.0f].staticArray!(float,3));
    hsv2rgbTest([150.0f, 0.5f, 1.0f].staticArray!(float,3), [0.5f, 1.0f, 0.75f].staticArray!(float,3));
    hsv2rgbTest([150.0f, 0.5f, 0.8f].staticArray!(float,3), [0.4f, 0.8f, 0.6f].staticArray!(float,3));
}

/**
Convert RGB image format to YUV.
YUV images in dcv are organized in the same buffer plane
where quantity of luma and chroma values are the same (as in
YUV444 format).
Params:
    input = Input RGB image.
    prealloc = Optional pre-allocated buffer. If given, has to be
        of same shape as input image, otherwise gets reallocated.
Returns:
    Resulting YUV image slice.
Note:
    Input and pre-allocated slices' strides must be identical.
*/
@nogc nothrow
Slice!(RCI!V, 3, SliceKind.contiguous) rgb2yuv(V)(Slice!(V*, 3, SliceKind.contiguous) input, Slice!(RCI!V, 3, SliceKind.contiguous) prealloc = emptyRCSlice!(3, V)) pure
in
{
    assert(input.length!2 == 3, "Invalid channel count.");
}
do
{
    if (prealloc.shape != input.shape)
        prealloc = uninitRCslice!V(input.shape);

    assert(input.strides == prealloc.strides,
            "Input image and pre-allocated buffer strides are not identical.");

    auto p = zip!true(input, prealloc).pack!1;
    p.each!(rgb2yuvImpl!(V, DeepElementType!(typeof(p))));

    return prealloc;
}

/**
Convert YUV image to RGB.
As in rgb2yuv conversion, YUV format is considered to have 
same amount of luma and chroma.
Params:
    input = Input YUV image.
    prealloc = Optional pre-allocated buffer. If given, has to be
        of same shape as input image, otherwise gets reallocated.
Returns:
    Resulting RGB image slice.
Note:
    Input and pre-allocated slices' strides must be identical.
*/
@nogc nothrow
Slice!(RCI!V, 3, SliceKind.contiguous) yuv2rgb(V)(Slice!(V*, 3, SliceKind.contiguous) input, Slice!(RCI!V, 3, SliceKind.contiguous) prealloc = emptyRCSlice!(3, V))
in
{
    assert(input.length!2 == 3, "Invalid channel count.");
}
do
{
    
    
    import mir.algorithm.iteration: each;

    if (prealloc.shape != input.shape)
        prealloc = uninitRCslice!V(input.shape); // uninitializedSlice!V(input.shape);

    assert(input.strides == prealloc.strides,
            "Input image and pre-allocated buffer strides are not identical.");

    auto p = zip!true(input, prealloc).pack!1;
    p.each!(yuv2rgbImpl!(V, DeepElementType!(typeof(p))));

    return prealloc;
}

unittest
{
    import mir.algorithm.iteration: equal;
    import mir.math.common: approxEqual;
    import std.traits : isIntegral;
    import std.conv : to;
    import std.math.operations : isClose;
    import mir.algorithm.iteration : all;
    // test rgb to yuv conversion
    auto rgb2yuvTest(TypeA)(TypeA rgb, TypeA expectedYuv)
    {
        auto computed = rgb[].sliced(1, 1, 3).rgb2yuv.lightScope;
        auto expected = expectedYuv[].sliced(1, 1, 3);

        assert(zip(computed, expected).all!(pair => isClose(pair.a, pair.b, 1.0)), 
                "computed " ~ computed.to!string ~ " should be equal to " ~ "expected" ~ expected.to!string);
    }

    rgb2yuvTest([0, 0, 0].staticArray!(ubyte, 3), [16, 128, 128].staticArray!(ubyte, 3));
    rgb2yuvTest([255, 0, 0].staticArray!(ubyte, 3), [82, 90, 240].staticArray!(ubyte, 3));
    rgb2yuvTest([0, 255, 0].staticArray!(ubyte, 3), [144, 54, 34].staticArray!(ubyte, 3));
    rgb2yuvTest([0, 0, 255].staticArray!(ubyte, 3), [41, 240, 110].staticArray!(ubyte, 3));
}

unittest
{   
    import mir.algorithm.iteration: equal;
    import mir.math.common: approxEqual;
    import std.traits : isIntegral;
    import std.conv : to;
    import std.math.operations : isClose;
    import mir.algorithm.iteration : all;
    
    // test yuv to rgb conversion
    auto yuv2rgbTest(Type)(Type[] yuv, Type[] expectedRgb)
    {
        auto computed = yuv.sliced(1, 1, 3).yuv2rgb;
        auto expected = expectedRgb.sliced(1, 1, 3);
        assert(zip(computed, expected).all!(pair => isClose(pair.a, pair.b, 1.0)), 
                "computed " ~ computed.to!string ~ " should be close to " ~ "expected" ~ expected.to!string);
    }

    yuv2rgbTest(cast(ubyte[])[16, 128, 128], cast(ubyte[])[0, 0, 0]);
    yuv2rgbTest(cast(ubyte[])[150, 54, 125], cast(ubyte[])[151, 187, 7]);
    yuv2rgbTest(cast(ubyte[])[144, 54, 34], cast(ubyte[])[0, 255, 0]);
    yuv2rgbTest(cast(ubyte[])[41, 240, 110], cast(ubyte[])[0, 0, 255]);
    
}

pure @nogc nothrow @fastmath:

void rgb2grayImplMean(P)(P pack)
{
    alias V = typeof(pack.b);
    pack.b = cast(V)((pack.a[0] + pack.a[1] + pack.a[2]) / 3);
}

void rgb2grayImplLuminance(RGBGRAY)(RGBGRAY pack)
{
    alias V = typeof(pack.b);
    pack.b = cast(V)(
            cast(float)pack.a[0] * 0.212642529f +
            cast(float)pack.a[1] * 0.715143029f +
            cast(float)pack.a[2] * 0.072214443f
            );
}

void bgr2grayImplLuminance(RGBGRAY)(RGBGRAY pack)
{
    alias V = typeof(pack.b);
    pack.b = cast(V)(
            cast(float)pack.a[2] * 0.212642529f +
            cast(float)pack.a[1] * 0.715143029f +
            cast(float)pack.a[0] * 0.072214443f
            );
}

void gray2rgbImpl(GRAYRGB)(GRAYRGB pack)
{
    auto v = pack.a;
    pack.b[0] = v;
    pack.b[1] = v;
    pack.b[2] = v;
}

void rgb2hsvImpl(RGBHSV)(RGBHSV pack)
{
    import mir.math.common;

    alias V = typeof(pack.a[0]);
    alias R = typeof(pack.b[0]);

    static if (is(V == ubyte))
    {
        auto r = cast(float)(pack.a[0]) * (1.0f / 255.0f);
        auto g = cast(float)(pack.a[1]) * (1.0f / 255.0f);
        auto b = cast(float)(pack.a[2]) * (1.0f / 255.0f);
    }
    else static if (is(V == ushort))
    {
        auto r = cast(float)(pack.a[0]) * (1.0f / 65535.0f);
        auto g = cast(float)(pack.a[1]) * (1.0f / 65535.0f);
        auto b = cast(float)(pack.a[2]) * (1.0f / 65535.0f);
    }
    else static if (isFloatingPoint!V)
    {
        // assumes a value range 0-1
        auto r = cast(float)(pack.a[0]);
        auto g = cast(float)(pack.a[1]);
        auto b = cast(float)(pack.a[2]);
    }
    else
    {
        static assert(0, "Invalid RGB input type: " ~ V.stringof);
    }

    auto cmax = fmax(r, fmax(g, b));
    auto cmin = fmin(r, fmin(g, b));
    auto cdelta = cmax - cmin; // TODO: compute min and max in a lockstep

    auto h = cast(R)((cdelta == 0) ? 0 : (cmax == r) ? 60.0f * ((g - b) / cdelta) : (cmax == g)
            ? 60.0f * ((b - r) / cdelta + 2) : 60.0f * ((r - g) / cdelta + 4));

    if (h < 0)
        h += 360;

    static if (isFloatingPoint!R)
    {
        auto s = cast(R)(cmax == 0 ? 0 : cdelta / cmax);
        auto v = cast(R)(cmax);
    }
    else
    {
        auto s = cast(R)(100.0f * (cmax == 0 ? 0 : cdelta / cmax));
        auto v = cast(R)(100.0f * cmax);
    }

    pack.b[0] = h;
    pack.b[1] = s;
    pack.b[2] = v;
}

void hsv2rgbImpl(HSVRGB)(HSVRGB pack)
{
    alias V = typeof(pack.a[0]);
    alias R = typeof(pack.b[0]);

    static if (isFloatingPoint!V)
    {
        auto h = pack.a[0];
        auto s = pack.a[1];
        auto v = pack.a[2];
    }
    else
    {
        float h = cast(float)pack.a[0];
        float s = cast(float)pack.a[1] * 0.01f;
        float v = cast(float)pack.a[2] * 0.01f;
    }

    if (s <= 0)
    {
        static if (isFloatingPoint!R)
        {
            pack.b[0] = cast(R)v;
            pack.b[1] = cast(R)v;
            pack.b[2] = cast(R)v;
        }
        else
        {
            pack.b[0] = cast(R)(v * R.max);
            pack.b[1] = cast(R)(v * R.max);
            pack.b[2] = cast(R)(v * R.max);
        }
        return;
    }

    if (v <= 0.0f)
    {
        pack.b[0] = cast(R)0;
        pack.b[1] = cast(R)0;
        pack.b[2] = cast(R)0;
        return;
    }

    if (h >= 360.0f)
        h = 0.0f;
    else
        h /= 60.0;

    auto hh = cast(int)h;
    auto ff = h - float(hh);

    auto p = v * (1.0f - s);
    auto q = v * (1.0f - (s * ff));
    auto t = v * (1.0f - (s * (1.0f - ff)));

    float r = void;
    float g = void;
    float b = void;

    switch (hh)
    {
    case 0:
        r = v;
        g = t;
        b = p;
        break;
    case 1:
        r = q;
        g = v;
        b = p;
        break;
    case 2:
        r = p;
        g = v;
        b = t;
        break;
    case 3:
        r = p;
        g = q;
        b = v;
        break;
    case 4:
        r = t;
        g = p;
        b = v;
        break;
    case 5:
    default:
        r = v;
        g = p;
        b = q;
        break;
    }

    static if (isFloatingPoint!R)
    {
        pack.b[0] = r;
        pack.b[1] = g;
        pack.b[2] = b;
    }
    else
    {
        pack.b[0] = cast(R)(r * R.max);
        pack.b[1] = cast(R)(g * R.max);
        pack.b[2] = cast(R)(b * R.max);
    }
}

void rgb2yuvImpl(V, RGBYUV)(RGBYUV pack)
{
    static if (isFloatingPoint!V)
    {
        auto r = cast(int)pack[0].a;
        auto g = cast(int)pack[1].a;
        auto b = cast(int)pack[2].a;
        pack[0].b = clip!V((r * .257) + (g * .504) + (b * .098) + 16);
        pack[1].b = clip!V((r * .439) + (g * .368) + (b * .071) + 128);
        pack[2].b = clip!V(-(r * .148) - (g * .291) + (b * .439) + 128);
    }
    else
    {
        auto r = pack[0].a;
        auto g = pack[1].a;
        auto b = pack[2].a;
        pack[0].b = clip!V(((66 * (r) + 129 * (g) + 25 * (b) + 128) >> 8) + 16);
        pack[1].b = clip!V(((-38 * (r) - 74 * (g) + 112 * (b) + 128) >> 8) + 128);
        pack[2].b = clip!V(((112 * (r) - 94 * (g) - 18 * (b) + 128) >> 8) + 128);
    }
}

void yuv2rgbImpl(V, YUVRGB)(YUVRGB pack) @nogc nothrow
{
    auto y = cast(int)(pack[0].a) - 16;
    auto u = cast(int)(pack[1].a) - 128;
    auto v = cast(int)(pack[2].a) - 128;
    static if (isFloatingPoint!V)
    {
        pack[0].b = clip!V(y + 1.4075 * v);
        pack[1].b = clip!V(y - 0.3455 * u - (0.7169 * v));
        pack[2].b = clip!V(y + 1.7790 * u);
    }
    else
    {
        pack[0].b = clip!V((298 * y + 409 * v + 128) >> 8);
        pack[1].b = clip!V((298 * y - 100 * u - 208 * v + 128) >> 8);
        pack[2].b = clip!V((298 * y + 516 * u + 128) >> 8);
    }
}
