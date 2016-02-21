module dcv.example.imgmanip;

/** 
 * Corner extraction example, by using Harris and Shi-Tomasi algorithms.
 */

import std.stdio;
import std.experimental.ndslice;

import dcv.core;
import dcv.features;
import dcv.imgproc.color;
import dcv.imgproc.filter;
import dcv.io;


void main()
{
	import std.algorithm.iteration : reduce;

	// read source image
	auto image = imread("../data/building.png");

	// prepare working sliced
	auto imslice = image.sliced!ubyte;
	auto imfslice = imslice.asType!float;
	auto gray = imfslice.rgb2gray;

	// make copies to draw corners 
	auto pixelSize = imslice.shape.reduce!"a*b";
	auto shiTomasiDraw = new ubyte[pixelSize].sliced(imslice.shape);
	auto harrisDraw = new ubyte[pixelSize].sliced(imslice.shape);
	shiTomasiDraw[] = imslice[];
	harrisDraw[] = imslice[];

	// estimate corner response for each of corner algorithms
	auto shiTomasiResponse = shiTomasiCorners(gray).filterNonMaximum; 
	auto harrisResponse = harrisCorners(gray).filterNonMaximum;

	// extract corners from the response matrix ( extract 100 corners, where each response is larger than 0.)
	auto shiTomasiCorners = extractCorners(shiTomasiResponse, 100, 0.);
	auto harrisCorners = extractCorners(harrisResponse, 100, 0.);

	// dummy function to draw corners
	shiTomasiDraw.drawCorners(shiTomasiCorners, 9, cast(ubyte[])[255, 0, 0]);
	harrisDraw.drawCorners(harrisCorners, 9, cast(ubyte[])[255, 0, 0]);

	shiTomasiResponse
		.byElement
		.ranged(0., 255.) // scale values in the response matrix for easier visualization.
		.array
		.sliced(shiTomasiResponse.shape)
		.asType!ubyte
		.imwrite("result/shiTomasiResponse.png");

	harrisResponse
		.byElement
		.ranged(0., 255.)
		.array
		.sliced(harrisResponse.shape)
		.asType!ubyte
		.imwrite("result/harrisResponse.png");

	shiTomasiDraw.imwrite("result/shiTomasiCorners.png");
	harrisDraw.imwrite("result/harrisCorners.png");

}

void drawCorners(T, Color)(Slice!(3, T*) image, ulong [2][] corners, ulong cornerSize, Color color) {
	import std.algorithm.iteration : each;
	auto ch = cast(long)(cornerSize / 2);
	foreach(corner; corners) { 
		auto c0 = cast(long)corner[0];
		auto c1 = cast(long)corner[1];
		if (c0 - ch < 0 || c0 + ch >= image.length!0 - 1 ||
			c1 - ch < 0 || c1 + ch >= image.length!1 - 1)	continue;
		auto window = image[corner[0] - ch.. corner[0] + ch, corner[1] - ch.. corner[1] + ch, 0..$];
		foreach(pix; window.pack!1.byElement) {
			pix[] = color[];
		}
	}
}