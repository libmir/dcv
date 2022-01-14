
import std.stdio, std.math;
import dcv.io.image : imread, imwrite;

import dcv.core;
import dcv.io.image;
import dcv.plot;
import dcv.imgproc;
import dcv.measure;
import dcv.morphology : floodFill;

import mir.ndslice;
import mir.algorithm.iteration : each;

int main(string[] args)
{
    Image img = imread("../data/maze.png"); // read an input image

    auto gray = img.sliced.rgb2gray; // convert it to gray level
    
    auto imbin = threshold!ubyte(gray, ubyte(10), ubyte(255)); // threshold the image
    imbin[].each!((ref a) { a = cast(ubyte)abs(a-255); }); // invert

    imbin = imbin.dilate(boxKernel!ubyte(3)); // thicken the wals a little bit

    imshow(imbin, "binary image");

    auto cntrs = findContours(imbin); // find contours (binary boundaries)
    auto cimg = contours2image(cntrs, imbin.shape[0], imbin.shape[1]);
    
    // fill contours
    foreach(contour; cntrs) // iterate over the regions
    { 
        auto tp = contour.anyInsidePoint;
        const size_t cx = tp[0];
        const size_t cy = tp[1];

        floodFill(cimg, cx, cy, ubyte(255));
    }

    imshow(cimg, "contour image");
    
    cimg[].each!((ref a) { a = cast(ubyte)abs(a-255); }); // invert

    auto dilated = cimg.dilate(boxKernel!ubyte(17));

    imshow(dilated, "dilated image");
    
    auto eroded = dilated.erode(boxKernel!ubyte(17));

    imshow(eroded, "eroded image");
    
    auto path = zip(dilated, eroded).map!((a, b) => abs(a - b)); // subtract dilated from eroded

    imshow(path, "path"); // display solution
    
    waitKey();
    
    return 0;
}
