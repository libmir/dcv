/**
Module contains utilities common for all algorithms which operate with feature points.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.features.utils;

import std.traits : isNumeric;

import mir.ndslice;

/**
Feature point.
*/
struct Feature
{
    /// x coordinate of the feature centroid
    size_t x;
    /// y coordinate of the feature centroid
    size_t y;
    /// octave in which the feature is detected.
    size_t octave;
    /// width of the feature
    float width;
    /// height of the feature
    float height;
    /// feature strengh.
    float score;
}

/**
Extract corners as array of 2D points, from response matrix.

Params:
    cornerResponse = Response matrix, collected as output from corner
    detection algoritms such as harrisCorners, or shiTomasiCorners.
    count = Number of corners which need to be extracted. Default is
    -1 which indicate that all responses with value above the threshold
    will be returned.
    threshold = Response threshold - response values in the matrix
    larger than this are considered as valid corners.

Returns:
    Lazy array of size_t[2], as in array of 2D points, of corner reponses
    which fit the given criteria.
*/
pure nothrow
auto extractCorners(T)
(
    Slice!(T*, 2, Contiguous) cornerResponse,
    int count = -1,
    T threshold = 0
) if ( isNumeric!T )
in
{
    assert(!cornerResponse.empty, "Corner response matrix should not be empty.");
}
do
{
    import std.array : Appender;
    import std.typecons : Tuple;

    import mir.ndslice.sorting : sort;
    import mir.ndslice.topology : zip, flattened, ndiota;

    alias Pair = Tuple!(T, "value", size_t[2], "position");

    // TODO: test if corner response is contiguous, or better yet - change
    //       the implementation not to depend on contiguous slice.

    auto resultAppender = Appender!(Pair[])();

    size_t r = 0, c;
    foreach(row; cornerResponse) {
        c = 0;
        foreach(value; row) {
            if (value > threshold) {
                resultAppender.put(Pair(value, [r, c]));
            }
            c++;
        }
        r++;
    }

    auto result = resultAppender
        .data
        .sliced
        .sort!( (a, b) => a.value > b.value )
        .map!( p => p.position );

    if (count > 0) {
        result = result[0..count];
    }

    return result;
}

///
unittest
{
    auto image = [0., 0., 0.,
                  0., 1., 0.,
                  0., 0., 0.].sliced(3, 3);

    auto res = image.extractCorners;

    assert(res.length == 1);
    assert(res[0] == [1, 1]);
}

///
unittest
{
    auto image = [0., 0.1, 0.,
                  0., 0.3, 0.,
                  0., 0.2, 0.].sliced(3, 3);

    auto res = image.extractCorners;

    assert(res.length == 3);
    assert(res[0] == [1, 1]);
    assert(res[1] == [2, 1]);
    assert(res[2] == [0, 1]);
}

///
unittest
{
    auto image = [0., 0.1, 0.,
                  0., 0.3, 0.,
                  0., 0.2, 0.].sliced(3, 3);

    auto res = image.extractCorners(1);

    assert(res.length == 1);
    assert(res[0] == [1, 1]);
}

///
unittest
{
    auto image = [0., 0.1, 0.,
                  0., 0.3, 0.,
                  0., 0.2, 0.].sliced(3, 3);

    auto res = image.extractCorners(-1, 0.2);

    assert(res.length == 1);
    assert(res[0] == [1, 1]);
}

import mir.rc: RCI;
import std.traits;
	
template ElemType(SliceType){
    static if (__traits(isSame, TemplateOf!(IteratorOf!(SliceType)), RCI)){
        alias ASeq = TemplateArgsOf!(IteratorOf!(SliceType));
        alias ElemType = ASeq[0];
    }else{
        alias PointerOf(T : T*) = T;
        alias P = IteratorOf!(SliceType);
        alias ElemType = PointerOf!P;

    }
}