module dcv.example.convolution;

/** 
 * Spatial image filtering example using dcv library.
 */

import std.experimental.ndslice;
import std.stdio : writeln;
import std.datetime : StopWatch;
import std.math : fabs;
import std.array : array;
import std.algorithm.iteration : map;

import dcv.core : Image, asType, ranged, ImageFormat;
import dcv.io : imread, imwrite;
import dcv.imgproc;

int main(string[] args)
{
    string impath = (args.length < 2) ? "../data/lena.png" : args[1];

    Image img = imread(impath); // read an image from filesystem.

    if (img.empty)
    { // check if image is properly read.
        writeln("Cannot read image at: " ~ impath);
        return 1;
    }

    Slice!(3, float*) imslice = img.asType!float // convert Image data type from ubyte to float
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
    // scale values from 0 to 255 to preview gradient direction and magnitude
    xgrads = xgrads.byElement.ranged(0, 255).array.sliced(xgrads.shape);

    // Take absolute values and range them from 0 to 255, to preview edges
    laplaceEdges = laplaceEdges.byElement.map!(a => fabs(a)).ranged(0, 255).array.sliced(laplaceEdges.shape);
    logEdges = logEdges.byElement.map!(a => fabs(a)).ranged(0, 255).array.sliced(logEdges.shape);

    // write resulting images on the filesystem.
    blur.asType!ubyte.imwrite(ImageFormat.IF_RGB, "./result/outblur.png");
    xgrads.asType!ubyte.imwrite(ImageFormat.IF_MONO, "./result/sobel.png");
    laplaceEdges.asType!ubyte.imwrite(ImageFormat.IF_MONO, "./result/laplace.png");
    logEdges.asType!ubyte.imwrite(ImageFormat.IF_MONO, "./result/log.png");
    cannyEdges.imwrite(ImageFormat.IF_MONO, "./result/cannyedges.png");

    return 0;
}
