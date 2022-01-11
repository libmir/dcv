/**
Module introduces image filtering functions and utilities.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).

$(DL Module contains:
    $(DD 
            $(BIG Filter kernel generators: )
            $(LINK2 #boxKernel,boxKernel)
            $(LINK2 #radianKernel,radianKernel)
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
            $(LINK2 #calcHistogram,calcHistogram)
            $(LINK2 #histEqualize,histEqualize)
            $(LINK2 #erode,erode)
            $(LINK2 #dilate,dilate)
            $(LINK2 #open,open)
            $(LINK2 #close,close)
    )
)

*/

module dcv.imgproc.filter;

import std.traits;
import std.range.primitives : ElementType, isForwardRange;
import std.exception : enforce;
import std.algorithm.sorting : topN;
import std.array : uninitializedArray;
import std.parallelism : parallel, taskPool, TaskPool;
import std.experimental.allocator.gc_allocator;

import mir.utility : min, max;
import mir.math.common;
import mir.ndslice.allocation;
import mir.math.common : fastmath;

import mir.ndslice.topology;
import mir.ndslice.slice;
import mir.algorithm.iteration : reduce, each;

import dcv.core.algorithm;
import dcv.core.utils;

/**
Box kernel creation.

Creates square kernel of given size, filled with given value.

Params:
    rows = Rows, or height of kernel.
    cols = Columns, or width of kernel.
    value = Value of elements in the kernel.

Returns:
    Kernel of size [rows, cols], filled with given value.
*/
Slice!(T*, 2LU, Contiguous) boxKernel(T)(size_t rows, size_t cols, T value = 1)
in
{
    assert(rows > 1 && cols > 1,
        "Invalid kernel size - rows, and columns have to be larger than 1.");
}
do
{
    return slice!T([rows, cols], value);
}

/// ditto
Slice!(T*, 2LU, Contiguous) boxKernel(T)(size_t size, T value = 1)
in
{
    assert(size > 1, "Invalid kernel size - has to be larger than 1.");
}
do
{
    return boxKernel!T(size, size, value);
}

/**
Radial kernel creation.

Creates square kernel of given radius as edge length, with given values.

Params:
    radius = Radius of kernel. Pixels in kernel with distance to center lesser than
             radius will have value of foreground, other pixels will have value of background.
    foreground = Foreground kernel values, or in the given radius (circle). Default is 1.
    background = Background kernel values, or out of the given radius (circle). Default is 0.

Returns:
    Kernel of size [radius, radius], filled with given values.
*/
Slice!(T*, 2LU, Contiguous) radialKernel(T)(size_t radius, T foreground = 1, T background = 0)
in
{
    assert(radius >= 3, "Radial dilation kernel has to be of larger radius than 3.");
    assert(radius % 2 != 0, "Radial dilation kernel has to be of odd radius.");
}
do
{
    auto kernel = makeUninitSlice!T(GCAllocator.instance, radius, radius); //uninitializedSlice!T(radius, radius);

    auto rf = cast(float)radius;
    auto mid = radius / 2;

    foreach (r; 0 .. radius)
    {
        foreach (c; 0 .. radius)
        {
            auto distanceToCenter = sqrt(cast(float)((mid - r) ^^ 2 + (mid - c) ^^ 2));
            kernel[r, c] = (distanceToCenter > mid) ? background : foreground;
        }
    }

    return kernel;
}

/**
Instantiate 2D gaussian kernel.
*/
Slice!(V*, 2LU, Contiguous) gaussian(V = double)(V sigma, size_t width, size_t height) pure
{

    static assert(isFloatingPoint!V,
        "Gaussian kernel can be constructed only using floating point types.");

    enforce(width > 2 && height > 2 && sigma > 0, "Invalid kernel values");

    auto h = makeUninitSlice!V(GCAllocator.instance, height, width); //uninitializedSlice!V(height, width);

    int arrv_w = -(cast(int)width - 1) / 2;
    int arrv_h = -(cast(int)height - 1) / 2;
    float sgm = 2 * (sigma ^^ 2);

    // build rows
    foreach (r; 0 .. height)
    {
        h[r][] = iota!ptrdiff_t([width], arrv_w).map!"a * a";
    }

    // build columns
    foreach (c; 0 .. width)
    {
        h[0 .. height, c][] += iota([width], -arrv_h + 1).map!"a * a";
        h[0 .. height, c].each!((ref v) => v = exp(-v / sgm));
    }

    // normalize
    import mir.math.sum : sum;

    h[] /= h.flattened.sum;

    return h;
}

