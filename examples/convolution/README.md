# Image convolution example


This example should demonstrate how to perform 2D [convolution](https://en.wikipedia.org/wiki/Kernel_(image_processing)) to an image. 
Should also provide insight to basic setup for any image processing, such as image i/o, image convertion to Slice object etc.


## Modules used
* dcv.core.image - Image, asType
* dcv.core.utils - Slice.asType
* dcv.io - imread, imwrite
- dcv.imgproc.convolution - conv

## Result

Naive version of the algorithm is implemented so far, so it's quite slow - my machine with six core AMD Phenom processor 
takes ~120ms for this example. Separable implementation should be done in the future, aswell as simd support for 
spatial domain 1D convolution.

*note: thread spawning on the application entry can mess up stopwatch significantly on my machine, so I've put Thread.getThis.sleep
just before timing the convolution...*


Complete output on my machine is:
```
Waiting for threads to be spawned and ready...
Convolution done in: 122ms
```

Input image:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/data/lena.png)

Blurred image:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/convolution/result/outblur.png)
