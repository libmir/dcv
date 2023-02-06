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

import dcv.core.utils : dlist;
debug import dcv.core.utils : nm, nf;

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
    import std.algorithm.searching : _minIndex = minIndex, _maxIndex = maxIndex;

    auto flatIter = image.flattened;
    auto min_index = flatIter._minIndex;
    auto max_index = flatIter._maxIndex;
    return (flatIter[min_index] + flatIter[max_index] ) / 2.0;
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

    foreach(kk; 0..(array.shape[0]*array.shape[1]-2)){
        immutable r0 = kk / array.shape[1];
        immutable c0 = kk % array.shape[1];

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

Tuple!(size_t, size_t) anyInsidePoint(C)(auto ref C contour){
    import dcv.morphology.geometry : isPointInPolygon;

    immutable size_t[8] dx8 = [1, -1, 1, 0, -1,  1,  0, -1];
    immutable size_t[8] dy8 = [0,  0, 1, 1,  1, -1, -1, -1];

    foreach (i; 0..contour.shape[0]){
        auto cur = contour[i];
        Tuple!(size_t, size_t) last = tuple(cast(size_t)contour[i][0],
            cast(size_t)contour[i][1]);
        foreach(direction; 0..8){
            Tuple!(size_t, size_t) point = tuple(last[0] + dx8[direction], last[1] + dy8[direction]);
            if(!contour._contains(point) && isPointInPolygon(point, contour))
                return point;
        }
    }
    return tuple(size_t(0), size_t(0));
}

private bool _contains(C, P)(C c, P p){
    foreach (i; 0..c.shape[0]){
        auto cur = c[i];

        if((cast(size_t)cur[0] == cast(size_t)p[0]) && 
            (cast(size_t)cur[1] == cast(size_t)p[1]))
            return true;
    }
    return false;
}
