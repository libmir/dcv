/**
Image manipulation module.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).

$(DL Module contains:
    $(DD 
            $(LINK2 #resize, resize)
            $(LINK2 #scale, scale)
            $(LINK2 #transformAffine,transformAffine)
            $(LINK2 #transformPerspective,transformPerspective)
            $(LINK2 #warp,warp)
            $(LINK2 #remap,remap)
    )
)
*/
module dcv.imgproc.imgmanip;

import mir.exception;

import std.range.primitives : ElementType;
import std.traits;
import mir.rc;

import dcv.core.utils;
public import dcv.imgproc.interpolate;

import mir.ndslice;
import mir.ndslice.topology;
import mir.ndslice.allocation;
import std.experimental.allocator.gc_allocator;

import dplug.core;

@nogc nothrow:

/**
Resize array using custom interpolation function.

Primarilly implemented as image resize. 
1D, 2D and 3D arrays are supported, where 3D array is
treated as channeled image - each channel is interpolated 
as isolated 2D array (matrix).

Interpolation function is given as a template parameter. 
Default interpolation function is linear. Custom interpolation
function can be implemented in the 3rd party code, by following
interpolation function rules in dcv.imgproc.interpolation.

Params:
    slice = Slice to an input array.
    newsize = tuple that defines new shape. New dimension has to be
    the same as input slice in the 1D and 2D resize, where in the 
    3D resize newsize has to be 2D.

TODO: consider size input as array, and add prealloc
*/
Slice!(RCI!V, N, SliceKind.contiguous) resize(alias interp = linear, SliceKind kind, size_t N, V, size_t SN)(Slice!(V*, N, kind) slice, size_t[SN] newsize)
    //if (packs.length == 1)
    //if (isInterpolationFunc!interp)
{

    static if (N == 1LU)
    {
        static assert(SN == 1, "Invalid new-size setup - dimension does not match with input slice.");
        return resizeImpl_1!interp(slice, newsize[0]);
    }
    else static if (N == 2LU)
    {
        static assert(SN == 2, "Invalid new-size setup - dimension does not match with input slice.");
        return resizeImpl_2!interp(slice, newsize[0], newsize[1]);
    }
    else static if (N == 3LU)
    {
        static assert(SN == 2, "Invalid new-size setup - 3D resize is performed as 2D."); // TODO: find better way to say this...
        return resizeImpl_3!interp(slice, newsize[0], newsize[1]);
    }
    else
    {
        static assert(0, "Resize is not supported for slice with " ~ N.stringof ~ " dimensions.");
    }
}

unittest
{
    auto vector = [0.0f, 0.1f, 0.2f].sliced(3);
    auto matrix = [0.0f, 0.1f, 0.2f, 0.3f].sliced(2, 2);
    auto image = [0.0f, 0.1f, 0.2f, 0.3f, 0.4f, 0.5f, 0.6f, 0.7f].sliced(2, 2, 2);

    auto resv = vector.resize!linear([10]);
    assert(resv.shape.length == 1);
    assert(resv.length == 10);

    auto resm = matrix.resize!linear([10, 15]);
    assert(resm.shape.length == 2);
    assert(resm.length!0 == 10 && resm.length!1 == 15);

    auto resi = image.resize!linear([20, 14]);
    assert(resi.shape.length == 3);
    assert(resi.length!0 == 20 && resi.length!1 == 14 && resi.length!2 == 2);
}

/**
Scale array size using custom interpolation function.

Implemented as convenience function which calls resize 
using scaled shape of the input slice as:

$(D_CODE scaled = resize(input, input.shape*scale))

 */
