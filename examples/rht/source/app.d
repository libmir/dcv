module dcv.example.convolution;

/** 
 * Spatial image filtering example using dcv library.
 */

import std.experimental.ndslice;
import std.stdio : writeln;
import std.datetime : StopWatch;
import std.math : fabs;
import std.typecons : tuple;

import dcv.core : Image, asType, ranged, ImageFormat;
import dcv.io : imread, imwrite;
import dcv.imgproc;
import dcv.features.rht;

void plotLine(T, Line, Color)(Slice!(3, T*) img, Line line, Color color)
{
	int height = cast(int)img.length!0;
	int width = cast(int)img.length!1;
	if(line.m == double.infinity){
		auto x = line.b;
		if(x >= 0 && x < width)
			foreach(y; 0..height) {
				img[cast(int)y, cast(int)x, 0..3] = color;
			}
	}
	else {
		foreach(x; 0..1000) {
			auto y = line.m*x + line.b;
			if(x >= 0 && x < width && y >= 0 && y < height) {
				img[cast(int)y, cast(int)x, 0..3] = color;
			}
		}
	}
}

int main(string[] args) {

	string impath = (args.length < 2) ? "../data/img.jpg" : args[1];

	Image img = imread(impath); // read an image from filesystem.

	if (img.empty) { // check if image is properly read.
		writeln("Cannot read image at: " ~ impath);
		return 1;
	}

	Slice!(3, float*) imslice = img
		.asType!float // convert Image data type from ubyte to float
		.sliced!float; // slice image data - calls img.data!float.sliced(img.height, img.width, img.channels)

	auto gray = imslice.rgb2gray; // convert rgb image to grayscale

	auto gaussianKernel = gaussian!float(2, 3, 3); // create gaussian convolution kernel (sigma, kernel width and height)

	auto blur = gray.conv(gaussianKernel);
	auto canny = blur.canny!ubyte(80, 220);

	auto lines = RhtLines().epouchs(50).iterations(250);
	StopWatch s;
	s.start;
	foreach(line; lines(canny)) {
		plotLine(imslice, line, [1.0, 1.0, 1.0]);
	}
	writeln("RHT took ", s.peek.msecs, "ms");
	// write resulting images on the filesystem.
	blur.asType!ubyte.imwrite(ImageFormat.IF_RGB, "./result/outblur.png");
	canny.asType!ubyte.imwrite(ImageFormat.IF_MONO, "./result/canny.png");
	
	return 0;
}
