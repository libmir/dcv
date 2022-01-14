module dcv.morphology.geometry;

import std.algorithm: min, max;

@nogc nothrow:

bool isPointInPolygon(Point, Polygon)(Point point, const ref Polygon polygon) pure {
    
    auto prev = polygon[polygon.shape[0]-1];
    
    bool oddNodes = false;
    
    foreach (i; 0..polygon.shape[0]){
        auto cur = polygon[i];
        if (isPointInSegment(prev, cur, point))
            return false;
        
        if (cur[1] < point[1] && prev[1] >= point[1] || prev[1] < point[1]
                && cur[1] >= point[1]) 
        {
            if (cur[0] + (point[1] - cur[1]) / (prev[1] - cur[1])
                    * (prev[0] - cur[0]) < point[0]) 
            {
                oddNodes = !oddNodes;
            }
        }
        prev = cur;
    }
    return oddNodes;
}

pragma(inline, true)
bool isPointInSegment(P1, P2, P3)(P1 r, P2 p, P3 q) pure {
    return q[0] <= max(p[0], r[0]) &&
            q[0] >= min(p[0], r[0]) &&
            q[1] <= max(p[1], r[1]) &&
            q[1] >= min(p[1], r[1]);
}