
import std.stdio, std.math;
import dcv.imageio.image : imread, imwrite;

import dcv.core;
import dcv.imageio.image;
import dcv.plot;
import dcv.imgproc;
import dcv.measure;
import dcv.morphology : floodFill;

import mir.ndslice;
import mir.algorithm.iteration : each;


// need revision. no solution anymore!

int main(string[] args)
{
    Image img = imread("../data/maze.png"); // read an input image
    scope(exit) destroyFree(img);

    auto gray = img.sliced.rgb2gray; // convert it to gray level
    
    auto imbin = threshold!ubyte(gray.lightScope, ubyte(10), ubyte(255), THR_INVERSE); // threshold the image

    imbin = imbin.dilate(boxKernel!ubyte(3)); // thicken the walls a little bit

    imshow(imbin, "binary image");

    auto cntrs_h = findContours(imbin); // find contours (binary boundaries)
    auto cntrs = cntrs_h[0];
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
   
    // inversion
    auto cimg_inv = cimg.lightScope.map!((a) => cast(ubyte)abs(a - 255));

    auto dilated = cimg_inv.dilate(boxKernel!ubyte(5));

    imshow(dilated, "dilated image");
   
    auto eroded = dilated.erode(boxKernel!ubyte(5));

    imshow(eroded, "eroded image");
    
    auto path = zip(dilated.lightScope, eroded.lightScope).map!((a, b) => abs(a - b)); // subtract dilated from eroded

    img.imOverlay(path);

    imshow(img, "path"); // display solution
    
    waitKey();
    
    destroyFigures();

    return 0;
}



void imOverlay(S, B)(ref S im, B binary){
    import std.algorithm.iteration;
    import std.range;

    size_t i;
    binary.each!((bin){
        if(bin == 255){
            im.data[i] = 255;
            im.data[i+1] = 0;
            im.data[i+2] = 0;
        }
        i += 3;
    });
}