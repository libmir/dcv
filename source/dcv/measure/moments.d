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
    
    double m00, m10, m01, m20, m11, m02, m30, m21, m12, m03, // spatial raw moments
        mu20, mu11, mu12, mu02, mu03, mu30, mu21, // central moments
        nu20, nu11, nu02, nu30, nu21, nu12, nu03; // normalized central moments
}

@nogc nothrow:

/** Compute raw moments of a binary region.

Params:
    contour = a contour slice N = 2 * npoints, an element of Contours from findContours  
    imbin = Input binary image of ubyte (0 for background)

Returns raw moments
*/
Moments calculateMoments(SliceView)(const ref Contour contour, SliceView imbin){
    
    auto xMax = cast(size_t)contour.colMax(0);
    auto yMax = cast(size_t)contour.colMax(1);

    auto xMin = cast(size_t)contour.colMin(0);
    auto yMin = cast(size_t)contour.colMin(1);

    auto subWin = imbin[xMin..xMax+1, yMin..yMax+1];

    //auto subWin = sWin[xMin, yMin];

    double m00 = 0, m10 = 0, m01 = 0, m20 = 0, m11 = 0, m02 = 0, m30 = 0, m21 = 0, m12 = 0, m03 = 0;
    double mu20 = 0, mu11 = 0, mu12 = 0, mu02 = 0, mu03 = 0, mu30 = 0, mu21 = 0;
    double nu20 = 0, nu11 = 0, nu02 = 0, nu30 = 0, nu21 = 0, nu12 = 0, nu03 = 0;

    //m00 = contour.contourArea;
    
    size_t yGrid;
    size_t xGrid;
    
    foreach(i; 0..subWin.shape[0] * subWin.shape[1]){
        
        yGrid = i % subWin.shape[1];
        xGrid = i / subWin.shape[1];
        
        if(subWin[xGrid, yGrid] == 0)
            continue;
        m00 += 1;
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
    if(m00 != 0) {
        double inv_m00 = 1.0 / m00;
        auto inv_sqrt_m00 = sqrt(inv_m00);
        mu20 = inv_m00 * m20 - (m10 * m10) * inv_m00 * inv_m00;
        mu11 = inv_m00 * m11 - (m10 * m01) * inv_m00 * inv_m00;
        mu02 = inv_m00 * m02 - (m01 * m01) * inv_m00 * inv_m00;
        mu30 = inv_m00 * m30 - 3 * m12 * inv_m00 * m10 + 2 * m10 * m10 * inv_m00 * inv_m00 * inv_m00 * m10;
        mu21 = inv_m00 * m21 - 2 * m10 * inv_m00 * mu11 - 2 * m01 * inv_m00 * inv_m00 * mu20 +
            (m01 * m10) * inv_m00 * inv_m00 * inv_m00 * inv_m00 * m01;
        
        mu12 = inv_m00 * m12 - m11 * inv_m00 * mu11 -
            m01 * inv_m00 * mu02 - m10 * inv_m00 * inv_m00 * mu21 +
            2 * m01 * inv_m00 * inv_m00 * mu11 * m10 +
            (m01 * m01) * inv_m00 * inv_m00 * inv_m00 * inv_m00 * m02;
        mu03 = inv_m00 * m03 - 3 * m01 * inv_m00 * mu02 +
            2 * m01 * m01 * inv_m00 * inv_m00 * inv_m00 * inv_m00 * m01;

        nu20 = mu20 * inv_sqrt_m00 * inv_sqrt_m00;
        nu11 = mu11 * inv_sqrt_m00 * inv_sqrt_m00;
        nu02 = mu02 * inv_sqrt_m00 * inv_sqrt_m00;
        nu30 = mu30 * inv_sqrt_m00 * inv_sqrt_m00 * inv_sqrt_m00;
        nu21 = mu21 * inv_sqrt_m00 * inv_sqrt_m00 * inv_sqrt_m00;
        nu12 = mu12 * inv_sqrt_m00 * inv_sqrt_m00 * inv_sqrt_m00;
        nu03 = mu03 * inv_sqrt_m00 * inv_sqrt_m00 * inv_sqrt_m00;
    }
    return Moments(m00, m10, m01, m20, m11, m02, m30, m21, m12, m03,
        mu20, mu11, mu12, mu02, mu03, mu30, mu21,
        nu20, nu11, nu02, nu30, nu21, nu12, nu03);
}