unittest
{
    // TODO: design the test

    auto fg = gaussian!float(1.0, 3, 3);
    auto dg = gaussian!double(1.0, 3, 3);
    auto rg = gaussian!real(1.0, 3, 3);

    import std.traits;

    static assert(__traits(compiles, gaussian!int(1, 3, 3)) == false,
        "Integral test failed in gaussian kernel.");
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
Slice!(T*, 2LU, Contiguous) laplacian(T = double)(T a = 0.) pure nothrow if (isNumeric!T)
in
{
    assert(a >= 0 && a <= 1);
}
do
{
    auto k = makeUninitSlice!T(GCAllocator.instance, 3, 3); //uninitializedSlice!T(3, 3);
    auto m = 4 / (a + 1);
    auto e1 = (a / 4) * m;
    auto e2 = ((1 - a) / 4) * m;
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
    assert(laplacian().flattened == [0, 1, 0, 1, -4, 1, 0, 1, 0]);
}

/**
Create laplacian of gaussian $(LINK3 http://homepages.inf.ed.ac.uk/rbf/HIPR2/log.htm, (LoG)) filter kernel.

Params:
    sigma = gaussian sigma variance value
    width = width of the kernel matrix
    height = height of the kernel matrix
*/
Slice!(T*, 2LU, Contiguous) laplacianOfGaussian(T = double)(T sigma,
    size_t width, size_t height)
{
    import std.traits : isFloatingPoint;

    static assert(isFloatingPoint!T);

    import mir.math.sum : sum;
    import mir.math.common : exp;
    import mir.utility : max;
    import std.math : E, PI;

    auto k = slice!T(height, width);

    auto ss = sigma * sigma;
    auto ts = -1 / (cast(T)PI * (ss * ss));
    auto ss2 = 2 * ss;
    auto w_h = cast(T)max(1u, width / 2);
    auto h_h = cast(T)max(1u, height / 2);

    foreach (i; 0 .. height)
        foreach (j; 0 .. width)
        {
            auto xx = (cast(T)j - w_h);
            auto yy = (cast(T)i - h_h);
            xx *= xx;
            yy *= yy;
            auto xy = (xx + yy) / ss2;
            k[i, j] = ts * (1. - xy) * exp(-xy);
        }

    k[] += -cast(T)(cast(float)k.flattened.sum / cast(float)(width * height));
    return k;
}

///
unittest
{
    import std.algorithm.comparison : equal;
    import std.math.operations : isClose;

    auto log = laplacianOfGaussian!float(0.84f, 3, 3);
    auto expected = [0.147722, -0.00865228, 0.147722, -0.00865228,
        -0.556277, -0.00865228, 0.147722, -0.00865228, 0.147722].sliced(3, 3);
    assert(equal!isClose(log.flattened, expected.flattened));
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
Slice!(T*, 2LU, Contiguous) sobel(T = double)(GradientDirection direction) nothrow pure @trusted
{
    return edgeKernelImpl!(T)(direction, cast(T)1, cast(T)2);
}

/// Create a Scharr edge kernel.
Slice!(T*, 2LU, Contiguous) scharr(T = double)(GradientDirection direction) nothrow pure @trusted
{
    return edgeKernelImpl!(T)(direction, cast(T)3, cast(T)10);
}

/// Create a Prewitt edge kernel.
Slice!(T*, 2LU, Contiguous) prewitt(T = double)(GradientDirection direction) nothrow pure @trusted
{
    return edgeKernelImpl!(T)(direction, cast(T)1, cast(T)1);
}

/// Create a kernel of given type.
Slice!(T*, 2LU, Contiguous) edgeKernel(T)(EdgeKernel kernelType,
    GradientDirection direction) nothrow pure @trusted
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

private Slice!(T*, 2LU, Contiguous) edgeKernelImpl(T)(
    GradientDirection direction, T lv, T hv) nothrow pure @trusted
{
    final switch (direction)
    {
    case GradientDirection.DIR_X:
        return [-lv, 0, lv, -hv, 0, hv, -lv, 0, lv].sliced(3, 3).as!T.slice;
    case GradientDirection.DIR_Y:
        return [-lv, -hv, -lv, 0, 0, 0, lv, hv, lv].sliced(3, 3).as!T.slice;
    case GradientDirection.DIAG:
        return [-hv, -lv, 0, -lv, 0, lv, 0, lv, hv].sliced(3, 3).as!T.slice;
    case GradientDirection.DIAG_INV:
        return [0, -lv, -hv, lv, 0, -lv, hv, lv, 0].sliced(3, 3).as!T.slice;
    }
}

// test sobel and scharr
unittest
{
    auto s = edgeKernelImpl!int(GradientDirection.DIR_X, 1, 2);
    auto expected = (cast(int[])[-1, 0, 1, -2, 0, 2, -1, 0, 1]).sliced(3, 3);
    assert(s.flattened == expected.flattened);
}

unittest
{
    auto s = edgeKernelImpl!int(GradientDirection.DIR_Y, 1, 2);
    auto expected = (cast(int[])[-1, -2, -1, 0, 0, 0, 1, 2, 1]).sliced(3, 3);
    assert(s.flattened == expected.flattened);
}

unittest
{
    auto s = edgeKernelImpl!int(GradientDirection.DIAG, 1, 2);
    auto expected = (cast(int[])[-2, -1, 0, -1, 0, 1, 0, 1, 2]).sliced(3, 3);
    assert(s.flattened == expected.flattened);
}

unittest
{
    auto s = edgeKernelImpl!int(GradientDirection.DIAG_INV, 1, 2);
    auto expected = (cast(int[])[0, -1, -2, 1, 0, -1, 2, 1, 0]).sliced(3, 3);
    assert(s.flattened == expected.flattened);
}

/**
Perform non-maxima filtering of the image.

Params:
    input = Input matrix.
    filterSize = Size of filtering kernel (aperture).

Returns:
    Input matrix, after filtering.
*/
auto filterNonMaximum(SliceKind kind, Iterator)(Slice!(Iterator, 2LU, kind) input, size_t filterSize = 10)
in
{
    assert(!input.empty && filterSize);
}
do
{
    import mir.ndslice.topology : universal;
    import mir.ndslice.dynamic : strided;

    immutable fs = filterSize;
    immutable fsh = max(size_t(1), fs / 2);

    input.universal.windows(fs, fs).strided!(0, 1)(fsh, fsh).each!filterNonMaximumImpl;

    return input;
}

/**
Calculate partial derivatives of an slice.

Partial derivatives are calculated by convolving an slice with
[-1, 1] kernel, horizontally and vertically.
*/
void calcPartialDerivatives(InputTensor, V = DeepElementType!InputTensor)(
    InputTensor input, ref Slice!(V*, 2LU, Contiguous) fx,
    ref Slice!(V*, 2LU, Contiguous) fy, TaskPool pool = taskPool) if (isFloatingPoint!V)
in
{
    static assert(isSlice!InputTensor,
        "Invalid input tensor type - has to be of type mir.ndslice.slice.Slice.");
    static assert(InputTensor.init.shape.length == 2,
        "Input tensor has to be 2 dimensional. (matrix)");
}
do
{
    if (input.empty)
        return;

    if (fx.shape != input.shape)
        fx = makeUninitSlice!V(GCAllocator.instance, input.shape);//uninitializedSlice!V(input.shape);
    if (fy.shape != input.shape)
        fy = makeUninitSlice!V(GCAllocator.instance, input.shape);

    if (input.length!0 > 1)
        foreach (r; pool.parallel(iota([input.length!0 - 1], 1)))
        {
            auto x_row = fx[r, 0 .. $];
            auto y_row = fy[r, 0 .. $];
            foreach (c; 1 .. input.length!1)
            {
                auto imrc = input[r, c];
                x_row[c] = cast(V)(-1. * input[r, c - 1] + imrc);
                y_row[c] = cast(V)(-1. * input[r - 1, c] + imrc);
            }
        }

    // calc border edges
    auto x_row = fx[0, 0 .. $];
    auto y_row = fy[0, 0 .. $];

    if (input.length!1 > 1)
        foreach (c; pool.parallel(iota(input.length!1 - 1)))
        {
            auto im_0c = input[0, c];
            x_row[c] = cast(V)(-1. * im_0c + input[0, c + 1]);
            y_row[c] = cast(V)(-1. * im_0c + input[1, c]);
        }

    auto x_col = fx[0 .. $, 0];
    auto y_col = fy[0 .. $, 0];

    if (input.length!0 > 1)
        foreach (r; pool.parallel(iota(input.length!0 - 1)))
        {
            auto im_r_0 = input[r, 0];
            x_col[r] = cast(V)(-1. * im_r_0 + input[r, 1]);
            y_col[r] = cast(V)(-1. * im_r_0 + input[r + 1, 0]);
        }

    // edges corner pixels
    fx[0, input.length!1 - 1] = cast(V)(-1 * input[0,
        input.length!1 - 2] + input[0, input.length!1 - 1]);
    fy[0, input.length!1 - 1] = cast(V)(-1 * input[0,
        input.length!1 - 1] + input[1, input.length!1 - 1]);
    fx[input.length!0 - 1, 0] = cast(V)(-1 * input[input.length!0 - 1,
        0] + input[input.length!0 - 1, 1]);
    fy[input.length!0 - 1, 0] = cast(V)(-1 * input[input.length!0 - 2,
        0] + input[input.length!0 - 1, 0]);
}

/**
Calculate gradient magnitude and orientation of an image slice.

Params:
    input           = Input slice of an image.
    mag             = Output magnitude value of gradients. If shape does not correspond to input, is
                      allocated anew.
    orient          = Orientation value of gradients in radians. If shape does not correspond to
                      input, is allocated anew.
    edgeKernelType  = Optional convolution kernel type to calculate partial derivatives. 
                      Default value is EdgeKernel.SIMPLE, which calls calcPartialDerivatives function
                      to calculate derivatives. Other options will perform convolution with requested
                      kernel type.
    pool            = TaskPool instance used parallelise the algorithm.

Note:
    Input slice's memory has to be contiguous. Magnitude and orientation slices' strides
    have to be the identical.
*/
void calcGradients(InputTensor, V = DeepElementType!InputTensor)
(
    InputTensor input,
    ref Slice!(V*, 2LU, Contiguous) mag,
    ref Slice!(V*, 2LU, Contiguous) orient,
    EdgeKernel edgeKernelType = EdgeKernel.SIMPLE,
    TaskPool pool = taskPool
) if (isFloatingPoint!V)
in
{
    static assert(isSlice!InputTensor, "Input tensor has to be of type mir.ndslice.slice.Slice");
    static assert(InputTensor.init.shape.length == 2,
        "Input tensor has to be 2 dimensional. (matrix)");
    assert(!input.empty);
}
do
{
    if (mag.shape != input.shape)
        mag = makeUninitSlice!V(GCAllocator.instance, input.shape);

    if (orient.shape != input.shape)
        orient = makeUninitSlice!V(GCAllocator.instance, input.shape);

    Slice!(V*, 2LU, Contiguous) fx, fy;
    if (edgeKernelType == EdgeKernel.SIMPLE)
    {
        calcPartialDerivatives(input, fx, fy, pool);
    }
    else
    {
        import dcv.imgproc.convolution;

        Slice!(V*, 2LU, Contiguous) kx, ky;
        kx = edgeKernel!V(edgeKernelType, GradientDirection.DIR_X);
        ky = edgeKernel!V(edgeKernelType, GradientDirection.DIR_Y);
        fx = conv(input, kx, emptySlice!(2, V), emptySlice!(2, V), pool);
        fy = conv(input, ky, emptySlice!(2, V), emptySlice!(2, V), pool);
    }
    
    assert(fx.strides == mag.strides || fx.strides == orient.strides,
        "Magnitude and orientation slices must be contiguous.");

    if (mag.strides == orient.strides && mag.strides == fx.strides)
    {
        auto data = zip!true(fx, fy, mag, orient);
        foreach (row; pool.parallel(data))
        {
            row.each!(p => calcGradientsImpl(p.a, p.b, p.c, p.d));
        }
    }
    else
    {
        foreach (row; /*pool.parallel(*/ndiota(input.shape)/*)*/) // parallel loop causes a linker error
        {
            row.each!(i => calcGradientsImpl(fx[i], fy[i], mag[i], orient[i]));
        }
    }
}

@fastmath void calcGradientsImpl(T)(T fx, T fy, ref T mag, ref T orient)
{
    import mir.math.common : sqrt;
    import std.math : atan2;

    mag = sqrt(fx * fx + fy * fy);
    orient = atan2(fy, fx);
}

/**
Edge detection impulse non-maxima supression.

Filtering used in canny edge detection algorithm - suppresses all 
edge impulses (gradient values along edges normal) except the peek value.

Params:
    mag         = Gradient magnitude.
    orient      = Gradient orientation of the same image source as magnitude.
    prealloc    = Optional pre-allocated buffer for output slice.
    pool        = TaskPool instance used parallelise the algorithm.

Note:
    Orientation and pre-allocated structures must match. If prealloc
    buffer is not given, orient memory has to be contiguous.
See:
    dcv.imgproc.filter.calcGradients, dcv.imgproc.convolution
*/
Slice!(V*, 2LU, Contiguous) nonMaximaSupression(InputTensor, V = DeepElementType!InputTensor)
(
    InputTensor mag,
    InputTensor orient,
    Slice!(V*, 2LU, Contiguous) prealloc = emptySlice!(2, V),
    TaskPool pool = taskPool
)
in
{
    static assert(isSlice!InputTensor, "Input tensor has to be of type mir.ndslice.slice.Slice");
    static assert(InputTensor.init.shape.length == 2,
        "Input tensor has to be 2 dimensional. (matrix)");

    assert(!mag.empty && !orient.empty);
    assert(mag.shape == orient.shape);
    assert(mag.strides == orient.strides,
        "Magnitude and Orientation tensor strides have to be the same.");
}
do
{
    import std.array : uninitializedArray;
    import std.math : PI;

    alias F = DeepElementType!InputTensor;

    if (prealloc.shape != orient.shape || prealloc.strides != mag.strides)
        prealloc = makeUninitSlice!V(GCAllocator.instance, mag.shape); //uninitializedSlice!V(mag.shape);

    assert(prealloc.strides == orient.strides,
        "Orientation and preallocated slice strides do not match.");

    auto magWindows = mag.windows(3, 3);
    auto dPack = zip!true(prealloc[1 .. $ - 1, 1 .. $ - 1], orient[1 .. $ - 1, 1 .. $ - 1]);

    auto innerShape = magWindows.shape;

    foreach (r; pool.parallel(iota(innerShape[0])))
    {
        auto d = dPack[r];
        auto m = magWindows[r];
        foreach (c; 0 .. innerShape[1])
        {
            nonMaximaSupressionImpl(d[c], m[c]);
        }
    }

    return prealloc;
}

/**
Perform canny filtering on an image to expose edges.

Params:
    slice           = Input image slice.
    lowThresh       = lower threshold value after non-maxima suppression.
    upThresh        = upper threshold value after non-maxima suppression.
    edgeKernelType  = Type of edge kernel used to calculate image gradients.
    prealloc        = Optional pre-allocated buffer.
    pool            = TaskPool instance used parallelise the algorithm.
*/
Slice!(V*, 2LU, Contiguous) canny(V, T, SliceKind kind)
(
    Slice!(T*, 2LU, kind) slice,
    T lowThresh,
    T upThresh,
    EdgeKernel edgeKernelType = EdgeKernel.SOBEL,
    Slice!(V*, 2LU, Contiguous) prealloc = emptySlice!(2, V),
    TaskPool pool = taskPool
)
{
    import dcv.imgproc.threshold;
    import dcv.core.algorithm : ranged;

    V upval = isFloatingPoint!V ? 1 : V.max;

    Slice!(float*, 2LU, Contiguous) mag, orient;
    calcGradients(slice, mag, orient, edgeKernelType);

    return nonMaximaSupression(mag, orient, emptySlice!(2, T), pool).ranged(0,
        upval).threshold(lowThresh, upThresh, prealloc);
}

/**
Perform canny filtering on an image to expose edges.

Convenience function to call canny with same lower and upper threshold values,
similar to dcv.imgproc.threshold.threshold.
*/
Slice!(V*, 2LU, Contiguous) canny(V, T, SliceKind kind)
(
    Slice!(T*, 2LU, kind) slice,
    T thresh,
    EdgeKernel edgeKernelType = EdgeKernel.SOBEL,
    Slice!(V*, 2LU, Contiguous) prealloc = emptySlice!(2, V)
)
{
    return canny!(V, T)(slice, thresh, thresh, edgeKernelType, prealloc);
}

/**
$(LINK2 https://en.wikipedia.org/wiki/Bilateral_filter,Bilateral) filtering implementation.

Non-linear, edge-preserving and noise-reducing smoothing filtering algorithm.

Params:
    bc          = Boundary condition test used to index the image slice.
    input       = Slice of the input image.
    sigmaCol    = Color sigma value.
    sigmaSpace  = Spatial sigma value.
    kernelSize  = Size of convolution kernel. Must be odd number.
    prealloc    = Optional pre-allocated result image buffer. If not of same shape as input slice, its allocated anew.
    pool        = Optional TaskPool instance used to parallelize computation.

Returns:
    Slice of filtered image.
*/
Slice!(OutputType*, N, Contiguous) bilateralFilter(OutputType, alias bc = neumann, SliceKind kind, size_t N, Iterator)
(
    Slice!(Iterator, N, kind) input,
    float sigmaCol,
    float sigmaSpace,
    size_t kernelSize,
    Slice!(OutputType*, N, Contiguous) prealloc = emptySlice!(N, OutputType),
    TaskPool pool = taskPool
)
in
{
    static assert(isBoundaryCondition!bc, "Invalid boundary condition test function.");
    assert(!input.empty);
    assert(kernelSize % 2);
}
do
{
    if (prealloc.shape != input.shape)
        prealloc = makeUninitSlice!OutputType(GCAllocator.instance, input.shape); //uninitializedSlice!OutputType(input.shape);

    static if (N == 2LU)
    {
        bilateralFilter2(input, sigmaCol, sigmaSpace, kernelSize, prealloc, pool);
    }
    else static if (N == 3LU)
    {
        foreach (channel; 0 .. input.length!2)
        {
            auto inch = input[0 .. $, 0 .. $, channel];
            auto prech = prealloc[0 .. $, 0 .. $, channel];
            bilateralFilter2(inch, sigmaCol, sigmaSpace, kernelSize, prech, pool);
        }
    }
    else
    {
        static assert(0, "Invalid slice dimensionality - 2 and 3 dimensional slices allowed.");
    }

    return prealloc;
}

private void bilateralFilter2(OutputType, alias bc = neumann,
    SliceKind outputKind, SliceKind kind, V)(Slice!(V*, 2LU, kind) input,
    float sigmaCol, float sigmaSpace, size_t kernelSize,
    Slice!(OutputType*, 2LU, outputKind) prealloc, TaskPool pool = taskPool)
in
{
    assert(prealloc.shape == input.shape);
}
do
{
    auto ks = kernelSize;
    auto kh = max(1u, ks / 2);

    auto inputWindows = input.windows(kernelSize, kernelSize);
    auto innerBody = prealloc[kh .. $ - kh, kh .. $ - kh];
    auto inShape = innerBody.shape;
    auto shape = input.shape;

    auto threadMask = pool.workerLocalStorage(slice!float(ks, ks));

    foreach (r; pool.parallel(iota(inShape[0])))
    {
        auto maskBuf = threadMask.get();
        foreach (c; 0 .. inShape[1])
        {
            innerBody[r, c] = bilateralFilterImpl(inputWindows[r, c], maskBuf, sigmaCol, sigmaSpace);
        }
    }

    foreach (border; pool.parallel(input.shape.borders(ks)[]))
    {
        auto maskBuf = threadMask.get();
        foreach (r; border.rows)
            foreach (c; border.cols)
            {
                import mir.ndslice.field;
                import mir.ndslice.iterator;

                static struct ndIotaWithShiftField
                {
                    ptrdiff_t[2] _shift;
                    ndIotaField!2 _field;
                    Slice!(V*, 2LU, kind) _input;
                    auto opIndex(ptrdiff_t index)
                    {
                        auto ret = _field[index];
                        ptrdiff_t r = _shift[0] - cast(ptrdiff_t)ret[0];
                        ptrdiff_t c = _shift[1] - cast(ptrdiff_t)ret[1];
                        return bc(_input, r, c);
                    }
                }

                auto inputWindow = FieldIterator!ndIotaWithShiftField(0, ndIotaWithShiftField([r + kh, c + kh], ndIotaField!2(ks), input)).sliced(ks, ks);
                prealloc[r, c] = bilateralFilterImpl(inputWindow, maskBuf, sigmaCol, sigmaSpace);
            }
    }
}

/**
Median filtering algorithm.

Params:
    slice       = Input image slice.
    kernelSize  = Square size of median kernel.
    prealloc    = Optional pre-allocated return image buffer.
    pool        = Optional TaskPool instance used to parallelize computation.

Returns:
    Returns filtered image of same size as the input. If prealloc parameter is not an empty slice, and is
    of same size as input slice, return value is assigned to prealloc buffer. If not, newly allocated buffer
    is used.
*/
Slice!(O*, N, Contiguous) medianFilter(alias BoundaryConditionTest = neumann, T, O = T, SliceKind kind, size_t N)
(
    Slice!(T*, N, kind) slice,
    size_t kernelSize,
    Slice!(O*, N, Contiguous) prealloc = emptySlice!(N, O),
    TaskPool pool = taskPool
)
in
{
    import std.traits : isAssignable;

    static assert(isAssignable!(T, O),
        "Output slice value type is not assignable to the input value type.");
    static assert(isBoundaryCondition!BoundaryConditionTest,
        "Given boundary condition test is not DCV valid boundary condition test function.");

    assert(!slice.empty());
}
do
{
    if (prealloc.shape != slice.shape)
        prealloc = makeUninitSlice!O(GCAllocator.instance, slice.shape);// uninitializedSlice!O(slice.shape);

    static if (N == 1LU)
        alias medianFilterImpl = medianFilterImpl1;
    else static if (N == 2LU)
        alias medianFilterImpl = medianFilterImpl2;
    else static if (N == 3LU)
        alias medianFilterImpl = medianFilterImpl3;
    else
        static assert(0, "Invalid slice dimension for median filtering.");

    medianFilterImpl!BoundaryConditionTest(slice, prealloc, kernelSize, pool);

    return prealloc;
}

unittest
{
    auto imvalues = [1, 20, 3, 54, 5, 643, 7, 80, 9].sliced(9);
    assert(imvalues.medianFilter!neumann(3) == [1, 3, 20, 5, 54, 7, 80, 9, 9]);
}

unittest
{
    auto imvalues = [1, 20, 3, 54, 5, 643, 7, 80, 9].sliced(3, 3);
    assert(imvalues.medianFilter!neumann(3).flattened == [5, 5, 5, 7, 9, 9, 7, 9, 9]);
}

unittest
{
    auto imvalues = [1, 20, 3, 43, 65, 76, 12, 5, 7, 54, 5, 643, 12, 54, 76,
        15, 68, 9, 65, 87, 17, 38, 0, 12, 21, 5, 7].sliced(3, 3, 3);
    assert(imvalues.medianFilter!neumann(3).flattened == [12, 20, 76, 12, 20, 9,
        12, 54, 9, 43, 20, 17, 21, 20, 12, 15, 5, 9, 54, 54, 17, 38, 5, 12, 21, 5,
        9]);
}

/**
Calculate range value histogram.

Params:
    HistogramType   = (template parameter) Histogram type. Can be static or dynamic array, most commonly
                      of 32 bit integer, of size T.max + 1, where T is element type of input range.
    range           = Input forward range, for which histogram is calculated.

Returns:
    Histogram for given forward range.
*/
HistogramType calcHistogram(Range, HistogramType = int[(ElementType!Range).max + 1])
(
    Range range
) if (isForwardRange!Range && (isDynamicArray!HistogramType || isStaticArray!HistogramType))
in
{
    static if (isStaticArray!HistogramType)
    {
        static assert(
            HistogramType.init.length == (
            ElementType!Range.max + 1),
            "Invalid histogram size - if given histogram type is static array, it has to be of lenght T.max + 1");
    }
}
do
{
    alias ValueType = ElementType!Range;

    HistogramType histogram;
    static if (isDynamicArray!HistogramType)
    {
        histogram.lenght = ValueType.max + 1;
    }
    histogram[] = cast(ElementType!HistogramType)0;

    foreach (v; range)
    {
        histogram[cast(size_t)v]++;
    }

    return histogram;
}

/**
Histogram Equalization.

Equalize histogram of given image slice. Slice can be 2D for grayscale, and 3D for color images.
If 3D slice is given, histogram is applied separatelly for each channel.

Example:
----
import dcv.core, dcv.io, dcv.imgproc, dcv.plot;

void main()
{
    Image image = imread("dcv/examples/data/lena.png");

    auto slice = image.sliced.rgb2gray;
    auto equalized = slice.histEqualize(slice.flattened.calcHistogram);

    slice.imshow("Original");
    equalized.imshow("Equalized");

    waitKey();
}
----
Example code will equalize grayscale Lena image, from this:

$(IMAGE https://github.com/libmir/dcv/blob/master/examples/data/lena_gray.png?raw=true)

... to this:

$(IMAGE https://github.com/libmir/dcv/blob/master/examples/data/histEqualExample.png?raw=true)

Note:
    For more valid color histogram equalization results, try converting image to HSV color model
    to perform equalization for V channel, $(LINK2 https://en.wikipedia.org/wiki/Histogram_equalization#Histogram_equalization_of_color_images,to alter the color as less as possible).

Params:
    HistogramType   = (template parameter) Histogram type, see $(LINK2 #calcHistogram,calcHistogram) function for details.
    slice           = Input image slice.
    histogram       = Histogram values for input image slice.
    prealloc        = Optional pre-allocated buffer where equalized image is saved.

Returns:
    Copy of input image slice with its histogram values equalized.
*/
auto histEqualize(T, HistogramType, SliceKind kind, size_t N)
(
    Slice!(T*, N, kind) slice,
    HistogramType histogram,
    Slice!(T*, N, Contiguous) prealloc = emptySlice!(N, T)
)
in
{
    //static assert(packs.length == 1, "Packed slices are not allowed.");
    assert(!slice.empty());
    static if (isDynamicArray!HistogramType)
    {
        assert(histogram.length == T.max + 1, "Invalid histogram length.");
    }
}
do
{
    //immutable N = packs[0];

    int n = cast(int)slice.elementCount; // number of pixels in image.
    immutable tmax = cast(int)T.max; // maximal possible value for pixel value type.

    // The probability of an occurrence of a pixel of level i in the image
    float[tmax + 1] cdf;

    cdf[0] = cast(float)histogram[0] / cast(float)n;
    foreach (i; 1 .. tmax + 1)
    {
        cdf[i] = cdf[i - 1] + cast(float)histogram[i] / cast(float)n;
    }

    if (prealloc.shape != slice.shape)
        prealloc = makeUninitSlice!T(GCAllocator.instance, slice.shape);//uninitializedSlice!T(slice.shape);

    static if (N == 2LU)
    {
        histEqualImpl(slice, cdf, prealloc);
    }
    else static if (N == 3LU)
    {
        foreach (c; 0 .. slice.length!2)
        {
            histEqualImpl(slice[0 .. $, 0 .. $, c], cdf, prealloc[0 .. $, 0 .. $, c]);
        }
    }
    else
    {
        static assert(0,
            "Invalid dimension for histogram equalization. Only 2D and 3D slices supported.");
    }

    return prealloc;
}

/**
Perform morphological $(LINK3 https://en.wikipedia.org/wiki/Erosion_(morphology),erosion).

Use given kernel matrix to estimate image erosion for given image slice. Given slice is
considered to be binarized with $(LINK2 #threshold, threshold) method.

For given input slice:
----
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 0 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1
----
... And erosion kernel of:
----
1 1 1
1 1 1
1 1 1
----
... Resulting slice is:
----
0 0 0 0 0 0 0 0 0 0 0 0 0
0 1 1 1 1 0 0 0 1 1 1 1 0
0 1 1 1 1 0 0 0 1 1 1 1 0
0 1 1 1 1 1 1 1 1 1 1 1 0
0 1 1 1 1 1 1 1 1 1 1 1 0
0 1 1 1 1 1 1 1 1 1 1 1 0
0 1 1 1 1 1 1 1 1 1 1 1 0
0 1 1 1 1 1 1 1 1 1 1 1 0
0 1 1 1 1 1 1 1 1 1 1 1 0
0 1 1 1 1 1 1 1 1 1 1 1 0
0 1 1 1 1 1 1 1 1 1 1 1 0
0 1 1 1 1 1 1 1 1 1 1 1 0
0 0 0 0 0 0 0 0 0 0 0 0 0
----

Note:
    Erosion works only for 2D binary images.

Params:
    slice       = Input image slice, to be eroded.
    kernel      = Erosion kernel. Default value is radialKernel!T(3).
    prealloc    = Optional pre-allocated buffer to hold result.
    pool        = Optional TaskPool instance used to parallelize computation.

Returns:
    Eroded image slice, of same type as input image.
*/
Slice!(T*, 2LU, kind) erode(alias BoundaryConditionTest = neumann, T, SliceKind kind)
(
    Slice!(T*, 2LU, kind) slice,
    Slice!(T*, 2LU, kind) kernel = radialKernel!T(3),
    Slice!(T*, 2LU, kind) prealloc = emptySlice!(2, T),
    TaskPool pool = taskPool
) if (isBoundaryCondition!BoundaryConditionTest)
{
    return morphOp!(MorphologicOperation.ERODE, BoundaryConditionTest)(slice,
        kernel, prealloc, pool);
}

/**
Perform morphological $(LINK3 https://en.wikipedia.org/wiki/Dilation_(morphology),dilation).

Use given kernel matrix to estimate image dilation for given image slice. Given slice is
considered to be binarized with $(LINK2 #threshold, threshold) method.

For given input slice:
----
0 0 0 0 0 0 0 0 0 0 0
0 1 1 1 1 0 0 1 1 1 0
0 1 1 1 1 0 0 1 1 1 0
0 1 1 1 1 1 1 1 1 1 0
0 1 1 1 1 1 1 1 1 1 0
0 1 1 0 0 0 1 1 1 1 0
0 1 1 0 0 0 1 1 1 1 0
0 1 1 0 0 0 1 1 1 1 0
0 1 1 1 1 1 1 1 0 0 0
0 1 1 1 1 1 1 1 0 0 0
0 0 0 0 0 0 0 0 0 0 0
----
... And dilation kernel of:
----
1 1 1
1 1 1
1 1 1
----
... Resulting slice is:
----
1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 0 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 0 0
1 1 1 1 1 1 1 1 1 0 0
----

Note:
    Dilation works only for 2D binary images.

Params:
    slice       = Input image slice, to be eroded.
    kernel      = Dilation kernel. Default value is radialKernel!T(3).
    prealloc    = Optional pre-allocated buffer to hold result.
    pool        = Optional TaskPool instance used to parallelize computation.
    
Returns:
    Dilated image slice, of same type as input image.
*/
Slice!(T*, 2LU, kind) dilate(alias BoundaryConditionTest = neumann, T, SliceKind kind)
(
    Slice!(T*, 2LU, kind) slice,
    Slice!(T*, 2LU, kind) kernel = radialKernel!T(3),
    Slice!(T*, 2LU, kind) prealloc = emptySlice!(2, T),
    TaskPool pool = taskPool
) if (isBoundaryCondition!BoundaryConditionTest)
{
    return morphOp!(MorphologicOperation.DILATE, BoundaryConditionTest)(slice,
        kernel, prealloc, pool);
}

/**
Perform morphological $(LINK3 https://en.wikipedia.org/wiki/Opening_(morphology),opening).

Performs erosion, than on the resulting eroded image performs dilation.

Note:
    Opening works only for 2D binary images.

Params:
    slice       = Input image slice, to be eroded.
    kernel      = Erosion/Dilation kernel. Default value is radialKernel!T(3).
    prealloc    = Optional pre-allocated buffer to hold result.
    pool        = Optional TaskPool instance used to parallelize computation.
    
Returns:
    Opened image slice, of same type as input image.
*/
Slice!(T*, 2LU, kind) open(alias BoundaryConditionTest = neumann, T, SliceKind kind)
(
    Slice!(T*, 2LU, kind) slice,
    Slice!(T*, 2LU, kind) kernel = radialKernel!T(3),
    Slice!(T*, 2LU, kind) prealloc = emptySlice!(2, T),
    TaskPool pool = taskPool
) if (isBoundaryCondition!BoundaryConditionTest)
{
    return morphOp!(MorphologicOperation.DILATE, BoundaryConditionTest)(
        morphOp!(MorphologicOperation.ERODE, BoundaryConditionTest)(slice,
        kernel, emptySlice!(2, T), pool), kernel, prealloc, pool);
}

/**
Perform morphological $(LINK3 https://en.wikipedia.org/wiki/Closing_(morphology),closing).

Performs dilation, than on the resulting dilated image performs erosion.

Note:
    Closing works only for 2D binary images.

Params:
    slice = Input image slice, to be eroded.
    kernel = Erosion/Dilation kernel. Default value is radialKernel!T(3).
    prealloc = Optional pre-allocated buffer to hold result.
    pool = Optional TaskPool instance used to parallelize computation.
    
Returns:
    Closed image slice, of same type as input image.
*/
Slice!(T*, 2LU, kind) close(alias BoundaryConditionTest = neumann, T, SliceKind kind)(
    Slice!(T*, 2LU, kind) slice,
    Slice!(T*, 2LU, kind) kernel = radialKernel!T(3),
    Slice!(T*, 2LU, kind) prealloc = emptySlice!(2, T), TaskPool pool = taskPool) if (
        isBoundaryCondition!BoundaryConditionTest)
{
    return morphOp!(MorphologicOperation.ERODE, BoundaryConditionTest)(
        morphOp!(MorphologicOperation.DILATE, BoundaryConditionTest)(slice,
        kernel, emptySlice!(2, T), pool), kernel, prealloc, pool);
}

@fastmath void calcBilateralMask(Window, Mask)(Window window, Mask mask,
    float sigmaCol, float sigmaSpace)
{
    import mir.math.common : exp, sqrt;

    auto in_val = window[$ / 2, $ / 2];
    float rd, cd, c_val, s_val;
    float i, j, wl2;
    wl2 = -(cast(float)window.length!0 / 2.0f);
    i = wl2;
    foreach (r; 0 .. window.length!0)
    {
        rd = i * i;
        j = wl2;
        foreach (c; 0 .. window.length!1)
        {
            cd = j * j;
            auto cdiff = cast(float)(window[r, c] - in_val);
            c_val = exp((cd + rd) / (-2.0f * sigmaCol * sigmaCol));
            s_val = exp((cdiff * cdiff) / (-2.0f * sigmaSpace * sigmaSpace));
            mask[r, c] = c_val * s_val;
            j++;
        }
        i++;
    }
}

@fastmath T calcBilateralValue(T, M)(T r, T i, M m)
{
    return cast(T)(r + i * m);
}

void filterNonMaximumImpl(Window)(Window window)
{
    alias T = DeepElementType!Window;

    static if (isFloatingPoint!T)
        auto lmsVal = -T.max;
    else
        auto lmsVal = T.min;

    T* locPtr = null;

    foreach (row; window)
        foreach (ref e; row)
        {
            if (e > lmsVal)
            {
                locPtr = &e;
                lmsVal = e;
            }
            e = T(0);
        }

    if (locPtr !is null)
    {
        *locPtr = lmsVal;
    }
}

private:

void nonMaximaSupressionImpl(DataPack, MagWindow)(DataPack p, MagWindow magWin)
{
    import mir.math.common;

    alias F = typeof(p.a);

    auto ang = p.b;
    auto aang = fabs(ang);

    auto mag = magWin[1, 1];
    typeof(mag) mb, ma; // magnitude before and after cursor

    immutable pi = 3.15f;
    immutable pi8 = pi / 8.0f;

    if (aang <= pi && aang > 7.0f * pi8)
    {
        mb = magWin[1, 0];
        ma = magWin[1, 2];
    }
    else if (ang >= -7.0f * pi8 && ang < -5.0f * pi8)
    {
        mb = magWin[0, 0];
        ma = magWin[2, 2];
    }
    else if (ang <= 7.0f * pi8 && ang > 5.0f * pi8)
    {
        mb = magWin[0, 2];
        ma = magWin[2, 0];
    }
    else if (ang >= pi8 && ang < 3.0f * pi8)
    {
        mb = magWin[2, 0];
        ma = magWin[0, 2];
    }
    else if (ang <= -pi8 && ang > -3.0f * pi8)
    {
        mb = magWin[2, 2];
        ma = magWin[0, 0];
    }
    else if (ang >= -5.0f * pi8 && ang < -3.0f * pi8)
    {
        mb = magWin[0, 1];
        ma = magWin[2, 1];
    }
    else if (ang <= 5.0f * pi8 && ang > 3.0f * pi8)
    {
        mb = magWin[2, 1];
        ma = magWin[0, 1];
    }
    else if (aang >= 0.0f && aang < pi8)
    {
        mb = magWin[1, 2];
        ma = magWin[1, 0];
    }

    p.a = cast(F)((ma > mb) ? 0 : mag);
}

auto bilateralFilterImpl(Window, Mask)(Window window, Mask mask, float sigmaCol, float sigmaSpace)
{
    import mir.math.common;

    calcBilateralMask(window, mask, sigmaCol, sigmaSpace);
    mask[] *= 1f / reduce!"a + b"(0f, mask.as!float.map!fabs);

    alias T = DeepElementType!Window;
    alias M = DeepElementType!Mask;

    return reduce!(calcBilateralValue!(T, M))(T(0), window, mask);
}

void medianFilterImpl1(alias bc, T, O, SliceKind kind0, SliceKind kind1)(
    Slice!(T*, 1LU, kind0) slice, Slice!(O*, 1LU, kind1) filtered,
    size_t kernelSize, TaskPool pool)
{
    import std.parallelism;

    import mir.utility : max;

    int kh = max(1, cast(int)kernelSize / 2);

    auto kernelStorage = pool.workerLocalStorage(new T[kernelSize]);

    foreach (i; pool.parallel(slice.length!0.iota!ptrdiff_t))
    {
        auto kernel = kernelStorage.get();
        size_t ki = 0;
        foreach (ii; i - kh .. i + kh + 1)
        {
            kernel[ki++] = bc(slice, ii);
        }
        topN(kernel, kh);
        filtered[i] = kernel[kh];
    }
}

void medianFilterImpl2(alias bc, T, O, SliceKind kind0, SliceKind kind1)(
    Slice!(T*, 2LU, kind0) slice, Slice!(O*, 2LU, kind1) filtered,
    size_t kernelSize, TaskPool pool)
{
    int kh = max(1, cast(int)kernelSize / 2);
    int n = cast(int)(kernelSize * kernelSize);
    int m = n / 2;

    auto kernelStorage = pool.workerLocalStorage(new T[kernelSize * kernelSize]);

    foreach (r; pool.parallel(slice.length!0.iota!ptrdiff_t))
    {
        auto kernel = kernelStorage.get();
        foreach (ptrdiff_t c; 0 .. slice.length!1)
        {
            size_t i = 0;
            foreach (rr; r - kh .. r + kh + 1)
            {
                foreach (cc; c - kh .. c + kh + 1)
                {
                    kernel[i++] = bc(slice, rr, cc);
                }
            }
            topN(kernel, m);
            filtered[r, c] = kernel[m];
        }
    }
}

void medianFilterImpl3(alias bc, T, O, SliceKind kind)
    (Slice!(T*, 3LU, kind) slice, Slice!(O*, 3LU, Contiguous) filtered, size_t kernelSize, TaskPool pool)
{
    foreach (channel; 0 .. slice.length!2)
    {
        medianFilterImpl2!bc(slice[0 .. $, 0 .. $, channel], filtered[0 .. $,
            0 .. $, channel], kernelSize, pool);
    }
}

void histEqualImpl(T, Cdf, SliceKind kind0, SliceKind kind1)
    (Slice!(T*, 2LU, kind0) slice, Cdf cdf, Slice!(T*, 2LU, kind1) prealloc = emptySlice!(2, T))
{
    foreach (e; zip(prealloc.flattened, slice.flattened))
        e.a = cast(T)(e.b * cdf[e.b]);
}

enum MorphologicOperation
{
    ERODE,
    DILATE
}

Slice!(T*, 2LU, kind) morphOp(MorphologicOperation op, alias BoundaryConditionTest = neumann, T, SliceKind kind)
    (Slice!(T*, 2LU, kind) slice, Slice!(T*, 2LU, kind) kernel, Slice!(T*, 2LU, kind) prealloc, TaskPool pool)
if (isBoundaryCondition!BoundaryConditionTest)
in
{
    assert(!slice.empty);
}
do
{
    if (prealloc.shape != slice.shape)
        prealloc = makeUninitSlice!T(GCAllocator.instance, slice.shape);//uninitializedSlice!T(slice.shape);

    ptrdiff_t khr = max(size_t(1), kernel.length!0 / 2);
    ptrdiff_t khc = max(size_t(1), kernel.length!1 / 2);

    static if (op == MorphologicOperation.ERODE)
    {
        immutable checkSlice = "!slice[r, c]";
        immutable checkMorphResult = "!v";
        T value = cast(T)0;
    }
    else
    {
        immutable checkSlice = "slice[r, c]";
        immutable checkMorphResult = "v";

        static if (isIntegral!T)
            T value = T.max;
        else
            T value = cast(T)1.0;
    }

    foreach (r; pool.parallel(slice.length!0.iota!ptrdiff_t))
    {
        foreach (ptrdiff_t c; 0 .. slice.length!1)
        {

            if (mixin(checkSlice))
            {
                prealloc[r, c] = value;
                continue;
            }

            size_t rk = 0;
            foreach (rr; r - khr .. r + khr + 1)
            {
                size_t ck = 0;
                foreach (cc; c - khc .. c + khc + 1)
                {
                    auto kv = kernel[rk, ck];
                    if (kv)
                    {
                        auto v = BoundaryConditionTest(slice, rr, cc) * kv;
                        if (mixin(checkMorphResult))
                        {
                            prealloc[r, c] = value;
                            goto skip_dil;
                        }
                    }
                    ++ck;
                }
                ++rk;
            }
            prealloc[r, c] = slice[r, c];
        skip_dil:
        }
    }

    return prealloc;
}