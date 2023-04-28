/**
Module contains $(LINK3 https://en.wikipedia.org/wiki/Lucas%E2%80%93Kanade_method, Lucas-Kanade) optical flow algorithm implementation.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.tracking.opticalflow.lucaskanade;

import std.math : PI, floor;

import dcv.core.utils : pool;
import dcv.imgproc.convolution;
import dcv.tracking.opticalflow.base;
public import dcv.imgproc.interpolate;
import std.array : staticArray;

import mir.ndslice;
import mir.rc;

import dplug.core;


/**
Lucas-Kanade optical flow method implementation.
*/
class LucasKanadeFlow : SparseOpticalFlow
{

    public
    {
        float sigma = 0.84f;
        RCArray!float cornerResponse;
        size_t iterationCount = 10;
    }

    @nogc nothrow:
    
    /**
    Lucas-Kanade optical flow algorithm implementation.
    
    Params:
        f1 = First frame image.
        f2 = Second frame image.
        points = points which are tracked.
        searchRegions = search region width and height for each point.
        flow = displacement values preallocated array.
        usePrevious = if algorithm should continue iterating by 
        using presented values in the flow array, set this to true.

    See:
        dcv.features.corner
    
    */
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
        import std.array : uninitializedArray;

        import mir.ndslice.allocation;
        import mir.ndslice.topology;
        import mir.algorithm.iteration : each;

        import dcv.core.algorithm : ranged, ranged;
        import dcv.imgproc.interpolate : linear;
        import dcv.imgproc.filter;
        import dcv.core.memory;

        const auto rows = f1.shape[0];
        const auto cols = f1.shape[1];
        const auto rl = cast(int)(rows - 1);
        const auto cl = cast(int)(cols - 1);
        const auto pointCount = points.length;
        const auto pixelCount = rows * cols;

        if (!usePrevious)
        {
            if (flow.length != pointCount)
                flow = uninitRCslice!(float[2])(pointCount);
            flow[] = [0.0f, 0.0f].staticArray;
        }
        
        import mir.ndslice.slice: sliced;

        Slice!(RCI!float, 2LU, SliceKind.contiguous) current, next;
        
        current = f1.rcslice;
        next = f2.rcslice;

        float gaussMul = 1.0f / (2.0f * PI * sigma);
        float gaussDel = 2.0f * (sigma ^^ 2);

        // Temporary buffers, used in algorithm -------------------------------
        // TODO: cache these in class, and reuse
        /*auto floatPool = [
            alignedAlloc!float(pixelCount), alignedAlloc!float(pixelCount),
            alignedAlloc!float(pixelCount), alignedAlloc!float(pixelCount)
        ].staticArray;*/
        //auto ubytePool = [alignedAlloc!ubyte(pixelCount), alignedAlloc!ubyte(pixelCount)].staticArray;

        /*scope (exit)
        {
            import std.algorithm.iteration : each;
            //floatPool[].each!(v => alignedFree(v));
            //ubytePool[].each!(v => alignedFree(v));
        }*/
        // --------------------------------------------------------------------

        auto f1s = uninitRCslice!float(rows, cols); //floatPool[0].sliced(rows, cols);
        auto f2s = uninitRCslice!float(rows, cols); //floatPool[1].sliced(rows, cols);
        auto fxs = uninitRCslice!float(rows, cols); //floatPool[2].sliced(rows, cols);
        auto fys = uninitRCslice!float(rows, cols); //floatPool[3].sliced(rows, cols);
        auto fxmask = uninitRCslice!ubyte(rows, cols); // ubytePool[0].sliced(rows, cols); 
        auto fymask = uninitRCslice!ubyte(rows, cols); // ubytePool[1].sliced(rows, cols); 


        f1s[] = current[];
        f2s[] = next[];

        fxs[] = 0.0f;
        fys[] = 0.0f;
        fxmask[] = ubyte(0);
        fymask[] = ubyte(0);

        // Fill-in masks where points are present
        //import std.range : lockstep;

        import mir.ndslice.iterator : ZipIterator;
        import std.algorithm : min;

        auto A = points.sliced(points.length);
        auto B = searchRegions.sliced(searchRegions.length);

        alias ItZ = ZipIterator!(typeof(A._iterator), typeof(B._iterator));
        auto zipp = ItZ(A._iterator, B._iterator);
        auto mlen = min(A.length, B.length);

        foreach(_; 0..mlen)
        {
            auto p = (*zipp).a;
            auto r = (*zipp).b;

            auto rb = cast(int)(p[0] - r[0] / 2.0f);
            auto re = cast(int)(p[0] + r[0] / 2.0f);
            auto cb = cast(int)(p[1] - r[1] / 2.0f);
            auto ce = cast(int)(p[1] + r[1] / 2.0f);

            import mir.utility : min, max;
            rb = max(1, rb);
            re = min(re, rl);
            cb = max(1, cb);
            ce = min(ce, cl);

            if (re - rb <= 0 || ce - cb <= 0)
                continue;

            fxmask[rb .. re, cb .. ce][] = ubyte(1);
            fymask[rb .. re, cb .. ce][] = ubyte(1);

            ++zipp;
        }

