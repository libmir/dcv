module dcv.io.image;

/**
 * Module for image I/O.
 * 
 * v0.1 norm:
 * Implemented and tested Image class.
 */

import std.exception : enforce;
import std.range : array;
import std.algorithm : reduce;
import std.string : toLower;
import std.path : extension;

import imageformats;

public import dcv.core.image;


/// Image reading parameter package type.
struct ReadParams {
	ImageFormat format = ImageFormat.IF_UNASSIGNED;
	BitDepth depth = BitDepth.BD_UNASSIGNED;
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
