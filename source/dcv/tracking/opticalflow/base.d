
module dcv.tracking.opticalflow.base;

public import std.experimental.ndslice : Slice;
public import dcv.core.image : Image;
public import dcv.core.utils : emptySlice;


alias DenseFlow = Slice!(3, float*);

interface DenseOpticalFlow {
    DenseFlow evaluate(inout Image f1, inout Image f2, 
        DenseFlow prealloc = emptySlice!(3, float), bool usePrevious = false);
}
