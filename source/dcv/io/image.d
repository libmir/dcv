module dcv.io.image;

/**
 * Module for image I/O.
 * 
 * v0.1 norm:
 * Implemented and tested Image class.
 */

private import std.exception : enforce;
private import std.range : array;
private import std.algorithm : reduce, map;
private import std.string : toLower;
private import std.path : extension;

public import std.experimental.ndslice;

private import imageformats;


/// Image reading parameter package type.
struct ReadParams {
	ImageFormat format = ImageFormat.IF_UNASSIGNED;
	BitDepth depth = BitDepth.BD_UNASSIGNED;
}

/// Image (pixel) format.
enum ImageFormat {
	IF_UNASSIGNED = 0,
	IF_MONO,
	IF_MONO_ALPHA,
	IF_RGB,
	IF_BGR,
	IF_YUV,
	IF_RGB_ALPHA,
	IF_BGR_ALPHA
}

private immutable ulong [] imageFormatChannelCount = [
	0, // unassigned
	1, // mono
	2, // mono alpha
	3, // rgb
	3, // bgr
	3, // yuv
	4, // rgba
	4  // bgra
];

/// Bit depth of a pixel in an image.
enum BitDepth : size_t {
	BD_UNASSIGNED = 0,
	BD_8 = 8,
	BD_16 = 16,
	BD_32 = 32
}

private	auto getDepthFromType(T)() @safe {
	static if (is (T==ubyte)) {
		return BitDepth.BD_8;
	} else static if (is (T == ushort)) {
		return BitDepth.BD_16;
	} else static if (is(T == float)) {
		return BitDepth.BD_32;
	} else {
		return BitDepth.BD_UNASSIGNED;
	}
}

/**
 * Image abstraction type, used primariliy as an I/O unit.
 */
class Image {
private:
	/// Format of an image.
	ImageFormat _format = ImageFormat.IF_UNASSIGNED;
	// Bit depth of a pixel: (8 - uchar, 16 - ushort, 32 - float)
	BitDepth _depth = BitDepth.BD_UNASSIGNED;
	/// Width of the image.
	size_t _width = 0;
	/// Height of the image.
	size_t _height = 0;
	/// Image pixel (data) array.
	ubyte[] _data = [];

	
public:

	this() {
	}

	this(in Image im, bool deepCopy = false) {
		if (im._data is null)
			return;
		_format = im._format;
		_depth = im._depth;
		_width = im._width;
		_height = im._height;
		if (deepCopy) {
			_data = new ubyte[im._data.length];
			_data[] = im._data[];
		} else {
			_data = cast(ubyte[])im._data;
		}
	}

	this(size_t width, size_t height, ImageFormat format = ImageFormat.IF_RGB,
		BitDepth depth = BitDepth.BD_8, ubyte[] data = [])
	in {
		assert(width > 0 && height > 0);
		assert(depth != BitDepth.BD_UNASSIGNED && format != ImageFormat.IF_UNASSIGNED);
	}
	body {
		_width = width;
		_height = height;
		_depth = depth;
		_format = format;
		_data = (data.length) ? data : new ubyte[width * height * cast(
				size_t) format * (cast(size_t) depth / 8)];
	}

	/// Get format of an image.
	@property format() const @safe pure {
		return _format;
	}
	/// Get height of an image.
	@property width() const @safe pure {
		return _width;
	}
	/// Get height of an image.
	@property height() const @safe pure {
		return _height;
	}
	/// Get bit depth of the image.
	@property depth() const @safe pure {
		return _depth;
	}
	/// Check if image is empty (there's no data present).
	@property empty() const @safe pure {
		return _data is null;
	}
	/// Channel count of the image.
	@property channels() const @safe pure {
		return imageFormatChannelCount[cast(int)format];
	}

	/// Number of bytes contained in one pixel of the image.
	@property pixelSize() const @safe pure {
		return channels * cast(size_t) _depth;
	}
	/// Number of bytes contained in the image.
	@property byteSize() const @safe pure {
		return width*height*pixelSize;
	}
	/// Number of bytes contained in one row of the image.
	@property rowStride() const @safe pure {
		return pixelSize * _width;
	}

	bool isOfType(T)() const @safe {
		return (depth != BitDepth.BD_UNASSIGNED && ((depth == BitDepth.BD_8 && is(T == ubyte)) ||
				(depth == BitDepth.BD_16 && is(T == ushort)) ||
				(depth == BitDepth.BD_32 && is(T == float))));
	}

	auto asType(T)() const 
	in {
		assert(_data);
	} body {
		import std.range : lockstep;
		import std.algorithm : copy;

		auto depth = getDepthFromType!T;
		assert(depth != BitDepth.BD_UNASSIGNED);

		if (depth == _depth)
			return new Image(this, true);

		Image newim = new Image(width, height, format, depth);
		switch (_depth) {
			case BitDepth.BD_8:
				data!ubyte.copy(newim.data!T); break;
			case BitDepth.BD_16:
				data!ushort.copy(newim.data!T); break;
			case BitDepth.BD_32:
				data!float.copy(newim.data!T); break;
			default:
				assert(0);
		}

		return newim;
	}

