# Kanade-Lucas-Tomasi Tracking Example

This example demonstrates usage of Pyramidal Lucas-Kanade Optical Flow algorithm implementation in dcv.


## Modules used
 * dcv.core;
 * dcv.io;
 * dcv.imgproc.filter : filterNonMaximum;
 * dcv.imgproc.color : gray2rgb;
 * dcv.features.corner.harris : shiTomasiCorners;
 * dcv.features.utils : extractCorners;
 * dcv.tracking.opticalflow : LucasKanadeFlow, SparsePyramidFlow;

## Example description

 In this example, [Kanade-Lucas-Tomasi](https://en.wikipedia.org/wiki/Kanade%E2%80%93Lucas%E2%80%93Tomasi_feature_tracker) 
 tracker is implemented to demonstrate feature tracking with [Lucas-Kanade](https://en.wikipedia.org/wiki/Lucas%E2%80%93Kanade_method) optical flow method.
 Similar to Horn-Schunck method, Lucas-Kanade is used to estimate field displacement of two adjacent frames in the video, only 
 here the displacement is estimated locally, around a distinct feature point in the frame. 

 For detailed info, please take a look into the example's source code.
