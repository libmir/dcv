module dcv.plot.draw;


/**
 * Shape drawing module.
 */

import std.experimental.ndslice;
import std.traits;

import dcv.imgproc.interpolate;


void drawPoint(size_t D, Range, Point, Color)
    (Slice!(D, Range) canvas, Point point, 
Color color, int strokeWidth) {

    assert(!canvas.empty && strokeWidth > 0);

    static if (D == 2) {
        if (strokeWidth == 1) {
            if (point[1] >= 0 && point[1] < canvas.length!0 && point[0] >= 0 && point[0] < canvas.length!1) {
                canvas[cast(int)point[1], cast(int)point[0]] = color;
            }
        } else {
            for (int r = cast(int)(point[1] - strokeWidth / 2); r < cast(int)(point[1] + strokeWidth / 2); r++) {
                for (int c = cast(int)(point[0] - strokeWidth / 2); c < cast(int)(point[0] + strokeWidth / 2); c++) {
                    if (r >= 0 && r < canvas.length!0 && c >= 0 && c < canvas.length!1)
                        canvas[r, c] += color;
                }
            }
        }
    } else static if (D == 3) {
        foreach(i; 0..D) {
            if (strokeWidth == 1) {
                if (point[1] >= 0 && point[1] < canvas.length!0 && point[0] >= 0 && point[0] < canvas.length!1) {
                    canvas[cast(int)point[1], cast(int)point[0], i] = color[i];
                }
            } else {
                for (int r = point[1] - strokeWidth / 2; r < point[1] + strokeWidth / 2; r++) {
                    for (int c = point[0] - strokeWidth / 2; c < point[0] + strokeWidth / 2; c++) {
                        if (r >= 0 && r < canvas.length!0 && c >= 0 && c < canvas.length!1)
                            canvas[r, c, i] += color[i];
                    }
                }
            }
        }
    } else {
        static assert(0, "Invalid slice dimension for canvas.");
    }
}

void drawLine(size_t D, Range, Point, Color)
    (Slice!(D, Range) canvas, Point startPoint, Point endPoint, 
Color color, int strokeWidth) {

    import std.math : sin, cos, abs;
    import std.algorithm.iteration : each;

    assert(!canvas.empty && strokeWidth > 0);

    int x_length = abs(cast(int)endPoint[0] - cast(int)startPoint[0]);
    int y_length = abs(cast(int)endPoint[1] - cast(int)startPoint[1]);

    int longer_axis;
    
    float [2] line_vec = [ endPoint[0] - startPoint[0], endPoint[1] - startPoint[1]];
    float [2] norm_vec;

    float [2] curr_point = [startPoint[0], startPoint[1]];
    float [2] ptn;

    immutable c = cos(90.0f);
    immutable s = sin(90.0f);

    norm_vec[0] = line_vec[0] * c - line_vec[1] * s;
    norm_vec[1] = line_vec[0] * s + line_vec[1] * c;

    auto sm = norm_vec[0] + norm_vec[1];
    norm_vec.each!((ref v) => v/sm);

    if (x_length >= y_length) {
        longer_axis = x_length;
    } else {
        longer_axis = y_length;
    }
    
    line_vec[] /= longer_axis;
    
    for (int i = 0; i < longer_axis; i++) {
        if (strokeWidth > 1) {
            for (float j = -1 * strokeWidth / 2; j < strokeWidth / 2; j += 0.1) {
                ptn[] = curr_point[] + (norm_vec[] * j);
                drawPoint!(D, Range, typeof(ptn), Color)(canvas, ptn, color, strokeWidth);
            }
        } else {
            drawPoint!(D, Range, typeof(curr_point), Color)(canvas, curr_point, color, strokeWidth);
        }
        curr_point[] += line_vec[];
    }
}
