module dcv.imgproc.imgmanip;

/**
 * Image manipulation module.
 * 
 * v0.1 norm:
 * resize (done, not tested)
 * scale (done, not tested)
 * transform!affine,perspective
 * remap (pixel-wise displacement)
 * split (split multichannel image to single channels)
 * merge (merge multiple channels to one image)
 * channelChain (chain mono images into multi-channel)
 */
public import dcv.imgproc.interpolate;

private import std.exception : enforce;
private import std.experimental.ndslice;
private import std.traits;
private import std.algorithm : each;
private import std.range : iota;
private import std.parallelism : parallel;


/**
 * Resize array using custom interpolation function.
 * 
 * Primarilly implemented as image resize. 
 * 1D, 2D and 3D arrays are supported, where 3D array is
 * treated as channeled image - each channel is interpolated 
 * as isolated 2D array (matrix).
 * 
 * Interpolation function is given as a template parameter. 
 * Default interpolation function is linear. Custom interpolation
 * function can be implemented in the 3rd party code, by following
 * interpolation function rules in dcv.imgproc.interpolation.
 * 
 * params:
 * slice = Slice to an input array.
 * newsize = tuple that defines new shape. New dimension has to be
 * the same as input slice in the 1D and 2D resize, where in the 
 * 3D resize newsize has to be 2D.
 */
Slice!(N, V*) resize(alias interp = linear, V, size_t N, Size...)
(Slice!(N, V*) slice, Size newsize) 
if (allSameType!Size && allSatisfy!(isIntegral, Size))
{
	static if (N == 1) {
		static assert(newsize.length == 1, 
			"Invalid new-size setup - dimension does not match with input slice.");
		return resizeImpl_1!interp(slice, newsize[0]);
	} else static if (N == 2) {
		static assert(newsize.length == 2, 
			"Invalid new-size setup - dimension does not match with input slice.");
		return resizeImpl_2!interp(slice, newsize[0], newsize[1]);
	} else static if (N == 3) {
		static assert(newsize.length == 2, 
			"Invalid new-size setup - 3D resize is performed as 2D."); // TODO: find better way to say this...
		return resizeImpl_3!interp(slice, newsize[0], newsize[1]);
	} else {
		import std.conv : to;
		static assert(0, "Resize is not supported for slice with " ~ N.to!string ~ " dimensions.");
	}
}

/**
 * Scale array size using custom interpolation function.
 * 
 * Implemented as convenience function which calls resize 
 * using scaled shape of the input slice as:
 * 
 * ```
 * scaled = resize(input, input.shape*scale)
 * ```
 */
Slice!(N, V*) scale(alias interp = linear, V, size_t N, Scale...)
(Slice!(N, V*) slice, Scale scale) 
if (allSameType!Scale && allSatisfy!(isFloatingPoint, Scale))
{
	foreach(v;scale)
		assert(v > 0., "Invalid scale values (v > 0.0)");

	static if (N == 1) {
		static assert(scale.length == 1, 
			"Invalid scale setup - dimension does not match with input slice.");
		auto newsize = slice.length*scale[0];
		enforce (newsize > 0, "Scaling value invalid - after scaling array size is zero.");
		return resizeImpl_1!interp(slice, newsize);
	} else static if (N == 2) {
		static assert(scale.length == 2, 
			"Invalid scale setup - dimension does not match with input slice.");
		auto newsize = [slice.length!0*scale[0], slice.length!1*scale[1]];
		enforce (newsize[0] > 0 && newsize[1] > 0, "Scaling value invalid - after scaling array size is zero.");
		return resizeImpl_2!interp(slice, newsize[0], newsize[1]);
	} else static if (N == 3) {
		static assert(scale.length == 2, 
			"Invalid scale setup - 3D scale is performed as 2D."); // TODO: find better way to say this...
		auto newsize = [slice.length!0*scale[0], slice.length!1*scale[1]];
		enforce (newsize[0] > 0 && newsize[1] > 0, "Scaling value invalid - after scaling array size is zero.");
		return resizeImpl_3!interp(slice, newsize[0], newsize[1]);
	} else {
		import std.conv : to;
		static assert(0, "Resize is not supported for slice with " ~ N.to!string ~ " dimensions.");
	}
}

unittest {
	// TODO: design the test
}


private:


// 1d resize implementation
Slice!(1, V*) resizeImpl_1(alias interp, V)(Slice!(1, V*) slice, ulong newsize) {
	static assert(__traits(compiles, interp(slice, newsize)), 
		"Interpolation function is not supported for given slice.");

	enforce(!slice.empty && newsize > 0);

	auto retval = new V[newsize];
	auto resizeRatio = cast(float)(newsize - 1) / cast(float)(slice.length - 1);

	foreach(i; iota(newsize).parallel) {
		retval[i] = interp(slice, cast(float)i/resizeRatio);
	}

	return retval.sliced(newsize);
}

// 1d resize implementation
Slice!(2, V*) resizeImpl_2(alias interp, V)(Slice!(2, V*) slice, ulong width, ulong height) {
		static assert(__traits(compiles, interp(slice, width, height)), 
		"Interpolation function is not supported for given slice.");

	enforce(!slice.empty && width > 0 && height > 0);

	auto retval = new V[width*height].sliced(height, width);

	auto rows = slice.length!0;
	auto cols = slice.length!1;

	auto r_v = cast(float)(height - 1) / cast(float)(rows - 1); // horizontaresize ratio
	auto r_h = cast(float)(width - 1) / cast(float)(cols - 1);

	foreach(i; iota(height).parallel) {
		auto row = retval[i, 0..width];
		foreach(j; iota(width)) {
			row[j] = interp(slice, cast(float)i/r_v, cast(float)j/r_h);
		}
	}

	return retval;
}

// 1d resize implementation
Slice!(3, V*) resizeImpl_3(alias interp, V)(Slice!(3, V*) slice, ulong width, ulong height) {

	/*
	static assert(__traits(compiles, interp(slice, width, height)), 
		"Interpolation function is not supported for given slice.");
	*/

	enforce(!slice.empty && width > 0 && height > 0);

	auto rows = slice.length!0;
	auto cols = slice.length!1;
	auto channels = slice.length!2;

	auto retval = new V[width*height*channels].sliced(height, width, channels);

	auto r_v = cast(float)(height - 1) / cast(float)(rows - 1); // horizontaresize ratio
	auto r_h = cast(float)(width - 1) / cast(float)(cols - 1);

	foreach(c; iota(channels)) {
		auto sl_ch = slice[0..rows, 0..cols, c];
		auto ret_ch = retval[0..height, 0..width, c];
		foreach(i; iota(height).parallel) {
			auto row = ret_ch[i, 0..width];
			foreach(j; iota(width)) {
				row[j] = interp(sl_ch, cast(float)i/r_v, cast(float)j/r_h);
			}
		}
	}

	return retval;
}
