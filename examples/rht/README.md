# Image filtering example


This example should demonstrate how to use Randomized Hough Transform to detect
shapes in images. 
Should showcases a few basics such as image i/o, conversion to Slice object etc.


## Modules used
* dcv.core.image
* dcv.core.utils
* dcv.io
* dcv.imgproc
* dcv.features.rht

## Source Image

As source image in this example is a bunch of geometic shapes (img.png).
Source data is loaded with next chunk of code:

```d
string impath = (args.length < 2) ? "../data/img.png" : args[1];

Image img = imread(impath); // read an image from filesystem.

if (img.empty) { // check if image is properly read.
	writeln("Cannot read image at: " ~ impath);
	return 1;
}

Slice!(3, float*) imslice = img
	.asType!float // convert Image data type from ubyte to float
	.sliced!float; // slice image data - calls img.data!float.sliced(img.height, img.width, img.channels)
```

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/data/img.png)


## Gaussian Blurring

Classic gaussian kernel is created using ```dcv.imgproc.filter.gaussian``` function. By convolving an image with created kernel, we filter out potential noise in the image.

### Code

We create gaussian (2D) kernel with sigma value of 2.0, of size 5x5, and then we convolve the image 
with it:

```d
auto gaussianKernel = gaussian!float(2, 5, 5);
auto blur = imslice.conv(gaussianKernel);
```

### Result

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/rht/result/outblur.png)


## Edge Detection

In this example, we apply classic Canny filter to detect edges:

```d
auto canny = blur.canny!ubyte(80);
```

### Result

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/rht/result/canny.png)

## Randomized Hough Transform (RHT)

### RHT for lines

Next step is to setup RHT context with key parameters that affect fundamental  properties such as time vs accuracy trade-off. The most important are `epouchs` - number of attempts to detect a shape, and `iterations` - number of steps in each attempt. Small number of iterations leads to poor accuracy, too high a number wastes a lot of CPU cycles. Since not every attempt is successul (being randomized method) the number of epouchs is advised to be 2-4 times larger than the number of expected shapes. `minCurve` parameter allows to filter out degenerate shapes with too few pixels, here we require at least 25 pixels in a shape:

```d
auto lines = RhtLines().epouchs(50).iterations(250).minCurve(25);
```

Apply method and iterate the lazily computating shapes:
```d
foreach(line; linesRange) {
	writeln(line);
	plotLine(imslice, line, [1.0, 1.0, 1.0]);
}
``` 
It is therefore easy to compute just enough of epouchs to get the first few likely shapes. 

### RHT for circles

Simillar setup is performed for RHT context for circles, using familliar key parameters.

```d
auto circles = RhtCircles().epouchs(5).iterations(2000).minCurve(16);
```

One twist is application of circle RHT, this time around we use it only on points left off after filtering out lines. This is especially useful filtering technique in pictures where circles is a minory compared to simple lines. Accessing filtered points has other use cases such as reconstructing the scene with some shapes removed.

```d
foreach(circle; circles(canny, linesRange.points[])) {
	writeln(circle);
	plotCircle(imslice, circle, [1.0, 1.0, 1.0]);
}
```

### Result

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/rht/result/rht.png)
