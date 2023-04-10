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

import mir.exception;

/*public*/ import mir.ndslice.slice;
import mir.ndslice.allocation;

import dplug.core.nogc;

/// Image (pixel) format.
enum ImageFormat
{
    IF_UNASSIGNED = 0, /// Not assigned format.
    IF_MONO = 1, /// Mono, single channel format.
    //IF_MONO_ALPHA, /// Mono with alpha channel.
    IF_RGB = 2, /// RGB format.
    IF_BGR = 3, /// BGR format.
    IF_YUV = 4, /// YUV (YCbCr) format.
    //IF_RGB_ALPHA, /// RGB format with alpha.
    //IF_BGR_ALPHA /// BGR format with alpha.
}


immutable size_t[] imageFormatChannelCount = [
    0, // unassigned
    1, // mono
    //2, // mono alpha
    3, // rgb
    3, // bgr
    3, // yuv
    //4, // rgba
    //4 // bgra
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
    bool borrower = false;

    @disable this();

    /**
    Copy constructor.
    
    Params:
        copy = Input image, which is copied into this image structure.
        deepCopy = if false (default) the data array will be referenced 
        from copy, esle values will be copied to newly allocated array.
    */
    @nogc nothrow this(Image copy, bool deepCopy = false)
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
            _data = mallocSlice!ubyte(copy._data.length);
            _data[] = copy._data[];
        }
        else
        {
            this.borrower = true;
            _data = copy._data;
        }
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
    @nogc nothrow this(size_t width, size_t height, ImageFormat format = ImageFormat.IF_RGB,
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
        
        if(data !is null){
            this.borrower = true;
            _data = data;
        }else{
            _data = mallocSlice!ubyte(width * height * channels * (cast(size_t)depth / 8));
        }
    }

    @nogc nothrow:
    ~this(){
        if(!borrower && (data !is null)){
             freeSlice(_data);
             _data = null;
        }
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
        import std.array : staticArray;
        return [width, height, channels].staticArray;
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
    const bool isOfType(T)()
    {
        return (depth != BitDepth.BD_UNASSIGNED && ((depth == BitDepth.BD_8 && is(T == ubyte))
                || (depth == BitDepth.BD_16 && is(T == ushort)) || (depth == BitDepth.BD_32 && is(T == float))));
    }

    /**
    Get data array from this image.
    Cast data array to corresponding dynamic array type,
    and return it.
    8-bit data is considered ubyte, 16-bit ushort, and 32-bit float.
    Params:
        T = (template parameter) value type (default ubyte) to which data array is casted to.
    */
    inout auto data()
    {
        return _data;
    }
    /*
    override string toString() const
    {
        import std.conv : to;

        return "Image [" ~ width.to!string ~ "x" ~ height.to!string ~ "]";
    }
    */

    auto sliced()
    {
        return data.sliced(height, width, channels);
    }

    auto rcsliced() inout
    {
        import mir.ndslice.allocation : rcslice;
        import mir.rc;

        import core.lifetime: move;

        Slice!(RCI!ubyte, 3LU, Contiguous) ret = uninitRCslice!ubyte(height, width, channels);
        ret[] = data;
        return ret.move;
    }
}

/**
Convert a ndslice object to an Image, with defined image format.
*/
@nogc nothrow
Image asImage(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice, ImageFormat format)
{
    static if(N == 1LU) static assert(0, "Packed slices are not supported.");

    import mir.rc: RCI;
    import std.traits;
    
    
    static if (__traits(isSame, TemplateOf!(IteratorOf!(typeof(slice))), RCI))
    { // is refcounted?
        alias ASeq = TemplateArgsOf!(IteratorOf!(typeof(slice)));
        alias T = ASeq[0];
        //ubyte* _iterator = cast(ubyte*)slice._iterator._array.ptr;
    }else{ // is regular Slice!(T*, N)
        alias PointerOf(T : T*) = T;
        alias P = IteratorOf!(typeof(slice));
        alias T = PointerOf!P;
        //ubyte* _iterator = cast(ubyte*)slice.ptr;
    }
    
    BitDepth depth = getDepthFromType!T;
    
    try enforce!("Invalid type of slice for convertion to image: " ~ T.stringof)(depth != BitDepth.BD_UNASSIGNED);
    catch(Exception e) assert(false, e.msg);
    
    
    static if (N == 2LU)
    {
        //ubyte[] s_arr = _iterator[0 .. slice.elementCount * T.sizeof];
        try enforce!("Invalid image format - has to be single channel" ~ T.stringof)(format == 1);
        catch(Exception e) assert(false, e.msg);
    }
    else static if (N == 3LU)
    {
        //ubyte[] s_arr = _iterator[0 .. slice.elementCount * T.sizeof];
        auto ch = slice.shape[2];
        try enforce!"Invalid slice shape - third dimension should contain from 1(grayscale) to 4(rgba) values."(ch >= 1 && ch <= 4);
        catch(Exception e) assert(false, e.msg);

        try enforce!"Invalid image format - channel count missmatch"(ch == imageFormatChannelCount[format]);
        catch(Exception e) assert(false, e.msg);
    }
    else
    {
        static assert(0, "Invalid slice dimension - should be 2(mono image) or 3(channel image) dimensional.");
    }

    auto ret = mallocNew!Image(slice.shape[1], slice.shape[0], format, depth);
    //static if(is(T==ubyte)){
    //    ret.data[] = slice[];
    //}else{
        foreach (i; 0..slice.elementCount) {
            T ta = slice.accessFlat(i);
            ret.data[i..i+T.sizeof] = (cast(ubyte*)&slice.accessFlat(i))[0..T.sizeof];
        }
    //}
    
    return ret;
}

/**
Convert ndslice object into an image, with default format setup, regarding to slice dimension.
*/
@nogc nothrow
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
        /+case 2:
            format = ImageFormat.IF_MONO_ALPHA;
            break;+/
        case 3:
            format = ImageFormat.IF_RGB;
            break;
        /+case 4:
            format = ImageFormat.IF_RGB_ALPHA;
            break;+/
        default:
            import std.conv : to;

            debug assert(0, "Invalid channel count: " ~ slice.length!2.to!string);
        }
    }
    else
    {
        static assert(0, "Invalid slice dimension - should be 2(mono image) or 3(channel image) dimensional.");
    }
    return slice.asImage(format);
}