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

Slice!(2, T*) filterNonMaximum(T)(Slice!(2, T*) image, size_t filterSize = 10) {

	assert(!image.empty && filterSize);

	typeof(image) lmsw;  // local maxima search window
	int lms_r, lms_c;
	int win_rows, win_cols;
	float lms_val;
	auto rows = image.length!0;
	auto cols = image.length!1;

	for (int br = 0; br < rows; br += filterSize / 2) {
		for (int bc = 0; bc < cols; bc += filterSize / 2) {
			win_rows = cast(int)((br + filterSize < rows) ? 
				filterSize : filterSize - ((br + filterSize) - rows) - 1);
			win_cols = cast(int)((bc + filterSize < cols) ? 
				filterSize : filterSize - ((bc + filterSize) - cols) - 1);

			if (win_rows <= 0 || win_cols <= 0) {
				continue;
			}

			lmsw = image[br..br+win_rows, bc..bc+win_cols];

			lms_val = -1;
			for (int r = 0; r < lmsw.length!0; r++) {
				for (int c = 0; c < lmsw.length!1; c++) {
					if (lmsw[r, c] > lms_val) {
						lms_val = lmsw[r, c];
						lms_r = r;
						lms_c = c;
					}
				}
			}
			lmsw[] = cast(T)0;
			if (lms_val != -1) {
				lmsw[lms_r, lms_c] = lms_val;
			}
		}
	}

	return image;
}
