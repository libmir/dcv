/**
Module for various utilities used throughout the library.
Copyright: Copyright Relja Ljubobratovic 2016.
Authors: Relja Ljubobratovic
License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.core.utils;

import std.traits;
import std.meta : allSatisfy;
import std.experimental.allocator.gc_allocator;

import mir.ndslice.slice, mir.rc;
import mir.ndslice.topology: iota, flattened;
import mir.ndslice.allocation;

/// Convenience method to return an empty slice - used mainly as default argument in functions in library.
static Slice!(V*, N, SliceKind.contiguous) emptySlice(size_t N, V)() pure @safe nothrow
{
    return Slice!(V*, N, SliceKind.contiguous)();
}

static Slice!(RCI!V, N, SliceKind.contiguous) emptyRCSlice(size_t N, V)() @nogc nothrow
{
    return Slice!(RCI!V, N, SliceKind.contiguous)();
}

package(dcv) @nogc pure nothrow
{
    /**
       Pack and unpack (N, T*) slices to (N-1, T[M]*).
    */
    auto staticPack(size_t CH, SliceKind kind, size_t N, T)(Slice!(T*, N, kind) slice)
        if (N == 3LU)
    {
        //enum N = packs[0];
        size_t[N-1] shape = slice.shape[0 .. N-1];
        T[CH]* ptr = cast(T[CH]*)slice.ptr;
        alias Ret = Slice!(T[CH]*, N-1, kind);
        return Ret(shape,  ptr);
    }

    /// ditto
    auto staticUnpack(size_t CH, SliceKind kind, size_t N, T)(Slice!(T[CH]*, N, kind) slice)
        if (N == 2LU)
    {
        size_t[N+1] shape = [slice.shape[0], slice.shape[1], CH];
        T* ptr = cast(T*)slice.ptr;
        alias Ret = Slice!(T*, N+1, kind);
        return Ret(shape, ptr);
    }

    @safe @nogc nothrow pure auto borders(Shape)(Shape shape, size_t ks)
    in
    {
        static assert(Shape.length == 2, "Non-matrix border extraction is not currently supported.");
    }
    do
    {
        import std.algorithm.comparison : max;

        static struct Range
        {
            import mir.ndslice.iterator;
            Slice!(IotaIterator!ptrdiff_t, 1LU, SliceKind.contiguous) rows;
            Slice!(IotaIterator!ptrdiff_t, 1LU, SliceKind.contiguous) cols;
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

import dplug.core;

static ThreadPool pool;

static this() @nogc nothrow {
    if(pool is null)
        pool = mallocNew!ThreadPool;
}

static ~this() @nogc nothrow {
    if(pool !is null)
        destroyFree(pool);
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
     * By input of multiple Slice!(T*, N, kind) objects, produces one Slice!(T*, N+1, kind)
     * object, where length of last dimension is number of input slices. Values
     * of input slices' elements are copied to resulting slice, where [..., i] element
     * of j-th input slice is copied to [..., i, j] element of output slice.
     * 
     * e.g. If three single channel images (Slice!(Iterator, 2, kind)) are merged, output will be 
     * a three channel image (Slice!(Iterator, 3, kind)).
     * 
     * Params:
     * slices = Input slices. All must by Slice object with same input template parameters.
     * 
     * Returns:
     * For input of n Slice!(T*, N, Contiguous) objects, outputs Slice!(T*, N+1, kind) object, where 
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
        const auto length = slices[0].elementCount;

        auto data = makeUninitSlice!(T)(GCAllocator.instance, length * slices.length);
        
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
    auto neumann(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) tensor, size_t[N] indices...)
    {
        //static assert(packs[0] == N, "Invalid index dimension");
        return tensor.bcImpl!_neumann(indices);
    }

    /// $(LINK2 https://en.wikipedia.org/wiki/Periodic_boundary_conditions,Periodic) boundary condition test
    auto periodic(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) tensor, size_t[N] indices...)
    {
        //static assert(packs[0] == N, "Invalid index dimension");
        return tensor.bcImpl!_periodic(indices);
    }

    /// Symmetric boundary condition test
    auto symmetric(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) tensor, size_t[N] indices...)
    {
        //static assert(packs[0] == N, "Invalid index dimension");
        return tensor.bcImpl!_symmetric(indices);
    }

}

