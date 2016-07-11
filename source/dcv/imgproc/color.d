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

import std.experimental.ndslice;

import dcv.core.utils;

import std.array : uninitializedArray;
import std.traits : CommonType, isFloatingPoint, isAssignable, isNumeric;
import std.algorithm.iteration : sum, each, reduce, map;
import std.algorithm.mutation : copy;
import std.algorithm.comparison : equal;
import std.algorithm : swap;
import std.range : zip, array, iota;
import std.parallelism : parallel;
import std.exception : enforce;
import std.range : lockstep;

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
    range = Input image range. Should have 3 channels, represented 
    as R, G and B respectivelly in that order.
    prealloc = Pre-allocated range, where grayscale image will be copied. Default
    argument is an empty slice, where new data is allocated and returned. If given 
    slice is not of corresponding shape(range.shape[0], range.shape[1]), it is 
    discarded and allocated anew.
    conv = Convertion strategy - mean, or luminance preservation.

Returns:
    Returns grayscale version of the given RGB image, of the same size.
*/
Slice!(2, V*) rgb2gray(V)(Slice!(3, V*) range, Slice!(2, V*) prealloc = emptySlice!(2, V),
        Rgb2GrayConvertion conv = Rgb2GrayConvertion.LUMINANCE_PRESERVE) pure nothrow
{

    auto m = rgb2GrayMltp[conv].map!(a => cast(real)a).array;
    m[] /= cast(real)m.sum;

    return rgb2grayImpl(range, prealloc, m);
}

unittest
{
    import std.math : approxEqual;

    auto rgb = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3].sliced(2, 2, 3);

    auto gray = rgb.rgb2gray;
    assert(equal!approxEqual(gray.byElement, [0, 1, 2, 3]));
}

/**
Convert BGR image to grayscale.

Same as rgb2gray, but follows swapped channels if luminance preservation
is chosen as convertion strategy.

Params:
    range = Input image range. Should have 3 channels, represented 
    as B, G and R respectivelly in that order.
    prealloc = Pre-allocated range, where grayscale image will be copied. Default
    argument is an empty slice, where new data is allocated and returned. If given 
    slice is not of corresponding shape(range.shape[0], range.shape[1]), it is 
    discarded and allocated anew.
    conv = Convertion strategy - mean, or luminance preservation.

Returns:
    Returns grayscale version of the given BGR image, of the same size.
*/
Slice!(2, V*) bgr2gray(V)(Slice!(3, V*) range, Slice!(2, V*) prealloc = emptySlice!(2, V),
        Rgb2GrayConvertion conv = Rgb2GrayConvertion.LUMINANCE_PRESERVE) pure nothrow
{

    auto m = rgb2GrayMltp[conv].map!(a => cast(real)a).array;
    m[] /= m.sum;
    m[0].swap(m[2]);

    return rgb2grayImpl(range, prealloc, m);
}

unittest
{
    import std.math : approxEqual;

    auto rgb = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3].sliced(2, 2, 3);

    auto gray = rgb.bgr2gray;

    assert(equal!approxEqual(gray.byElement, [0, 1, 2, 3]));
}

/**
Convert gray image to RGB.

Uses grayscale value and assigns it's value
to each of three channels for the RGB image version.

Params:
    range = Grayscale image version, to be converted to the RGB.
    prealloc = Pre-allocated range, where RGB image will be copied. Default
    argument is an empty slice, where new data is allocated and returned. If given 
    slice is not of corresponding shape(range.shape[0], range.shape[1], 3), it is 
    discarded and allocated anew.

Returns:
    Returns RGB version of the given grayscale image.
*/
Slice!(3, V*) gray2rgb(V)(Slice!(2, V*) range, Slice!(3, V*) prealloc = emptySlice!(3, V)) pure nothrow
{

    if (prealloc.empty || (range.shape[0 .. 2][]).equal(prealloc.shape[0 .. 2][]) || prealloc.shape[2] != 3)
        prealloc = uninitializedArray!(V[])(range.length!0 * range.length!1 * 3).sliced(range.length!0,
                range.length!1, 3);

    for (size_t r = 0; r < range.length!0; ++r)
    {
        for (size_t c = 0; c < range.length!1; ++c)
        {
            immutable v = range[r, c];
            prealloc[r, c, 0] = v;
            prealloc[r, c, 1] = v;
            prealloc[r, c, 2] = v;
        }
    }

    return prealloc;
}

