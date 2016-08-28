module dcv.example.stereo;

import dcv.io.image;
import dcv.plot;
import dcv.stereo.matching;

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

	auto estimate = matcher.evaluate(left, right);
	estimate[] *= 4;

	imshow(estimate);
	imshow(groundTruth);
	waitKey();
}