	auto data(T = ubyte)() inout {
		static assert(is(T == ubyte) ||
			is(T == ushort) ||
			is(T == float), "Pixel data type not supported. Supported ones are: ubyte(8bit), ushort(16bit), float(32bit)");
		enforce(isOfType!T, "Invalid pixel data type cast.");
		static if (is (typeof(_data) == T))
			return _data;
		else
			return cast(T[])_data;
	}

	/// Get row at given index.
	auto row(V = ubyte)(size_t i) inout
	in {
		assert(i < height);
	} body {
		auto trowstride = width*channels;
		return data!V[trowstride*i..trowstride*(i+1)];
	}

	/// Get col at given index.
	auto col(V = ubyte)(size_t i) inout
	in {
		assert(i < width);
	} body {
		import std.range : stride;
		auto start = i*channels;
		return data!V[start..width*height*channels].stride(width*channels);
	}

	auto byElement(T)() inout {
		static assert(is(T == ubyte) ||
			is(T == ushort) ||
			is(T == float), "Pixel data type not supported. Supported ones are: ubyte(8bit), ushort(16bit), float(32bit)");

		struct ElementRange {
			T [] data;
			size_t iter = 0;
			size_t end = 0;

			bool empty() const { return iter == end; }
			void popFront() { iter++; }
			ref T front() { return data[iter]; }
			T front() const { return data[iter]; }
		}

		ElementRange r;
		r.data = cast(T[])_data;
		r.end = rowStride*height;

		return r;
	}

	auto byPixel(T, size_t ch)() inout {
		static assert(is(T == ubyte) ||
			is(T == ushort) ||
			is(T == float), "Pixel data type not supported. Supported ones are: ubyte(8bit), ushort(16bit), float(32bit)");
		static assert(ch >= 1 && ch <= 4, "Channel count is invalid. Should be between 1(mono) and 4(rgba)");

		struct PixelRange {
			T [] data;
			size_t iter = 0;
			size_t end = 0;

			bool empty() const { return (iter + ch) >= end; }
			void popFront() { iter+=ch; }
			T [] front() { return data[iter..iter+ch]; }
			const(T[]) front() const { return data[iter..iter+ch]; }
		}

		PixelRange r;
		r.data = cast(T[])_data;
		r.end = width*height*channels;

		return r;
	}

	override string toString() const {
		import std.conv : to;
		return "Image [" ~ width.to!string ~ "x" ~ height.to!string ~ "]"; 
	}

	auto sliced(T = ubyte)() {
		return data!T.sliced(height, width, channels);
	}
}

Image asImage(size_t N, T)(Slice!(N, T*) slice, ImageFormat format) {
	import std.conv : to;

	BitDepth depth = getDepthFromType!T;
	enforce (depth != BitDepth.BD_UNASSIGNED, "Invalid type of slice for convertion to image: ", T.stringof);
	static if (N == 2) {
		ubyte* ptr = cast(ubyte*)&slice[0, 0];
		ubyte [] s_arr = ptr[0 .. slice.shape.reduce!"a*b"*T.sizeof][];
		enforce (format.to!int == 1, "Invalid image format - has to be single channel");
		return new Image(slice.shape[1], slice.shape[0], format, depth, s_arr);
	} else static if (N == 3) {
		ubyte* ptr = cast(ubyte*)&slice[0, 0, 0];
		ubyte [] s_arr = ptr[0 .. slice.shape.reduce!"a*b"*T.sizeof][];
		auto ch = slice.shape[2];
		enforce(ch >= 1 && ch <= 4, 
			"Invalid slice shape - third dimension should contain from 1(grayscale) to 4(rgba) values.");
		enforce (ch == imageFormatChannelCount[format], "Invalid image format - channel count missmatch");
		return new Image(slice.shape[1], slice.shape[0], format, depth, s_arr);
	} else {
		static assert(0, "Invalid slice dimension - should be 2(mono image) or 3(channel image) dimensional.");
	}
}

unittest {
	import std.algorithm : each;

	ubyte [] data = new ubyte[3*3*3];

	data[0] = 1;
	data[1] = 2;
	data[2] = 3;

	auto im = new Image(3, 3, ImageFormat.IF_RGB, BitDepth.BD_8, data);
	auto imslice = im.sliced!ubyte;

	imslice
		.byElement
			.each!((ref v) => v *= 2);

	assert(data[0] == 2);
	assert(data[1] == 4);
	assert(data[2] == 6);
}


/** 
 * Read image from the file system.
 * 
 * params:
 * path = File system path to the image.
 * params = Reading parameters - desired format and depth of the image that's read. 
 * Default parameters include no convertion, but loading image orignal data depth and 
 * color format. To load original depth or format, set to _UNASSIGNED (ImageFormat.IF_UNASSIGNED,
 * BitDepth.BD_UNASSIGNED).
 * 
 * return:
 * Image read from the filesystem.
 * 
 * throws:
 * Exception and ImageIOException from imageformats library.
 */
