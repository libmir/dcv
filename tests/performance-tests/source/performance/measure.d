module performance.measure;

import std.stdio;
import std.range;
import std.algorithm;
import std.datetime;
import std.string;
import std.traits;
import std.typecons;
import std.parallelism : taskPool;

import core.time;
import core.thread;

import performance.common;

import dcv.core;
import dcv.imgproc;
import dcv.features;
import dcv.multiview;
import dcv.tracking;
import dcv.io;

immutable imsize = 128;
size_t iterations = 1_000;

alias BenchmarkFunction = long function();

BenchmarkFunction[string] funcs;

void measure(string test, size_t iterations)
{
    .iterations = iterations;
    registerBenchmarks(test);
    Thread.getThis.sleep(dur!"msecs"(1000));
    runBenchmarks(exeDir ~ "/profile.csv");
}

void registerBenchmark(alias fun)()
{
    auto fnName = fullyQualifiedName!fun.replace("performance.measure.", "").replace("run_", "").replace("_", ".");
    funcs[fnName] = &fun;
}

void registerBenchmarks(string test)
{
    foreach (m; __traits(allMembers, performance.measure))
    {
        static if (m.length > 4 && m[0 .. 4].equal("run_"))
        {
            if (test.empty || !find(m.replace("_", "."), test).empty)
                registerBenchmark!(__traits(getMember, performance.measure, m));
        }
    }
}

void runBenchmarks(string outputPath)
{
    import std.file;
    import std.format;

    string output;

    auto fnNames = sort(funcs.keys);
    foreach (name; fnNames)
    {
        auto fn = funcs[name];

        std.stdio.write(name, ":");
        stdout.flush();
        auto res = fn();
        std.stdio.writeln(res.usecs);

        output ~= format("%s,%d\n", name, res);
    }
    write(outputPath, output);
}

auto evalBenchmark(Fn, Args...)(Fn fn, Args args)
{
    StopWatch s;
    s.start;
    foreach (i; iota(iterations))
    {
        fn(args);
    }
    return s.peek.usecs;
}

// Profiling functions ------------------------------------------------------------------

auto run_dcv_features_corner_harris_harrisCorners_3()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    return evalBenchmark(&harrisCorners!(float, float), image, 3, 0.64, 0.84, result);
}

auto run_dcv_features_corner_harris_harrisCorners_5()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    return evalBenchmark(&harrisCorners!(float, float), image, 5, 0.64, 0.84, result);
}

auto run_dcv_features_corner_harris_shiTomasiCorners_3()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    return evalBenchmark(&shiTomasiCorners!(float, float), image, 3, 0.84, result);
}

auto run_dcv_features_corner_harris_shiTomasiCorners_5()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    return evalBenchmark(&shiTomasiCorners!(float, float), image, 5, 0.84, result);
}

auto run_dcv_features_corner_fast_FASTDetector()
{
    FASTDetector detector = new FASTDetector;
    auto image = new Image(imsize, imsize, ImageFormat.IF_MONO, BitDepth.BD_8);

    auto detect(FASTDetector detector, Image image)
    {
        detector.detect(image);
    }

    return evalBenchmark(&detect, detector, image);
}

