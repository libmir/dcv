module dcv.core.algorithm;

private import std.experimental.ndslice;
private import std.range;
private import std.traits : isNumeric,  isAssignable;
private import std.algorithm : map, each, max, min, reduce;

enum NormType {
	INF, // infinite norm
	L1, // one norm
	L2 // eucledian norm
}


/// Find minimum(default) or maximum value in the range.
ElementType!Range findMinMax(string comparator, Range)(Range range)
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	ElementType!Range v = range.front;
	mixin("foreach(e; range) { if (e " ~ comparator ~ " v) v = e; }");
	return v;
}

/// ditto
ElementType!Range findMin(Range)(Range range)
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	return range.findMinMax!"<";
}

/// ditto
ElementType!Range findMax(Range)(Range range)
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	return range.findMinMax!">";
}

unittest {
	auto arr = [1, 2, 3];
	assert(arr.findMin == 1);
	assert(arr.findMax == 3);
}

/// Find norm of range.
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
	import std.math : sqrt, approxEqual;

	auto arr = [1., 2., 3.];
	assert(approxEqual(arr.norm(NormType.INF), 3.));
	assert(approxEqual(arr.norm(NormType.L1), ((1.+2.+3.))));
	//assert(approxEqual(arr.norm(NormType.L2), sqrt(arr[0]^^2 + arr[1]^^2 + arr[2]^^2)));
}

/// Scale range values (outrange = alpha*inrange + beta)
auto scale(Range, Scalar)(Range range, Scalar alpha = 1, Scalar beta = 0) 
	if (isForwardRange!Range && isNumeric!(ElementType!Range) && isNumeric!Scalar 
&& isAssignable!(ElementType!Range, Scalar)) {
	// TODO: redesign as pure with map
	range.each!((ref v) => v = (alpha*(v) + beta));
	return range;
}

unittest {
	auto arr = [0.0, 0.5, 1.0];
	arr.scale(10);
	assert(arr[0] == 0.);
	assert(arr[1] == 5.);
	assert(arr[2] == 10.);
}

/// Normalize range using automatically calculated norm of given type.
Range normalize(Range)(Range range, NormType normType)
if (isForwardRange!Range && isAssignable!(real, ElementType!Range)) {
	// TODO: redesign as pure
	auto n = range.norm(normType);
	range.each!((ref v) => v /= n);
	return range;
}

private: // implementation

// basic norm implementation ////////

auto normImpl_inf(Range)(Range range) {
	return range.findMax;
}

auto normImpl_n1(Range)(Range range) {
	return range.reduce!((a, b) => a + b);
}

auto normImpl_n2(Range)(Range range) {
	import std.math : sqrt;
	return range.reduce!((a, b) => a^^2 + b^^2).sqrt;
}
