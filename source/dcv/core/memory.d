/**
Module introduces memory management utilities to help manage memory for SIMD compatible arrays,
with or without use of GC.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.core.memory;

import core.simd;
import core.memory;
import core.cpuid;

import std.experimental.allocator.mallocator : AlignedMallocator, Mallocator;

/**
Allocate array using strict memory alignment.

Uses std.experimental.allocator.mallocator.AlignmedMallocator to 
allocate memory. 

params:
count = Count of elements to be allocated for the array.
alignment = size in bytes for memory alignment pattern.

returns:
Dynamic array of type T, with lenght of given count, aligned using
given alignment size.

note:
Dynamic array is not added to GC, so it has to be destoyed explicitly
using alignedFree. If GC is needed, use alignedAllocGC.
 */
@nogc @trusted T[] alignedAlloc(T)(size_t count, uint alignment = 16)
{
    auto buff = AlignedMallocator.instance.alignedAllocate(count * T.sizeof, alignment);
    return (cast(T*)buff)[0 .. count][];
}

/**
Allocate array using strict memory alignment.

Uses std.experimental.allocator.mallocator.AlignmedMallocator to 
reallocate memory. 
Forwards to AlignedMallocator.reallocate.

params:
ptr = Pointer to a memory where the reallocation is to be performed at.
newSize = Size of the reallocated array.

returns:
Status of reallocation. Returns AlignedMallocator.reallocate out status.
*/
@nogc bool alignedRealloc(ref void[] ptr, size_t newSize)
{
    return AlignedMallocator.instance.reallocate(ptr, newSize);
}

/**
Frees memory allocated using alignedAlloc function.

Uses AlignedMallocator.deallocate.

params:
ptr = Pointer to memory that is to be freed.
*/
void alignedFree(void[] ptr) @nogc
{
    AlignedMallocator.instance.deallocate(ptr);
}

version (skipSIMD)
{
    T[] allocArray(T)(size_t length)
    {
        return new T[length];
    }

    void freeArray(void[] ptr) @nogc
    {
        ptr.destroy;
    }
}
else
{
    T[] allocArray(T)(size_t length) @trusted @nogc
    {
        return alignedAlloc!T(length, 16);
    }

    void freeArray(void[] ptr) @nogc
    {
        ptr.alignedFree;
    }
}

unittest
{
    // TODO: design the test...

    import mir.ndslice;

    int[] arr = allocArray!int(3);
    scope (exit)
        arr.freeArray;

    auto slice = arr.sliced(3);
    assert(&arr[0] == &slice[0]);
}

/**
 * Template to get alias to SSE2 compatible vector for given type.
 */
template VectorSSE2(T)
{
    import std.traits : isNumeric;

    static assert(isNumeric!T, "SIMD vector has to be composed of numberic type");
    static if (is(T == ubyte))
    {
        alias VectorSSE2 = ubyte16;
    }
    else static if (is(T == ushort))
    {
        alias VectorSSE2 = ushort8;
    }
    else static if (is(T == uint))
    {
        alias VectorSSE2 = uint4;
    }
    else static if (is(T == ulong))
    {
        alias VectorSSE2 = ulong2;
    }
    else static if (is(T == byte))
    {
        alias VectorSSE2 = byte16;
    }
    else static if (is(T == short))
    {
        alias VectorSSE2 = short8;
    }
    else static if (is(T == int))
    {
        alias VectorSSE2 = int4;
    }
    else static if (is(T == long))
    {
        alias VectorSSE2 = long2;
    }
    else static if (is(T == float))
    {
        alias VectorSSE2 = float4;
    }
    else static if (is(T == double))
    {
        alias VectorSSE2 = double2;
    }
    else
    {
        alias VectorSSE2 = void;
    }
}

/**
 * Template to get alias to AVX compatible vector for given type.
 */
template VectorAVX(T)
{
    import std.traits : isNumeric;

    static assert(isNumeric!T, "SIMD vector has to be composed of numberic type");
    static if (is(T == ubyte))
    {
        alias VectorAVX = ubyte32;
    }
    else static if (is(T == ushort))
    {
        alias VectorAVX = ushort16;
    }
    else static if (is(T == uint))
    {
        alias VectorAVX = uint8;
    }
    else static if (is(T == ulong))
    {
        alias VectorAVX = ulong4;
    }
    else static if (is(T == byte))
    {
        alias VectorAVX = byte32;
    }
    else static if (is(T == short))
    {
        alias VectorAVX = short16;
    }
    else static if (is(T == int))
    {
        alias VectorAVX = int8;
    }
    else static if (is(T == long))
    {
        alias VectorAVX = long4;
    }
    else static if (is(T == float))
    {
        alias VectorAVX = float8;
    }
    else static if (is(T == double))
    {
        alias VectorAVX = double4;
    }
    else
    {
        alias VectorAVX = void;
    }
}

enum size_t vectorSize(T) = T.init.length;