auto run_dcv_features_rht_RhtLines()
{
    import dcv.features.rht;

    auto image = imread(getExampleDataPath() ~ "/img.png", ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;
    auto evalRht(Slice!(2, ubyte*) image)
    {
        auto lines = RhtLines().epouchs(10).iterations(10).minCurve(50);
        auto collectedLines = lines(image).array;
    }

    return evalBenchmark(&evalRht, image.reshape(image.length!0, image.length!1).scale([0.15, 0.15]));
}

auto run_dcv_features_rht_RhtCircles()
{
    import dcv.features.rht;

    auto image = imread(getExampleDataPath() ~ "/img.png", ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;
    auto evalRht(Slice!(2, ubyte*) image)
    {
        auto circles = RhtCircles().epouchs(10).iterations(10).minCurve(50);
        auto collectedCircles = circles(image).array;
    }

    return evalBenchmark(&evalRht, image.reshape(image.length!0, image.length!1).scale([0.15, 0.15]));
}

auto run_dcv_features_utils_extractCorners()
{
    auto image = imread(getExampleDataPath() ~ "/../features/result/harrisResponse.png",
            ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;
    return evalBenchmark(&extractCorners!ubyte, image.reshape(image.length!0, image.length!1), -1, cast(ubyte)0);
}

auto run_dcv_imgproc_color_rgb2gray()
{
    auto rgb = slice!ubyte(imsize, imsize, 3);
    auto gray = slice!ubyte(imsize, imsize);
    return evalBenchmark(&rgb2gray!ubyte, rgb, gray, Rgb2GrayConvertion.LUMINANCE_PRESERVE);
}

auto run_dcv_imgproc_color_gray2rgb()
{
    auto rgb = slice!ubyte(imsize, imsize, 3);
    auto gray = slice!ubyte(imsize, imsize);
    return evalBenchmark(&gray2rgb!ubyte, gray, rgb);
}

auto run_dcv_imgproc_color_rgb2hsv()
{
    auto rgb = slice!ubyte(imsize, imsize, 3);
    auto hsv = slice!float(imsize, imsize, 3);
    return evalBenchmark(&rgb2hsv!(float, ubyte), rgb, hsv);
}

auto run_dcv_imgproc_color_hsv2rgb()
{
    auto rgb = slice!ubyte(imsize, imsize, 3);
    auto hsv = slice!float(imsize, imsize, 3);
    return evalBenchmark(&hsv2rgb!(ubyte, float), hsv, rgb);
}

auto run_dcv_imgproc_color_rgb2yuv()
{
    auto rgb = slice!ubyte(imsize, imsize, 3);
    auto yuv = slice!ubyte(imsize, imsize, 3);
    return evalBenchmark(&rgb2yuv!ubyte, rgb, yuv);
}

auto run_dcv_imgproc_color_yuv2rgb()
{
    auto rgb = slice!ubyte(imsize, imsize, 3);
    auto yuv = slice!ubyte(imsize, imsize, 3);
    return evalBenchmark(&yuv2rgb!ubyte, yuv, rgb);
}

auto run_dcv_imgproc_convolution_conv_1D_3()
{
    auto vector = slice!float(imsize * imsize);
    auto result = slice!float(imsize * imsize);
    auto kernel = slice!float(3);
    return evalBenchmark(&conv!(neumann, float, float, float, 1, 1), vector, kernel, result,
            emptySlice!(1, float), taskPool);
}

auto run_dcv_imgproc_convolution_conv_1D_5()
{
    auto vector = slice!float(imsize * imsize);
    auto result = slice!float(imsize * imsize);
    auto kernel = slice!float(5);
    return evalBenchmark(&conv!(neumann, float, float, float, 1, 1), vector, kernel, result,
            emptySlice!(1, float), taskPool);
}

auto run_dcv_imgproc_convolution_conv_1D_7()
{
    auto vector = slice!float(imsize * imsize);
    auto result = slice!float(imsize * imsize);
    auto kernel = slice!float(7);
    return evalBenchmark(&conv!(neumann, float, float, float, 1, 1), vector, kernel, result,
            emptySlice!(1, float), taskPool);
}

auto run_dcv_imgproc_convolution_conv_2D_3x3()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    auto kernel = slice!float(3, 3);
    return evalBenchmark(&conv!(neumann, float, float, float, 2, 2), image, kernel, result,
            emptySlice!(2, float), taskPool);
}

auto run_dcv_imgproc_convolution_conv_2D_5x5()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    auto kernel = slice!float(5, 5);
    return evalBenchmark(&conv!(neumann, float, float, float, 2, 2), image, kernel, result,
            emptySlice!(2, float), taskPool);
}

auto run_dcv_imgproc_convolution_conv_2D_7x7()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    auto kernel = slice!float(7, 7);
    return evalBenchmark(&conv!(neumann, float, float, float, 2, 2), image, kernel, result,
            emptySlice!(2, float), taskPool);
}

auto run_dcv_imgproc_convolution_conv_3D_3x3()
{
    auto image = slice!float(imsize, imsize, 3);
    auto result = slice!float(imsize, imsize, 3);
    auto kernel = slice!float(3, 3);
    return evalBenchmark(&conv!(neumann, float, float, float, 3, 2), image, kernel, result,
            emptySlice!(2, float), taskPool);
}

auto run_dcv_imgproc_convolution_conv_3D_5x5()
{
    auto image = slice!float(imsize, imsize, 3);
    auto result = slice!float(imsize, imsize, 3);
    auto kernel = slice!float(5, 5);
    return evalBenchmark(&conv!(neumann, float, float, float, 3, 2), image, kernel, result,
            emptySlice!(2, float), taskPool);
}

