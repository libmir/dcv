/**
   Module for image I/O.

   Copyright: Copyright Relja Ljubobratovic 2016.

   Authors: Relja Ljubobratovic

   License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
 */
module dcv.io.image;
/*


   TODO: write wrappers and  use libjpeg, libpng, libtiff, openexr.

   v0.1 norm:
   Implemented and tested Image class.
 */

import std.exception: enforce;
import std.range:array;
import std.algorithm: reduce;
import std.string: toLower;
import std.path:extension;

import imageformats;

import mir.ndslice.topology: reshape;
import mir.ndslice.slice:Slice, ContiguousMatrix, sliced, DeepElementType, Contiguous, SliceKind;
import mir.ndslice.allocation: slice;

import dcv.core.types;


/**
   Base classification for exception that can occurr in the
   image I/O.
 */
class IOImageException : Exception
{
    this(in string msg)
    {
        super(msg);
    }
}

/**
   Read image from the file system.

   Params:
      path = File system path to the image.

   Return:
      Image read from the filesystem.

   Throws:
      IOImageException.
 */
ContiguousMatrix!T imread(T)(in string path)
if (isPixel!T)
{
    return imreadImpl_imageformats!T(path);
}


unittest
{
    // should read all images.
    foreach (f; dirEntries("./tests/", SpanMode.breadth))
    {
        auto ext = f.extension.toLower;
        if (ext == ".png" || ext == ".bmp" || ext == ".tga")
        {
            Image im = imread(f);
            assert(im);
        }
    }
}


/**
   Write image to the given path on the filesystem.

   Params:
      path = Path where the image will be written.
      width = Width of the image.
      height = Height of the image.
      format = Format of the image.
      depth = Bit depth of the image.
      data = Image data in unsigned bytes.
 */
void imwrite(SliceKind kind, size_t[] packs, Iterator)
(
    Slice!(kind, packs, Iterator) image,
    in string path
) if (isPixel!(DeepElementType!(typeof(image)) ) )
{
    alias T = DeepElementType!(typeof(image)); // pixel type
    enum depth    = pixelDepth!T;
    enum channels = channelCount!T;

    // Extract scalar (basis) type of the image
    alias B = BaseType!T;

    static assert(is (B == Pixel8u), "Only 8bit image write is supported at this moment.");

    if (image.empty)
    {
        throw new IOImageException("Input image is empty.");
    }

    // Image raw data.
    B* data = null;

    static if (is (T* == Iterator) && kind == Contiguous)
    {
        data = cast(B*)image.iterator;
    }
    else
    {
        try
        {
            data = cast(B*)image.slice.iterator;
        }
        catch (Throwable t)
        {
            throw new IOImageException("Exception thrown while evaluating lazy image: " ~ t.msg);
        }
    }

    static if(depth == 1)
    {
        long w = cast(long)image.length !1;
        long h = cast(long)image.length !0;
        write_image(path, w, h, data[0 .. w * h * channels * depth], channels);
    }
    else
    {
        static assert(0, "Image bit depth not currently supported.");
    }
}

/**
   Convenience wrapper for imwrite with Image.

   params:
   image = Image to be written;
   path = Path where the image will be written.

   return:
   Status of the writing as bool.
 */
// bool imwrite(in Image image, in string path)
// {
//     return imwrite(path, image.width, image.height, image.format, image.depth, image.data!ubyte);
// }

/**
   Convenience wrapper for imwrite with Slice type.

   Params:
    slice   = Slice of the image data;
    format  = Explicit definition of the image format.
    path    = Path where the image will be written.

   Returns:
    Status of the writing as bool.
 */
// bool imwrite(SliceKind kind, size_t [] packs, T)
// (
//     Slice!(kind, packs, T*) slice,
//     ImageFormat format,
//     in string path
// )
// {
//     static assert(packs.length == 1, "Packed slices are not allowed in imwrite.");
//     static assert(packs[0] == 2 || packs[0] == 3, "Slice has to be 2 or 3 dimensional.");

//     int  err;
//     auto sdata = slice.reshape([slice.elementsCount], err).array;
//     assert(err == 0, "Internal error, cannot reshape the slice."); // should never happen, right?

//     static if (is (T == ubyte))
//     {
//         return imwrite(path, slice.shape[1], slice.shape[0], format, BitDepth.BD_8, sdata);
//     }
//     else static if (is (T == ushort))
//     {
//         throw new Exception("Writting image format not supported.");
//     }
//     else static if (is (T == float))
//     {
//         throw new Exception("Writting image format not supported.");
//     }
//     else
//     {
//         throw new Exception("Writting image format not supported.");
//     }
// }

