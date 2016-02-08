module dcv.imgproc.color;

/*
 * Color format convertion module.
 * 
 * v0.1 norm:
 * rgb2gray vice versa (done)
 * hsv2rgb -||-
 * hls2rgb -||-
 * lab2rgb -||-
 * luv2rgb -||-
 * luv2rgb -||-
 * 
 * v0.1+:
 * bayer2rgb - maybe move to v0.1 norm?
 */

private import std.experimental.ndslice;

private import dcv.core.utils;

private import std.array : uninitializedArray;
private import std.traits : CommonType, isFloatingPoint, isAssignable;
private import std.algorithm.iteration : sum, each, reduce, map;
private import std.algorithm.mutation : copy;
private import std.algorithm.comparison : equal;
private import std.algorithm : swap;
private import std.range : zip, array, iota;
private import std.parallelism : parallel;

/**
 * RGB to Grayscale convertion strategy.
 */
enum Rgb2GrayConvertion : size_t {
	MEAN = 0, /// Mean the RGB values and assign to gray.
	LUMINANCE_PRESERVE = 1 /// Use luminance preservation technique (0.2126R + 0.715G + 0.0722B). 
}



/**
 * Convert RGB image to grayscale.
 * 
 * params:
 * range = Input image range. Should have 3 channels, represented 
 * as R, G and B respectivelly in that order.
 * prealloc = Pre-allocated range, where grayscale image will be copied. Default
 * argument is an empty slice, where new data is allocated and returned. If given 
 * slice is not of corresponding shape(range.shape[0], range.shape[1]), it is 
 * discarded and allocated anew.
 * conv = Convertion strategy - mean, or luminance preservation.
 * 
 * return:
 * Returns grayscale version of the given RGB image, of the same size.
 */
Slice!(2, V*) rgb2gray(V)(Slice!(3, V*) range, 
	Slice!(2, V*) prealloc = emptySlice!(2, V), 
	Rgb2GrayConvertion conv = Rgb2GrayConvertion.LUMINANCE_PRESERVE) pure nothrow @trusted {

	auto m = rgb2GrayMltp[conv].map!(a => cast(real)a).array;
	m[] /= m.sum;

	return rgb2grayImpl(range, prealloc, m);
}

/**
 * Convert BGR image to grayscale.
 * 
 * Same as rgb2gray, but follows swapped channels if luminance preservation
 * is chosen as convertion strategy.
 * 
 * params:
 * range = Input image range. Should have 3 channels, represented 
 * as B, G and R respectivelly in that order.
 * prealloc = Pre-allocated range, where grayscale image will be copied. Default
 * argument is an empty slice, where new data is allocated and returned. If given 
 * slice is not of corresponding shape(range.shape[0], range.shape[1]), it is 
 * discarded and allocated anew.
 * conv = Convertion strategy - mean, or luminance preservation.
 * 
 * return:
 * Returns grayscale version of the given BGR image, of the same size.
 */
Slice!(2, V*) bgr2gray(V)(Slice!(3, V*) range, 
	Slice!(2, V*) prealloc = emptySlice!(2, V), 
	Rgb2GrayConvertion conv = Rgb2GrayConvertion.LUMINANCE_PRESERVE) pure nothrow @trusted {

	auto m = rgb2GrayMltp[conv].map!(a => cast(real)a).array;
	m[] /= m.sum;
	m[0].swap(m[2]);

	return rgb2grayImpl(range, prealloc, m);
}

/**
 * Convert gray image to RGB.
 * 
 * Uses grayscale value and assigns it's value
 * to each of three channels for the RGB image version.
 * 
 * params:
 * range = Grayscale image version, to be converted to the RGB.
 * prealloc = Pre-allocated range, where RGB image will be copied. Default
 * argument is an empty slice, where new data is allocated and returned. If given 
 * slice is not of corresponding shape(range.shape[0], range.shape[1], 3), it is 
 * discarded and allocated anew.
 * 
 * return:
 * Returns RGB version of the given grayscale image.
 */
Slice!(3, V*) gray2rgb(V)(Slice!(2, V*) range, 
	Slice!(3, V*) prealloc = emptySlice!(3, V)) pure nothrow @trusted {

	if (prealloc.empty || (range.shape[0..2][]).equal(prealloc.shape[0..2][]) || prealloc.shape[2] != 3)
		prealloc = uninitializedArray!(V[])(range.length!0*range.length!1*3)
			.sliced(range.length!0, range.length!1, 3);

	for (size_t r = 0; r < range.length!0; ++r) {
		for (size_t c = 0; c < range.length!1; ++c) {
			immutable v = range[r, c];
			prealloc[r, c, 0] = v;
			prealloc[r, c, 1] = v;
			prealloc[r, c, 2] = v;
		}
	}

	return prealloc;
}

unittest {
	// TODO: design the test...
}


private:

immutable real [][] rgb2GrayMltp = [
	[0.3333, 0.3333, 0.3333],
	[0.2126, 0.715, 0.0722]
];

Slice!(2, V*) rgb2grayImpl(V)(Slice!(3, V*) range, 
	Slice!(2, V*) prealloc, in real[] m) pure nothrow @trusted {
	if (prealloc.empty) {
		if (!(range.shape[0..2][].equal(prealloc.shape[0..2][])))
			prealloc = uninitializedArray!(V[])(range.shape[0]*range.shape[1])
				.sliced(range.shape[0], range.shape[1]);	
	}

	auto rp = range.pack!1;

	auto rows = rp.length!0;
	auto cols = rp.length!1;

	for (size_t i = 0; i < rows; ++i) {
		auto g_row = prealloc[i, 0..cols];
		auto rgb_row = rp[i, 0..cols];
		size_t j = 0;
		auto rgb = rgb_row[0];
		for (; j < cols; ++j) {
			g_row[j] = cast(V) (
				rgb[0]*m[0] +
				rgb[1]*m[1] +
				rgb[2]*m[2]
				);
		}
	}

	/*
	// this is ~4x slower than nested foor loops?
	range.pack!1
		.byElement
		.map!(rgb => cast(ubyte)(rgb[0]*m[0] + rgb[1]*m[1] + rgb[2]*m[2]))
		.copy(prealloc.byElement);
	*/

	return prealloc;
}