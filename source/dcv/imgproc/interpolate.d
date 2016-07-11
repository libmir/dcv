/**
Value interpolation module.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.imgproc.interpolate;
/**
 
 * 
 * v0.1 norm:
 * nn
 * linear
 * cubic
 * 
 * v0.1+:
 * lanczos?
 */

import std.range : isRandomAccessRange, ElementType;
import std.traits : isNumeric, isScalarType, isIntegral, allSameType, allSatisfy, ReturnType,
    isFloatingPoint;
import std.exception;

import std.experimental.ndslice;

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
T linear(T, size_t N, Position...)(Slice!(N, T*) slice, Position pos) pure 
        if (isNumeric!T && isScalarType!T && allSameType!Position && allSatisfy!(isNumeric, Position))
{
    // TODO: document
    static assert(N == pos.length, "Interpolation indexing has to be of same dimension as the input slice.");

    static if (pos.length == 1)
    {
        return linearImpl_1(slice, pos[0]);
    }
    else static if (pos.length == 2)
    {
        return linearImpl_2(slice, pos[0], pos[1]);
    }
    else
    {
        static assert(0, "Unsupported slice dimension for linear interpolation.");
    }
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

private:

auto linearImpl_1(T)(Slice!(1, T*) range, double pos) pure
{
    import std.math : floor;

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

auto linearImpl_2(T)(Slice!(2, T*) range, double pos_x, double pos_y) pure
{
    import std.math : floor;

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