auto run_dcv_imgproc_filter_filterNonMaximum()
{
    auto image = slice!float(imsize, imsize);
    return evalBenchmark(&filterNonMaximum!float, image, 10);
}

auto run_dcv_imgproc_filter_calcPartialDerivatives()
{
    auto image = slice!float(imsize, imsize);
    auto fx = slice!float(imsize, imsize);
    auto fy = slice!float(imsize, imsize);
    return evalBenchmark(&calcPartialDerivatives!float, image, fx, fy);
}

auto run_dcv_imgproc_filter_calcGradients()
{
    auto image = slice!float(imsize, imsize);
    auto mag = slice!float(imsize, imsize);
    auto orient = slice!float(imsize, imsize);
    return evalBenchmark(&calcGradients!(float), image, mag, orient, EdgeKernel.SIMPLE);
}

auto run_dcv_imgproc_filter_nonMaximaSupression()
{
    auto mag = slice!float(imsize, imsize);
    auto orient = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    return evalBenchmark(&nonMaximaSupression!(float, float), mag, orient, result);
}

auto run_dcv_imgproc_filter_canny()
{
    // TODO implement random sampling image generation
    auto image = slice!float(imsize, imsize);
    auto result = slice!ubyte(imsize, imsize);
    auto runCanny(typeof(image) image, typeof(result) result)
    {
        canny!ubyte(image, 0, 1, EdgeKernel.SOBEL, result);
    }
    //return evalBenchmark(&canny!(float,ubyte), image, cast(ubyte)0, cast(ubyte)1, EdgeKernel.SOBEL, result);
    return evalBenchmark(&runCanny, image, result);
}

auto run_dcv_imgproc_filter_bilateralFilter_3()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    return evalBenchmark(&bilateralFilter!(neumann, float, float, 2), image, 0.84, 3, result, taskPool);
}

auto run_dcv_imgproc_filter_bilateralFilter_5()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    return evalBenchmark(&bilateralFilter!(neumann, float, float, 2), image, 0.84, 5, result, taskPool);
}

auto run_dcv_imgproc_filter_medianFilter_3()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    return evalBenchmark(&medianFilter!(neumann, float, float, 2), image, 3, result, taskPool);
}

auto run_dcv_imgproc_filter_medianFilter_5()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    return evalBenchmark(&medianFilter!(neumann, float, float, 2), image, 5, result, taskPool);
}

auto run_dcv_imgproc_filter_histEqual()
{
    auto image = slice!ubyte(imsize, imsize);
    auto result = slice!ubyte(imsize, imsize);
    int[256] histogram;
    return evalBenchmark(&histEqual!(ubyte, int[256], 2), image, histogram, result);
}

auto run_dcv_imgproc_filter_erode()
{
    auto image = slice!ubyte(imsize, imsize);
    auto result = slice!ubyte(imsize, imsize);
    return evalBenchmark(&erode!(neumann, ubyte), image, radialKernel!ubyte(3), result, taskPool);
}

auto run_dcv_imgproc_filter_dilate()
{
    auto image = slice!ubyte(imsize, imsize);
    auto result = slice!ubyte(imsize, imsize);
    return evalBenchmark(&dilate!(neumann, ubyte), image, radialKernel!ubyte(3), result, taskPool);
}

auto run_dcv_imgproc_filter_open()
{
    auto image = slice!ubyte(imsize, imsize);
    auto result = slice!ubyte(imsize, imsize);
    return evalBenchmark(&open!(neumann, ubyte), image, radialKernel!ubyte(3), result, taskPool);
}

auto run_dcv_imgproc_filter_close()
{
    auto image = slice!ubyte(imsize, imsize);
    auto result = slice!ubyte(imsize, imsize);
    return evalBenchmark(&close!(neumann, ubyte), image, radialKernel!ubyte(3), result, taskPool);
}

auto run_dcv_imgproc_imgmanip_resize_upsize()
{
    auto image = slice!float(imsize, imsize);
    size_t[2] resultSize = [cast(size_t)(imsize * 1.5), cast(size_t)(imsize * 1.5f)];
    return evalBenchmark(&resize!(linear, float, 2, 2), image, resultSize, taskPool);
}

