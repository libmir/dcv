
import core.stdc.stdio;
import std.array : s = staticArray;

import dcv.core;
import dcv.imageio;
import dcv.plot;
import dcv.imgproc;
import dcv.measure;

import mir.ndslice;
import mir.math.stat: mean;

@nogc nothrow:

int main()
{
    Image img = imread("../data/test_labels.png"); // read an input image
    scope(exit) destroyFree(img);

    auto gray = img.sliced.rgb2gray; // convert it to gray level

    auto hist = calcHistogram(gray.flattened); // compute histogram
    
    auto thr = getOtsuThresholdValue(hist); // determine a threshold
    
    auto imbin = threshold!ubyte(gray.lightScope, cast(ubyte)thr); // threshold the image
    
    auto labels = bwlabel(imbin); // create label matrix
    auto labelimg = label2rgb(labels); // visualize the label matrix
    imshow(labelimg, "labelimg");

    auto cntrs_h = findContours(imbin); // find contours (binary boundaries)
    auto cntrs = cntrs_h[0];
    auto cimg = contours2image(cntrs, imbin.shape[0], imbin.shape[1]); // visualize the contours
    auto fig = imshow(cimg, "cimg");
    
    foreach(contour; cntrs) // iterate over the regions
    { 
        auto moments = calculateMoments(contour, imbin);
        auto ellipse = ellipseFit(moments);
        
        auto bx = boundingBox(contour);
        fig.drawRectangle([PlotPoint(bx.y, bx.x), PlotPoint(bx.y+bx.height, bx.x+bx.width)].s, plotGreen, 3.0f);

        printf("Orientation: %f\n", ellipse.angle);
        printf("Minor axis length: %f\n", ellipse.minor);
        printf("Major axis length: %f\n", ellipse.major);
        printf("Centroid x: %f Centroid y: %f\n", contour[0..$, 0].mean, contour[0..$, 1].mean);
        printf("Bounding box: [%zu, %zu, %zu, %zu]\n", boundingBox(contour).tupleof);
        printf("convexHull indices: ");
        foreach (ind; convexHull(contour)[]){
            printf("%zu, ", ind);
        }
        printf("\n");

        printf("Area: %f\n", contour.contourArea); // or contour.contourArea
        printf("Perimeter: %f\n", contour.arcLength);
    }

    // write to disk
    labelimg.imwrite(ImageFormat.IF_RGB, "result/labels.png");
    // write rendered figure to disk
    fig.plot2imslice.imwrite(ImageFormat.IF_RGB, "result/contours.png");

    waitKey();
    

    destroyFigures();

    return 0;
}
