/**
Module for image I/O.
Copyright: Copyright Relja Ljubobratovic 2016.
Authors: Relja Ljubobratovic
License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.imageio.image;
/*
TODO: write wrappers and  use libjpeg, libpng, libtiff, openexr.
v0.1 norm:
Implemented and tested Image class.
*/

import std.exception : enforce;
import std.range : array;
import std.algorithm : reduce;
import std.string : toLower;
import std.path : extension;

import gamut : GamutImage = Image,
                LOAD_NO_ALPHA,
                LOAD_RGB,
                LOAD_GREYSCALE,
                LOAD_8BIT,
                LOAD_16BIT,
                PixelType,
                LAYOUT_GAPLESS,
                LAYOUT_VERT_STRAIGHT;
                
                

import mir.ndslice.topology : reshape;
import mir.ndslice.slice;

public import dcv.core.image;

version (unittest)
{
    import std.algorithm : map;
    import std.range : iota;
    import std.random : uniform;
    import std.array : array;
    import std.functional : pipe;
    import std.path : extension;
    import std.file : dirEntries, SpanMode, remove;

    alias imgen_8 = pipe!(iota, map!(v => cast(ubyte)uniform(0, ubyte.max)), array);
    alias imgen_16 = pipe!(iota, map!(v => cast(ushort)uniform(0, ushort.max)), array);

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

/// Image reading parameter package type.
struct ReadParams
{
    ImageFormat format = ImageFormat.IF_UNASSIGNED;
    BitDepth depth = BitDepth.BD_UNASSIGNED;
}

/** 
Read image from the file system.
params:
path = File system path to the image.
params = Reading parameters - desired format and depth of the image that's read. 
Default parameters include no convertion, but loading image orignal data depth and 
color format. To load original depth or format, set to _UNASSIGNED (ImageFormat.IF_UNASSIGNED,
BitDepth.BD_UNASSIGNED).
return:
Image read from the filesystem.
throws:
Exception and ImageIOException from imageformats library.
*/
Image imread(in string path, ReadParams params = ReadParams(ImageFormat.IF_UNASSIGNED, BitDepth.BD_UNASSIGNED))
{
    return imreadImpl_imageformats(path, params);
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

unittest
{

}

/**
Write image to the given path on the filesystem.
params:
path = Path where the image will be written.
width = Width of the image.
height = Height of the image.
format = Format of the image.
depth = Bit depth of the image.
data = Image data in unsigned bytes.
return:
Status of the writing as bool.
*/
bool imwrite(in string path, size_t width, size_t height, ImageFormat format, BitDepth depth, ubyte[] data)
{
    assert(depth != BitDepth.BD_UNASSIGNED);
    assert(width > 0 && height > 0);
    if (depth == BitDepth.BD_8)
    {
        GamutImage image;
        image.loadFromMemory(data, ReadParams(format, depth).readParams2LoadFlags);
        if (!image.saveToFile(path))
                throw new Exception("Writing " ~ path ~ " failed");
        // write_image(path, cast(long)width, cast(long)height, data, imageFormatChannelCount[format]);
    }
    else if (depth == BitDepth.BD_16)
    {
        throw new Exception("Writting image format not supported.");
    }
    else
    {
        throw new Exception("Writting image format not supported.");
    }
    return true;
}

/**
Convenience wrapper for imwrite with Image.
params:
image = Image to be written;
path = Path where the image will be written.
return:
Status of the writing as bool.
*/
bool imwrite(in Image image, in string path)
{
    return imwrite(path, image.width, image.height, image.format, image.depth, image.data!ubyte);
}

/**
Convenience wrapper for imwrite with Slice type.
Params:
    slice   = Slice of the image data;
    format  = Explicit definition of the image format.
    path    = Path where the image will be written.
Returns:
    Status of the writing as bool.
*/


bool imwrite(SliceKind kind, size_t N, Iterator)
(
    Slice!(Iterator, N, kind) slice,
    ImageFormat format,
    in string path
)
{
    //static assert(packs.length == 1, "Packed slices are not allowed in imwrite.");
    static assert(N == 2LU || N == 3LU, "Slice has to be 2 or 3 dimensional.");

    import mir.rc: RCI;
    import std.traits;
    static if (__traits(isSame, TemplateOf!(IteratorOf!(typeof(slice))), RCI))
    { // is refcounted?
        alias ASeq = TemplateArgsOf!(IteratorOf!(typeof(slice)));
        alias T = ASeq[0];
    }else{ // is custom (GC) allocated
        alias PointerOf(T : T*) = T;
        alias P = IteratorOf!(typeof(slice));
        alias T = PointerOf!P;
    }

    int err;
    auto sdata = slice.reshape([slice.elementCount], err).array;
    assert(err == 0, "Internal error, cannot reshape the slice."); // should never happen, right?

    static if (is(T == ubyte))
    {
        return imwrite(path, slice.shape[1], slice.shape[0], format, BitDepth.BD_8, sdata);
    }
    else static if (is(T == ushort))
    {
        throw new Exception("Writting image format not supported.");
    }
    else static if (is(T == float))
    {
        throw new Exception("Writting image format not supported.");
    }
    else
    {
        throw new Exception("Writting image format not supported.");
    }
}


unittest
{
    // test 8-bit mono image writing
    import std.algorithm.comparison : equal;

    auto f = "__test__.png";
    auto fs = "__test__slice__.png";
    auto d = im_ubyte_8_mono;
    auto w = 32;
    auto h = 32;
    auto imw = new Image(w, h, ImageFormat.IF_MONO, BitDepth.BD_8, d);
    imwrite(imw, f);
    imwrite(imw.sliced, ImageFormat.IF_MONO, fs);
    Image im = imread(f, ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8));
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
    catch(Exception e)
    {
    }
}

unittest
{
    // test 8-bit rgb image writing
    import std.algorithm.comparison : equal;

    auto f = "__test__.png";
    auto fs = "__test__slice__.png";
    auto d = im_ubyte_8_rgb;
    auto w = 32;
    auto h = 32;
    auto imw = new Image(w, h, ImageFormat.IF_RGB, BitDepth.BD_8, d);
    imwrite(imw, f);
    imwrite(imw.sliced, ImageFormat.IF_RGB, fs);
    Image im = imread(f, ReadParams(ImageFormat.IF_RGB, BitDepth.BD_8));
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
    catch(Exception e)
    {
    }
}

unittest
{
    // test 8-bit rgba image writing
    import std.algorithm.comparison : equal;

    auto f = "__test__.png";
    auto fs = "__test__slice__.png";
    auto d = im_ubyte_8_rgba;
    auto w = 32;
    auto h = 32;
    auto imw = new Image(w, h, ImageFormat.IF_RGB_ALPHA, BitDepth.BD_8, d);
    imwrite(imw, f);
    imwrite(imw.sliced, ImageFormat.IF_RGB_ALPHA, fs);
    Image im = imread(f, ReadParams(ImageFormat.IF_RGB_ALPHA, BitDepth.BD_8));
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
    catch(Exception e)
    {
    }
}

private:

int readParams2LoadFlags(ReadParams params){
    int ret;

    if(params.format == ImageFormat.IF_RGB){
        ret |= LOAD_RGB;
    }else 
    if(params.format == ImageFormat.IF_MONO){
        ret |= LOAD_GREYSCALE;
    }
    
    if(params.depth == BitDepth.BD_8){
        ret |= LOAD_8BIT;
    }else 
    if(params.depth == BitDepth.BD_16){
        ret |= LOAD_16BIT;
    }
    return ret | LOAD_NO_ALPHA;
}

Image imreadImpl_imageformats(in string path, ReadParams params)
{
    enforce(params.depth != BitDepth.BD_32, "Currenly reading of 32-bit image data is not supported");

    if (params.format == ImageFormat.IF_UNASSIGNED)
        params.format = ImageFormat.IF_RGB;

    Image im = null;
    //auto ch = imreadImpl_imageformats_adoptFormat(params.format);

    GamutImage gimage;
    
    if (params.depth == BitDepth.BD_UNASSIGNED || params.depth == BitDepth.BD_8)
    {
        //IFImage ifim = read_image(path, ch);
        gimage.loadFromFile(path, LOAD_NO_ALPHA | LOAD_RGB | LOAD_8BIT);
        //gimage.setSize(gimage.width, gimage.height, PixelType.rgb8, LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT); // make contiguous

        //ubyte[] allpixels = gimage.allPixelsAtOnce().dup;

        ubyte[] allpixels = new ubyte[gimage.width*gimage.height*3];
        size_t kk;
        for (int y = 0; y < gimage.height(); ++y)
        {
            ubyte* scan = cast(ubyte*) gimage.scanline(y);
            for (int x = 0; x < gimage.width(); ++x)
            {
                allpixels[kk++] = scan[3*x + 0];
                allpixels[kk++] = scan[3*x + 1];
                allpixels[kk++] = scan[3*x + 2];
            }
        }
        
        import std.conv : to;
        if (gimage.errored)
            throw new Exception(gimage.errorMessage.to!string);
        im = new Image(cast(size_t)gimage.width, cast(size_t)gimage.height, params.format, BitDepth.BD_8, allpixels);
    }
    else if (params.depth == BitDepth.BD_16)
    {
        // This should be revised according to gamut. Probably will not work as its present form

        enforce(path.extension.toLower == ".png", "Reading 16-bit image has to be in PNG format.");
        gimage.loadFromFile(path, LOAD_NO_ALPHA | LOAD_RGB | LOAD_16BIT);
        gimage.setSize(gimage.width, gimage.height, PixelType.rgb16, LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT);
        ubyte[] allpixels = gimage.allPixelsAtOnce().dup;
        //IFImage16 ifim = read_png16(path, ch);
        im = new Image(cast(size_t)gimage.width, cast(size_t)gimage.height, params.format, BitDepth.BD_16, allpixels);
    }
    else
    {
        throw new Exception("Reading image depth not supported.");
    }

    return im;
}

unittest
{
    // test 8 bit read
    auto f = "./tests/pngsuite/basi0g08.png";
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
    auto f = "./tests/pngsuite/basi0g08.png";
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
    auto f = "./tests/pngsuite/pngtest16rgba.png";
    Image im = imreadImpl_imageformats(f, ReadParams(ImageFormat.IF_UNASSIGNED, BitDepth.BD_16));
    assert(im);
    assert(im.width == 32);
    assert(im.height == 32);
    assert(im.channels == 3);
    assert(im.depth == BitDepth.BD_16);
    assert(im.format == ImageFormat.IF_RGB);
}

unittest
{
    // test if 32-bit read request fails
    // TODO: support, and remove the test.
    try
    {
        imreadImpl_imageformats("", ReadParams(ImageFormat.IF_UNASSIGNED, BitDepth.BD_32));
        assert(0);
    }
    catch (Exception e)
    {
        // should enter here...
    }
}

int imreadImpl_imageformats_adoptFormat(ImageFormat format)
{
    int ch = 0;
    switch (format)
    {
    case ImageFormat.IF_RGB:
        ch = 3;
        break;
    //case ImageFormat.IF_RGB_ALPHA:
    //    ch = 4;
    //    break;
    case ImageFormat.IF_MONO:
        ch = 1;
        break;
    //case ImageFormat.IF_MONO_ALPHA:
    //    ch = 2;
    //    break;
    default:
        throw new Exception("Format not supported");
    }
    return ch;
}

unittest
{
    /// Test imageformats color format adoption
    assert(imreadImpl_imageformats_adoptFormat(ImageFormat.IF_RGB) == ColFmt.RGB);
    assert(imreadImpl_imageformats_adoptFormat(ImageFormat.IF_RGB_ALPHA) == ColFmt.RGBA);
    assert(imreadImpl_imageformats_adoptFormat(ImageFormat.IF_MONO) == ColFmt.Y);
    assert(imreadImpl_imageformats_adoptFormat(ImageFormat.IF_MONO_ALPHA) == ColFmt.YA);
    try
    {
        imreadImpl_imageformats_adoptFormat(ImageFormat.IF_YUV);
        assert(0);
    }
    catch (Exception e)
    {
        // should enter here...
    }
}