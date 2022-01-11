module dcv.example.imgmanip;

/**
 * Corner extraction example, by using Harris and Shi-Tomasi algorithms.
 */

import mir.ndslice;

import dcv.core;
import dcv.features;
import dcv.imgproc.color;
import dcv.imgproc.filter;
import dcv.io;
import dcv.plot;


void main()
{
    // read source image
    auto image = imread("../data/building.jpg");

    // prepare working sliced
    auto imslice = image.sliced!ubyte;
    auto imfslice = imslice.as!float.slice;
    auto gray = imfslice.rgb2gray;

    // make copies to draw corners 
    auto pixelSize = imslice.elementCount;
    auto shiTomasiDraw = imslice.slice;
    auto harrisDraw = imslice.slice;

    // estimate corner response for each of corner algorithms by using 5x5 window.
    auto shiTomasiResponse = shiTomasiCorners(gray, 5).filterNonMaximum;
    auto harrisResponse = harrisCorners(gray, 5).filterNonMaximum;

    // extract corners from the response matrix ( extract 100 corners, where each response is larger than 0.)
    auto shiTomasiCorners = extractCorners(shiTomasiResponse, 100, 0.0f).slice.field;
    auto harrisCorners = extractCorners(harrisResponse, 100, 0.0f).slice.field;

    // visualize corner response, and write it to disk.
    visualizeCornerResponse(harrisResponse, "harrisResponse");
    visualizeCornerResponse(shiTomasiResponse, "shiTomasiResponse");

    // plot corner points on image.
    auto figureHarris = imshow(imslice, "harrisCorners");
    auto figureshiTomasi = imshow(imslice, "shiTomasiCorners");

    figureHarris.overlayCorners(harrisCorners);
    figureshiTomasi.overlayCorners(shiTomasiCorners);

    waitKey();
}

void visualizeCornerResponse(SliceKind kind)(Slice!(float*, 2, kind) response, string windowName)
{
    response
        // scale values in the response matrix for easier visualization.
        .ranged(0f, 255f)
        .as!ubyte
        .slice
        // Show the window
        .imshow(windowName);   
}

void overlayCorners(Figure handle, size_t[2][] corners){
    import std.array : array;
    import std.algorithm.iteration : map;

    // separate coordinate values
    auto xs = corners.map!(e => e[1]);
    auto ys = corners.map!(e => e[0]);

    foreach(i; 0..xs.length){
        handle.drawCircle(PlotCircle(cast(float)xs[i], cast(float)ys[i], 5.0f), plotRed);
    }
}
