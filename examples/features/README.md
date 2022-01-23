# Corner detection example


This example demonstrates corner detection algorithms - Harris, and Shi-Tomasi.


## Modules used
* dcv.core
* dcv.features
* dcv.imgproc.color
* dcv.imgproc.filter
* dcv.imageio

## Example description

In the source code both Harris and Shi-Tomasi corner extraction is performed, but for simplicity's sake, here we'll explain only Harris code usage - the API is same for both algorithms, so the Shi-Tomasi should be clear as well.

Example code will be broken down to segments, explaining each step.

First reading of the building example from the /examples/data:

```d
auto image = imread("../data/building.png");
```

So, the input image is:

![alt tag](https://github.com/libmir/dcv/blob/master/examples/data/building.png)

Following chunk of code prepares the data for corner extraction - slices the image data, makes grayscale version of the image, and copies the input image where the corners will be drawn out.

```d
// prepare working sliced
auto imslice = image.sliced!ubyte;
auto imfslice = imslice.as!float.slice;
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

After the extraction, we plot and save extracted corners:

```d
auto xs = corners.map!(v => v[1]);
auto ys = corners.map!(v => v[0]);

auto aes = Aes!(typeof(xs), "x", typeof(ys), "y", bool[], "fill", string[], "colour")(xs, ys,
        false.repeat(xs.length).array, "red".repeat(xs.length).array);

auto gg = GGPlotD().put(geomPoint(aes));

// plot corners on the same figure, and save it's image to disk.
slice.plot(gg, windowName).image().imwrite("result/" ~ windowName ~ ".png");
```

... And process the response for easier visualization, then save it to *result* folder:

```d
harrisResponse 
    // Scale values to fit 0-255 range,
    .byElement
    .ranged(0., 255.).array.sliced(harrisResponse.shape)
    .as!ubyte
    .slice
    // .. show the window,
    .imshow(windowName) 
    .image
    // ... but also write it to disk.
    .imwrite("result/" ~ windowName ~ ".png");
```

So the response result image looks like:

![alt tag](https://github.com/libmir/dcv/blob/master/examples/features/result/harrisResponse.png)

And the drawn corners:

![alt tag](https://github.com/libmir/dcv/blob/master/examples/features/result/harrisCorners.png)