version (unittest)
{
    import std.algorithm:map;
    import std.range:iota;
    import std.random:uniform;
    import std.array:array;
    import std.functional: pipe;
    import std.path:extension;
    import std.file:dirEntries, SpanMode, remove;

    alias imgen_8  = pipe!(iota, map!(v => cast(ubyte)uniform(0, ubyte.max)), std.array.array);
    alias imgen_16 = pipe!(iota, map!(v => cast(ushort)uniform(0, ushort.max)), std.array.array);

    auto im_ubyte_8_mono()
    {
        return (32 * 32).imgen_8;
    }

    auto im_ubyte_8_rgb()
    {
        return (32 * 32 * 3).imgen_8;
    }

    auto im_ubyte_8_rgba()
    {
        return (32 * 32 * 4).imgen_8;
    }

    auto im_ubyte_16_mono()
    {
        return (32 * 32).imgen_16;
    }

    auto im_ubyte_16_rgb()
    {
        return (32 * 32 * 3).imgen_16;
    }

    auto im_ubyte_16_rgba()
    {
        return (32 * 32 * 4).imgen_16;
    }
}
unittest
{
    // test 8-bit mono image writing
    import std.algorithm.comparison: equal;

    auto f   = "__test__.png";
    auto fs  = "__test__slice__.png";
    auto d   = im_ubyte_8_mono;
    auto w   = 32;
    auto h   = 32;
    auto imw = new Image(w, h, ImageFormat.IF_MONO, BitDepth.BD_8, d);
    imwrite(imw, f);
    imwrite(imw.sliced, ImageFormat.IF_MONO, fs);
    Image im  = imread(f, ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8));
    Image ims = imread(fs, ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8));

    // test read image comparing to the input arguments
    assert(im.width == w);
    assert(im.height == h);
    assert(im.format == ImageFormat.IF_MONO);
    assert(im.channels == 1);
    assert(im.depth == BitDepth.BD_8);
    assert(equal(im.data, d));

    // test slice written image compared to the Image writen one
    assert(im.width == ims.width);
    assert(im.height == ims.height);
    assert(im.format == ims.format);
    assert(im.channels == ims.channels);
    assert(im.depth == ims.depth);
    assert(equal(im.data, ims.data));
    try
    {
        remove(f);
        remove(fs);
    }
    catch
    {
    }
}

unittest
{
    // test 8-bit rgb image writing
    import std.algorithm.comparison: equal;

    auto f   = "__test__.png";
    auto fs  = "__test__slice__.png";
    auto d   = im_ubyte_8_rgb;
    auto w   = 32;
    auto h   = 32;
    auto imw = new Image(w, h, ImageFormat.IF_RGB, BitDepth.BD_8, d);
    imwrite(imw, f);
    imwrite(imw.sliced, ImageFormat.IF_RGB, fs);
    Image im  = imread(f, ReadParams(ImageFormat.IF_RGB, BitDepth.BD_8));
    Image ims = imread(fs, ReadParams(ImageFormat.IF_RGB, BitDepth.BD_8));

    // test read image comparing to the input arguments
    assert(im.width == w);
    assert(im.height == h);
    assert(im.format == ImageFormat.IF_RGB);
    assert(im.channels == 3);
    assert(im.depth == BitDepth.BD_8);
    assert(equal(im.data, d));

    // test slice written image compared to the Image writen one
    assert(im.width == ims.width);
    assert(im.height == ims.height);
    assert(im.format == ims.format);
    assert(im.channels == ims.channels);
    assert(im.depth == ims.depth);
    assert(equal(im.data, ims.data));
    try
    {
        remove(f);
        remove(fs);
    }
    catch
    {
    }
}

