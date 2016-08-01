/**
Module introduces image filtering functions and utilities.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).

$(DL Module contains:
    $(DD 
            $(BIG Filter kernel generators: )
            $(LINK2 #gaussian, gaussian)
            $(LINK2 #laplacian,laplacian)
            $(LINK2 #laplacianOfGaussian,laplacianOfGaussian)
            $(LINK2 #sobel, sobel)
            $(LINK2 #scharr,scharr)
            $(LINK2 #prewitt,prewitt)
    )
    $(DD 
            $(BIG Image processing functions: )
            $(LINK2 #filterNonMaximum, filterNonMaximum)
            $(LINK2 #calcPartialDerivatives,calcPartialDerivatives)
            $(LINK2 #calcGradients,calcGradients)
            $(LINK2 #nonMaximaSupression,nonMaximaSupression)
            $(LINK2 #canny,canny)
            $(LINK2 #bilateralFilter,bilateralFilter)
            $(LINK2 #medianFilter,medianFilter)
    )
)

*/

module dcv.imgproc.filter;

import std.experimental.ndslice;

import std.traits : allSameType, allSatisfy, isFloatingPoint, isNumeric;
import std.range : iota, array, lockstep;
import std.exception : enforce;
import std.math : abs, PI, floor, exp, pow;
import std.algorithm.iteration : map, sum, each;
import std.algorithm.sorting : topN;
import std.algorithm.comparison : max;
import std.algorithm.mutation : copy;
import std.array : uninitializedArray;
import std.parallelism : parallel, taskPool;


import dcv.core.algorithm;
import dcv.core.utils;


/**
Instantiate 2D gaussian kernel.
*/
Slice!(2, V*) gaussian(V = real)(real sigma, size_t width, size_t height) pure
{

    static assert(isFloatingPoint!V, "Gaussian kernel can be constructed " "only using floating point types.");

    enforce(width > 2 && height > 2 && sigma > 0, "Invalid kernel values");

    auto h = new V[width * height].sliced(height, width);

    int arrv_w = -(cast(int)width - 1) / 2;
    int arrv_h = -(cast(int)height - 1) / 2;
    float sgm = 2 * (sigma ^^ 2);

    // build rows
    foreach (r; 0 .. height)
    {
        arrv_w.iota(-arrv_w + 1).map!(e => cast(V)(e ^^ 2)).array.copy(h[r]);
    }

    // build columns
    foreach (c; 0 .. width)
    {
        auto cadd = arrv_h.iota(-arrv_h + 1).map!(e => cast(V)(e ^^ 2)).array;
        h[0 .. height, c][] += cadd[];
        h[0 .. height, c].map!((ref v) => v = (-(v) / sgm).exp).copy(h[0 .. height, c]);
    }

    // normalize
    h[] /= h.byElement.sum;

    return h;
}

unittest
{
    // TODO: design the test

    auto fg = gaussian!float(1.0, 3, 3);
    auto dg = gaussian!double(1.0, 3, 3);
    auto rg = gaussian!real(1.0, 3, 3);

    import std.traits;

    static assert(__traits(compiles, gaussian!int(1, 3, 3)) == false, "Integral test failed in gaussian kernel.");
}

