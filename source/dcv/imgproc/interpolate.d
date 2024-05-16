/**
Value interpolation module.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.imgproc.interpolate;

import std.traits : isNumeric, isScalarType, isIntegral, allSameType, ReturnType,
    isFloatingPoint, Unqual;
import std.meta : allSatisfy;

import mir.math.common : fastmath;

import mir.ndslice.slice;


/**
Test if given function is proper form for interpolation.
*/
static bool isInterpolationFunc(alias F)()
{
    auto s = [0., 1.].sliced(2);
    return (__traits(compiles, F(s, 0))); // TODO: check the return type?
}

/**
Test for 1D (vector) interpolation function.
*/
static bool isInterpolationFunc1D(alias F)()
{
    return isInterpolationFunc!F;
}

/**
Test for 2D (matrix) interpolation function.
*/
static bool isInterpolationFunc2D(alias F)()
{
    auto s = [0, 1, 2, 3].sliced(2, 2);
    return (__traits(compiles, F(s, 3, 3)));
}

unittest
{
    static assert(isInterpolationFunc!linear);
    static assert(isInterpolationFunc1D!linear);
    static assert(isInterpolationFunc2D!linear);
}

/**
Linear interpolation.

Params:
    slice = Input slice which values are interpolated.
    pos = Position on which slice values are interpolated.

Returns:
    Interpolated resulting value.
*/
pure auto linear(P, SliceType)(SliceType slice, P pos0)
if(SliceType.N == 1)
{
    // TODO: document
    //static assert(N == packs[0], "Interpolation indexing has to be of same dimension as the input slice.");

    return linearImpl_1(slice, cast(double)pos0);
}

pure auto linear(P, SliceType)(SliceType slice, P pos0, P pos1)
if(SliceType.N == 2)
{
    // TODO: document
    //static assert(N == packs[0], "Interpolation indexing has to be of same dimension as the input slice.");

    return linearImpl_2(slice, cast(double)pos0, cast(double)pos1);
}

unittest
{
    auto arr1 = [0., 1.].sliced(2);
    assert(linear(arr1, 0.) == 0.);
    assert(linear(arr1, 1.) == 1.);
    assert(linear(arr1, 0.1) == 0.1);
    assert(linear(arr1, 0.5) == 0.5);
    assert(linear(arr1, 0.9) == 0.9);

    auto arr1_integral = [0, 10].sliced(2);
    assert(linear(arr1_integral, 0.) == 0);
    assert(linear(arr1_integral, 1.) == 10);
    assert(linear(arr1_integral, 0.1) == 1);
    assert(linear(arr1_integral, 0.5) == 5);
    assert(linear(arr1_integral, 0.9) == 9);

    auto arr2 = [0., 0., 0., 1.].sliced(2, 2);
    assert(arr2.linear(0.5, 0.5) == 0.25);
    assert(arr2.linear(0., 0.) == 0.);
    assert(arr2.linear(1., 1.) == 1.);
    assert(arr2.linear(1., 0.) == 0.);
}

/**
Bilinear interpolation.

Params:
    slice = Input slice which values are interpolated.
    pos = Position on which slice values are interpolated.

Returns:
    Interpolated resulting value.
*/
pure auto bilinear(P, SliceType)(SliceType slice, P pos)
if(SliceType.N == 1)
{
    // TODO: document
    //static assert(N == packs[0], "Interpolation indexing has to be of same dimension as the input slice.");

    return bilinear_interpolate_Impl1(slice, pos);

}

pure auto bilinear(P, SliceType)(SliceType slice, P pos0, P pos1)
if(SliceType.N == 2)
{
    // TODO: document
    //static assert(N == packs[0], "Interpolation indexing has to be of same dimension as the input slice.");
    return bilinear_interpolate_Impl2(slice, pos0, pos1);

}

/**
Nearest neighbor interpolation.

Params:
    slice = Input slice which values are interpolated.
    pos = Position on which slice values are interpolated.

Returns:
    Interpolated resulting value.
*/
pure auto nearestNeighbor(P, SliceType)(SliceType slice, P pos)
if(SliceType.N == 1)
{
    // TODO: document
    //static assert(N == packs[0], "Interpolation indexing has to be of same dimension as the input slice.");

    return nn_interpolate_Impl1(slice, pos);
}

pure auto nearestNeighbor(P, SliceType)(SliceType slice, P pos0, P pos1)
if(SliceType.N == 2)
{
    // TODO: document
    //static assert(N == packs[0], "Interpolation indexing has to be of same dimension as the input slice.");

    return nn_interpolate_Impl2(slice, pos0, pos1);
}

private:

