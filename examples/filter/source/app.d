module dcv.example.convolution;

/** 
 * Spatial image filtering example using dcv library.
 */

import core.stdc.stdio : printf;
import std.datetime.stopwatch : StopWatch;
import std.math : abs;
import std.array : array;

import mir.ndslice, mir.rc;

import dcv.core;
import dcv.imageio : imread, imwrite;
import dcv.imgproc;
import dcv.plot;

@nogc nothrow:

int main(string[] args)
{
    string impath = (args.length < 2) ? "../data/lena.png" : args[1];

    Image img = imread(impath); // read an image from filesystem.
    scope(exit) destroyFree(img);

    if (img.empty)
    { // check if image is properly read.
        printf("Cannot read image at: %s", CString(impath).storage);
        return 1;
    }


    Slice!(RCI!float, 3) imslice = img.sliced.as!float.rcslice; // create a rcslice (copy).

    auto gray = imslice.lightScope.rgb2gray; // convert rgb image to grayscale

    auto gaussianKernel = gaussian!float(2, 5, 5); // create gaussian convolution kernel (sigma, kernel width and height)
    auto sobelXKernel = sobel!real(GradientDirection.DIR_X); // sobel operator for horizontal (X) gradients
    auto laplacianKernel = laplacian!double; // laplacian kernel, similar to matlabs fspecial('laplacian', alpha)
    auto logKernel = laplacianOfGaussian!float(1.0, 5, 5); // laplacian of gaussian, similar to matlabs fspecial('log', alpha, width, height)

    // perform convolution for each kernel
    auto blur = conv(imslice, gaussianKernel);
    
    auto xgrads = conv(gray, sobelXKernel);
    auto laplaceEdges = conv(gray, laplacianKernel);
    auto logEdges = conv(gray, logKernel);

    // calculate canny edges
    auto cannyEdges = gray.lightScope.canny!ubyte(75);

    // perform bilateral blurring
    auto bilBlur = imslice.lightScope.bilateralFilter!float(10.0f, 10.0f, 5);

    // Add salt and pepper noise at input image green channel
    auto noisyImage = imslice.rcslice;
    auto saltNPepperNoise = noisyImage[0 .. $, 0 .. $, 1].saltNPepper(0.15f);
    // ... and perform median blurring on noisy image
    auto medBlur = noisyImage.lightScope.medianFilter(5);

    // scale values from 0 to 255 to preview gradient direction and magnitude
    xgrads.ranged(0, 255);
    // Take absolute values and range them from 0 to 255, to preview edges
    laplaceEdges = laplaceEdges.lightScope.map!(a => abs(a)).rcslice.ranged(0.0f, 255.0f);
    logEdges = logEdges.lightScope.map!(a => abs(a)).rcslice.ranged(0.0f, 255.0f);

    // Show images on screen
    img.imshow("Original");
    bilBlur.imshow("Bilateral Blurring");
    noisyImage.imshow("Salt and Pepper noise at green channel for Median");
    medBlur.imshow("Median Blurring");
    blur.imshow("Gaussian Blurring");
    xgrads.imshow("Sobel X");
    laplaceEdges.imshow("Laplace");
    logEdges.imshow("Laplacian of Gaussian");
    cannyEdges.imshow("Canny Edges");
 
    waitKey();
    destroyFigures();
    return 0;
}

auto saltNPepper(InputSlice)(InputSlice input, float saturation)
{
    import std.algorithm : min;

    import mir.random;
    import mir.random.variable;

    alias T = DeepElementType!InputSlice;
    
    int err;
    ulong pixelCount = input.length!0*input.length!1;
    ulong noisyPixelCount = cast(typeof(pixelCount))(pixelCount * saturation);

    auto noisyPixels = rcslice!size_t(noisyPixelCount);

    auto gen = Random(unpredictableSeed);
    auto rv = uniformVar(0, pixelCount);
    
    foreach(ref e; noisyPixels)
    {
        e = cast(size_t)rv(gen);
    }

    auto imdata = input.reshape([pixelCount], err);

    assert(err == 0);

    auto A = noisyPixels[0 .. $ / 2]; // salt
    auto B = noisyPixels[$ / 2 .. $]; // pepper
    
    // nogc lockStep workaround
    alias ItZ = ZipIterator!(typeof(A._iterator), typeof(B._iterator));
    auto zipp = ItZ(A._iterator, B._iterator);
    auto mlen = min(A.length, B.length);

    foreach(_; 0..mlen)
    {
        auto salt = (*zipp).a;
        auto pepper = (*zipp).b;

        imdata[salt] = cast(T)255;
        imdata[pepper] = cast(T)0;
        ++zipp;
    }
    return input;
}
