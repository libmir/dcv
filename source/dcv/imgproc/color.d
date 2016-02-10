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
private import std.traits : CommonType, isFloatingPoint, isAssignable, isNumeric;
private import std.algorithm.iteration : sum, each, reduce, map;
private import std.algorithm.mutation : copy;
private import std.algorithm.comparison : equal;
private import std.algorithm : swap;
private import std.range : zip, array, iota;
private import std.parallelism : parallel;
private import std.exception : enforce;


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

/**
 * Convert RGB image to HSV color format.
 * 
 * If HSV is represented as floating point, H is 
 * represented as 0-360 (degrees), S and V are 0.0-1.0.
 * If is integral, S, and V are 0-100.
 * 
 * Depending on the RGB (input) type, values are treated in the
 * algorithm to be ranged as 0-255 for ubyte, 0-65535 for ushort, 
 * and 0-1 for floating point types.
 * 
 * params:
 * range = RGB image version, which gets converted to HVS.
 * prealloc = Pre-allocated range, where HSV image will be copied. Default
 * argument is an empty slice, where new data is allocated and returned. If given 
 * slice is not of corresponding shape(range.shape[0], range.shape[1], 3), it is 
 * discarded and allocated anew.
 * 
 * return:
 * Returns HSV verion of the given RGB image.
 */
Slice!(3, R*) rgb2hsv(R, V)(Slice!(3, V*) range, 
	Slice!(3, R*) prealloc = emptySlice!(3, R)) @trusted
	if (isNumeric!R && isNumeric!V)
{
	import std.algorithm.comparison : max, min;
	static assert(R.max >= 360, "Invalid output type for HSV (R.max >= 360)");

	enforce(range.length!2 == 3, "Invalid channel count.");

	if (prealloc.empty || prealloc.shape[].equal(range.shape[])) {
		prealloc = uninitializedArray!(R[])(range.length!0*range.length!1*3)
			.sliced(range.length!0, range.length!1, 3);
	}

	foreach (rgb, hsv; lockstep(range.pack!1.byElement, prealloc.pack!1.byElement)) {
		static if ( is (V == ubyte) ) {
			auto r = cast(float)(rgb[0]) / 255.;
			auto g = cast(float)(rgb[1]) / 255.;
			auto b = cast(float)(rgb[2]) / 255.;
		} else static if ( is (V == ushort)) {
			auto r = cast(float)(rgb[0]) / 65535.;
			auto g = cast(float)(rgb[1]) / 65535.;
			auto b = cast(float)(rgb[2]) / 65535.;
		} else static if ( isFloatingPoint!V) {
			// assumes rgb value range 0-1
			auto r = cast(float)(rgb[0]);
			auto g = cast(float)(rgb[1]);
			auto b = cast(float)(rgb[2]);
		} else {
			static assert(0, "Invalid RGB input type: " ~ V.stringof);
		}

		auto cmax = max(r, max(g, b));
		auto cmin = min(r, min(g, b));
		auto cdelta = cmax - cmin;

		hsv[0] = cast(R)((cdelta == 0) ? 0 :
			(cmax == r) ? 60. * ((g - b)  / cdelta) :
			(cmax == g) ? 60. * ((b - r) / cdelta + 2) :
			((r - g) / cdelta + 4));

		if (hsv[0] < 0.0)
			hsv[0] += 360.0;

		static if (isFloatingPoint!R) {
			hsv[1] = cast(R)(cmax == 0 ? 0 : cdelta / cmax);
			hsv[2] = cast(R)(cmax);
		} else {
			hsv[1] = cast(R)(100 * cmax == 0 ? 0 : cdelta / cmax);
			hsv[2] = cast(R)(100 * cmax);
		} 

	}
	return prealloc;
}

/**
 * Convert HSV image to RGB color format.
 * 
 * HSV is represented in floating point, where
 * H is 0-360 degrees, S and V is 0.0-1.0. 
 * 
 * Output range values are based on the output type cast - ubyte will
 * range RGB values to be 0-255, ushort 0-65535, and floating types
 * 0.0-1.0. Other types are not supported.
 * 
 * params:
 * range = RGB image version, which gets converted to HVS.
 * prealloc = Pre-allocated range, where HSV image will be copied. Default
 * argument is an empty slice, where new data is allocated and returned. If given 
 * slice is not of corresponding shape(range.shape[0], range.shape[1], 3), it is 
 * discarded and allocated anew.
 * 
 * return:
 * Returns HSV verion of the given RGB image.
 */
Slice!(3, R*) hsv2rgb(R, V)(Slice!(3, V*) range, 
	Slice!(3, R*) prealloc = emptySlice!(3, R)) @trusted
	if (isNumeric!R && isNumeric!V && isFloatingPoint!V)
{
	import std.math : fabs;
	enforce(range.length!2 == 3, "Invalid channel count.");

	if (prealloc.empty || prealloc.shape[].equal(range.shape[])) {
		prealloc = uninitializedArray!(R[])(range.length!0*range.length!1*3)
			.sliced(range.length!0, range.length!1, 3);
	}

	float [3] _rgb;
	immutable hhswitch = [ 
		[0, 1, 2],
		[1, 0, 2],
		[2, 0, 1],
		[2, 1, 0],
		[1, 2, 0],
		[0, 2, 1]
	];

	foreach (hsv, rgb; lockstep(range.pack!1.byElement, prealloc.pack!1.byElement)) {
		auto h = hsv[0];
		auto s = hsv[1];
		auto v = hsv[2];

		float c = v*s;
		float x = c * (1. - fabs((h / 60.) % 2 - 1));
		float m = v - c;

		int hh = cast(int)(h / 60.);
		_rgb = [c, x, 0.];

		static if (isFloatingPoint!R) {
			rgb[0] = cast(R)((_rgb[hhswitch[hh][0]]+m));
			rgb[1] = cast(R)((_rgb[hhswitch[hh][1]]+m));
			rgb[2] = cast(R)((_rgb[hhswitch[hh][2]]+m));
		} else static if (is (R == ubyte)) {
			rgb[0] = cast(R)((_rgb[hhswitch[hh][0]]+m)*255.);
			rgb[1] = cast(R)((_rgb[hhswitch[hh][1]]+m)*255.);
			rgb[2] = cast(R)((_rgb[hhswitch[hh][2]]+m)*255.);
		} else static if (is (R == ushort) ) {
			rgb[0] = cast(R)((_rgb[hhswitch[hh][0]]+m)*65535.);
			rgb[1] = cast(R)((_rgb[hhswitch[hh][1]]+m)*65535.);
			rgb[2] = cast(R)((_rgb[hhswitch[hh][2]]+m)*65535.);
		} else {
			static assert(0, "Output type is not supported: " ~ R.stringof);
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