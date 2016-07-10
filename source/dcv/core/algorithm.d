/**
Module implements various algorithms used often in computer vision.

$(DL Module contains:
    $(DD 
            $(LINK2 #findMin,findMin)
            $(LINK2 #findMax,findMax)
            $(LINK2 #norm,norm)
            $(LINK2 #normalize,normalize)
            $(LINK2 #scaled,scaled)
            $(LINK2 #ranged,ranged)
    )
)

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/ 

module dcv.core.algorithm;

import std.experimental.ndslice;
import std.range;
import std.traits : isNumeric,  isAssignable;
import std.algorithm : map, each, max, min, reduce;

/**
Type of matrix and vector norms.
*/
enum NormType {
    INF, /// Infinite norm, max(x)
    L1, /// 1-norm, sum(abs(x))
    L2 /// Eucledian norm, sqrt(sum(x^^2))
}

private ElementType!Range findMinMax(string comparator, Range)(Range range) pure nothrow
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
    ElementType!Range v = range.front;
    mixin("foreach(e; range) { if (e " ~ comparator ~ " v) v = e; }");
    return v;
}

/**
Find minimum value in the forward range.

params:
range = Forward range in which minimum value is looked for.

returns:
Minimum value of all elements in given range.
*/
ElementType!Range findMin(Range)(Range range) pure nothrow
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
    return range.findMinMax!"<";
}

/// Find minimal value in the array.
unittest {
    auto arr = [1, 2, 3];
    assert(arr.findMin == 1);
}

/**
Find maximum value in the forward range.

params:
range = Forward range in which maximum value is looked for.

returns:
Maximum value of all elements in given range.
*/
ElementType!Range findMax(Range)(Range range) pure nothrow
if (isForwardRange!Range && isNumeric!(ElementType!Range)) {
    return range.findMinMax!">";
}

/// Find maximal value in the array.
unittest {
    auto arr = [1, 2, 3];
    assert(arr.findMax == 3);
}

/**
Calculate value of various norm types for vectors and matrices.

params:
range = Forward range that represents vector or matrix of which the norm is calculated.
normType = requested type of norm.

returns:
Calculated norm value as real.
*/
real norm(Range)(Range range, in NormType normType) 
    if (isForwardRange!Range && 
        isNumeric!(ElementType!Range) && 
isAssignable!(real, ElementType!Range)) {
    final switch (normType) {
        case NormType.INF:
            return range.normImpl_inf;
        case NormType.L1:
            return range.normImpl_n1;
        case NormType.L2:
            return range.normImpl_n2;
    }
}

unittest {
    import std.math : sqrt, approxEqual;

    auto arr = [1.0f, 2.0f, 3.0f];
    assert(approxEqual(arr.norm(NormType.INF), 3.0f));
    assert(approxEqual(arr.norm(NormType.L1), ((arr[0]+arr[1]+arr[2]))));
    assert(approxEqual(arr.norm(NormType.L2), sqrt(arr[0]^^2 + arr[1]^^2 + arr[2]^^2)));
}

/**
Normalize range using given norm type.

Performs lazy normalization by utilizing std.algorithm.iteration.map.
params:
range = Forward range that represent vector or matrix which is normalized.
normType = requested norm type for normalization.

returns:
Returns the map result range that evaluates normalization lazily.
*/
auto normalize(Range)(Range range, NormType normType = NormType.L2)
if (isForwardRange!Range && isAssignable!(real, ElementType!Range)) {
    // TODO: redesign as pure
    auto n = range.norm(normType);
    return range.map!(v => v / n);
}

unittest {
    import std.algorithm.comparison : equal;
    import std.math : sqrt, approxEqual;
    auto arr = [0.0, 1.0, 2.0];
    auto infNorm = 2.0;
    auto l1Norm = 3.0;
    auto l2Norm = sqrt(5.0);
    assert(equal!approxEqual([arr[0] / infNorm, arr[1] / infNorm, arr[2] / infNorm], arr.normalize(NormType.INF).array)); 
    assert(equal!approxEqual([arr[0] / l1Norm, arr[1] / l1Norm, arr[2] / l1Norm], arr.normalize(NormType.L1).array)); 
    assert(equal!approxEqual([arr[0] / l2Norm, arr[1] / l2Norm, arr[2] / l2Norm], arr.normalize(NormType.L2).array)); 
}

/**
Scale range values by shift and multiplication.

Performs value scaling by multiplication and shifting by following equation:
$(D_CODE $(D_PARAM out) = $(D_PARAM alpha)*$(D_PARAM range) + $(D_PARAM beta))

Performs lazy scale of the values by utilizing std.algorithm.iteration.map.

params:
range = Forward range in which values are being scaled.
alpha = Multiplier value.
beta = Shift value.

returns:
Returns the map result range that evaluates value scaling lazily.
*/
auto scaled(Scalar, Range)(Range range, Scalar alpha = 1, Scalar beta = 0) pure @safe nothrow
    if (isForwardRange!Range && isNumeric!(ElementType!Range) && isNumeric!Scalar 
&& isAssignable!(ElementType!Range, Scalar)) {
    static if (is(ElementType!Range == Scalar))
        return range.map!(v => alpha*(v) + beta);
    else
        return range.map!(v => cast(ElementType!Range)(alpha*(v) + beta));
}

///
unittest {
    auto arr = [0.0, 0.5, 1.0];
    arr = arr.scaled(10.0, 2.0).array;
    assert(arr[0] == 2.0);
    assert(arr[1] == 7.0);
    assert(arr[2] == 12.0);
}

/**
Scale range values to fit a given value range.

Performs lazy scale of the values by utilizing std.algorithm.iteration.map.

params:
range = Forward range in which values are being scaled.
min = Minimal range value.
max = Maximal range value.

returns:
Returns the map result range that evaluates value scaling lazily.
*/
auto ranged(Scalar, Range)(Range range, Scalar min = 0, Scalar max = 1)
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

///
unittest {
    auto arr = [0.0, 0.5, 1.0].ranged(0, 10).array;
    assert(arr[0] == 0.);
    assert(arr[1] == 5.);
    assert(arr[2] == 10.);
}

unittest {
    auto arr = [0.0, 0.5, 1.0].ranged(0.0, 10.0).array;
    assert(arr[0] == 0.);
    assert(arr[1] == 5.);
    assert(arr[2] == 10.);
}

unittest {
    auto arr = [0.0, 0.5, 1.0].ranged(0.0f, 10.0f).array;
    assert(arr[0] == 0.);
    assert(arr[1] == 5.);
    assert(arr[2] == 10.);
}

private: // implementation

// basic norm implementation ////////

auto normImpl_inf(Range)(Range range) {
    return range.findMax;
}

auto normImpl_n1(Range)(Range range) {
    import std.math : abs;
    return range.reduce!((a, b) => abs(a + b));
}

auto normImpl_n2(Range)(Range range) {
    import std.math : sqrt;
    ElementType!Range v = 0;
    foreach(e; range) {
        v += e^^2;
    }
    return sqrt(v);
}

