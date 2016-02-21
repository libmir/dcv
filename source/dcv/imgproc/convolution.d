module dcv.imgproc.convolution;

/**
 * Module introduces array convolution functions.
 * 
 * v0.1 norm:
 * conv (done)
 * separable_conv
 * 
 * v0.1+ plans:
 * 1d_conv_simd
 */
private import dcv.core.memory;
private import dcv.core.utils;

private import std.traits : isAssignable;
private import std.range;
private import std.algorithm.comparison : equal;

private import std.experimental.ndslice;

private import std.algorithm.iteration : reduce;
private import std.algorithm.comparison : max, min;
private import std.exception : enforce;
private	import std.parallelism : parallel;
private	import std.math : abs, floor;


/**
 * Perform convolution to given range, using given kernel.
 * Convolution is supported for 1, 2, and 3D slices.
 * 
 * params:
 * range = Input range slice (1D, 2D, and 3D slice supported)
 * kernel = Convolution kernel slice. For 1D range, 1D kernel is expected. 
 * For 2D range, 2D kernele is expected. For 3D range, 2D or 3D kernel is expected - 
 * if 2D kernel is given, each item in kernel matrix is applied to each value in 
 * corresponding 2D coordinate in the range.
 * prealloc = Pre-allocated array where convolution result can be stored. Default 
 * value is emptySlice, where resulting array will be newly allocated. Also if
 * prealloc is not of same shape as input range, resulting array will be newly allocated. 
 * mask = Masking range. Convolution will skip each element where mask is 0. Default value
 * is empty slice, which tells that convolution will be performed on the whole range.
 */
Slice!(N, V*) conv(V, K, size_t N, size_t NK)(Slice!(N, V*) range, Slice!(NK, K*) kernel, 
	Slice!(N, V*) prealloc = emptySlice!(N, V),
	Slice!(NK, V*) mask = emptySlice!(NK, V))
{
	static assert(isAssignable!(V, K), "Uncompatible types for range and kernel");

	if (!mask.empty && !mask.shape[].equal(range.shape[])) {
		import std.conv : to;
		throw new Exception("Invalid mask shape: " ~ mask.shape[].to!string ~ 
			", range shape: " ~ range.shape[].to!string);
	}

	static if (N == 1) {
		static assert(NK == 1, "Invalid kernel dimension");
		return conv1Impl(range, kernel, prealloc, mask);
	} else static if (N == 2) {
		static assert(NK == 2,  "Invalid kernel dimension");
		return conv2Impl(range, kernel, prealloc, mask);
	} else static if (N == 3) {
		static assert(NK == 2 || NK == 3, "Invalid kernel dimension");
		return conv3Impl(range, kernel, prealloc, mask);
	} else {
		import std.conv : to;
		static assert(0, "Convolution over " ~ N.to!string ~ "D ranges is not implemented");
	}
}

unittest {
	auto r1 = [0., 1., 2., 3., 4., 5.].sliced(6);
	auto k1 = [-1., 0., 1.].sliced(3);
	auto res1 = r1.conv(k1);
	assert(res1.equal([0., 2., 2., 2., 2., 0.]));

	/*
	 k1 = [0.3333, 0.3333, 0.3333].sliced(3);
	 auto res2 = r1.conv(k1);
	 assert(res2.equal([2. / 3., 1., 2., 3., 4., 13. / 3.]));
	 */
}

/**
 * 
 */
