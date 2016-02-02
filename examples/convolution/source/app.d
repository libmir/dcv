module dcv.example.convolution;

/** 
 * Convolution example using dcv library.
 */

import std.experimental.ndslice;
import std.stdio : writeln;
import std.datetime : StopWatch;
import core.thread;

import dcv.core : Image, asType;
import dcv.io : imread, imwrite;
import dcv.imgproc.convolution : conv;
import dcv.imgproc.filter : gaussian;


int main(string[] args) {
	
    Image img = null;
	string impath = "";

    if (args.length < 2) {
		impath = "../data/lena.png";
    } else {
		impath = args[1];
	}

	img = imread(impath); // read an image from filesystem.

    if (img.empty) { // check if image is properly read.
        writeln("Cannot read image at: " ~ impath);
        return 1;
    }

    Slice!(3, float*) imslice = img
		.asType!float // convert Image data type from ubyte to float
		.sliced!float; // slice image data - calls img.data!float.sliced(img.height, img.width, img.channels)

    // create gaussian convolution kernel
    auto kernel = gaussian!float(2, 5, 5);

	StopWatch s;

	writeln("Waiting for threads to be spawned and ready...");
	Thread.getThis.sleep(dur!"msecs"(1000));

	s.start;
    // perform convultionon gray image using average kernel
    auto blur = imslice.conv(kernel);
	writeln("Convolution done in: ", s.peek.msecs, "ms");

    /*
	//Pre-allocation of the return buffer is allowed through third input parameter:
	import std.algorithm.iteration : reduce;
	auto blur = new float[imgray.shape.reduce!"a*b"].sliced(imgray.shape);

	blur = imgray.conv(kernel, blur); // here covolution will be stored to a blur buffer
	*/

    auto blur_byte = blur.asType!ubyte; // convert average image to ubyte for writing.

    // write resulting images on the filesystem.
    blur_byte.imwrite("./result/outblur.png");

    return 0;
}
