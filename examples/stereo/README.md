# Stereo Matching
*... by [Henry Gouk](https://github.com/henrygouk)*

This example shows how to use stereo matching utilities in DCV.

## Modules used
* dcv.imgproc
* dcv.io.image
* dcv.plot
* dcv.multiview.stereo.matching

## Stereo Matching Pipeline

Stereo matching API is realized through the `dcv.multiview.stereo.matching.StereoPipeline` class. This class provides a 
framework for constructing stereo matching pipelines that conform to the taxonomy laid out in [Scharstein and Szeliski (2002)](http://vision.middlebury.edu/stereo/taxonomy-IJCV.pdf).

According to this taxonomy, stereo matching can be divided into four steps:

1. Matching cost computation
2. Cost aggregation
3. Disparity computation
4. Disparity refinement

Implementations of various algorithms that conform to requirements of these components
can be found in `dcv.multiview.stereo.matching` module, as well as several helper functions that will create
commonly used pipelines out of these building blocks.

## Semiglobal Stereo Matching

One particular pipeline construct in DCV is the semiglobal matching[1], initialized with `dcv.multiview.stereo.matching.semiGlobalMatchingPipeline` 
function. **Absolute difference** is used here for computing costs, **winner takes all** algorithm is used to compute disparity map, which is afterwards refined
with **median filter**.

*[1] Hirschmuller, H. (2008). Stereo processing by semiglobal matching and mutual information. IEEE Transactions on pattern analysis and machine intelligence, 30(2), 328-341.*

## Results

Let's use *Cones* example images, from [Middlebury dataset](http://vision.middlebury.edu/stereo/data/):

![middlebury-cones](https://github.com/libmir/dcv/blob/master/examples/data/stereo/example_anim.gif)

In the example code, paths to stereo pair (left and right images) and to it's ground truth disparity map should be supplied as entry point arguments.
Given stereo pair is used to estimate disparity map with semiglobal matching algorithm, which is afterwards compared against given ground truth image. 
Here are the estimated disparity map results from the example program, and ground truth disparity map for *Cones* by Middlebury:

![disparity-results](https://github.com/libmir/dcv/blob/master/examples/data/stereo/result_anim.gif)

