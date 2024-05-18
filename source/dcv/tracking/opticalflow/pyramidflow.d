/**
Module contains optical flow pyramid implementation.

Pyramidal optical flow evaluation in $(BIG DCV) is designed to be a wrapper to actual optical flow algorithm. $(LINK2 #SparesePyramidFlow, Sparse) and 
$(LINK2 #DensePyramidFlow, dense) optical flow algorithms have a corresponding utility class which will evaluate the algorithm 
in $(LINK3 https://en.wikipedia.org/wiki/Pyramid_(image_processing)#Gaussian_pyramid, pyramid), coarse-to-fine fashion.

----
// Evaluate Horn-Schunck method in pyramid.
HornSchunckFlow hsFlow = new HornSchunckFlow(props);
DensePyramidFlow densePyramid = new DensePyramidFlow(hsFlow, pyramidLevels); 

auto flow = densePyramid.evaluate(current, next);
----

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.tracking.opticalflow.pyramidflow;

import std.array : staticArray;
import mir.algorithm.iteration: each;

import dcv.core.utils : emptyRCSlice;
import dcv.core.image;
import dcv.imgproc.imgmanip : warp, resize;
import dcv.tracking.opticalflow.base;

import mir.ndslice.allocation;
import mir.ndslice.topology: as, flattened, iota, reshape;
import mir.ndslice : Contiguous;
import mir.rc;
import mir.exception;

import dplug.core.nogc;
/**
Sparse pyramidal optical flow utility class.
*/
class SparsePyramidFlow : SparseOpticalFlow
{

    private SparseOpticalFlow flowAlgorithm;
    private uint levelCount;

    @nogc nothrow:

    this(SparseOpticalFlow flow, uint levels)
    in
    {
        assert(flow !is null);
        assert(levels > 0);
    }
    do
    {
        flowAlgorithm = flow;
        levelCount = levels;
    }

    override Slice!(RCI!(float[2]), 1) evaluate(Slice!(float*, 2, Contiguous) f1, Slice!(float*, 2, Contiguous) f2, float[2][] points,
            float[2][] searchRegions, Slice!(RCI!(float[2]), 1) flow = emptyRCSlice!(1, float[2]), bool usePrevious = false)
    in
    {
        assert(!f1.empty && !f2.empty && f1.shape == f2.shape && f1.N == 2);
        assert(points.length == searchRegions.length);
        if (usePrevious)
        {
            assert(!flow.empty);
            assert(points.length == flow.length);
        }
    }
    do
    {
        import mir.ndslice.slice: sliced;

        size_t[2] size = [f1.shape[0], f1.shape[1]];
        const auto pointCount = points.length;

        // pyramid flow array - each item is double sized flow from the next
        size_t[2][] flowPyramid = mallocSlice!(size_t[2])(levelCount);
        scope(exit) freeSlice(flowPyramid);

        flowPyramid[$ - 1] = size;

        foreach_reverse (i; 0 .. (levelCount - 1))
        {
            size[] /= 2;
            if (size[0] < 1 || size[1] < 1){
                try enforce!"Pyramid downsampling exceeded minimal image size."(false);
                catch(Exception e) assert(false, e.msg);
            }
            flowPyramid[i] = size;
        }

        float[2] flowScale = [cast(float)f1.shape[0] / cast(float)flowPyramid[0][0],
            cast(float)f1.shape[1] / cast(float)flowPyramid[0][1]];

        float[2][] lpoints = mallocSlice!(float[2])(points.length); lpoints[] = points[]; // dup here
        scope(exit) freeSlice(lpoints);
        
        float[2][] lsearchRegions = mallocSlice!(float[2])(searchRegions.length); lsearchRegions[] = searchRegions[]; // dup here
        scope(exit) freeSlice(lsearchRegions);

        alias scale = (ref v) { v[0] /= flowScale[0]; v[1] /= flowScale[1]; };
        lpoints.sliced(lpoints.length).each!scale;
        lsearchRegions.sliced(lsearchRegions.length).each!scale;

        if (usePrevious)
        {
            flow.each!scale;
        }
        else
        {
            flow = uninitRCslice!(float[2])(pointCount);
            flow[] = [0.0f, 0.0f].staticArray;
        }

        auto h = f1.shape[0];
        auto w = f1.shape[1];

        Slice!(RCI!float, 2LU, Contiguous) current, next;

        // calculate pyramid flow

        foreach (i; 0 .. levelCount)
        {

            auto lh = flowPyramid[i][0];
            auto lw = flowPyramid[i][1];

            if (lh != h || lw != w)
            {
                current = f1.resize([lh, lw]);
                next = f2.resize([lh, lw]);
            }
            else
            {
                current = f1.rcslice;
                next = f2.rcslice;
            }

            flowAlgorithm.evaluate(current.lightScope, next.lightScope, lpoints,
                    lsearchRegions, flow, true);

            if (i < levelCount - 1)
            {
                alias twice = (ref v) { v[0] += v[0]; v[1] += v[1]; };
                flow.each!twice;
                lpoints.sliced(lpoints.length).each!twice;
                lsearchRegions.sliced(lsearchRegions.length).each!twice;
            }
        }

        return flow;
    }
}

/**
Dense pyramidal optical flow utility class.
*/
class DensePyramidFlow : DenseOpticalFlow
{

    private DenseOpticalFlow flowAlgorithm;
    private uint levelCount;

    @nogc nothrow:

