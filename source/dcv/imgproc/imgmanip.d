module dcv.imgproc.imgmanip;

/**
 * Image manipulation module.
 * 
 * v0.1 norm:
 * resize (done, not tested)
 * scale (done, not tested)
 * transform!affine,perspective
 * warp (pixel-wise displacement)
 * remap (pixel-wise image remapping)
 * split (split multichannel image to single channels)
 * merge (merge multiple channels to one image)
 * channelChain (chain mono images into multi-channel)
 */
public import dcv.imgproc.interpolate;

import std.exception : enforce;
import std.experimental.ndslice;
import std.traits : allSatisfy, isFloatingPoint, 
	allSameType, isNumeric, isIntegral;
import std.algorithm : each;
import std.range : iota;
import std.parallelism : parallel;
import std.range : isArray, ElementType;

import dcv.core.utils;

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
 * 
 * TODO: consider size input as array, and add prealloc
 */
Slice!(N, V*) resize(alias interp = linear, V, size_t N, Size...)
(Slice!(N, V*) slice, Size newsize) 
if (allSameType!Size && allSatisfy!(isIntegral, Size) && isInterpolationFunc!interp)
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
if (allSameType!Scale && allSatisfy!(isFloatingPoint, Scale) &&	isInterpolationFunc!interp)
{
	foreach(v;scale)
		assert(v > 0., "Invalid scale values (v > 0.0)");

	static if (N == 1) {
		static assert(scale.length == 1, 
			"Invalid scale setup - dimension does not match with input slice.");
		auto newsize = slice.length*scale[0];
		enforce (newsize > 0, "Scaling value invalid - after scaling array size is zero.");
		return resizeImpl_1!interp(slice, cast(ulong)newsize);
	} else static if (N == 2) {
		static assert(scale.length == 2, 
			"Invalid scale setup - dimension does not match with input slice.");
		auto newsize = [slice.length!0*scale[0], slice.length!1*scale[1]];
		enforce (newsize[0] > 0 && newsize[1] > 0, "Scaling value invalid - after scaling array size is zero.");
		return resizeImpl_2!interp(slice, cast(ulong)newsize[0], cast(ulong)newsize[1]);
	} else static if (N == 3) {
		static assert(scale.length == 2, 
			"Invalid scale setup - 3D scale is performed as 2D."); // TODO: find better way to say this...
		auto newsize = [slice.length!0*scale[0], slice.length!1*scale[1]];
		enforce (newsize[0] > 0 && newsize[1] > 0, "Scaling value invalid - after scaling array size is zero.");
		return resizeImpl_3!interp(slice, cast(ulong)newsize[0], cast(ulong)newsize[1]);
	} else {
		import std.conv : to;
		static assert(0, "Resize is not supported for slice with " ~ N.to!string ~ " dimensions.");
	}
}

unittest {
	// TODO: design the test
}

/**
 * Pixel-wise warping of the image.
 */
Slice!(N, T*) warp(alias interp = linear, size_t N, T, V)
	(Slice!(N, T*) image, Slice!(3, V*) map, Slice!(N, T*) prealloc = emptySlice!(N, T)) pure {
	return pixelWiseDisplacementImpl!(linear, warpImpl, N, T, V)(image, map, prealloc);
}

/**
 * Pixel-wise remapping of the image.
 */
Slice!(N, T*) remap(alias interp = linear, size_t N, T, V)
	(Slice!(N, T*) image, Slice!(3, V*) map, Slice!(N, T*) prealloc = emptySlice!(N, T)) pure {
	return pixelWiseDisplacementImpl!(linear, remapImpl, N, T, V)(image, map, prealloc);
}

