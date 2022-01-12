/**
Module for labelling connected regions of a binary image slice.
Copyright: Copyright Ferhat Kurtulmuş 2021.
Authors: Ferhat Kurtulmuş
License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.measure.label;

import std.typecons: tuple, Tuple;

import mir.ndslice;
import mir.ndslice.allocation;

/**
Label connected components in 2-D binary image

Params:
    input = Input slice of 2-D binary image (Slice!(Iterator, 2LU, kind)) .
*/

@nogc nothrow:

auto bwlabel(alias Conn = 8, SliceKind kind, Iterator)(auto ref Slice!(Iterator, 2LU, kind) input)
in
{
    assert(Conn == 4 || Conn == 8, "Connection rule must be either of 4 or 8");
}
do
{
    Labelizer2D lblzr;
    return lblzr.labelize!(Conn)(input);
}

/** Return an RGB image where color-coded labels are painted over the image.

Params:
    label = Label matrix.
*/
auto label2rgb(InputType)(InputType label)
{
    import mir.random;
    import mir.random.variable;
    import mir.ndslice.allocation;
    import mir.ndslice.topology;
    import mir.rc;
    
    Slice!(RCI!ubyte, 3LU, Contiguous) img = uninitRCslice!ubyte(label.shape[0], label.shape[1], 3);
    img[] = 0;

    auto index = label.maxIndex;

    long nregions = label[index[0], index[1]];

    auto gen = Random(unpredictableSeed);
    auto rv = uniformVar(0, 255);

    foreach (nr; 1..nregions+1)
    {
        ubyte[3] color;
        color[0] = cast(ubyte)rv(gen);
        color[1] = cast(ubyte)rv(gen);
        color[2] = cast(ubyte)rv(gen);
        size_t li;
        label.each!((a){
            if(a == nr)
                img.ptr[3*li .. 3*li+3] = color[];
            li++;
        });
    }

    return img;
}

/+ a rewrite of https://github.com/scikit-image/scikit-image/blob/main/skimage/measure/_ccomp.pyx

   Fiorio, C., & Gustedt, J. (1996). Two linear time union-find strategies for image processing. Theoretical Computer Science, 154(2), 165-181.
+/
struct Labelizer2D{
    auto labelize(alias Conn, Iterator, SliceKind kind)(ref Slice!(Iterator, 2LU, kind) input){
        static if(Conn == 4){
           enum _conn = 1;
        }else
        static if(Conn == 8){
            enum _conn = 2;
        }
        return label_cython!(_conn)(input);
    }
}
private :

alias DTYPE = long;

enum BG_NODE_NULL = -999;
alias DTYPE_t  = DTYPE;

alias Tfun_ravel = size_t function(size_t, size_t, size_t, shape_info*) @nogc nothrow pure;

enum {
    // the 0D neighbor
    // D_ee, # We don't need D_ee
    // the 1D neighbor
    D_ed,
    // 2D neighbors
    D_ea, D_eb, D_ec,
    // 3D neighbors
    D_ef, D_eg, D_eh, D_ei, D_ej, D_ek, D_el, D_em, D_en,
    D_COUNT
}

struct s_shpinfo{
    DTYPE_t x;
    DTYPE_t y;
    DTYPE_t z;

    // Number of elements
    DTYPE_t numels;
    // Dimensions of of the input array
    DTYPE_t ndim;

    // Offsets between elements recalculated to linear index increments
    // DEX[D_ea] is offset between E and A (i.e. to the point to upper left)
    // The name DEX is supposed to evoke DE., where . = A, B, C, D, F etc.
    DTYPE_t[D_COUNT] DEX;

    // Function pointer to a function that recalculates multi-index to linear
    // index. Heavily depends on dimensions of the input array.
    Tfun_ravel ravel_index;
}

alias shape_info = s_shpinfo;

struct bginfo{
    // The value in the image (i.e. not the label!) that identifies
    // the background.
    DTYPE_t background_val;
    DTYPE_t background_node;
    // Identification of the background in the labelled image
    DTYPE_t background_label;
}

void get_bginfo(DTYPE_t background_val, bginfo* ret){

    ret.background_val = background_val;

    // The node -999 doesn't exist, it will get subsituted by a meaningful value
    // upon the first background pixel occurrence
    ret.background_node = BG_NODE_NULL;
    ret.background_label = 0;
}

