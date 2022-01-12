/*
Copyright (c) 2021- Ferhat Kurtulmuş
Boost Software License - Version 1.0 - August 17th, 2003
*/
module dcv.measure.contours;

import std.typecons: Tuple, tuple;
import std.math;
debug import std.stdio;
import core.lifetime: move;

import mir.ndslice;
import mir.rc;

import bcaa;

// based on https://github.com/scikit-image/scikit-image/blob/main/skimage/measure/_find_contours.py

struct Point {
    double x, y;
}

struct Rectangle {
    size_t x;
    size_t y;
    size_t width;
    size_t height;
}

alias BoundingBox = Rectangle;

@nogc nothrow:

/** Find iso-valued contours in a 2D array for a given level value.

Params:
    image = Input binary image of ubyte (0 for background). Agnostic to SliceKind

Returns RCArray!Slice!(RCI!double, 2LU, Contiguous): a refcounted array of Contours
*/
RCArray!Contour findContours(InputType)(auto ref InputType image, double level = defaultLevel, bool fullyConnected = true)
{
    if (level == -1.0)
        level = _defaultLevel(image);
    
    auto segments = _get_contour_segments(image.as!double, level, fullyConnected);
    auto contours = _assemble_contours(segments);

    return contours;
}

private enum defaultLevel = -1.0;

private double _defaultLevel(InputType)(auto ref InputType image)
{
    auto min_index = image.minIndex;
    auto max_index = image.maxIndex;
    return (image[min_index[0], min_index[1]] + image[max_index[0], max_index[1]] ) / 2.0;
}

pragma(inline, true)
private double _get_fraction(double from_value, double to_value, double level)
{
    if (to_value == from_value)
        return 0;
    return ((level - from_value) / (to_value - from_value));
}

private auto _get_contour_segments(InputType)
(
    InputType array,
    double level,
    bool vertex_connect_high)
{

    import mir.appender;

    alias TPP = Tuple!(Point, Point);

    auto segments = scopedBuffer!TPP;

    ubyte square_case = 0;
    Point top, bottom, left, right;
    double ul, ur, ll, lr;
    size_t r1, c1;

    foreach(r0; 0 .. array.shape[0] - 1){
        foreach(c0; 0 .. array.shape[1] - 1){
            r1 = r0 + 1;
            c1 = c0 + 1;

            ul = array[r0, c0];
            ur = array[r0, c1];
            ll = array[r1, c0];
            lr = array[r1, c1];

            square_case = 0;
            if (ul > level) square_case += 1;
            if (ur > level) square_case += 2;
            if (ll > level) square_case += 4;
            if (lr > level) square_case += 8;

            if ((square_case == 0) || (square_case == 15))
                // only do anything if there's a line passing through the
                // square. Cases 0 and 15 are entirely below/above the contour.
                continue;

            top = Point(r0, c0 + _get_fraction(ul, ur, level));
            bottom = Point(r1, c0 + _get_fraction(ll, lr, level));
            left = Point(r0 + _get_fraction(ul, ll, level), c0);
            right = Point(r0 + _get_fraction(ur, lr, level), c1);

            if (square_case == 1)
                // top to left
                segments.put(tuple(top, left));
            else if (square_case == 2)
                // right to top
                segments.put(tuple(right, top));
            else if (square_case == 3)
                // right to left
                segments.put(tuple(right, left));
            else if (square_case == 4)
                // left to bottom
                segments.put(tuple(left, bottom));
            else if (square_case == 5)
                // top to bottom
                segments.put(tuple(top, bottom));
            else if (square_case == 6){
                if (vertex_connect_high){
                    segments.put(tuple(left, top));
                    segments.put(tuple(right, bottom));
                }else{
                    segments.put(tuple(right, top));
                    segments.put(tuple(left, bottom));
                }
            }
            else if (square_case == 7)
                // right to bottom
                segments.put(tuple(right, bottom));
            else if (square_case == 8)
                // bottom to right
                segments.put(tuple(bottom, right));
            else if (square_case == 9){
                if (vertex_connect_high){
                    segments.put(tuple(top, right));
                    segments.put(tuple(bottom, left));
                }else{
                    segments.put(tuple(top, left));
                    segments.put(tuple(bottom, right));
                }
            }
            else if (square_case == 10)
                // bottom to top
                segments.put(tuple(bottom, top));
            else if (square_case == 11)
                // bottom to left
                segments.put(tuple(bottom, left));
            else if (square_case == 12)
                // lef to right
                segments.put(tuple(left, right));
            else if (square_case == 13)
                // top to right
                segments.put(tuple(top, right));
            else if (square_case == 14)
                // left to top
                segments.put(tuple(left, top));
        }
    }

    auto ret = RCArray!Point(segments.length * 2);
    ret.ptr[0..segments.length*2] = (cast(Point*)segments.data[].ptr)[0..segments.length * 2];

    return ret;
}

