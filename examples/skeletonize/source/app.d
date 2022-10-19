import std.stdio;

import dcv.imageio.image : imread, imwrite;
import dcv.core;
import dcv.plot;
import dcv.imgproc;
import dcv.morphology;

import mir.rc;

void main()
{
    Image img = imread("../data/test_labels.png");

    Slice!(ubyte*, 2, Contiguous) gray = img.sliced.rgb2gray; // the test image is already binary here

    auto skel = skeletonize2D(gray);

    imwrite(skel.asImage(ImageFormat.IF_MONO), "result/skel.png");

    imshow(skel, "skel");
    
    waitKey();
}