void get_shape_info(size_t[] inarr_shape, shape_info* res){
    import std.algorithm.sorting;
    import mir.rc;
    debug import std.exception, std.format;
    /+
    Precalculates all the needed data from the input array shape
    and stores them in the shape_info struct.
    +/
    res.y = 1;
    res.z = 1;
    res.ravel_index = &ravel_index2D;
    // A shape (3, 1, 4) would make the algorithm crash, but the corresponding
    // good_shape (i.e. the array with axis swapped) (1, 3, 4) is OK.
    // Having an axis length of 1 when an axis on the left is longer than 1
    // (in this case, it has length of 3) is NOT ALLOWED.
    auto good_shape = inarr_shape.sort().rcarray;

    res.ndim = inarr_shape.length;
    if( res.ndim == 1){
        res.x = inarr_shape[0];
        res.ravel_index = &ravel_index1D;
    }else if (res.ndim == 2){
        res.x = inarr_shape[1];
        res.y = inarr_shape[0];
        res.ravel_index = &ravel_index2D;
        if (res.x == 1 && res.y > 1){
            // Should not occur, but better be safe than sorry
            debug throw new Exception(
                format("Swap axis of your %s array so it has a %s shape",
                inarr_shape.stringof, good_shape.stringof));
        }
    }
    else if (res.ndim == 3){
        res.x = inarr_shape[2];
        res.y = inarr_shape[1];
        res.z = inarr_shape[0];
        res.ravel_index = &ravel_index3D;
        if ((res.x == 1 && res.y > 1)
            || res.y == 1 && res.z > 1){
            // Should not occur, but better be safe than sorry
            debug throw new Exception(
                format("Swap axes of your %s array so it has a %s shape",
                inarr_shape.stringof, good_shape.stringof));
        }
    }
    else{
        debug throw new Exception(
            format("Only for images of dimension 1-3 are supported, got a %sD one",
                 res.ndim));
    }
    res.numels = res.x * res.y * res.z;

    // When reading this for the first time, look at the diagram by the enum
    // definition above (keyword D_ee)
    // Difference between E and G is (x=0, y=-1, z=-1), E and A (-1, -1, 0) etc.
    // Here, it is recalculated to linear (raveled) indices of flattened arrays
    // with their last (=contiguous) dimension is x.

    // So now the 1st (needed for 1D, 2D and 3D) part, y = 1, z = 1
    res.DEX[D_ed] = -1;

    // Not needed, just for illustration
    // res.DEX[D_ee] = 0

    // So now the 2nd (needed for 2D and 3D) part, y = 0, z = 1
    res.DEX[D_ea] = res.ravel_index(-1, -1, 0, res);
    res.DEX[D_eb] = res.DEX[D_ea] + 1;
    res.DEX[D_ec] = res.DEX[D_eb] + 1;

    // And now the 3rd (needed only for 3D) part, z = 0
    res.DEX[D_ef] = res.ravel_index(-1, -1, -1, res);
    res.DEX[D_eg] = res.DEX[D_ef] + 1;
    res.DEX[D_eh] = res.DEX[D_ef] + 2;
    res.DEX[D_ei] = res.DEX[D_ef] - res.DEX[D_eb];  // DEX[D_eb] = one row up, remember?
    res.DEX[D_ej] = res.DEX[D_ei] + 1;
    res.DEX[D_ek] = res.DEX[D_ei] + 2;
    res.DEX[D_el] = res.DEX[D_ei] - res.DEX[D_eb];
    res.DEX[D_em] = res.DEX[D_el] + 1;
    res.DEX[D_en] = res.DEX[D_el] + 2;

}

pragma (inline, true)
void join_trees_wrapper(DTYPE_t* data_p, DTYPE_t* forest_p,
                                    DTYPE_t rindex, DTYPE_t idxdiff) @nogc nothrow{ 
    if (data_p[rindex] == data_p[rindex + idxdiff])
        join_trees(forest_p, rindex, rindex + idxdiff);
}

size_t ravel_index1D(size_t x, size_t y, size_t z,
                          shape_info* shapeinfo) @nogc nothrow pure {
    /+
    Ravel index of a 1D array - trivial. y and z are ignored.
    +/
    return x;
}
size_t ravel_index2D(size_t x, size_t y, size_t z,
                          shape_info* shapeinfo) @nogc nothrow pure {
    /+
    Ravel index of a 2D array. z is ignored
    +/
    return x + y * shapeinfo.x;
}

