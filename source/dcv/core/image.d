module dcv.core.image;

private import std.exception : enforce;
public import mir.ndslice;

/// Image (pixel) format.
enum ImageFormat : size_t {
	IF_UNASSIGNED = 0,
	IF_MONO = 1,
	IF_MONO_ALPHA = 2,
	IF_RGB = 3,
	IF_RGB_ALPHA = 4
}

/// Bit depth of a pixel in an image.
enum BitDepth : size_t {
	BD_UNASSIGNED = 0,
	BD_8 = 8,
	BD_16 = 16,
	BD_32 = 32
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

	auto getDepthFromType(T)() const @safe {
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

public:

	this() {
	}

	this(in Image im) {
		if (im._data is null)
			return;
		_format = im._format;
		_depth = im._depth;
		_width = im._width;
		_height = im._height;
		_data = cast(ubyte[])im._data;
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
	@property depth() const @safe pure {
		return _depth;
	}
	/// Channel count of the image.
	@property channels() const @safe pure {
		switch (_format) {
			case ImageFormat.IF_MONO:
				return 0;
			case ImageFormat.IF_MONO_ALPHA:
				return 2;
			case ImageFormat.IF_RGB:
				return 3;
			case ImageFormat.IF_RGB_ALPHA:
				return 4;
			default:
				return -1;
		}
	}

	/// Number of bytes contained in one pixel of the image.
	@property pixelSize() const @safe pure {
		return channels * cast(size_t) _depth;
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

		auto depth = getDepthFromType!T;
		assert(depth != BitDepth.BD_UNASSIGNED);

		if (depth == _depth)
			return new Image(this);

		Image newim = new Image(width, height, format, depth);
		switch (_depth) {
			case BitDepth.BD_8:
				foreach(ref v, o; lockstep(cast(T[])newim._data, _data)) { v = cast(T)o; }
				break;
			case BitDepth.BD_16:
				foreach(ref v, o; lockstep(cast(T[])newim._data, cast(ushort[])_data)) { v = cast(T)o; }
				break;
			case BitDepth.BD_32:
				foreach(ref v, o; lockstep(cast(T[])newim._data, cast(float[])_data)) { v = cast(T)o; }
				break;
			default:
				assert(0);
		}

		return newim;
	}

	auto data(T)() {
		static assert(is(T == ubyte) ||
			is(T == ushort) ||
			is(T == float), "Pixel data type not supported. Supported ones are: ubyte(8bit), ushort(16bit), float(32bit)");
		enforce(isOfType!T, "Invalid pixel data type cast.");
		return cast(T[])_data;
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

			bool empty() const { return iter == end; }
			void popFront() { iter+=ch; }
			T [] front() { return data[iter..iter+ch]; }
			const(T[]) front() const { return data[iter..iter+ch]; }
		}

		PixelRange r;
		r.data = cast(T[])_data;
		r.end = rowStride*height;

		return r;
	}

	override string toString() const {
		import std.conv : to;
		return "Image [" ~ width.to!string ~ "x" ~ height.to!string ~ "]"; 
	}

	auto sliced(T)() {
		return data!T.sliced(height, width, channels);
	}
}