Slice!(RCI!V, N, kind) scale(alias interp = linear, V, ScaleValue, SliceKind kind, size_t N, size_t SN)(Slice!(V*, N, kind) slice, ScaleValue[SN] scale)
        if (isFloatingPoint!ScaleValue && isInterpolationFunc!interp)
{
    debug import std.exception : std_enforce = enforce;

    foreach (v; scale)
        assert(v > 0., "Invalid scale values (v > 0.0)");

    static if (N == 1LU)
    {
        static assert(SN == 1, "Invalid scale setup - dimension does not match with input slice.");
        size_t newsize = cast(size_t)(slice.length * scale[0]);
        debug std_enforce(newsize > 0, "Scaling value invalid - after scaling array size is zero.");
        return resizeImpl_1!interp(slice, newsize);
    }
    else static if (N == 2LU)
    {
        static assert(SN == 2, "Invalid scale setup - dimension does not match with input slice.");
        size_t[2] newsize = [cast(size_t)(slice.length!0 * scale[0]), cast(size_t)(slice.length!1 * scale[1])];
        debug std_enforce(newsize[0] > 0 && newsize[1] > 0, "Scaling value invalid - after scaling array size is zero.");
        return resizeImpl_2!interp(slice, newsize[0], newsize[1]);
    }
    else static if (N == 3LU)
    {
        static assert(SN == 2, "Invalid scale setup - 3D scale is performed as 2D."); // TODO: find better way to say this...
        size_t[2] newsize = [cast(size_t)(slice.length!0 * scale[0]), cast(size_t)(slice.length!1 * scale[1])];
        debug std_enforce(newsize[0] > 0 && newsize[1] > 0, "Scaling value invalid - after scaling array size is zero.");
        return resizeImpl_3!interp(slice, newsize[0], newsize[1]);
    }
    else
    {
        import std.conv : to;
        static assert(0, "Resize is not supported for slice with " ~ N.to!string ~ " dimensions.");
    }
}

unittest
{
    auto vector = [0.0f, 0.1f, 0.2f].sliced(3);
    auto matrix = [0.0f, 0.1f, 0.2f, 0.3f].sliced(2, 2);
    auto image = [0.0f, 0.1f, 0.2f, 0.3f, 0.4f, 0.5f, 0.6f, 0.7f].sliced(2, 2, 2);

    auto resv = vector.scale!linear([2.0f]);
    assert(resv.shape.length == 1);
    assert(resv.length == vector.length * 2);

    auto resm = matrix.scale!linear([3.0f, 4.0f]);
    assert(resm.shape.length == 2);
    assert(resm.length!0 == matrix.length!0 * 3 && resm.length!1 == matrix.length!1 * 4);

    auto resi = image.scale!linear([5.0f, 8.0f]);
    assert(resi.shape.length == 3);
    assert(resi.length!0 == image.length!0 * 5 && resi.length!1 == image.length!1 * 8 && resi.length!2 == 2);
}

/**
Pixel-wise warping of the image.

Displace each pixel of an image by given [x, y] values.

Params:
    interp = (template parameter) Interpolation function, default linear.
    image = Input image, which is warped. Single and multiple channel images are allowed.
    map = Displacement map, which holds [x, y] displacement for each pixel of an image.
    prealloc = Pre-allocated memory where resulting warped image is stored, if defined. 
    Should be of same shape as input image, or an emptySlice, which implies newly allocated image is used.

Returns:
    Warped input image by given map.
*/
pure auto warp(alias interp = linear, ImageTensor, MapTensor, PreAl)(ImageTensor image, MapTensor map,
        PreAl prealloc = emptyRCSlice!(ImageTensor.N, DeepElementType!ImageTensor))
{
    return pixelWiseDisplacement!(linear, DisplacementType.WARP, ImageTensor, MapTensor, PreAl)
        (image, map, prealloc);
}

/**
Pixel-wise remapping of the image.

Move each pixel of an image to a given [x, y] location defined by the map.
Function is similar to dcv.imgproc.imgmanip.warp, except displacement of pixels
is absolute, rather than relative.

Params:
    interp = (template parameter) Interpolation function, default linear.
    image = Input image, which is remapped. Single and multiple channel images are allowed.
    map = Target map, which holds [x, y] position for each pixel of an image.
    prealloc = Pre-allocated memory where resulting remapped image is stored, if defined. 
    Should be of same shape as input image, or an emptySlice, which implies newly allocated image is used.

Returns:
    Remapped input image by given map.
*/
pure auto remap(alias interp = linear, ImageTensor, MapTensor)(ImageTensor image, MapTensor map,
        ImageTensor prealloc = ImageTensor.init)
{
    return pixelWiseDisplacement!(linear, DisplacementType.REMAP, ImageTensor, MapTensor)
        (image, map, prealloc);
}

/// Test if warp and remap always returns slice of corresponding format.
unittest
{
    import std.random : uniform01;
    import mir.ndslice.allocation;

    auto image = iota(3, 3).as!float.slice;
    auto wmap = iota(3, 3, 2).map!(v => cast(float)uniform01).slice;

    auto warped = image.warp(wmap);
    assert(warped.shape == image.shape);

    auto remapped = image.remap(wmap);
    assert(remapped.shape == image.shape);
}