size_t ravel_index3D(size_t x, size_t y, size_t z,
                          shape_info* shapeinfo) @nogc nothrow pure {
    /+
    Ravel index of a 3D array
    +/
    return x + y * shapeinfo.x + z * shapeinfo.y * shapeinfo.x;
}

DTYPE_t find_root(DTYPE_t* forest, DTYPE_t n) @nogc nothrow {
    /+Find the root of node n.
    Given the example above, for any integer from 1 to 9, 1 is always returned
    +/
    DTYPE_t root = n;
    while (forest[root] < root)
        root = forest[root];
    return root;
}

pragma (inline, true)
void set_root(DTYPE_t *forest, DTYPE_t n, DTYPE_t root) @nogc nothrow {
    /+
    Set all nodes on a path to point to new_root.
    Given the example above, given n=9, root=6, it would "reconnect" the tree.
    so forest[9] = 6 and forest[8] = 6
    The ultimate goal is that all tree nodes point to the real root,
    which is element 1 in this case.
    +/
    DTYPE_t j;
    while (forest[n] < n){
        j = forest[n];
        forest[n] = root;
        n = j;
    }

    forest[n] = root;
}

pragma (inline, true)
void join_trees(DTYPE_t *forest, DTYPE_t n, DTYPE_t m) @nogc nothrow {
    /+Join two trees containing nodes n and m.
    If we imagine that in the example tree, the root 1 is not known, we
    rather have two disjoint trees with roots 2 and 6.
    Joining them would mean that all elements of both trees become connected
    to the element 2, so forest[9] == 2, forest[6] == 2 etc.
    However, when the relationship between 1 and 2 can still be discovered later.
    +/
    DTYPE_t root;
    DTYPE_t root_m;

    if (n != m){
        root = find_root(forest, n);
        root_m = find_root(forest, m);

        if (root > root_m)
            root = root_m;

        set_root(forest, n, root);
        set_root(forest, m, root);
    }
}

auto label_cython(alias _conn, alias background = 0, alias return_num = false, Iterator, size_t N, SliceKind kind)
    (Slice!(Iterator, N, kind) input_, ) {
    // A rewrite of https://github.com/scikit-image/scikit-image/blob/main/skimage/measure/_ccomp.pyx

    // Connected components search as described in Fiorio et al.
    // We have to ensure that the shape of the input can be handled by the
    // algorithm.
    

    import mir.ndslice.allocation;
    import mir.ndslice.topology;
    import mir.rc: RCI;

    auto shape = input_.shape;

    Slice!(RCI!DTYPE_t, 1LU, SliceKind.contiguous) forest;

    // Having data a 2D array slows down access considerably using linear
    // indices even when using the data_p pointer :-(

    // makes a copy so it is safe to modify data in-place
    auto data = input_.as!DTYPE_t.rcslice;
    forest = iota(input_.elementCount()).as!DTYPE.rcslice;
    

    DTYPE_t* forest_p = forest.ptr;

    DTYPE_t* data_p = data.ptr;

    shape_info shapeinfo;
    bginfo bg;

    get_shape_info(shape, &shapeinfo);
    get_bginfo(background, &bg);

    // todo: implement dim check here

    DTYPE_t conn = _conn;
    // Label output
    DTYPE_t ctr;
    
    scanBG(data_p, forest_p, &shapeinfo, &bg);
    // the data are treated as degenerated 3D arrays if needed
    // without any performance sacrifice
    scan3D(data_p, forest_p, &shapeinfo, &bg, conn);
    ctr = resolve_labels(data_p, forest_p, &shapeinfo, &bg);

    import std.typecons : tuple;
    static if (return_num){
        return tuple(data, ctr);
    }else{
        return data;
    }
}

DTYPE_t resolve_labels(DTYPE_t* data_p, DTYPE_t* forest_p,
                            shape_info* shapeinfo, bginfo* bg) @nogc nothrow {
    /+
    We iterate through the provisional labels and assign final labels based on
    our knowledge of prov. labels relationship.
    We also track how many distinct final labels we have.
    +/
    DTYPE_t counter = 1;

    foreach (i; 0..shapeinfo.numels){
        if (i == forest_p[i]){
            // We have stumbled across a root which is something new to us (root
            // is the LOWEST of all prov. labels that are equivalent to it)

            // If the root happens to be the background,
            // assign the background label instead of a
            // new label from the counter
            if (i == bg.background_node)
                // Also, if there is no background in the image,
                // bg.background_node == BG_NODE_NULL < 0 and this never occurs.
                data_p[i] = bg.background_label;
            else{
                data_p[i] = counter;
                // The background label is basically hardcoded to 0, so no need
                // to check that the new counter != bg.background_label
                counter += 1;
            }
        }else
            data_p[i] = data_p[forest_p[i]];
    }
    return counter - 1;
}

