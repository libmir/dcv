module dcv.example.imgmanip;

/** 
 * Image manipulation example using dcv library.
 */

import std.stdio;
import mir.ndslice;

import dcv.core;
import dcv.imgproc.imgmanip;
import dcv.io;

void main()
{
    /**
	 * Image (array) resize
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
    array_1d.resize([9]).writeln; // so, same as calling array_1d.resize!linear([9])
    writeln();

    auto array_2d = [1., 2., 3., 4.].sliced(2, 2);

    // resize 2D array:
    writeln("2D:");
    auto res_2d = array_2d.resize([9, 9]);
    foreach (row; res_2d)
        row.writeln;
    writeln();

    auto array_3d = [1., 2., 3., 4., 5., 6., 7., 8.].sliced(2, 2, 2);

    // resize 3D array:
    writeln("3D:");
    auto res_3d = array_3d.resize([9, 9]);
    foreach (row; res_3d)
        row.writeln;
    writeln();

    // resize image:
    auto image = [255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255].sliced(2, 2, 3).as!ubyte.slice;
    auto resizedImage = image.resize([300, 300]);
    resizedImage.imwrite(ImageFormat.IF_RGB, "./result/resizedImage.png");

    // scale image:
    auto scaledImage = resizedImage.scale([2., 2.]);
    scaledImage.imwrite(ImageFormat.IF_RGB, "./result/scaledImage.png");

    /*
	 * Image transformation
	 * 
	 * Affine and Perspective transformation over images can be 
	 * performed by using dcv.imgproc.imgmanip.transformAffine,
	 * and transformPerspective functions. 
	 * 
	 * Functions take the slice of an image as first argument, which can be 2D, and 3D.
	 * Second argument is a 3x3 transformation matrix, which can be defined
	 * as Slice object, or as build in 2D array in floating point type. Third argument
	 * is the output image size. And as in resize, first template argument is an alias 
	 * to interpolation function, which is by default linear.
	 */
    import std.math : sin, cos, PI;

    image = imread("../data/lena.png").sliced!ubyte;

    double ang = PI / 4.; // rotation angle
    double t_x = 30.; // x offset
    double t_y = -100.; // y offset
    size_t[2] outSize = [image.length!1 * 2, image.length!0 * 2]; // output size: [width*2, height*2]

    // transform image:
    auto transformedImage = image.transformAffine([[cos(ang), -sin(ang), t_x], [sin(ang),
            cos(ang), t_y], [0., 0., 1.]], outSize);

    transformedImage.imwrite(ImageFormat.IF_RGB, "./result/transformedImage.png");
}
