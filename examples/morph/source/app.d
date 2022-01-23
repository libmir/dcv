module dcv.example.morph;

/** 
 * Image morphological operations example using DCV library.
 */

import dcv.core;
import dcv.imageio;
import dcv.imgproc;
import dcv.plot;


void main()
{
    Image image = imread("../data/lena.png");

    auto slice = image.sliced.rgb2gray;
    auto thesholded = slice.threshold!ubyte(30, 60);
    auto dilated = thesholded.dilate(radialKernel!ubyte(5));
    auto eroded = thesholded.erode(radialKernel!ubyte(5));
    auto opened = thesholded.open(radialKernel!ubyte(5));
    auto closed = thesholded.close(radialKernel!ubyte(5));

    slice.imshow("Original");
    thesholded.imshow("Thresholded");
    dilated.imshow("Dilated");
    eroded.imshow("Eroded");
    opened.imshow("Opened");
    closed.imshow("Closed");

    waitKey();
}
