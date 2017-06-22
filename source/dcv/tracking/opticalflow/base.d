/**
   Module introduces the API that defines Optical Flow utilities in the dcv library.

   Copyright: Copyright Relja Ljubobratovic 2016.

   Authors: Relja Ljubobratovic

   License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
 */
module dcv.tracking.opticalflow.base;

import mir.ndslice.slice;
import dcv.core.types;

/**
   Sparse Optical Flow algorithm interface.
 */
// mixin template BaseSparseOpticalFlow()
// {
//     /**
//        Evaluate sparse optical flow method between two consecutive frames.

//        Params:
//         currentFrame  = First frame image.
//         nextFrame     = Second frame image.
//         currentPoints = points which are tracked.
//         nextPoints    = tracked (result) points.
//         usePrevious   = if algorithm should continue iterating by
//                           using presented values in the flow array, set this to true.

//        Returns:
//         Array of 2 floating point values which represent movement of each given feature point, from f1 to f2.
//      */
//     void evaluate(size_t[] packs, T, P)
//     (
//         Slice!(Contiguous, packs, const(T*)) currentFrame,
//         Slice!(Contiguous, packs, const(T*)) nextFrame,
//         in Point!P[] currentPoints,
//         out Point!P[] NextPoints,
//         bool usePrevious = false);
// }

/**
   Dense Optical Flow algorithm interface.
 */
// mixin template BaseDenseOpticalFlow()
// {
//     /**
//        Evaluate dense optical flow method between two consecutive frames.

//        Params:
//         f1          = First image, i.e. previous frame in the video.
//         f2          = Second image of same size and type as $(D f1), i.e. current frame in the video.
//         prealloc    = Optional pre-allocated flow buffer. If provided, has to be of same size as input images are, and with 2 channels (u, v).
//         usePrevious = Should the previous flow be used. If true $(D prealloc) is treated as previous flow, and has to satisfy size requirements.

//        Returns:
//         Calculated flow field.
//      */
//     void evaluate(inout Image f1, inout Image f2, DenseFlow prealloc = emptySlice!([3], float),
//                   bool usePrevious = false);
// }

