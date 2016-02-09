module dcv.example.imgmanip;

/** 
 * Image manipulation example using dcv library.
 */

import std.stdio;
import std.experimental.ndslice;

import dcv.core;
import dcv.imgproc.imgmanip;
import dcv.io;

void main()
{
	/**
	 * Image (array) resize example.
	 * 
	 * Resize is done by using dcv.imgproc.imgmanip.resize method. 
	 * Value interpolation in the resize operation is defined
	 * by the first template parameter which is by default 
	 * linear (dcv.imgproc.interpolation.linear).
	 * Custom interpolation method can be defined in the 3rd 
	 * party code, by following rules established in existing
	 * interpolation functions. Such custom interpolation method
	 * can be used in any transformation function as:
	 * 
	 * auto resizedArray = array.resize!customInterpolation(newsize)
	 * or...
	 * auto scaledImage = array.scale!customInterpolation(scaleValue) etc.
	 */

	auto array_1d = [0., 1.].sliced(2);

	// resize 1D array:
	writeln("1D:");
	array_1d.resize(9).writeln; // so, same as calling array_1d.resize!linear(9)
	writeln();
	
	auto array_2d = [1., 2., 3., 4.].sliced(2, 2);

	// resize 2D array:
	writeln("2D:");
	auto res_2d = array_2d.resize(9, 9);
	foreach(row; res_2d)
		row.writeln;
	writeln();

	auto array_3d = [1., 2.,  3., 4., 
	5., 6.,  7., 8.].sliced(2, 2, 2);

	// resize 3D array:
	writeln("3D:");
	auto res_3d = array_3d.resize(9, 9);
	foreach(row; res_3d)
		row.writeln;
	writeln();

	// resize image:
	auto image = [255, 0, 0,  0, 255, 0,  0, 0, 255,  255, 255, 255].sliced(2, 2, 3).asType!ubyte;
	auto resizedImage = image.resize(300, 300);
	resizedImage.imwrite("./result/resizedImage.png");

}
