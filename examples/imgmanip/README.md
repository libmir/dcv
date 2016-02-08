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
auto scaledImage = array.scale!customInterpolation(scaleValue) etc.
```

Example so far only demonstrates how to resize an ND array.

### 1D resize

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

### 2D resize

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

### 3D resize

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

### Image resize

As shown in the **3D resize** example, multi-channel (RGB) images can be resized as:

```d
auto image = [255, 0, 0,  0, 255, 0,  0, 0, 255,  255, 255, 255].sliced(2, 2, 3).asType!ubyte;
auto resizedImage = image.resize(300, 300);
resizedImage.imwrite("./result/resizedImage.png");
```

Output image:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/imgmanip/result/resizedImage.png)