unittest
{
    import std.random : uniform01;
    import mir.ndslice.allocation;

    auto image = iota(3, 3, 3).as!float.slice;
    auto wmap = iota(3, 3, 2).map!(v => cast(float)uniform01).slice;
    auto warped = image.warp(wmap);
    assert(warped.shape == image.shape);

    auto remapped = image.remap(wmap);
    assert(remapped.shape == image.shape);
}

unittest
{
    import std.random : uniform01;
    import mir.ndslice.allocation;

    auto image = iota(3, 3).as!float.slice;
    auto warped = slice!float(3, 3);
    auto remapped = slice!float(3, 3);
    auto wmap = iota(3, 3, 2).map!(v => cast(float)uniform01).slice;
    auto warpedRetVal = image.warp(wmap, warped);
    assert(warped.shape == image.shape);
    assert(warpedRetVal.shape == image.shape);
    assert(&warped[0, 0] == &warpedRetVal[0, 0]);

    auto remappedRetVal = image.remap(wmap, remapped);
    assert(remapped.shape == image.shape);
    assert(remappedRetVal.shape == image.shape);
    assert(&remapped[0, 0] == &remappedRetVal[0, 0]);
}

private enum DisplacementType
{
    WARP,
    REMAP
}

private pure auto pixelWiseDisplacement(alias interp, DisplacementType disp, ImageTensor, MapTensor, PreAl)
    (ImageTensor image, MapTensor map, PreAl prealloc)
in
{
    assert(!image.empty, "Input image is empty");
    assert(map.shape[0 .. 2] == image.shape[0 .. 2], "Invalid map size.");
}
do
{
    static assert(isSlice!ImageTensor, "Image type has to be of type mir.ndslice.slice.Slice");
    static assert(isSlice!MapTensor, "Map type has to be of type mir.ndslice.slice.Slice");
    immutable N = ImageTensor.init.N;
    
    static assert(MapTensor.init.N == 3LU,
            "Invalid map tensor dimension - should be matrix of [x, y] displacements (3D).");

    if (prealloc.shape != image.shape)
    {
        prealloc = uninitRCslice!(DeepElementType!ImageTensor)(image.shape); //uninitializedSlice!(DeepElementType!ImageTensor)(image.shape);
    }

    static if (N == 2)
    {
        displacementImpl!(interp, disp, ImageTensor, MapTensor)
            (image, map, prealloc);
    }
    else static if (N == 3)
    {
        foreach (i; 0 .. image.length!2)
        {
            auto imagec = image[0 .. $, 0 .. $, i];
            auto resultc = prealloc[0 .. $, 0 .. $, i];
            displacementImpl!(interp, disp, typeof(imagec), MapTensor)
                (imagec, map, resultc);
        }
    }
    else
        static assert(0, "Pixel displacement operations are supported only for 2D and 3D slices.");

    return prealloc;
}

private pure void displacementImpl(alias interp, DisplacementType disp, ImageMatrix, MapTensor, Result)
    (ImageMatrix image, MapTensor map, Result result)
{
    static if (disp == DisplacementType.WARP)
        float r = 0.0f, c;
    immutable rf = cast(float)image.length!0;
    immutable cf = cast(float)image.length!1;

    auto image_ls = image.lightScope;

    for (; !result.empty; result.popFront, map.popFront)
    {
        auto rrow = result.front;
        auto mrow = map.front;
        static if (disp == DisplacementType.WARP) c = 0.0f;
        for (; !rrow.empty; rrow.popFront, mrow.popFront)
        {
            auto m = mrow.front;
            static if (disp == DisplacementType.WARP)
            {
                float rr = r + m[1];
                float cc = c + m[0];
            }
            else
            {
                float rr = m[1];
                float cc = m[0];
            }
            if (rr >= 0.0f && rr < rf && cc >= 0.0f && cc < cf)
            {
                rrow.front = interp(image_ls, rr, cc);
            }
            static if (disp == DisplacementType.WARP) ++c;
        }
        static if (disp == DisplacementType.WARP) ++r;
    }
}

private enum TransformType : size_t
{
    AFFINE_TRANSFORM = 0,
    PERSPECTIVE_TRANSFORM = 1
}

