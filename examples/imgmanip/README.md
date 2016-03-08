# Image manipulation example


This example should demonstrate how to apply various image (spatial) transformations.


## Modules used
* dcv.core;
* dcv.imgproc.imgmanip;
* dcv.io;

## Resize

Array resize is done by using dcv.imgproc.imgmanip.resize method. Value interpolation in the resize operation is defined
by the first template parameter which is by default linear (dcv.imgproc.interpolation.linear). Custom interpolation 
method can be defined in the 3rd party code, by following rules established in existing interpolation functions. 
Such custom interpolation method can be used in any transformation function as:

```d
auto resizedArray = array.resize!customInterpolation(newsize)
//or...
auto scaledArray = array.scale!customInterpolation(scaleValue) etc.
```

Example so far only demonstrates how to resize an ND array.

### 1D Resize

Resize method supports 1D (vector) interpolated resizing.
As shown in the example code:

```d
auto array_1d = [0., 1.].sliced(2);
array_1d.resize(9).writeln
```

... prints out:
```
[0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1]
```

### 2D Resize

... Or the matrix resize, for the following code:

```d
auto array_2d = [1., 2., 3., 4.].sliced(2, 2);
auto res_2d = array_2d.resize(9, 9);
foreach(row; res_2d) row.writeln;
```

... outputs on the console:
```
[1, 1.125, 1.25, 1.375, 1.5, 1.625, 1.75, 1.875, 2]
[1.25, 1.375, 1.5, 1.625, 1.75, 1.875, 2, 2.125, 2.25]
[1.5, 1.625, 1.75, 1.875, 2, 2.125, 2.25, 2.375, 2.5]
[1.75, 1.875, 2, 2.125, 2.25, 2.375, 2.5, 2.625, 2.75]
[2, 2.125, 2.25, 2.375, 2.5, 2.625, 2.75, 2.875, 3]
[2.25, 2.375, 2.5, 2.625, 2.75, 2.875, 3, 3.125, 3.25]
[2.5, 2.625, 2.75, 2.875, 3, 3.125, 3.25, 3.375, 3.5]
[2.75, 2.875, 3, 3.125, 3.25, 3.375, 3.5, 3.625, 3.75]
[3, 3.125, 3.25, 3.375, 3.5, 3.625, 3.75, 3.875, 4]
```

### 3D Resize

3D resize is defined as would be on the multi-channel image - values of each channel are interpolated individualy as
in 2D resize:

```d
auto array_3d = [1., 2.,  3., 4.,  5., 6.,  7., 8.].sliced(2, 2, 2);

auto res_3d = array_3d.resize(9, 9); // notice the 2D new size (9, 9)
foreach(row; res_3d) row.writeln;
```

... prints out:

```
[[1, 2], [1.25, 2.25], [1.5, 2.5], [1.75, 2.75], [2, 3], [2.25, 3.25], [2.5, 3.5], [2.75, 3.75], [3, 4]]
[[1.5, 2.5], [1.75, 2.75], [2, 3], [2.25, 3.25], [2.5, 3.5], [2.75, 3.75], [3, 4], [3.25, 4.25], [3.5, 4.5]]
[[2, 3], [2.25, 3.25], [2.5, 3.5], [2.75, 3.75], [3, 4], [3.25, 4.25], [3.5, 4.5], [3.75, 4.75], [4, 5]]
[[2.5, 3.5], [2.75, 3.75], [3, 4], [3.25, 4.25], [3.5, 4.5], [3.75, 4.75], [4, 5], [4.25, 5.25], [4.5, 5.5]]
[[3, 4], [3.25, 4.25], [3.5, 4.5], [3.75, 4.75], [4, 5], [4.25, 5.25], [4.5, 5.5], [4.75, 5.75], [5, 6]]
[[3.5, 4.5], [3.75, 4.75], [4, 5], [4.25, 5.25], [4.5, 5.5], [4.75, 5.75], [5, 6], [5.25, 6.25], [5.5, 6.5]]
[[4, 5], [4.25, 5.25], [4.5, 5.5], [4.75, 5.75], [5, 6], [5.25, 6.25], [5.5, 6.5], [5.75, 6.75], [6, 7]]
[[4.5, 5.5], [4.75, 5.75], [5, 6], [5.25, 6.25], [5.5, 6.5], [5.75, 6.75], [6, 7], [6.25, 7.25], [6.5, 7.5]]
[[5, 6], [5.25, 6.25], [5.5, 6.5], [5.75, 6.75], [6, 7], [6.25, 7.25], [6.5, 7.5], [6.75, 7.75], [7, 8]]
```

### Image Resize

As shown in the **3D resize** example, multi-channel (RGB) images can be resized as:

```d
auto image = [255, 0, 0,  0, 255, 0,  0, 0, 255,  255, 255, 255].sliced(2, 2, 3).asType!ubyte;
auto resizedImage = image.resize(300, 300);
resizedImage.imwrite("./result/resizedImage.png");
```

Output image:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/imgmanip/result/resizedImage.png)

### Image Scale

Similar to resize, images can be scaled. Image scaling calls resize internally with scaled image size by given value.

```d
// scale image:
auto scaledImage = resizedImage.scale(2., 2.);
scaledImage.imwrite("./result/scaledImage.png");
```

Output image:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/imgmanip/result/scaledImage.png)


## Image Transform

Affine and Perspective transformation over images can be performed by using dcv.imgproc.imgmanip.transformAffine,
and transformPerspective functions. 

Functions take the slice of an image as first argument, which can be 2D, and 3D. Second argument is a 3x3 
transformation matrix, which can be defined as Slice object, or as build in 2D array in floating point type. 
Third argument is the output image size. And as in resize, first template argument is an alias to interpolation 
function, which is by default linear.

### Code

```d
import std.math : sin, cos, PI;

image = imread("../data/lena.png").sliced!ubyte;

double ang = PI / 4.; // rotation angle
double t_x = 30.; // x offset
double t_y = -100.; // y offset
size_t [2] outSize = [image.length!1 * 2, image.length!0 * 2]; // output size: [width*2, height*2]

// transform image:
auto transformedImage = image.transformAffine([
		[cos(ang), -sin(ang), t_x],
		[sin(ang), cos(ang), t_y],
		[0., 0., 1.]
	], outSize); 

transformedImage.imwrite("./result/transformedImage.png");
```

Output image:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/imgmanip/result/transformedImage.png)

