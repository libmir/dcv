/**
Module introduces $(LINK3 https://en.wikipedia.org/wiki/Kernel_(image_processing)#Convolution, image convolution) function.

Following example loads famous image of Lena Söderberg and performs gaussian blurring by convolving the image with gaussian kernel.

----
import dcv.io.image : imread, ReadParams;
import dcv.core.image : Image, asType;
import dcv.imgproc.convolution : conv;

Image lenaImage = imread("../data/lena.png", ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8));
auto slice = lenaImage.sliced!ubyte;
----

... this loads the following image:<br>
$(IMAGE https://github.com/ljubobratovicrelja/dcv/blob/master/examples/data/lena.png?raw=true)

----
blurred = slice
             .asType!float // convert ubyte data to float.
             .conv(gaussian!float(0.84f, 5, 5)); // convolve image with gaussian kernel

----

... which give the resulting image:<br>
$(IMAGE https://github.com/ljubobratovicrelja/dcv/blob/master/examples/filter/result/outblur.png?raw=true)


Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.imgproc.convolution;

import std.traits : isAssignable, ReturnType;
import std.conv : to;
import std.algorithm.comparison : equal;
import std.parallelism : parallel, taskPool, TaskPool;

import ldc.attributes : fastmath;

import mir.ndslice;
import mir.ndslice.algorithm : ndReduce, Yes;

import dcv.core.memory;
import dcv.core.utils;

/**
Perform convolution to given tensor, using given kernel.
Convolution is supported for 1, 2, and 3 dimensional tensors.

Params:
    bc = (Template parameter) Boundary Condition function used while indexing the image matrix.
    input = Input tensor.
    kernel = Convolution kernel tensor. For 1D input, 1D kernel is expected.
    For 2D input, 2D kernel is expected. For 3D input, 2D or 3D kernel is expected -
    if 2D kernel is given, each item in kernel matrix is applied to each value in
    corresponding 2D coordinate in the input.
    prealloc = Pre-allocated buffer where convolution result can be stored. Default
    value is emptySlice, where resulting array will be newly allocated. Also if
    prealloc is not of same shape as input input, resulting array will be newly allocated.
    mask = Masking input. Convolution will skip each element where mask is 0. Default value
    is empty slice, which tells that convolution will be performed on the whole input.
    pool = Optional TaskPool instance used to parallelize computation.

Returns:
    Resulting image after convolution, of same type as input tensor.

Note:
    Input, mask and pre-allocated slices' strides must be the same.
*/
InputTensor conv
    (alias bc = neumann, InputTensor, KernelTensor, MaskTensor = KernelTensor)
    (InputTensor input, KernelTensor kernel, InputTensor prealloc = InputTensor.init,
     MaskTensor mask = MaskTensor.init, TaskPool pool = taskPool)
in
{
    static assert(isSlice!InputTensor, "Input tensor has to be of type mir.ndslice.slice.Slice");
    static assert(isSlice!KernelTensor, "Kernel tensor has to be of type mir.ndslice.slice.Slice");
    static assert(isSlice!MaskTensor, "Mask tensor has to be of type mir.ndslice.slice.Slice");
    static assert(isBoundaryCondition!bc, "Invalid boundary condition test function.");
    static assert(isAssignable!(DeepElementType!InputTensor, DeepElementType!KernelTensor),
            "Incompatible types for input and kernel");

    immutable N = ReturnType!(InputTensor.shape).length;
    immutable NK = ReturnType!(KernelTensor.shape).length;

    static assert(ReturnType!(MaskTensor.shape).length == NK, "Mask tensor has to be of same dimension as the kernel tensor.");

    immutable invalidKernelMsg = "Invalid kernel dimension";
    static if (N == 1)
        static assert(NK == 1, invalidKernelMsg);
    else static if (N == 2)
        static assert(NK == 2, invalidKernelMsg);
    else static if (N == 3)
        static assert(NK == 2, invalidKernelMsg);
    else
        static assert(0, "Convolution not implemented for given tensor dimension.");

    assert(input.ptr != prealloc.ptr, "Preallocated and input buffer cannot point to the same memory.");

    if (!mask.empty)
    {
        assert(mask.shape == input.shape, "Invalid mask size. Should be of same size as input tensor.");
        assert(input.structure.strides == mask.structure.strides, "Input input and mask need to have same strides.");
    }

    if (prealloc.empty)
        assert(input.stride!(N-1) == 1, "Input tensor has to be contiguous (i.e. input.stride!(N-1) == 1).");
    else
        assert(input.structure.strides == prealloc.structure.strides,
                "Input input and result(preallocated) buffer need to have same strides.");
}
body
{
    if (prealloc.shape != input.shape)
        prealloc = uninitializedSlice!(DeepElementType!InputTensor)(input.shape);

    return convImpl!bc(input, kernel, prealloc, mask, pool);
}