Image imread(in string path,
	ReadParams params = ReadParams(ImageFormat.IF_UNASSIGNED, BitDepth.BD_UNASSIGNED)) {
	return imreadImpl_imageformats(path, params);
}

/**
 * Write image to the given path on the filesystem.
 * 
 * params:
 * path = Path where the image will be written.
 * width = Width of the image.
 * height = Height of the image.
 * format = Format of the image.
 * depth = Bit depth of the image.
 * data = Image data in unsigned bytes.
 * 
 * return:
 * Status of the writing as bool.
 */
bool imwrite(in string path, ulong width, ulong height, ImageFormat format, BitDepth depth, ubyte [] data) {
	assert(depth != BitDepth.BD_UNASSIGNED);
	assert(width > 0 && height > 0);
	if (depth == BitDepth.BD_8) {
		write_image(path, cast(long)width, cast(long)height, data, cast(long)format);
	} else if (depth == BitDepth.BD_16) {
		enforce(path.extension.toLower == ".png", "Writting 16-bit image has to be in PNG format.");
		write_image(path, cast(long)width, cast(long)height, data, cast(long)format);
	} else {
		throw new Exception("Writting image format not supported.");
	}
	return true;
}

/**
 * Convenience wrapper for imwrite with Image.
 * 
 * params:
 * image = Image to be written;
 * path = Path where the image will be written.
 * 
 * return:
 * Status of the writing as bool.
 */
bool imwrite(in Image image, in string path) {
	return imwrite(path, image.width, image.height, image.format, image.depth, image.data!ubyte);
}

/**
 * Convenience wrapper for imwrite with Slice type.
 * 
 * Assumes 2D slice as grayscale image, and 3D is interpreted
 * by number of elements in the 3rd dimension (1 - mono, 2 - mono with 
 * alpha, 3 - rgb, 4 - rgba).
 * 
 * params:
 * slice = Slice of the image data;
 * path = Path where the image will be written.
 * 
 * return:
 * Status of the writing as bool.
 */
bool imwrite(size_t dims, T)(Slice!(dims, T*) slice, in string path) {
	static assert(dims >= 2);

	static if (dims == 2) {
		ImageFormat format = ImageFormat.IF_MONO;
	} else {
		ImageFormat format = cast(ImageFormat)slice.shape[2];
	}
	auto sdata = slice.reshape(slice.shape[].reduce!"a*b").array;

	static if (is(T == ubyte)) {
		return imwrite(path, slice.shape[1], slice.shape[0], format, BitDepth.BD_8, sdata);
	} else static if (is(T == ushort)) {
		enforce(path.extension.toLower == ".png", "Writing 16-bit image has to be in PNG format.");
		return imwrite(path, slice.shape[1], slice.shape[0], format, BitDepth.BD_16, cast(ubyte[])sdata);
	} else static if (is (T == float)) {
		throw new Exception("Writting image format not supported.");
	} else {
		throw new Exception("Writting image format not supported.");
	}
}

private:

Image imreadImpl_imageformats(in string path, ReadParams params) {
	enforce(params.depth != BitDepth.BD_32,
		"Currenly reading of 32-bit image data is not supported");

	Image im = null;
	auto ch = imreadImpl_imageformats_adoptFormat(params.format);

	if (params.depth == BitDepth.BD_UNASSIGNED || params.depth == BitDepth.BD_8) {
		IFImage ifim = read_image(path, ch);
		if (params.format == ImageFormat.IF_UNASSIGNED)
			params.format = ImageFormat.IF_RGB;
		im = new Image(cast(ulong) ifim.w, cast(ulong) ifim.h, params.format,
			BitDepth.BD_8, ifim.pixels);
	} else if (params.depth == BitDepth.BD_16) {
		enforce (path.extension.toLower == ".png", "Reading 16-bit image has to be in PNG format.");
		IFImage16 ifim = read_png16(path, ch);
		im = new Image(cast(ulong)ifim.w, cast(ulong)ifim.h, params.format, BitDepth.BD_16, cast(ubyte[])ifim.pixels);
	} else {
		throw new Exception("Reading image depth not supported.");
	}

	return im;
}

int imreadImpl_imageformats_adoptFormat(ImageFormat format) {
	typeof(return) ch = 0;
	switch(format) {
		case ImageFormat.IF_RGB:
			ch = ColFmt.RGB;
			break;
		case ImageFormat.IF_RGB_ALPHA:
			ch = ColFmt.RGBA;
			break;
		case ImageFormat.IF_MONO:
			ch = ColFmt.Y;
			break;
		case ImageFormat.IF_MONO_ALPHA:
			ch = ColFmt.YA;
			break;
		default:
			ch = ColFmt.RGB;
	}
	return ch;
}
