# Image convolution example


This example should demonstrate how to perform 2D [convolution](https://en.wikipedia.org/wiki/Kernel_(image_processing)) to an image. 
Should also provide insight to basic setup for any image processing, such as image i/o, image convertion to Slice object etc.


## Modules used
* dcv.core.image - Image
* dcv.core.utils - Slice.asType
* dcv.io - imread, imwrite
* dcv.imgproc.color - rgb2gray
- dcv.imgproc.convolution - conv

## Result

Input image:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/data/lena.png)

Grayscale version:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/convolution/result/outgray.png)

Average:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/convolution/result/outblur.png)
