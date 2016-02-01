module dcv.example.convolution;

/** 
 * Convolution example using dcv library.
 */

import std.stdio;

import dcv.core;
import dcv.io;
import dcv.imgproc.convolution;
import dcv.imgproc.color;


int main(string[] args) {
	
    if (args.length < 2) {
        writeln("Invalid argument count - first argument should be a path to RGB image.");
		return 1;
    }

    Image img = imread(args[1]); // read an image from filesystem.

    if (img.empty) { // check if image is properly read.
        writeln("Cannot read image at: " ~ args[1]);
        return 1;
    }

    Slice!(3, float*) imslice = img
		.asType!float // convert Image data type from ubyte to float
		.sliced!float; // slice image data - calls img.data!float.sliced(img.height, img.width, img.channels)

    auto imgray = imslice.rgb2gray; // convert image from rgb to gray

    // create average convolution kernel
    auto kernel = new float[9].sliced(3, 3);
    kernel[] = 1. / 9.;

    // perform convultionon gray image using average kernel
    auto blur = imgray.conv(kernel);

    /*
	//Pre-allocation of the return buffer is allowed through third input parameter:
	import std.algorithm.iteration : reduce;
	auto blur = new float[imgray.shape.reduce!"a*b"].sliced(imgray.shape);

	blur = imgray.conv(kernel, blur); // here covolution will be stored to a blur buffer
	*/

    auto blur_byte = blur.asType!ubyte; // convert average image to ubyte for writing.
    auto imgray_byte = imgray.asType!ubyte; // also the gray image...

    // write resulting images on the filesystem.
    imgray_byte.imwrite("./result/outgray.png");
    blur_byte.imwrite("./result/outblur.png");

    return 0;
}
