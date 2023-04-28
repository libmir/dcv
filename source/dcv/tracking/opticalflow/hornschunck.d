/**
Module contains $(LINK3 https://en.wikipedia.org/wiki/Horn%E2%80%93Schunck_method, Horn-Schunck) optical flow algorithm implementation.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.tracking.opticalflow.hornschunck;

import mir.ndslice;
import mir.rc;

import dcv.tracking.opticalflow.base;
import dcv.core.utils : emptyRCSlice;

public import dcv.tracking.opticalflow.base : DenseFlow;

/**
Horn-Schunck algorithm properties.
*/
struct HornSchunckProperties
{
    /// How many iterations is algorithm evaluated to estimate the flow values.
    size_t iterationCount = 100;
    /// Smoothing weight parameter for the flow field.
    float alpha = 20;
    /// Size of the gaussian kernel used to blur the image as pre-process step before the algorithm.
    size_t gaussKernelSize = 5;
    /// Sigma value of gaussian kernel used to blur the image.
    float gaussSigma = 2;
    /// iteration stopping criterion.
    float tol = 1.0e-06;
}

/**
Horn-Schunck algorithm implementation.
*/
class HornSchunckFlow : DenseOpticalFlow
{
    private
    {
        Slice!(RCI!float, 2LU, SliceKind.contiguous) current;
        Slice!(RCI!float, 2LU, SliceKind.contiguous) next;
        HornSchunckProperties props;
    }

    @nogc nothrow:

    /**
    Initialize the algorithm with given set of properties.
    */
    this(HornSchunckProperties props = HornSchunckProperties())
    {
        this.props = props;
    }

    ~this()
    {
    }

    /**
    Evaluate Horn-Schunck dense optical flow method between two consecutive frames.

    Params:
        f1 = First image, i.e. previous frame in the video.
        f2 = Second image of same size and type as $(D f1), i.e. current frame in the video.
        prealloc = Optional pre-allocated flow buffer. If provided, has to be of same size as input images are, and with 2 channels (u, v).
        usePrevious = Should the previous flow be used. If true $(D prealloc) is treated as previous flow, and has to satisfy size requirements.
    
    Returns:
        Calculated flow field.
    */
    override DenseFlow evaluate(Slice!(float*, 2, Contiguous) f1, Slice!(float*, 2, Contiguous) f2, DenseFlow prealloc = emptyRCSlice!(3,
            float), bool usePrevious = false)
    in
    {
        assert(!f1.empty && !f2.empty && f1.N == 2 && f1.shape == f2.shape);
        if (usePrevious)
        {
            assert(prealloc.length!0 == f1.shape[0] && prealloc.length!1 == f1.shape[1] && prealloc.length!2 == 2);
        }
    }
    do
    {
        size_t height = f1.shape[0];
        size_t width = f1.shape[1];
        import mir.ndslice.allocation;
        import mir.ndslice.topology;
        if (current.shape == [height, width] && next.shape == [height, width])
        {
            current[] = f1[];
            next[] = f2[];
        }
        else
        {
            current = f1.rcslice;
            next = f2.rcslice;
        }

        if (prealloc.shape[0 .. 2] != current.shape)
            prealloc = rcslice!float([current.length!0, current.length!1, 2], 0.0f);
        else if (!usePrevious)
            prealloc[] = 0.0f;

        // smooth images
        if (props.gaussSigma)
        {
            import dcv.imgproc.filter : gaussian;
            import dcv.imgproc.convolution;
            import dcv.core.utils : neumann;

            auto g = gaussian!float(props.gaussSigma, props.gaussKernelSize, props.gaussKernelSize);

            current = conv!neumann(current, g);
            next = conv!neumann(next, g);
        }

        int iter = 0;
        float err = props.tol;

        auto flow_b = rcslice!float(prealloc.shape);

        auto const rows = cast(int)current.length!0;
        auto const cols = cast(int)current.length!1;
        auto const a2 = props.alpha * props.alpha;

        while (++iter < props.iterationCount && err >= props.tol)
        {
            err = 0;
            flow_b[] = prealloc[];
            hsflowImpl(rows, cols, current.ptr, next.ptr, flow_b.ptr, prealloc.ptr, a2, err);
        }

        return prealloc;
    }
}