void calcPartialDerivatives(T)(Slice!(2, T*) image, 
	ref Slice!(2, T*) fx, ref Slice!(2, T*) fy) {

	assert(!image.empty);
	auto itemLength = image.shape.reduce!"a*b";
	if (!fx.shape[].equal(image.shape[]))
		fx = uninitializedArray!(T[])(itemLength).sliced(image.shape);
	if (!fy.shape[].equal(image.shape[]))
		fy = uninitializedArray!(T[])(itemLength).sliced(image.shape);

	auto rows = image.length!0;
	auto cols = image.length!1;

	// calc mid-ground
	foreach (r ; 1.iota(rows)) {
		auto x_row = fx[r, 0..$];
		auto y_row = fy[r, 0..$];
		foreach (c; 1.iota(cols)) {
			auto imrc = image[r, c];
			x_row[c] = cast(T)(-1. * image[r, c - 1] + imrc);
			y_row[c] = cast(T)(-1. * image[r - 1, c] + imrc);
		}
	}

	// calc border edges
	auto x_row = fx[0, 0..$];
	auto y_row = fy[0, 0..$];

	foreach (c; 0.iota(cols - 1)) {
		auto im_0c = image[0, c];
		x_row[c] = cast(T)(-1. * im_0c + image[0, c + 1]);
		y_row[c] = cast(T)(-1. * im_0c + image[1, c]);
	}

	auto x_col = fx[0..$, 0];
	auto y_col = fy[0..$, 0];

	foreach (r; iota(rows - 1)) {
		auto im_r_0 = image[r, 0];
		x_col[r] = cast(T)(-1. * im_r_0 + image[r, 1]);
		y_col[r] = cast(T)(-1. * im_r_0 + image[r + 1, 0]);
	}

	// edges corner pixels
	fx[0, cols-1] = cast(T)(-1* image[0, cols-2] + image[0, cols-1]);
	fy[0, cols-1] = cast(T)(-1*image[0, cols-1] + image[1, cols-1]);
	fx[rows-1, 0] = cast(T)(-1*image[rows-1, 0] + image[rows-1, 1]);
	fy[rows-1, 0] = cast(T)(-1*image[rows-2, 0] + image[rows-1, 0]);
}

private:

// TODO: implement SIMD
Slice!(1, V*) conv1Impl(V, K)(Slice!(1, V*) range, Slice!(1, K*) kernel, 
	Slice!(1, V*) prealloc, Slice!(1, V*) mask) {

	if (prealloc.empty || prealloc.shape != range.shape)
		prealloc = uninitializedArray!(V[])(cast(ulong)range.length).sliced(range.shape);

	enforce(&range[0] != &prealloc[0], 
		"Preallocated has to contain different data from that of a input range.");

	auto rl = range.length;
	int ks = cast(int)kernel.length; // kernel size
	int kh = max(1, cast(int)(floor(cast(float)ks / 2.))); // kernel size half
	int ke = cast(int)(ks % 2 == 0 ? kh-1 : kh);
	int rt = cast(int)(ks % 2 == 0 ? rl - 1 - kh : rl - kh); // range top

	bool useMask = !mask.empty;

	// run main (inner) loop
	foreach(i; kh.iota(rt).parallel) {
		if (useMask && !mask[i])
			continue;
		V v = 0;
		V *rp = &range[i];
		for(int j = -kh; j < ke+1; ++j) {
			v += rp[j]*kernel[j+kh];
		}
		prealloc[i] = v;
	}

	// run starting edge with mirror (symmetric) indexing.
	foreach(i; 0 .. kh) {
		if (useMask && !mask[i])
			continue;
		V v_start = 0;
		for(int j = -kh; j < ke+1; ++j) {
			v_start += range[abs(i+j)]*kernel[j+kh];
		}
		prealloc[i] = v_start;
	}

	// run ending edge with mirror (symmetric) indexing.
	foreach(i; rt .. rl) {
		if (useMask && !mask[i])
			continue;
		V v_end = 0;
		for(int j = -kh; j < ke+1; ++j) {
			v_end += range[(rl-1)-abs(j)]*kernel[j+kh];
		}
		prealloc[i] = v_end;
	}
	return prealloc;
}

