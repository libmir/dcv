/**
Module for various utilities used throughout the library.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.core.utils;

import std.traits;
import std.meta : allSatisfy;
import std.range : lockstep;
import std.algorithm.iteration : reduce;

import mir.ndslice;

/// Check if an type is a Slice.
enum bool isSlice(T) = is(T : Slice!(N, Range), size_t N, Range);

/// Convenience method to return an empty slice - used mainly as default argument in functions in library.
static Slice!(N, V*) emptySlice(size_t N, V)() pure @safe nothrow
{
    return Slice!(N, V*)();
}

/**
Take another typed Slice. Type conversion for the Slice object.

Params:
    inslice = Input slice, to be converted to the O type.

Returns:
    Return a slice with newly allocated data of type O, with same
    shape as input slice.
*/
static Slice!(N, O*) asType(O, V, size_t N)(Slice!(N, V*) inslice)
{
    static if (__traits(compiles, cast(O)V.init))
    {
        auto other = new O[inslice.shape.reduce!"a*b"].sliced(inslice.shape);
        foreach (e, ref a; lockstep(inslice.byElement, other.byElement))
        {
            a = cast(O)e;
        }
        return other;
    }
    else
    {
        static assert(0, "Type " ~ V.stringof ~ " is not convertible to type " ~ O.stringof ~ ".");
    }
}

unittest
{
    import std.range : iota;
    import std.array : array;

    auto slice = 6.iota.array.sliced(2, 3);
    auto fslice = slice.asType!float;
    foreach (ref s, ref f; lockstep(slice.byElement, fslice.byElement))
    {
        assert(cast(float)s == f);
    }
}

/**
Clip value by it's value range.

Params:
    v = input value, of the input type

Returns:
    Clipped value of the output type.
*/
static pure nothrow @safe T clip(T, V)(V v) if (isNumeric!V && isNumeric!T)
{
    import std.traits : isFloatingPoint;

    static if (is(T == V))
    {
        return v;
    }
    else
    {
        if (v <= T.min)
            return T.min;
        else if (v >= T.max)
            return T.max;
        return cast(T)v;
    }
}

pure nothrow @safe unittest
{
    int value = 30;
    assert(clip!int(value) == cast(int)30);
}

pure nothrow @safe unittest
{
    int max_ubyte_value = cast(int)ubyte.max + 1;
    int min_ubyte_value = cast(int)ubyte.min - 1;
    assert(clip!ubyte(max_ubyte_value) == cast(ubyte)255);
    assert(clip!ubyte(min_ubyte_value) == cast(ubyte)0);
}

import std.compiler;

static if (__VERSION__ >= 2071)
{ // due to undefined bug in byElement in dmd 2.070.0

    /**
     * Merge multiple slices into one.
     * 
     * By input of multiple Slice!(N, T*) objects, produces one Slice!(N+1, T*)
     * object, where length of last dimension is number of input slices. Values
     * of input slices' elements are copied to resulting slice, where [..., i] element
     * of j-th input slice is copied to [..., i, j] element of output slice.
     * 
     * e.g. If three single channel images (Slice!(2, T*)) are merged, output will be 
     * a three channel image (Slice!(3, T*)).
     * 
     * Params:
     * slices = Input slices. All must by Slice object with same input template parameters.
     * 
     * Returns:
     * For input of n Slice!(N, T*) objects, outputs Slice!(N+1, T*) object, where 
     * last dimension size is n.
     */
    pure auto merge(Slices...)(Slices slices)
            if (Slices.length > 0 && isSlice!(Slices[0]) && allSameType!Slices)
    {
        import std.algorithm.iteration : map;
        import std.array : uninitializedArray;

        alias ElementRange = typeof(slices[0].byElement);
        alias T = typeof(slices[0].byElement.front);

        immutable D = slices[0].shape.length;
        const auto length = slices[0].shape.reduce!"a*b";

        auto data = uninitializedArray!(T[])(length * slices.length);
        ElementRange[slices.length] elRange;

        foreach (i, v; slices)
        {
            elRange[i] = v.byElement;
        }

        auto i = 0;
        foreach (e; 0 .. length)
        {
            foreach (ecol; elRange)
            {
                data[i++] = ecol[e];
            }
        }

        size_t[D + 1] newShape;
        newShape[0 .. D] = slices[0].shape[0 .. D];
        newShape[D] = slices.length;

        return data.sliced(newShape);
    }

    version (unittest)
    {
        import std.algorithm.comparison : equal;
        import std.array : array;
    }

    unittest
    {
        auto s1 = [1, 2, 3].sliced(3);
        auto s2 = [4, 5, 6].sliced(3);
        auto m = merge(s1, s2);
        assert(m == [1, 4, 2, 5, 3, 6].sliced(3, 2));
    }

    unittest
    {
        auto s1 = [1, 2, 3, 4].sliced(2, 2);
        auto s2 = [5, 6, 7, 8].sliced(2, 2);
        auto m = merge(s1, s2);
        assert(m == [1, 5, 2, 6, 3, 7, 4, 8].sliced(2, 2, 2));
    }
}

