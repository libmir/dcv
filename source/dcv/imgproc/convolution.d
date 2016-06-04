module dcv.imgproc.convolution;

/**
 * Module introduces array convolution functions.
 * 
 * v0.1 norm:
 * conv (done)
 * separable_conv
 * 
 * v0.1+ plans:
 * 1d_conv_simd
 */
private import dcv.core.memory;
private import dcv.core.utils;

private import std.traits : isAssignable;
private import std.range;
private import std.algorithm.comparison : equal;

private import std.experimental.ndslice;

private import std.algorithm.iteration : reduce;
private import std.algorithm.comparison : max, min;
private import std.exception : enforce;
private	import std.parallelism : parallel;
private	import std.math : abs, floor;


/**
 * Perform convolution to given range, using given kernel.
 * Convolution is supported for 1, 2, and 3D slices.
 * 
 * params:
 * range = Input range slice (1D, 2D, and 3D slice supported)
 * kernel = Convolution kernel slice. For 1D range, 1D kernel is expected. 
 * For 2D range, 2D kernele is expected. For 3D range, 2D or 3D kernel is expected - 
 * if 2D kernel is given, each item in kernel matrix is applied to each value in 
 * corresponding 2D coordinate in the range.
 * prealloc = Pre-allocated array where convolution result can be stored. Default 
 * value is emptySlice, where resulting array will be newly allocated. Also if
 * prealloc is not of same shape as input range, resulting array will be newly allocated. 
 * mask = Masking range. Convolution will skip each element where mask is 0. Default value
 * is empty slice, which tells that convolution will be performed on the whole range.
 */
Slice!(N, V*) conv(alias bc = neumann, V, K, size_t N, size_t NK)(Slice!(N, V*) range, Slice!(NK, K*) kernel, 
    Slice!(N, V*) prealloc = emptySlice!(N, V),
    Slice!(NK, V*) mask = emptySlice!(NK, V))
{
    static assert(isBoundaryCondition!bc, "Invalid boundary condition test function.");
    static assert(isAssignable!(V, K), "Uncompatible types for range and kernel");

    if (!mask.empty && !mask.shape[].equal(range.shape[])) {
        import std.conv : to;
        throw new Exception("Invalid mask shape: " ~ mask.shape[].to!string ~ 
            ", range shape: " ~ range.shape[].to!string);
    }

    static if (N == 1) {
        static assert(NK == 1, "Invalid kernel dimension");
        return conv1Impl!bc(range, kernel, prealloc, mask);
    } else static if (N == 2) {
        static assert(NK == 2,  "Invalid kernel dimension");
        return conv2Impl!bc(range, kernel, prealloc, mask);
    } else static if (N == 3) {
        static assert(NK == 2, "Invalid kernel dimension");
        return conv3Impl!bc(range, kernel, prealloc, mask);
    } else {
        import std.conv : to;
        static assert(0, "Convolution over " ~ N.to!string ~ "D ranges is not implemented");
    }
}

unittest {
    import std.math : approxEqual;
    auto r1 = [0., 1., 2., 3., 4., 5.].sliced(6);
    auto k1 = [-1., 0., 1.].sliced(3);
    auto res1 = r1.conv(k1);
    assert(res1.equal!approxEqual([1., 2., 2., 2., 2., 1.]));
}

unittest {
    import std.algorithm.comparison : equal;
    auto image = new float[15*15].sliced(15, 15);
    auto kernel = new float[3*3].sliced(3, 3);
    auto convres = conv(image, kernel);
    assert(convres.shape[].equal(image.shape[]));
}

unittest {
    import std.algorithm.comparison : equal;
    auto image = new float[15*15*3].sliced(15, 15, 3);
    auto kernel = new float[3*3].sliced(3, 3);
    auto convres = conv(image, kernel);
    assert(convres.shape[].equal(image.shape[]));
}

/**
 * 
 */
