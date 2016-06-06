module dcv.example.convolution;

/** 
 * Spatial image filtering example using dcv library.
 */

import std.experimental.ndslice;
import std.stdio : writeln;
import std.datetime : StopWatch;
import std.math : fabs;

import dcv.core : Image, asType, ranged, ImageFormat;
import dcv.io : imread, imwrite;
import dcv.imgproc;


int main(string[] args) {

	string impath = (args.length < 2) ? "../data/lena.png" : args[1];

	Image img = imread(impath); // read an image from filesystem.

	if (img.empty) { // check if image is properly read.
		writeln("Cannot read image at: " ~ impath);
		return 1;
	}

	Slice!(3, float*) imslice = img
		.asType!float // convert Image data type from ubyte to float
		.sliced!float; // slice image data - calls img.data!float.sliced(img.height, img.width, img.channels)

	auto gray = imslice.rgb2gray; // convert rgb image to grayscale

	auto gaussianKernel = gaussian!float(2, 5, 5); // create gaussian convolution kernel (sigma, kernel width and height)
	auto sobelKernel = sobel!real(GradientDirection.DIAG); // sobel operator for horizontal (X) gradients
	
	// perform convolution for each kernel
	StopWatch s;

	s.start;
	auto blur = imslice.conv(gaussianKernel);
	auto grads = gray.conv(sobelKernel);
	
	// write resulting images on the filesystem.
	blur.asType!ubyte.imwrite(ImageFormat.IF_RGB, "./result/outblur.png");
	grads.asType!ubyte.imwrite(ImageFormat.IF_MONO, "./result/sobel.png");
	
	return 0;
}
