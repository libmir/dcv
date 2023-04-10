/**
Module introduces the API that defines Optical Flow utilities in the dcv library.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.tracking.opticalflow.base;

public import mir.ndslice.slice : Slice, SliceKind;
import mir.rc;
public import dcv.core.image : Image;
public import dcv.core.utils : emptyRCSlice;

/**
Sparse Optical Flow algorithm interface.
*/
interface SparseOpticalFlow
{

    /**
    Evaluate sparse optical flow method between two consecutive frames.

    Params:
        f1              = First frame image.
        f2              = Second frame image.
        points          = points which are tracked.
        searchRegions   = search region width and height for each point.
        prevflow            = displacement values preallocated array.
        usePrevious     = if algorithm should continue iterating by 
                          using presented values in the flow array, set this to true.

    Returns:
        Array of 2 floating point values which represent movement of each given feature point, from f1 to f2.
    */
    @nogc nothrow
    Slice!(RCI!(float[2]), 1) evaluate(Image f1, Image f2, float[2][] points,
            float[2][] searchRegions, Slice!(RCI!(float[2]), 1) prevflow = emptyRCSlice!(1, float[2]), bool usePrevious = false);
}

/// Alias to a type used to define the dense optical flow field.
alias DenseFlow = Slice!(RCI!float, 3LU, SliceKind.contiguous);

/**
Dense Optical Flow algorithm interface.
*/
interface DenseOpticalFlow
{
    /**
    Evaluate dense optical flow method between two consecutive frames.

    Params:
        f1          = First image, i.e. previous frame in the video.
        f2          = Second image of same size and type as $(D f1), i.e. current frame in the video.
        prealloc    = Optional pre-allocated flow buffer. If provided, has to be of same size as input images are, and with 2 channels (u, v).
        usePrevious = Should the previous flow be used. If true $(D prealloc) is treated as previous flow, and has to satisfy size requirements.

    Returns:
        Calculated flow field.
    */
    @nogc nothrow
    DenseFlow evaluate(Image f1, Image f2, DenseFlow prealloc = emptyRCSlice!(3, float),
            bool usePrevious = false);
}