private static bool isTransformMatrix(TransformMatrix)()
{
    import std.traits : isScalarType, isPointer, TemplateArgsOf, PointerTarget;

    static if (isArray!TransformMatrix)
    {
        static if (isArray!(ElementType!TransformMatrix)
                && isScalarType!(ElementType!(ElementType!TransformMatrix))
                && isFloatingPoint!(ElementType!(ElementType!TransformMatrix)))
            return true;
        else
            return false;
    }
    else static if (isSlice!TransformMatrix)
    {
        static if (kindOf!TransformMatrix == SliceKind.contiguous &&
                TemplateArgsOf!(TransformMatrix)[1] == 2 &&
                isFloatingPoint!(DeepElementType!TransformMatrix))
            return true;
        else
            return false;
    }
    else
    {
        return false;
    }
}

unittest
{
    static assert(isTransformMatrix!(float[][]));
    static assert(isTransformMatrix!(double[][]));
    static assert(isTransformMatrix!(real[][]));
    static assert(isTransformMatrix!(real[3][3]));
    static assert(isTransformMatrix!(Slice!(float*, 2, SliceKind.contiguous)));
    static assert(isTransformMatrix!(Slice!(double*, 2, SliceKind.contiguous)));
    static assert(isTransformMatrix!(Slice!(real*, 2, SliceKind.contiguous)));

    static assert(!isTransformMatrix!(Slice!(real*, 2, SliceKind.universal)));
    static assert(!isTransformMatrix!(Slice!(real*, 2, SliceKind.canonical)));

    static assert(!isTransformMatrix!(int[][]));
    static assert(!isTransformMatrix!(real[]));
    static assert(!isTransformMatrix!(real[][][]));
    static assert(!isTransformMatrix!(Slice!(int*, 2, SliceKind.contiguous)));
    static assert(!isTransformMatrix!(Slice!(float*, 1, SliceKind.contiguous)));
}

/**
Transform an image by given affine transformation.

Params:
    interp = (template parameter) Interpolation function. Default linear.
    slice = Slice of an image which is transformed.
    transform = 2D Transformation matrix (3x3). Its element type must be floating point type,
    and it can be defined as Slice object, dynamic or static 2D array.
    outSize = Output image size - if transformation potentially moves parts of image out
    of input image bounds, output image can be sized differently to maintain information.

Note:
    Given transformation is considered to be an affine transformation. If it is not, result is undefined.

Returns:
    Transformed image.
*/
Slice!(RCI!V, N, kind) transformAffine(alias interp = linear, V, TransformMatrix, SliceKind kind, size_t N)(Slice!(V*, N, kind) slice, inout TransformMatrix transform, size_t[2] outSize = [0, 0])
{
    static if (isTransformMatrix!TransformMatrix)
    {
      return transformImpl!(TransformType.AFFINE_TRANSFORM, interp)(slice, transform, outSize);
    }
    else
    {
        static assert(0, "Invalid transform matrix type: " ~ typeof(transform).stringof);
    }
}

/**
Transform an image by given perspective transformation.

Params:
    interp = (template parameter) Interpolation function. Default linear.
    slice = Slice of an image which is transformed.
    transform = 2D Transformation matrix (3x3). Its element type must be floating point type,
    and it can be defined as Slice object, dynamic or static 2D array.
    outSize = Output image size [width, height] - if transformation potentially moves parts of image out
    of input image bounds, output image can be sized differently to maintain information.

Note:
    Given transformation is considered to be an perspective transformation. If it is not, result is undefined.

Returns:
    Transformed image.
*/
Slice!(RCI!V, N, kind) transformPerspective(alias interp = linear, V, TransformMatrix, SliceKind kind, size_t N)(
    Slice!(V*, N, kind) slice,
    TransformMatrix transform,
    size_t[2] outSize = [0, 0])
{
    static if (isTransformMatrix!TransformMatrix)
    {
      return transformImpl!(TransformType.PERSPECTIVE_TRANSFORM, linear)(slice, transform, outSize);
    }
    else
    {
        static assert(0, "Invalid transform matrix type: " ~ typeof(transform).stringof);
    }
}

version (unittest)
{
    auto transformMatrix = [[1.0f, 0.0f, 5.0f], [0.0f, 1.0f, 5.0f], [0.0f, 0.0f, 1.0f]];
}

unittest
{
    // test if affine transform without outSize parameter gives out same-shaped result.
    import mir.ndslice.allocation;
    auto image = slice!float(3, 3);
    auto transformed = transformAffine(image, transformMatrix);
    assert(image.shape == transformed.shape);
}

