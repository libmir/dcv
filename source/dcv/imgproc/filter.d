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
Slice!(2, V*) gaussian(V = real)(real sigma, size_t width, size_t height) pure {

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

/**
 * Create negative laplacian 3x3 kernel matrix.
 * 
 * Creates laplacian kernel matrix using
 * 
 * I - image
 * Laplacian(I) =   
 *              [a/4,    (1-a)/4,   a/4]
 *    4/(a+1) * |(1-a)/4   -1   (1-a)/4|
 *              [a/4,    (1-a)/4,   a/4]
 * 
 */
Slice!(2, T*) laplacian(T = real)(real a = 0.) pure nothrow 
    if (isNumeric!T) 
    in {
        assert(a >= 0. && a <= 1.);
} body {
    auto k = new T[9].sliced(3, 3);
    auto m = 4. / (a + 1.);
    auto e1 = (a / 4.) * m;
    auto e2 = ((1. - a) / 4.) * m;
    k[0, 0] = e1;
    k[0, 2] = e1;
    k[2, 0] = e1;
    k[2, 2] = e1;
    k[0, 1] = e2;
    k[1, 0] = e2;
    k[1, 2] = e2;
    k[2, 1] = e2;
    k[1, 1] = -m;
    return k;
}

unittest {
    import std.algorithm.comparison : equal;
    auto l4 = laplacian(); // laplacian!real(0);
    assert(equal(l4.byElement, [0, 1, 0, 1, -4, 1, 0, 1, 0]));
}


/**
 * Create laplacian of gaussian (LoG) filter kernel.
 * 
 * params:
 * sigma = gaussian sigma variance value
 * width = width of the kernel matrix
 * height = height of the kernel matrix
 */
Slice!(2, T*) laplacianOfGaussian(T = real)(real sigma, size_t width, size_t height) {
    import std.traits : isSigned;
    static assert(isSigned!T);

    import std.algorithm.comparison : max;
    import std.math : E;

    auto k = new T[width*height].sliced(height, width);

    auto ts = -1./(PI*(sigma^^4));
    auto ss = sigma^^2;
    auto ss2 = 2.*ss;
    auto w_h = cast(T)max(1, width / 2);
    auto h_h = cast(T)max(1, height / 2);

    foreach(i; iota(height)) {
        foreach(j; iota(width)) {
            auto xx = (cast(T)j - w_h);
            auto yy = (cast(T)i - h_h);
            xx *= xx;
            yy *= yy;
            auto xy = (xx+yy) / ss2;
            k[i, j] = ts * (1. - xy) * exp(-xy);
        }
    }

    k[] -= cast(T)(cast(float)k.byElement.sum / cast(float)(width*height));
    return k;
}

unittest {
    import std.algorithm.comparison : equal;
    import std.math : approxEqual;
    auto log = laplacianOfGaussian!float(0.84f, 3, 3);
    auto expected = [
        0.147722, -0.00865228, 0.147722, 
        -0.00865228, -0.556277, -0.00865228, 
        0.147722, -0.00865228, 0.147722].sliced(3, 3);
    assert(log.byElement.array.equal!approxEqual(expected.byElement.array));
}

enum GradientDirection {
    DIR_X, // x direction (x partial gradients)
    DIR_Y, // y direction (y partial gradients)
    DIAG, // diagonal, from top-left to bottom right
    DIAG_INV, // inverse diagonal, from top-right to bottom left
}

Slice!(2, T*) sobel(T = real)(GradientDirection direction) nothrow pure @trusted {
    return sobelScharr!(T)(direction, cast(T)1, cast(T)2);
}

Slice!(2, T*) scharr(T = real)(GradientDirection direction) nothrow pure @trusted {
    return sobelScharr!(T)(direction, cast(T)3, cast(T)10);
}

private Slice!(2, T*) sobelScharr(T)(GradientDirection direction, T lv, T hv) nothrow pure @trusted {
    final switch(direction) {
        case GradientDirection.DIR_X:
            return [
                -lv, 0, lv,
                -hv, 0, hv,
                -lv, 0, lv
            ].map!(a => cast(T)a).array.sliced(3, 3);
        case GradientDirection.DIR_Y:
            return [
                -lv, -hv, -lv,
                0, 0, 0,
                lv, hv, lv
            ].map!(a => cast(T)a).array.sliced(3, 3);
        case GradientDirection.DIAG:
            return [
                -hv, -lv, 0,
                -lv, 0, lv,
                0, lv, hv
            ].map!(a => cast(T)a).array.sliced(3, 3);
        case GradientDirection.DIAG_INV:
            return [
                0, -lv, -hv,
                lv, 0, -lv,
                hv, lv, 0
            ].map!(a => cast(T)a).array.sliced(3, 3);
    }
}

// test sobel and scharr
unittest {
    import std.algorithm.comparison : equal;
    auto s = sobelScharr!int(GradientDirection.DIR_X, 1, 2);
    auto expected = (cast(int[])[
            -1, 0, 1,
            -2, 0, 2,
            -1, 0, 1
        ]).sliced(3, 3);
    assert(s.byElement.array.equal(expected.byElement.array));
}

unittest {
    import std.algorithm.comparison : equal;
    auto s = sobelScharr!int(GradientDirection.DIR_Y, 1, 2);
    auto expected = (cast(int[])[
            -1, -2, -1,
            0, 0, 0,
            1, 2, 1
        ]).sliced(3, 3);
    assert(s.byElement.array.equal(expected.byElement.array));
}

unittest {
    import std.algorithm.comparison : equal;
    auto s = sobelScharr!int(GradientDirection.DIAG, 1, 2);
    auto expected = (cast(int[])[
            -2, -1, 0,
            -1, 0, 1,
            0, 1, 2
        ]).sliced(3, 3);
    assert(s.byElement.array.equal(expected.byElement.array));
}

unittest {
    import std.algorithm.comparison : equal;
    auto s = sobelScharr!int(GradientDirection.DIAG_INV, 1, 2);
    auto expected = (cast(int[])[
            0, -1, -2,
            1, 0, -1,
            2, 1, 0
        ]).sliced(3, 3);
    assert(s.byElement.array.equal(expected.byElement.array));
}

enum NonMaximumFilter {
    POINT,
    LINE
}

/**
 * Perform non-maxima filtering of the image.
 * 
 * note: 
 * proxy function, not a proper API! 
 * 
 * TODO: Implement non-maxima supression for edge detection (canny), and
 * make the interface of the function fit both needs.
 * 
 */
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
                lmsw[lms_r, lms_c] = cast(T)lms_val;
            }
        }
    }
    return image;
}
