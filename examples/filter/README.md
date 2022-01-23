# Image filtering example


This example should demonstrate how to apply basic spatial filtering methods to images, using dcv.
Should also provide insight to basic setup for any image processing, such as image i/o, image convertion to Slice object etc.


## Modules used
* dcv.core.image
* dcv.core.utils
* dcv.imageio
* dcv.imgproc

## Source Image

As source image in this example, Lena image is used (Lena Söderberg). Source data is loaded with next chunk of code:

```d
string impath = (args.length < 2) ? "../data/lena.png" : args[1];

Image img = imread(impath); // read an image from filesystem.

if (img.empty) { // check if image is properly read.
	writeln("Cannot read image at: " ~ impath);
	return 1;
}

Slice!(3, float*) imslice = img
    .sliced // slice image data
    .as!float // convert it to float
    .slice // make a copy.
```

![alt tag](https://github.com/libmir/dcv/blob/master/examples/data/lena.png)


## Filter Kernel Creation

In this example spatial filtering is done with image convolution by using gaussian, sobel,
laplacian and LoG(laplacian of gaussian) operators. These operators can be created by using 
functions present in ```dcv.imgproc.filter``` module. Each function takes a template argument
as matrix (Slice) type, which is by default ```real```.


## Gaussian Blurring

Classic gaussian kernel is created using ```dcv.imgproc.filter.gaussian``` function. By convolving an image
with created kernel, we can perform image blurring.

### Code

We create gaussian (2D) kernel with sigma value of 2.0, of size 5x5, and then we convolve the image 
with it:

```d
auto gaussianKernel = gaussian!float(2, 5, 5);
auto blur = imslice.conv(gaussianKernel);
```

### Result

![alt tag](https://github.com/libmir/dcv/blob/master/examples/filter/result/outblur.png)


## Edge Detection

In this example, few well known operators are used for spatial edge extraction - sobel, laplacian and laplacian of gaussian.
Operators are created with:

```d
auto sobelXKernel = sobel!real(GradientDirection.DIR_X); // sobel operator for horizontal (X) gradients
auto laplacianKernel = laplacian!double; // laplacian kernel, similar to matlabs fspecial('laplacian', alpha)
auto logKernel = laplacianOfGaussian(1, 5, 5); // laplacian of gaussian, similar to matlabs fspecial('log', alpha, width, height)
```

### Sobel

Gradient direction for sobel operator can be defined with input argument:

```d
// GradientDirection.DIR_X:
	-1, 0, 1,
	-2, 0, 2,
	-1, 0, 1

// GradientDirection.DIR_Y:
	-1, -2, -1,
	0, 0, 0,
	1, 2, 1

// GradientDirection.DIAG:
	-2, -1, 0,
	-1, 0, 1,
	0, 1, 2

// GradientDirection.DIAG_INV:
	0, -1, -2,
	1, 0, -1,
	2, 1, 0
```
#### Result

![alt tag](https://github.com/libmir/dcv/blob/master/examples/filter/result/sobel.png)

### Laplacian

Laplacian kernel function creates negative 3x3 laplacian kernel defined as:

```d
              | a/4,    (1-a)/4,   a/4 |
    4/(a+1) * | (1-a)/4   -1   (1-a)/4 |
              | a/4,    (1-a)/4,   a/4 |
```

... so for the alpha value of 0 (which is the default value), we get:

```d
0  1  0
1 -4  1
0  1  0
```

#### Result

![alt tag](https://github.com/libmir/dcv/blob/master/examples/filter/result/laplace.png)

### Laplacian Of Gaussian

LoG operator function creates an kernel by [LoG formula](http://homepages.inf.ed.ac.uk/rbf/HIPR2/log.htm),
and normalize it so it's sum is 0.

#### Result

![alt tag](https://github.com/libmir/dcv/blob/master/examples/filter/result/log.png)

