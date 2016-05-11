module dcv.core.algorithm;

/**
 * Module implements various algorithms used often in
 * computer vision.
 * 
 * v0.1 norm:
 * ???
 */ 
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
private ElementType!Range findMinMax(string comparator, Range)(Range range) pure nothrow
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	ElementType!Range v = range.front;
	mixin("foreach(e; range) { if (e " ~ comparator ~ " v) v = e; }");
	return v;
}

/// ditto
ElementType!Range findMin(Range)(Range range) pure nothrow
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
	return range.findMinMax!"<";
}

/// ditto
ElementType!Range findMax(Range)(Range range) pure nothrow
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
auto scaled(Scalar, Range)(Range range, Scalar alpha = 1, Scalar beta = 0) pure @safe nothrow
	if (isForwardRange!Range && isNumeric!(ElementType!Range) && isNumeric!Scalar 
&& isAssignable!(ElementType!Range, Scalar)) {
	static if (is(ElementType!Range == Scalar))
		return range.map!(v => alpha*(v) + beta);
	else
		return range.map!(v => cast(ElementType!Range)(alpha*(v) + beta));
}

auto ranged(Scalar, Range)(Range range, Scalar min = 0, Scalar max = 1) //pure @safe nothrow
	if (isForwardRange!Range && isNumeric!(ElementType!Range) && isNumeric!Scalar
&& isAssignable!(ElementType!Range, Scalar)) {
	import std.traits : isFloatingPoint;
	auto _min = range.findMin;
	auto _max = range.findMax;
	auto _d = _max - _min;
	static if (isFloatingPoint!Scalar) {
		auto sc_val = (max / _d);
		static if (is(ElementType!Range == Scalar))
			return range.map!(a => (a - _min) * sc_val);
		else
			return range.map!(a => cast(ElementType!Range)((a - _min) * sc_val));
	} else {
		auto sc_val = cast(float)(max / _d);
		return range.map!(a => cast(ElementType!Range)(cast(float)(a - _min) * sc_val));
	}
}

unittest {
	auto arr = [0.0, 0.5, 1.0];
	arr = arr.scaled(10).array;
	assert(arr[0] == 0.);
	assert(arr[1] == 5.);
	assert(arr[2] == 10.);
}

/// Normalize range using automatically calculated norm of given type.
auto normalize(Range)(Range range, NormType normType = NormType.L2)
if (isForwardRange!Range && isAssignable!(real, ElementType!Range)) {
	// TODO: redesign as pure
	auto n = range.norm(normType);
	return range.map!(v => v / n);
}

private: // implementation

// basic norm implementation ////////

auto normImpl_inf(Range)(Range range) {
	return range.findMax;
}

auto normImpl_n1(Range)(Range range) {
	import std.math : abs, fabs;
	import std.traits : isFloatingPoint;
	static if (isFloatingPoint!(ElementType!Range)) {
		return range.reduce!((a, b) => fabs(a + b));
	} else {
		return range.reduce!((a, b) => abs(a + b));
	}
}

auto normImpl_n2(Range)(Range range) {
	import std.math : sqrt;
	return range.reduce!((a, b) => a^^2 + b^^2).sqrt;
}

