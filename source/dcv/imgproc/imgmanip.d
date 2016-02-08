module dcv.imgproc.imgmanip;

/**
 * Image manipulation module. (resize, scale, transform, split, merge etc.)
 */
private import dcv.imgproc.interpolate;

private import std.exception : enforce;
private import std.experimental.ndslice;
private import std.traits;
private import std.algorithm : each;
private import std.range : iota;
private import std.parallelism : parallel;


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
		auto row = retval[i, 0..rows];
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
			auto row = ret_ch[i, 0..height];
			foreach(j; iota(width)) {
				row[j] = interp(sl_ch, cast(float)i/r_v, cast(float)j/r_h);
			}
		}
	}

	return retval;
}