unittest
{
    // test 8-bit rgba image writing
    import std.algorithm.comparison: equal;

    auto f   = "__test__.png";
    auto fs  = "__test__slice__.png";
    auto d   = im_ubyte_8_rgba;
    auto w   = 32;
    auto h   = 32;
    auto imw = new Image(w, h, ImageFormat.IF_RGB_ALPHA, BitDepth.BD_8, d);
    imwrite(imw, f);
    imwrite(imw.sliced, ImageFormat.IF_RGB_ALPHA, fs);
    Image im  = imread(f, ReadParams(ImageFormat.IF_RGB_ALPHA, BitDepth.BD_8));
    Image ims = imread(fs, ReadParams(ImageFormat.IF_RGB_ALPHA, BitDepth.BD_8));

    // test read image comparing to the input arguments
    assert(im.width == w);
    assert(im.height == h);
    assert(im.format == ImageFormat.IF_RGB_ALPHA);
    assert(im.channels == 4);
    assert(im.depth == BitDepth.BD_8);
    assert(equal(im.data, d));

    // test slice written image compared to the Image writen one
    assert(im.width == ims.width);
    assert(im.height == ims.height);
    assert(im.format == ims.format);
    assert(im.channels == ims.channels);
    assert(im.depth == ims.depth);
    assert(equal(im.data, ims.data));

    try
    {
        remove(f);
        remove(fs);
    }
    catch
    {
    }
}

private:

ContiguousMatrix!T imreadImpl_imageformats(T)(in string path)
{
    enum ifTypeCode = imreadImpl_imageformats_adoptFormat!T;
    enum depth      = pixelDepth!T;

    try
    {
        static if (depth == 1)
        {
            IFImage ifim = read_image(path, ifTypeCode);
            return (cast(T*)ifim.pixels.ptr).sliced(ifim.h, ifim.w);
        }
        else static if (depth == 2)
        {
            IFImage16 ifim = read_png16(path, ifTypeCode);
            return (cast(T*)ifim.pixels.ptr).sliced(ifim.h, ifim.w);
        }
        else
        {
            static assert(0, "Reading image depth not supported.");
        }
    }
    // Wrap third party custom exception type into DCV error type,
    // Because the underlying library (imageformats) can be changed
    // someday.
    catch (Throwable e)
    {
        throw new IOImageException(e.msg);
    }

}

unittest
{
    // test 8 bit read
    auto  f   = "./tests/pngsuite/basi0g08.png";
    Image im1 = imreadImpl_imageformats(f, ReadParams(ImageFormat.IF_UNASSIGNED, BitDepth.BD_8));
    Image im2 = imreadImpl_imageformats(f, ReadParams(ImageFormat.IF_UNASSIGNED, BitDepth.BD_UNASSIGNED));
    assert(im1 && im2);
    assert(im1.width == im2.width);
    assert(im1.height == im2.height);
    assert(im1.channels == im2.channels);
    assert(im1.channels == 3);
    assert(im1.depth == im2.depth);
    assert(im1.depth == BitDepth.BD_8);
    assert(im1.format == im2.format);
}

unittest
{
    // test read as mono
    auto  f  = "./tests/pngsuite/basi0g08.png";
    Image im = imreadImpl_imageformats(f, ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8));
    assert(im);
    assert(im.width == 32);
    assert(im.height == 32);
    assert(im.channels == 1);
    assert(im.depth == BitDepth.BD_8);
    assert(im.format == ImageFormat.IF_MONO);
}

unittest
{
    // test 16 bit read
    auto  f  = "./tests/pngsuite/pngtest16rgba.png";
    Image im = imreadImpl_imageformats(f, ReadParams(ImageFormat.IF_UNASSIGNED, BitDepth.BD_16));
    assert(im);
    assert(im.width == 32);
    assert(im.height == 32);
    assert(im.channels == 3);
    assert(im.depth == BitDepth.BD_16);
    assert(im.format == ImageFormat.IF_RGB);
}

ColFmt imreadImpl_imageformats_adoptFormat(T)()
{
    static if (isRGB!T)
    {
        static if (T.components == "rgba")
        {
            return ColFmt.RGBA;
        }
        else static if (T.components == "rgb")
        {
            return ColFmt.RGB;
        }
        else static if (T.components == "l")
        {
            return ColFmt.Y;
        }
        else static if (T.components == "la")
        {
            return ColFmt.YA;
        }
    }
    else static if (isMonoPixel!T)
    {
        return ColFmt.Y;
    }
    else
    {
        static assert(0, "Given pixel type representative is invalid.");
    }
};

unittest
{
    /// Test imageformats color format adoption
    static assert(imreadImpl_imageformats_adoptFormat!RGB8 == ColFmt.RGB);
    static assert(imreadImpl_imageformats_adoptFormat!RBGA8 == ColFmt.RGBA);
    static assert(imreadImpl_imageformats_adoptFormat!Pixel8u == ColFmt.Y);
    static assert(imreadImpl_imageformats_adoptFormat!(RGB!("la", ubyte) ) == ColFmt.YA);
}

