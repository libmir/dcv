/**
Module contains utilities common for all algorithms which operate with feature points.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic, Ferhat Kurtulmuş

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.features.utils;

import std.traits : isNumeric;
import std.typecons : Tuple;
import std.math;
public import std.container.array : Array;

import mir.ndslice;
import mir.rc;

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
@nogc nothrow:

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
    import mir.appender;
    import std.typecons : Tuple;

    import mir.ndslice.sorting : sort;
    import mir.ndslice.topology : zip, flattened, ndiota;
    import std.array : _sa = staticArray;

    alias Pair = Tuple!(T, "value", size_t[2], "position");

    // TODO: test if corner response is contiguous, or better yet - change
    //       the implementation not to depend on contiguous slice.

    auto resultAppender = scopedBuffer!Pair;

    size_t r = 0, c;
    foreach(row; cornerResponse) {
        c = 0;
        foreach(value; row) {
            if (value > threshold) {
                resultAppender.put(Pair(value, [r, c]._sa));
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

    auto ret = result[].rcarray;
    return ret;
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

/++
    Returns euclidean distance between feature descriptor vectors.
+/
double euclideanDistBetweenDescriptors(DescriptorValueType)(const DescriptorValueType[] desc1, const DescriptorValueType[] desc2) 
{
    double sum = 0;
    foreach (i; 0 .. desc1.length) {
        const diff = desc1[i] - desc2[i];
        sum += diff * diff;
    }
    return sum.sqrt;
}

alias FeatureMatch = Tuple!(int, "index1", int, "index2", double, "distNearestNeighbor", double, "nearestNeighborDistanceRatio");
/++
    Returns an Array containing matched indices of the given Keypoints with brute force approach.
+/
Array!FeatureMatch
find_MatchingPointsBruteForce(KeyPoint)(const ref Array!KeyPoint keypoints1,
                     const ref Array!KeyPoint keypoints2, double threshold = 0.5)
{
    const num_keypoints1 = cast(int)keypoints1.length;
    auto vec_dim = keypoints1[0].descriptor.length;
    
    const num_keypoints2 = cast(int)keypoints2.length;

    Array!FeatureMatch matches;

    foreach(int index1; 0..num_keypoints1)
    {
        auto desc1 = keypoints1[index1].descriptor[];

        const(ubyte)[] nearest_n1;
        int nearest_n1_index = -1;
        double nearest_n1_dist = 100000000;

        const(ubyte)[] nearest_n2;
        int nearest_n2_index = -1;
        double nearest_n2_dist = 100000000;

        foreach(int index2; 0..num_keypoints2){
            auto desc2 = keypoints2[index2].descriptor[];

            double temp_dist = euclideanDistBetweenDescriptors(desc1, desc2);

            if (temp_dist < nearest_n1_dist)
            {
                nearest_n2 = nearest_n1;
                nearest_n2_index = nearest_n1_index;
                nearest_n2_dist = nearest_n1_dist;
                
                nearest_n1 = desc2[];
                nearest_n1_index = index2;
                nearest_n1_dist = temp_dist;
            }else if (temp_dist < nearest_n2_dist)
            {
                nearest_n2 = desc2[];
                nearest_n2_index = index2;
                nearest_n2_dist = temp_dist;
            }
        }

        double nndr = nearest_n1_dist / nearest_n2_dist;

        if (nndr < threshold)
            matches ~= FeatureMatch(index1, nearest_n1_index, nearest_n1_dist, nndr);
    }

    return matches;
}