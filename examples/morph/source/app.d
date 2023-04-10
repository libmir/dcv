module dcv.example.morph;

/** 
 * Image morphological operations example using DCV library.
 */

import dcv.core;
import dcv.imageio;
import dcv.imgproc;
import dcv.plot;

import mir.qualifier : ls = lightScope;

@nogc nothrow:

void main()
{
    Image image = imread("../data/lena.png");
    scope(exit) destroyFree(image);

    auto slice = image.sliced.rgb2gray;
    auto thesholded = slice.ls.threshold!ubyte(30, 60);
    auto dilated = thesholded.ls.dilate(radialKernel!ubyte(5));
    auto eroded = thesholded.ls.erode(radialKernel!ubyte(5));
    auto opened = thesholded.ls.open(radialKernel!ubyte(5));
    auto closed = thesholded.ls.close(radialKernel!ubyte(5));

    slice.imshow("Original");
    thesholded.imshow("Thresholded");
    dilated.imshow("Dilated");
    eroded.imshow("Eroded");
    opened.imshow("Opened");
    closed.imshow("Closed");

    waitKey();

    destroyFigures();
}
