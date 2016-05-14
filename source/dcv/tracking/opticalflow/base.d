
module dcv.tracking.opticalflow.base;

public import std.experimental.ndslice : Slice;
public import dcv.core.image : Image;
public import dcv.core.utils : emptySlice;

alias Flow = Slice!(3, float*);


interface DenseOpticalFlow {
    Flow evaluate(inout Image f1, inout Image f2, 
        Flow prealloc = emptySlice!(3, float), bool usePrevious = false);
}
