/**
Module implements Image utility class, and basic API for image manipulation.
Image class encapsulates image properties with minimal functionality. It is primarily designed to be used as I/O unit.
For any image processing needs, image data can be sliced to mir.ndslice.slice.Slice. 
Example:
----
Image image = new Image(32, 32, ImageFormat.IF_MONO, BitDepth.BD_32);
Slice!(float*, 3, Contiguous) slice = image.sliced!float; // slice image data, considering the data is of float type.
assert(image.height == slice.length!0 && image.width == slice.length!1);
assert(image.channels == 1);
image = slice.asImage(ImageFormat.IF_MONO); // create the image back from sliced data.
----
Copyright: Copyright Relja Ljubobratovic 2016.
Authors: Relja Ljubobratovic
License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.core.image;

import std.exception : enforce;

/*public*/ import mir.ndslice.slice;
import mir.ndslice.allocation;


/// Image (pixel) format.
enum ImageFormat
{
    IF_UNASSIGNED = 0, /// Not assigned format.
    IF_MONO, /// Mono, single channel format.
    IF_MONO_ALPHA, /// Mono with alpha channel.
    IF_RGB, /// RGB format.
    IF_BGR, /// BGR format.
    IF_YUV, /// YUV (YCbCr) format.
    IF_RGB_ALPHA, /// RGB format with alpha.
    IF_BGR_ALPHA /// BGR format with alpha.
}

immutable size_t[] imageFormatChannelCount = [0, // unassigned
    1, // mono
    2, // mono alpha
    3, // rgb
    3, // bgr
    3, // yuv
    4, // rgba
    4 // bgra
    ];

/// Bit depth of a pixel in an image.
enum BitDepth : size_t
{
    BD_UNASSIGNED = 0, /// Not assigned depth info.
    BD_8 = 8, /// 8-bit (ubyte) depth type.
    BD_16 = 16, /// 16-bit (ushort) depth type.
    BD_32 = 32 /// 32-bit (float) depth type.
}

private pure nothrow @safe auto getDepthFromType(T)()
{
    static if (is(T == ubyte))
    {
        return BitDepth.BD_8;
    }
    else static if (is(T == ushort))
    {
        return BitDepth.BD_16;
    }
    else static if (is(T == float))
    {
        return BitDepth.BD_32;
    }
    else
    {
        return BitDepth.BD_UNASSIGNED;
    }
}

unittest
{
    assert(getDepthFromType!ubyte == BitDepth.BD_8);
    assert(getDepthFromType!ushort == BitDepth.BD_16);
    assert(getDepthFromType!float == BitDepth.BD_32);
    assert(getDepthFromType!real == BitDepth.BD_UNASSIGNED);
}

/**
Image abstraction type.
*/
class Image
{
private:
    // Format of an image.
    ImageFormat _format = ImageFormat.IF_UNASSIGNED;
    // Bit depth of a pixel: (8 - uchar, 16 - ushort, 32 - float)
    BitDepth _depth = BitDepth.BD_UNASSIGNED;
    // Width of the image.
    size_t _width = 0;
    // Height of the image.
    size_t _height = 0;
    // Image pixel (data) array.
    ubyte[] _data = null;

public:

    pure @safe nothrow this()
    {
    }

    /**
    Copy constructor.
    
    Params:
        copy = Input image, which is copied into this image structure.
        deepCopy = if false (default) the data array will be referenced 
        from copy, esle values will be copied to newly allocated array.
    */
    pure this(in Image copy, bool deepCopy = false)
    {
        if (copy is null || copy._data is null)
        {
            return;
        }
        _format = copy._format;
        _depth = copy._depth;
        _width = copy._width;
        _height = copy._height;
        if (deepCopy)
        {
            _data = new ubyte[copy._data.length];
            _data[] = copy._data[];
        }
        else
        {
            _data = cast(ubyte[])copy._data;
        }
    }

    unittest
    {
        Image image = new Image(null, false);
        assert(image.width == 0);
        assert(image.height == 0);
        assert(image.format == ImageFormat.IF_UNASSIGNED);
        assert(image.depth == BitDepth.BD_UNASSIGNED);
        assert(image.data == null);
        assert(image.empty == true);
    }