auto run_dcv_imgproc_imgmanip_resize_downsize()
{
    auto image = slice!float(imsize, imsize);
    size_t[2] resultSize = [cast(size_t)(imsize * 0.5), cast(size_t)(imsize * 0.5f)];
    return evalBenchmark(&resize!(linear, float, 2, 2), image, resultSize, taskPool);
}

auto run_dcv_imgproc_imgmanip_scale_upsize()
{
    auto image = slice!float(imsize, imsize);
    float[2] scaleFactor = [1.5f, 1.5f];
    return evalBenchmark(&scale!(linear, float, float, 2, 2), image, scaleFactor, taskPool);
}

auto run_dcv_imgproc_imgmanip_scale_downsize()
{
    auto image = slice!float(imsize, imsize);
    float[2] scaleFactor = [0.5f, 0.5f];
    return evalBenchmark(&scale!(linear, float, float, 2, 2), image, scaleFactor, taskPool);
}

auto run_dcv_imgproc_imgmanip_transformAffine()
{
    auto image = slice!float(imsize, imsize);
    auto matrix = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];
    size_t[2] outSize = [0, 0];
    return evalBenchmark(&transformAffine!(linear, float, typeof(matrix), 2), image, matrix, outSize);
}

auto run_dcv_imgproc_imgmanip_transformPerspective()
{
    auto image = slice!float(imsize, imsize);
    auto matrix = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];
    size_t[2] outSize = [0, 0];
    return evalBenchmark(&transformPerspective!(linear, float, typeof(matrix), 2), image, matrix, outSize);
}

auto run_dcv_imgproc_imgmanip_warp()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    auto warpMap = slice!float(imsize, imsize, 2);
    return evalBenchmark(&warp!(linear, 2, float, float), image, warpMap, result);
}

auto run_dcv_imgproc_imgmanip_remap()
{
    auto image = slice!float(imsize, imsize);
    auto result = slice!float(imsize, imsize);
    auto remapMap = slice!float(imsize, imsize, 2);
    return evalBenchmark(&remap!(linear, 2, float, float), image, remapMap, result);
}

auto run_dcv_imgproc_threshold_threshold()
{
    auto image = slice!ubyte(imsize, imsize);
    auto result = slice!ubyte(imsize, imsize);
    auto runThreshold(typeof(image) image, typeof(result) result)
    {
        threshold(image, 0, 1, result);
    }
    //return evalBenchmark(&threshold!(ubyte, ubyte, 2), image, 0, 1, result);
    return evalBenchmark(&runThreshold, image, result);
}

auto run_dcv_multiview_stereo_matching_semiGlobalMatchingPipeline()
{
    import dcv.multiview.stereo.matching;

    auto left = imread(getExampleDataPath() ~ "/stereo/left.png", ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8))
        .sliced;
    auto right = imread(getExampleDataPath() ~ "/stereo/right.png", ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8))
        .sliced;

    auto ls = left.reshape(left.length!0, left.length!1).scale([0.25, 0.25]).asImage(ImageFormat.IF_MONO);
    auto rs = right.reshape(left.length!0, left.length!1).scale([0.25, 0.25]).asImage(ImageFormat.IF_MONO);

    auto props = StereoPipelineProperties(ls.width, ls.height, ls.channels);
    auto matcher = semiGlobalMatchingPipeline(props, 2, 5, 10);
    auto runStereo(typeof(matcher) matcher, Image left, Image right)
    {
        matcher.evaluate(left, right);
    }

    return evalBenchmark(&runStereo, matcher, ls, rs);
}