unittest
{
    // test if affine transform with outSize parameter gives out proper-shaped result.
    import mir.ndslice.allocation;
    auto image = slice!float(3, 3);
    auto transformed = transformAffine(image, transformMatrix, [5, 10]);
    assert(transformed.length!0 == 10 && transformed.length!1 == 5);
}

unittest
{
    // test if perspective transform without outSize parameter gives out same-shaped result.
    import mir.ndslice.allocation;
    auto image = slice!float(3, 3);
    auto transformed = transformPerspective(image, transformMatrix);
    assert(image.shape == transformed.shape);
}

unittest
{
    // test if perspective transform with outSize parameter gives out proper-shaped result.
    import mir.ndslice.allocation;
    auto image = slice!float(3, 3);
    auto transformed = transformPerspective(image, transformMatrix, [5, 10]);
    assert(transformed.length!0 == 10 && transformed.length!1 == 5);
}

private:
@nogc nothrow:

// 1d resize implementation
Slice!(RCI!V, 1LU, SliceKind.contiguous) resizeImpl_1(alias interp, V)(Slice!(V*, 1LU, SliceKind.contiguous) slice, size_t newsize)
{

    assert(!slice.empty && newsize > 0);

    auto retval = RCArray!V(newsize);
    auto resizeRatio = cast(float)(newsize - 1) / cast(float)(slice.length - 1);

    auto iterable = newsize.iota;
    void worker(int _i, int threadIndex) nothrow @nogc {
        auto i = iterable[_i];
        retval[i] = interp(slice, cast(float)i / resizeRatio);
    }
    pool.parallelFor(cast(int)iterable.length, &worker);

    return retval.moveToSlice;
}

// 1d resize implementation
Slice!(RCI!V, 2LU, SliceKind.contiguous) resizeImpl_2(alias interp, SliceKind kind, V)(Slice!(V*, 2LU, kind) slice, size_t height, size_t width)
{

    assert(!slice.empty && width > 0 && height > 0);

    auto retval = uninitRCslice!V(height, width);

    auto rows = slice.length!0;
    auto cols = slice.length!1;

    auto r_v = cast(float)(height - 1) / cast(float)(rows - 1); // horizontaresize ratio
    auto r_h = cast(float)(width - 1) / cast(float)(cols - 1);

    auto iterable = iota(height);
    void worker(int _i, int threadIndex) nothrow @nogc {
        auto i = iterable[_i];
        auto row = retval[i, 0 .. width];
        foreach (j; iota(width))
        {
            row[j] = interp(slice, cast(float)i / r_v, cast(float)j / r_h);
        }
    }
    pool.parallelFor(cast(int)iterable.length, &worker);

    return retval;
}

// 1d resize implementation
Slice!(RCI!V, 3LU, SliceKind.contiguous) resizeImpl_3(alias interp, SliceKind kind, V)(Slice!(V*, 3LU, kind) slice, size_t height, size_t width)
{

    assert(!slice.empty && width > 0 && height > 0);

    auto rows = slice.length!0;
    auto cols = slice.length!1;
    auto channels = slice.length!2;

    auto retval = uninitRCslice!V(height, width, channels);

    auto r_v = cast(float)(height - 1) / cast(float)(rows - 1); // horizontaresize ratio
    auto r_h = cast(float)(width - 1) / cast(float)(cols - 1);

    foreach (c; iota(channels))
    {
        auto sl_ch = slice[0 .. rows, 0 .. cols, c];
        auto ret_ch = retval[0 .. height, 0 .. width, c];

        auto iterable = iota(height);
        void worker(int _i, int threadIndex) nothrow @nogc {
            auto i = iterable[_i];
            auto row = ret_ch[i, 0 .. width];
            foreach (j; iota(width))
            {
                row[j] = interp(sl_ch, cast(float)i / r_v, cast(float)j / r_h);
            }
        }
        pool.parallelFor(cast(int)iterable.length, &worker);
    }

    return retval;
}

