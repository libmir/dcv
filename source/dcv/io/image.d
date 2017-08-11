/**
   Module for image I/O.

   Copyright: Copyright Relja Ljubobratovic 2016.

   Authors: Relja Ljubobratovic

   License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
 */
module dcv.io.image;

import std.exception: enforce;
import std.range:array, empty;
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

class InvalidDecoderException : Exception
{
    this(in string msg = "")
    {
        super("Invalid algorithm is used to decode an image" ~ msg.empty ? "" : (", " ~ msg));
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

enum Codec
{
    bmp,
    png,
    tga,
    jpeg
}

/**
   Decode raw image data from memory.

   Params:
      data = Data buffer containing encoded image.
      codec = Codec algorithm with which the image gets decoded.

   Return:
      Decoded image.

   Throws:
     InvalidDecoderException.
 */
ContiguousMatrix!T imdecode(T)(in ubyte[] data, Codec codec)
if (isPixel!T)
{
    return imdecodeImpl_imageformats!T(data, codec);
}


/**
   Write image to the given path on the filesystem.

   Params:
      image = Image data.
      path = Path where the image will be written.

   Throws:
      IOImageException.
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
    // The underlying library (imageformats) is likey to be changed
    // someday.
    catch (Throwable e)
    {
        throw new IOImageException(e.msg);
    }
}

ContiguousMatrix!T imdecodeImpl_imageformats(T)(in ubyte[] data, Codec codec)
{
    enum ifTypeCode = imreadImpl_imageformats_adoptFormat!T;
    enum depth      = pixelDepth!T;

    try
    {
        static if (depth == 1)
        {
            auto    decoder_func = selectDecoder8_imageformats(codec);
            IFImage ifim         = decoder_func(data, 0);
            return (cast(T*)ifim.pixels.ptr).sliced(ifim.h, ifim.w);
        }
        else static if (depth == 2)
        {
            auto      decoder_func = selectDecoder16_imageformats(codec);
            IFImage16 ifim         = decoder_func(data, 0);
            return (cast(T*)ifim.pixels.ptr).sliced(ifim.h, ifim.w);
        }
        else
        {
            static assert(0, "Reading image depth not supported.");
        }
    }
    catch (InvalidDecoderException e)
    {
        // just rethrow
        throw e;
    }
    // Wrap third party custom exception type into DCV error type,
    // The underlying library (imageformats) is likey to be changed
    // someday.
    catch (Throwable e)
    {
        throw new InvalidDecoderException(e.msg);
    }
}

alias DecoderFunc8  = IFImage function(in ubyte[], long);
alias DecoderFunc16 = IFImage16 function(in ubyte[], long);

DecoderFunc8 selectDecoder8_imageformats(Codec codec)
{
    final switch (codec)
    {
    case Codec.bmp:
        return &read_bmp_from_mem;
    case codec.png:
        return &read_png_from_mem;
    case codec.tga:
        return &read_tga_from_mem;
    case codec.jpeg:
        return &read_jpeg_from_mem;
    }
}

DecoderFunc16 selectDecoder16_imageformats(Codec codec)
{
    switch (codec)
    {
    case codec.png:
        return &read_png16_from_mem;
    default:
        throw new InvalidDecoderException("Only png format supported for 16-bit images.");
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
}

