/**
   Module implements FAST<sup>[1]</sup> corner detector algorithm - Features from accelerated segment test (FAST) algorithm
   discovered and developed by Edward Rosten and Tom Drummond.

   This package offers D class interface to machine generated C code, adopted
   to D, which is located originally on $(LINK3 https://github.com/edrosten/fast-C-src, Edward Rosten's github).

   Copyright: Copyright (c) 2006, 2008 Edward Rosten, Relja Ljubobratovic 2016

   Authors: Edward Rosten, Relja Ljubobratovic

   License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).

   1. Edward Rosten, Tom Drummond (2005). "Fusing points and lines for high performance tracking", IEEE International Conference on Computer Vision 2: 1508–1511.
 */
module dcv.features.corner.fast;

import mir.ndslice;

import dcv.features.corner.fast.base:xy;
import dcv.features.corner.fast.fast_9;
import dcv.features.corner.fast.fast_10;
import dcv.features.corner.fast.fast_11;
import dcv.features.corner.fast.fast_12;
import dcv.features.corner.fast.nonmax;

public import dcv.features.common;

/**
   FAST corner detector utility.
 */
// class FASTDetector : Detector
// {
//     public
//     {
//         /// Should the non-maximum suppression be performed with the detection.
//         static immutable PERFORM_NON_MAX_SUPRESSION = 0x0100;
//         /// Should the features be sorted by score at the output.
//         static immutable SORT_OUT_FEATURES_BY_SCORE = 0x0200;
//     }

//     /// Pixel neighborhood type, described in the paper.
//     public enum Type
//     {
//         FAST_9,
//         FAST_10,
//         FAST_11,
//         FAST_12,
//     }

//     private
//     {
//         uint _threshold;
//         Type _type;
//         int _flags;
//     }

//     /**
//     Default constructor.

//     Params:
//     threshold = Threshold on pixel intensity difference between central and border pixels.
//     type = Pixel neighborhood type.
//     flags = Flag value where <i>PERFORM_NON_MAX_SUPRESSION</i> and/or <i>SORT_OUT_FEATURES_BY_SCORE</i> flags can be passed.
//     */
//     @safe pure nothrow this(uint threshold = 100, Type type = Type.FAST_9, int flags = 0)
//     {
//         assert(threshold > 0);
//         this._threshold = threshold;
//         this._type = type;
//         this._flags = flags;
//     }

//     /// Threshold for corner detection.
//     auto threshold() const @property @safe pure nothrow @nogc
//     {
//         return _threshold;
//     }
//     /// Threshold value setter.
//     auto threshold(uint value) @property @safe pure nothrow @nogc
//     {
//         assert(value > 0);
//         _threshold = value;
//     }

//     /// Type of the detector.
//     auto type() const @property @safe pure nothrow @nogc
//     {
//         return _type;
//     }
//     /// ditto
//     auto type(Type type) @property @safe pure nothrow @nogc
//     {
//         _type = type;
//     }
//     /// Algorithm flags.
//     auto flags() const @property @safe pure nothrow @nogc
//     {
//         return _flags;
//     }

//     /**
//     Detect features for given image.

//     Params:
//     image = Input image where corners are to be found. Only 8-bit mono image is supported as this time.
//     count = How many corners are to be found.

//     Returns:
//     Array of found feature points.
//     */
//     override Feature[] detect(in Image image, size_t count = 0) const
//     {
//         import core.stdc.stdlib : free;
//         import std.exception : enforce;
//         import std.algorithm : min;

//         enforce(image.depth == BitDepth.BD_8, "Invalid bit depth - FAST is supported so " ~ "far only for 8-bit images");
//         enforce(image.channels == 1, "Invalid image format - has to be mono");

//         Feature[] features; // output features
//         int featureCount = 0; // feature count - internal use
//         int* featureScore = null; // feature score intenal use
//         xy* xyFeatures = null; // xy (feature coordinate) array - internal use

//         scope (exit)
//         {
//             free(featureScore);
//             free(xyFeatures);
//         }

//         xy* function(const ubyte*, int, int, int, int, int*) detectFunc;
//         int* function(const ubyte* i, int stride, xy* corners, int num_corners, int b) scoreFunc;

//         final switch (_type)
//         {
//         case Type.FAST_9:
//             detectFunc = &fast9_detect;
//             scoreFunc = &fast9_score;
//             break;
//         case Type.FAST_10:
//             detectFunc = &fast10_detect;
//             scoreFunc = &fast10_score;
//             break;
//         case Type.FAST_11:
//             detectFunc = &fast11_detect;
//             scoreFunc = &fast11_score;
//             break;
//         case Type.FAST_12:
//             detectFunc = &fast12_detect;
//             scoreFunc = &fast12_score;
//         }