Slice!(2, V*) conv2Impl(V, K)(Slice!(2, V*) range, Slice!(2, K*) kernel, 
	Slice!(2, V*) prealloc, Slice!(2, V*) mask) {

	if (prealloc.empty || prealloc.shape != range.shape)
		prealloc = uninitializedArray!(V[])(cast(ulong)range.shape.reduce!"a*b").sliced(range.shape);

	enforce(&range[0, 0] != &prealloc[0, 0], 
		"Preallocated has to contain different data from that of a input range.");

	auto rr = range.length!0; // range rows
	auto rc = range.length!1; // range columns

	int krs = cast(int)kernel.length!0; // kernel rows
	int kcs = cast(int)kernel.length!1; // kernel rows

	int krh = max(1, cast(int)(floor(cast(float)krs / 2.))); // kernel rows size half
	int kch = max(1, cast(int)(floor(cast(float)kcs / 2.))); // kernel rows size half

	int kre = cast(int)(krs % 2 == 0 ? krh-1 : krh);
	int kce = cast(int)(kcs % 2 == 0 ? kch-1 : kch);

	int rrt = cast(int)(krs % 2 == 0 ? rr - 1 - krh : rr - krh); // range top
	int rct = cast(int)(kcs % 2 == 0 ? rc - 1 - kch : rc - kch); // range top

	bool useMask = !mask.empty;

	// run inner body convolution of the matrix.
	foreach(i; krh.iota(rrt).parallel) {
		auto row = prealloc[i, 0..rc];
		foreach(j; kch.iota(rct)) {
			if (useMask && !mask[i, j])
				continue;
			V v = 0;
			for(int ii = -krh; ii < krh+1; ++ii) {
				for(int jj = -kch; jj < kch+1; ++jj) {
					v += range[i+ii, j+jj]*kernel[ii+krh, jj+kch];
				}
			}
			row[j] = v;
		}
	}

	// run upper edge with mirror (symmetric) indexing.
	auto row = prealloc[0, 0..rc];
	foreach(j; 0.iota(rc).parallel) {
		if (useMask && !mask[0, j])
			continue;
		V v = 0;
		for(int ii = -krh; ii < krh+1; ++ii) {
			for(int jj = -kch; jj < kch+1; ++jj) {
				immutable jjj = j+jj;
				immutable jj_pos = jjj < 0 ? abs(jjj) :	jjj > rc-1 ? rc-1-abs(jj) : jjj;
				v += range[abs(ii), jj_pos]*kernel[ii+krh, jj+kch];
			}
		}
		row[j] = v;
	}

	// run lower edge with mirror (symmetric) indexing.
	row = prealloc[rr-1, 0..rc];
	foreach(j; 0.iota(rc).parallel) {
		if (useMask && !mask[rr-1, j])
			continue;
		V v = 0;
		for(int ii = -krh; ii < krh+1; ++ii) {
			for(int jj = -kch; jj < kch+1; ++jj) {
				immutable jjj = j+jj;
				immutable jj_pos = jjj < 0 ? abs(jjj) :	jjj > rc-1 ? rc-1-abs(jj) : jjj;
				v += range[(rr-1)-abs(ii), jj_pos]*kernel[ii+krh, jj+kch];
			}
		}
		row[j] = v;
	}

	// run left edge with mirror (symmetric) indexing.
	auto col = prealloc[0..rr, 0];
	foreach(i; 0.iota(rr).parallel) {
		if (useMask && !mask[i, 0])
			continue;
		V v = 0;
		for(int ii = -krh; ii < krh+1; ++ii) {
			for(int jj = -kch; jj < kch+1; ++jj) {
				immutable iii = i+ii;
				immutable ii_pos = iii < 0 ? abs(iii) :	iii > rr - 1 ? rr-1-abs(ii) : iii;
				v += range[ii_pos, abs(jj)]*kernel[ii+krh, jj+kch];
			}
		}
		col[i] = v;
	}

	// run right edge with mirror (symmetric) indexing.
	col = prealloc[0..rr, rc-1];
	foreach(i; 0.iota(rr).parallel) {
		if (useMask && !mask[i, rc-1])
			continue;
		V v = 0;
		for(int ii = -krh; ii < krh+1; ++ii) {
			for(int jj = -kch; jj < kch+1; ++jj) {
				immutable iii = i+ii;
				immutable ii_pos = iii < 0 ? abs(iii) :	iii > rr - 1 ? rr-1-abs(ii) : iii;
				v += range[ii_pos, (rc-1)-abs(jj)]*kernel[ii+krh, jj+kch];
			}
		}
		col[i] = v;
	}

	return prealloc;
}

