/**
Module introduces $(LINK3 https://en.wikipedia.org/wiki/Kernel_(image_processing)#Convolution, image convolution) function.

Following example loads famous image of Lena Söderberg and performs gaussian blurring by convolving the image with gaussian kernel.

----
import dcv.imageio.image : imread, ReadParams;
import dcv.core.image : Image;
import dcv.imgproc.convolution : conv;

Image lenaImage = imread("../data/lena.png", ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8));
auto slice = lenaImage.sliced;
----

... this loads the following image:<br>
$(IMAGE https://github.com/libmir/dcv/blob/master/examples/data/lena.png?raw=true)

----
blurred = slice
             .as!float // convert ubyte data to float.
             .conv(gaussian!float(0.84f, 5, 5)); // convolve image with gaussian kernel

----

... which give the resulting image:<br>
$(IMAGE https://github.com/libmir/dcv/blob/master/examples/filter/result/outblur.png?raw=true)


Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.imgproc.convolution;

import std.traits : isAssignable, ReturnType, Unqual, TemplateOf;
import std.conv : to;
import dplug.core.thread : ThreadPool;
import dplug.core.nogc;


import mir.math.common : fastmath;

import mir.ndslice.slice;
import mir.ndslice.iterator: SliceIterator;
import mir.ndslice.topology;
import mir.algorithm.iteration : reduce;
import mir.rc;
import mir.ndslice.allocation;


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
@nogc nothrow
auto conv(alias bc = neumann, InputTensor, KernelTensor, PreAlloc, MaskTensor)
(
    InputTensor input, 
    KernelTensor kernel,
    PreAlloc prealloc,
    MaskTensor mask
)
in
{
    static assert(isSlice!InputTensor, "Input tensor has to be of type mir.ndslice.slice.Slice");
    static assert(isSlice!KernelTensor, "Kernel tensor has to be of type mir.ndslice.slice.Slice");
    static assert(isSlice!MaskTensor, "Mask tensor has to be of type mir.ndslice.slice.Slice");
    static assert(isBoundaryCondition!bc, "Invalid boundary condition test function.");
    static assert(isAssignable!(DeepElementType!InputTensor, DeepElementType!KernelTensor),
            "Incompatible types for input and kernel");

    immutable N = InputTensor.init.shape.length;
    immutable NK = KernelTensor.init.shape.length;

    static assert(MaskTensor.init.shape.length == NK, "Mask tensor has to be of same dimension as the kernel tensor.");

    immutable invalidKernelMsg = "Invalid kernel dimension";
    static if (N == 1)
        static assert(NK == 1, invalidKernelMsg);
    else static if (N == 2)
        static assert(NK == 2, invalidKernelMsg);
    else static if (N == 3)
        static assert(NK == 2, invalidKernelMsg);
    else
        static assert(0, "Convolution not implemented for given tensor dimension.");

    //assert(input.ptr != prealloc.ptr, "Preallocated and input buffer cannot point to the same memory.");

    if (!mask.empty)
    {
        assert(mask.shape == input.shape, "Invalid mask size. Should be of same size as input tensor.");
        assert(input.strides == mask.strides, "Input input and mask need to have same strides.");
    }

    if (prealloc.empty)
        assert(input._stride!(N-1) == 1, "Input tensor has to be contiguous (i.e. input.stride!(N-1) == 1).");
    else
        assert(input.strides == prealloc.strides,
                "Input input and result(preallocated) buffer need to have same strides.");
}
do
{
    static if (prealloc._strides.length == 0)
        if (prealloc.shape != input.shape)
            prealloc = uninitRCslice!(Unqual!(DeepElementType!InputTensor))(input.shape); // uninitializedSlice!(DeepElementType!InputTensor)(input.shape);

    return convImpl!bc(input, kernel, prealloc, mask);
}

@nogc nothrow
auto conv(alias bc = neumann, InputTensor, KernelTensor)
(
    InputTensor input,
    KernelTensor kernel,
    Slice!(RCI!(Unqual!(DeepElementType!InputTensor)), InputTensor.N) prealloc
)
{
    return conv!bc(input, kernel, prealloc, KernelTensor.init);
}

@nogc nothrow
auto conv(alias bc = neumann, InputTensor, KernelTensor)
(
    InputTensor input,
    KernelTensor kernel
)
{
    return conv!bc(input, kernel, Slice!(RCI!(Unqual!(DeepElementType!InputTensor)), InputTensor.N).init, KernelTensor.init);
}

unittest
{
    import std.math.operations : isClose;
    import std.algorithm.comparison : equal;

    auto r1 = [0., 1., 2., 3., 4., 5.].sliced(6);
    auto k1 = [-1., 0., 1.].sliced(3);
    auto res1 = r1.conv(k1);
    assert(res1.equal!isClose([1., 2., 2., 2., 2., 1.]));
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

nothrow @nogc @fastmath auto kapply(T)(const T r, const T i, const T k)
{
    return r + i * k;
}

private:

auto convImpl
    (alias bc = neumann, InputTensor, KernelTensor, PreTensor, MaskTensor)
    (InputTensor input, KernelTensor kernel, PreTensor prealloc, MaskTensor mask) @nogc nothrow
if (InputTensor.init.shape.length == 1)
{
    alias InputType = Unqual!(DeepElementType!InputTensor);

    auto kl = kernel.length;
    auto kh = kl / 2;

    static if (__traits(isSame, TemplateOf!(IteratorOf!(InputTensor)), RCI)){
        auto input_ls = input.lightScope;
    }else{
        alias input_ls = input;
    }

    static if (__traits(isSame, TemplateOf!(IteratorOf!(KernelTensor)), RCI)){
        auto kernel_ls = kernel.lightScope;
    }else{
        alias kernel_ls = kernel;
    }
    
    static if (__traits(isSame, TemplateOf!(IteratorOf!(PreTensor)), RCI)){
        auto prealloc_ls = prealloc.lightScope;
    }else{
        alias prealloc_ls = prealloc;
    }

    static if (__traits(isSame, TemplateOf!(IteratorOf!(MaskTensor)), RCI)){
        auto mask_ls = mask.lightScope;
    }else{
        alias mask_ls = mask;
    }

    if (mask.empty)
    {
        auto packedWindows = zip!true(prealloc_ls, input_ls).windows(kl);
        
        void worker(int i, int threadIndex) nothrow @nogc {
            auto p = packedWindows[i];
            p[kh].a = reduce!(kapply!InputType)(0.0f, p.unzip!'b', kernel_ls);
        }
        pool.parallelFor(cast(int)packedWindows.length, &worker);
    }
    else
    {
        // TODO: extract masked convolution as separate function?
        auto packedWindows = zip!true(prealloc_ls, input_ls, mask_ls).windows(kl);

        void worker(int i, int threadIndex) nothrow @nogc {
            auto p = packedWindows[i];
            if (p[$ / 2].c)
                p[$ / 2].a = reduce!(kapply!InputType)(0.0f, p.unzip!'b', kernel_ls);
        }
        pool.parallelFor(cast(int)packedWindows.length, &worker);
    }

    handleEdgeConv1d!bc(input_ls, prealloc_ls, kernel_ls, mask_ls, 0, kl);
    handleEdgeConv1d!bc(input_ls, prealloc_ls, kernel_ls, mask_ls, input.length - 1 - kh, input.length);

    return prealloc;
}

auto convImpl
    (alias bc = neumann, InputTensor, KernelTensor, PreAlloc, MaskTensor)
    (InputTensor input, KernelTensor kernel, PreAlloc prealloc, MaskTensor mask) @nogc nothrow
if (InputTensor.init.shape.length == 2)
{
    auto krs = kernel.length!0; // kernel rows
    auto kcs = kernel.length!1; // kernel rows

    auto krh = krs / 2;
    auto kch = kcs / 2;

    static if (__traits(isSame, TemplateOf!(IteratorOf!(InputTensor)), RCI)){
        auto input_ls = input.lightScope;
    }else{
        alias input_ls = input;
    }

    static if (__traits(isSame, TemplateOf!(IteratorOf!(KernelTensor)), RCI)){
        auto kernel_ls = kernel.lightScope;
    }else{
        alias kernel_ls = kernel;
    }
    
    static if (__traits(isSame, TemplateOf!(IteratorOf!(PreAlloc)), RCI)){
        auto prealloc_ls = prealloc.lightScope;
    }else{
        alias prealloc_ls = prealloc;
    }

    static if (__traits(isSame, TemplateOf!(IteratorOf!(MaskTensor)), RCI)){
        auto mask_ls = mask.lightScope;
    }else{
        alias mask_ls = mask;
    }

    if (mask.empty)
    {
        auto packedWindows = zip!true(prealloc_ls, input_ls).windows(krs, kcs);
        void worker(int i, int threadIndex) nothrow @nogc {
            auto prow = packedWindows[i];
            foreach (p; prow)
                p[krh, kch].a = reduce!kapply(0.0f, p.unzip!'b', kernel_ls);
        }
        pool.parallelFor(cast(int)packedWindows.length, &worker);
    }
    else
    {
        auto packedWindows = zip!true(prealloc_ls, input_ls, mask_ls).windows(krs, kcs);
        void worker(int i, int threadIndex) nothrow @nogc {
            auto prow = packedWindows[i];
            foreach (p; prow)
                if (p[krh, kch].c)
                    p[krh, kch].a = reduce!kapply(0.0f, p.unzip!'b', kernel_ls);
        }
        pool.parallelFor(cast(int)packedWindows.length, &worker);
    }

    handleEdgeConv2d!bc(input_ls, prealloc_ls, kernel_ls, mask_ls, [0, input.length!0], [0, kch]); // upper row
    handleEdgeConv2d!bc(input_ls, prealloc_ls, kernel_ls, mask_ls, [0, input.length!0], [input.length!1 - kch, input.length!1]); // lower row
    handleEdgeConv2d!bc(input_ls, prealloc_ls, kernel_ls, mask_ls, [0, krh], [0, input.length!1]); // left column
    handleEdgeConv2d!bc(input_ls, prealloc_ls, kernel_ls, mask_ls, [input.length!0 - krh, input.length!0], [0, input.length!1]); // right column

    return prealloc;
}

auto convImpl
    (alias bc = neumann, InputTensor, KernelTensor, PreAlloc, MaskTensor)
    (InputTensor input, KernelTensor kernel, PreAlloc prealloc, MaskTensor mask) @nogc nothrow
if (InputTensor.init.shape.length == 3)
{
    foreach (i; 0 .. input.length!2)
    {
        auto r_c = input[0 .. $, 0 .. $, i];
        auto p_c = prealloc[0 .. $, 0 .. $, i];
        
        r_c.conv(kernel, p_c, mask);
    }

    return prealloc;
}

@nogc nothrow @fastmath :
void handleEdgeConv1d(alias bc, T, K, M,
    SliceKind kindi,
    SliceKind kindp,
    SliceKind kindk,
    SliceKind kindm,
    )(
    Slice!(T*, 1LU, kindi) input,
    Slice!(T*, 1LU, kindp) prealloc,
    Slice!(K*, 1LU, kindk) kernel,
    Slice!(M*, 1LU, kindm) mask,
    size_t from, size_t to)
in
{
    assert(from < to);
}
do
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

void handleEdgeConv2d(alias bc, SliceKind kind0, SliceKind kind1, SliceKind kind2, SliceKind kind3, T, K, M)(
    Slice!(T*, 2LU, kind0) input,
    Slice!(T*, 2LU, kind1) prealloc,
    Slice!(K*, 2LU, kind2) kernel,
    Slice!(M*, 2LU, kind3) mask, 
    size_t[2] rowRange, size_t[2] colRange)
in
{
    assert(rowRange[0] < rowRange[1]);
    assert(colRange[0] < colRange[1]);
}
do
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