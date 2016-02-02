module dcv.imgproc.color;

/*
 * Color format convertion module.
 */

private import std.experimental.ndslice;

private import dcv.core.utils;

private import std.array : uninitializedArray;
private import std.traits : CommonType, isFloatingPoint;
private import std.algorithm.iteration : sum, each, reduce;
private import std.algorithm.comparison : equal;
private import std.range : put;

/**
 * RGB to Grayscale convertion strategy.
 */
enum Rgb2GrayConvertion : size_t {
	MEAN, /// Mean the RGB values and assign to gray.
	LUMINANCE_PRESERVE /// Use luminance preservation technique (0.2126R + 0.715G + 0.0722B). 
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
	Rgb2GrayConvertion conv = Rgb2GrayConvertion.LUMINANCE_PRESERVE) {

	if (prealloc.empty) {
		if (!(range.shape[0..2][].equal(prealloc.shape[0..2][])))
			prealloc = uninitializedArray!(V[])(range.shape[0]*range.shape[1])
				.sliced(range.shape[0], range.shape[1]);
	}

	real [3] mltp; 

	if (conv == Rgb2GrayConvertion.MEAN) {
		mltp[] = 1.;
	} else {
		mltp[0] = 0.2126;
		mltp[1] = 0.715;
		mltp[2] = 0.0722;
	}

	auto s = mltp[].sum;
	mltp[] /= s;

	for (size_t r = 0; r < range.shape[0]; ++r) {
		for (size_t c = 0; c < range.shape[1]; ++c) {
			prealloc[r, c] = cast(V)(
				range[r, c, 0]*mltp[0] +
				range[r, c, 1]*mltp[1] +
				range[r, c, 2]*mltp[2]);
		}
	}
	return prealloc;
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
	Rgb2GrayConvertion conv = Rgb2GrayConvertion.LUMINANCE_PRESERVE) {

	// TODO: implement rgb2gray and bgr2gray as same function - organize better!

	if (prealloc.empty || (range.shape[0..2][]).equal(prealloc.shape[0..2][]))
		prealloc = uninitializedArray!(V[])(range.shape.reduce!"a*b")
			.sliced(range.shape[0], range.shape[1]);

	real [3] mltp; 

	if (conv == Rgb2GrayConvertion.MEAN) {
		mltp[] = 1.;
	} else {
		mltp[0] = 0.2126;
		mltp[1] = 0.715;
		mltp[2] = 0.0722;
	}

	auto s = mltp[].sum;
	mltp[] /= s;

	for (size_t r = 0; r < range.shape[0]; ++r) {
		for (size_t c = 0; c < range.shape[1]; ++c) {
			prealloc[r, c] = cast(V)(
				range[r, c, 0]*mltp[0] +
				range[r, c, 1]*mltp[1] +
				range[r, c, 2]*mltp[2]);
		}
	}
	return prealloc;
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
	Slice!(3, V*) prealloc = emptySlice!(2, V)) {
	if (prealloc.empty || (range.shape[0..2][]).equal(prealloc.shape[0..2][]) || prealloc.shape[2] != 3)
		prealloc = uninitializedArray!(V[])(range.shape.reduce!"a*b"*3)
			.sliced(range.shape[0], range.shape[1], 3);

	for (size_t r = 0; r < range.shape[0]; ++r) {
		for (size_t c = 0; c < range.shape[1]; ++c) {
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
