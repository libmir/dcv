module dcv.core.algorithm;

private import mir.ndslice;
private import std.range;
private import std.traits;
private import std.algorithm : map, each, max, min;
private import std.functional;
private import std.parallelism;

enum NormType {
	INF, // infinite norm
	L1, // one norm
	L2 // eucledian norm
}


/// Find minimum(default) or maximum value in the range.
ElementType!Range findMinMax(string comparator, Range)(Range range)
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	ElementType!Range v = 0;
	mixin("foreach(e; range) { if (e " ~ comparator ~ " v) v = e; }");
	return v;
}

ElementType!Range findMin(Range)(Range range)
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	return range.findMinMax!"<";
}

ElementType!Range findMax(Range)(Range range)
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	return range.findMinMax!">";
}

unittest {
	auto arr = [1, 2, 3];
	assert(arr.findMin == 1);
	assert(arr.findMax == 3);
}

real norm(Range)(Range range, in NormType normType) 
	if (isForwardRange!Range && 
		isNumeric!(ElementType!Range) && 
		isAssignable!(real, ElementType!Range)) {
	switch (normType) {
		case NormType.INF:
			return range.normImpl_inf;
		case NormType.L1:
			return range.normImpl_n1;
		case NormType.L2:
			return range.normImpl_n2;
		default:
			assert(0);
	}
}

unittest {
	float []arr = [1, 2, 3];
	import std.math : sqrt;

	assert(arr.norm(NormType.INF) == 3);
	assert(arr.norm(NormType.L1) == ((1.+2.+3.)/3.));
	assert(arr.norm(NormType.L2) == sqrt(1.+4.+9.));
}

/// Scale range values (outrange = alpha*inrange + beta)
auto scale(Range, Scalar)(Range range, Scalar alpha = 1, Scalar beta = 0) 
	if (isForwardRange!Range && isNumeric!(ElementType!Range) && isNumeric!Scalar 
		&& isAssignable!(ElementType!Range, Scalar)) {
	//return taskPool.amap!(v => cast(float)(alpha*v + beta))(range).array;
	range.each!((ref v) => v = (alpha*(v) + beta));
	return range;
}

unittest {
	auto arr = [0.0, 0.5, 1.0];
	arr.scale(0, 10);
	assert(arr[0] == 0.);
	assert(arr[1] == 5.);
	assert(arr[2] == 10.);
}

Range normalize(Range)(Range range, NormType normType)
	if (isForwardRange!Range && isAssignable!(real, ElementType!Range)) {
	auto n = range.norm(normType);
	range.each!((ref v) => v /= n);
	return range;
}

unittest {

}

auto sum(Range)(Range range) @safe pure
	if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	import std.algorithm : reduce;
	return range.reduce!"a+b";
}

auto mean(Range)(Range range) @safe pure
	if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	return range.sum / range.length;
}

auto abs(Range)(Range range) @safe pure
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	import std.math : abs;
	range.each!((ref v) => v = abs(v));
	return range;
}

auto fabs(Range)(Range range) @safe pure
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	import std.math : fabs;
	range.each!((ref v) => v = fabs(v));
	return range;
}

auto ceil(Range)(Range range) @safe pure
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	import std.math : ceil;
	range.each!((ref v) => v = ceil(v));
	return range;
}

auto floor(Range)(Range range) @safe pure
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	import std.math : floor;
	range.each!((ref v) => v = floor(v));
	return range;
}

auto log(Range)(Range range) @safe pure
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	import std.math : log;
	range.each!((ref v) => v = log(v));
	return range;
}

auto log10(Range)(Range range) @safe pure
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	import std.math : log10;
	range.each!((ref v) => v = log10(v));
	return range;
}

auto pow(Range)(Range range) @safe pure
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	import std.math : pow;
	range.each!((ref v) => v = pow(v));
	return range;
}

auto sqrt(Range)(Range range) @safe pure
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	import std.math : sqrt;
	range.each!((ref v) => v = sqrt(v));
	return range;
}

auto sqrt(Range)(Range range) @safe pure
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	import std.math : sqrt;
	range.each!((ref v) => v = sqrt(v));
	return range;
}

@safe pure unittest {
	float []arr = [1, 2, 3];
	assert(arr.sum == 6);
	assert(arr.mean == 2);
}

private: // implementation

auto normImpl_inf(Range)(Range range) {
	ElementType!Range n = 0;
	foreach (e; range) {
		if (e > n)
			n = e;
	}
	return n;
}

auto normImpl_n1(Range)(Range range) {
	ElementType!Range n = 0;
	foreach (e; range) {
		n += e;
	}
	return n;
}

auto normImpl_n2(Range)(Range range) {
	import std.math : sqrt;

	ElementType!Range n = 0;
	foreach (e; range) {
		n += (e*e);
	}
	return sqrt(n);
}
