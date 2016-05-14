# Optical Flow Example


This example demonstrates usage of Pyramidal Horn-Schunck optical flow algorithm implementation in DCV library.


## Modules used
* import dcv.core
* import dcv.io
* import dcv.imgproc.imgmanip
* import dcv.tracking.opticalflow
* import dcv.plot.opticalflow

## Example description

In this example, optical flow benchmark data set from [Middlebury University's website](http://vision.middlebury.edu/flow/data/) 
is used to demonstrate the algorithm results. Some of this data is present in the 
[library's example data directory](https://github.com/ljubobratovicrelja/dcv/tree/master/examples/data/optflow).

For simple demonstaration, let's take the **Army** image pair from Middlebury:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/data/optflow/Army/frame10.png)
![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/data/optflow/Army/frame11.png)

The Horn-Schunck properties are stored in the `HornSchunckProperties` structure. Here is the chunck of code
where those are initialized:

```d
// Setup algorithm parameters.
HornSchunckProperties props = HornSchunckProperties();
props.iterationCount = args.length >= 4 ? args[3].to!int : 100;
props.alpha = args.length >= 5 ? args[4].to!float : 10.0f;
props.gaussSigma = args.length >= 6 ? args[5].to!float : 1.0f;
props.gaussKernelSize = args.length >= 7 ? args[6].to!uint : 3;

uint pyramidLevels = args.length >= 8 ? args[7].to!int : 3;

```

Following chunck of code initializes the Optical Flow algorithm objects, and calls the flow evaluation:
```d
HornSchunckFlow hsFlow = new HornSchunckFlow(props);
DensePyramidFlow densePyramid = new DensePyramidFlow(hsFlow, pyramidLevels); 

auto flow = densePyramid.evaluate(current, next);
 ```

Returning value `flow` is of type Slice!(3, float*), as matrix of float[2] (uv, or xy) displacement values. 
In the following chucnk, we color-code this displacement map by using `dcv.plot.opticalflow.colorCode` function, 
and also use it to warp the `current` image by use of `dcv.imgproc.imgmanip.warp` function,
so we can nicely visualize the success rate of the computed flow values:

```d
auto flowColor = flow.colorCode;
auto flowWarp = current.sliced.warp(flow);
```

Here is the color code of computed flow for *Army* images:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/opticalflow/result/2_flowColor.png)


And lastly we write out these images in following order:

```d
current.imwrite("./result/1_current.png");
flowColor.imwrite(ImageFormat.IF_RGB, "./result/2_flowColor.png");
flowWarp.imwrite(ImageFormat.IF_MONO, "./result/3_flowWarp.png");
next.imwrite("./result/4_next.png");
```

Images are written in this order to help you inspect them in ordinary image viewer application. Assuming that
files in your directory are sorted by name, you could switch easily between warped image and target (next) image, 
and see clearly the difference between the original and computed (warped) one.

## Example Program

Please refer to example program's help for more info (./optical flow -h).

## Note

Currently only 8-bit mono images are supported in the `HornSchunckFlow` implementation. This will be resolved in
future to support RGB images in 16, and 32 bit depth.