        f1s.conv(sobel!float(GradientDirection.DIR_X), fxs, fxmask);
        f1s.conv(sobel!float(GradientDirection.DIR_Y), fys, fymask);

        cornerResponse = RCArray!float(pointCount);

        auto next_ls = next.lightScope;

        auto iterable = iota(pointCount);

        void worker(int _i, int threadIndex) nothrow @nogc
        {
            import std.math : sqrt, exp;

            auto ptn = iterable[_i];

            auto p = points[ptn];
            auto r = searchRegions[ptn];

            auto rb = cast(int)(p[0] - r[0] / 2.0f);
            auto re = cast(int)(p[0] + r[0] / 2.0f);
            auto cb = cast(int)(p[1] - r[1] / 2.0f);
            auto ce = cast(int)(p[1] + r[1] / 2.0f);

            rb = rb < 1 ? 1 : rb;
            re = re > rl ? rl : re;
            cb = cb < 1 ? 1 : cb;
            ce = ce > cl ? cl : ce;

            if (re - rb <= 0 || ce - cb <= 0)
            {
                return;
            }

            float a1, a2, a3;
            float b1, b2;

            a1 = 0.0f;
            a2 = 0.0f;
            a3 = 0.0f;
            b1 = 0.0f;
            b2 = 0.0f;

            const auto rm = floor(cast(float)re - (r[0] / 2.0f));
            const auto cm = floor(cast(float)ce - (r[1] / 2.0f));

            foreach (iteration; 0 .. iterationCount)
            {
                foreach (i; rb .. re)
                {
                    foreach (j; cb .. ce)
                    {

                        const float nx = cast(float)j + flow[ptn][0];
                        const float ny = cast(float)i + flow[ptn][1];

                        if (nx < 0.0f || nx > cast(float)ce || ny < 0.0f || ny > cast(float)re)
                        {
                            continue;
                        }

                        // TODO: gaussian weighting produces errors - examine
                        float w = 1.0f; //gaussMul * exp(-((rm - cast(float)i)^^2 + (cm - cast(float)j)^^2) / gaussDel);

                        // TODO: consider subpixel precision for gradient sampling.
                        const float fx = fxs[i, j];
                        const float fy = fys[i, j];
                        const float ft = cast(float)(linear(next_ls, ny, nx) - current[i, j]);

                        const float fxx = fx * fx;
                        const float fyy = fy * fy;
                        const float fxy = fx * fy;

                        a1 += w * fxx;
                        a2 += w * fxy;
                        a3 += w * fyy;

                        b1 += w * fx * ft;
                        b2 += w * fy * ft;
                    }
                }

                // TODO: consider resp normalization...
                cornerResponse[ptn] = ((a1 + a3) - sqrt((a1 - a3) * (a1 - a3) + a2 * a2));

                auto d = (a1 * a3 - a2 * a2);

                if (d)
                {
                    d = 1.0f / d;
                    flow[ptn][0] += (a2 * b2 - a3 * b1) * d;
                    flow[ptn][1] += (a2 * b1 - a1 * b2) * d;
                }
            }
        }
        pool.parallelFor(cast(int)iterable.length, &worker);

        return flow;
    }
}

// TODO: implement functional tests.
version (unittest)
{
    import std.algorithm.iteration : map;
    import std.range : iota;
    import std.array : array;
    import std.random : uniform;

    private auto createImage()
    {
        return new Image(5, 5, ImageFormat.IF_MONO, BitDepth.BD_8,
                25.iota.map!(v => cast(ubyte)uniform(0, 255)).array);
    }
}

unittest
{
    LucasKanadeFlow flow = new LucasKanadeFlow;
    auto f1 = createImage();
    auto f2 = createImage();
    auto p = 10.iota.map!(v => cast(float[2])[cast(float)uniform(0, 2), cast(float)uniform(0, 2)]).array;
    auto r = 10.iota.map!(v => cast(float[2])[3.0f, 3.0f]).array;
    auto f = flow.evaluate(f1, f2, p, r);
    assert(f.length == p.length);
    assert(flow.cornerResponse.length == p.length);
}

unittest
{
    LucasKanadeFlow flow = new LucasKanadeFlow;
    auto f1 = createImage();
    auto f2 = createImage();
    auto p = 10.iota.map!(v => cast(float[2])[cast(float)uniform(0, 2), cast(float)uniform(0, 2)]).array;
    auto f = 10.iota.map!(v => cast(float[2])[cast(float)uniform(0, 2), cast(float)uniform(0, 2)]).array;
    auto r = 10.iota.map!(v => cast(float[2])[3.0f, 3.0f]).array;
    auto fe = flow.evaluate(f1, f2, p, r, f);
    assert(f.length == fe.length);
    assert(f.ptr == fe.ptr);
    assert(flow.cornerResponse.length == p.length);
}
