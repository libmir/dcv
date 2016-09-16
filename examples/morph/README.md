# Morphological Operations Example

This example should demonstrate how to perform morphological operation on binary images in DCV, such as erode, dilate, open and close.

## Modules used

*   dcv.core
*   dcv.io
*   dcv.imgproc
*   dcv.plot

## Source Image

As in other examples, here we’ll use Lena image as source (input image). We’ll convert it to grayscale, then afterwards threshold its values in a way to achieve reasonable results usable for demonstrating morphology operations.

Here is the grayscale:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/data/lena_gray.png)

## Thresholding

To apply morphological operations, we first binarize the grayscale image. With following code:

```d
auto thesholded = slice.threshold!ubyte(30, 60);
```

… we get following image:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/morph/result/thresholded.png)

## Morphological Ops

Following functions in DCV perform morphological operations: [erode](https://ljubobratovicrelja.github.io/dcv/?loc=dcv_imgproc_filter.html#erode), [dilate](https://ljubobratovicrelja.github.io/dcv/?loc=dcv_imgproc_filter.html#dilate), [open](https://ljubobratovicrelja.github.io/dcv/?loc=dcv_imgproc_filter.html#open), [close](https://ljubobratovicrelja.github.io/dcv/?loc=dcv_imgproc_filter.html#close). Those functions have identical API - by using given kernel, apply chosen morphological operation to given image slice. Most basic kernels used in these functions would be [boxKernel](https://ljubobratovicrelja.github.io/dcv/?loc=dcv_imgproc_filter.html#boxKernel)(or [radialKernel](https://ljubobratovicrelja.github.io/dcv/?loc=dcv_imgproc_filter.html#radialKernel) if blocky effects are obvious), but other custom shaped kernels can be provided.

### Erode

In this example we erode the image with radialKernel of radius size 5:

```d
auto eroded = thesholded.erode(radialKernel!ubyte(5));
```

This gives us following result:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/morph/result/eroded.png)

When we zoom at the eye, and switch between input image, and the result we can clearly see that bordering white pixels have been “eroded”:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/morph/result/erodeanim.gif)

### Dilate

Inverse of erosion, dilation will grow white pixel field with given kernel. In this example we use the same kernel in each morphological operation, so following command:

```d
auto dilated = thesholded.dilate(radialKernel!ubyte(5));
```


… Will produce following image:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/morph/result/dilated.png)

Same as before, we can analyze the result more closely by looking at the zoomed gif:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/morph/result/dilateanim.gif)

### Open

Opening operation is used, as the name implies, to open closing forms. It will suppress slimmer edges, where concentration of white pixels is low, but will keep overall shape of regions with denser distribution of white pixels. We'll skip the code, since its fairly similar as in dilate and erode example. Here is the opening result:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/morph/result/opened.png)

Looking at zoomed eye region, we can see that eye-line on the lower edge has disappeared, i.e. "opened":

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/morph/result/openanim.gif)

### Close

Opposite of the opening, closing tends to close, or fill holes in forms. Here is the result:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/morph/result/closed.png)

Effects are obvious when looking at zoomed eye region in gif comparison with the input image:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/morph/result/closeanim.gif)
