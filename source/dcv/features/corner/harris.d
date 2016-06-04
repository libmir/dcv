module dcv.features.corner.harris;

private import std.experimental.ndslice;

private import dcv.core.utils : emptySlice;
private import dcv.imgproc.convolution : calcPartialDerivatives;


/**
 * Harris corner detector.
 */
Slice!(2, O*) harrisCorners(T, O = T)(Slice!(2, T*) image, in uint winSize = 3,
        in float k = .64, in float gauss = .84, Slice!(2, O*) prealloc = emptySlice!(2, O)) {
    HarrisDetector det;
    det.k = k;
    return calcCorners(image, winSize, gauss, prealloc, det);
}

/**
 * Shi-Tomasi good features to track corner detector.
 */
Slice!(2, O*) shiTomasiCorners(T, O = T)(Slice!(2, T*) image,
        in uint winSize = 3, in float gauss = .84, Slice!(2, O*) prealloc = emptySlice!(2, O)) {
    ShiTomasiDetector det;
    return calcCorners(image, winSize, gauss, prealloc, det);
}

unittest {
    import std.algorithm.comparison : equal;
    auto image = new float[9].sliced(3, 3);
    auto result = harrisCorners(image, 3, 0.64, 0.84);
    assert(result.shape[].equal(image.shape[]));
}

unittest {
    import std.algorithm.comparison : equal;
    import std.range : lockstep;
    auto image = new float[9].sliced(3, 3);
    auto resultBuffer = new double[9].sliced(3, 3);
    auto result = harrisCorners!(float, double)(image, 3, 0.64, 0.84, resultBuffer);
    assert(result.shape[].equal(image.shape[]));
    foreach(ref r1, ref r2; lockstep(result.byElement, resultBuffer.byElement)) {
        assert(&r1 == &r2);
    }
}

unittest {
    import std.algorithm.comparison : equal;
    auto image = new float[9].sliced(3, 3);
    auto result = shiTomasiCorners(image, 3, 0.84);
    assert(result.shape[].equal(image.shape[]));
}

unittest {
    import std.algorithm.comparison : equal;
    import std.range : lockstep;
    auto image = new float[9].sliced(3, 3);
    auto resultBuffer = new double[9].sliced(3, 3);
    auto result = shiTomasiCorners!(float, double)(image, 3, 0.84, resultBuffer);
    assert(result.shape[].equal(image.shape[]));
    foreach(ref r1, ref r2; lockstep(result.byElement, resultBuffer.byElement)) {
        assert(&r1 == &r2);
    }
}

private:

struct HarrisDetector {
    float k;

    float opCall(float r1, float r2, float r3) {
        return (((r1 * r1) - (r2 * r3)) - k * ((r1 + r3) * r1 + r3));
    }
}

struct ShiTomasiDetector {
    float opCall(float r1, float r2, float r3) {
        import std.math : sqrt;

        return ((r1 + r3) - sqrt((r1 - r3) * (r1 - r3) + r2 * r2));
    }
}

Slice!(2, O*) calcCorners(Detector, T, O)(Slice!(2, T*) image, uint winSize,
        float gaussSigma, Slice!(2, O*) prealloc, Detector detector) {

    import std.math : exp, PI;
    import std.array : uninitializedArray;
    import std.range : iota;
    import std.algorithm.iteration : reduce, each;
    import std.algorithm.comparison : equal;

    assert(!image.empty);

    if (!prealloc.shape[].equal(image.shape[])) {
        prealloc = uninitializedArray!(O[])(image.shape[].reduce!"a*b").sliced(image.shape);
    }
    prealloc[] = cast(O)0;

    auto rows = image.length!0;
    auto cols = image.length!1;

    Slice!(2, T*) fx, fy;
    calcPartialDerivatives(image, fx, fy);

    auto winSqr = winSize ^^ 2;
    auto winHalf = winSize / 2;

    float R; // Score value
    float w, gx, gy, r1, r2, r3;
    float gaussMul = 1.0f / (2.0f * PI * gaussSigma );
    float gaussDel = 2.0f * (gaussSigma^^2);

    foreach (i; winHalf.iota(rows - winHalf)) {
        foreach (j; winHalf.iota(cols - winHalf)) {
            r1 = 0.;
            r2 = 0.;
            r3 = 0.;
            for (int cr = cast(int)(i - winHalf); cr < i + winHalf; cr++) {
                for (int cc = cast(int)(j - winHalf); cc < j + winHalf; cc++) {
                    w = 1.0f; //gaussMul * exp(-((cast(float)cr - i)^^2 + (cast(float)cc - j)^^2) / gaussDel);

                    gx = fx[cr, cc];
                    gy = fy[cr, cc];
                    r1 += w * (gx * gx);
                    r2 += w * (gx * gy);
                    r3 += w * (gy * gy);
                }
            }
            r1 = (r1 / winSqr) * 0.5;
            r2 /= winSqr;
            r3 = (r3 / winSqr) * 0.5;
            R = detector(r1, r2, r3);
            if (R > 0)
                prealloc[i, j] = cast(O) R;
        }
    }
    return prealloc;
}