pure @fastmath auto linearImpl_1(SliceType)(SliceType range, double pos)
{
    import mir.math.common;

    alias T = Unqual!(DeepElementType!range);

    assert(pos < range.length);

    if (pos == range.length - 1)
    {
        return range[$ - 1];
    }

    size_t round = cast(size_t)pos.floor;
    double weight = pos - cast(double)round;

    static if (isIntegral!T)
    {
        // TODO: is this branch really necessary?
        auto v1 = cast(double)range[round];
        auto v2 = cast(double)range[round + 1];
    }
    else
    {
        auto v1 = range[round];
        auto v2 = range[round + 1];
    }
    return cast(T)(v1 * (1. - weight) + v2 * (weight));
}

pure @fastmath auto linearImpl_2(SliceType)(SliceType range, double pos_x, double pos_y)
{
    import mir.math.common : floor;

    alias T = Unqual!(DeepElementType!SliceType);

    assert(pos_x < range.length!0 && pos_y < range.length!1);

    size_t rx = cast(size_t)pos_x.floor;
    size_t ry = cast(size_t)pos_y.floor;
    double wx = pos_x - cast(double)rx;
    double wy = pos_y - cast(double)ry;

    auto w00 = (1. - wx) * (1. - wy);
    auto w01 = (wx) * (1. - wy);
    auto w10 = (1. - wx) * (wy);
    auto w11 = (wx) * (wy);

    auto x_end = rx == range.length!0 - 1;
    auto y_end = ry == range.length!1 - 1;

    static if (isIntegral!T)
    {
        // TODO: (same as in 1D vesion) is this branch really necessary?
        double v1, v2, v3, v4;
        v1 = cast(double)range[rx, ry];
        v2 = cast(double)range[x_end ? rx : rx + 1, ry];
        v3 = cast(double)range[rx, y_end ? ry : ry + 1];
        v4 = cast(double)range[x_end ? rx : rx + 1, y_end ? ry : ry + 1];
    }
    else
    {
        T v1, v2, v3, v4;
        v1 = range[rx, ry];
        v2 = range[x_end ? rx : rx + 1, ry];
        v3 = range[rx, y_end ? ry : ry + 1];
        v4 = range[x_end ? rx : rx + 1, y_end ? ry : ry + 1];
    }
    return cast(T)(v1 * w00 + v2 * w01 + v3 * w10 + v4 * w11);
}

package {
    pragma(inline, true)
    pure auto getPixel(S, I)(const ref S s, I row, I col, I ch = 0){
        auto yy = row;
        auto xx = col;
        if (xx < 0)
            xx = 0;
        if (xx >= s.shape[1])
            xx = cast(int)s.shape[1] - 1;
        if (yy < 0)
            yy = 0;
        if (yy >= s.shape[0])
            yy = cast(int)s.shape[0] - 1;

        static if (s.N==2){
            return s[yy, xx];
        }else{
            return s[yy, xx, ch];
        }
    }

    pragma(inline, true)
    pure auto getValue(S, I)(const ref S s, I pos){
        if (pos < 0)
            pos = 0;
        if (pos >= s.shape[0])
            pos = cast(int)s.shape[0] - 1;
        return s[pos];
    }
}

pure @fastmath auto bilinear_interpolate_Impl1(SliceType)(SliceType range, double pos)
{
    import std.math : floor;

    alias T = Unqual!(DeepElementType!range);

    float p1, p2;
    size_t x_floor = cast(size_t)pos.floor;
    size_t x_ceil = x_floor + 1;
    p1 = range.getValue(x_floor);
    p2 = range.getValue(x_ceil);
    double weight = pos - cast(double)x_floor;
    return cast(T)(p1 * (1. - weight) + p2 * weight);
}

pure @fastmath auto bilinear_interpolate_Impl2(SliceType)(SliceType range, double pos_x, double pos_y)
{
    import mir.math.common : floor;
    
    alias T = Unqual!(DeepElementType!SliceType);

    float p1, p2, p3, p4, q1, q2;
    int rx = cast(int)pos_x.floor;
    int ry = cast(int)pos_y.floor;
    int rx_next = rx + 1;
    int ry_next = ry + 1;
    p1 = range.getPixel(rx, ry);
    p2 = range.getPixel(rx_next, ry);
    p3 = range.getPixel(rx, ry_next);
    p4 = range.getPixel(rx_next, ry_next);
    float wx = pos_x - cast(float)rx;
    float wy = pos_y - cast(float)ry;
    q1 = (1.0f - wx) * p1 + wx * p2;
    q2 = (1.0f - wx) * p3 + wx * p4;
    return cast(T)((1.0f - wy) * q1 + wy * q2);
}

pure @fastmath auto nn_interpolate_Impl1(SliceType)(SliceType range, double pos)
{
    import mir.math.common : round;
    alias T = Unqual!(DeepElementType!(SliceType));
    return cast(T)range.getValue(cast(size_t)round(pos));
}

pure @fastmath auto nn_interpolate_Impl2(SliceType)(SliceType range, double pos_x, double pos_y)
{
    import mir.math.common : round;
    alias T = Unqual!(DeepElementType!(SliceType));
    return cast(T)range.getPixel(cast(size_t)round(pos_x), cast(size_t)round(pos_y));
}