private {

	Slice!(N, T*) pixelWiseDisplacementImpl(alias interp, alias dispFunc, size_t N, T, V)
		(Slice!(N, T*) image, Slice!(3, V*) map, Slice!(N, T*) prealloc = emptySlice!(N, T)) pure {
		static assert (isNumeric!T);
		import std.algorithm.comparison : equal;
		import std.algorithm.iteration : reduce;
		import std.array : array, uninitializedArray;
	 
		typeof(image) warped;
		if (prealloc.empty || prealloc.shape.array.equal(image.shape.array)) {
			warped = uninitializedArray!(T[])(image.shape.reduce!"a*b").sliced(image.shape);
		} else {
			enforce(&(warped.byElement.front) != &(image.byElement.front), 
				"Invalid preallocation slice - it must not share data with input image slice");
			warped = prealloc;
		}

		static if (N == 2) {
			dispFunc!(interp, T, V)(image, map, warped);
		} else static if (N == 3) {
			auto imp = image.pack!1;
			foreach(i; 0..image.length!2) {
				dispFunc!(interp, T, V)(image[0..$, 0..$, i], map, warped[0..$, 0..$, i]);
			}
		} else {
			import std.conv : to;
			static assert(0, "Invalid slice dimension - " ~ N.to!string);
		}
		return warped;
	}

	Slice!(2, T*) warpImpl(alias interp, T, V)
		(Slice!(2, T*) image, Slice!(3, V*) map, Slice!(2, T*) warped) pure {
		auto const rows = image.length!0;
		auto const cols = image.length!1;
		const auto rf = cast(float)rows;
		const auto cf = cast(float)cols;
		foreach(i; 0..rows) {
			foreach(j; 0..cols) {
				auto x = cast(float)i + map[i, j, 1];
				auto y = cast(float)j + map[i, j, 0];
				if (x >= 0.0f && x < rf && 
					y >= 0.0f && y < cf) {
					warped[i, j] = interp(image, x, y); 
				}
			}
		}
		return warped;
	}

	Slice!(2, T*) remapImpl(alias interp, T, V)
		(Slice!(2, T*) image, Slice!(3, V*) map, Slice!(2, T*) remapped) pure {
		auto const rows = image.length!0;
		auto const cols = image.length!1;
		const auto rf = cast(float)rows;
		const auto cf = cast(float)cols;
		foreach(i; 0..rows) {
			foreach(j; 0..cols) {
				auto x = map[i, j, 1];
				auto y = map[i, j, 0];
				if (x >= 0.0f && x < rf && 
					y >= 0.0f && y < cf) {
					remapped[i, j] = interp(image, x, y); 
				}
			}
		}
		return remapped;
	}
}

private enum TransformType : size_t {
	AFFINE_TRANSFORM = 0,
	PERSPECTIVE_TRANSFORM = 1
}

private static bool isTransformMatrix(TransformMatrix)() {
	// static if its float[][], or its Slice!(2, float*)
	static if(isArray!TransformMatrix) {
		static if (isArray!(ElementType!TransformMatrix) 
			&& isScalarType!(ElementType!(ElementType!TransformMatrix))
			&& isFloatingPoint!(ElementType!(ElementType!TransformMatrix)))
			return true;
		else 
			return false;
	} else static if (__traits(compiles, TemplateOf!TransformMatrix)) {
		static if (__traits(isSame, TemplateOf!TransformMatrix, Slice)
			&& (TemplateArgsOf!TransformMatrix)[0] == 2
			&& isPointer!((TemplateArgsOf!TransformMatrix)[1])
			&& isFloatingPoint!(PointerTarget!((TemplateArgsOf!TransformMatrix)[1]))) 
		{
			return true;
		} else {
			return false;
		}
	}
	else 
	{
		return false;
	}
}

unittest {
	static assert(isTransformMatrix!(float[][]));
	static assert(isTransformMatrix!(double[][]));
	static assert(isTransformMatrix!(real[][]));
	static assert(isTransformMatrix!(real[3][3]));
	static assert(isTransformMatrix!(Slice!(2, float*)));
	static assert(isTransformMatrix!(Slice!(2, double*)));
	static assert(isTransformMatrix!(Slice!(2, real*)));

	static assert(!isTransformMatrix!(int[][]));
	static assert(!isTransformMatrix!(real[]));
	static assert(!isTransformMatrix!(real[][][]));
	static assert(!isTransformMatrix!(Slice!(2, int*)));
	static assert(!isTransformMatrix!(Slice!(1, float*)));
}

Slice!(N, V*) transformAffine(alias interp = linear, V, TransformMatrix, size_t N) 
	(Slice!(N, V*) slice, TransformMatrix transform, size_t[2] outSize = [0, 0])
{
	static if (isTransformMatrix!TransformMatrix) {
		return transformImpl!(TransformType.AFFINE_TRANSFORM, interp)(slice, transform, outSize);
	} else {
		static assert(0, "Invalid transform matrix type: " ~ typeof(transform).stringof);
	}
}