unittest
{
    import std.math : approxEqual;

    auto r1 = [0., 1., 2., 3., 4., 5.].sliced(6);
    auto k1 = [-1., 0., 1.].sliced(3);
    auto res1 = r1.conv(k1);
    assert(res1.equal!approxEqual([1., 2., 2., 2., 2., 1.]));
}

unittest
{
    auto image = slice!float(15, 15);
    auto kernel = slice!float(3, 3);
    auto convres = conv(image, kernel);
    assert(convres.shape == image.shape);
}

unittest
{
    auto image = slice!float(15, 15, 3);
    auto kernel = slice!float(3, 3);
    auto convres = conv(image, kernel);
    assert(convres.shape == image.shape);
}

nothrow @nogc @fastmath auto kapply(T)(T r, T i, T k)
{
    return r + i * k;
}

private:

auto convImpl
    (alias bc = neumann, InputTensor, KernelTensor, MaskTensor)
    (InputTensor input, KernelTensor kernel, InputTensor prealloc, MaskTensor mask, TaskPool pool) 
if (ReturnType!(InputTensor.shape).length == 1)
{
    alias InputType = DeepElementType!InputTensor;

    auto kl = kernel.length;
    auto kh = kl / 2;

    if (mask.empty)
    {
        auto packedWindows = assumeSameStructure!("result", "input")(prealloc, input).windows(kl);
        foreach (p; pool.parallel(packedWindows))
        {
            p[kh].result = ndReduce!(kapply!InputType, Yes.vectorized, Yes.fastmath)
                                    (0.0f, p.ndMap!(p => p.input), kernel);
        }
    }
    else
    {
        // TODO: extract masked convolution as separate function?
        auto packedWindows = assumeSameStructure!("result", "input", "mask")(prealloc, input, mask).windows(kl);
        foreach (p; pool.parallel(packedWindows))
        {
            if (p[$ / 2].mask)
                p[$ / 2].result = ndReduce!(kapply!InputType)
                                           (0.0f, p.ndMap!(p => p.input), kernel);
        }
    }

    handleEdgeConv1d!bc(input, prealloc, kernel, mask, 0, kl);
    handleEdgeConv1d!bc(input, prealloc, kernel, mask, input.length - 1 - kh, input.length);

    return prealloc;
}

auto convImpl
    (alias bc = neumann, InputTensor, KernelTensor, MaskTensor)
    (InputTensor input, KernelTensor kernel, InputTensor prealloc, MaskTensor mask, TaskPool pool) 
