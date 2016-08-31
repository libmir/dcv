module dcv.example.stereo;

import std.algorithm;
import std.math;
import std.range;
import std.stdio;

import dcv.imgproc;
import dcv.io.image;
import dcv.plot;
import dcv.multiview.stereo.matching;

void main(string[] args)
{
    if(args.length != 4)
    {
        writeln("Usage: stereo <left image> <right image> <true disparity image>");
        return;
    }

    //Load the input images
    auto left = imread(args[1]);
    auto right = imread(args[2]);
    auto groundTruth = imread(args[3]);

    //Create a matcher
    auto props = StereoPipelineProperties(left.width, left.height, left.channels);
    auto matcher = semiGlobalMatchingPipeline(props);

    //Estimate the disparity
    auto estimate = matcher.evaluate(left, right);

    //Scale by a factor 4 for displaying
    estimate[] *= 4;

    //Compute the accuracy. In this case we consider something within 3 units correct. Note that we have scaled everything up by a factor of 4.
    uint c;
    auto acc = zip(estimate.byElement, groundTruth.asType!ushort.sliced!ushort.rgb2gray.byElement)
              .filter!(x => x[1] != 0)
              .tee!(x => c++)
              .map!(x => abs(cast(int)x[0] - cast(int)x[1]) < 12 ? 1 : 0)
              .fold!((a, b) => a + b)(0.0f);

    writeln((acc / cast(float)c) * 100, "% accuracy (<3px)");

    //Display estimated disparity and true disparity
    imshow(estimate);
    imshow(groundTruth);
    waitKey();
}