Slice!(N, V*) transformPerspective(alias interp = linear, V, TransformMatrix, size_t N) 
	(Slice!(N, V*) slice, TransformMatrix transform, size_t[2] outSize = [0, 0])
{
	static if (isTransformMatrix!TransformMatrix) {
		return transformImpl!(TransformType.PERSPECTIVE_TRANSFORM, linear)(slice, transform, outSize);
	} else {
		static assert(0, "Invalid transform matrix type: " ~ typeof(transform).stringof);
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
Slice!(2, V*) resizeImpl_2(alias interp, V)(Slice!(2, V*) slice, ulong height, ulong width) {
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
Slice!(3, V*) resizeImpl_3(alias interp, V)(Slice!(3, V*) slice, ulong height, ulong width) {

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


// hope someday slice gets integrated into scid. :) until that day...
Slice!(2, float*) invertTransformMatrix(TransformMatrix)(TransformMatrix t) {
	import scid.matrix;
	import scid.linalg : invert;
	static if (isArray!TransformMatrix) {
		float []tarray = [
			t[0][0], t[0][1], t[0][2],
			t[1][0], t[1][1], t[1][2],
			t[2][0], t[2][1], t[2][2]
		];
	} else {
		float []tarray = [
			t[0, 0], t[0, 1], t[0, 2],
			t[1, 0], t[1, 1], t[1, 2],
			t[2, 0], t[2, 1], t[2, 2]
		];
	}

	auto tmatrix = MatrixView!float(tarray, 3, 3);
	invert(tmatrix);

	return tmatrix.array.sliced(3, 3);
}

Slice!(N, V*) transformImpl(TransformType transformType, alias interp, V, TransformMatrix, size_t N) 
	(Slice!(N, V*) slice, TransformMatrix transform, size_t[2] outSize) 
in {
	static assert(N == 2 || N == 3, "Unsupported slice dimension (only 2D and 3D supported)");

	uint rcount = 0;
	foreach(r; transform) {
		assert(r.length == 3);
		rcount++;
	}
	assert(rcount == 3);
} body {
	// outsize is [width, height]
	if (outSize[0] == 0)
		outSize[0] = slice.length!1;
	if (outSize[1] == 0)
		outSize[1] = slice.length!0;

	static if (N == 2) {
		auto tSlice = new V[outSize[0]*outSize[1]]
		.sliced(outSize[1], outSize[0]);
	} else {
		auto tSlice = new V[outSize[0]*outSize[1]*slice.length!2]
		.sliced(outSize[1], outSize[0], slice.length!2);
	}

	tSlice[] = cast(V)0;

	auto t = transform.invertTransformMatrix;

	static if (N == 3) {
		auto sliceChannels = new Slice!(2, V*)[N];
		foreach(c; iota(slice.length!2)) {
			sliceChannels[c] = slice[0..$, 0..$, c];
		}
	}

	double outOffset_x = cast(double)outSize[0]/2.;
	double outOffset_y = cast(double)outSize[1]/2.;
	double inOffset_x = cast(double)slice.length!1 /2.;
	double inOffset_y = cast(double)slice.length!0 /2.;

	foreach(i; iota(outSize[1])) { // height, rows
		foreach(j; iota(outSize[0])) { // width, columns
			double src_x, src_y;
			double dst_x = cast(double)j - outOffset_x;
			double dst_y = cast(double)i - outOffset_y;
			static if (transformType == TransformType.AFFINE_TRANSFORM) {
				src_x = t[0, 0]*dst_x + t[0, 1]*dst_y + t[0, 2];
				src_y = t[1, 0]*dst_x + t[1, 1]*dst_y + t[1, 2];
			} else static if (transformType == TransformType.PERSPECTIVE_TRANSFORM) {
				double d = (t[2, 9]*dst_x + t[2, 1]*dst_y + t[2, 2]);
				src_x = (t[0, 0]*dst_x + t[0, 1]*dst_y + t[0, 2]) / d;
				src_y = (t[1, 0]*dst_x + t[1, 1]*dst_y + t[1, 2]) / d;
			} else {
				static assert(0, "Invalid transform type"); // should never happen
			}
			src_x += inOffset_x;
			src_y += inOffset_y;
			if (src_x >= 0 && src_x < slice.length!1 &&
				src_y >= 0 && src_y < slice.length!0) {
				static if (N == 2) {
					tSlice[i, j] = interp(slice, src_y, src_x);
				} else if (N == 3) {
					foreach(c; iota(slice.length!2)) {
						tSlice[i, j, c] = interp(sliceChannels[c], src_y, src_x);
					}
				}
			}
		}
	}

	return tSlice;
}
