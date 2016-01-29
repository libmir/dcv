module dcv.imgproc.convolution;


private import std.traits;
private import std.range;

private import mir.ndslice;

private import std.algorithm.iteration : reduce;
private import std.algorithm.comparison : max, min;
private import std.exception : enforce;
private	import std.parallelism;


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

private:

Slice!(1, V*) conv1Impl(V, K)(Slice!(1, V*) range, Slice!(1, K*) kernel, Slice!(1, V*) prealloc) {

	if (prealloc.empty || prealloc.shape != range.shape)
		prealloc = new V[cast(ulong)range.shape.reduce!"a*b"].sliced(range.shape);

	enforce(&range[0] != &prealloc[0], "Preallocated range value has point to a different data from that of a input range.");

	if (kernel.length == 3) {
		conv1Impl_3(range, kernel, prealloc);
	} else {
		int ks = cast(int)kernel.length; // kernel size
		int kh = max(1, ks / 2);
		for(int i = kh; i < range.length-kh; i++) {
			real v = 0;
			for(int j = -kh; j < kh+1; ++j) {
				v += range[i+j]*kernel[j+kh];
			}
			prealloc[i] = v;
		}
	}

	return prealloc;
}

Slice!(1, V*) conv1Impl_3(V, K)(Slice!(1, V*) range, Slice!(1, K*) kernel, Slice!(1, V*) prealloc) {

	import core.simd;
	import core.cpuid;

	foreach(i, ref e; taskPool.parallel(range)) {
		if (i == 0 || i == range.length-1)
			continue;
	//foreach(i; 1.iota(range.length-1)) {
	//for(int i = 1; i < range.length-1; ++i) {
		prealloc[i] = range[i-1]*kernel[0];
		prealloc[i] += range[i]*kernel[1];
		prealloc[i] += range[i+1]*kernel[2];
	}

	return prealloc;
}

Slice!(2, V*) conv2Impl(V, K)(Slice!(2, V*) range, Slice!(2, K*) kernel, Slice!(1, V*) prealloc) {
	return range;
}

Slice!(3, V*) conv3Impl(V, K, size_t NK)(Slice!(3, V*) range, Slice!(NK, K*) kernel, Slice!(1, V*) prealloc) 
{
	return range;
}
