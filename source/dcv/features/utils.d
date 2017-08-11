/**
   Module contains utilities common for all algorithms which operate with feature points.

   Copyright: Copyright Relja Ljubobratovic 2016.

   Authors: Relja Ljubobratovic

   License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
 */

module dcv.features.utils;

import std.traits: isNumeric;

import mir.ndslice;

import dcv.features.common: Feature;

/**
   Extract features from response matrix.

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
Feature[] extractFeaturesFromResponse(Iterator)
(
    Slice!(Contiguous, [2], Iterator) cornerResponse,
    int count = -1,
    DeepElementType!(Slice!(Contiguous, [2], Iterator) ) threshold = 0
)
in
{
    assert(!cornerResponse.empty, "Corner response matrix should not be empty.");
}
body
{
    import std.array:Appender;
    import std.typecons:Tuple;
    import std.algorithm.comparison: min;

    import mir.ndslice.sorting:sort;
    import mir.ndslice.topology:zip, flattened, ndiota;

    auto resultAppender = Appender!(Feature[])();

    size_t r = 0, c;
    foreach(row; cornerResponse)
    {
        c = 0;
        foreach(score; row)
        {
            if (score > threshold)
            {
                resultAppender.put(Feature(c, r, 0, 0, 0, cast(float)score));
            }
            c++;
        }
        r++;
    }

    auto result = resultAppender
                  .data
                  .sliced;

    if (!result.empty)
    {

        result = result.sort!((a, b) => a.score > b.score);
    }


    if (count > 0)
    {
        result = result[0..min(count, $)];
    }

    return result.field;
}

///
// unittest
// {
//     auto image = [0., 0., 0.,
//                   0., 1., 0.,
//                   0., 0., 0.].sliced(3, 3);

//     auto res = image.extractCorners;

//     assert(res.length == 1);
//     assert(res[0] == [1, 1]);
// }

///
// unittest
// {
//     auto image = [0., 0.1, 0.,
//                   0., 0.3, 0.,
//                   0., 0.2, 0.].sliced(3, 3);

//     auto res = image.extractCorners;

//     assert(res.length == 3);
//     assert(res[0] == [1, 1]);
//     assert(res[1] == [2, 1]);
//     assert(res[2] == [0, 1]);
// }

///
// unittest
// {
//     auto image = [0., 0.1, 0.,
//                   0., 0.3, 0.,
//                   0., 0.2, 0.].sliced(3, 3);

//     auto res = image.extractCorners(1);

//     assert(res.length == 1);
//     assert(res[0] == [1, 1]);
// }

// ///
// unittest
// {
//     auto image = [0., 0.1, 0.,
//                   0., 0.3, 0.,
//                   0., 0.2, 0.].sliced(3, 3);

//     auto res = image.extractCorners(-1, 0.2);

//     assert(res.length == 1);
//     assert(res[0] == [1, 1]);
// }