    /**
    Construct an image by given size, format and bit depth information.
    
    Params:
        width = width of a newly created image.
        height = height of a newly created image.
        format = format of a newly created image.
        depth = bit depth of a newly created image.
        data = potential data of an image, pre-allocated. If not a null, data array
        has to be of correct size = width*height*channels*depth, where channels are
        defined by the format, and depth is counded in bytes.
    */
    @safe pure nothrow this(size_t width, size_t height, ImageFormat format = ImageFormat.IF_RGB,
            BitDepth depth = BitDepth.BD_8, ubyte[] data = null)
    in
    {
        assert(width > 0 && height > 0);
        assert(depth != BitDepth.BD_UNASSIGNED && format != ImageFormat.IF_UNASSIGNED);
        if (data !is null)
        {
            assert(data.length == width * height * imageFormatChannelCount[cast(size_t)format] * (cast(size_t)depth / 8));
        }
    }
    do
    {
        _width = width;
        _height = height;
        _depth = depth;
        _format = format;
        _data = (data !is null) ? data : new ubyte[width * height * channels * (cast(size_t)depth / 8)];
    }

    unittest
    {
        Image image = new Image(1, 1, ImageFormat.IF_BGR, BitDepth.BD_8);
        assert(image.isOfType!ubyte);
    }

    unittest
    {
        Image image = new Image(1, 1, ImageFormat.IF_BGR, BitDepth.BD_16);
        assert(image.isOfType!ushort);
    }

    unittest
    {
        Image image = new Image(1, 1, ImageFormat.IF_BGR, BitDepth.BD_32);
        assert(image.isOfType!float);
    }

    unittest
    {
        import std.algorithm.comparison : equal;

        immutable width = 10;
        immutable height = 15;
        immutable format = ImageFormat.IF_BGR;
        immutable depth = BitDepth.BD_8;
        immutable channels = 3;
        Image image = new Image(width, height, format, depth);
        assert(image.width == width);
        assert(image.height == height);
        assert(image.format == format);
        assert(image.channels == channels);
        assert(image.depth == depth);
        assert(image.empty == false);
        assert(image.size == cast(size_t[3])[width, height, channels]);
    }

    unittest
    {
        immutable width = 10;
        immutable height = 15;
        immutable format = ImageFormat.IF_BGR;
        immutable depth = BitDepth.BD_8;
        immutable channels = 3;
        Image image = new Image(width, height, format, depth);
        Image copy = new Image(image, false);
        assert(copy.width == image.width);
        assert(copy.height == image.height);
        assert(copy.channels == image.channels);
        assert(copy.format == image.format);
        assert(copy.depth == image.depth);
        assert(copy.data.ptr == image.data.ptr);
    }

    unittest
    {
        immutable width = 10;
        immutable height = 15;
        immutable format = ImageFormat.IF_BGR;
        immutable depth = BitDepth.BD_8;
        immutable channels = 3;
        Image image = new Image(width, height, format, depth);
        Image copy = new Image(image, true);
        assert(copy.width == image.width);
        assert(copy.height == image.height);
        assert(copy.channels == image.channels);
        assert(copy.format == image.format);
        assert(copy.depth == image.depth);
        assert(copy.data.ptr != image.data.ptr);
    }

    /// Get format of an image.
    @property auto format() const @safe pure nothrow
    {
        return _format;
    }
    /// Get height of an image.
    @property auto width() const @safe pure nothrow
    {
        return _width;
    }
    /// Get height of an image.
    @property auto height() const @safe pure nothrow
    {
        return _height;
    }
    /// Get bit depth of the image.
    @property auto depth() const @safe pure nothrow
    {
        return _depth;
    }
    /// Check if image is empty (there's no data present).
    @property auto empty() const @safe pure nothrow
    {
        return _data is null;
    }
    /// Channel count of the image.
    @property auto channels() const @safe pure nothrow
    {
        return imageFormatChannelCount[cast(int)format];
    }

    /// Number of bytes contained in one pixel of the image.
    @property auto pixelSize() const @safe pure nothrow
    {
        return channels * (cast(size_t)_depth / 8);
    }
    /// Number of bytes contained in the image.
    @property auto byteSize() const @safe pure nothrow
    {
        return width * height * pixelSize;
    }
    /// Number of bytes contained in one row of the image.
    @property auto rowStride() const @safe pure nothrow
    {
        return pixelSize * _width;
    }

    /// Size of the image.
    /// Returns an array of 3 sizes: [width, height, channels]
    @property size_t[3] size() const @safe pure nothrow
    {
        return [width, height, channels];
    }

    /**
    Check if this images data corresponds to given value type.
    
    Given value type is checked against the image data bit depth. 
    Data of 8-bit image is considered to be typed as ubyte array,
    16-bit as ushort, and 32-bit as float array. Any other type as
    input returns false result.
    
    Params:
        T = (template parameter) value type which is tested against the bit depth of the image data.
    */
    @safe pure nothrow const bool isOfType(T)()
    {
        return (depth != BitDepth.BD_UNASSIGNED && ((depth == BitDepth.BD_8 && is(T == ubyte))
                || (depth == BitDepth.BD_16 && is(T == ushort)) || (depth == BitDepth.BD_32 && is(T == float))));
    }

