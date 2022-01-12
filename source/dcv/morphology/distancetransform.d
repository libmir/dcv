module dcv.morphology.distancetransform;

import std.algorithm.comparison : min;

import mir.ndslice;
import mir.rc;

/** Apply distance transform using chamfer distance algorithm.

Params:
    image = Input binary image (0 for background). Agnostic to SliceKind

Returns distance image of Slice!(RCI!int, 2LU, Contiguous)
*/
auto distanceTransform(InputImg)(InputImg img) @nogc nothrow
{
    auto rows = img.shape[0];
    auto cols = img.shape[1];
    Slice!(RCI!int, 2LU, Contiguous) dt = uninitRCslice!int(rows, cols);

    size_t r, c;
    
    if (img[r,c] != 0)
        dt[r,c] = 65535;
    foreach(i; 1..rows)
        if (img[i,c] != 0)
            dt[i,c] = 3 + dt[i-1,c];
    foreach(j; 1..cols){
        r = 0;
        if (img[r,j] != 0)
            dt[r,j] = min(3 + dt[r,j-1], 4 + dt[r+1,j-1]);
        foreach(i; 1..rows-1)
            if (img[i,j] != 0)
            dt[i,j] = min(4 + dt[i-1,j-1], 3 + dt[i,j-1], 4 + dt[i+1,j-1], 3 + dt[i-1,j]);
        r = rows-1;
        if (img[r,j] != 0)
            dt[r,j] = min(4 + dt[r-1,j-1], 3 + dt[r,j-1], 3 + dt[r-1,j]);
    }
    foreach_reverse(i; 0..rows-1){
        c = cols-1;
        if (img[i,c] != 0)
            dt[i,c] = min(dt[i,c], 3 + dt[i+1,c]);
    }
    foreach_reverse(j; 0..cols-1){
        r = rows-1;
        if (img[r,j] != 0)
            dt[r,j] = min(dt[r,j], 3 + dt[r,j+1], 4 + dt[r-1,j+1]);
        foreach(i; 1..rows-1)
            if (img[i,j] != 0)
                dt[i,j] = min(dt[i,j], 4 + dt[i+1,j+1], 3 + dt[i,j+1], 4 + dt[i-1,j+1], 3 + dt[i+1,j]);
        r = 0;
        if (img[r,j] != 0)
            dt[r,j] = min(dt[r,j], 4 + dt[r+1,j+1], 3 + dt[r,j+1], 3 + dt[r+1,j]);
    }
    return dt;
}