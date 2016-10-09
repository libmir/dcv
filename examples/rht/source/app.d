module dcv.example.rht;

/** 
 * Randomized Hough Transform example using dcv library.
 */

import std.stdio : writeln;
import std.datetime : StopWatch;
import std.math : fabs, PI, sin, cos, rint;
import std.typecons : tuple;

import mir.ndslice;

import dcv.core.image : Image, ImageFormat;
import dcv.core.utils : clip;
import dcv.io : imread, imwrite;
import dcv.imgproc;
import dcv.features.rht;

void plotLine(T, Line, Color)(Slice!(3, T*) img, Line line, Color color)
{
    int height = cast(int)img.length!0;
    int width = cast(int)img.length!1;
    if (line.m == double.infinity)
    {
        auto x = line.b;
        if (x >= 0 && x < width)
            foreach (y; 0 .. height)
            {
                img[cast(int)y, cast(int)x, 0 .. 3] = color;
            }
    }
    else
    {
        foreach (x; 0 .. 1000)
        {
            auto y = line.m * x + line.b;
            if (x >= 0 && x < width && y >= 0 && y < height)
            {
                img[cast(int)y, cast(int)x, 0 .. 3] = color;
            }
        }
    }
}

void plotCircle(T, Circle, Color)(Slice!(3, T*) img, Circle circle, Color color)
{
    int height = cast(int)img.length!0;
    int width = cast(int)img.length!1;
    // quick and dirty circle plot
    foreach (t; 0 .. 360)
    {
        int x = cast(int)rint(circle.x + circle.r * cos(t * PI / 180));
        int y = cast(int)rint(circle.y + circle.r * sin(t * PI / 180));
        if (x >= 0 && x < width && y >= 0 && y < height)
            img[y, x, 0 .. 3] = color;
    }
}

int main(string[] args)
{

    string impath = (args.length < 2) ? "../data/img.png" : args[1];

    Image img = imread(impath); // read an image from filesystem.

    if (img.empty)
    { // check if image is properly read.
        writeln("Cannot read image at: " ~ impath);
        return 1;
    }

    Slice!(3, float*) imslice = img.sliced.as!float.slice; // convert Image data type from ubyte to float

    auto gray = imslice.rgb2gray; // convert rgb image to grayscale

    auto gaussianKernel = gaussian!float(2, 3, 3); // create gaussian convolution kernel (sigma, kernel width and height)

    auto blur = gray.conv(gaussianKernel);
    auto canny = blur.canny!ubyte(150);

    auto lines = RhtLines().epouchs(35).iterations(500).minCurve(70);
    StopWatch s;
    s.start;
    auto linesRange = lines(canny);
    foreach (line; linesRange)
    {
        writeln(line);
        plotLine(imslice, line, [1.0, 1.0, 1.0]);
    }
    s.stop;
    writeln("RHT lines took ", s.peek.msecs, "ms");
    writeln("Points left after lines:", linesRange.points.length);
    auto circles = RhtCircles().epouchs(15).iterations(2000).minCurve(50);
    s.reset;
    s.start;
    foreach (circle; circles(canny, linesRange.points[]))
    {
        writeln(circle);
        plotCircle(imslice, circle, [1.0, 1.0, 1.0]);
    }
    s.stop;
    writeln("RHT circles took ", s.peek.msecs, "ms");

    // write resulting images on the filesystem.
    blur.ndMap!(v => v.clip!ubyte).slice.imwrite(ImageFormat.IF_RGB, "./result/outblur.png");
    canny.ndMap!(v => v.clip!ubyte).slice.imwrite(ImageFormat.IF_MONO, "./result/canny.png");
    imslice.ndMap!(v => v.clip!ubyte).slice.imwrite(ImageFormat.IF_RGB, "./result/rht.png");

    return 0;
}
