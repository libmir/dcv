module dcv.features.corner.fast.fast_11;

/*
Authors: Edward Rosten
Copyright: Copyright (c) 2006, 2008 Edward Rosten, All rights reserved.

Additional notice:
Module integrates FAST implementation present in the Edward Rosten's
github repository: https://github.com/edrosten/fast-C-src
*/

import core.stdc.stdlib : malloc, free, realloc;

import dcv.features.corner.fast.base;


int fast11_corner_score(const ubyte* p, const int *pixel, int bstart)
{    
    int bmin = bstart;
    int bmax = 255;
    int b = (bmax + bmin)/2;
    
    /*Compute the score using binary search*/
    for(;;)
    {
        int cb = *p + b;
        int c_b= *p - b;

        
        if( p[pixel[0]] > cb)
            if( p[pixel[1]] > cb)
                if( p[pixel[2]] > cb)
                    if( p[pixel[3]] > cb)
                        if( p[pixel[4]] > cb)
                            if( p[pixel[5]] > cb)
                                if( p[pixel[6]] > cb)
                                    if( p[pixel[7]] > cb)
                                        if( p[pixel[8]] > cb)
                                            if( p[pixel[9]] > cb)
                                                if( p[pixel[10]] > cb)
                                                    goto is_a_corner;
                                                else
                                                    if( p[pixel[15]] > cb)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            if( p[pixel[14]] > cb)
                if( p[pixel[15]] > cb)
                    goto is_a_corner;
                else
                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[13]] > cb)
                if( p[pixel[14]] > cb)
                    if( p[pixel[15]] > cb)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[12]] > cb)
                if( p[pixel[13]] > cb)
                    if( p[pixel[14]] > cb)
                        if( p[pixel[15]] > cb)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[11]] > cb)
                if( p[pixel[12]] > cb)
                    if( p[pixel[13]] > cb)
                        if( p[pixel[14]] > cb)
                            if( p[pixel[15]] > cb)
                                goto is_a_corner;
                            else
                                goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[5]] < c_b)
            if( p[pixel[10]] > cb)
                if( p[pixel[11]] > cb)
                    if( p[pixel[12]] > cb)
                        if( p[pixel[13]] > cb)
                            if( p[pixel[14]] > cb)
                                if( p[pixel[15]] > cb)
                                    goto is_a_corner;
                                else
                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[10]] < c_b)
            if( p[pixel[6]] < c_b)
                if( p[pixel[7]] < c_b)
                    if( p[pixel[8]] < c_b)
                        if( p[pixel[9]] < c_b)
                            if( p[pixel[11]] < c_b)
                                if( p[pixel[12]] < c_b)
                                    if( p[pixel[13]] < c_b)
                                        if( p[pixel[14]] < c_b)
                                            if( p[pixel[15]] < c_b)
                                                goto is_a_corner;
                                            else
                                                goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[10]] > cb)
                if( p[pixel[11]] > cb)
                    if( p[pixel[12]] > cb)
                        if( p[pixel[13]] > cb)
                            if( p[pixel[14]] > cb)
                                if( p[pixel[15]] > cb)
                                    goto is_a_corner;
                                else
                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[4]] < c_b)
            if( p[pixel[15]] > cb)
                if( p[pixel[9]] > cb)
                    if( p[pixel[10]] > cb)
                        if( p[pixel[11]] > cb)
                            if( p[pixel[12]] > cb)
                                if( p[pixel[13]] > cb)
                                    if( p[pixel[14]] > cb)
                                        goto is_a_corner;
                                    else
                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[9]] < c_b)
            if( p[pixel[5]] < c_b)
                if( p[pixel[6]] < c_b)
                    if( p[pixel[7]] < c_b)
                        if( p[pixel[8]] < c_b)
                            if( p[pixel[10]] < c_b)
                                if( p[pixel[11]] < c_b)
                                    if( p[pixel[12]] < c_b)
                                        if( p[pixel[13]] < c_b)
                                            if( p[pixel[14]] < c_b)
                                                goto is_a_corner;
                                            else
                                                goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[5]] < c_b)
                if( p[pixel[6]] < c_b)
                    if( p[pixel[7]] < c_b)
                        if( p[pixel[8]] < c_b)
                            if( p[pixel[9]] < c_b)
                                if( p[pixel[10]] < c_b)
                                    if( p[pixel[11]] < c_b)
                                        if( p[pixel[12]] < c_b)
                                            if( p[pixel[13]] < c_b)
                                                if( p[pixel[14]] < c_b)
                                                    goto is_a_corner;
                                                else
                                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[9]] > cb)
                if( p[pixel[10]] > cb)
                    if( p[pixel[11]] > cb)
                        if( p[pixel[12]] > cb)
                            if( p[pixel[13]] > cb)
                                if( p[pixel[14]] > cb)
                                    if( p[pixel[15]] > cb)
                                        goto is_a_corner;
                                    else
                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[9]] < c_b)
            if( p[pixel[5]] < c_b)
                if( p[pixel[6]] < c_b)
                    if( p[pixel[7]] < c_b)
                        if( p[pixel[8]] < c_b)
                            if( p[pixel[10]] < c_b)
                                if( p[pixel[11]] < c_b)
                                    if( p[pixel[12]] < c_b)
                                        if( p[pixel[13]] < c_b)
                                            if( p[pixel[14]] < c_b)
                                                if( p[pixel[15]] < c_b)
                                                    goto is_a_corner;
                                                else
                                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[3]] < c_b)
            if( p[pixel[14]] > cb)
                if( p[pixel[8]] > cb)
                    if( p[pixel[9]] > cb)
                        if( p[pixel[10]] > cb)
                            if( p[pixel[11]] > cb)
                                if( p[pixel[12]] > cb)
                                    if( p[pixel[13]] > cb)
                                        if( p[pixel[15]] > cb)
                                            goto is_a_corner;
                                        else
                                            if( p[pixel[4]] > cb)
                                                if( p[pixel[5]] > cb)
                                                    if( p[pixel[6]] > cb)
                                                        if( p[pixel[7]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[8]] < c_b)
            if( p[pixel[4]] < c_b)
                if( p[pixel[5]] < c_b)
                    if( p[pixel[6]] < c_b)
                        if( p[pixel[7]] < c_b)
                            if( p[pixel[9]] < c_b)
                                if( p[pixel[10]] < c_b)
                                    if( p[pixel[11]] < c_b)
                                        if( p[pixel[12]] < c_b)
                                            if( p[pixel[13]] < c_b)
                                                goto is_a_corner;
                                            else
                                                goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[14]] < c_b)
            if( p[pixel[5]] < c_b)
                if( p[pixel[6]] < c_b)
                    if( p[pixel[7]] < c_b)
                        if( p[pixel[8]] < c_b)
                            if( p[pixel[9]] < c_b)
                                if( p[pixel[10]] < c_b)
                                    if( p[pixel[11]] < c_b)
                                        if( p[pixel[12]] < c_b)
                                            if( p[pixel[13]] < c_b)
                                                if( p[pixel[4]] < c_b)
                                                    goto is_a_corner;
                                                else
                                                    if( p[pixel[15]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[4]] < c_b)
                if( p[pixel[5]] < c_b)
                    if( p[pixel[6]] < c_b)
                        if( p[pixel[7]] < c_b)
                            if( p[pixel[8]] < c_b)
                                if( p[pixel[9]] < c_b)
                                    if( p[pixel[10]] < c_b)
                                        if( p[pixel[11]] < c_b)
                                            if( p[pixel[12]] < c_b)
                                                if( p[pixel[13]] < c_b)
                                                    goto is_a_corner;
                                                else
                                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[8]] > cb)
                if( p[pixel[9]] > cb)
                    if( p[pixel[10]] > cb)
                        if( p[pixel[11]] > cb)
                            if( p[pixel[12]] > cb)
                                if( p[pixel[13]] > cb)
                                    if( p[pixel[14]] > cb)
                                        if( p[pixel[15]] > cb)
                                            goto is_a_corner;
                                        else
                                            if( p[pixel[4]] > cb)
                                                if( p[pixel[5]] > cb)
                                                    if( p[pixel[6]] > cb)
                                                        if( p[pixel[7]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[8]] < c_b)
            if( p[pixel[5]] < c_b)
                if( p[pixel[6]] < c_b)
                    if( p[pixel[7]] < c_b)
                        if( p[pixel[9]] < c_b)
                            if( p[pixel[10]] < c_b)
                                if( p[pixel[11]] < c_b)
                                    if( p[pixel[12]] < c_b)
                                        if( p[pixel[13]] < c_b)
                                            if( p[pixel[14]] < c_b)
                                                if( p[pixel[4]] < c_b)
                                                    goto is_a_corner;
                                                else
                                                    if( p[pixel[15]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[2]] < c_b)
            if( p[pixel[7]] > cb)
                if( p[pixel[8]] > cb)
                    if( p[pixel[9]] > cb)
                        if( p[pixel[10]] > cb)
                            if( p[pixel[11]] > cb)
                                if( p[pixel[12]] > cb)
                                    if( p[pixel[13]] > cb)
                                        if( p[pixel[14]] > cb)
                                            if( p[pixel[15]] > cb)
                                                goto is_a_corner;
                                            else
                                                if( p[pixel[4]] > cb)
                                                    if( p[pixel[5]] > cb)
                                                        if( p[pixel[6]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[3]] > cb)
                if( p[pixel[4]] > cb)
                    if( p[pixel[5]] > cb)
                        if( p[pixel[6]] > cb)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[7]] < c_b)
            if( p[pixel[5]] < c_b)
                if( p[pixel[6]] < c_b)
                    if( p[pixel[8]] < c_b)
                        if( p[pixel[9]] < c_b)
                            if( p[pixel[10]] < c_b)
                                if( p[pixel[11]] < c_b)
                                    if( p[pixel[12]] < c_b)
                                        if( p[pixel[4]] < c_b)
                                            if( p[pixel[3]] < c_b)
                                                goto is_a_corner;
                                            else
                                                if( p[pixel[13]] < c_b)
                                                    if( p[pixel[14]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[13]] < c_b)
                if( p[pixel[14]] < c_b)
                    if( p[pixel[15]] < c_b)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[7]] > cb)
                if( p[pixel[8]] > cb)
                    if( p[pixel[9]] > cb)
                        if( p[pixel[10]] > cb)
                            if( p[pixel[11]] > cb)
                                if( p[pixel[12]] > cb)
                                    if( p[pixel[13]] > cb)
                                        if( p[pixel[14]] > cb)
                                            if( p[pixel[15]] > cb)
                                                goto is_a_corner;
                                            else
                                                if( p[pixel[4]] > cb)
                                                    if( p[pixel[5]] > cb)
                                                        if( p[pixel[6]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[3]] > cb)
                if( p[pixel[4]] > cb)
                    if( p[pixel[5]] > cb)
                        if( p[pixel[6]] > cb)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[7]] < c_b)
            if( p[pixel[5]] < c_b)
                if( p[pixel[6]] < c_b)
                    if( p[pixel[8]] < c_b)
                        if( p[pixel[9]] < c_b)
                            if( p[pixel[10]] < c_b)
                                if( p[pixel[11]] < c_b)
                                    if( p[pixel[12]] < c_b)
                                        if( p[pixel[13]] < c_b)
                                            if( p[pixel[4]] < c_b)
                                                if( p[pixel[3]] < c_b)
                                                    goto is_a_corner;
                                                else
                                                    if( p[pixel[14]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            if( p[pixel[14]] < c_b)
                if( p[pixel[15]] < c_b)
                    goto is_a_corner;
                else
                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[1]] < c_b)
            if( p[pixel[6]] > cb)
                if( p[pixel[7]] > cb)
                    if( p[pixel[8]] > cb)
                        if( p[pixel[9]] > cb)
                            if( p[pixel[10]] > cb)
                                if( p[pixel[11]] > cb)
                                    if( p[pixel[12]] > cb)
                                        if( p[pixel[13]] > cb)
                                            if( p[pixel[14]] > cb)
                                                if( p[pixel[15]] > cb)
                                                    goto is_a_corner;
                                                else
                                                    if( p[pixel[4]] > cb)
                                                        if( p[pixel[5]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[3]] > cb)
                if( p[pixel[4]] > cb)
                    if( p[pixel[5]] > cb)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[2]] > cb)
                if( p[pixel[3]] > cb)
                    if( p[pixel[4]] > cb)
                        if( p[pixel[5]] > cb)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[6]] < c_b)
            if( p[pixel[5]] < c_b)
                if( p[pixel[7]] < c_b)
                    if( p[pixel[8]] < c_b)
                        if( p[pixel[9]] < c_b)
                            if( p[pixel[10]] < c_b)
                                if( p[pixel[11]] < c_b)
                                    if( p[pixel[4]] < c_b)
                                        if( p[pixel[3]] < c_b)
                                            if( p[pixel[2]] < c_b)
                                                goto is_a_corner;
                                            else
                                                if( p[pixel[12]] < c_b)
                                                    if( p[pixel[13]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[12]] < c_b)
                if( p[pixel[13]] < c_b)
                    if( p[pixel[14]] < c_b)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[12]] < c_b)
                if( p[pixel[13]] < c_b)
                    if( p[pixel[14]] < c_b)
                        if( p[pixel[15]] < c_b)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[6]] > cb)
                if( p[pixel[7]] > cb)
                    if( p[pixel[8]] > cb)
                        if( p[pixel[9]] > cb)
                            if( p[pixel[10]] > cb)
                                if( p[pixel[11]] > cb)
                                    if( p[pixel[12]] > cb)
                                        if( p[pixel[13]] > cb)
                                            if( p[pixel[14]] > cb)
                                                if( p[pixel[15]] > cb)
                                                    goto is_a_corner;
                                                else
                                                    if( p[pixel[4]] > cb)
                                                        if( p[pixel[5]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[3]] > cb)
                if( p[pixel[4]] > cb)
                    if( p[pixel[5]] > cb)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[2]] > cb)
                if( p[pixel[3]] > cb)
                    if( p[pixel[4]] > cb)
                        if( p[pixel[5]] > cb)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[6]] < c_b)
            if( p[pixel[5]] < c_b)
                if( p[pixel[7]] < c_b)
                    if( p[pixel[8]] < c_b)
                        if( p[pixel[9]] < c_b)
                            if( p[pixel[10]] < c_b)
                                if( p[pixel[11]] < c_b)
                                    if( p[pixel[12]] < c_b)
                                        if( p[pixel[4]] < c_b)
                                            if( p[pixel[3]] < c_b)
                                                if( p[pixel[2]] < c_b)
                                                    goto is_a_corner;
                                                else
                                                    if( p[pixel[13]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            if( p[pixel[13]] < c_b)
                if( p[pixel[14]] < c_b)
                    goto is_a_corner;
                else
                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[13]] < c_b)
                if( p[pixel[14]] < c_b)
                    if( p[pixel[15]] < c_b)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[0]] < c_b)
            if( p[pixel[1]] > cb)
                if( p[pixel[6]] > cb)
                    if( p[pixel[5]] > cb)
                        if( p[pixel[7]] > cb)
                            if( p[pixel[8]] > cb)
                                if( p[pixel[9]] > cb)
                                    if( p[pixel[10]] > cb)
                                        if( p[pixel[11]] > cb)
                                            if( p[pixel[4]] > cb)
                                                if( p[pixel[3]] > cb)
                                                    if( p[pixel[2]] > cb)
                                                        goto is_a_corner;
                                                    else
                                                        if( p[pixel[12]] > cb)
                                                            if( p[pixel[13]] > cb)
                                                                goto is_a_corner;
                                                            else
                                                                goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[12]] > cb)
                if( p[pixel[13]] > cb)
                    if( p[pixel[14]] > cb)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[12]] > cb)
                if( p[pixel[13]] > cb)
                    if( p[pixel[14]] > cb)
                        if( p[pixel[15]] > cb)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[6]] < c_b)
            if( p[pixel[7]] < c_b)
                if( p[pixel[8]] < c_b)
                    if( p[pixel[9]] < c_b)
                        if( p[pixel[10]] < c_b)
                            if( p[pixel[11]] < c_b)
                                if( p[pixel[12]] < c_b)
                                    if( p[pixel[13]] < c_b)
                                        if( p[pixel[14]] < c_b)
                                            if( p[pixel[15]] < c_b)
                                                goto is_a_corner;
                                            else
                                                if( p[pixel[4]] < c_b)
                                                    if( p[pixel[5]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[3]] < c_b)
                if( p[pixel[4]] < c_b)
                    if( p[pixel[5]] < c_b)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[2]] < c_b)
                if( p[pixel[3]] < c_b)
                    if( p[pixel[4]] < c_b)
                        if( p[pixel[5]] < c_b)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[1]] < c_b)
            if( p[pixel[2]] > cb)
                if( p[pixel[7]] > cb)
                    if( p[pixel[5]] > cb)
                        if( p[pixel[6]] > cb)
                            if( p[pixel[8]] > cb)
                                if( p[pixel[9]] > cb)
                                    if( p[pixel[10]] > cb)
                                        if( p[pixel[11]] > cb)
                                            if( p[pixel[12]] > cb)
                                                if( p[pixel[4]] > cb)
                                                    if( p[pixel[3]] > cb)
                                                        goto is_a_corner;
                                                    else
                                                        if( p[pixel[13]] > cb)
                                                            if( p[pixel[14]] > cb)
                                                                goto is_a_corner;
                                                            else
                                                                goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[13]] > cb)
                if( p[pixel[14]] > cb)
                    if( p[pixel[15]] > cb)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[7]] < c_b)
            if( p[pixel[8]] < c_b)
                if( p[pixel[9]] < c_b)
                    if( p[pixel[10]] < c_b)
                        if( p[pixel[11]] < c_b)
                            if( p[pixel[12]] < c_b)
                                if( p[pixel[13]] < c_b)
                                    if( p[pixel[14]] < c_b)
                                        if( p[pixel[15]] < c_b)
                                            goto is_a_corner;
                                        else
                                            if( p[pixel[4]] < c_b)
                                                if( p[pixel[5]] < c_b)
                                                    if( p[pixel[6]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[3]] < c_b)
                if( p[pixel[4]] < c_b)
                    if( p[pixel[5]] < c_b)
                        if( p[pixel[6]] < c_b)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[2]] < c_b)
            if( p[pixel[3]] > cb)
                if( p[pixel[14]] > cb)
                    if( p[pixel[5]] > cb)
                        if( p[pixel[6]] > cb)
                            if( p[pixel[7]] > cb)
                                if( p[pixel[8]] > cb)
                                    if( p[pixel[9]] > cb)
                                        if( p[pixel[10]] > cb)
                                            if( p[pixel[11]] > cb)
                                                if( p[pixel[12]] > cb)
                                                    if( p[pixel[13]] > cb)
                                                        if( p[pixel[4]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            if( p[pixel[15]] > cb)
                                                                goto is_a_corner;
                                                            else
                                                                goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[14]] < c_b)
            if( p[pixel[8]] > cb)
                if( p[pixel[4]] > cb)
                    if( p[pixel[5]] > cb)
                        if( p[pixel[6]] > cb)
                            if( p[pixel[7]] > cb)
                                if( p[pixel[9]] > cb)
                                    if( p[pixel[10]] > cb)
                                        if( p[pixel[11]] > cb)
                                            if( p[pixel[12]] > cb)
                                                if( p[pixel[13]] > cb)
                                                    goto is_a_corner;
                                                else
                                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[8]] < c_b)
            if( p[pixel[9]] < c_b)
                if( p[pixel[10]] < c_b)
                    if( p[pixel[11]] < c_b)
                        if( p[pixel[12]] < c_b)
                            if( p[pixel[13]] < c_b)
                                if( p[pixel[15]] < c_b)
                                    goto is_a_corner;
                                else
                                    if( p[pixel[4]] < c_b)
                                        if( p[pixel[5]] < c_b)
                                            if( p[pixel[6]] < c_b)
                                                if( p[pixel[7]] < c_b)
                                                    goto is_a_corner;
                                                else
                                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[4]] > cb)
                if( p[pixel[5]] > cb)
                    if( p[pixel[6]] > cb)
                        if( p[pixel[7]] > cb)
                            if( p[pixel[8]] > cb)
                                if( p[pixel[9]] > cb)
                                    if( p[pixel[10]] > cb)
                                        if( p[pixel[11]] > cb)
                                            if( p[pixel[12]] > cb)
                                                if( p[pixel[13]] > cb)
                                                    goto is_a_corner;
                                                else
                                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[3]] < c_b)
            if( p[pixel[4]] > cb)
                if( p[pixel[15]] < c_b)
                    if( p[pixel[9]] > cb)
                        if( p[pixel[5]] > cb)
                            if( p[pixel[6]] > cb)
                                if( p[pixel[7]] > cb)
                                    if( p[pixel[8]] > cb)
                                        if( p[pixel[10]] > cb)
                                            if( p[pixel[11]] > cb)
                                                if( p[pixel[12]] > cb)
                                                    if( p[pixel[13]] > cb)
                                                        if( p[pixel[14]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[9]] < c_b)
            if( p[pixel[10]] < c_b)
                if( p[pixel[11]] < c_b)
                    if( p[pixel[12]] < c_b)
                        if( p[pixel[13]] < c_b)
                            if( p[pixel[14]] < c_b)
                                goto is_a_corner;
                            else
                                goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[5]] > cb)
                if( p[pixel[6]] > cb)
                    if( p[pixel[7]] > cb)
                        if( p[pixel[8]] > cb)
                            if( p[pixel[9]] > cb)
                                if( p[pixel[10]] > cb)
                                    if( p[pixel[11]] > cb)
                                        if( p[pixel[12]] > cb)
                                            if( p[pixel[13]] > cb)
                                                if( p[pixel[14]] > cb)
                                                    goto is_a_corner;
                                                else
                                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[4]] < c_b)
            if( p[pixel[5]] > cb)
                if( p[pixel[10]] > cb)
                    if( p[pixel[6]] > cb)
                        if( p[pixel[7]] > cb)
                            if( p[pixel[8]] > cb)
                                if( p[pixel[9]] > cb)
                                    if( p[pixel[11]] > cb)
                                        if( p[pixel[12]] > cb)
                                            if( p[pixel[13]] > cb)
                                                if( p[pixel[14]] > cb)
                                                    if( p[pixel[15]] > cb)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[10]] < c_b)
            if( p[pixel[11]] < c_b)
                if( p[pixel[12]] < c_b)
                    if( p[pixel[13]] < c_b)
                        if( p[pixel[14]] < c_b)
                            if( p[pixel[15]] < c_b)
                                goto is_a_corner;
                            else
                                goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[5]] < c_b)
            if( p[pixel[6]] < c_b)
                if( p[pixel[7]] < c_b)
                    if( p[pixel[8]] < c_b)
                        if( p[pixel[9]] < c_b)
                            if( p[pixel[10]] < c_b)
                                goto is_a_corner;
                            else
                                if( p[pixel[15]] < c_b)
                                    goto is_a_corner;
                                else
                                    goto is_not_a_corner;
        else
            if( p[pixel[14]] < c_b)
                if( p[pixel[15]] < c_b)
                    goto is_a_corner;
                else
                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[13]] < c_b)
                if( p[pixel[14]] < c_b)
                    if( p[pixel[15]] < c_b)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[12]] < c_b)
                if( p[pixel[13]] < c_b)
                    if( p[pixel[14]] < c_b)
                        if( p[pixel[15]] < c_b)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[11]] < c_b)
                if( p[pixel[12]] < c_b)
                    if( p[pixel[13]] < c_b)
                        if( p[pixel[14]] < c_b)
                            if( p[pixel[15]] < c_b)
                                goto is_a_corner;
                            else
                                goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[10]] < c_b)
                if( p[pixel[11]] < c_b)
                    if( p[pixel[12]] < c_b)
                        if( p[pixel[13]] < c_b)
                            if( p[pixel[14]] < c_b)
                                if( p[pixel[15]] < c_b)
                                    goto is_a_corner;
                                else
                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[9]] > cb)
                if( p[pixel[5]] > cb)
                    if( p[pixel[6]] > cb)
                        if( p[pixel[7]] > cb)
                            if( p[pixel[8]] > cb)
                                if( p[pixel[10]] > cb)
                                    if( p[pixel[11]] > cb)
                                        if( p[pixel[12]] > cb)
                                            if( p[pixel[13]] > cb)
                                                if( p[pixel[14]] > cb)
                                                    if( p[pixel[15]] > cb)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[9]] < c_b)
            if( p[pixel[10]] < c_b)
                if( p[pixel[11]] < c_b)
                    if( p[pixel[12]] < c_b)
                        if( p[pixel[13]] < c_b)
                            if( p[pixel[14]] < c_b)
                                if( p[pixel[15]] < c_b)
                                    goto is_a_corner;
                                else
                                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[8]] > cb)
                if( p[pixel[5]] > cb)
                    if( p[pixel[6]] > cb)
                        if( p[pixel[7]] > cb)
                            if( p[pixel[9]] > cb)
                                if( p[pixel[10]] > cb)
                                    if( p[pixel[11]] > cb)
                                        if( p[pixel[12]] > cb)
                                            if( p[pixel[13]] > cb)
                                                if( p[pixel[14]] > cb)
                                                    if( p[pixel[4]] > cb)
                                                        goto is_a_corner;
                                                    else
                                                        if( p[pixel[15]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[8]] < c_b)
            if( p[pixel[9]] < c_b)
                if( p[pixel[10]] < c_b)
                    if( p[pixel[11]] < c_b)
                        if( p[pixel[12]] < c_b)
                            if( p[pixel[13]] < c_b)
                                if( p[pixel[14]] < c_b)
                                    if( p[pixel[15]] < c_b)
                                        goto is_a_corner;
                                    else
                                        if( p[pixel[4]] < c_b)
                                            if( p[pixel[5]] < c_b)
                                                if( p[pixel[6]] < c_b)
                                                    if( p[pixel[7]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[7]] > cb)
                if( p[pixel[5]] > cb)
                    if( p[pixel[6]] > cb)
                        if( p[pixel[8]] > cb)
                            if( p[pixel[9]] > cb)
                                if( p[pixel[10]] > cb)
                                    if( p[pixel[11]] > cb)
                                        if( p[pixel[12]] > cb)
                                            if( p[pixel[13]] > cb)
                                                if( p[pixel[4]] > cb)
                                                    if( p[pixel[3]] > cb)
                                                        goto is_a_corner;
                                                    else
                                                        if( p[pixel[14]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            if( p[pixel[14]] > cb)
                if( p[pixel[15]] > cb)
                    goto is_a_corner;
                else
                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[7]] < c_b)
            if( p[pixel[8]] < c_b)
                if( p[pixel[9]] < c_b)
                    if( p[pixel[10]] < c_b)
                        if( p[pixel[11]] < c_b)
                            if( p[pixel[12]] < c_b)
                                if( p[pixel[13]] < c_b)
                                    if( p[pixel[14]] < c_b)
                                        if( p[pixel[15]] < c_b)
                                            goto is_a_corner;
                                        else
                                            if( p[pixel[4]] < c_b)
                                                if( p[pixel[5]] < c_b)
                                                    if( p[pixel[6]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[3]] < c_b)
                if( p[pixel[4]] < c_b)
                    if( p[pixel[5]] < c_b)
                        if( p[pixel[6]] < c_b)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[6]] > cb)
                if( p[pixel[5]] > cb)
                    if( p[pixel[7]] > cb)
                        if( p[pixel[8]] > cb)
                            if( p[pixel[9]] > cb)
                                if( p[pixel[10]] > cb)
                                    if( p[pixel[11]] > cb)
                                        if( p[pixel[12]] > cb)
                                            if( p[pixel[4]] > cb)
                                                if( p[pixel[3]] > cb)
                                                    if( p[pixel[2]] > cb)
                                                        goto is_a_corner;
                                                    else
                                                        if( p[pixel[13]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            if( p[pixel[13]] > cb)
                if( p[pixel[14]] > cb)
                    goto is_a_corner;
                else
                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[13]] > cb)
                if( p[pixel[14]] > cb)
                    if( p[pixel[15]] > cb)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[6]] < c_b)
            if( p[pixel[7]] < c_b)
                if( p[pixel[8]] < c_b)
                    if( p[pixel[9]] < c_b)
                        if( p[pixel[10]] < c_b)
                            if( p[pixel[11]] < c_b)
                                if( p[pixel[12]] < c_b)
                                    if( p[pixel[13]] < c_b)
                                        if( p[pixel[14]] < c_b)
                                            if( p[pixel[15]] < c_b)
                                                goto is_a_corner;
                                            else
                                                if( p[pixel[4]] < c_b)
                                                    if( p[pixel[5]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[3]] < c_b)
                if( p[pixel[4]] < c_b)
                    if( p[pixel[5]] < c_b)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[2]] < c_b)
                if( p[pixel[3]] < c_b)
                    if( p[pixel[4]] < c_b)
                        if( p[pixel[5]] < c_b)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[5]] > cb)
                if( p[pixel[6]] > cb)
                    if( p[pixel[7]] > cb)
                        if( p[pixel[8]] > cb)
                            if( p[pixel[9]] > cb)
                                if( p[pixel[10]] > cb)
                                    if( p[pixel[11]] > cb)
                                        if( p[pixel[4]] > cb)
                                            if( p[pixel[3]] > cb)
                                                if( p[pixel[2]] > cb)
                                                    if( p[pixel[1]] > cb)
                                                        goto is_a_corner;
                                                    else
                                                        if( p[pixel[12]] > cb)
                                                            goto is_a_corner;
                                                        else
                                                            goto is_not_a_corner;
        else
            if( p[pixel[12]] > cb)
                if( p[pixel[13]] > cb)
                    goto is_a_corner;
                else
                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[12]] > cb)
                if( p[pixel[13]] > cb)
                    if( p[pixel[14]] > cb)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[12]] > cb)
                if( p[pixel[13]] > cb)
                    if( p[pixel[14]] > cb)
                        if( p[pixel[15]] > cb)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else if( p[pixel[5]] < c_b)
            if( p[pixel[6]] < c_b)
                if( p[pixel[7]] < c_b)
                    if( p[pixel[8]] < c_b)
                        if( p[pixel[9]] < c_b)
                            if( p[pixel[10]] < c_b)
                                if( p[pixel[11]] < c_b)
                                    if( p[pixel[4]] < c_b)
                                        if( p[pixel[3]] < c_b)
                                            if( p[pixel[2]] < c_b)
                                                if( p[pixel[1]] < c_b)
                                                    goto is_a_corner;
                                                else
                                                    if( p[pixel[12]] < c_b)
                                                        goto is_a_corner;
                                                    else
                                                        goto is_not_a_corner;
        else
            if( p[pixel[12]] < c_b)
                if( p[pixel[13]] < c_b)
                    goto is_a_corner;
                else
                    goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[12]] < c_b)
                if( p[pixel[13]] < c_b)
                    if( p[pixel[14]] < c_b)
                        goto is_a_corner;
                    else
                        goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            if( p[pixel[12]] < c_b)
                if( p[pixel[13]] < c_b)
                    if( p[pixel[14]] < c_b)
                        if( p[pixel[15]] < c_b)
                            goto is_a_corner;
                        else
                            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;
        else
            goto is_not_a_corner;

    is_a_corner:
        bmin=b;
        goto end_if;

    is_not_a_corner:
        bmax=b;
        goto end_if;

    end_if:

        if(bmin == bmax - 1 || bmin == bmax)
            return bmin;
        b = (bmin + bmax) / 2;
    }
    return 0;
}