private auto _assemble_contours(Segments)(auto ref Segments segments){ 
    import std.algorithm.comparison : equal;
    import mir.ndslice: chunks;

    debug nm = nf = 0;

    size_t current_index = 0;
    
    alias DLP = dlist!(Point);
    
    Bcaa!(size_t, DLP) contours;
    
    Bcaa!(Point, Tuple!(DLP, size_t)) starts;
    Bcaa!(Point, Tuple!(DLP, size_t)) ends;

    scope(exit){
        starts.free;
        ends.free;
        contours.free;
    }
    
    foreach(elem; segments.asSlice.chunks(2)){
        Point from_point = elem[0];
        Point to_point = elem[1];

        // Ignore degenerate segments.
        // This happens when (and only when) one vertex of the square is
        // exactly the contour level, and the rest are above or below.
        // This degenerate vertex will be picked up later by neighboring
        // squares.
        if (from_point == to_point)
            continue;
        
        DLP tail;
        size_t tail_num;
        
        if (auto tuptail = to_point in starts){
            tail = (*tuptail)[0];
            tail_num = (*tuptail)[1];
            starts.remove(to_point);
        }

        DLP head;
        size_t head_num;
        
        if (auto tuphead = from_point in ends){
            head = (*tuphead)[0];
            head_num = (*tuphead)[1];
            ends.remove(from_point);
        }

        if ((!tail.empty) && (!head.empty)){
            // We need to connect these two contours.
            if (tail[].equal(head[])){
                // We need to closed a contour: add the end point
                head.insertBack(to_point);
            }
            else{  // tail is not head
                // We need to join two distinct contours.
                // We want to keep the first contour segment created, so that
                // the final contours are ordered left->right, top->bottom.
                if (tail_num > head_num){
                    // tail was created second. Append tail to head.
                    head.insertBack(tail[]);
                    // Remove tail from the detected contours
                    contours[tail_num].clear;
                    contours.remove(tail_num);
                    // Update starts and ends
                    starts[head[].front] = tuple(head, head_num);
                    ends[head[].back] = tuple(head, head_num);
                }else{  // tail_num <= head_num 
                    // head was created second. Prepend head to tail.
                    
                    tail.insertFront(head[]);
                    
                    // Remove head from the detected contours
                    starts.remove(head[].front); // head[0] can be == to_point!

                    contours[head_num].clear;
                    contours.remove(head_num);
                    // Update starts and ends
                    starts[tail[].front] = tuple(tail, tail_num);
                    ends[tail[].back] = tuple(tail, tail_num);
                    
                }
            }
        }
        else if((tail.empty) && (head.empty)) {
            // We need to add a new contour
            DLP new_contour = DLP(from_point, to_point);
            if(auto eptr = current_index in contours){
                (*eptr).insertBack(new_contour[]);
            }else{
                contours[current_index] = new_contour;
            }
            
            starts[from_point] = tuple(new_contour, current_index);
            ends[to_point] = tuple(new_contour, current_index);
            current_index ++;
        }
        else if(head.empty){  // tail is not None
            // tail first element is to_point: the new segment should be
            // prepended.
            tail.insertFront(from_point);
            
            // Update starts
            starts[from_point] = tuple(tail, tail_num);
        } else {
            // tail is None and head is not None:
            // head last element is from_point: the new segment should be
            // appended
            head.insertBack(to_point);
            // Update ends
            ends[to_point] = tuple(head, head_num);
        }
    }

    debug assert(starts.length == 0 && ends.length == 0, "Unexpected segment state");
    
    import mir.ndslice.sorting : sort;

    auto cts = RCArray!Contour(contours.length);
    size_t i;
    
    auto _keys = contours.byKey.rcarray.asSlice.sort;
    
    foreach (k; _keys)
    {
        auto tmp = contours[k];
        auto _c = tmp[].rcarray!Point;
        auto len = _c.length;
        Contour ctr = uninitRCslice!(double)(len, 2);
        
        ctr._iterator[0..len*2][] = (cast(double*)_c.ptr)[0..len*2];
        
        cts[i++] = ctr;
        tmp.clear;
    }

    debug assert( nm == nf, "Memory leaks here!");

    return cts.move;
}

