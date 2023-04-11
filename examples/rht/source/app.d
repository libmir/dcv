module dcv.example.rht;

/** 
 * Randomized Hough Transform example using dcv library.
 */

import core.stdc.stdio : printf;
import std.datetime.stopwatch : StopWatch;
import std.math : fabs, PI, sin, cos, rint;
import std.typecons : tuple;
import std.array : staticArray;

import mir.ndslice, mir.rc;
import dplug.core.nogc;

import dcv.core.image : Image, ImageFormat;
import dcv.core.utils : clip;
import dcv.imageio : imread, imwrite;
import dcv.imgproc;
import dcv.features.rht;

@nogc nothrow:

void plotLine(Input, Line, Color)(Input img, Line line, Color color)
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

void plotCircle(Input, Circle, Color)(Input img, Circle circle, Color color)
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
    scope(exit) destroyFree(img);

    if (img.empty)
    { // check if image is properly read.
        printf("Cannot read image at the path provided.");
        return 1;
    }

    auto imslice = img.sliced.as!float.rcslice; // convert Image data type from ubyte to float

    auto gray = imslice.lightScope.rgb2gray; // convert rgb image to grayscale

    auto gaussianKernel = gaussian!float(2, 3, 3); // create gaussian convolution kernel (sigma, kernel width and height)

    auto blur = gray.conv(gaussianKernel);
    auto canny = blur.lightScope.canny!ubyte(150);

    auto lines = RhtLines().epouchs(35).iterations(500).minCurve(70);
    StopWatch s;
    s.start;
    auto linesRange = lines(canny.lightScope);
    foreach (line; linesRange)
    {
        printf("m=%f, b=%f\n", line.tupleof);
        plotLine(imslice, line, [1.0, 1.0, 1.0].staticArray);
    }
    s.stop;
    printf("RHT lines took %d ms\n", s.peek.total!"msecs");
    printf("Points left after lines: %d\n", linesRange.points.length);
    auto circles = RhtCircles().epouchs(15).iterations(2000).minCurve(50);
    s.reset;
    s.start;
    foreach (circle; circles(canny.lightScope, linesRange.points[]))
    {
        printf("x=%f, y=%f, r=%f\n", circle.tupleof);
        plotCircle(imslice, circle, [1.0, 1.0, 1.0].staticArray);
    }
    s.stop;
    printf("RHT circles took %d ms \n", s.peek.total!"msecs");

    // write resulting images on the filesystem.
    blur.lightScope.map!(v => v.clip!ubyte).rcslice.imwrite(ImageFormat.IF_MONO, "./result/outblur.png");
    canny.lightScope.map!(v => v.clip!ubyte).rcslice.imwrite(ImageFormat.IF_MONO, "./result/canny.png");
    imslice.lightScope.map!(v => v.clip!ubyte).rcslice.imwrite(ImageFormat.IF_RGB, "./result/rht.png");

    return 0;
}