auto run_dcv_tracking_opticalflow_hornschunck_HornSchunckFlow()
{
    auto left = imread(getExampleDataPath() ~ "/optflow/Army/frame10.png",
            ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;
    auto right = imread(getExampleDataPath() ~ "/optflow/Army/frame11.png",
            ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;

    auto ls = left.reshape(left.length!0, left.length!1).scale([0.25, 0.25]).asImage(ImageFormat.IF_MONO);
    auto rs = right.reshape(left.length!0, left.length!1).scale([0.25, 0.25]).asImage(ImageFormat.IF_MONO);

    HornSchunckFlow flowAlgorithm = new HornSchunckFlow;
    auto flow = slice!float(ls.height, ls.width, 2);

    auto runFlow(HornSchunckFlow flowAlgorithm, Image left, Image right, DenseFlow flow)
    {
        flowAlgorithm.evaluate(left, right, flow);
    }

    return evalBenchmark(&runFlow, flowAlgorithm, ls, rs, flow);
}

auto run_dcv_tracking_opticalflow_lucaskanade_LucasKanadeFlow()
{
    auto left = imread(getExampleDataPath() ~ "/optflow/Army/frame10.png",
            ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;
    auto right = imread(getExampleDataPath() ~ "/optflow/Army/frame11.png",
            ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;

    auto ls = left.reshape(left.length!0, left.length!1).scale([0.25, 0.25]).asImage(ImageFormat.IF_MONO);
    auto rs = right.reshape(left.length!0, left.length!1).scale([0.25, 0.25]).asImage(ImageFormat.IF_MONO);

    immutable pointCount = 25;

    LucasKanadeFlow flowAlgorithm = new LucasKanadeFlow;
    float[2][] points;
    float[2][] flow;

    flow.length = pointCount;

    float x = 0.0f, y = 0.0f;
    5.iota.each!((i) {
        x = 0.0f;
        5.iota.each!((j) { float[2] xy = [x, y]; flow ~= xy; x += 10.0f; });
        y += 10.0f;
    });

    float[2][] searchRegions = pointCount.iota.map!( i => cast(float[2])[3.0f, 3.0f]).array;

    auto runFlow(LucasKanadeFlow flowAlgorithm, Image left, Image right, in float[2][] points,
            in float[2][] searchRegions, float[2][] flow)
    {
        flowAlgorithm.evaluate(left, right, points, searchRegions, flow, false);
    }

    return evalBenchmark(&runFlow, flowAlgorithm, ls, rs, points, searchRegions, flow);
}

auto run_dcv_tracking_opticalflow_pyramidflow_DensePyramidFlow_HornSchunckFlow()
{
    auto left = imread(getExampleDataPath() ~ "/optflow/Army/frame10.png",
            ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;
    auto right = imread(getExampleDataPath() ~ "/optflow/Army/frame11.png",
            ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;
    auto ls = left.reshape(left.length!0, left.length!1).scale([0.25, 0.25]).asImage(ImageFormat.IF_MONO);
    auto rs = right.reshape(left.length!0, left.length!1).scale([0.25, 0.25]).asImage(ImageFormat.IF_MONO);
    DensePyramidFlow flowAlgorithm = new DensePyramidFlow(new HornSchunckFlow, 3);
    auto flow = slice!float(ls.height, ls.width, 2);
    auto runFlow(DensePyramidFlow flowAlgorithm, Image left, Image right, DenseFlow flow)
    {
        flowAlgorithm.evaluate(left, right, flow);
    }

    return evalBenchmark(&runFlow, flowAlgorithm, ls, rs, flow);
}

auto run_dcv_tracking_opticalflow_pyramidflow_SparsePyramidFlow_LucasKanadeFlow()
{
    auto left = imread(getExampleDataPath() ~ "/optflow/Army/frame10.png",
            ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;
    auto right = imread(getExampleDataPath() ~ "/optflow/Army/frame11.png",
            ReadParams(ImageFormat.IF_MONO, BitDepth.BD_8)).sliced;

    auto ls = left.reshape(left.length!0, left.length!1).scale([0.25, 0.25]).asImage(ImageFormat.IF_MONO);
    auto rs = right.reshape(left.length!0, left.length!1).scale([0.25, 0.25]).asImage(ImageFormat.IF_MONO);

    immutable pointCount = 25;

    SparsePyramidFlow flowAlgorithm = new SparsePyramidFlow(new LucasKanadeFlow, 3);
    float[2][] points;
    float[2][] flow;

    flow.length = pointCount;

    float x = 0.0f, y = 0.0f;
    5.iota.each!((i) {
        x = 0.0f;
        5.iota.each!((j) { float[2] xy = [x, y]; flow ~= xy; x += 10.0f; });
        y += 10.0f;
    });

    float[2][] searchRegions = pointCount.iota.map!( i => cast(float[2])[3.0f, 3.0f]).array;

    auto runFlow(SparsePyramidFlow flowAlgorithm, Image left, Image right, in float[2][] points,
            in float[2][] searchRegions, float[2][] flow)
    {
        flowAlgorithm.evaluate(left, right, points, searchRegions, flow, false);
    }

    return evalBenchmark(&runFlow, flowAlgorithm, ls, rs, points, searchRegions, flow);
}

