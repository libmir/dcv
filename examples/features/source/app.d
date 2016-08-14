module dcv.example.imgmanip;

/** 
 * Corner extraction example, by using Harris and Shi-Tomasi algorithms.
 */

import std.stdio;
import std.experimental.ndslice;
import std.array : array;
import std.algorithm.iteration : map, reduce;
import std.range : repeat;

import dcv.core;
import dcv.features;
import dcv.imgproc.color;
import dcv.imgproc.filter;
import dcv.io;
import dcv.plot;

import ggplotd.ggplotd;
import ggplotd.geom;
import ggplotd.aes;

void main()
{
    // read source image
    auto image = imread("../data/building.png");

    // prepare working sliced
    auto imslice = image.sliced!ubyte;
    auto imfslice = imslice.asType!float;
    auto gray = imfslice.rgb2gray;

    // make copies to draw corners 
    auto pixelSize = imslice.shape.reduce!"a*b";
    auto shiTomasiDraw = new ubyte[pixelSize].sliced(imslice.shape);
    auto harrisDraw = new ubyte[pixelSize].sliced(imslice.shape);
    shiTomasiDraw[] = imslice[];
    harrisDraw[] = imslice[];

    // estimate corner response for each of corner algorithms by using 5x5 window.
    auto shiTomasiResponse = shiTomasiCorners(gray, 5).filterNonMaximum;
    auto harrisResponse = harrisCorners(gray, 5).filterNonMaximum;

    // extract corners from the response matrix ( extract 100 corners, where each response is larger than 0.)
    auto shiTomasiCorners = extractCorners(shiTomasiResponse, 100, 0.);
    auto harrisCorners = extractCorners(harrisResponse, 100, 0.);

    // visualize corner response, and write it to disk.
    visualizeCornerResponse(harrisResponse, "harrisResponse");
    visualizeCornerResponse(shiTomasiResponse, "shiTomasiResponse");

    // plot corner points on image.
    cornerPlot(harrisDraw, harrisCorners, "harrisCorners");
    cornerPlot(shiTomasiDraw, shiTomasiCorners, "shiTomasiCorners");

    waitKey();
}

void visualizeCornerResponse(Slice!(2, float*) response, string windowName)
{
    response 
        // scale values in the response matrix for easier visualization.
        .byElement
        .ranged(0., 255.).array.sliced(response.shape).asType!ubyte
        // Show the window
        .imshow(windowName) 
        .image
        // ... but also write it to disk.
        .imwrite("result/" ~ windowName ~ ".png");
}

void cornerPlot(Slice!(3, ubyte*) slice, ulong[2][] corners, string windowName)
{
    // separate coordinate values
    auto xs = corners.map!(v => v[1]);
    auto ys = corners.map!(v => v[0]);

    auto aes = Aes!(typeof(xs), "x", typeof(ys), "y", bool[], "fill", string[], "colour")(xs, ys,
            false.repeat(xs.length).array, "red".repeat(xs.length).array);

    auto gg = GGPlotD().put(geomPoint(aes));

    // plot corners on the same figure, and save it's image to disk.
    slice.plot(gg, windowName).image().imwrite("result/" ~ windowName ~ ".png");
}
