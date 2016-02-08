module dcv.imgproc.filter;

/**
 * Module introduces image filtering functions and utilities.
 * 
 * v0.1 norm:
 * gaussian (done)
 * sobel
 * scharr
 * prewitt
 * canny
 */

private import std.experimental.ndslice;

private import std.traits : allSameType, allSatisfy, isFloatingPoint, isNumeric;
private import std.range : iota, array, lockstep;
private import std.exception : enforce;
private import std.math : abs, PI, floor, exp, pow;
private import std.algorithm.iteration : map, sum, each;
private import std.algorithm : copy;


/**
 * Instantiate 2D gaussian kernel.
 */
Slice!(2, V*) gaussian(V)(real sigma, size_t width, size_t height) pure {

	static assert(isFloatingPoint!V, "Gaussian kernel can be constructed "
		"only using floating point types.");

	enforce(width > 2 && height > 2 && sigma > 0, "Invalid kernel values");

	auto h = new V[width*height].sliced(height, width);

	int arrv_w = -(cast(int)width-1)/2;
	int arrv_h = -(cast(int)height-1)/2;
	float sgm = 2*(sigma^^2);

	// build rows
	foreach(r; 0..height) {
		arrv_w.iota(-arrv_w+1)
			.map!(e => cast(V)(e^^2))
				.array
				.copy(h[r]);
	}

	// build columns
	foreach(c; 0..width) {
		auto cadd = arrv_h.iota(-arrv_h+1)
			.map!(e => cast(V)(e^^2))
				.array;
		h[0..height, c][] += cadd[];
		h[0..height, c].map!((ref v) => v = (-(v) / sgm).exp).copy(h[0..height, c]);
	}

	// normalize
	h[] /= h.byElement.sum;

	return h;
}

unittest {
	// TODO: design the test

	auto fg = gaussian!float(1.0, 3, 3);
	auto dg = gaussian!double(1.0, 3, 3);
	auto rg = gaussian!real(1.0, 3, 3);

	import std.traits;

	static assert(__traits(compiles, gaussian!int(1, 3, 3)) == false, 
		"Integral test failed in gaussian kernel.");
}
