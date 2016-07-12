module dcv.example.opticalflow;

/** 
 * Dense optical flow example, by using 
 * pyramidal Horn-Schunck implementation in dcv.
 */

import std.stdio;
import std.conv : to;
import std.experimental.ndslice;

import dcv.core;
import dcv.io;

import dcv.imgproc.imgmanip : warp;
import dcv.tracking.opticalflow : HornSchunckFlow, HornSchunckProperties, DensePyramidFlow;
import dcv.plot.opticalflow : colorCode;

void printHelp()
{
    writeln(`
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

    if (args.length == 2)
    {
        currentPath = "../../data/optflow/" ~ args[1] ~ "/frame10.png";
        nextPath = "../../data/optflow/" ~ args[1] ~ "/frame11.png";
    }
    else
    {
        currentPath = args.length >= 2 ? args[1] : "../../data/optflow/Army/frame10.png";
        nextPath = args.length >= 3 ? args[2] : "../../data/optflow/Army/frame11.png";
    }

    auto current = imread(currentPath, rparams);
    auto next = imread(nextPath, rparams);

    // Setup algorithm parameters.
    HornSchunckProperties props = HornSchunckProperties();
    props.iterationCount = args.length >= 4 ? args[3].to!int : 100;
    props.alpha = args.length >= 5 ? args[4].to!float : 10.0f;
    props.gaussSigma = args.length >= 6 ? args[5].to!float : 1.0f;
    props.gaussKernelSize = args.length >= 7 ? args[6].to!uint : 3;

    uint pyramidLevels = args.length >= 8 ? args[7].to!int : 3;

    HornSchunckFlow hsFlow = new HornSchunckFlow(props);
    DensePyramidFlow densePyramid = new DensePyramidFlow(hsFlow, pyramidLevels);

    auto flow = densePyramid.evaluate(current, next);

    auto flowColor = flow.colorCode;
    auto flowWarp = current.sliced.warp(flow);

    current.imwrite("./result/1_current.png");
    flowColor.imwrite(ImageFormat.IF_RGB, "./result/2_flowColor.png");
    flowWarp.imwrite(ImageFormat.IF_MONO, "./result/3_flowWarp.png");
    next.imwrite("./result/4_next.png");
}
