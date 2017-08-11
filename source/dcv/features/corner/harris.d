/**
   Module implements $(LINK3 https://en.wikipedia.org/wiki/Corner_detection#The_Harris_.26_Stephens_.2F_Plessey_.2F_Shi.E2.80.93Tomasi_corner_detection_algorithms, Harris and Shi-Tomasi) corner detectors.

   Copyright: Copyright Relja Ljubobratovic 2016.

   Authors: Relja Ljubobratovic

   License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
 */
module dcv.features.corner.harris;

import std.traits: isFloatingPoint;

import mir.math.common : fastmath;

import mir.ndslice;
import mir.ndslice.algorithm: each;

import dcv.core.utils:emptySlice;
import dcv.imgproc.filter: calcPartialDerivatives;

import dcv.features.common;


alias HarrisKernel    = CornerKernel!HarrisFormula;
alias ShiTomasiKernel = CornerKernel!ShiTomasiFormula;

alias HarrisDetector    = CornerDetector!(HarrisProperties, HarrisKernel);
alias ShiTomasiDetector = CornerDetector!(ShiTomasiProperties, ShiTomasiKernel);

/**
   Create Harris corner detector using given algorithm properties.

   Params:
    properties = HarrisProperties instance, holding algorithm configuration.

   Returns:
    HarrisDetector instace built using given properties.
 */
auto harrisDetector(HarrisProperties properties)
{
    auto formula  = HarrisFormula(properties.sensitivity);
    auto kernel   = HarrisKernel(formula);
    auto detector = HarrisDetector(properties, kernel);

    return detector;
}

/**
   Create Shi-Tomasi corner detector using given algorithm properties.

   Params:
       properties = ShiTomasiProperties instance, holding algorithm configuration.

   Returns:
       ShiTomasiDetector instace built using given properties.
 */
auto shiTomasiDetector(ShiTomasiProperties properties)
{
    auto formula  = ShiTomasiFormula.init;
    auto kernel   = ShiTomasiKernel(formula);
    auto detector = ShiTomasiDetector(properties, kernel);

    return detector;
}

/// Harris corner detector algorithm properties.
struct HarrisProperties
{
    mixin CornerProperties;
    /// Algorithm sensitivity parameter. Smaller value means more corners will be detected.
    float sensitivity = 0.6f;
}

/// Harris corner detector algorithm properties.
struct ShiTomasiProperties
{
    mixin CornerProperties;
}

private mixin template CornerProperties()
{
    /// Size of the corner sampling window. Set larger window size to detect larger
    /// corners in the image. Window size has to be an odd number.
    uint windowSize = 3;
    /// Smoothing sigma value. Each corner sampling window is weighed according
    /// to gaussian kernel of same size, constructed using this sigma value.
    float gaussianSigma = 0.8f;
    /// Feature response threshold (0-1). Leave at 0 to return all possible responses as features.
    float featureThreshold = 0.0f;
    /// Maximal count of detected features. Leave at 0 to detect all possible responses as features.
    size_t maximumFeatures = 0;
    /// Non-maxima supression window size.
    size_t nonmaxWindowSize = 10;
}

/**
   Calculate per-pixel corner impulse response using Harris corner detector.

   Params:
    image       = Input image slice.

    pool        = TaskPool instance used parallelise the algorithm.

   Returns:
    Response matrix the same size of the input image, where each pixel represents
    corner response value - the bigger the value, more probably it represents the
    actual corner in the image.
 */
Slice!(Contiguous, [2], OutputType*)
harrisResponse(InputType, OutputType = InputType, SliceKind inputKind)
(
    Slice!(inputKind, [2], InputType*) image,
    HarrisProperties properties
)
in
{
    assert(!image.empty, "Empty image given.");
    assert(properties.windowSize % 2 != 0, "Kernel window size has to be odd.");
    assert(properties.gaussianSigma > 0.0, "Gaussian sigma value has to be greater than 0.");
    assert(properties.sensitivity > 0.0, "Sensitivity value has to be greater than 0.");
}
body
{
    auto detector = HarrisDetector(properties);
    return detector.calcResponse(image);
}

/**
   Calculate per-pixel corner impulse response using Shi-Tomasi corner detector.

   Params:
    image       = Input image slice.
    winSize     = Window (square) size used in corner detection.
    gauss       = Gauss sigma value used as window weighting parameter.
    prealloc    = Optional pre-allocated buffer for return response image.
    pool        = TaskPool instance used parallelise the algorithm.

   Returns:
    Response matrix the same size of the input image, where each pixel represents
    corner response value - the bigger the value, more probably it represents the
    actual corner in the image.
 */