// TODO: think of less boilerplate implementation.
Slice!(3, V*) conv3Impl(V, K, size_t NK)(Slice!(3, V*) range, Slice!(NK, K*) kernel, 
	Slice!(3, V*) prealloc, Slice!(NK, V*) mask)
{
	static if (NK == 2) {
		return conv3Impl_kernel2(range, kernel, prealloc, mask);
	} else if (NK == 3) {
		return conv3Impl_kernel3(range, kernel, prealloc, mask);
	} // else other is statically checked in the main conv call.
}

Slice!(3, V*) conv3Impl_kernel2(V, K)(Slice!(3, V*) range, Slice!(2, K*) kernel, 
	Slice!(3, V*) prealloc, Slice!(2, V*) mask)
{
	if (prealloc.empty || prealloc.shape != range.shape)
		prealloc = uninitializedArray!(V[])(cast(ulong)range.shape.reduce!"a*b").sliced(range.shape);

	enforce(&range[0, 0, 0] != &prealloc[0, 0, 0], 
		"Preallocated has to contain different data from that of a input range.");

	auto rr = range.length!0; // range rows
	auto rc = range.length!1; // range columns
	auto rch = range.length!2; // range channels

	int krs = cast(int)kernel.length!0; // kernel rows
	int kcs = cast(int)kernel.length!1; // kernel rows

	int krh = max(1, cast(int)(floor(cast(float)krs / 2.))); // kernel rows size half
	int kch = max(1, cast(int)(floor(cast(float)kcs / 2.))); // kernel rows size half

	int kre = cast(int)(krs % 2 == 0 ? krh-1 : krh);
	int kce = cast(int)(kcs % 2 == 0 ? kch-1 : kch);

	int rrt = cast(int)(krs % 2 == 0 ? rr - 1 - krh : rr - krh); // range top
	int rct = cast(int)(kcs % 2 == 0 ? rc - 1 - kch : rc - kch); // range top

	bool useMask = !mask.empty;

	// run inner body convolution of the matrix.
	foreach(i; krh.iota(rrt).parallel) {
		auto row = prealloc[i, 0..rc, 0..rch];
		foreach(j; kch.iota(rct)) {
			if (useMask && !mask[i, j])
				continue;
			row[j, 0..rch][] = 0;
			for(int ii = -krh; ii < krh+1; ++ii) {
				for(int jj = -kch; jj < kch+1; ++jj) {
					foreach(c; 0.iota(rch)) {
						row[j, c] += range[i+ii, j+jj, c]*kernel[ii+krh, jj+kch];
					}
				}
			}
		}
	}

	// run upper edge with mirror (symmetric) indexing.
	foreach(i; 0.iota(krh+1)) {
		auto row = prealloc[i, 0..rc, 0..rch];
		foreach(j; 0.iota(rc).parallel) {
			if (useMask && !mask[0, j])
				continue;
			row[j, 0..rch][] = 0;
			for(int ii = -krh; ii < krh+1; ++ii) {
				for(int jj = -kch; jj < kch+1; ++jj) {
					immutable jjj = j+jj;
					immutable jj_pos = jjj < 0 ? abs(jjj) :	jjj > rc-1 ? rc-1-abs(jj) : jjj;
					foreach(c; 0.iota(rch)) {
						row[j, c] += range[abs(ii), jj_pos, c]*kernel[ii+krh, jj+kch];
					}
				}
			}
		}
	}

	// run lower edge with mirror (symmetric) indexing.
	foreach(i; rrt.iota(rr)) {
		auto row = prealloc[i, 0..rc, 0..rch];
		foreach(j; 0.iota(rc).parallel) {
			if (useMask && !mask[rr-1, j])
				continue;
			row[j, 0..rch][] = 0;
			for(int ii = -krh; ii < krh+1; ++ii) {
				for(int jj = -kch; jj < kch+1; ++jj) {
					immutable jjj = j+jj;
					immutable jj_pos = jjj < 0 ? abs(jjj) :	jjj > rc-1 ? rc-1-abs(jj) : jjj;
					foreach(c; 0.iota(rch)) {
						row[j, c] += range[(rr-1)-abs(ii), jj_pos, c]*kernel[ii+krh, jj+kch];
					}
				}
			}
		}
	}

	// run left edge with mirror (symmetric) indexing.
	foreach(j; 0.iota(kch)) {
		auto col = prealloc[0..rr, j, 0..rch];
		foreach(i; 0.iota(rr).parallel) {
			if (useMask && !mask[i, 0])
				continue;
			col[i, 0..rch][] = 0;
			for(int ii = -krh; ii < krh+1; ++ii) {
				for(int jj = -kch; jj < kch+1; ++jj) {
					immutable iii = i+ii;
					immutable ii_pos = iii < 0 ? abs(iii) :	iii > rr - 1 ? rr-1-abs(ii) : iii;
					foreach(c; 0.iota(rch)) {
						col[i, c] += range[ii_pos, abs(jj), c]*kernel[ii+krh, jj+kch];
					}
				}
			}
		}
	}

	// run right edge with mirror (symmetric) indexing.
	foreach(j; rct.iota(rc)) {
		auto col = prealloc[0..rr, j, 0..rch];
		foreach(i; 0.iota(rr).parallel) {
			if (useMask && !mask[i, rc-1])
				continue;
			col[i, 0..rch][] = 0;
			for(int ii = -krh; ii < krh+1; ++ii) {
				for(int jj = -kch; jj < kch+1; ++jj) {
					immutable iii = i+ii;
					immutable ii_pos = iii < 0 ? abs(iii) :	iii > rr - 1 ? rr-1-abs(ii) : iii;
					foreach(c; 0.iota(rch)) {
						col[i, c] += range[ii_pos, (rc-1)-abs(jj), c]*kernel[ii+krh, jj+kch];
					}
				}
			}
		}
	}

	return prealloc;
}