alias Contour = Slice!(RCI!double, 2LU, Contiguous);

auto contours2image(RCArray!Contour contours, size_t rows, size_t cols)
{

    Slice!(RCI!ubyte, 2LU, Contiguous) cimg = uninitRCslice!ubyte(rows, cols);
    cimg[] = 0;

    contours[].each!((cntr){ // TODO: parallelizm here?
        foreach(p; cntr){
            cimg[cast(size_t)p[0], cast(size_t)p[1]] = 255;
        }
    });

    return cimg.move;
}

double contourArea(C)(auto ref C contour)
{
    
    auto xx = contour[0..$, 0];
    auto yy = contour[0..$, 1];

    immutable npoints = contour.shape[0];
    
    double area = 0.0;
    
    foreach(i; 0..npoints){
        auto j = (i + 1) % npoints;
        area += xx[i] * yy[j];
        area -= xx[j] * yy[i];
    }
    area = abs(area) / 2.0;
    return area;
}

double arcLength(C)(auto ref C contour)
{
    auto xx = contour[0..$, 0];
    auto yy = contour[0..$, 1];
    
    double perimeter = 0.0, xDiff = 0.0, yDiff = 0.0;
    for( auto k = 0; k < xx.length-1; k++ ) {
        xDiff = xx[k+1] - xx[k];
        yDiff = yy[k+1] - yy[k];
        perimeter += pow( xDiff*xDiff + yDiff*yDiff, 0.5 );
    }
    xDiff = xx[xx.length-1] - xx[0];
    yDiff = yy[yy.length-1] - yy[0];
    perimeter += pow( xDiff*xDiff + yDiff*yDiff, 0.5 );
    
    return perimeter;
}

auto colMax(S)(auto ref S x, size_t i)
{
    return x[x[0..$, i].maxIndex[0], i];
}

auto colMin(S)(auto ref S x, size_t i)
{
    return x[x[0..$, i].minIndex[0], i];
}

BoundingBox boundingBox(C)(C contour)
{
    import std.math;

    auto xMax = cast(size_t)contour.colMax(0).round;
    auto yMax = cast(size_t)contour.colMax(1).round;

    auto xMin = cast(size_t)contour.colMin(0).round;
    auto yMin = cast(size_t)contour.colMin(1).round;

    return BoundingBox(xMin, yMin, xMax - xMin + 1, yMax - yMin + 1);


}

private:

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
    import std.range : Take;

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

    bool opEquals()(ref const DList rhs) const
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
        if (r.empty)
            return;

        BaseNode* last = null;
        do
        {
            last = r._first;
            mfree(last);
            r.popFront();
        } while ( !r.empty );

        mfree(_root);
        _root = null;
        
    }

    @property dlist dup()
    {
        return dlist(this[]);
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