unittest
{
    import std.math : approxEqual;

    auto gray = [0, 1, 2, 3].sliced(2, 2);

    auto rgb = gray.gray2rgb;

    assert(equal!approxEqual(rgb.byElement, [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3]));
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
    range = RGB image version, which gets converted to HVS.
    prealloc = Pre-allocated range, where HSV image will be copied. Default
    argument is an empty slice, where new data is allocated and returned. If given 
    slice is not of corresponding shape(range.shape[0], range.shape[1], 3), it is 
    discarded and allocated anew.

Returns:
    Returns HSV verion of the given RGB image.
*/
Slice!(3, R*) rgb2hsv(R, V)(Slice!(3, V*) range, Slice!(3, R*) prealloc = emptySlice!(3, R))
        if (isNumeric!R && isNumeric!V)
{
    import std.algorithm.comparison : max, min;

    static assert(R.max >= 360, "Invalid output type for HSV (R.max >= 360)");

    enforce(range.length!2 == 3, "Invalid channel count.");

    if (prealloc.empty || prealloc.shape[].equal(range.shape[]))
    {
        prealloc = uninitializedArray!(R[])(range.length!0 * range.length!1 * 3).sliced(range.length!0,
                range.length!1, 3);
    }

    foreach (rgb, hsv; lockstep(range.pack!1.byElement, prealloc.pack!1.byElement))
    {
        static if (is(V == ubyte))
        {
            auto r = cast(float)(rgb[0]) / 255.;
            auto g = cast(float)(rgb[1]) / 255.;
            auto b = cast(float)(rgb[2]) / 255.;
        }
        else static if (is(V == ushort))
        {
            auto r = cast(float)(rgb[0]) / 65535.;
            auto g = cast(float)(rgb[1]) / 65535.;
            auto b = cast(float)(rgb[2]) / 65535.;
        }
        else static if (isFloatingPoint!V)
        {
            // assumes rgb value range 0-1
            auto r = cast(float)(rgb[0]);
            auto g = cast(float)(rgb[1]);
            auto b = cast(float)(rgb[2]);
        }
        else
        {
            static assert(0, "Invalid RGB input type: " ~ V.stringof);
        }

        auto cmax = max(r, max(g, b));
        auto cmin = min(r, min(g, b));
        auto cdelta = cmax - cmin;

        hsv[0] = cast(R)((cdelta == 0) ? 0 : (cmax == r) ? 60.0f * ((g - b) / cdelta) : (cmax == g)
                ? 60.0f * ((b - r) / cdelta + 2) : 60.0f * ((r - g) / cdelta + 4));

        if (hsv[0] < 0)
            hsv[0] += 360;

        static if (isFloatingPoint!R)
        {
            hsv[1] = cast(R)(cmax == 0 ? 0 : cdelta / cmax);
            hsv[2] = cast(R)(cmax);
        }
        else
        {
            hsv[1] = cast(R)(100.0 * (cmax == 0 ? 0 : cdelta / cmax));
            hsv[2] = cast(R)(100.0 * cmax);
        }
    }
    return prealloc;
}

unittest
{
    // value comparison based on results from http://www.rapidtables.com/convert/color/rgb-to-hsv.htm
    auto rgb2hsvTest(RGBType, HSVType)(RGBType[] rgb, HSVType[] expectedHSV)
    {
        import std.algorithm.comparison : equal;
        import std.array : array;
        import std.math : approxEqual;

        assert(rgb.sliced(1, 1, 3).rgb2hsv!HSVType.byElement.array.equal!approxEqual(expectedHSV));
    }

    rgb2hsvTest(cast(ubyte[])[255, 0, 0], cast(ushort[])[0, 100, 100]);
    rgb2hsvTest(cast(ubyte[])[255, 0, 0], cast(float[])[0, 1.0f, 1.0f]); // test float result

    // test same input values as above for 16-bit and 32-bit images
    rgb2hsvTest(cast(ushort[])[ushort.max, 0, 0], cast(ushort[])[0, 100, 100]);
    rgb2hsvTest(cast(float[])[1.0f, 0, 0], cast(ushort[])[0, 100, 100]);

    rgb2hsvTest(cast(ubyte[])[0, 255, 0], cast(ushort[])[120, 100, 100]);
    rgb2hsvTest(cast(ubyte[])[0, 0, 255], cast(ushort[])[240, 100, 100]);
    rgb2hsvTest(cast(ubyte[])[122, 158, 200], cast(float[])[212, 0.39, 0.784]);
}

/**
Convert HSV image to RGB color format.

If HSV is represented in floating point, H is 0-360 degrees, S and V is 0.0-1.0. 
If it's of integral type, S and V values are in 0-100 range.

Output range values are based on the output type cast - ubyte will
range RGB values to be 0-255, ushort 0-65535, and floating types
0.0-1.0. Other types are not supported.

Params:
    range = RGB image version, which gets converted to HVS.
    prealloc = Pre-allocated range, where HSV image will be copied. Default
    argument is an empty slice, where new data is allocated and returned. If given 
    slice is not of corresponding shape(range.shape[0], range.shape[1], 3), it is 
    discarded and allocated anew.

Returns:
    Returns HSV verion of the given RGB image.
*/
Slice!(3, R*) hsv2rgb(R, V)(Slice!(3, V*) range, Slice!(3, R*) prealloc = emptySlice!(3, R))
        if (isNumeric!R && isNumeric!V)
{
    import std.math : fabs, abs;

    enforce(range.length!2 == 3, "Invalid channel count.");

    if (prealloc.empty || prealloc.shape[].equal(range.shape[]))
    {
        prealloc = uninitializedArray!(R[])(range.length!0 * range.length!1 * 3).sliced(range.length!0,
                range.length!1, 3);
    }

    float[3] _rgb;
    immutable hhswitch = [[0, 1, 2], [1, 0, 2], [2, 0, 1], [2, 1, 0], [1, 2, 0], [0, 2, 1]];

    foreach (hsv, rgb; lockstep(range.pack!1.byElement, prealloc.pack!1.byElement))
    {

        static if (isFloatingPoint!V)
        {
            auto h = hsv[0];
            auto s = hsv[1];
            auto v = hsv[2];
        }
        else
        {
            float h = cast(float)hsv[0];
            float s = cast(float)hsv[1] / 100.0;
            float v = cast(float)hsv[2] / 100.0;
        }

        float c = v * s;
        float x = c * (1. - fabs((h / 60.) % 2 - 1));
        float m = v - c;

        int hh = abs(cast(int)(h / 60.) % 6);
        _rgb = [c, x, 0.];

        static if (isFloatingPoint!R)
        {
            rgb[0] = cast(R)((_rgb[hhswitch[hh][0]] + m));
            rgb[1] = cast(R)((_rgb[hhswitch[hh][1]] + m));
            rgb[2] = cast(R)((_rgb[hhswitch[hh][2]] + m));
        }
        else static if (is(R == ubyte))
        {
            rgb[0] = cast(R)((_rgb[hhswitch[hh][0]] + m) * 255.);
            rgb[1] = cast(R)((_rgb[hhswitch[hh][1]] + m) * 255.);
            rgb[2] = cast(R)((_rgb[hhswitch[hh][2]] + m) * 255.);
        }
        else static if (is(R == ushort))
        {
            rgb[0] = cast(R)((_rgb[hhswitch[hh][0]] + m) * 65535.);
            rgb[1] = cast(R)((_rgb[hhswitch[hh][1]] + m) * 65535.);
            rgb[2] = cast(R)((_rgb[hhswitch[hh][2]] + m) * 65535.);
        }
        else
        {
            static assert(0, "Output type is not supported: " ~ R.stringof);
        }
    }
    return prealloc;
}

unittest
{
    // value comparison based on results from http://www.rapidtables.com/convert/color/hsv-to-rgb.htm
    auto hsv2rgbTest(HSVType, RGBType)(HSVType[] hsv, RGBType[] expectedRgb)
    {
        import std.algorithm.comparison : equal;
        import std.array : array;
        import std.math : approxEqual;

        assert(hsv.sliced(1, 1, 3).hsv2rgb!RGBType.byElement.array.equal!approxEqual(expectedRgb));
    }

    import std.random : uniform;

    foreach (i; 0 .. 10)
    {
        // test any value with value of 0, should give rgb [0, 0, 0]
        hsv2rgbTest(cast(ushort[])[uniform(0, 359), uniform(0, 99), 0], cast(ubyte[])[0, 0, 0]);
    }

    hsv2rgbTest(cast(ushort[])[0, 0, 100], cast(ubyte[])[255, 255, 255]);
    hsv2rgbTest(cast(ushort[])[150, 50, 100], cast(ubyte[])[128, 255, 191]);
    hsv2rgbTest(cast(ushort[])[150, 50, 80], cast(ubyte[])[102, 204, 153]);

    hsv2rgbTest(cast(float[])[0.0f, 0.0f, 1.0f], cast(ubyte[])[255, 255, 255]);
    hsv2rgbTest(cast(float[])[150.0f, 0.5f, 1.0f], cast(ubyte[])[128, 255, 191]);
    hsv2rgbTest(cast(float[])[150.0f, 0.5f, 0.8f], cast(ubyte[])[102, 204, 153]);

    hsv2rgbTest(cast(ushort[])[0, 0, 100], cast(ushort[])[65535, 65535, 65535]);
    hsv2rgbTest(cast(ushort[])[150, 50, 100], cast(ushort[])[32896, 65535, 49087]);
    hsv2rgbTest(cast(ushort[])[150, 50, 80], cast(ushort[])[26214, 52428, 39321]);

    hsv2rgbTest(cast(float[])[0.0f, 0.0f, 1.0f], cast(float[])[1.0f, 1.0f, 1.0f]);
    hsv2rgbTest(cast(float[])[150.0f, 0.5f, 1.0f], cast(float[])[0.5f, 1.0f, 0.75f]);
    hsv2rgbTest(cast(float[])[150.0f, 0.5f, 0.8f], cast(float[])[0.4f, 0.8f, 0.6f]);
}

/**
Convert RGB image format to YUV.

YUV images in dcv are organized in the same buffer plane
where quantity of luma and chroma values are the same (as in
YUV444 format).
*/
Slice!(3, V*) rgb2yuv(V)(Slice!(3, V*) range, Slice!(3, V*) prealloc = emptySlice!(3, V))
{

    enforce(range.length!2 == 3, "Invalid channel count.");

    if (prealloc.empty || prealloc.shape[].equal(range.shape[]))
    {
        prealloc = uninitializedArray!(V[])(range.length!0 * range.length!1 * 3).sliced(range.length!0,
                range.length!1, 3);
    }

    foreach (rgb, yuv; lockstep(range.pack!1.byElement, prealloc.pack!1.byElement))
    {
        static if (isFloatingPoint!V)
        {
            auto r = cast(int)rgb[0];
            auto g = cast(int)rgb[1];
            auto b = cast(int)rgb[2];
            yuv[0] = clip!V((r * .257) + (g * .504) + (b * .098) + 16);
            yuv[1] = clip!V((r * .439) + (g * .368) + (b * .071) + 128);
            yuv[2] = clip!V(-(r * .148) - (g * .291) + (b * .439) + 128);
        }
        else
        {
            auto r = rgb[0];
            auto g = rgb[1];
            auto b = rgb[2];
            yuv[0] = clip!V(((66 * (r) + 129 * (g) + 25 * (b) + 128) >> 8) + 16);
            yuv[1] = clip!V(((-38 * (r) - 74 * (g) + 112 * (b) + 128) >> 8) + 128);
            yuv[2] = clip!V(((112 * (r) - 94 * (g) - 18 * (b) + 128) >> 8) + 128);
        }
    }

    return prealloc;
}

/**
Convert YUV image to RGB.

As in rgb2yuv conversion, YUV format is considered to have 
same amount of luma and chroma.

TODO: 
    Separate input and output type as in rgb2hsv etc.
*/
Slice!(3, V*) yuv2rgb(V)(Slice!(3, V*) range, Slice!(3, V*) prealloc = emptySlice!(3, V))
{

    enforce(range.length!2 == 3, "Invalid channel count.");

    if (prealloc.empty || prealloc.shape[].equal(range.shape[]))
    {
        prealloc = uninitializedArray!(V[])(range.length!0 * range.length!1 * 3).sliced(range.length!0,
                range.length!1, 3);
    }

    foreach (yuv, rgb; lockstep(range.pack!1.byElement, prealloc.pack!1.byElement))
    {
        auto y = cast(int)(yuv[0]) - 16;
        auto u = cast(int)(yuv[1]) - 128;
        auto v = cast(int)(yuv[2]) - 128;
        static if (isFloatingPoint!V)
        {
            rgb[0] = clip!V(y + 1.4075 * v);
            rgb[1] = clip!V(y - 0.3455 * u - (0.7169 * v));
            rgb[2] = clip!V(y + 1.7790 * u);
        }
        else
        {
            rgb[0] = clip!V((298 * y + 409 * v + 128) >> 8);
            rgb[1] = clip!V((298 * y - 100 * u - 208 * v + 128) >> 8);
            rgb[2] = clip!V((298 * y + 516 * u + 128) >> 8);
        }
    }

    return prealloc;
}

unittest
{
    // test rgb to yuv conversion
    auto rgb2yuvTest(Type)(Type[] rgb, Type[] expectedYuv)
    {
        import std.algorithm.comparison : equal;
        import std.array : array;
        import std.math : approxEqual;

        assert(rgb.sliced(1, 1, 3).rgb2yuv.byElement.array.equal!approxEqual(expectedYuv));
    }

    rgb2yuvTest(cast(ubyte[])[0, 0, 0], cast(ubyte[])[16, 128, 128]);
    rgb2yuvTest(cast(ubyte[])[255, 0, 0], cast(ubyte[])[82, 90, 240]);
    rgb2yuvTest(cast(ubyte[])[0, 255, 0], cast(ubyte[])[144, 54, 34]);
    rgb2yuvTest(cast(ubyte[])[0, 0, 255], cast(ubyte[])[41, 240, 110]);
}

unittest
{
    // test yuv to rgb conversion
    auto yuv2rgbTest(Type)(Type[] yuv, Type[] expectedRgb)
    {
        import std.algorithm.comparison : equal;
        import std.array : array;
        import std.math : approxEqual;

        assert(yuv.sliced(1, 1, 3).yuv2rgb.byElement.array.equal!approxEqual(expectedRgb));
    }

    yuv2rgbTest(cast(ubyte[])[16, 128, 128], cast(ubyte[])[0, 0, 0]);
    yuv2rgbTest(cast(ubyte[])[150, 54, 125], cast(ubyte[])[151, 187, 7]);
    yuv2rgbTest(cast(ubyte[])[144, 54, 34], cast(ubyte[])[0, 255, 0]);
    yuv2rgbTest(cast(ubyte[])[41, 240, 110], cast(ubyte[])[0, 0, 255]);
}

private:

immutable real[][] rgb2GrayMltp = [[0.3333, 0.3333, 0.3333], [0.2126, 0.715, 0.0722]];

Slice!(2, V*) rgb2grayImpl(V)(Slice!(3, V*) range, Slice!(2, V*) prealloc, in real[] m) pure nothrow
{
    if (prealloc.empty)
    {
        if (!(range.shape[0 .. 2][].equal(prealloc.shape[0 .. 2][])))
            prealloc = uninitializedArray!(V[])(range.shape[0] * range.shape[1]).sliced(range.shape[0], range.shape[1]);
    }

    auto rp = range.pack!1;

    auto rows = rp.length!0;
    auto cols = rp.length!1;

    for (size_t i = 0; i < rows; ++i)
    {
        auto g_row = prealloc[i, 0 .. cols];
        auto rgb_row = rp[i, 0 .. cols];
        size_t j = 0;
        for (; j < cols; ++j)
        {
            auto rgb = rgb_row[j];
            auto v = rgb[0] * m[0] + rgb[1] * m[1] + rgb[2] * m[2];
            static if (isFloatingPoint!(typeof(v)) && !isFloatingPoint!V)
            {
                import std.math : floor;

                g_row[j] = cast(V)(v + 0.5).floor;
            }
            else
            {
                g_row[j] = cast(V)v;
            }
        }
    }

    return prealloc;
}