// TODO: implement functional tests.
unittest
{
    HornSchunckFlow flow = new HornSchunckFlow;
    auto f1 = new Image(3, 3, ImageFormat.IF_MONO, BitDepth.BD_8);
    auto f2 = new Image(3, 3, ImageFormat.IF_MONO, BitDepth.BD_8);
    auto f = flow.evaluate(f1, f2);
    assert(f.length!0 == f1.height && f.length!1 == f1.width && f.length!2 == 2);
}

unittest
{
    HornSchunckFlow flow = new HornSchunckFlow;
    auto f1 = new Image(3, 3, ImageFormat.IF_MONO, BitDepth.BD_8);
    auto f2 = new Image(3, 3, ImageFormat.IF_MONO, BitDepth.BD_8);
    auto f = new float[9 * 2].sliced(3, 3, 2);
    auto fe = flow.evaluate(f1, f2, f);
    assert(f.shape[] == fe.shape[]);
    assert(&f[0, 0, 0] == &fe[0, 0, 0]);
}

private:

nothrow @nogc void hsflowImpl(in int rows, in int cols, float* current, float* next, float* flow_b,
        float* prealloc, float a2, ref float err)
{

    immutable div12 = (1.0f / 12.0f);
    immutable div6 = (1.0f / 6.0f);

    auto const cols2 = cols * 2;

    foreach (i; 1 .. rows - 1)
    {
        auto const ro = i * cols; // row offset
        foreach (j; 1 .. cols - 1)
        {

            auto fx_val = ((current[ro + j - 1] - current[ro + j]) + (next[ro + j - 1] - next[ro + j])) / 2.0f;
            auto fy_val = ((current[(i - 1) * cols + j] - current[ro + j]) + (next[(i - 1) * cols + j] - next[ro + j])) / 2.0f;
            auto ft_val = next[ro + j] - current[ro + j];

            auto prev_u = flow_b[ro * 2 + j * 2];
            auto prev_v = flow_b[ro * 2 + j * 2 + 1];

            auto u_val = div12 * (flow_b[(i - 1) * cols2 + (j - 1) * 2] + flow_b[(i - 1) * cols2 + (
                    j + 1) * 2] + flow_b[(i + 1) * cols2 + (j - 1) * 2] + flow_b[(i + 1) * cols2 + (j + 1) * 2])
                + div6 * (flow_b[i * cols2 + (j - 1) * 2] + flow_b[(i - 1) * cols2 + j * 2] + flow_b[(
                        i + 1) * cols2 + j * 2] + flow_b[i * cols2 + (j + 1) * 2]);
            auto v_val = div12 * (flow_b[(i - 1) * cols2 + (j - 1) * 2 + 1] + flow_b[(i - 1) * cols2 + (
                    j + 1) * 2 + 1] + flow_b[(i + 1) * cols2 + (j - 1) * 2 + 1] + flow_b[(i + 1) * cols2 + (j + 1)
                    * 2 + 1]) + div6 * (flow_b[i * cols2 + (j - 1) * 2 + 1] + flow_b[(
                    i - 1) * cols2 + j * 2 + 1] + flow_b[(i + 1) * cols2 + j * 2 + 1] + flow_b[i * cols2 + (j + 1)
                    * 2 + 1]);

            auto p = fx_val * u_val + fy_val * v_val + ft_val;
            auto d = (a2 + fx_val * fx_val + fy_val * fy_val);

            if (p && d)
                p /= d;
            else
                p = 0.0f;

            prealloc[i * cols2 + j * 2] = u_val - (fx_val * p);
            prealloc[i * cols2 + j * 2 + 1] = v_val - (fy_val * p);

            err += (prealloc[i * cols2 + j * 2] - prev_u) * (prealloc[i * cols2 + j * 2] - prev_u) + (
                    (prealloc[i * cols2 + j * 2 + 1] - prev_v) * (prealloc[i * cols2 + j * 2 + 1] - prev_v));

        }
    }
}