Slice!(RCI!float, 2LU, SliceKind.contiguous) invertTransformMatrix(TransformMatrix)(TransformMatrix t)
{
    auto result = rcslice!float(3, 3);

    double determinant = +t[0][0] * (t[1][1] * t[2][2] - t[2][1] * t[1][2]) - t[0][1] * (
            t[1][0] * t[2][2] - t[1][2] * t[2][0]) + t[0][2] * (t[1][0] * t[2][1] - t[1][1] * t[2][0]);

    try enforce!"Transform matrix determinant is zero."(determinant != 0.0f);
    catch(Exception e) assert(false, e.msg);

    double invdet = 1 / determinant;
    result[0][0] = (t[1][1] * t[2][2] - t[2][1] * t[1][2]) * invdet;
    result[0][1] = -(t[0][1] * t[2][2] - t[0][2] * t[2][1]) * invdet;
    result[0][2] = (t[0][1] * t[1][2] - t[0][2] * t[1][1]) * invdet;
    result[1][0] = -(t[1][0] * t[2][2] - t[1][2] * t[2][0]) * invdet;
    result[1][1] = (t[0][0] * t[2][2] - t[0][2] * t[2][0]) * invdet;
    result[1][2] = -(t[0][0] * t[1][2] - t[1][0] * t[0][2]) * invdet;
    result[2][0] = (t[1][0] * t[2][1] - t[2][0] * t[1][1]) * invdet;
    result[2][1] = -(t[0][0] * t[2][1] - t[2][0] * t[0][1]) * invdet;
    result[2][2] = (t[0][0] * t[1][1] - t[1][0] * t[0][1]) * invdet;

    return result;
}

Slice!(RCI!V, N, kind) transformImpl(TransformType transformType, alias interp, V, TransformMatrix, SliceKind kind, size_t N)
    (Slice!(V*, N, kind) slice, TransformMatrix transform, size_t[2] outSize)
in
{
    static assert(N == 2LU || N == 3LU, "Unsupported slice dimension (only 2D and 3D supported)");

    uint rcount = 0;
    foreach (r; transform)
    {
        assert(r.length == 3);
        rcount++;
    }
    assert(rcount == 3);
}
do
{
    // outsize is [width, height]
    if (outSize[0] == 0)
        outSize[0] = slice.length!1;
    if (outSize[1] == 0)
        outSize[1] = slice.length!0;
    
    int err;
    static if (N == 2LU)
    {
        auto tSlice = RCArray!V(outSize[0] * outSize[1]).moveToSlice.reshape([outSize[1], outSize[0]], err);
    }
    else
    {
        auto tSlice = RCArray!V(outSize[0] * outSize[1] * slice.length!2).moveToSlice.reshape([outSize[1], outSize[0], slice.length!2], err);
    }

    tSlice[] = cast(V)0;

    auto t = transform.invertTransformMatrix;

    static if (N == 3LU)
    {
        typeof(slice[0..$, 0..$, 0])[N] sliceChannels;
        foreach (c; iota(slice.length!2))
        {
            sliceChannels[c] = slice[0 .. $, 0 .. $, c];
        }
    }

    double outOffset_x = cast(double)outSize[0] / 2.;
    double outOffset_y = cast(double)outSize[1] / 2.;
    double inOffset_x = cast(double)slice.length!1 / 2.;
    double inOffset_y = cast(double)slice.length!0 / 2.;

    foreach (i; iota(outSize[1]))
    { // height, rows
        foreach (j; iota(outSize[0]))
        { // width, columns
            double src_x, src_y;
            double dst_x = cast(double)j - outOffset_x;
            double dst_y = cast(double)i - outOffset_y;
            static if (transformType == TransformType.AFFINE_TRANSFORM)
            {
                src_x = t[0, 0] * dst_x + t[0, 1] * dst_y + t[0, 2];
                src_y = t[1, 0] * dst_x + t[1, 1] * dst_y + t[1, 2];
            }
            else static if (transformType == TransformType.PERSPECTIVE_TRANSFORM)
            {
                double d = (t[2, 0] * dst_x + t[2, 1] * dst_y + t[2, 2]);
                src_x = (t[0, 0] * dst_x + t[0, 1] * dst_y + t[0, 2]) / d;
                src_y = (t[1, 0] * dst_x + t[1, 1] * dst_y + t[1, 2]) / d;
            }
            else
            {
                static assert(0, "Invalid transform type"); // should never happen
            }
            src_x += inOffset_x;
            src_y += inOffset_y;
            if (src_x >= 0 && src_x < slice.length!1 && src_y >= 0 && src_y < slice.length!0)
            {
                static if (N == 2LU)
                {
                    tSlice[i, j] = interp(slice, src_y, src_x);
                }
                else if (N == 3LU)
                {
                    foreach (c; iota(slice.length!2))
                    {
                        tSlice[i, j, c] = interp(sliceChannels[c], src_y, src_x);
                    }
                }
            }
        }
    }

    return tSlice;
}