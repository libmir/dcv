module dcv.io;

private import std.exception : enforce;
private import std.range : array;
private import std.algorithm : reduce, map;
private import std.string : toLower;
private import std.path : extension;

public import mir.ndslice;
public import dcv.core.image;

private import imageformats;

/// Image reading parameter package type.
struct ReadParams {
    ImageFormat format = ImageFormat.IF_UNASSIGNED;
    BitDepth depth = BitDepth.BD_UNASSIGNED;
}

/** 
 * Read image from the file system.
 * 
 * 
*/
Image imread(in string path,
    ReadParams params = ReadParams(ImageFormat.IF_UNASSIGNED, BitDepth.BD_UNASSIGNED)) {
    return imreadImpl_imageformats(path, params);
}

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

bool imwrite(in string path, in Image image) {
	return imwrite(path, image.width, image.height, image.format, image.depth, image.data!ubyte);
}

bool imwrite(size_t dims, T)(in string path, Slice!(dims, T*) slice) {
	static assert(dims >= 2);

	ImageFormat format = dims == 2 ? ImageFormat.IF_MONO : cast(ImageFormat)slice.shape[2];
	auto sdata = slice.reshape(slice.shape[].reduce!"a*b").array;

	static if (is(T == ubyte)) {
		return imwrite(path, slice.shape[0], slice.shape[1], format, BitDepth.BD_8, sdata);
	} else static if (is(T == ushort)) {
		enforce(path.extension.toLower == ".png", "Writing 16-bit image has to be in PNG format.");
		return imwrite(path, slice.shape[0], slice.shape[1], format, BitDepth.BD_16, cast(ubyte[])sdata);
	} else static if (is (T == float)) {
		throw new Exception("Writting image format not supported.");
	} else {
		throw new Exception("Writting image format not supported.");
	}
}

private:
// impl

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
    if (format == ImageFormat.IF_RGB)
        ch = ColFmt.RGB;
    else if (format == ImageFormat.IF_RGB_ALPHA)
        ch = ColFmt.RGBA;
    else if (format == ImageFormat.IF_MONO)
        ch = ColFmt.Y;
    else if (format == ImageFormat.IF_MONO_ALPHA)
        ch = ColFmt.YA;
    return ch;
}
