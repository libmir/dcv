/**
Module for various utilities used throughout the library.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.core.utils;

import std.traits;
import std.meta : allSatisfy;

import mir.ndslice.slice;
import mir.ndslice.topology: iota, flattened;


/// Convenience method to return an empty slice - used mainly as default argument in functions in library.
static Slice!(SliceKind.contiguous, packs, V*) emptySlice(size_t[] packs, V)() pure @safe nothrow
{
    return Slice!(SliceKind.contiguous, packs, V*)();
}

package(dcv) @nogc pure nothrow
{
    /**
       Pack and unpack (N, T*) slices to (N-1, T[M]*).
    */
    auto staticPack(size_t CH, SliceKind kind, size_t[] packs, T)(Slice!(kind, packs, T*) slice)
        if (packs.length == 1)
    {
        enum N = packs[0];
        size_t[N-1] shape = slice.shape[0 .. N-1];
        ptrdiff_t[N-1] strides = [slice.strides[0] / CH, slice.strides[1] / CH];
        T[CH]* ptr = cast(T[CH]*)slice._iterator;
        alias Ret = Slice!(kind, [N-1], T[CH]*);
        return Ret(shape, strides[0 .. Ret.init._strides.length], ptr);
    }

    /// ditto
    auto staticUnpack(size_t CH, SliceKind kind, size_t[] packs, T)(Slice!(kind, packs, T[CH]*) slice)
        if (packs.length == 1)
    {
        enum N = packs[0];
        size_t[N+1] shape = [slice.shape[0], slice.shape[1], CH];
        ptrdiff_t[N+1] strides = [slice.strides[0] * CH, slice.strides[1] * CH, 1];
        T* ptr = cast(T*)slice._iterator;
        alias Ret = Slice!(kind, [N+1], T*);
        return Ret(shape, strides[0 .. Ret.init._strides.length], ptr);
    }

    @safe @nogc nothrow pure auto borders(Shape)(Shape shape, size_t ks)
    in
    {
        static assert(Shape.length == 2, "Non-matrix border extraction is not currently supported.");
    }
    body
    {
        import std.algorithm.comparison : max;

        static struct Range
        {
            import mir.ndslice.iterator;
            Slice!(SliceKind.contiguous, [1], IotaIterator!ptrdiff_t) rows;
            Slice!(SliceKind.contiguous, [1], IotaIterator!ptrdiff_t) cols;
        }

        size_t kh = max(size_t(1), ks / 2);

        Range[4] borders = [
            Range(iota(shape[0]), iota(kh)),
            Range(iota(shape[0]), iota([kh], shape[1] - kh)),
            Range(iota(kh), iota(shape[1])),
            Range(iota([kh], shape[0] - kh), iota(shape[1])),
        ];

        return borders;
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
{ // due to undefined bug in flattened in dmd 2.070.0

    /**
     * Merge multiple slices into one.
     * 
     * By input of multiple Slice!(kind, [N], T*) objects, produces one Slice!(kind, [N+1], T*)
     * object, where length of last dimension is number of input slices. Values
     * of input slices' elements are copied to resulting slice, where [..., i] element
     * of j-th input slice is copied to [..., i, j] element of output slice.
     * 
     * e.g. If three single channel images (Slice!(kind, [2], Iterator)) are merged, output will be 
     * a three channel image (Slice!(kind, [3], Iterator)).
     * 
     * Params:
     * slices = Input slices. All must by Slice object with same input template parameters.
     * 
     * Returns:
     * For input of n Slice!(Contiguous, [N], T*) objects, outputs Slice!(kind, [N+1], T*) object, where 
     * last dimension size is n.
     */
    pure auto merge(Slices...)(Slices slices)
            if (Slices.length > 0 && isSlice!(Slices[0]) && allSameType!Slices)
    {
        import std.algorithm.iteration : map;
        import std.array : uninitializedArray;

        alias ElementRange = typeof(slices[0].flattened);
        alias T = typeof(slices[0].flattened.front);

        immutable D = slices[0].shape.length;
        const auto length = slices[0].elementsCount;

        auto data = uninitializedArray!(T[])(length * slices.length);
        ElementRange[slices.length] elRange;

        foreach (i, v; slices)
        {
            elRange[i] = v.flattened;
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
    enum bool isBoundaryCondition = true;
}

nothrow @nogc pure
{

    /// $(LINK2 https://en.wikipedia.org/wiki/Neumann_boundary_condition, Neumann) boundary condition test
    auto neumann(SliceKind kind, size_t[] packs, Iterator, size_t N)(Slice!(kind, packs, Iterator) tensor, size_t[N] indices...)
    {
        static assert(packs[0] == N, "Invalid index dimension");
        return tensor.bcImpl!_neumann(indices);
    }

    /// $(LINK2 https://en.wikipedia.org/wiki/Periodic_boundary_conditions,Periodic) boundary condition test
    auto periodic(SliceKind kind, size_t[] packs, Iterator, size_t N)(Slice!(kind, packs, Iterator) tensor, size_t[N] indices...)
    {
        static assert(packs[0] == N, "Invalid index dimension");
        return tensor.bcImpl!_periodic(indices);
    }

    /// Symmetric boundary condition test
    auto symmetric(SliceKind kind, size_t[] packs, Iterator, size_t N)(Slice!(kind, packs, Iterator) tensor, size_t[N] indices...)
    {
        static assert(packs[0] == N, "Invalid index dimension");
        return tensor.bcImpl!_symmetric(indices);
    }

}

/// Alias for generalized boundary condition test function.
template BoundaryConditionTest(SliceKind kind, size_t[] packs, T, size_t N)
{
    alias BoundaryConditionTest = ref T function(ref Slice!(kind, packs, T*) slice, size_t[N] indices...);
}

unittest
{
    import mir.ndslice.allocation;

    static assert(isBoundaryCondition!neumann);
    static assert(isBoundaryCondition!periodic);
    static assert(isBoundaryCondition!symmetric);

    /*
     * [0, 1, 2,
     *  3, 4, 5,
     *  6, 7, 8]
     */
    auto s = iota(3, 3).slice;

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

nothrow @nogc pure:

auto bcImpl(alias bcfunc, SliceKind kind, size_t[] packs, Iterator, size_t N)(Slice!(kind, packs, Iterator) tensor, size_t[N] indices...)
{
    static if (N == 1)
    {
        return tensor[bcfunc(cast(int)indices[0], cast(int)tensor.length)];
    }
    else static if (N == 2)
    {
        return tensor[bcfunc(cast(int)indices[0], cast(int)tensor.length!0),
            bcfunc(cast(int)indices[1], cast(int)tensor.length!1)];
    }
    else static if (N == 3)
    {
        return tensor[bcfunc(cast(int)indices[0], cast(int)tensor.length!0),
            bcfunc(cast(int)indices[1], cast(int)tensor.length!1), bcfunc(cast(int)indices[2],
                    cast(int)tensor.length!2)];
    }
    else
    {
        foreach (i, ref id; indices)
        {
            id = bcfunc(cast(int)id, cast(int)tensor._lengths[i]);
        }
        return tensor[indices];
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