/// Alias for generalized boundary condition test function.
template BoundaryConditionTest(T, size_t N, SliceKind kind)
{
    alias BoundaryConditionTest = ref T function(ref Slice!(T*, N, kind) slice, size_t[N] indices...);
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

import mir.rc: RCI;
import std.traits;
	
template ElemType(SliceType){
    static if (__traits(isSame, TemplateOf!(IteratorOf!(SliceType)), RCI)){
        alias ASeq = TemplateArgsOf!(IteratorOf!(SliceType));
        alias ElemType = ASeq[0];
    }else{
        alias PointerOf(T : T*) = T;
        alias P = IteratorOf!(SliceType);
        alias ElemType = PointerOf!P;

    }
}

/** A reduced port of std/container/dlist.d
    suitable for @nogc nothrow

    Copyright: 2010- Andrei Alexandrescu. All rights reserved by the respective holders.
    License: Distributed under the Boost Software License, Version 1.0.
    (See accompanying file LICENSE_1_0.txt or copy at $(HTTP
    boost.org/LICENSE_1_0.txt)).
*/

import std.range.primitives;
import std.traits;

import core.stdc.stdlib;

public import std.container.util;

debug int nm, nf;

T* mmalloc(T)(size_t sz){
    debug ++nm;
    return cast(T*)malloc(sz);
}

void mfree(T)(T* ptr){
    debug ++nf;
    free(cast(void*)ptr);
}

private struct BaseNode
{
    private BaseNode* _prev = null;
    private BaseNode* _next = null;

    @nogc nothrow:

    ref inout(T) getPayload(T)() inout @trusted
    {
        return (cast(inout(dlist!T.PayNode)*)&this)._payload;
    }

    static void connect(BaseNode* p, BaseNode* n) 
    {
        p._next = n;
        n._prev = p;
    }
}

private struct DRange
{

@nogc nothrow :
    private BaseNode* _first;
    private BaseNode* _last;

    private this(BaseNode* first, BaseNode* last)
    {
        _first = first;
        _last = last;
    }
    private this(BaseNode* n)
    {
        this(n, n);
    }

    @property
    bool empty() const scope
    {
        return !_first;
    }

    @property BaseNode* front() return scope
    {
        return _first;
    }

    void popFront() scope
    {
        if (_first is _last)
        {
            _first = _last = null;
        }
        else
        {
            _first = _first._next;
        }
    }

    @property BaseNode* back() return scope
    {
        return _last;
    }

    void popBack() scope
    {
        if (_first is _last)
        {
            _first = _last = null;
        }
        else
        {
            _last = _last._prev;
        }
    }

    @property DRange save() return scope { return this; }
}

struct dlist(T)
{
    struct PayNode
    {
        BaseNode _base;
        alias _base this;

        T _payload = T.init;

        @nogc nothrow:

        this (BaseNode _base, T _payload)
        {
            this._base = _base;
            this._payload = _payload;
        }

        inout(BaseNode)* asBaseNode() inout @trusted
        {
            return &_base;
        }
    }

    private BaseNode* _root;

  private
  {
    static BaseNode* createNode(Stuff)(auto ref Stuff arg, BaseNode* prev = null, BaseNode* next = null)
    {
		auto pn = mmalloc!PayNode(PayNode.sizeof);
		*pn = PayNode(BaseNode(prev, next), arg);
        return (pn).asBaseNode();
    }

    void initialize() nothrow  
    {
        if (_root) return;
		_root = (mmalloc!PayNode( PayNode.sizeof)).asBaseNode();
        _root._next = _root._prev = _root;
    }
    ref inout(BaseNode*) _first() @property  nothrow  inout
    {
        return _root._next;
    }
    ref inout(BaseNode*) _last() @property  nothrow  inout
    {
        return _root._prev;
    }
  } 

    this(U)(U[] values...) if (isImplicitlyConvertible!(U, T))
    {
        insertBack(values);
    }

    this(Stuff)(Stuff stuff)
    if (isInputRange!Stuff && isImplicitlyConvertible!(ElementType!Stuff, T))
    {
        insertBack(stuff);
    }

    bool opEquals()(ref const typeof(this) rhs) const
    if (is(typeof(front == front)))
    {
        const lhs = this;
        const lroot = lhs._root;
        const rroot = rhs._root;

        if (lroot is rroot) return true;
        if (lroot is null) return rroot is rroot._next;
        if (rroot is null) return lroot is lroot._next;

        const(BaseNode)* pl = lhs._first;
        const(BaseNode)* pr = rhs._first;
        while (true)
        {
            if (pl is lroot) return pr is rroot;
            if (pr is rroot) return false;

            // !== because of NaN
            if (!(pl.getPayload!T() == pr.getPayload!T())) return false;

            pl = pl._next;
            pr = pr._next;
        }
    }

    struct Range
    {
        static assert(isBidirectionalRange!Range);

        DRange _base;
        alias _base this;

        @nogc nothrow:

        private this(BaseNode* first, BaseNode* last)
        {
            _base = DRange(first, last);
        }
        private this(BaseNode* n)
        {
            this(n, n);
        }

        @property ref T front()
        {
            return _base.front.getPayload!T();
        }

        @property ref T back()
        {
            return _base.back.getPayload!T();
        }

        @property Range save() { return this; }
    }

    bool empty() @property const nothrow
    {
        return _root is null || _root is _first;
    }

    void clear()
    {	
        auto r = this[];

        if (r.empty){
            if(_root){
                mfree(_root);
                _root = null;
            }
            return;
        }

        BaseNode* last = null;
        do
        {
            last = r._first;
            r.popFront();
            BaseNode.connect(_root, _first._next);
            mfree(last);
        } while ( !r.empty );
        
        
        if(_root){
            mfree(_root);
            _root = null;
        }
		
    }

    @property typeof(this) dup()
    {
		typeof(this) dl;
		dl.insertBack(this[]);
        return dl;
    }

    Range opSlice()
    {
        if (empty)
            return Range(null, null);
        else
            return Range(_first, _last);
    }

    @property ref inout(T) front() inout
    {
        return _first.getPayload!T();
    }

    @property ref inout(T) back() inout
    {
        return _last.getPayload!T();
    }


/+ ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +/
/+                        BEGIN INSERT FUNCTIONS HERE                         +/
/+ ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +/

/**
Inserts `stuff` to the front/back of the container. `stuff` can be a
value convertible to `T` or a range of objects convertible to $(D
T). The stable version behaves the same, but guarantees that ranges
iterating over the container are never invalidated.
Returns: The number of elements inserted
Complexity: $(BIGOH log(n))
     */
    size_t insertFront(Stuff)(Stuff stuff)
    {
        initialize();
        return insertAfterNode(_root, stuff);
    }

    /// ditto
    size_t insertBack(Stuff)(Stuff stuff)
    {
        initialize();
        return insertBeforeNode(_root, stuff);
    }

    /// ditto
    alias insert = insertBack;

    /// ditto
    alias stableInsert = insert;

    /// ditto
    alias stableInsertFront = insertFront;

    /// ditto
    alias stableInsertBack = insertBack;

    size_t insertBefore(Stuff)(Range r, Stuff stuff)
    {
        if (r._first)
            return insertBeforeNode(r._first, stuff);
        else
        {
            initialize();
            return insertAfterNode(_root, stuff);
        }
    }

    /// ditto
    alias stableInsertBefore = insertBefore;

    /// ditto
    size_t insertAfter(Stuff)(Range r, Stuff stuff)
    {
        if (r._last)
            return insertAfterNode(r._last, stuff);
        else
        {
            initialize();
            return insertBeforeNode(_root, stuff);
        }
    }

    /// ditto
    alias stableInsertAfter = insertAfter;

    void removeFront()
    {
        debug assert(!empty, "dlist.removeFront: List is empty");
        debug assert(_root is _first._prev, "dlist: Inconsistent state");

        auto torm = _first;
        BaseNode.connect(_root, _first._next);
        mfree(torm);
    }

    void removeBack()
    {
        debug assert(!empty, "dlist.removeBack: List is empty");
        debug assert(_last._next is _root, "dlist: Inconsistent state");
        auto torm = _last;
        BaseNode.connect(_last._prev, _root);
        mfree(torm);
    }

    void popFirstOf(ref Range r)
    {
        debug assert(_root !is null, "Cannot remove from an un-initialized List");
        debug assert(r._first, "popFirstOf: Range is empty");
        auto toFree = r._first;
        auto prev = r._first._prev;
        auto next = r._first._next;
        r.popFront();
        BaseNode.connect(prev, next);
        mfree(toFree);
    }

private:
    // Helper: Inserts stuff before the node n.
    size_t insertBeforeNode(Stuff)(BaseNode* n, ref Stuff stuff)
    if (isImplicitlyConvertible!(Stuff, T))
    {
        auto p = createNode(stuff, n._prev, n);
        n._prev._next = p;
        n._prev = p;
        return 1;
    }
    // ditto
    size_t insertBeforeNode(Stuff)(BaseNode* n, ref Stuff stuff)
    if (isInputRange!Stuff && isImplicitlyConvertible!(ElementType!Stuff, T))
    {
        if (stuff.empty) return 0;
        size_t result;
        Range r = createRange(stuff, result);
        BaseNode.connect(n._prev, r._first);
        BaseNode.connect(r._last, n);
        return result;
    }

    // Helper: Inserts stuff after the node n.
    size_t insertAfterNode(Stuff)(BaseNode* n, ref Stuff stuff)
    if (isImplicitlyConvertible!(Stuff, T))
    {
        auto p = createNode(stuff, n, n._next);
        n._next._prev = p;
        n._next = p;
        return 1;
    }
    // ditto
    size_t insertAfterNode(Stuff)(BaseNode* n, ref Stuff stuff)
    if (isInputRange!Stuff && isImplicitlyConvertible!(ElementType!Stuff, T))
    {
        if (stuff.empty) return 0;
        size_t result;
        Range r = createRange(stuff, result);
        BaseNode.connect(r._last, n._next);
        BaseNode.connect(n, r._first);
        return result;
    }

    // Helper: Creates a chain of nodes from the range stuff.
    Range createRange(Stuff)(ref Stuff stuff, ref size_t result)
    {
        BaseNode* first = createNode(stuff.front);
        BaseNode* last = first;
        ++result;
        for ( stuff.popFront() ; !stuff.empty ; stuff.popFront() )
        {
            auto p = createNode(stuff.front, last);
            last = last._next = p;
            ++result;
        }
        return Range(first, last);
    }
}

private:

nothrow @nogc pure:

auto bcImpl(alias bcfunc, SliceKind kind, Iterator, size_t N)(Slice!(Iterator, N, kind ) tensor, size_t[N] indices...)
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