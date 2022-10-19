/*
Copyright (c) 2021- Ferhat Kurtulmuş
Boost Software License - Version 1.0 - August 17th, 2003
*/
module dcv.morphology.skeletonize;

import mir.ndslice;
import mir.rc;

@nogc nothrow:

// A rewrite of https://github.com/scikit-image/scikit-image/blob/main/skimage/morphology/_skeletonize_cy.pyx

/** Apply fast skeletonize algorithm to given binary image.

Params:
    binary = Input binary image of ubyte. Agnostic to SliceKind
Returns a refcounted Slice representing one pixel length skeletons of the binary regions. The resulting slice is Canonical.
*/
Slice!(RCI!ubyte, 2LU, Canonical) skeletonize2D(InputType)(auto ref InputType binary, int whiteValue = 255){

    // we copy over the image into a larger version with a single pixel border
    // this removes the need to handle border cases below

    immutable size_t nrows = binary.shape[0] + 2;
    immutable size_t ncols = binary.shape[1] + 2;

    auto skeleton = uninitRCslice!ubyte(nrows, ncols);
    skeleton[] = 0;
    
    skeleton[1..$-1, 1..$-1] = binary[]; // copy original data in the bordered frame
    
    auto cleaned_skeleton = rcslice!ubyte(skeleton.shape[0], skeleton.shape[1]);
    cleaned_skeleton[] = skeleton[]; // dup

    bool pixel_removed = true;

    while(pixel_removed){
        pixel_removed = false;

        // there are two phases, in the first phase, pixels labeled
        // (see below) 1 and 3 are removed, in the second 2 and 3

        // nogil can't iterate through `(True, False)` because it is a Python
        // tuple. Use the fact that 0 is Falsy, and 1 is truthy in C
        // for the iteration instead.
        // for first_pass in (True, False):
        bool first_pass;
        foreach(pass_num; 0..2){
            first_pass = (pass_num == 0);
            foreach(row; 1..nrows-1){
                foreach(col; 1..ncols-1){
                    // all set pixels ...

                    if(skeleton[row, col]){
                        // are correlated with a kernel
                        // (coefficients spread around here ...)
                        // to apply a unique number to every
                        // possible neighborhood ...

                        // which is used with the lut to find the
                        // "connectivity type"

                        immutable neighbors = lut[skeleton[row - 1, col - 1] / whiteValue +
                                                2 * skeleton[row - 1, col] / whiteValue +
                                                4 * skeleton[row - 1, col + 1] / whiteValue +
                                                8 * skeleton[row, col + 1] / whiteValue +
                                                16 * skeleton[row + 1, col + 1] / whiteValue +
                                                32 * skeleton[row + 1, col] / whiteValue +
                                                64 * skeleton[row + 1, col - 1] / whiteValue +
                                                128 * skeleton[row, col - 1] / whiteValue];

                        if (neighbors == 0)
                            continue;
                        else if ((neighbors == 3) ||
                                (neighbors == 1 && first_pass) ||
                                (neighbors == 2 && !first_pass)){
                            // Remove the pixel
                            cleaned_skeleton[row, col] = 0;
                            pixel_removed = true;
                        }
                    }
                }
            }
            // once a step has been processed, the original skeleton
            // is overwritten with the cleaned version
            skeleton[] = cleaned_skeleton[];
        }
    }

    // because of the dropborders the resulting slice is Canonical
    // with an extra copying process it can be converted to a Contiguous Slice if this is needed.
    return skeleton.dropBorders; 
}

private immutable ubyte[256] lut = [0, 0, 0, 1, 0, 0, 1, 3, 0, 0, 3, 1, 1, 0,
                                    1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 2, 0,
                                    3, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                    2, 0, 0, 0, 3, 0, 2, 2, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0,
                                    0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0,
                                    3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 3, 0,
                                    2, 0, 0, 0, 3, 1, 0, 0, 1, 3, 0, 0, 0, 0,
                                    0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 1, 3, 1, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 1, 3,
                                    0, 0, 1, 3, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                    2, 3, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
                                    0, 0, 3, 3, 0, 1, 0, 0, 0, 0, 2, 2, 0, 0,
                                    2, 0, 0, 0];