if (ReturnType!(InputTensor.shape).length == 2)
{
    auto krs = kernel.length!0; // kernel rows
    auto kcs = kernel.length!1; // kernel rows

    auto krh = krs / 2;
    auto kch = kcs / 2;

    auto useMask = !mask.empty;

    if (mask.empty)
    {
        auto packedWindows = assumeSameStructure!("result", "input")(prealloc, input).windows(krs, kcs);
        foreach (prow; pool.parallel(packedWindows))
            foreach (p; prow)
            {
                p[krh, kch].result = ndReduce!(kapply, Yes.vectorized, Yes.fastmath)
                                              (0.0f, p.ndMap!(v => v.input), kernel);
            }
    }
    else
    {
        auto packedWindows = assumeSameStructure!("result", "input", "mask")(prealloc, input, mask).windows(krs, kcs);
        foreach (prow; pool.parallel(packedWindows))
            foreach (p; prow)
            {
                if (p[krh, kch].mask)
                {
                    p[krh, kch].result = ndReduce!(kapply, Yes.vectorized, Yes.fastmath)
                                                  (0.0f, p.ndMap!(v => v.input), kernel);
                }
            }
    }

    handleEdgeConv2d!bc(input, prealloc, kernel, mask, [0, input.length!0], [0, kch]); // upper row
    handleEdgeConv2d!bc(input, prealloc, kernel, mask, [0, input.length!0], [input.length!1 - kch, input.length!1]); // lower row
    handleEdgeConv2d!bc(input, prealloc, kernel, mask, [0, krh], [0, input.length!1]); // left column
    handleEdgeConv2d!bc(input, prealloc, kernel, mask, [input.length!0 - krh, input.length!0], [0, input.length!1]); // right column

    return prealloc;
}

auto convImpl
    (alias bc = neumann, InputTensor, KernelTensor, MaskTensor)
    (InputTensor input, KernelTensor kernel, InputTensor prealloc, MaskTensor mask, TaskPool pool) 
if (ReturnType!(InputTensor.shape).length == 3)
{
    foreach (i; 0 .. input.length!2)
    {
        auto r_c = input[0 .. $, 0 .. $, i];
        auto p_c = prealloc[0 .. $, 0 .. $, i];
        r_c.conv(kernel, p_c, mask, pool);
    }

    return prealloc;
}

void handleEdgeConv1d(alias bc, T, K, M)(Slice!(1, T*) input, Slice!(1, T*) prealloc, Slice!(1,
        K*) kernel, Slice!(1, M*) mask, size_t from, size_t to)
in
{
    assert(from < to);
}
body
{
    int kl = cast(int)kernel.length;
    int kh = kl / 2, i = cast(int)from, j;

    bool useMask = !mask.empty;

    T t;
    foreach (ref p; prealloc[from .. to])
    {
        if (useMask && mask[i] <= 0)
            goto loop_end;
        t = 0;
        j = -kh;
        foreach (k; kernel)
        {
            t += bc(input, i + j) * k;
            ++j;
        }
        p = t;
    loop_end:
        ++i;
    }
}

void handleEdgeConv2d(alias bc, T, K, M)(Slice!(2, T*) input, Slice!(2, T*) prealloc, Slice!(2,
        K*) kernel, Slice!(2, M*) mask, size_t[2] rowRange, size_t[2] colRange)
in
{
    assert(rowRange[0] < rowRange[1]);
    assert(colRange[0] < colRange[1]);
}
body
{
    int krl = cast(int)kernel.length!0;
    int kcl = cast(int)kernel.length!1;
    int krh = krl / 2, kch = kcl / 2;
    int r = cast(int)rowRange[0], c, i, j;

    bool useMask = !mask.empty;

    auto roi = prealloc[rowRange[0] .. rowRange[1], colRange[0] .. colRange[1]];

    T t;
    foreach (prow; roi)
    {
        c = cast(int)colRange[0];
        foreach (ref p; prow)
        {
            if (useMask && mask[r, c] <= 0)
                goto loop_end;
            t = 0;
            i = -krh;
            foreach (krow; kernel)
            {
                j = -kch;
                foreach (k; krow)
                {
                    t += bc(input, r + i, c + j) * k;
                    ++j;
                }
                ++i;
            }
            p = t;
        loop_end:
            ++c;
        }
        ++r;
    }
}
