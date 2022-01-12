/*
Copyright (c) 2021- Ferhat Kurtulmuş
Boost Software License - Version 1.0 - August 17th, 2003
*/
module dcv.measure.convexhull;

import std.math;

import mir.ndslice.sorting: sort;
import mir.ndslice;
import mir.rc;
import mir.appender;

/** return indices of convex hull or points based on the template param of indices_only = true/false
Params:
    points = n x 2 points (Slice).

*/
auto convexHull(alias indices_only = true, PTSlice)(PTSlice points) @nogc nothrow {

    //assert( n >= 3, "Convex hull not possible");
    
    import std.range: chain;

    const n = points.length!0;

    struct Coord {
        double x, y;

        size_t index;

        int opCmp(Coord rhs) @nogc nothrow {
            if (x < rhs.x) return -1;
            if (rhs.x < x) return 1;
            return 0;
        }
    }
    auto _p = RCArray!Coord(n);
    
    foreach(i; 0..n)
        _p[i] = Coord(cast(double)points[i, 0], cast(double)points[i, 1], i);
    
    
    import std.algorithm.sorting : ssort = sort;
    auto p = _p[].ssort;
    
    auto upper_pts = scopedBuffer!Coord;
    upper_pts.put(p[0]); upper_pts.put(p[1]);
    
    foreach (i; 2..n){
        upper_pts.put(p[i]);
        while ((upper_pts.length > 2) && 
            !rightTurn(upper_pts.data[$ - 1], upper_pts.data[$ - 2], upper_pts.data[$ - 3])){
            Coord tmp = upper_pts.data[$-1];
            upper_pts.popBackN(2);
            upper_pts.put(tmp);
        }
    }
    
    auto lower_pts = scopedBuffer!Coord;
    lower_pts.put(p[$ - 1]); lower_pts.put(p[$ - 2]);
    
    foreach_reverse (i; 0..(n - 2)){
        lower_pts.put(p[i]);
        while ((lower_pts.length > 2) && !rightTurn(lower_pts.data[$ - 1], lower_pts.data[$ - 2], lower_pts.data[$ - 3])){
            Coord tmp = lower_pts.data[$-1];
            lower_pts.popBackN(2);
            lower_pts.put(tmp);
        }
    }
    
    auto lower = lower_pts.data[1 .. $-1];

    static if(indices_only){
        RCArray!size_t hull_indices = RCArray!size_t(lower.length + upper_pts.length); // returning indices are of size_t
        size_t i;
        foreach (hp; chain(upper_pts.data[], lower))
            hull_indices[i++] = hp.index;
        return hull_indices;
    } else {
        Slice!(RCI!double, 2LU, Contiguous) hullpoints = uninitRCslice!(double)(lower.length + upper_pts.length, 2);
        size_t i;
        foreach (hp; chain(upper_pts.data[], lower))
        {
            hullpoints[i, 0] = hp.x;
            hullpoints[i, 1] = hp.y;
            ++i;
        }
        return hullpoints; // returning coords are of double
    }
}

pragma(inline, true)
private bool rightTurn(PC)(PC p1, PC p2, PC p3) {
    if ((p3.y-p1.y)*(p2.x-p1.x) >= (p2.y-p1.y)*(p3.x-p1.x))
        return false;
    return true;
}    