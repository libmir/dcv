# Kanade-Lucas-Tomasi Tracking Example

This example demonstrates usage of Pyramidal Lucas-Kanade Optical Flow algorithm implementation in dcv.

## Modules used
 * dcv.core;
 * dcv.imageio;
 * dcv.imgproc.filter : filterNonMaximum;
 * dcv.imgproc.color : gray2rgb;
 * dcv.features.corner.harris : shiTomasiCorners;
 * dcv.features.utils : extractCorners;
 * dcv.tracking.opticalflow : LucasKanadeFlow, SparsePyramidFlow;

## Example description

 In this example, [Kanade-Lucas-Tomasi](https://en.wikipedia.org/wiki/Kanade%E2%80%93Lucas%E2%80%93Tomasi_feature_tracker) 
 tracker is implemented to demonstrate feature tracking with [Lucas-Kanade](https://en.wikipedia.org/wiki/Lucas%E2%80%93Kanade_method) optical flow method. 
 KLT is very popular technique used to help solve various tasks such as [match moving](https://en.wikipedia.org/wiki/Match_moving).
 Similar to Horn-Schunck method, Lucas-Kanade is used to estimate field displacement of two adjacent frames in the video, only 
 here the displacement is estimated locally, around a distinct feature point in the frame. 

## Video Input

 Similarly as in the [video](https://github.com/libmir/dcv/tree/master/examples/video) example, video input
 is implemented to support file loading, as well as the web camera live streaming. **Only, please note that this implementation
 is not optimized to run in real-time yet, so web cam tracking would most probably achieve bad results.**

## Lucas-Kanade Flow

 With similar API as in the [dense flow](https://github.com/libmir/dcv/tree/master/examples/tracking/hornschunck) 
 we can instantiate Lucas-Kanade flow algorithm, and then instantiate Sparse Pyramidal Flow algorithm:

 ```d
 LucasKanadeFlow lkFlow = new LucasKanadeFlow;
 SparsePyramidFlow spFlow = new SparsePyramidFlow(lkFlow, pyrLevels);
 ```

## Tracking

 Tracking algorithm is most trivially defined as:
 1. grab next frame
 2. find N shi-tomasi corners in the frame
 3. grab next frame
 4. estimate lucas-kanade flow for each corner, between these two frames
 5. discard poorly tracked corners (ones that result in small corner eigenvalue by [Shi-Tomasi formula](https://en.wikipedia.org/wiki/Corner_detection#The_Harris_.26_Stephens_.2F_Plessey_.2F_Shi.E2.80.93Tomasi_corner_detection_algorithms)
 6. extract new corners so that sum of old and new corners is N
 7. repeat from 3, until no more frames. 

 Here is the sneak preview of the tracking, performed on the *dcv/examples/data/centaur_1.mpg* file:

 ![alt](https://github.com/libmir/dcv/blob/master/examples/tracking/klt/result/track.gif)