static void make_offsets(int *pixel, int row_stride)
{
    pixel[0] = 0 + row_stride * 3;
    pixel[1] = 1 + row_stride * 3;
    pixel[2] = 2 + row_stride * 2;
    pixel[3] = 3 + row_stride * 1;
    pixel[4] = 3 + row_stride * 0;
    pixel[5] = 3 + row_stride * -1;
    pixel[6] = 2 + row_stride * -2;
    pixel[7] = 1 + row_stride * -3;
    pixel[8] = 0 + row_stride * -3;
    pixel[9] = -1 + row_stride * -3;
    pixel[10] = -2 + row_stride * -2;
    pixel[11] = -3 + row_stride * -1;
    pixel[12] = -3 + row_stride * 0;
    pixel[13] = -3 + row_stride * 1;
    pixel[14] = -2 + row_stride * 2;
    pixel[15] = -1 + row_stride * 3;
}



int* fast11_score(const ubyte* i, int stride, xy* corners, int num_corners, int b)
{	
    int* scores = cast(int*)malloc(int.sizeof* num_corners);
    int n;

    int [16]pixel;
    make_offsets(pixel.ptr, stride);

    for(n=0; n < num_corners; n++)
        scores[n] = fast11_corner_score(i + corners[n].y*stride + corners[n].x, pixel.ptr, b);

    return scores;
}


