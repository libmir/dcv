module dcv.example.imgmanip;

/**
 * Corner extraction example, by using Harris and Shi-Tomasi algorithms.
 */

import mir.ndslice;
import mir.rc;

import dcv.core;
import dcv.features;
import dcv.imgproc.color;
import dcv.imgproc.filter;
import dcv.imageio;
import dcv.plot;

@nogc nothrow:

void main()
{
    // read source image
    auto image = imread("../data/building.jpg");
    scope(exit) destroyFree(image);

    // prepare working sliced
    auto imslice = image.sliced;
    auto imfslice = imslice.as!float.rcslice;
    auto gray = imfslice.lightScope.rgb2gray;

    // estimate corner response for each of corner algorithms by using 5x5 window.
    auto shiTomasiResponse = shiTomasiCorners(gray.lightScope, 5).filterNonMaximum;
    auto harrisResponse = harrisCorners(gray.lightScope, 5).filterNonMaximum;

    // extract corners from the response matrix ( extract 100 corners, where each response is larger than 0.)
    auto shiTomasiCorners = extractCorners(shiTomasiResponse.lightScope, 100, 0.0f);
    auto harrisCorners = extractCorners(harrisResponse.lightScope, 100, 0.0f);

    // visualize corner response, and write it to disk.
    visualizeCornerResponse(harrisResponse, "harrisResponse");
    visualizeCornerResponse(shiTomasiResponse, "shiTomasiResponse");

    // plot corner points on image.
    auto figureHarris = imshow(imslice, "harrisCorners");
    auto figureshiTomasi = imshow(imslice, "shiTomasiCorners");

    figureHarris.overlayCorners(harrisCorners);
    figureshiTomasi.overlayCorners(shiTomasiCorners);

    waitKey();

    destroyFigures();
}

void visualizeCornerResponse(SliceKind kind)(Slice!(RCI!float, 2, kind) response, string windowName)
{
    response
        // scale values in the response matrix for easier visualization.
        .ranged(0f, 255f)
        .as!ubyte
        .rcslice
        // Show the window
        .imshow(windowName);   
}

void overlayCorners(Figure handle, RCArray!(size_t[2]) corners){
    import std.array : array;
    import mir.ndslice.topology : map;

    // separate coordinate values
    auto xs = corners.asSlice.map!(e => e[1]);
    auto ys = corners.asSlice.map!(e => e[0]);

    foreach(i; 0..xs.length){
        handle.drawCircle(PlotCircle(cast(float)xs[i], cast(float)ys[i], 5.0f), plotRed, true);
    }
}
