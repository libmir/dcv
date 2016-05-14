module dcv.features.utils;


/**
 * Module contains utilities common for all algorithms which operate with feature points.
 */

private import std.experimental.ndslice;
private import std.traits : isNumeric;


/**
 * Feature point.
 */
struct Feature {
    size_t x; // x coordinate of the feature centroid
    size_t y; // y coordinate of the feature centroid
    size_t octave; // octave in which the feature is detected.
    float width; // width of the feature
    float height; // height of the feature
    float score; // feature strengh.
}

/**
 * Extract corners as array of 2D points, from response matrix.
 * 
 * params:
 * cornerResponse = Response matrix, collected as output from corner
 * detection algoritms such as harrisCorners, or shiTomasiCorners.
 * count = Number of corners which need to be extracted. Default is
 * -1 which indicate that all responses with value above the threshold
 * will be returned.
 * threshold = Response threshold - response values in the matrix
 * larger than this are considered as valid corners.
 * 
 * return:
 * Dynamic array of ulong[2], as in array of 2D points, of corner reponses 
 * which fit the given criteria.
 */
ulong [2][] extractCorners(T)(Slice!(2, T*) cornerResponse, 
    long count = -1, T threshold = cast(T)0) @trusted pure nothrow
    if (isNumeric!T)
{
    import std.algorithm : sort, map, min;
    import std.array : array;
    import std.range : take, iota;

    ulong [2] [float] features;

    if (cornerResponse.empty) {
        return typeof(return).init;
    }

    auto rows = cornerResponse.length!0;
    auto cols = cornerResponse.length!1;

    foreach(r; rows.iota) {
        foreach(c; cols.iota) {
            auto res = cornerResponse[r, c];
            if (res > threshold)
                features[res] = [r, c];
        }
    }

    return sort!"a > b"(features.keys)
        .take(count > 0 ? min(count, features.length) : features.length)
            .map!(a => features[a])
            .array;
}

unittest {
    auto image = [
        0., 0., 0.,
        0., 1., 0.,
        0., 0., 0.
    ].sliced(3, 3);

    auto res = image.extractCorners;

    assert(res.length == 1);
    assert(res[0] == [1, 1]);
}

unittest {
    auto image = [
        0., 0.1, 0.,
        0., 0.3, 0.,
        0., 0.2, 0.
    ].sliced(3, 3);

    auto res = image.extractCorners;

    assert(res.length == 3);
    assert(res[0] == [1, 1]);
    assert(res[1] == [2, 1]);
    assert(res[2] == [0, 1]);
}

unittest {
    auto image = [
        0., 0.1, 0.,
        0., 0.3, 0.,
        0., 0.2, 0.
    ].sliced(3, 3);

    auto res = image.extractCorners(1);

    assert(res.length == 1);
    assert(res[0] == [1, 1]);
}

unittest {
    auto image = [
        0., 0.1, 0.,
        0., 0.3, 0.,
        0., 0.2, 0.
    ].sliced(3, 3);

    auto res = image.extractCorners(-1, 0.2);

    assert(res.length == 1);
    assert(res[0] == [1, 1]);
}