Slice!(3, V*) conv3Impl_kernel3(V, K)(Slice!(3, V*) range, Slice!(3, K*) kernel, 
	Slice!(3, V*) prealloc, Slice!(3, V*) mask)
{
	if (prealloc.empty || prealloc.shape != range.shape)
		prealloc = uninitializedArray!(V[])(cast(ulong)range.shape.reduce!"a*b").sliced(range.shape);

	enforce(&range[0, 0, 0] != &prealloc[0, 0, 0], 
		"Preallocated has to contain different data from that of a input range.");

	auto rr = range.length!0; // range rows
	auto rc = range.length!1; // range columns
	auto rch = range.length!2; // range channels

	int krs = cast(int)kernel.length!0; // kernel rows
	int kcs = cast(int)kernel.length!1; // kernel rows

	int krh = max(1, cast(int)(floor(cast(float)krs / 2.))); // kernel rows size half
	int kch = max(1, cast(int)(floor(cast(float)kcs / 2.))); // kernel cols size half

	int kre = cast(int)(krs % 2 == 0 ? krh-1 : krh);
	int kce = cast(int)(kcs % 2 == 0 ? kch-1 : kch);

	int rrt = cast(int)(krs % 2 == 0 ? rr - 1 - krh : rr - krh); // range top
	int rct = cast(int)(kcs % 2 == 0 ? rc - 1 - kch : rc - kch); // range top

	bool useMask = !mask.empty;

	// run inner body convolution of the matrix.
	foreach(i; krh.iota(rrt).parallel) {
		auto row = prealloc[i, 0..rc, 0..rch];
		foreach(j; kch.iota(rct)) {
			foreach(c; 0.iota(rch)) {
				if (useMask && !mask[i, j, c])
					continue;
				V v = 0;
				for(int ii = -krh; ii < krh+1; ++ii) {
					for(int jj = -kch; jj < kch+1; ++jj) {
						v += range[i+ii, j+jj, c]*kernel[ii+krh, jj+kch, c];
					}
				}
				row[j, c] = v;
			}
		}
	}

	// run upper edge with mirror (symmetric) indexing.
	foreach(i; 0.iota(krh+1)) {
		auto row = prealloc[i, 0..rc, 0..rch];
		foreach(j; 0.iota(rc).parallel) {
			foreach(c; 0.iota(rch)) {
				if (useMask && !mask[0, j, c])
					continue;
				V v = 0;
				for(int ii = -krh; ii < krh+1; ++ii) {
					for(int jj = -kch; jj < kch+1; ++jj) {
						immutable jjj = j+jj;
						immutable jj_pos = jjj < 0 ? abs(jjj) :	jjj > rc-1 ? rc-1-abs(jj) : jjj;
						v += range[abs(ii), jj_pos, c]*kernel[ii+krh, jj+kch, c];
					}
				}
				row[j, c] = v;
			}
		}
	}

	// run lower edge with mirror (symmetric) indexing.
	foreach(i; rrt.iota(rr)) {
		auto row = prealloc[i, 0..rc, 0..rch];
		foreach(j; 0.iota(rc).parallel) {
			foreach(c; 0.iota(rch)) {
				if (useMask && !mask[rr-1, j, c])
					continue;
				V v = 0;
				for(int ii = -krh; ii < krh+1; ++ii) {
					for(int jj = -kch; jj < kch+1; ++jj) {
						immutable jjj = j+jj;
						immutable jj_pos = jjj < 0 ? abs(jjj) :	jjj > rc-1 ? rc-1-abs(jj) : jjj;
						v += range[(rr-1)-abs(ii), jj_pos, c]*kernel[ii+krh, jj+kch, c];
					}
				}
				row[j, c] = v;
			}
		}
	}

	// run left edge with mirror (symmetric) indexing.
	foreach(j; 0.iota(kch)) {
		auto col = prealloc[0..rr, j, 0..rch];
		foreach(i; 0.iota(rr).parallel) {
			foreach(c; 0.iota(rch)) {
				if (useMask && !mask[i, 0, c])
					continue;
				V v = 0;
				for(int ii = -krh; ii < krh+1; ++ii) {
					for(int jj = -kch; jj < kch+1; ++jj) {
						immutable iii = i+ii;
						immutable ii_pos = iii < 0 ? abs(iii) :	iii > rr - 1 ? rr-1-abs(ii) : iii;
						v += range[ii_pos, abs(jj), c]*kernel[ii+krh, jj+kch, c];
					}
				}
				col[i, c] = v;
			}
		}
	}

	// run right edge with mirror (symmetric) indexing.
	foreach(j; rct.iota(rc)) {
		auto col = prealloc[0..rr, j, 0..rch];
		foreach(i; 0.iota(rr).parallel) {
			foreach(c; 0.iota(rch)) {
				if (useMask && !mask[i, rc-1, c])
					continue;
				V v = 0;
				for(int ii = -krh; ii < krh+1; ++ii) {
					for(int jj = -kch; jj < kch+1; ++jj) {
						immutable iii = i+ii;
						immutable ii_pos = iii < 0 ? abs(iii) :	iii > rr - 1 ? rr-1-abs(ii) : iii;
						v += range[ii_pos, (rc-1)-abs(jj), c]*kernel[ii+krh, jj+kch, c];
					}
				}
				col[i, c] = v;
			}
		}
	}

	return prealloc;
}


