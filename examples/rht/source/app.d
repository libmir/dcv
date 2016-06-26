module dcv.example.convolution;

/** 
 * Spatial image filtering example using dcv library.
 */

import std.experimental.ndslice;
import std.stdio : writeln;
import std.datetime : StopWatch;
import std.math : fabs, PI, sin, cos, rint;
import std.typecons : tuple;

import dcv.core : Image, asType, ranged, ImageFormat;
import dcv.io : imread, imwrite;
import dcv.imgproc;
import dcv.features.rht;

void plotLine(T, Line, Color)(Slice!(3, T*) img, Line line, Color color) {
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

void plotCircle(T, Circle, Color)(Slice!(3, T*) img, Circle circle, Color color) {
	int height = cast(int)img.length!0;
	int width = cast(int)img.length!1;
	// quick and dirty circle plot
	foreach(t; 0..360) {
		int x = cast(int)rint(circle.x + circle.r*cos(t*PI/180));
		int y = cast(int)rint(circle.y + circle.r*sin(t*PI/180));
		if(x >= 0 && x < width && y >= 0 && y < height)
			img[y, x, 0..3] = color; 
	}
}

int main(string[] args) {

	string impath = (args.length < 2) ? "../data/img.png" : args[1];

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
	auto canny = blur.canny!ubyte(80);

	auto lines = RhtLines().epouchs(50).iterations(250).minCurve(20);
	StopWatch s;
	s.start;
	auto linesRange = lines(canny);
	foreach(line; linesRange) {
		writeln(line);
		plotLine(imslice, line, [1.0, 1.0, 1.0]);
	}
	writeln("RHT lines took ", s.peek.msecs, "ms");
	writeln("Points:", linesRange.points.length);
	auto circles = RhtCircles()
		.epouchs(25).iterations(10000).minCurve(16);
	foreach(circle; circles(canny, linesRange.points)) {
		writeln(circle);
		plotCircle(imslice, circle, [1.0, 1.0, 1.0]);
	}
	plotCircle(imslice, RhtCircles.Curve(100, 100, 25.0), [1.0, 0.0, 0.0]);
	// write resulting images on the filesystem.
	blur.asType!ubyte.imwrite(ImageFormat.IF_RGB, "./result/outblur.png");
	canny.asType!ubyte.imwrite(ImageFormat.IF_MONO, "./result/canny.png");
	imslice.asType!ubyte.imwrite(ImageFormat.IF_RGB, "./result/rht.png");
	return 0;
}
