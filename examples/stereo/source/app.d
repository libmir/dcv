module dcv.example.stereo;

import std.math;
import std.range;
import std.stdio;

import mir.algorithm.iteration : reduce;

import dcv.core;
import dcv.imgproc;
import dcv.imageio.image;
import dcv.plot;
import dcv.multiview.stereo.matching;

void main(string[] args)
{
    if (args.length != 4)
    {
        writeln("Usage: stereo <left image> <right image> <true disparity image>");
        return;
    }

    //Load the input images
    auto left = imread(args[1]);
    auto right = imread(args[2]);
    auto groundTruth = imread(args[3]);

    scope(exit){
        left.destroyFree;
        right.destroyFree;
        groundTruth.destroyFree;
    }
    //Create a matcher
    auto props = StereoPipelineProperties(left.width, left.height, left.channels);
    auto matcher = semiGlobalMatchingPipeline(props);

    //Estimate the disparity
    auto estimate = matcher.evaluate(left, right);

    //Scale by a factor 4 for displaying
    estimate[] *= 4;

    //Compute the accuracy. In this case we consider something within 3 units correct. Note that we have scaled everything up by a factor of 4.
    float c = 0;

    float evalAccum(float accum, uint est, uint gt)
    {
        if (gt != 0)
        {
            c++;
            return accum + (abs(cast(float)est - cast(float)gt) <= 12.0f ? 1.0f : 0.0f);
        }
        else
        {
            return accum;
        }
    }

    auto acc = reduce!(evalAccum)(0.0f, estimate, groundTruth.sliced.rgb2gray);

    writeln((acc / cast(float)c) * 100, "% accuracy (<=3px)");

    //Display estimated disparity and true disparity
    imshow(estimate);
    imshow(groundTruth);

    waitKey();

    destroyFigures();
}