/// Check if given function can perform boundary condition test.
template isBoundaryCondition(alias bc)
{
    import std.typetuple;

    alias Indices = TypeTuple!(int, int);
    alias bct = bc!(2, float, Indices);
    static if (isCallable!(bct) && is(Parameters!bct[0] == Slice!(2, float*))
            && is(Parameters!bct[1] == int) && is(Parameters!bct[2] == int) && is(ReturnType!bct == float))
    {
        enum bool isBoundaryCondition = true;
    }
    else
    {
        enum bool isBoundaryCondition = false;
    }
}

/// $(LINK2 https://en.wikipedia.org/wiki/Neumann_boundary_condition, Neumann) boundary condition test
ref T neumann(size_t N, T, Indices...)(ref Slice!(N, T*) slice, Indices indices)
        if (allSameType!Indices && allSatisfy!(isIntegral, Indices))
{
    static assert(indices.length == N, "Invalid index dimension");
    return slice.bcImpl!_neumann(indices);
}

/// $(LINK2 https://en.wikipedia.org/wiki/Periodic_boundary_conditions,Periodic) boundary condition test
ref T periodic(size_t N, T, Indices...)(ref Slice!(N, T*) slice, Indices indices)
        if (allSameType!Indices && allSatisfy!(isIntegral, Indices))
{
    static assert(indices.length == N, "Invalid index dimension");
    return slice.bcImpl!_periodic(indices);
}

/// Symmetric boundary condition test
ref T symmetric(size_t N, T, Indices...)(ref Slice!(N, T*) slice, Indices indices)
        if (allSameType!Indices && allSatisfy!(isIntegral, Indices))
{
    static assert(indices.length == N, "Invalid index dimension");
    return slice.bcImpl!_symmetric(indices);
}

/// Alias for generalized boundary condition test function.
template BoundaryConditionTest(size_t N, T, Indices...)
{
    alias BoundaryConditionTest = ref T function(ref Slice!(N, T*) slice, Indices indices);
}

unittest
{
    import std.range : iota;
    import std.array : array;

    assert(isBoundaryCondition!neumann);
    assert(isBoundaryCondition!periodic);
    assert(isBoundaryCondition!symmetric);

    /*
     * [0, 1, 2,
     *  3, 4, 5,
     *  6, 7, 8]
     */
    auto s = iota(9).array.sliced(3, 3);

    assert(s.neumann(-1, -1) == s[0, 0]);
    assert(s.neumann(0, -1) == s[0, 0]);
    assert(s.neumann(-1, 0) == s[0, 0]);
    assert(s.neumann(0, 0) == s[0, 0]);
    assert(s.neumann(2, 2) == s[2, 2]);
    assert(s.neumann(3, 3) == s[2, 2]);
    assert(s.neumann(1, 3) == s[1, 2]);
    assert(s.neumann(3, 1) == s[2, 1]);

    assert(s.symmetric(-1, -1) == s[1, 1]);
    assert(s.symmetric(-2, -2) == s[2, 2]);
    assert(s.symmetric(0, 0) == s[0, 0]);
    assert(s.symmetric(2, 2) == s[2, 2]);
    assert(s.symmetric(3, 3) == s[1, 1]);
}

private:

ref auto bcImpl(alias bcfunc, size_t N, T, Indices...)(ref Slice!(N, T*) slice, Indices indices)
{
    static if (N == 1)
    {
        return slice[bcfunc(cast(int)indices[0], cast(int)slice.length)];
    }
    else static if (N == 2)
    {
        return slice[bcfunc(cast(int)indices[0], cast(int)slice.length!0),
            bcfunc(cast(int)indices[1], cast(int)slice.length!1)];
    }
    else static if (N == 3)
    {
        return slice[bcfunc(cast(int)indices[0], cast(int)slice.length!0),
            bcfunc(cast(int)indices[1], cast(int)slice.length!1), bcfunc(cast(int)indices[2],
                    cast(int)slice.length!2)];
    }
    else
    {
        foreach (i, ref id; indices)
        {
            id = bcfunc(cast(int)id, cast(int)slice.shape[i]);
        }
        return slice[indices];
    }
}

int _neumann(int x, int nx)
{
    if (x < 0)
    {
        x = 0;
    }
    else if (x >= nx)
    {
        x = nx - 1;
    }

    return x;
}

int _periodic(int x, int nx)
{
    if (x < 0)
    {
        const int n = 1 - cast(int)(x / (nx + 1));
        const int ixx = x + n * nx;

        x = ixx % nx;
    }
    else if (x >= nx)
    {
        x = x % nx;
    }

    return x;
}

int _symmetric(int x, int nx)
{
    if (x < 0)
    {
        const int borde = nx - 1;
        const int xx = -x;
        const int n = cast(int)(xx / borde) % 2;

        if (n)
            x = borde - (xx % borde);
        else
            x = xx % borde;
    }
    else if (x >= nx)
    {
        const int borde = nx - 1;
        const int n = cast(int)(x / borde) % 2;

        if (n)
            x = borde - (x % borde);
        else
            x = x % borde;
    }
    return x;
}