Slice!(Contiguous, [2], OutputType*)
shiTomasiCornerResponse(InputType, OutputType = InputType, SliceKind inputKind)
(
    Slice!(inputKind, [2], InputType*) image,
    ShiTomasiProperties properties
)
in
{
    assert(!image.empty, "Empty image given.");
    assert(properties.windowSize % 2 != 0, "Kernel window size has to be odd.");
    assert(properties.gaussianSigma > 0.0, "Gaussian sigma value has to be greater than 0.");
}
body
{
    auto detector = ShiTomasiDetector(properties);
    return detector.calcResponse(image);
}

/**
   Corner detector algorithm base.

   Contains core routines common to Harris and Shi-Tomasi corner detectors.
 */
struct CornerDetector (Properties, Kernel)
{
    mixin BaseDetector;

    @disable this();

    this(Properties properties, Kernel kernel)
    {
        this.properties = properties;
        this.kernel     = kernel;
    }

    /**
       Calculate per-pixel response for this corner detector.
     */
    public
    auto calcResponse(size_t[] packs, T)
    (
        Slice!(Contiguous, packs, const(T)*) image,
    )
    in
    {
        assert(!image.empty, "Given image must not be empty.");
    }
    body
    {
        import mir.ndslice.topology:zip;
        import std.algorithm.comparison:max;

        Slice!(Contiguous, [2], T*) fx, fy;

        calcPartialDerivatives(image, fx, fy);

        immutable size_t ws  = properties.windowSize;
        immutable size_t wsh = max(1, ws / 2);

        return zip(fx, fy)
               .windows(ws, ws)
               .map!(w => kernel.evaluate!(typeof(w))(w));
    }

private:
    Feature[] evaluateImpl(size_t[] packs, T)
    (
        Slice!(Contiguous, packs, const(T)*) image
    )
    {
        import mir.math.sum:sum;
        import dcv.features.utils:extractFeaturesFromResponse;
        import dcv.imgproc.filter:filterNonMaximum;

        auto response = this
                        .calcResponse!(packs, T)(image)
                        .filterNonMaximum(properties.nonmaxWindowSize);

        auto s = response.sum;

        return response
               .map!(e => e / s)
               .slice
               .extractFeaturesFromResponse!(T*)(cast(int)properties.maximumFeatures, properties.featureThreshold);
    }

    Properties properties;
    Kernel     kernel;
}

struct CornerKernel (EigenvalueFormula)
{
    import mir.ndslice.slice:isSlice;

    this(EigenvalueFormula formula)
    {
        this.formula = formula;
    }

    @nogc nothrow @fastmath:

    auto evaluate(Window)
    (
        Window window
    ) if (isSlice!Window)
    {
        import mir.ndslice.algorithm:reduce;

        auto fx = unzip !'a' (window);
        auto fy = unzip !'b' (window);

        alias T = DeepElementType!(typeof(fx));

        static assert(isFloatingPoint!T,
                      "Processing element type of corner response matrix has to be of floating point type.");

        T[3] r = [0, 0, 0];

        T winSqr = cast(T)window.length !0;
        winSqr *= winSqr;

        r = reduce!sumResponse(r, fx, fy);

        r[0]  = (r[0] / winSqr)  * T(0.5);
        r[1] /= winSqr;
        r[2]  = (r[2] / winSqr) * 0.5f;

        return formula(r[0], r[1], r[2]);
    }

    static float[3] sumResponse(float [3] r, float gx, float gy)
    {
        return [r[0] + gx * gx, r[1] + gx * gy, r[2] + gy * gy];
    }

private:
    EigenvalueFormula formula;
}

struct HarrisFormula
{
    float k;

    this(float k)
    {
        this.k = k;
    }

    pure nothrow @nogc @safe @fastmath
    float opCall(float r1, float r2, float r3)
    {
        return (((r1 * r1) - (r2 * r3)) - k * ((r1 + r3) * r1 + r3));
    }
}

struct ShiTomasiFormula
{
    pure nothrow @nogc @safe @fastmath
    float opCall(float r1, float r2, float r3)
    {
        import mir.math.common : sqrt;
        return ((r1 + r3) - sqrt((r1 - r3) * (r1 - r3) + r2 * r2));
    }
}

