module dcv.example.opticalflow;

/** 
 * Dense optical flow example, by using 
 * pyramidal Horn-Schunck implementation in dcv.
 */

import core.stdc.stdio;
import core.stdc.stdlib : atoi, atof;
import std.exception : assumeUnique;
import mir.ndslice;

import dcv.core;
import dcv.imageio;

import dcv.imgproc.imgmanip : warp;
import dcv.tracking.opticalflow : HornSchunckFlow, HornSchunckProperties, DensePyramidFlow;
import dcv.plot;

void printHelp() @nogc nothrow
{
    printf(`
DCV Optical DenseFlow example.

If only one parameter is given it is considered to be
the name of the subfolder of the data/optflow directory.
These directories represent the benchmark dataset from the
Middlebury University website: http://vision.middlebury.edu/flow/data/

Example:
./hornschunck Army

Note:
This mode will use default parameters (described in the following section).

If multiple parameters are given, then parameters are considered to be:

1 - path to current frame image; [../data/optflow/Army/frame10.png]
2 - path to next frame image; [../data/optflow/Army/frame11.png]
3 - optical flow iteration count; [100]
4 - Horn-Schunck flow smoothness strength parameter; [10.0]
5 - Gaussian image smoothing theta parameter; [1.0]
6 - Gaussian kernel size; [3]
7 - optical flow pyramid level count; [3]

Example:
./hornschunck ../../data/optflow/Evergreen/frame10.png ../../data/optflow/Evergreen/frame11.png 300 25 3 5 4

... which will compute the optical flow for given two images, 
by 300 iteration at each pyramid level, by using value of 25.0 
as smoothness strenght, in 4 pyramid levels. Images are smoothed
with gaussian filter with sigma value 3.0, sized 5x5.
        `);
}

@nogc nothrow:

void main(string[] args)
{

    if (args.length == 2 && args[1] == "-h")
    {
        printHelp();
        return;
    }

    // Read source images.
    auto rparams = ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8);

    string currentPath, nextPath;
    char[256] buff1, buff2;
    if (args.length == 2)
    {
        sprintf(buff1.ptr, "../../data/optflow/%s/frame10.png", args[1].ptr);
        currentPath = buff1[].assumeUnique;

        sprintf(buff2.ptr, "../../data/optflow/%s/frame11.png", args[1].ptr);
        nextPath = buff2[].assumeUnique;
    }
    else
    {
        currentPath = args.length >= 2 ? args[1] : "../../data/optflow/Army/frame10.png";
        nextPath = args.length >= 3 ? args[2] : "../../data/optflow/Army/frame11.png";
    }

    auto _current = imread(currentPath, rparams);
    auto _next = imread(nextPath, rparams);
    
    scope(exit){
        destroyFree(_current);
        destroyFree(_next);
    }
    auto current = _current.sliced2D.as!float.rcslice;
    auto next = _next.sliced2D.as!float.rcslice;

    // Setup algorithm parameters.
    HornSchunckProperties props = HornSchunckProperties();
    props.iterationCount = args.length >= 4 ? args[3].ptr.atoi : 100;
    props.alpha = args.length >= 5 ? args[4].ptr.atof : 10.0f;
    props.gaussSigma = args.length >= 6 ? args[5].ptr.atof : 1.0f;
    props.gaussKernelSize = args.length >= 7 ? cast(uint)args[6].ptr.atoi : 3;

    uint pyramidLevels = args.length >= 8 ? args[7].ptr.atoi : 3;

    HornSchunckFlow hsFlow = mallocNew!HornSchunckFlow(props);
    DensePyramidFlow densePyramid = mallocNew!DensePyramidFlow(hsFlow, pyramidLevels);
    
    scope(exit){
        destroyFree(hsFlow);
        destroyFree(densePyramid);
    }
    auto flow = densePyramid.evaluate(current.lightScope, next.lightScope);

    auto flowColor = colorCode(flow.lightScope);
    auto flowWarp = warp(current.lightScope, flow.lightScope);

    current.as!ubyte.rcslice.imwrite(ImageFormat.IF_MONO,"./result/1_current.png");
    flowColor.imwrite(ImageFormat.IF_RGB, "./result/2_flowColor.png");
    flowWarp.as!ubyte.rcslice.imwrite(ImageFormat.IF_MONO, "./result/3_flowWarp.png");
    next.as!ubyte.rcslice.imwrite(ImageFormat.IF_MONO, "./result/4_next.png");

    imshow(flowColor, "flowColor");

    waitKey();

    destroyFigures();
}
