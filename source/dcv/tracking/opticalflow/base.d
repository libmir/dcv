module dcv.tracking.opticalflow.base;

public import std.experimental.ndslice : Slice;
public import dcv.core.image : Image;
public import dcv.core.utils : emptySlice;

interface SparseOpticalFlow {
    float[2][] evaluate(inout Image f1, inout Image f2, in float[2][] points,
            in float[2][] searchRegions, float[2][] prevflow = null, bool usePrevious = false);
}

alias DenseFlow = Slice!(3, float*);

interface DenseOpticalFlow {
    DenseFlow evaluate(inout Image f1, inout Image f2,
            DenseFlow prealloc = emptySlice!(3, float), bool usePrevious = false);
}