    @safe pure nothrow unittest
    {
        Image image = new Image(1, 1, ImageFormat.IF_BGR, BitDepth.BD_8);
        assert(image.isOfType!ubyte);
        assert(!image.isOfType!ushort);
        assert(!image.isOfType!float);
        assert(!image.isOfType!real);
    }

    @safe pure nothrow unittest
    {
        Image image = new Image(1, 1, ImageFormat.IF_BGR, BitDepth.BD_16);
        assert(!image.isOfType!ubyte);
        assert(image.isOfType!ushort);
        assert(!image.isOfType!float);
        assert(!image.isOfType!real);
    }

    @safe pure nothrow unittest
    {
        Image image = new Image(1, 1, ImageFormat.IF_BGR, BitDepth.BD_32);
        assert(!image.isOfType!ubyte);
        assert(!image.isOfType!ushort);
        assert(image.isOfType!float);
        assert(!image.isOfType!real);
    }

    /**
    Convert image data type to given type.
    Creates new image with data typed as given value type. 
    If this image's data type is the same as given type, deep
    copy of this image is returned.
    Params:
        T = (template parameter) value type to which image's data is converted.
    
    Returns:
        Copy of this image with casted data to given type. If given type is same as
        current data of this image, deep copy is returned.
    */
    inout auto asType(T)()
    in
    {
        assert(_data);
        static assert(is(T == ubyte) || is(T == ushort) || is(T == float),
                "Given type is invalid - only ubyte (8) ushort(16) or float(32) are supported");
    }
    do
    {
        import std.range : lockstep;
        import std.algorithm.mutation : copy;
        import std.traits : isAssignable;

        auto depth = getDepthFromType!T;
        if (depth == _depth)
            return new Image(this, true);

        Image newim = new Image(width, height, format, depth);

        if (_depth == BitDepth.BD_8)
        {
            foreach (v1, ref v2; lockstep(data!ubyte, newim.data!T))
            {
                v2 = cast(T)v1;
            }
        }
        else if (_depth == BitDepth.BD_16)
        {
            foreach (v1, ref v2; lockstep(data!ushort, newim.data!T))
            {
                v2 = cast(T)v1;
            }
        }
        else if (_depth == BitDepth.BD_32)
        {
            foreach (v1, ref v2; lockstep(data!float, newim.data!T))
            {
                v2 = cast(T)v1;
            }
        }

        return newim;
    }

    /**
    Get data array from this image.
    Cast data array to corresponding dynamic array type,
    and return it.
    8-bit data is considered ubyte, 16-bit ushort, and 32-bit float.
    Params:
        T = (template parameter) value type (default ubyte) to which data array is casted to.
    */
    pure inout auto data(T = ubyte)()
    {
        import std.range : ElementType;

        if (_data is null)
        {
            return null;
        }
        static assert(is(T == ubyte) || is(T == ushort) || is(T == float),
                "Pixel data type not supported. Supported ones are: ubyte(8bit), ushort(16bit), float(32bit)");
        enforce(isOfType!T, "Invalid pixel data type cast.");
        static if (is(ElemetType!(typeof(_data)) == T))
            return _data;
        else
            return cast(T[])_data;
    }

    override string toString() const
    {
        import std.conv : to;

        return "Image [" ~ width.to!string ~ "x" ~ height.to!string ~ "]";
    }

    auto sliced(T = ubyte)() inout
    {
        return data!T.sliced(height, width, channels);
    }

    auto rcsliced(T = ubyte)() inout
    {
        import mir.ndslice.allocation : rcslice;
        import mir.rc;

        import core.lifetime: move;

        Slice!(RCI!T, 3LU, Contiguous) ret = uninitRCslice!T(height, width, channels);
        ret[] = data!T;
        return ret.move;
    }
}

version (unittest)
{
    import std.range : iota, lockstep;
    import std.array : array;
    import std.algorithm.iteration : map;

    immutable width = 3;
    immutable height = 3;
    immutable format = ImageFormat.IF_MONO;
    immutable depth = BitDepth.BD_8;
    auto data = (width * height).iota.map!(v => cast(ubyte)v).array;
}

unittest
{
    Image image = new Image;
    assert(image.format == ImageFormat.IF_UNASSIGNED);
    assert(image.depth == BitDepth.BD_UNASSIGNED);
    assert(image.width == 0);
    assert(image.height == 0);
    assert(image.data == null);
    assert(image.empty == true);
}