void calcPartialDerivatives(T)(Slice!(2, T*) image, 
    ref Slice!(2, T*) fx, ref Slice!(2, T*) fy) {

    assert(!image.empty);
    auto itemLength = image.shape.reduce!"a*b";
    if (!fx.shape[].equal(image.shape[]))
        fx = uninitializedArray!(T[])(itemLength).sliced(image.shape);
    if (!fy.shape[].equal(image.shape[]))
        fy = uninitializedArray!(T[])(itemLength).sliced(image.shape);

    auto rows = image.length!0;
    auto cols = image.length!1;

    // calc mid-ground
    foreach (r ; 1.iota(rows)) {
        auto x_row = fx[r, 0..$];
        auto y_row = fy[r, 0..$];
        foreach (c; 1.iota(cols)) {
            auto imrc = image[r, c];
            x_row[c] = cast(T)(-1. * image[r, c - 1] + imrc);
            y_row[c] = cast(T)(-1. * image[r - 1, c] + imrc);
        }
    }

    // calc border edges
    auto x_row = fx[0, 0..$];
    auto y_row = fy[0, 0..$];

    foreach (c; 0.iota(cols - 1)) {
        auto im_0c = image[0, c];
        x_row[c] = cast(T)(-1. * im_0c + image[0, c + 1]);
        y_row[c] = cast(T)(-1. * im_0c + image[1, c]);
    }

    auto x_col = fx[0..$, 0];
    auto y_col = fy[0..$, 0];

    foreach (r; iota(rows - 1)) {
        auto im_r_0 = image[r, 0];
        x_col[r] = cast(T)(-1. * im_r_0 + image[r, 1]);
        y_col[r] = cast(T)(-1. * im_r_0 + image[r + 1, 0]);
    }

    // edges corner pixels
    fx[0, cols-1] = cast(T)(-1* image[0, cols-2] + image[0, cols-1]);
    fy[0, cols-1] = cast(T)(-1*image[0, cols-1] + image[1, cols-1]);
    fx[rows-1, 0] = cast(T)(-1*image[rows-1, 0] + image[rows-1, 1]);
    fy[rows-1, 0] = cast(T)(-1*image[rows-2, 0] + image[rows-1, 0]);
}

private:

// TODO: implement SIMD
Slice!(1, V*) conv1Impl(alias bc, V, K)(Slice!(1, V*) range, Slice!(1, K*) kernel, 
    Slice!(1, V*) prealloc, Slice!(1, V*) mask) {

    if (prealloc.empty || prealloc.shape != range.shape)
        prealloc = uninitializedArray!(V[])(cast(ulong)range.length).sliced(range.shape);

    enforce(&range[0] != &prealloc[0], 
        "Preallocated has to contain different data from that of a input range.");

    auto rl = range.length;
    int ks = cast(int)kernel.length; // kernel size
    int kh = max(1, cast(int)(floor(cast(float)ks / 2.))); // kernel size half
    int ke = cast(int)(ks % 2 == 0 ? kh-1 : kh);
    int rt = cast(int)(ks % 2 == 0 ? rl - 1 - kh : rl - kh); // range top

    bool useMask = !mask.empty;

    // run main (inner) loop
    foreach(i; iota(rl).parallel) {
        if (useMask && !mask[i])
            continue;
        V v = 0;
        for(int j = -kh; j < ke+1; ++j) {
            v += bc(range, i+j)*kernel[j+kh];
        }
        prealloc[i] = v;
    }

    return prealloc;
}

Slice!(2, V*) conv2Impl(alias bc, V, K)(Slice!(2, V*) range, Slice!(2, K*) kernel, 
    Slice!(2, V*) prealloc, Slice!(2, V*) mask) {

    if (prealloc.empty || prealloc.shape != range.shape)
        prealloc = uninitializedArray!(V[])(cast(ulong)range.shape.reduce!"a*b").sliced(range.shape);

    enforce(&range[0, 0] != &prealloc[0, 0], 
        "Preallocated has to contain different data from that of a input range.");

    auto rr = range.length!0; // range rows
    auto rc = range.length!1; // range columns

    int krs = cast(int)kernel.length!0; // kernel rows
    int kcs = cast(int)kernel.length!1; // kernel rows

    int krh = max(1, cast(int)(floor(cast(float)krs / 2.))); // kernel rows size half
    int kch = max(1, cast(int)(floor(cast(float)kcs / 2.))); // kernel rows size half

    bool useMask = !mask.empty;

    // run inner body convolution of the matrix.
    foreach(i; iota(rr).parallel) {
        auto row = prealloc[i, 0..rc];
        foreach(j; iota(rc)) {
            if (useMask && !mask[i, j])
                continue;
            V v = 0;
            for(int ii = -krh; ii < krh+1; ++ii) {
                for(int jj = -kch; jj < kch+1; ++jj) {
                    v += bc(range, i+ii, j+jj)*kernel[ii+krh, jj+kch];
                }
            }
            row[j] = v;
        }
    }

    return prealloc;
}

Slice!(3, V*) conv3Impl(alias bc, V, K, size_t NK)(Slice!(3, V*) range, Slice!(NK, K*) kernel, 
    Slice!(3, V*) prealloc, Slice!(NK, V*) mask)
{
    if (prealloc.empty || prealloc.shape != range.shape)
        prealloc = uninitializedArray!(V[])(cast(ulong)range.shape.reduce!"a*b").sliced(range.shape);

    enforce(&range[0, 0, 0] != &prealloc[0, 0, 0], 
        "Preallocated has to contain different data from that of a input range.");

    foreach(i; iota(range.length!2)) {
        auto r_c = range[0..$, 0..$, i];
        auto p_c = prealloc[0..$, 0..$, i];
        r_c.conv(kernel, p_c);
    }

    return prealloc;
}

