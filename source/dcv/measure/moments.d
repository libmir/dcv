/*
Copyright (c) 2021- Ferhat Kurtulmuş
Boost Software License - Version 1.0 - August 17th, 2003
*/
module dcv.measure.moments;

import dcv.measure.contours;

import std.math;

import mir.algorithm.iteration;
import mir.ndslice.topology;
import mir.ndslice;

struct Moments {
    // spatial raw moments
    double m00, m10, m01, m20, m11, m02, m30, m21, m12, m03;
}

/** Compute raw moments of a binary region.

Params:
    contour = a contour slice N = 2 * npoints, an element of Contours from findContours  
    imbin = Input binary image of ubyte (0 for background)

Returns raw moments
*/
Moments calculateMoments(SliceView)(const ref Contour contour, ref SliceView imbin){

    auto xMax = cast(size_t)contour.colMax(0).round;
    auto yMax = cast(size_t)contour.colMax(1).round;

    auto xMin = cast(size_t)contour.colMin(0).round;
    auto yMin = cast(size_t)contour.colMin(1).round;

    auto sWin = imbin.windows(xMax-xMin +1, yMax-yMin +1);

    auto subWin = sWin[xMin, yMin];

    double m00 = 0, m10 = 0, m01 = 0, m20 = 0, m11 = 0, m02 = 0, m30 = 0, m21 = 0, m12 = 0, m03 = 0;

    m00 = contour.contourArea;
    
    ulong yGrid;
    ulong xGrid;
    
    foreach(i; 0..subWin.shape[0] * subWin.shape[1]){
        
        yGrid = i % subWin.shape[1];
        xGrid = i / subWin.shape[1];
        
        m01 += xGrid*(subWin[xGrid, yGrid]/255);
        m10 += yGrid*(subWin[xGrid, yGrid]/255);
        m11 += yGrid*xGrid*(subWin[xGrid, yGrid]/255);
        m02 += (xGrid^^2)*(subWin[xGrid, yGrid]/255);
        m20 += (yGrid^^2)*(subWin[xGrid, yGrid]/255);
        m12 += xGrid*(yGrid^^2)*(subWin[xGrid, yGrid]/255);
        m21 += (xGrid^^2)*yGrid*(subWin[xGrid, yGrid]/255);
        m03 += (xGrid^^3)*(subWin[xGrid, yGrid]/255);
        m30 += (yGrid^^3)*(subWin[xGrid, yGrid]/255);
    }

    return Moments(m00, m10, m01, m20, m11, m02, m30, m21, m12, m03);
}