xy* fast11_detect(const ubyte* im, int xsize, int ysize, int stride, int b, int* ret_num_corners)
{
    int num_corners=0;
    xy* ret_corners;
    int rsize=512;
    int [16]pixel;
    int x, y;

    ret_corners = cast(xy*)malloc(xy.sizeof*rsize);
    make_offsets(pixel.ptr, stride);

    for(y=3; y < ysize - 3; y++)
        for(x=3; x < xsize - 3; x++)
    {
        const ubyte* p = im + y*stride + x;
        
        int cb = *p + b;
        int c_b= *p - b;
        if(p[pixel[0]] > cb)
            if(p[pixel[1]] > cb)
                if(p[pixel[2]] > cb)
                    if(p[pixel[3]] > cb)
                        if(p[pixel[4]] > cb)
                            if(p[pixel[5]] > cb)
                                if(p[pixel[6]] > cb)
                                    if(p[pixel[7]] > cb)
                                        if(p[pixel[8]] > cb)
                                            if(p[pixel[9]] > cb)
                                                if(p[pixel[10]] > cb)
                                            {}
        else
            if(p[pixel[15]] > cb)
        {}
        else
            continue;
        else
            if(p[pixel[14]] > cb)
                if(p[pixel[15]] > cb)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[13]] > cb)
                if(p[pixel[14]] > cb)
                    if(p[pixel[15]] > cb)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[12]] > cb)
                if(p[pixel[13]] > cb)
                    if(p[pixel[14]] > cb)
                        if(p[pixel[15]] > cb)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[11]] > cb)
                if(p[pixel[12]] > cb)
                    if(p[pixel[13]] > cb)
                        if(p[pixel[14]] > cb)
                            if(p[pixel[15]] > cb)
                        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[5]] < c_b)
            if(p[pixel[10]] > cb)
                if(p[pixel[11]] > cb)
                    if(p[pixel[12]] > cb)
                        if(p[pixel[13]] > cb)
                            if(p[pixel[14]] > cb)
                                if(p[pixel[15]] > cb)
                            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[10]] < c_b)
            if(p[pixel[6]] < c_b)
                if(p[pixel[7]] < c_b)
                    if(p[pixel[8]] < c_b)
                        if(p[pixel[9]] < c_b)
                            if(p[pixel[11]] < c_b)
                                if(p[pixel[12]] < c_b)
                                    if(p[pixel[13]] < c_b)
                                        if(p[pixel[14]] < c_b)
                                            if(p[pixel[15]] < c_b)
                                        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[10]] > cb)
                if(p[pixel[11]] > cb)
                    if(p[pixel[12]] > cb)
                        if(p[pixel[13]] > cb)
                            if(p[pixel[14]] > cb)
                                if(p[pixel[15]] > cb)
                            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[4]] < c_b)
            if(p[pixel[15]] > cb)
                if(p[pixel[9]] > cb)
                    if(p[pixel[10]] > cb)
                        if(p[pixel[11]] > cb)
                            if(p[pixel[12]] > cb)
                                if(p[pixel[13]] > cb)
                                    if(p[pixel[14]] > cb)
                                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[9]] < c_b)
            if(p[pixel[5]] < c_b)
                if(p[pixel[6]] < c_b)
                    if(p[pixel[7]] < c_b)
                        if(p[pixel[8]] < c_b)
                            if(p[pixel[10]] < c_b)
                                if(p[pixel[11]] < c_b)
                                    if(p[pixel[12]] < c_b)
                                        if(p[pixel[13]] < c_b)
                                            if(p[pixel[14]] < c_b)
                                        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[5]] < c_b)
                if(p[pixel[6]] < c_b)
                    if(p[pixel[7]] < c_b)
                        if(p[pixel[8]] < c_b)
                            if(p[pixel[9]] < c_b)
                                if(p[pixel[10]] < c_b)
                                    if(p[pixel[11]] < c_b)
                                        if(p[pixel[12]] < c_b)
                                            if(p[pixel[13]] < c_b)
                                                if(p[pixel[14]] < c_b)
                                            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[9]] > cb)
                if(p[pixel[10]] > cb)
                    if(p[pixel[11]] > cb)
                        if(p[pixel[12]] > cb)
                            if(p[pixel[13]] > cb)
                                if(p[pixel[14]] > cb)
                                    if(p[pixel[15]] > cb)
                                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[9]] < c_b)
            if(p[pixel[5]] < c_b)
                if(p[pixel[6]] < c_b)
                    if(p[pixel[7]] < c_b)
                        if(p[pixel[8]] < c_b)
                            if(p[pixel[10]] < c_b)
                                if(p[pixel[11]] < c_b)
                                    if(p[pixel[12]] < c_b)
                                        if(p[pixel[13]] < c_b)
                                            if(p[pixel[14]] < c_b)
                                                if(p[pixel[15]] < c_b)
                                            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[3]] < c_b)
            if(p[pixel[14]] > cb)
                if(p[pixel[8]] > cb)
                    if(p[pixel[9]] > cb)
                        if(p[pixel[10]] > cb)
                            if(p[pixel[11]] > cb)
                                if(p[pixel[12]] > cb)
                                    if(p[pixel[13]] > cb)
                                        if(p[pixel[15]] > cb)
                                    {}
        else
            if(p[pixel[4]] > cb)
                if(p[pixel[5]] > cb)
                    if(p[pixel[6]] > cb)
                        if(p[pixel[7]] > cb)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[8]] < c_b)
            if(p[pixel[4]] < c_b)
                if(p[pixel[5]] < c_b)
                    if(p[pixel[6]] < c_b)
                        if(p[pixel[7]] < c_b)
                            if(p[pixel[9]] < c_b)
                                if(p[pixel[10]] < c_b)
                                    if(p[pixel[11]] < c_b)
                                        if(p[pixel[12]] < c_b)
                                            if(p[pixel[13]] < c_b)
                                        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[14]] < c_b)
            if(p[pixel[5]] < c_b)
                if(p[pixel[6]] < c_b)
                    if(p[pixel[7]] < c_b)
                        if(p[pixel[8]] < c_b)
                            if(p[pixel[9]] < c_b)
                                if(p[pixel[10]] < c_b)
                                    if(p[pixel[11]] < c_b)
                                        if(p[pixel[12]] < c_b)
                                            if(p[pixel[13]] < c_b)
                                                if(p[pixel[4]] < c_b)
                                            {}
        else
            if(p[pixel[15]] < c_b)
        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[4]] < c_b)
                if(p[pixel[5]] < c_b)
                    if(p[pixel[6]] < c_b)
                        if(p[pixel[7]] < c_b)
                            if(p[pixel[8]] < c_b)
                                if(p[pixel[9]] < c_b)
                                    if(p[pixel[10]] < c_b)
                                        if(p[pixel[11]] < c_b)
                                            if(p[pixel[12]] < c_b)
                                                if(p[pixel[13]] < c_b)
                                            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[8]] > cb)
                if(p[pixel[9]] > cb)
                    if(p[pixel[10]] > cb)
                        if(p[pixel[11]] > cb)
                            if(p[pixel[12]] > cb)
                                if(p[pixel[13]] > cb)
                                    if(p[pixel[14]] > cb)
                                        if(p[pixel[15]] > cb)
                                    {}
        else
            if(p[pixel[4]] > cb)
                if(p[pixel[5]] > cb)
                    if(p[pixel[6]] > cb)
                        if(p[pixel[7]] > cb)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[8]] < c_b)
            if(p[pixel[5]] < c_b)
                if(p[pixel[6]] < c_b)
                    if(p[pixel[7]] < c_b)
                        if(p[pixel[9]] < c_b)
                            if(p[pixel[10]] < c_b)
                                if(p[pixel[11]] < c_b)
                                    if(p[pixel[12]] < c_b)
                                        if(p[pixel[13]] < c_b)
                                            if(p[pixel[14]] < c_b)
                                                if(p[pixel[4]] < c_b)
                                            {}
        else
            if(p[pixel[15]] < c_b)
        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[2]] < c_b)
            if(p[pixel[7]] > cb)
                if(p[pixel[8]] > cb)
                    if(p[pixel[9]] > cb)
                        if(p[pixel[10]] > cb)
                            if(p[pixel[11]] > cb)
                                if(p[pixel[12]] > cb)
                                    if(p[pixel[13]] > cb)
                                        if(p[pixel[14]] > cb)
                                            if(p[pixel[15]] > cb)
                                        {}
        else
            if(p[pixel[4]] > cb)
                if(p[pixel[5]] > cb)
                    if(p[pixel[6]] > cb)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[3]] > cb)
                if(p[pixel[4]] > cb)
                    if(p[pixel[5]] > cb)
                        if(p[pixel[6]] > cb)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[7]] < c_b)
            if(p[pixel[5]] < c_b)
                if(p[pixel[6]] < c_b)
                    if(p[pixel[8]] < c_b)
                        if(p[pixel[9]] < c_b)
                            if(p[pixel[10]] < c_b)
                                if(p[pixel[11]] < c_b)
                                    if(p[pixel[12]] < c_b)
                                        if(p[pixel[4]] < c_b)
                                            if(p[pixel[3]] < c_b)
                                        {}
        else
            if(p[pixel[13]] < c_b)
                if(p[pixel[14]] < c_b)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[13]] < c_b)
                if(p[pixel[14]] < c_b)
                    if(p[pixel[15]] < c_b)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[7]] > cb)
                if(p[pixel[8]] > cb)
                    if(p[pixel[9]] > cb)
                        if(p[pixel[10]] > cb)
                            if(p[pixel[11]] > cb)
                                if(p[pixel[12]] > cb)
                                    if(p[pixel[13]] > cb)
                                        if(p[pixel[14]] > cb)
                                            if(p[pixel[15]] > cb)
                                        {}
        else
            if(p[pixel[4]] > cb)
                if(p[pixel[5]] > cb)
                    if(p[pixel[6]] > cb)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[3]] > cb)
                if(p[pixel[4]] > cb)
                    if(p[pixel[5]] > cb)
                        if(p[pixel[6]] > cb)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[7]] < c_b)
            if(p[pixel[5]] < c_b)
                if(p[pixel[6]] < c_b)
                    if(p[pixel[8]] < c_b)
                        if(p[pixel[9]] < c_b)
                            if(p[pixel[10]] < c_b)
                                if(p[pixel[11]] < c_b)
                                    if(p[pixel[12]] < c_b)
                                        if(p[pixel[13]] < c_b)
                                            if(p[pixel[4]] < c_b)
                                                if(p[pixel[3]] < c_b)
                                            {}
        else
            if(p[pixel[14]] < c_b)
        {}
        else
            continue;
        else
            if(p[pixel[14]] < c_b)
                if(p[pixel[15]] < c_b)
            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[1]] < c_b)
            if(p[pixel[6]] > cb)
                if(p[pixel[7]] > cb)
                    if(p[pixel[8]] > cb)
                        if(p[pixel[9]] > cb)
                            if(p[pixel[10]] > cb)
                                if(p[pixel[11]] > cb)
                                    if(p[pixel[12]] > cb)
                                        if(p[pixel[13]] > cb)
                                            if(p[pixel[14]] > cb)
                                                if(p[pixel[15]] > cb)
                                            {}
        else
            if(p[pixel[4]] > cb)
                if(p[pixel[5]] > cb)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[3]] > cb)
                if(p[pixel[4]] > cb)
                    if(p[pixel[5]] > cb)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[2]] > cb)
                if(p[pixel[3]] > cb)
                    if(p[pixel[4]] > cb)
                        if(p[pixel[5]] > cb)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[6]] < c_b)
            if(p[pixel[5]] < c_b)
                if(p[pixel[7]] < c_b)
                    if(p[pixel[8]] < c_b)
                        if(p[pixel[9]] < c_b)
                            if(p[pixel[10]] < c_b)
                                if(p[pixel[11]] < c_b)
                                    if(p[pixel[4]] < c_b)
                                        if(p[pixel[3]] < c_b)
                                            if(p[pixel[2]] < c_b)
                                        {}
        else
            if(p[pixel[12]] < c_b)
                if(p[pixel[13]] < c_b)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[12]] < c_b)
                if(p[pixel[13]] < c_b)
                    if(p[pixel[14]] < c_b)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[12]] < c_b)
                if(p[pixel[13]] < c_b)
                    if(p[pixel[14]] < c_b)
                        if(p[pixel[15]] < c_b)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[6]] > cb)
                if(p[pixel[7]] > cb)
                    if(p[pixel[8]] > cb)
                        if(p[pixel[9]] > cb)
                            if(p[pixel[10]] > cb)
                                if(p[pixel[11]] > cb)
                                    if(p[pixel[12]] > cb)
                                        if(p[pixel[13]] > cb)
                                            if(p[pixel[14]] > cb)
                                                if(p[pixel[15]] > cb)
                                            {}
        else
            if(p[pixel[4]] > cb)
                if(p[pixel[5]] > cb)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[3]] > cb)
                if(p[pixel[4]] > cb)
                    if(p[pixel[5]] > cb)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[2]] > cb)
                if(p[pixel[3]] > cb)
                    if(p[pixel[4]] > cb)
                        if(p[pixel[5]] > cb)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[6]] < c_b)
            if(p[pixel[5]] < c_b)
                if(p[pixel[7]] < c_b)
                    if(p[pixel[8]] < c_b)
                        if(p[pixel[9]] < c_b)
                            if(p[pixel[10]] < c_b)
                                if(p[pixel[11]] < c_b)
                                    if(p[pixel[12]] < c_b)
                                        if(p[pixel[4]] < c_b)
                                            if(p[pixel[3]] < c_b)
                                                if(p[pixel[2]] < c_b)
                                            {}
        else
            if(p[pixel[13]] < c_b)
        {}
        else
            continue;
        else
            if(p[pixel[13]] < c_b)
                if(p[pixel[14]] < c_b)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[13]] < c_b)
                if(p[pixel[14]] < c_b)
                    if(p[pixel[15]] < c_b)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[0]] < c_b)
            if(p[pixel[1]] > cb)
                if(p[pixel[6]] > cb)
                    if(p[pixel[5]] > cb)
                        if(p[pixel[7]] > cb)
                            if(p[pixel[8]] > cb)
                                if(p[pixel[9]] > cb)
                                    if(p[pixel[10]] > cb)
                                        if(p[pixel[11]] > cb)
                                            if(p[pixel[4]] > cb)
                                                if(p[pixel[3]] > cb)
                                                    if(p[pixel[2]] > cb)
                                                {}
        else
            if(p[pixel[12]] > cb)
                if(p[pixel[13]] > cb)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[12]] > cb)
                if(p[pixel[13]] > cb)
                    if(p[pixel[14]] > cb)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[12]] > cb)
                if(p[pixel[13]] > cb)
                    if(p[pixel[14]] > cb)
                        if(p[pixel[15]] > cb)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[6]] < c_b)
            if(p[pixel[7]] < c_b)
                if(p[pixel[8]] < c_b)
                    if(p[pixel[9]] < c_b)
                        if(p[pixel[10]] < c_b)
                            if(p[pixel[11]] < c_b)
                                if(p[pixel[12]] < c_b)
                                    if(p[pixel[13]] < c_b)
                                        if(p[pixel[14]] < c_b)
                                            if(p[pixel[15]] < c_b)
                                        {}
        else
            if(p[pixel[4]] < c_b)
                if(p[pixel[5]] < c_b)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[3]] < c_b)
                if(p[pixel[4]] < c_b)
                    if(p[pixel[5]] < c_b)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[2]] < c_b)
                if(p[pixel[3]] < c_b)
                    if(p[pixel[4]] < c_b)
                        if(p[pixel[5]] < c_b)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[1]] < c_b)
            if(p[pixel[2]] > cb)
                if(p[pixel[7]] > cb)
                    if(p[pixel[5]] > cb)
                        if(p[pixel[6]] > cb)
                            if(p[pixel[8]] > cb)
                                if(p[pixel[9]] > cb)
                                    if(p[pixel[10]] > cb)
                                        if(p[pixel[11]] > cb)
                                            if(p[pixel[12]] > cb)
                                                if(p[pixel[4]] > cb)
                                                    if(p[pixel[3]] > cb)
                                                {}
        else
            if(p[pixel[13]] > cb)
                if(p[pixel[14]] > cb)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[13]] > cb)
                if(p[pixel[14]] > cb)
                    if(p[pixel[15]] > cb)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[7]] < c_b)
            if(p[pixel[8]] < c_b)
                if(p[pixel[9]] < c_b)
                    if(p[pixel[10]] < c_b)
                        if(p[pixel[11]] < c_b)
                            if(p[pixel[12]] < c_b)
                                if(p[pixel[13]] < c_b)
                                    if(p[pixel[14]] < c_b)
                                        if(p[pixel[15]] < c_b)
                                    {}
        else
            if(p[pixel[4]] < c_b)
                if(p[pixel[5]] < c_b)
                    if(p[pixel[6]] < c_b)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[3]] < c_b)
                if(p[pixel[4]] < c_b)
                    if(p[pixel[5]] < c_b)
                        if(p[pixel[6]] < c_b)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[2]] < c_b)
            if(p[pixel[3]] > cb)
                if(p[pixel[14]] > cb)
                    if(p[pixel[5]] > cb)
                        if(p[pixel[6]] > cb)
                            if(p[pixel[7]] > cb)
                                if(p[pixel[8]] > cb)
                                    if(p[pixel[9]] > cb)
                                        if(p[pixel[10]] > cb)
                                            if(p[pixel[11]] > cb)
                                                if(p[pixel[12]] > cb)
                                                    if(p[pixel[13]] > cb)
                                                        if(p[pixel[4]] > cb)
                                                    {}
        else
            if(p[pixel[15]] > cb)
        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[14]] < c_b)
            if(p[pixel[8]] > cb)
                if(p[pixel[4]] > cb)
                    if(p[pixel[5]] > cb)
                        if(p[pixel[6]] > cb)
                            if(p[pixel[7]] > cb)
                                if(p[pixel[9]] > cb)
                                    if(p[pixel[10]] > cb)
                                        if(p[pixel[11]] > cb)
                                            if(p[pixel[12]] > cb)
                                                if(p[pixel[13]] > cb)
                                            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[8]] < c_b)
            if(p[pixel[9]] < c_b)
                if(p[pixel[10]] < c_b)
                    if(p[pixel[11]] < c_b)
                        if(p[pixel[12]] < c_b)
                            if(p[pixel[13]] < c_b)
                                if(p[pixel[15]] < c_b)
                            {}
        else
            if(p[pixel[4]] < c_b)
                if(p[pixel[5]] < c_b)
                    if(p[pixel[6]] < c_b)
                        if(p[pixel[7]] < c_b)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[4]] > cb)
                if(p[pixel[5]] > cb)
                    if(p[pixel[6]] > cb)
                        if(p[pixel[7]] > cb)
                            if(p[pixel[8]] > cb)
                                if(p[pixel[9]] > cb)
                                    if(p[pixel[10]] > cb)
                                        if(p[pixel[11]] > cb)
                                            if(p[pixel[12]] > cb)
                                                if(p[pixel[13]] > cb)
                                            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[3]] < c_b)
            if(p[pixel[4]] > cb)
                if(p[pixel[15]] < c_b)
                    if(p[pixel[9]] > cb)
                        if(p[pixel[5]] > cb)
                            if(p[pixel[6]] > cb)
                                if(p[pixel[7]] > cb)
                                    if(p[pixel[8]] > cb)
                                        if(p[pixel[10]] > cb)
                                            if(p[pixel[11]] > cb)
                                                if(p[pixel[12]] > cb)
                                                    if(p[pixel[13]] > cb)
                                                        if(p[pixel[14]] > cb)
                                                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[9]] < c_b)
            if(p[pixel[10]] < c_b)
                if(p[pixel[11]] < c_b)
                    if(p[pixel[12]] < c_b)
                        if(p[pixel[13]] < c_b)
                            if(p[pixel[14]] < c_b)
                        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[5]] > cb)
                if(p[pixel[6]] > cb)
                    if(p[pixel[7]] > cb)
                        if(p[pixel[8]] > cb)
                            if(p[pixel[9]] > cb)
                                if(p[pixel[10]] > cb)
                                    if(p[pixel[11]] > cb)
                                        if(p[pixel[12]] > cb)
                                            if(p[pixel[13]] > cb)
                                                if(p[pixel[14]] > cb)
                                            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[4]] < c_b)
            if(p[pixel[5]] > cb)
                if(p[pixel[10]] > cb)
                    if(p[pixel[6]] > cb)
                        if(p[pixel[7]] > cb)
                            if(p[pixel[8]] > cb)
                                if(p[pixel[9]] > cb)
                                    if(p[pixel[11]] > cb)
                                        if(p[pixel[12]] > cb)
                                            if(p[pixel[13]] > cb)
                                                if(p[pixel[14]] > cb)
                                                    if(p[pixel[15]] > cb)
                                                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[10]] < c_b)
            if(p[pixel[11]] < c_b)
                if(p[pixel[12]] < c_b)
                    if(p[pixel[13]] < c_b)
                        if(p[pixel[14]] < c_b)
                            if(p[pixel[15]] < c_b)
                        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[5]] < c_b)
            if(p[pixel[6]] < c_b)
                if(p[pixel[7]] < c_b)
                    if(p[pixel[8]] < c_b)
                        if(p[pixel[9]] < c_b)
                            if(p[pixel[10]] < c_b)
                        {}
        else
            if(p[pixel[15]] < c_b)
        {}
        else
            continue;
        else
            if(p[pixel[14]] < c_b)
                if(p[pixel[15]] < c_b)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[13]] < c_b)
                if(p[pixel[14]] < c_b)
                    if(p[pixel[15]] < c_b)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[12]] < c_b)
                if(p[pixel[13]] < c_b)
                    if(p[pixel[14]] < c_b)
                        if(p[pixel[15]] < c_b)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[11]] < c_b)
                if(p[pixel[12]] < c_b)
                    if(p[pixel[13]] < c_b)
                        if(p[pixel[14]] < c_b)
                            if(p[pixel[15]] < c_b)
                        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[10]] < c_b)
                if(p[pixel[11]] < c_b)
                    if(p[pixel[12]] < c_b)
                        if(p[pixel[13]] < c_b)
                            if(p[pixel[14]] < c_b)
                                if(p[pixel[15]] < c_b)
                            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[9]] > cb)
                if(p[pixel[5]] > cb)
                    if(p[pixel[6]] > cb)
                        if(p[pixel[7]] > cb)
                            if(p[pixel[8]] > cb)
                                if(p[pixel[10]] > cb)
                                    if(p[pixel[11]] > cb)
                                        if(p[pixel[12]] > cb)
                                            if(p[pixel[13]] > cb)
                                                if(p[pixel[14]] > cb)
                                                    if(p[pixel[15]] > cb)
                                                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[9]] < c_b)
            if(p[pixel[10]] < c_b)
                if(p[pixel[11]] < c_b)
                    if(p[pixel[12]] < c_b)
                        if(p[pixel[13]] < c_b)
                            if(p[pixel[14]] < c_b)
                                if(p[pixel[15]] < c_b)
                            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[8]] > cb)
                if(p[pixel[5]] > cb)
                    if(p[pixel[6]] > cb)
                        if(p[pixel[7]] > cb)
                            if(p[pixel[9]] > cb)
                                if(p[pixel[10]] > cb)
                                    if(p[pixel[11]] > cb)
                                        if(p[pixel[12]] > cb)
                                            if(p[pixel[13]] > cb)
                                                if(p[pixel[14]] > cb)
                                                    if(p[pixel[4]] > cb)
                                                {}
        else
            if(p[pixel[15]] > cb)
        {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[8]] < c_b)
            if(p[pixel[9]] < c_b)
                if(p[pixel[10]] < c_b)
                    if(p[pixel[11]] < c_b)
                        if(p[pixel[12]] < c_b)
                            if(p[pixel[13]] < c_b)
                                if(p[pixel[14]] < c_b)
                                    if(p[pixel[15]] < c_b)
                                {}
        else
            if(p[pixel[4]] < c_b)
                if(p[pixel[5]] < c_b)
                    if(p[pixel[6]] < c_b)
                        if(p[pixel[7]] < c_b)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[7]] > cb)
                if(p[pixel[5]] > cb)
                    if(p[pixel[6]] > cb)
                        if(p[pixel[8]] > cb)
                            if(p[pixel[9]] > cb)
                                if(p[pixel[10]] > cb)
                                    if(p[pixel[11]] > cb)
                                        if(p[pixel[12]] > cb)
                                            if(p[pixel[13]] > cb)
                                                if(p[pixel[4]] > cb)
                                                    if(p[pixel[3]] > cb)
                                                {}
        else
            if(p[pixel[14]] > cb)
        {}
        else
            continue;
        else
            if(p[pixel[14]] > cb)
                if(p[pixel[15]] > cb)
            {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[7]] < c_b)
            if(p[pixel[8]] < c_b)
                if(p[pixel[9]] < c_b)
                    if(p[pixel[10]] < c_b)
                        if(p[pixel[11]] < c_b)
                            if(p[pixel[12]] < c_b)
                                if(p[pixel[13]] < c_b)
                                    if(p[pixel[14]] < c_b)
                                        if(p[pixel[15]] < c_b)
                                    {}
        else
            if(p[pixel[4]] < c_b)
                if(p[pixel[5]] < c_b)
                    if(p[pixel[6]] < c_b)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[3]] < c_b)
                if(p[pixel[4]] < c_b)
                    if(p[pixel[5]] < c_b)
                        if(p[pixel[6]] < c_b)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[6]] > cb)
                if(p[pixel[5]] > cb)
                    if(p[pixel[7]] > cb)
                        if(p[pixel[8]] > cb)
                            if(p[pixel[9]] > cb)
                                if(p[pixel[10]] > cb)
                                    if(p[pixel[11]] > cb)
                                        if(p[pixel[12]] > cb)
                                            if(p[pixel[4]] > cb)
                                                if(p[pixel[3]] > cb)
                                                    if(p[pixel[2]] > cb)
                                                {}
        else
            if(p[pixel[13]] > cb)
        {}
        else
            continue;
        else
            if(p[pixel[13]] > cb)
                if(p[pixel[14]] > cb)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[13]] > cb)
                if(p[pixel[14]] > cb)
                    if(p[pixel[15]] > cb)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[6]] < c_b)
            if(p[pixel[7]] < c_b)
                if(p[pixel[8]] < c_b)
                    if(p[pixel[9]] < c_b)
                        if(p[pixel[10]] < c_b)
                            if(p[pixel[11]] < c_b)
                                if(p[pixel[12]] < c_b)
                                    if(p[pixel[13]] < c_b)
                                        if(p[pixel[14]] < c_b)
                                            if(p[pixel[15]] < c_b)
                                        {}
        else
            if(p[pixel[4]] < c_b)
                if(p[pixel[5]] < c_b)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[3]] < c_b)
                if(p[pixel[4]] < c_b)
                    if(p[pixel[5]] < c_b)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[2]] < c_b)
                if(p[pixel[3]] < c_b)
                    if(p[pixel[4]] < c_b)
                        if(p[pixel[5]] < c_b)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[5]] > cb)
                if(p[pixel[6]] > cb)
                    if(p[pixel[7]] > cb)
                        if(p[pixel[8]] > cb)
                            if(p[pixel[9]] > cb)
                                if(p[pixel[10]] > cb)
                                    if(p[pixel[11]] > cb)
                                        if(p[pixel[4]] > cb)
                                            if(p[pixel[3]] > cb)
                                                if(p[pixel[2]] > cb)
                                                    if(p[pixel[1]] > cb)
                                                {}
        else
            if(p[pixel[12]] > cb)
        {}
        else
            continue;
        else
            if(p[pixel[12]] > cb)
                if(p[pixel[13]] > cb)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[12]] > cb)
                if(p[pixel[13]] > cb)
                    if(p[pixel[14]] > cb)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[12]] > cb)
                if(p[pixel[13]] > cb)
                    if(p[pixel[14]] > cb)
                        if(p[pixel[15]] > cb)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else if(p[pixel[5]] < c_b)
            if(p[pixel[6]] < c_b)
                if(p[pixel[7]] < c_b)
                    if(p[pixel[8]] < c_b)
                        if(p[pixel[9]] < c_b)
                            if(p[pixel[10]] < c_b)
                                if(p[pixel[11]] < c_b)
                                    if(p[pixel[4]] < c_b)
                                        if(p[pixel[3]] < c_b)
                                            if(p[pixel[2]] < c_b)
                                                if(p[pixel[1]] < c_b)
                                            {}
        else
            if(p[pixel[12]] < c_b)
        {}
        else
            continue;
        else
            if(p[pixel[12]] < c_b)
                if(p[pixel[13]] < c_b)
            {}
        else
            continue;
        else
            continue;
        else
            if(p[pixel[12]] < c_b)
                if(p[pixel[13]] < c_b)
                    if(p[pixel[14]] < c_b)
                {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            if(p[pixel[12]] < c_b)
                if(p[pixel[13]] < c_b)
                    if(p[pixel[14]] < c_b)
                        if(p[pixel[15]] < c_b)
                    {}
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        else
            continue;
        if(num_corners == rsize)
        {
            rsize*=2;
            ret_corners = cast(xy*)realloc(ret_corners, xy.sizeof*rsize);
        }

        ret_corners[num_corners].x = x;
        ret_corners[num_corners].y = y;
        num_corners++;
    }
    
    *ret_num_corners = num_corners;
    return ret_corners;

}