/**
Create negative laplacian 3x3 kernel matrix.

Creates laplacian kernel matrix using

$(D_CODE
I - image
Laplacian(I) =   
             [a/4,    (1-a)/4,   a/4]
   4/(a+1) * |(1-a)/4   -1   (1-a)/4|
             [a/4,    (1-a)/4,   a/4]
)

*/
Slice!(2, T*) laplacian(T = real)(real a = 0.) pure nothrow if (isNumeric!T)
in
{
    assert(a >= 0. && a <= 1.);
}
body
{
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

///
unittest
{
    import std.algorithm.comparison : equal;

    auto l4 = laplacian(); // laplacian!real(0);
    assert(equal(l4.byElement, [0, 1, 0, 1, -4, 1, 0, 1, 0]));
}

/**
Create laplacian of gaussian $(LINK3 http://homepages.inf.ed.ac.uk/rbf/HIPR2/log.htm, (LoG)) filter kernel.

Params:
    sigma = gaussian sigma variance value
    width = width of the kernel matrix
    height = height of the kernel matrix
*/
Slice!(2, T*) laplacianOfGaussian(T = real)(real sigma, size_t width, size_t height)
{
    import std.traits : isSigned;

    static assert(isSigned!T);

    import std.algorithm.comparison : max;
    import std.math : E;

    auto k = new T[width * height].sliced(height, width);

    auto ts = -1. / (PI * (sigma ^^ 4));
    auto ss = sigma ^^ 2;
    auto ss2 = 2. * ss;
    auto w_h = cast(T)max(1, width / 2);
    auto h_h = cast(T)max(1, height / 2);

    foreach (i; iota(height))
    {
        foreach (j; iota(width))
        {
            auto xx = (cast(T)j - w_h);
            auto yy = (cast(T)i - h_h);
            xx *= xx;
            yy *= yy;
            auto xy = (xx + yy) / ss2;
            k[i, j] = ts * (1. - xy) * exp(-xy);
        }
    }

    k[] -= cast(T)(cast(float)k.byElement.sum / cast(float)(width * height));
    return k;
}

///
unittest
{
    import std.algorithm.comparison : equal;
    import std.math : approxEqual;

    auto log = laplacianOfGaussian!float(0.84f, 3, 3);
    auto expected = [0.147722, -0.00865228, 0.147722, -0.00865228, -0.556277, -0.00865228,
        0.147722, -0.00865228, 0.147722].sliced(3, 3);
    assert(log.byElement.array.equal!approxEqual(expected.byElement.array));
}

enum GradientDirection
{
    DIR_X, // x direction (x partial gradients)
    DIR_Y, // y direction (y partial gradients)
    DIAG, // diagonal, from top-left to bottom right
    DIAG_INV, // inverse diagonal, from top-right to bottom left
}

/**
Convolution kernel type for edge detection.
*/
public enum EdgeKernel
{
    SIMPLE,
    SOBEL,
    SCHARR,
    PREWITT
}

/// Create a Sobel edge kernel.
Slice!(2, T*) sobel(T = real)(GradientDirection direction) nothrow pure @trusted
{
    return edgeKernelImpl!(T)(direction, cast(T)1, cast(T)2);
}

/// Create a Scharr edge kernel.
Slice!(2, T*) scharr(T = real)(GradientDirection direction) nothrow pure @trusted
{
    return edgeKernelImpl!(T)(direction, cast(T)3, cast(T)10);
}

/// Create a Prewitt edge kernel.
Slice!(2, T*) prewitt(T = real)(GradientDirection direction) nothrow pure @trusted
{
    return edgeKernelImpl!(T)(direction, cast(T)1, cast(T)1);
}

/// Create a kernel of given type.
Slice!(2, T*) edgeKernel(T)(EdgeKernel kernelType, GradientDirection direction) nothrow pure @trusted
{
    typeof(return) k;
    final switch (kernelType)
    {
    case EdgeKernel.SOBEL:
        k = sobel!T(direction);
        break;
    case EdgeKernel.SCHARR:
        k = scharr!T(direction);
        break;
    case EdgeKernel.PREWITT:
        k = prewitt!T(direction);
        break;
    case EdgeKernel.SIMPLE:
        break;
    }
    return k;
}

private Slice!(2, T*) edgeKernelImpl(T)(GradientDirection direction, T lv, T hv) nothrow pure @trusted
{
    final switch (direction)
    {
    case GradientDirection.DIR_X:
        return [-lv, 0, lv, -hv, 0, hv, -lv, 0, lv].map!(a => cast(T)a).array.sliced(3, 3);
    case GradientDirection.DIR_Y:
        return [-lv, -hv, -lv, 0, 0, 0, lv, hv, lv].map!(a => cast(T)a).array.sliced(3, 3);
    case GradientDirection.DIAG:
        return [-hv, -lv, 0, -lv, 0, lv, 0, lv, hv].map!(a => cast(T)a).array.sliced(3, 3);
    case GradientDirection.DIAG_INV:
        return [0, -lv, -hv, lv, 0, -lv, hv, lv, 0].map!(a => cast(T)a).array.sliced(3, 3);
    }
}

// test sobel and scharr
unittest
{
    import std.algorithm.comparison : equal;

    auto s = edgeKernelImpl!int(GradientDirection.DIR_X, 1, 2);
    auto expected = (cast(int[])[-1, 0, 1, -2, 0, 2, -1, 0, 1]).sliced(3, 3);
    assert(s.byElement.array.equal(expected.byElement.array));
}

unittest
{
    import std.algorithm.comparison : equal;

    auto s = edgeKernelImpl!int(GradientDirection.DIR_Y, 1, 2);
    auto expected = (cast(int[])[-1, -2, -1, 0, 0, 0, 1, 2, 1]).sliced(3, 3);
    assert(s.byElement.array.equal(expected.byElement.array));
}

unittest
{
    import std.algorithm.comparison : equal;

    auto s = edgeKernelImpl!int(GradientDirection.DIAG, 1, 2);
    auto expected = (cast(int[])[-2, -1, 0, -1, 0, 1, 0, 1, 2]).sliced(3, 3);
    assert(s.byElement.array.equal(expected.byElement.array));
}

unittest
{
    import std.algorithm.comparison : equal;

    auto s = edgeKernelImpl!int(GradientDirection.DIAG_INV, 1, 2);
    auto expected = (cast(int[])[0, -1, -2, 1, 0, -1, 2, 1, 0]).sliced(3, 3);
    assert(s.byElement.array.equal(expected.byElement.array));
}

/**
Perform non-maxima filtering of the image.

note: 
proxy function, not a proper API! 

*/
Slice!(2, T*) filterNonMaximum(T)(Slice!(2, T*) slice, size_t filterSize = 10)
{

    assert(!slice.empty && filterSize);

    typeof(slice) lmsw; // local maxima search window
    int lms_r, lms_c;
    int win_rows, win_cols;
    float lms_val;
    auto rows = slice.length!0;
    auto cols = slice.length!1;

    for (int br = 0; br < rows; br += filterSize / 2)
    {
        for (int bc = 0; bc < cols; bc += filterSize / 2)
        {
            win_rows = cast(int)((br + filterSize < rows) ? filterSize : filterSize - ((br + filterSize) - rows) - 1);
            win_cols = cast(int)((bc + filterSize < cols) ? filterSize : filterSize - ((bc + filterSize) - cols) - 1);

            if (win_rows <= 0 || win_cols <= 0)
            {
                continue;
            }

            lmsw = slice[br .. br + win_rows, bc .. bc + win_cols];

            lms_val = -1;
            for (int r = 0; r < lmsw.length!0; r++)
            {
                for (int c = 0; c < lmsw.length!1; c++)
                {
                    if (lmsw[r, c] > lms_val)
                    {
                        lms_val = lmsw[r, c];
                        lms_r = r;
                        lms_c = c;
                    }
                }
            }
            lmsw[] = cast(T)0;
            if (lms_val != -1)
            {
                lmsw[lms_r, lms_c] = cast(T)lms_val;
            }
        }
    }
    return slice;
}

/**
Calculate partial derivatives of an slice.

Partial derivatives are calculated by convolving an slice with
[-1, 1] kernel, horizontally and vertically.
*/
void calcPartialDerivatives(T, V = T)(Slice!(2, T*) slice, ref Slice!(2, V*) fx, ref Slice!(2, V*) fy)
        if (isFloatingPoint!V)
in
{
    assert(!slice.empty);
}
body
{
    import std.range : iota;
    import std.array : array, uninitializedArray;
    import std.algorithm : equal, reduce;

    auto itemLength = slice.shape.reduce!"a*b";
    if (!fx.shape[].equal(slice.shape[]))
        fx = uninitializedArray!(V[])(itemLength).sliced(slice.shape);
    if (!fy.shape[].equal(slice.shape[]))
        fy = uninitializedArray!(V[])(itemLength).sliced(slice.shape);

    auto rows = slice.length!0;
    auto cols = slice.length!1;

    // calc mid-ground
    foreach (r; 1.iota(rows))
    {
        auto x_row = fx[r, 0 .. $];
        auto y_row = fy[r, 0 .. $];
        foreach (c; 1.iota(cols))
        {
            auto imrc = slice[r, c];
            x_row[c] = cast(V)(-1. * slice[r, c - 1] + imrc);
            y_row[c] = cast(V)(-1. * slice[r - 1, c] + imrc);
        }
    }

    // calc border edges
    auto x_row = fx[0, 0 .. $];
    auto y_row = fy[0, 0 .. $];

    foreach (c; 0.iota(cols - 1))
    {
        auto im_0c = slice[0, c];
        x_row[c] = cast(V)(-1. * im_0c + slice[0, c + 1]);
        y_row[c] = cast(V)(-1. * im_0c + slice[1, c]);
    }

    auto x_col = fx[0 .. $, 0];
    auto y_col = fy[0 .. $, 0];

    foreach (r; iota(rows - 1))
    {
        auto im_r_0 = slice[r, 0];
        x_col[r] = cast(V)(-1. * im_r_0 + slice[r, 1]);
        y_col[r] = cast(V)(-1. * im_r_0 + slice[r + 1, 0]);
    }

    // edges corner pixels
    fx[0, cols - 1] = cast(V)(-1 * slice[0, cols - 2] + slice[0, cols - 1]);
    fy[0, cols - 1] = cast(V)(-1 * slice[0, cols - 1] + slice[1, cols - 1]);
    fx[rows - 1, 0] = cast(V)(-1 * slice[rows - 1, 0] + slice[rows - 1, 1]);
    fy[rows - 1, 0] = cast(V)(-1 * slice[rows - 2, 0] + slice[rows - 1, 0]);
}

/**
Calculate gradient magnitude and orientation of an image slice.

Params:
    slice = Input slice of an image.
    mag = Output magnitude value of gradients.
    orient = Orientation value of gradients in radians.
    edgeKernelType = Optional convolution kernel type to calculate partial derivatives. 
    Default value is EdgeKernel.SIMPLE, which calls calcPartialDerivatives function
    to calculate derivatives. Other options will perform convolution with requested
    kernel type.
*/
void calcGradients(T, V = T)(Slice!(2, T*) slice, ref Slice!(2, V*) mag, ref Slice!(2, V*) orient,
        EdgeKernel edgeKernelType = EdgeKernel.SIMPLE) if (isFloatingPoint!V)
in
{
    assert(!slice.empty);
}
body
{
    import std.array : uninitializedArray;
    import std.math : sqrt, atan2;

    if (mag.shape[] != slice.shape[])
    {
        mag = uninitializedArray!(V[])(slice.length!0 * slice.length!1).sliced(slice.shape);
    }

    if (orient.shape[] != slice.shape[])
    {
        orient = uninitializedArray!(V[])(slice.length!0 * slice.length!1).sliced(slice.shape);
    }

    Slice!(2, V*) fx, fy;
    if (edgeKernelType == EdgeKernel.SIMPLE)
    {
        calcPartialDerivatives(slice, fx, fy);
    }
    else
    {
        import dcv.imgproc.convolution;

        Slice!(2, V*) kx, ky;
        kx = edgeKernel!V(edgeKernelType, GradientDirection.DIR_X);
        ky = edgeKernel!V(edgeKernelType, GradientDirection.DIR_Y);
        fx = slice.conv(kx);
        fy = slice.conv(ky);
    }

    foreach (i; 0 .. slice.length!0)
    {
        foreach (j; 0 .. slice.length!1)
        {
            mag[i, j] = cast(V)sqrt(fx[i, j] ^^ 2 + fy[i, j] ^^ 2);
            orient[i, j] = cast(V)atan2(fy[i, j], fx[i, j]);
        }
    }

}

/**
Edge detection impuls non-maxima supression.

Filtering used in canny edge detection algorithm - suppresses all 
edge impulses (gradient values along edges normal) except the peek value.

Params:
mag = Gradient magnitude.
orient = Gradient orientation of the same image source as magnitude.
prealloc = Optional pre-allocated buffer for output slice.

see:
dcv.imgproc.filter.calcGradients, dcv.imgproc.convolution
*/
Slice!(2, V*) nonMaximaSupression(T, V = T)(Slice!(2, T*) mag, Slice!(2, T*) orient, Slice!(2,
        V*) prealloc = emptySlice!(2, V))
in
{
    assert(!mag.empty && !orient.empty);
    assert(mag.shape[] == orient.shape[]);
}
body
{
    import std.array : uninitializedArray;
    import std.math : PI, abs;

    if (prealloc.shape[] != orient.shape[])
    {
        prealloc = uninitializedArray!(V[])(mag.length!0 * mag.length!1).sliced(mag.shape);
    }

    ulong[2] p0;
    ulong[2] p1;

    foreach (i; 1 .. mag.length!0 - 1)
    {
        foreach (j; 1 .. mag.length!1 - 1)
        {
            auto ang = orient[i, j];
            auto aang = abs(ang);

            immutable pi = 3.15;
            immutable pi8 = pi / 8.0;

            if (aang <= pi && aang > 7.0 * pi8) 
            {
                p0[0] = j - 1;
                p0[1] = i;
                p1[0] = j + 1;
                p1[1] = i;
            }
            else if (ang >= -7.0 * pi8 && ang < -5.0 * pi8)
            {
                p0[0] = j - 1;
                p0[1] = i - 1;
                p1[0] = j + 1;
                p1[1] = i + 1;
            }
            else if (ang <= 7.0 * pi8 && ang > 5.0 * pi8)
            {
                p0[0] = j + 1;
                p0[1] = i - 1;
                p1[0] = j - 1;
                p1[1] = i + 1;
            }
            else if (ang >= pi8 && ang < 3.0 * pi8)
            {
                p0[0] = j - 1;
                p0[1] = i + 1;
                p1[0] = j + 1;
                p1[1] = i - 1;
            }
            else if (ang <= -pi8 && ang > -3.0 * pi8)
            {
                p0[0] = j + 1;
                p0[1] = i + 1;
                p1[0] = j - 1;
                p1[1] = i - 1;
            }
            else if (ang >= -5.0 * pi8 && ang < -3.0 * pi8)
            {
                p0[0] = j;
                p0[1] = i - 1;
                p1[0] = j;
                p1[1] = i + 1;
            }
            else if (ang <= 5.0 * pi8 && ang > 3.0 * pi8)
            {
                p0[0] = j;
                p0[1] = i + 1;
                p1[0] = j;
                p1[1] = i - 1;
            } 
            else if (aang >= 0.0 && aang < pi8)
            {
                p0[0] = j + 1;
                p0[1] = i;
                p1[0] = j - 1;
                p1[1] = i;
            }

            if (mag[p1[1], p1[0]] <= mag[p0[1], p0[0]])
            {
                prealloc[i, j] = 0;
            }
            else
            {
                prealloc[i, j] = mag[i, j];
            }
        }
    }

    return prealloc;
}

/**
Perform canny filtering on an image to expose edges.

Params:
    slice = Input image slice.
    lowThresh = lower threshold value after non-maxima suppression.
    upThresh = upper threshold value after non-maxima suppression.
    edgeKernelType = Type of edge kernel used to calculate image gradients.
    prealloc = Optional pre-allocated buffer.
*/
Slice!(2, V*) canny(V, T)(Slice!(2, T*) slice, T lowThresh, T upThresh,
        EdgeKernel edgeKernelType = EdgeKernel.SOBEL, Slice!(2, V*) prealloc = emptySlice!(2, V))
{
    import dcv.imgproc.threshold;
    import dcv.core.algorithm : ranged;

    V upval = isFloatingPoint!V ? 1 : V.max;

    Slice!(2, float*) mag, orient;
    calcGradients(slice, mag, orient, edgeKernelType);
    auto nonmax = nonMaximaSupression(mag, orient);

    return nonmax.byElement.ranged(0, upval).array.sliced(nonmax.shape).threshold!V(lowThresh, upThresh);
}

/**
Perform canny filtering on an image to expose edges.

Convenience function to call canny with same lower and upper threshold values,
similar to dcv.imgproc.threshold.threshold.
*/
Slice!(2, V*) canny(V, T)(Slice!(2, T*) slice, T thresh,
        EdgeKernel edgeKernelType = EdgeKernel.SOBEL, Slice!(2, V*) prealloc = emptySlice!(2, V))
{
    return canny!(V, T)(slice, thresh, thresh, edgeKernelType, prealloc);
}

/**
$(LINK2 https://en.wikipedia.org/wiki/Bilateral_filter,Bilateral) filtering implementation.

Non-linear, edge-preserving and noise-reducing smoothing filtering algorithm.

Params:
    bc = Boundary condition test used to index the image slice.
    slice = Slice of the input image.
    sigma = Smoothing strength parameter.
    kernelSize = Size of convolution kernel. Must be odd number.
    prealloc = Optional pre-allocated result image buffer. If not of same shape as input slice, its allocated
        anew.

Returns:
    Slice of filtered image.
*/
Slice!(N, OutputType*) bilateralFilter(alias bc = neumann, InputType, OutputType = InputType, size_t N)(Slice!(N,
        InputType*) slice, float sigma, uint kernelSize, Slice!(N,
        OutputType*) prealloc = emptySlice!(N, OutputType)) if (N == 2)
in
{
    static assert(isBoundaryCondition!bc, "Invalid boundary condition test function.");
    assert(!slice.empty);
    assert(kernelSize % 2);
}
body
{
    import std.algorithm.comparison : max;
    import std.algorithm.iteration : reduce;
    import std.math : exp, sqrt;
    import std.parallelism : parallel;

    if (prealloc.empty || prealloc.shape != slice.shape)
    {
        prealloc = uninitializedArray!(OutputType[])(slice.shape.reduce!"a*b").sliced(slice.shape);
    }

    int ks = cast(int)kernelSize;
    int ksh = max(1, ks / 2);
    int rows = cast(int)slice.length!0;
    int cols = cast(int)slice.length!1;

    foreach (r; iota(rows).parallel)
    {
        auto mask = new float[ks * ks].sliced(ks, ks);
        foreach (c;  0 .. cols )
        {
            auto p_val = slice[r, c];

            // generate mask
            int i = 0;
            int j;
            foreach (int kr; r - ksh .. r + ksh + 1)
            {
                j = 0;
                auto rk = (r - kr) ^^ 2;
                foreach (int kc; c - ksh .. c + ksh + 1)
                {
                    auto ck = (c - kc) ^^ 2;
                    float c_val = exp(-0.5f * ((sqrt(cast(float)(ck + rk)) / sigma) ^^ 2) );
                    float s_val = exp(-0.5f * ((cast(float)(bc(slice, kr, kc) - p_val) / sigma) ^^ 2));
                    mask[i, j] = c_val * s_val;
                    ++j;
                }
                ++i;
            }

            // normalize mask and calculate result value.
            float mask_sum = mask.byElement.norm(NormType.L1);
            float res_val = 0.0f;

            i = 0;
            foreach (kr; r - ksh .. r + ksh + 1)
            {
                j = 0;
                auto rk = (r - kr) ^^ 2;
                foreach (kc; c - ksh .. c + ksh + 1) 
                {
                    res_val += (mask[i, j] / mask_sum) * bc(slice, kr, kc);
                    ++j;
                }
                ++i;
            }

            prealloc[r, c] = cast(OutputType)res_val;
        }
    }

    return prealloc;
}

/// ditto
Slice!(N, OutputType*) bilateralFilter(alias bc = neumann, InputType, OutputType = InputType, size_t N)(Slice!(N,
        InputType*) slice, float sigma, uint kernelSize, Slice!(N,
        OutputType*) prealloc = emptySlice!(N, OutputType)) if (N == 3)
{
    if (prealloc.empty || prealloc.shape != slice.shape)
    {
        prealloc = uninitializedArray!(OutputType[])(slice.shape.reduce!"a*b").sliced(slice.shape);
    }

    foreach(channel; 0 .. slice.length!2)
    {
        bilateralFilter!(bc, InputType, OutputType)
        (slice[0 .. $, 0 .. $, channel], sigma, kernelSize, prealloc[0 .. $, 0 .. $, channel]);
    }

    return prealloc;
}

/**
Median filtering algorithm.

Params:
    slice = Input image slice.
    kernelSize = Square size of median kernel.
    prealloc = Optional pre-allocated return image buffer.

Returns:
    Returns filtered image of same size as the input. If prealloc parameter is not an empty slice, and is
    of same size as input slice, return value is assigned to prealloc buffer. If not, newly allocated buffer
    is used.
*/
Slice!(N, O*) medianFilter(alias BoundaryConditionTest = neumann, T, O = T, size_t N)(Slice!(N, T*) slice, ulong kernelSize, 
        Slice!(N, O*) prealloc = emptySlice!(N, O))
in
{
    import std.traits : isAssignable;
    static assert(isAssignable!(T, O), "Output slice value type is not assignable to the input value type.");
    static assert(isBoundaryCondition!BoundaryConditionTest, "Given boundary condition test is not DCV "
            "valid boundary condition test function.");

    assert(!slice.empty());
}
body
{
    import std.array : uninitializedArray;
    import std.algorithm.iteration : reduce;

    if (prealloc.shape != slice.shape)
        prealloc = uninitializedArray!(O[])(slice.shape.reduce!"a*b").sliced(slice.shape);

    static if (N == 1)
        medianFilterImpl1!BoundaryConditionTest(slice, prealloc, kernelSize);
    else static if (N == 2)
        medianFilterImpl2!BoundaryConditionTest(slice, prealloc, kernelSize);
    else static if (N == 3)
        medianFilterImpl3!BoundaryConditionTest(slice, prealloc, kernelSize);
    else
        static assert(0, "Invalid slice dimension for median filtering.");

    return prealloc;
}

unittest
{
    import std.algorithm : equal;
    auto imvalues = [1, 20, 3, 54, 5, 643, 7, 80, 9].sliced(9);
    assert(imvalues.medianFilter!neumann(3).equal([1, 3, 20, 5, 54, 7, 80, 9, 9]));
}

unittest
{
    import std.algorithm : equal;
    auto imvalues = [1, 20, 3, 
                     54, 5, 643, 
                     7, 80, 9].sliced(3, 3);
    assert(imvalues.medianFilter!neumann(3).byElement.equal(
                [5, 5, 5, 
                7, 9, 9, 
                7, 9, 9]));
}

unittest
{
    import std.algorithm : equal;
    auto imvalues = [1, 20, 3,  43, 65, 76,  12, 5, 7,
                     54, 5, 643,  12, 54, 76,  15, 68, 9,
                     65, 87, 17,  38, 0, 12,  21, 5, 7].sliced(3, 3, 3);
    assert(imvalues.medianFilter!neumann(3).byElement.equal(
                    [12, 20, 76,  12, 20, 9,  12, 54, 9, 
                    43, 20, 17,  21, 20, 12,  15, 5, 9, 
                    54, 54, 17,  38, 5, 12,  21, 5, 9]));
}

private:

void medianFilterImpl1(alias bc, T, O)(Slice!(1, T*) slice, Slice!(1, O*) filtered, ulong kernelSize)
{
    import std.algorithm.sorting : topN;
    import std.algorithm.comparison : max;
    import std.parallelism;

    int kh = max(1, cast(int)kernelSize / 2);
    int length = cast(int)slice.length!0;

    auto kernelStorage = taskPool.workerLocalStorage(new T[kernelSize]);

    foreach(i; iota(length).parallel)
    {
        auto kernel = kernelStorage.get();
        ulong ki = 0;
        foreach(ii; i - kh .. i + kh + 1)
        {
            kernel[ki++] = bc(slice, ii);
        }
        topN(kernel, kh);
        filtered[i] = kernel[kh];
    }
}

void medianFilterImpl2(alias bc, T, O)(Slice!(2, T*) slice, Slice!(2, O*) filtered, ulong kernelSize)
{
    int kh = max(1, cast(int)kernelSize / 2);
    int n = cast(int)kernelSize^^2;
    int m = n / 2;
    int rows = cast(int)slice.length!0;
    int cols = cast(int)slice.length!1;

    auto kernelStorage = taskPool.workerLocalStorage(new T[kernelSize^^2]);

    foreach(r; iota(rows).parallel)
    {
        foreach(c; 0 .. cols)
        {
            auto kernel = kernelStorage.get();
            ulong i = 0;
            foreach(rr; r - kh .. r + kh + 1)
            {
                foreach(cc; c - kh .. c + kh + 1)
                {
                    kernel[i++] = bc(slice, rr, cc);
                }
            }
            topN(kernel, m);
            filtered[r, c] = kernel[m];
        }
    }
}

void medianFilterImpl3(alias bc, T, O)(Slice!(3, T*) slice, Slice!(3, O*) filtered, ulong kernelSize)
{
    foreach(channel; 0 .. slice.length!2)
    {
        medianFilterImpl2!bc(slice[0 .. $, 0 .. $, channel], filtered[0 .. $, 0 .. $, channel], kernelSize);
    }
}

