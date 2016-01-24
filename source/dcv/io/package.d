module dcv.io;

private import std.exception : enforce;

public import dcv.core.image, mir.ndslice;

private import imageformats;

/// Image reading parameter package type.
struct ReadParams {
    ImageFormat format = ImageFormat.IF_UNASSIGNED;
    BitDepth depth = BitDepth.BD_UNASSIGNED;
}

/// Read image from the file system.
Image imread(in string path,
    ReadParams params = ReadParams(ImageFormat.IF_UNASSIGNED, BitDepth.BD_UNASSIGNED)) {
    return imreadImpl_imageformats(path, params);
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
		//IFImage16 ifim = read_png16(
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

void imreadImpl_adoptType(Image image, ReadParams params) {

}