void scanBG(DTYPE_t* data_p, DTYPE_t* forest_p, shape_info* shapeinfo,
                 bginfo* bg) @nogc nothrow {
    /+
    Settle all background pixels now and don't bother with them later.
    Since this only requires one linar sweep through the array, it is fast
    and it makes sense to do it separately.
    The purpose of this function is update of forest_p and bg parameter inplace.
    +/
    DTYPE_t bgval = bg.background_val, firstbg = shapeinfo.numels;
    // We find the provisional label of the background, which is the index of
    // the first background pixel
    foreach (i; 0..shapeinfo.numels){
        if (data_p[i] == bgval){
            firstbg = i;
            bg.background_node = firstbg;
            break;
        }
    }
    // There is no background, therefore the first background element
    // is not defined.
    // Since BG_NODE_NULL < 0, this is enough to ensure
    // that resolve_labels doesn't worry about background.
    if (bg.background_node == BG_NODE_NULL)
        return;

    // And then we apply this provisional label to the whole background
    foreach(i; firstbg..shapeinfo.numels)
        if (data_p[i] == bgval)
            forest_p[i] = firstbg;
}

void scan1D(DTYPE_t* data_p, DTYPE_t* forest_p, shape_info* shapeinfo,
                 bginfo* bg, DTYPE_t connectivity, DTYPE_t y, DTYPE_t z) @nogc nothrow {
    /+
    Perform forward scan on a 1D object, usually the first row of an image
    +/
    if (shapeinfo.numels == 0)
        return;
    // Initialize the first row
    DTYPE_t rindex, bgval = bg.background_val;
    DTYPE_t* DEX = shapeinfo.DEX.ptr;
    rindex = shapeinfo.ravel_index(0, y, z, shapeinfo);

    foreach(x; 1..shapeinfo.x){
        rindex++;
        // Handle the first row
        if (data_p[rindex] == bgval)
            // Nothing to do if we are background
            continue;

        join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ed]);
    }
}

void scan2D(DTYPE_t* data_p, DTYPE_t* forest_p, shape_info* shapeinfo,
                 bginfo* bg, DTYPE_t connectivity, DTYPE_t z) @nogc nothrow {
    /+
    Perform forward scan on a 2D array.
    +/
    if (shapeinfo.numels == 0)
        return;
    DTYPE_t rindex, bgval = bg.background_val;
    DTYPE_t* DEX = shapeinfo.DEX.ptr;
    scan1D(data_p, forest_p, shapeinfo, bg, connectivity, 0, z);
    foreach (y; 1..shapeinfo.y){
        // BEGINNING of x = 0
        rindex = shapeinfo.ravel_index(0, y, 0, shapeinfo);
        // Handle the first column
        if (data_p[rindex] != bgval){
            // Nothing to do if we are background

            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eb]);

            if (connectivity >= 2)
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ec]);
        // END of x = 0
        }
        foreach(x; 1 .. shapeinfo.x - 1){
            // We have just moved to another column (of the same row)
            // so we increment the raveled index. It will be reset when we get
            // to another row, so we don't have to worry about altering it here.
            rindex += 1;
            if (data_p[rindex] == bgval)
                // Nothing to do if we are background
                continue;

            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eb]);
            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ed]);

            if (connectivity >= 2){
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ea]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ec]);
            }
        }
        // Finally, the last column
        // BEGINNING of x = max
        rindex++;
        if (data_p[rindex] != bgval){
            // Nothing to do if we are background

            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eb]);
            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ed]);

            if (connectivity >= 2)
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ea]);
        // END of x = max
        }
    }
}