//         xyFeatures = detectFunc(cast(const ubyte*)image.data.ptr, cast(int)image.width,
//                 cast(int)image.height, cast(int)image.rowStride, cast(int)threshold, &featureCount);

//         if (flags & FASTDetector.PERFORM_NON_MAX_SUPRESSION)
//         {
//             int nonMaxFeatureCount = 0;
//             xy* xySuppressed = null;

//             featureScore = scoreFunc(cast(ubyte*)image.data.ptr, cast(int)image.rowStride,
//                     xyFeatures, featureCount, cast(int)threshold);

//             xySuppressed = nonmax_suppression(xyFeatures, featureScore, featureCount, &nonMaxFeatureCount);


/// Pixel neighborhood type, described in the paper.
enum FASTType
{
    t9,
    t10,
    t11,
    t12,
}

struct FASTProperties
{
    /// corner threshold
    uint threshold = 100;
    /// should non-max suporession be performed.
    bool suppressnm = true;
    /// type of the detector
    FASTType type = FASTType.t9;
}


auto fastDetector(FASTProperties properties)
{
    return FASTDetector(properties);
}

/**
   FAST corner detector utility.
 */
struct FASTDetector
{
    mixin BaseDetector;

    @disable this();

    this(FASTProperties properties)
    {
        this.properties = properties;
    }

private:
    /**
       Detect features for given image.

       Properties.
       image = Input image where corners are to be found. Only 8-bit mono image is supported as this time.
       count = How many corners are to be found.

       Returns:
       Array of found feature points.
     */
    Feature[] evaluateImpl(size_t[] packs, T)
    (
        Slice!(Contiguous, packs, const(T)*) image
    )
    {
        import core.stdc.stdlib : free;
        enum errMsg = "FAST detector is only available for 8bit mono images.";

        static assert(is (T == ubyte), errMsg);

        Feature[] features;            // output features
        int       featureCount = 0;    // feature count - internal use
        int*      featureScore = null; // feature score intenal use
        xy*       xyFeatures   = null; // xy (feature coordinate) array - internal use

        const auto imdata      = image.iterator;
        const auto imwidth     = cast(int)image.length !1;
        const auto imheight    = cast(int)image.length !0;
        const auto imrowstride = imwidth;

        scope (exit)
        {
            free(featureScore);
            free(xyFeatures);
        }

        xy* function(const ubyte*, int, int, int, int, int*) detectFunc;
        int* function(const ubyte* i, int stride, xy* corners, int num_corners, int b) scoreFunc;

        final switch (properties.type)
        {
        case FASTType.t9:
            detectFunc = &fast9_detect;
            scoreFunc  = &fast9_score;
            break;
        case FASTType.t10:
            detectFunc = &fast10_detect;
            scoreFunc  = &fast10_score;
            break;
        case FASTType.t11:
            detectFunc = &fast11_detect;
            scoreFunc  = &fast11_score;
            break;
        case FASTType.t12:
            detectFunc = &fast12_detect;
            scoreFunc  = &fast12_score;
        }

        xyFeatures = detectFunc(imdata, imwidth, imheight, imrowstride, properties.threshold, &featureCount);

        if (properties.suppressnm)
        {
            import core.stdc.stdlib : free;

            int nonMaxFeatureCount = 0;
            xy* xySuppressed       = null;

            featureScore = scoreFunc(imdata, imrowstride, xyFeatures, featureCount, cast(int)properties.threshold);
            xySuppressed = nonmax_suppression(xyFeatures, featureScore, featureCount, &nonMaxFeatureCount);

            // free the score before the suppresion
            free(featureScore);
            featureScore = null;

            // assign new feature count after the suppression
            featureCount = nonMaxFeatureCount;

            // free previous features and assign new ones.
            free(xyFeatures);
            xyFeatures = xySuppressed;
        }

        featureScore = scoreFunc(imdata, imrowstride, xyFeatures, featureCount, cast(int)properties.threshold);

        // Convert FAST results to features
        features.length = featureCount;
        foreach (i, ref feature; features)
        {
            feature.x      = xyFeatures[i].x;
            feature.y      = xyFeatures[i].y;
            feature.width  = 16.;
            feature.height = 16.;
            feature.octave = 0;
            feature.score  = featureScore[i];
        }

        return features;
    }

    FASTProperties properties;
}