    this(DenseOpticalFlow flow, uint levels)
    in
    {
        assert(flow !is null);
        assert(levels > 0);
    }
    do
    {
        flowAlgorithm = flow;
        levelCount = levels;
    }

    override DenseFlow evaluate(Slice!(float*, 2, Contiguous) f1, Slice!(float*, 2, Contiguous) f2, DenseFlow prealloc = emptyRCSlice!(3,
            float), bool usePrevious = false)
    in
    {
        assert(prealloc.length!2 == 2);
        assert(!f1.empty && f1.shape == f2.shape);
        if (usePrevious)
        {
            assert(prealloc.length!0 == f1.shape[0] && prealloc.length!1 == f1.shape[1]);
        }
    }
    do
    {
        import mir.ndslice.slice: sliced;
        
        size_t[2] size = f1.shape;
        uint level = 0;

        // pyramid flow array - each item is double sized flow from the next
        size_t[2][] flowPyramid = mallocSlice!(size_t[2])(levelCount);
        scope(exit) freeSlice(flowPyramid);

        flowPyramid[$ - 1] = size;

        DenseFlow flow;

        foreach_reverse (i; 0 .. (levelCount - 1))
        {
            size[] /= 2;
            if (size[0] < 1 || size[1] < 1){
                try enforce!"Pyramid downsampling exceeded minimal image size"(false);
                catch(Exception e) assert(false, e.msg);
            }
            flowPyramid[i] = size;
        }

        // allocate flow for each pyramid level
        if (usePrevious)
        {
            flow = prealloc.lightScope.resize(flowPyramid[0]);
        }
        else
        {
            flow = rcslice!float([flowPyramid[0][0], flowPyramid[0][1], 2], 0f);
        }

        auto h = f1.shape[0];
        auto w = f1.shape[1];

        Slice!(RCI!float, 2LU, Contiguous) current, next;

        // first flow used as indicator to skip the first warp.
        bool firstFlow = usePrevious;

        // calculate pyramid flow

        // we cannot use lightScope of current and next before the loop because 
        // refs of current and next changes with assignments like current = f1.rcslice;

        foreach (i; 0 .. levelCount)
        {
            auto lh = flow.length!0;
            auto lw = flow.length!1;

            if (lh != h || lw != w)
            {
                current = f1.resize([lh, lw]);
                next = f2.resize([lh, lw]);
            }
            else
            {
                current = f1.rcslice;
                next = f2.rcslice;
            }

            if (!firstFlow)
            {
                // warp the image using previous flow, 
                // except if this is the first level
                // or usePrevious is false.
                current = warp(current, flow);
            }

            // evaluate the flow algorithm
            auto lflow = flowAlgorithm.evaluate(current.lightScope, next.lightScope);

            // add flow calculated in this iteration to previous one.
            flow[] += lflow;

            if (i < levelCount - 1)
            {
                flow = flow.lightScope.resize(flowPyramid[i + 1]);
                flow[] *= 2.0f;
            }
            // assign the first flow indicator to false.
            firstFlow = false;
        }

        return flow;
    }

}

// TODO: implement functional tests.
version (unittest)
{
    private auto createImage()
    {
        import mir.random.variable: normalVar;
        import mir.random.algorithm: randomSlice;
        
        auto rndSlice = normalVar.randomSlice(32*32);

        auto imSlice = uninitRCslice!float(32,32);
        imSlice.flattened[0..$] = rndSlice[0..$].as!float;
        return imSlice;
    }

    class DummySparseFlow : SparseOpticalFlow
    {
        @nogc nothrow
        Slice!(RCI!(float[2]), 1) evaluate(Slice!(float*, 2, Contiguous) f1, Slice!(float*, 2, Contiguous) f2, float[2][] points,
            float[2][] searchRegions, Slice!(RCI!(float[2]), 1) prevflow = emptyRCSlice!(1, float[2]), bool usePrevious = false)
        {
            import std.array : uninitializedArray;

            return uninitRCslice!(float[2])(points.length);
        }
    }

    import mir.ndslice;

    class DummyDenseFlow : DenseOpticalFlow
    {
        @nogc nothrow
        DenseFlow evaluate(Slice!(float*, 2, Contiguous) f1, Slice!(float*, 2, Contiguous) f2, DenseFlow prealloc = emptyRCSlice!(3, float),
            bool usePrevious = false)
        {
            return RCArray!float(f1.shape[0] * f1.shape[1] * 2).moveToSlice.sliced(f1.shape[0], f1.shape[1], 2);
        }
    }
}

unittest
{
    import std.random, std.array;
    import std.range;
    import std.algorithm.iteration;

    auto rnd = Random(unpredictableSeed);

    SparsePyramidFlow flow = new SparsePyramidFlow(new DummySparseFlow, 3);
    auto f1 = createImage();
    auto f2 = createImage();
    auto p = 10.iota.map!(v => cast(float[2])[cast(float)uniform(0, 2, rnd), cast(float)uniform(0, 2, rnd)]).array;
    auto r = 10.iota.map!(v => cast(float[2])[3.0f, 3.0f]).array;
    auto f = flow.evaluate(f1.lightScope, f2.lightScope, p, r);
    assert(f.length == p.length);
}

unittest
{
    DensePyramidFlow flow = new DensePyramidFlow(new DummyDenseFlow, 3);
    auto f1 = createImage();
    auto f2 = createImage();
    auto f = flow.evaluate(f1.lightScope, f2.lightScope);
    assert(f.length!0 == f1.shape[0] && f.length!1 == f1.shape[1] && f.length!2 == 2);
}