// Image.asType!
unittest
{
    Image image = new Image(width, height, format, depth, data);
    Image sameImage = image.asType!ubyte;
    assert(image.data == sameImage.data);
    assert(image.data.ptr != sameImage.data.ptr);
}

unittest
{
    Image image = new Image(width, height, format, depth, data);
    assert(image.data.ptr == data.ptr);
    assert(image.width == width);
    assert(image.height == height);
    Image oImage = image.asType!ushort;
    assert(oImage.width == image.width);
    assert(oImage.height == image.height);
    foreach (bv, fv; lockstep(image.data!ubyte, oImage.data!ushort))
    {
        assert(cast(ushort)bv == fv);
    }
}

unittest
{
    ubyte[] shdata = new ubyte[18];
    ubyte* ptr = cast(ubyte*)(data.map!(v => cast(ushort)v).array.ptr);
    shdata[] = ptr[0 .. width * height * 2][];
    Image image = new Image(width, height, format, BitDepth.BD_16, shdata);
    Image oImage = image.asType!float;
    assert(oImage.width == image.width);
    assert(oImage.height == image.height);
    foreach (bv, fv; lockstep(image.data!ushort, oImage.data!float))
    {
        assert(cast(float)bv == fv);
    }
}

unittest
{
    size_t floatsize = width * height * 4;
    ubyte[] fdata = new ubyte[floatsize];
    ubyte* ptr = cast(ubyte*)(data.map!(v => cast(float)v).array.ptr);
    fdata[] = ptr[0 .. floatsize][];
    Image image = new Image(width, height, format, BitDepth.BD_32, fdata);
    Image oImage = image.asType!ushort;
    assert(oImage.width == image.width);
    assert(oImage.height == image.height);
    foreach (bv, fv; lockstep(image.data!float, oImage.data!ushort))
    {
        assert(cast(ushort)bv == fv);
    }
}

/**
Convert a ndslice object to an Image, with defined image format.
*/
Image asImage(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice, ImageFormat format)
{
    static if(N == 1LU) static assert(0, "Packed slices are not supported.");

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

    BitDepth depth = getDepthFromType!T;
    enforce(depth != BitDepth.BD_UNASSIGNED, "Invalid type of slice for convertion to image: ", T.stringof);
    
    static if (N == 2LU)
    {
        ubyte* _iterator = cast(ubyte*)slice.slice._iterator;
        ubyte[] s_arr = _iterator[0 .. slice.elementCount * T.sizeof][];
        enforce(format == 1, "Invalid image format - has to be single channel");
        return new Image(slice.shape[1], slice.shape[0], format, depth, s_arr);
    }
    else static if (N == 3LU)
    {
        ubyte* _iterator = cast(ubyte*)slice.slice._iterator;
        ubyte[] s_arr = _iterator[0 .. slice.elementCount * T.sizeof][];
        auto ch = slice.shape[2];
        enforce(ch >= 1 && ch <= 4,
                "Invalid slice shape - third dimension should contain from 1(grayscale) to 4(rgba) values.");
        enforce(ch == imageFormatChannelCount[format], "Invalid image format - channel count missmatch");
        return new Image(slice.shape[1], slice.shape[0], format, depth, s_arr);
    }
    else
    {
        static assert(0, "Invalid slice dimension - should be 2(mono image) or 3(channel image) dimensional.");
    }
}

/**
Convert ndslice object into an image, with default format setup, regarding to slice dimension.
*/
Image asImage(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
{
    import mir.rc: RCI;
    import std.traits;
    
    static if (__traits(isSame, TemplateOf!(IteratorOf!(typeof(slice))), RCI)){
        alias ASeq = TemplateArgsOf!(IteratorOf!(typeof(slice)));
        alias T = ASeq[0];
    }else{
        alias PointerOf(T : T*) = T;
        alias P = IteratorOf!(typeof(slice));
        alias T = PointerOf!P;
    }

    ImageFormat format;
    static if (N == 2LU)
    {
        format = ImageFormat.IF_MONO;
    }
    else static if (N == 3LU)
    {
        switch (slice.length!2)
        {
        case 1:
            format = ImageFormat.IF_MONO;
            break;
        case 2:
            format = ImageFormat.IF_MONO_ALPHA;
            break;
        case 3:
            format = ImageFormat.IF_RGB;
            break;
        case 4:
            format = ImageFormat.IF_RGB_ALPHA;
            break;
        default:
            import std.conv : to;

            assert(0, "Invalid channel count: " ~ slice.length!2.to!string);
        }
    }
    else
    {
        static assert(0, "Invalid slice dimension - should be 2(mono image) or 3(channel image) dimensional.");
    }
    return slice.asImage(format);
}