/**
   Module for image I/O.

   Copyright: Copyright Relja Ljubobratovic 2016.

   Authors: Relja Ljubobratovic

   License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
 */
module dcv.io.image;

import std.exception: enforce;
import std.range:array;
import std.algorithm: reduce;
import std.string: toLower;
import std.path:extension;

import mir.ndslice.topology: reshape;
import mir.ndslice.slice:Slice, ContiguousMatrix, sliced, DeepElementType, Contiguous, SliceKind;
import mir.ndslice.allocation: slice;

import imageformats;

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

