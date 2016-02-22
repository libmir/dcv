# Corner detection example


This example demonstrates corner detection algorithms - Harris, and Shi-Tomasi.


## Modules used
* dcv.core;
* dcv.features
* dcv.imgproc.color;
* dcv.imgproc.filter;
* dcv.io;

## Example description

In the source code both Harris and Shi-Tomasi corner extraction is performed, but for simplicity's sake, here we'll explain only Harris code usage - the API is same for both algorithms, so the Shi-Tomasi should be clear as well.

Example code will be broken down to segments, explaining each step.

First reading of the building example from the /examples/data:

```d
auto image = imread("../data/building.png");
```

So, the input image is:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/data/building.png)

Following chunk of code prepares the data for corner extraction - slices the image data, makes grayscale version of the image, and copies the input image where the corners will be drawn out.

```d
// prepare working sliced
auto imslice = image.sliced!ubyte;
auto imfslice = imslice.asType!float;
auto gray = imfslice.rgb2gray;

// make copies to draw corners 
auto pixelSize = imslice.shape.reduce!"a*b";
auto harrisDraw = new ubyte[pixelSize].sliced(imslice.shape);
harrisDraw[] = imslice[];
```

Next call will estimate the Harris corner response for each pixel in the image, and in the pipeline call the non-maximum filtering method, which will locally supress lower response values, and leave out the higher ones:
```d
auto harrisResponse = harrisCorners(gray).filterNonMaximum;
```

After the response matrix is estimated and filtered, we can call ```extractCorners```, which will return dynamic array of ulong[2] values, as in pixel coordinates where responses are strong by the given criteria:

```d
// extract corners from the response matrix ( extract 100 corners, where each response is larger than 0.)
auto harrisCorners = extractCorners(harrisResponse, 100, 0.);
```

After the extraction, we draw corners by using dummy function (which will hopefully be replaced in plot module with a proper one), and save the responses and the drawn corners to the file system, in the result folder:

```d
harrisDraw.drawCorners(harrisCorners, 9, cast(ubyte[])[255, 0, 0]);

harrisResponse
  .byElement 
  .ranged(0., 255.) // scale the value range so it fits 0-255, for the preview.
  .array
  .sliced(harrisResponse.shape)
  .asType!ubyte // convert image (or the slice of an image data) from float to ubyte 
  .imwrite("result/harrisResponse.png");

harrisDraw.imwrite("result/harrisCorners.png");
```

So the response result image looks like:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/features/result/harrisResponse.png)

And the drawn corners:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/features/result/harrisCorners.png)
