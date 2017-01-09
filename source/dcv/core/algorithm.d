/**
Module implements various algorithms used often in computer vision.

$(DL Module contains:
    $(DD 
            $(LINK2 #norm,norm)
            $(LINK2 #normalized,normalized)
            $(LINK2 #scaled,scaled)
            $(LINK2 #ranged,ranged)
    )
)

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.core.algorithm;

import std.traits : isNumeric, isFloatingPoint;

import mir.ndslice.slice;
import mir.ndslice.algorithm : reduce, each;
import mir.math.internal;

/**
Scale tensor values.

Params:
    tensor = Input tensor.
    alpha = Multiplier value.
    beta = Offset value.

Performs value modification of tensor elements using following formula:
----
ref output = alpha * (input) + beta;
----

Returns:
    Scaled input tensor.
    
*/
nothrow @nogc auto scaled(Scalar, Tensor)(Tensor tensor, Scalar alpha = 1, Scalar beta = 0) if (isNumeric!Scalar)
in
{
    static assert(isSlice!Tensor, "Input tensor has to be of type mir.ndslice.slice.Slice.");
}
body
{
    tensor.each!((ref v) { v = cast(DeepElementType!Tensor)(alpha * (v) + beta); });
    return tensor;
}

nothrow unittest
{
    import std.math : approxEqual;

    auto t = tensor1();
    auto ts = t.scaled(10.0f, 2.0f);

    assert(t.iterator == ts.iterator);

    assert(approxEqual(ts[0], 12.0f));
    assert(approxEqual(ts[1], 22.0f));
    assert(approxEqual(ts[2], 32.0f));
}

/**
In-place tensor scaling to fit given value range.

Params:
    tensor = Input tensor.
    minValue = Minimal value output tensor should contain.
    maxValue = Maximal value output tensor should contain.

*/
nothrow @nogc auto ranged(Scalar, Tensor)(Tensor tensor,
        Scalar minValue = 0, Scalar maxValue = 1) if (isNumeric!Scalar)
in
{
    static assert(isSlice!Tensor, "Input tensor has to be of type mir.ndslice.slice.Slice.");
}
body
{
    alias T = DeepElementType!Tensor;

    static if (isFloatingPoint!T)
    {
        import mir.math.internal : fmin, fmax;
        auto _max = reduce!fmax(T.min_normal, tensor);
        auto _min = reduce!fmin(T.max, tensor);
    }
    else
    {
        import mir.utility : min, max;
        auto _max = reduce!max(T.min, tensor);
        auto _min = reduce!min(T.max, tensor);
    }

    auto rn_val = _max - _min;
    auto sc_val = maxValue - minValue;

    tensor.each!((ref a) { a = cast(T)(sc_val * ((a - _min) / rn_val) + minValue); });

    return tensor;
}

unittest
{
    immutable smin = -10.0f;
    immutable smax = 15.0f;

    auto t1 = tensor1();
    auto t2 = tensor2();
    auto t3 = tensor3();

    auto t1r = t1.ranged(smin, smax);
    auto t2r = t2.ranged(smin, smax);
    auto t3r = t3.ranged(smin, smax);

    assert(t1.iterator == t1r.iterator);
    assert(t2.iterator == t2r.iterator);
    assert(t3.iterator == t3r.iterator);

}

nothrow unittest
{
    import std.math : approxEqual;

    import mir.utility;

    immutable smin = -10.0f;
    immutable smax = 15.0f;

    auto t1 = tensor1();
    auto t2 = tensor2();
    auto t3 = tensor3();

    auto t1r = t1.ranged(smin, smax);
    auto t2r = t2.ranged(smin, smax);
    auto t3r = t3.ranged(smin, smax);

    assert(approxEqual(reduce!min(float.max, t1r), smin));
    assert(approxEqual(reduce!max(float.min_normal, t1r), smax));

    assert(approxEqual(reduce!min(float.max, t2r), smin));
    assert(approxEqual(reduce!max(float.min_normal, t2r), smax));

    assert(approxEqual(reduce!min(float.max, t3r), smin));
    assert(approxEqual(reduce!max(float.min_normal, t3r), smax));
}

version (unittest)
{
    auto tensor1()
    {
        return [1.0f, 2.0f, 3.0f].sliced(3);
    }

    auto tensor2()
    {
        return [1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f, 8.0f, 9.0f].sliced(3, 3);
    }

    auto tensor3()
    {
        return [1.0f, 2.0f, 3.0f,       4.0f, 5.0f, 6.0f,       7.0f, 8.0f, 9.0f, 
               10.0f, 11.0f, 12.0f,     13.0f, 14.0f, 15.0f,    16.0f, 17.0f, 18.0f, 
               19.0f, 20.0f, 21.0f,     22.0f, 23.0f, 24.0f,    25.0f, 26.0f, 27.0f].sliced(3, 3, 3);
    }
}
