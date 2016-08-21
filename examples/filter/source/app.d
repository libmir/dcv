module dcv.example.convolution;

/** 
 * Spatial image filtering example using dcv library.
 */

import std.stdio : writeln;
import std.datetime : StopWatch;
import std.math : fabs;
import std.array : array;
import std.algorithm.iteration : map;

import mir.ndslice;

import dcv.core : Image, asType, ranged, ImageFormat;
import dcv.io : imread, imwrite;
import dcv.imgproc;
import dcv.plot;

int main(string[] args)
{
    string impath = (args.length < 2) ? "../data/lena.png" : args[1];

    Image img = imread(impath); // read an image from filesystem.

    if (img.empty)
    { // check if image is properly read.
        writeln("Cannot read image at: " ~ impath);
        return 1;
    }

    Slice!(3, float*) imslice = img
        .asType!float // convert Image data type from ubyte to float
        .sliced!float; // slice image data - calls img.data!float.sliced(img.height, img.width, img.channels)

    auto gray = imslice.rgb2gray; // convert rgb image to grayscale

    auto gaussianKernel = gaussian!float(2, 5, 5); // create gaussian convolution kernel (sigma, kernel width and height)
    auto sobelXKernel = sobel!real(GradientDirection.DIR_X); // sobel operator for horizontal (X) gradients
    auto laplacianKernel = laplacian!double; // laplacian kernel, similar to matlabs fspecial('laplacian', alpha)
    auto logKernel = laplacianOfGaussian(1, 5, 5); // laplacian of gaussian, similar to matlabs fspecial('log', alpha, width, height)

    // perform convolution for each kernel
    auto blur = imslice.conv(gaussianKernel);
    auto xgrads = gray.conv(sobelXKernel);
    auto laplaceEdges = gray.conv(laplacianKernel);
    auto logEdges = gray.conv(logKernel);


    // calculate canny edges
    auto cannyEdges = gray.canny!ubyte(75);

    // perform bilateral blurring
    auto bilBlur = imslice.bilateralFilter(10.0f, 5);

    // Add salt and pepper noise at input image green channel
    auto noisyImage = imslice.byElement.array.sliced(imslice.shape);
    auto saltNPepperNoise = noisyImage[0 .. $, 0 .. $, 1].saltNPepper(0.15f);
    // ... and perform median blurring on noisy image
    auto medBlur = noisyImage.medianFilter(5);

    // scale values from 0 to 255 to preview gradient direction and magnitude
    xgrads.ranged(0, 255);
    // Take absolute values and range them from 0 to 255, to preview edges
    laplaceEdges = laplaceEdges.ndMap!(a => fabs(a)).byElement.array.sliced(laplaceEdges.shape).ranged(0.0f, 255.0f);
    logEdges = logEdges.ndMap!(a => fabs(a)).byElement.array.sliced(logEdges.shape).ranged(0.0f, 255.0f);

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

    return 0;
}

Slice!(2, T*) saltNPepper(T)(Slice!(2, T*) slice, float saturation) 
{
    import std.range, std.random;

    ulong pixelCount = slice.length!0*slice.length!1;
    ulong noisyPixelCount = cast(typeof(pixelCount))(pixelCount * saturation);

    auto noisyPixels = noisyPixelCount.iota.map!(x => uniform(0, pixelCount)).array;
    auto imdata = slice.reshape(pixelCount);

    foreach(salt, pepper; lockstep(noisyPixels[0 .. $ / 2], noisyPixels[$ / 2 .. $]))
    {
        imdata[salt] = cast(T)255;
        imdata[pepper] = cast(T)0;
    }
    return slice;
}
