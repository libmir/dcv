module dcv.imgproc.convolution;

private import dcv.core.memory;

private import core.cpuid;
private import core.simd;

private import std.traits;
private import std.range;

private import mir.ndslice;

private import std.algorithm.iteration : reduce;
private import std.algorithm.comparison : max, min;
private import std.exception : enforce;
private	import std.parallelism;

debug {
	import std.stdio : writeln;
}

Slice!(N, V*) conv(V, K, size_t N, size_t NK)(Slice!(N, V*) range, Slice!(NK, K*) kernel, 
	Slice!(N, V*) prealloc = Slice!(N, V*)(),
	Slice!(N, V*) mask = Slice!(N, V*)())
{
	static assert(isAssignable!(V, K), "Uncompatible types for range and kernel");
	static if (N == 1) {
		static assert(NK == 1, "Invalid kernel dimension");
		return conv1Impl(range, kernel, prealloc);
	} else static if (N == 2) {
		static assert(NK == 2,  "Invalid kernel dimension");
		return conv2Impl(range, kernel, prealloc);
	} else static if (N == 3) {
		static assert(NK == 2 || NK == 3, "Invalid kernel dimension");
		return conv3Impl(range, kernel, prealloc);
	} else {
		import std.conv : to;
		static assert(0, "Convolution over " ~ N.to!string ~ "D ranges is not implemented");
	}
}

unittest {
	
	import std.numeric : normalize;

	// test 1
	auto r1 = [0., 1., 2., 3., 4., 5.].sliced(6);
	auto k1 = [-1., 0., 1.].sliced(3);

	auto res1 = r1.conv(k1);

	assert(res1.equal([0., 2., 2., 2., 2., 0.]));

	k1 = [0.3333, 0.3333, 0.3333].sliced(3);

	auto res2 = r1.conv(k1);

	assert(res2.equal([2. / 3., 1., 2., 3., 4., 13. / 3.]));

}

private:

// TODO: implement SIMD
Slice!(1, V*) conv1Impl(V, K)(Slice!(1, V*) range, Slice!(1, K*) kernel, Slice!(1, V*) prealloc) {

	import std.math : abs, floor;

	if (prealloc.empty || prealloc.shape != range.shape)
		prealloc = uninitializedArray!(V[])(cast(ulong)range.length).sliced(range.shape);

	enforce(&range[0] != &prealloc[0], 
		"Preallocated has to contain different data from that of a input range.");

	auto rl = range.length;
	int ks = cast(int)kernel.length; // kernel size
	int kh = max(1, cast(int)(floor(cast(float)ks / 2.))); // kernel size half
	int ke = cast(int)(ks % 2 == 0 ? kh-1 : kh);
	int rt = cast(int)(ks % 2 == 0 ? rl - 1 - kh : rl - kh); // range top

	// run main (inner) loop
	foreach(i; kh.iota(rt).parallel) {
		V v = 0;
		V *rp = &range[i];
		for(int j = -kh; j < ke+1; ++j) {
			v += rp[j]*kernel[j+kh];
		}
		prealloc[i] = v;
	}

	// run starting edge with mirror (symmetric) indexing.
	foreach(i; 0 .. kh) {
		V v_start = 0;
		for(int j = -kh; j < ke+1; ++j) {
			v_start += range[abs(i+j)]*kernel[j+kh];
		}
		prealloc[i] = v_start;
	}

	// run ending edge with mirror (symmetric) indexing.
	foreach(i; rt .. rl) {
		V v_end = 0;
		for(int j = -kh; j < ke+1; ++j) {
			v_end += range[(rl-1)-abs(j)]*kernel[j+kh];
		}
		prealloc[i] = v_end;
	}
	return prealloc;
}

Slice!(2, V*) conv2Impl(V, K)(Slice!(2, V*) range, Slice!(2, K*) kernel, Slice!(2, V*) prealloc) {

	import std.math : abs, floor;

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

	// run inner body convolution of the matrix.
	foreach(i; krh.iota(rrt).parallel) {
		auto row = prealloc[i, 0..rc];
		foreach(j; kch.iota(rct)) {
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

Slice!(3, V*) conv3Impl(V, K, size_t NK)(Slice!(3, V*) range, Slice!(NK, K*) kernel, Slice!(1, V*) prealloc)
{
	return range;
}

