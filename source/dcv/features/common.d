/**
   Module introduces the common types and utilities that define feature detection, description and matching API in the dcv library.

   Copyright: Copyright Relja Ljubobratovic 2016.

   Authors: Relja Ljubobratovic

   License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
 */
module dcv.features.common;


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
   Feature detector base mixin.
 */
mixin template BaseDetector()
{
    /**
       Detector features in the image.

       Params:
        image = Image in which features are looked for.
        count = How many features are to be extracted from given image.
     */
    public
    Feature[] evaluate(size_t[] packs, T)
    (
        Slice!(Contiguous, packs, const(T)*) image
    ) const
    in
    {
        assert(image.empty, "Given image should not be empty.");
        assert(packs.length == 2 || packs.length == 3, "Given image must be a two or three-dimensional slice.");
    }
    body
    {
        return evaluateImpl(image);
    }
}

/**
   Feature descriptor base mixin.
 */
mixin template BaseDescriptor(T)
{
    import mir.ndslice.slice:ContiguousMatrix;

    /**
       Array of descriptors - m-by-n matrix, where m is the number of
       descriptors, and n is the dimensionality (size) of the descritor.
     */
    public alias DescriptorArray = ContiguousMatrix!T;

    public
    DescriptorArray evaluate(size_t[] packs, T)
    (
        Slice!(Contiguous, packs, const(T)*) image
    ) const
    {
        return(evaluateImpl(image));
    }
}

