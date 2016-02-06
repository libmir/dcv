module dcv.imgproc.filter;

/**
 * Module introduces image filtering functions and utilities.
 */

private import std.experimental.ndslice;

private import std.traits : allSameType, allSatisfy, isIntegral, isNumeric;
private import std.range : iota, array, lockstep;
private import std.exception : enforce;
private import std.math : abs, PI, floor, exp, pow;
private import std.algorithm.iteration : map, sum, each;
private import std.algorithm : copy;



/**
 * Instantiate 2D gaussian kernel.
 */
auto gaussian(V)(real sigma, size_t width, size_t height) if (isNumeric!V) {

	enforce(width > 2 && height > 2 && sigma > 0, "Invalid kernel values");

	/**
	matlab imlementation for square kernel
	m = 5; n = 5;
	sigma = 1;
	[h1, h2] = meshgrid(-(m-1)/2:(m-1)/2, -(n-1)/2:(n-1)/2);
	hg = exp(- (h1.^2+h2.^2) / (2*sigma^2));
	h = hg ./ sum(hg(:));
	*/

	auto h = new V[width*height].sliced(height, width);

	int arrv_w = -(cast(int)width-1)/2;
	int arrv_h = -(cast(int)height-1)/2;
	float sgm = 2*(sigma^^2);

	foreach(r; 0..height) {
		arrv_w.iota(-arrv_w+1)
			.map!(e => cast(V)(e^^2))
			.array
			.copy(h[r]);
	}

	foreach(c; 0..width) {
		auto cadd = arrv_h.iota(-arrv_h+1)
			.map!(e => cast(V)(e^^2))
			.array;
		h[0..height, c][] += cadd[];
		h[0..height, c].map!((ref v) => v = (-(v) / sgm).exp).copy(h[0..height, c]);
	}

	h[] /= h.byElement.sum;

	return h;
}