void scan3D(DTYPE_t *data_p, DTYPE_t *forest_p, shape_info *shapeinfo,
                 bginfo *bg, DTYPE_t connectivity) @nogc nothrow
{
    /+
    Perform forward scan on a 3D array.
    +/
    if (shapeinfo.numels == 0)
        return;
    DTYPE_t rindex, bgval = bg.background_val;
    DTYPE_t* DEX = shapeinfo.DEX.ptr;
    // Handle first plane
    scan2D(data_p, forest_p, shapeinfo, bg, connectivity, 0);
    foreach(z; 1..shapeinfo.z){
        // Handle first row in 3D manner
        // BEGINNING of y = 0
        // BEGINNING of x = 0
        rindex = shapeinfo.ravel_index(0, 0, z, shapeinfo);
        if (data_p[rindex] != bgval){
            // Nothing to do if we are background

            // Now we have pixels below
            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ej]);

            if (connectivity >= 2){
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ek]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_em]);
                if (connectivity >= 3)
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_en]);
            }
        
        }// END of x = 0
        foreach(x; 1 .. shapeinfo.x - 1){
            rindex++;
            // Handle the first row
            if (data_p[rindex] == bgval)
                continue;// Nothing to do if we are background
                

            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ed]);
            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ej]);

            if (connectivity >= 2){
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ei]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ek]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_em]);
                if (connectivity >= 3){
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_el]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_en]);
                }
            }
        }
        // BEGINNING of x = max
        rindex++;
        // Handle the last element of the first row
        if (data_p[rindex] != bgval){
            // Nothing to do if we are background

            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ed]);
            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ej]);

            if (connectivity >= 2){
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ei]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_em]);
                if (connectivity >= 3)
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_el]);
            }
        }
        // END of x = max
        // END of y = 0
        
        // BEGINNING of y = ...
        foreach(y; 1 .. shapeinfo.y - 1){
            // BEGINNING of x = 0
            rindex = shapeinfo.ravel_index(0, y, z, shapeinfo);
            // Handle the first column in 3D manner
            if (data_p[rindex] != bgval){
                // Nothing to do if we are background

                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eb]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ej]);

                if (connectivity >= 2){
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ec]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eg]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ek]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_em]);
                    if (connectivity >= 3){
                        join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eh]);
                        join_trees_wrapper(data_p, forest_p, rindex, DEX[D_en]);
                    }
                }
            
            }// END of x = 0
            // Handle the rest of columns
            foreach(x; 1 .. shapeinfo.x - 1){
                rindex++;
                if (data_p[rindex] == bgval)
                    continue;// Nothing to do if we are background
                    

                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eb]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ed]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ej]);

                if (connectivity >= 2){
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ea]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ec]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eg]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ei]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ek]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_em]);
                    if (connectivity >= 3){
                        join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ef]);
                        join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eh]);
                        join_trees_wrapper(data_p, forest_p, rindex, DEX[D_el]);
                        join_trees_wrapper(data_p, forest_p, rindex, DEX[D_en]);
                    }
                }
            }
            // BEGINNING of x = max
            rindex++;
            if (data_p[rindex] != bgval){
                // Nothing to do if we are background

                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eb]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ed]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ej]);

                if (connectivity >= 2){
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ea]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eg]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ei]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_em]);
                    if (connectivity >= 3){
                        join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ef]);
                        join_trees_wrapper(data_p, forest_p, rindex, DEX[D_el]);
                    }
                }
            }// END of x = max
        }// END of y = ...

        // BEGINNING of y = max
        // BEGINNING of x = 0
        rindex = shapeinfo.ravel_index(0, shapeinfo.y - 1, z, shapeinfo);
        // Handle the first column in 3D manner
        if (data_p[rindex] != bgval){
            // Nothing to do if we are background

            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eb]);
            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ej]);

            if (connectivity >= 2){
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ec]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eg]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ek]);
                if (connectivity >= 3)
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eh]);
            }
        }// END of x = 0

        // Handle the rest of columns
        foreach(x; 1 .. shapeinfo.x - 1){
            rindex++;
            if (data_p[rindex] == bgval)
                continue;// Nothing to do if we are background
                

            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eb]);
            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ed]);
            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ej]);

            if (connectivity >= 2){
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ea]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ec]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eg]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ei]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ek]);
                if (connectivity >= 3){
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ef]);
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eh]);
                }
            }
        }
        // BEGINNING of x = max
        rindex++;
        if (data_p[rindex] != bgval){
            // Nothing to do if we are background

            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eb]);
            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ed]);
            join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ej]);

            if (connectivity >= 2){
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ea]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_eg]);
                join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ei]);
                if (connectivity >= 3)
                    join_trees_wrapper(data_p, forest_p, rindex, DEX[D_ef]);
            }
        }// END of x = max
        // END of y = max
    }
}