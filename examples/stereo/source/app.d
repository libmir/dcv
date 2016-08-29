module dcv.example.stereo;

import dcv.io.image;
import dcv.plot;
import dcv.multiview.stereo.matching;

void main(string[] args)
{
    if(args.length != 4)
    {
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

	//Display estimated disparity and true disparity
    imshow(estimate);
    imshow(groundTruth);
    waitKey();
}
