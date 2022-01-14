module dcv.morphology.floodfill;

import std.typecons: Tuple, tuple;

import mir.ndslice;
import mir.rc;

import dcv.core.utils : dlist;

@nogc nothrow:

/** Apply flood fill to given binary image using BFS approach.

Params:
    image = Input binary image of ubyte. Agnostic to SliceKind
*/
void floodFill(InputImg, T = DeepElementType!InputImg)(ref InputImg data, size_t x, size_t y, T color = 255)
{
    const rows = data.shape[0];
    const cols = data.shape[1];

    debug assert((x < rows && x >= 0) && (y < cols && y >= 0), "Seed index is out of bounds!");

    Slice!(RCI!ubyte, 2LU, Contiguous) vis = uninitRCslice!ubyte(rows, cols);
    vis[] = 0;

    alias Point = Tuple!(size_t, "first", size_t, "second");
    
    dlist!(Point) obj;
    scope(exit) obj.clear;

    obj.insertBack(Point( x, y ));

    vis[x, y] = 1;

    while (!obj.empty)
    {
        Point coord = obj[].front();
        x = coord.first;
        y = coord.second;
        auto preColor = data[x, y];

        data[x, y] = color;
        
        obj.removeFront();

        if (validCoord(x + 1, y, rows, cols)
            && vis[x + 1, y] == 0
            && data[x + 1, y] == preColor)
        {
            obj.insertBack(Point( x + 1, y ));
            vis[x + 1, y] = 1;
        }
        
        if (validCoord(x - 1, y, rows, cols)
            && vis[x - 1, y] == 0
            && data[x - 1, y] == preColor)
        {
            obj.insertBack(Point( x - 1, y ));
            vis[x - 1, y] = 1;
        }
        
        if (validCoord(x, y + 1, rows, cols)
            && vis[x, y + 1] == 0
            && data[x, y + 1] == preColor)
        {
            obj.insertBack(Point( x, y + 1 ));
            vis[x, y + 1] = 1;
        }
        
        if (validCoord(x, y - 1, rows, cols)
            && vis[x, y - 1] == 0
            && data[x ,y - 1] == preColor)
        {
            obj.insertBack(Point( x, y - 1 ));
            vis[x, y - 1] = 1;
        }
    }
}

pragma(inline, true)
private bool validCoord(size_t x, size_t y, size_t n, size_t m)
{
    if (x < 0 || y < 0) {
        return false;
    }
    if (x >= n || y >= m) {
        return false;
    }
    return true;
}