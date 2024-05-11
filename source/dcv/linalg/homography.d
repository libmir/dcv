/*
    Authors: Burak Künkçü, Ferhat Kurtulmuş

    Based on the original python implementation https://github.com/kunkcu/image-stitching
*/

module dcv.linalg.homography;

import std.typecons;
import std.math;
import std.container.array : Array;
debug import std.stdio;

import mir.ndslice;
import mir.rc;
import mir.math.stat : mean;

import kaleidic.lubeck2;


import dcv.features.utils : FeatureMatch;

@nogc nothrow:

Tuple!(Slice!(RCI!double), Slice!(RCI!double))
applyHomography(const ref Slice!(RCI!double) x, const ref Slice!(RCI!double) y, const ref Slice!(RCI!double, 2) H)
{
    auto D = H[2,0] * x[] + H[2,1] * y[] + 1.0;
    auto xs = ((H[0,0] * x[] + H[0,1] * y[] + H[0,2]) / D[]).rcslice;
    auto ys = ((H[1,0] * x[] + H[1,1] * y[] + H[1,2]) / D[]).rcslice;

    return tuple(xs, ys);
}

Tuple!(double, double)
applyHomography(double x, double y, const ref Slice!(RCI!double, 2) H)
{
    auto D = H[2,0] * x + H[2,1] * y + 1.0;
    double xs = (H[0,0] * x + H[0,1] * y + H[0,2]) / D;
    double ys = (H[1,0] * x + H[1,1] * y + H[1,2]) / D;

    return tuple(xs, ys);
}

Slice!(RCI!double, 2)
applyHomographyJacobian(const ref Slice!(RCI!double) x, const ref Slice!(RCI!double) y, const ref Slice!(RCI!double, 2) H){

    const N = x.shape[0];
    auto J = rcslice!double([2*N, 8], 0.0);
    auto D = H[2,0] * x[] + H[2,1] * y[] + 1.0;
    auto xs = (H[0,0] * x[] + H[0,1] * y[] + H[0,2]) / D[];
    auto ys = (H[1,0] * x[] + H[1,1] * y[] + H[1,2]) / D[];

    J[0..N,0] = x[] / D[];
    J[0..N,1] = y[] / D[];
    J[0..N,2] = 1.0 / D[];
    J[0..N,6] = - x[] * xs[];
    J[0..N,7] = - y[] * ys[];

    J[N..2*N,3] = x[] / D[];
    J[N..2*N,4] = y[] / D[];
    J[N..2*N,5] = 1.0 / D[];
    J[N..2*N,6] = - x[] * xs[];
    J[N..2*N,7] = - y[] * ys[];

    return J;

}

Slice!(RCI!double, 2)
findHomography(const ref Slice!(RCI!double) x, const ref Slice!(RCI!double) y, const ref Slice!(RCI!double) xp, const ref Slice!(RCI!double) yp, size_t iters)
{
    // x,y,xp&yp-> N-by-1
    import kaleidic.lubeck2 : pinv;

    auto H = rcslice!double([3,3], 0.0);
    H[2,2] = 1.0;

    foreach(_; 0..iters)
    {
        // Compute homography coordinates
        auto xs_ys = applyHomography(x, y, H);
        auto xs = xs_ys[0];
        auto ys = xs_ys[1];
        // Compute residuals
        auto rx = xs[] - xp[];
        auto ry = ys[] - yp[];

        auto r = uninitRCslice!double(xs.length*2);
        r[0..rx.length] = rx[];
        r[rx.length..$] = ry[];

        // Compute Jacobian
        auto J = applyHomographyJacobian(x,y,H);
        
        // Compute update via linear least squares
        size_t errResponse;
        auto JT = J.transposed;
        auto delta = pinv(mtimes(JT, J), errResponse).mtimes(JT).mtimes(r);
        
        enum msg = "pinv: pinv was not successful due to a convergence issue during SVD calculation.";
        assert(!errResponse, msg);
        
        // Update homography matrix
        auto newDelta = uninitRCslice!double(delta.shape[0]+1);
        newDelta[0..delta.length] = delta[];
        newDelta[$-1] = 0;
        
        H.flattened[] -= newDelta[];
    }
    return H;
}

auto estimateHomographyRANSAC(KeyPoint)(const ref Array!KeyPoint keypoints1,
            const ref Array!KeyPoint keypoints2,
            const ref Array!FeatureMatch matches,
            size_t min_points = 10, size_t req_points = 20, 
            size_t gn_iters = 100, size_t max_iters = 1000, double ransac_threshold = 3)
{

    auto H_best = Slice!(RCI!double, 2)();
    double err_best = 100000000;
    Slice!(RCI!double) x_best, y_best, xp_best, yp_best;
    Slice!(RCI!size_t) idx_best;

    debug writeln("      Extracting matched feature point coordinates...");
    auto x_y_xp_yp = get_match_coordinates(keypoints1, keypoints2, matches);
    Slice!(RCI!double) x = x_y_xp_yp[0];
    Slice!(RCI!double) y = x_y_xp_yp[1];
    Slice!(RCI!double) xp = x_y_xp_yp[2];
    Slice!(RCI!double) yp = x_y_xp_yp[3];

    debug writeln("      Running RANSAC iterations...");
    foreach( num_iter; 0..max_iters){
        Slice!(RCI!double) x_inl, y_inl, xp_inl, yp_inl;
        Slice!(RCI!double) x_oth, y_oth, xp_oth, yp_oth;

        Slice!(RCI!size_t) idx_inl, idx_oth;

        if (!idx_best.empty)
        {
            // Get 'num_inliers/2' random inliers from the best set
            auto inliers_outliers = get_random_inliers_with_index(x, y, xp, yp, idx_best, (idx_best.length / 2));
            x_inl = inliers_outliers[0];
            y_inl = inliers_outliers[1];
            xp_inl = inliers_outliers[2];
            yp_inl = inliers_outliers[3];
            x_oth = inliers_outliers[4];
            y_oth = inliers_outliers[5];
            xp_oth = inliers_outliers[6];
            yp_oth = inliers_outliers[7];
            idx_inl = inliers_outliers[8];
            idx_oth = inliers_outliers[9];
        } else{
            // Get 'min_points' random inliers from the set
            auto inliers_outliers = get_random_inliers(x, y, xp, yp, min_points);
            x_inl = inliers_outliers[0];
            y_inl = inliers_outliers[1];
            xp_inl = inliers_outliers[2];
            yp_inl = inliers_outliers[3];
            x_oth = inliers_outliers[4];
            y_oth = inliers_outliers[5];
            xp_oth = inliers_outliers[6];
            yp_oth = inliers_outliers[7];
            idx_inl = inliers_outliers[8];
            idx_oth = inliers_outliers[9];
        }

        // Fit a homography to randomly selected inliers
        auto H = findHomography(x_inl, y_inl, xp_inl, yp_inl, gn_iters);

        // Evaluate homography on the rest of the set
        auto xs_oth_ys_oth = applyHomography(x_oth, y_oth, H);
        auto xs_oth = xs_oth_ys_oth[0];
        auto ys_oth = xs_oth_ys_oth[1];

        auto r_oth = ((xs_oth.lightScope[] - xp_oth.lightScope[]).map!(a => a * a) + 
                      (ys_oth.lightScope[] - yp_oth.lightScope[]).map!(a => a * a)).map!(a => cast(double)sqrt(a));

        // Add good fit points to inliers

        auto idx = zip(r_oth, iota(r_oth.length), ransac_threshold.repeat(r_oth.length))
            .filter!(x => x.a < x.c).map!(a => a.b).rcarray;

        if (idx.length > 0)
        {
            auto _x_inl = uninitRCslice!double(x_inl.shape[0] + idx.length);
            _x_inl[0..x_inl.length] = x_inl[];
            {
                size_t kk = 0;
                foreach(_id; idx[]){
                    _x_inl[(kk++) + x_inl.length] = x_oth[_id];
                }
            }
            //_x_inl[x_inl.length..$] = idx.lightScope.rcmap!(a => x_oth[a]).asSlice;
            x_inl = _x_inl;

            auto _y_inl = uninitRCslice!double(y_inl.shape[0] + idx.length);
            _y_inl[0..y_inl.length] = y_inl[];
            {
                size_t kk = 0;
                foreach(_id; idx[]){
                    _y_inl[(kk++) + y_inl.length] = y_oth[_id];
                }
            }
            //_y_inl[y_inl.length..$] = idx.lightScope.rcmap!(a => y_oth[a]).asSlice;
            y_inl = _y_inl;

            auto _xp_inl = uninitRCslice!double(xp_inl.shape[0] + idx.length);
            _xp_inl[0..xp_inl.length] = xp_inl[];
            {
                size_t kk = 0;
                foreach(_id; idx[]){
                    _xp_inl[(kk++) + xp_inl.length] = xp_oth[_id];
                }
            }
            //_xp_inl[xp_inl.length..$] = idx.lightScope.rcmap!(a => xp_oth[a]).asSlice;
            xp_inl = _xp_inl;

            auto _yp_inl = uninitRCslice!double(yp_inl.shape[0] + idx.length);
            _yp_inl[0..yp_inl.length] = yp_inl[];
            {
                size_t kk = 0;
                foreach(_id; idx[]){
                    _yp_inl[(kk++) + yp_inl.length] = yp_oth[_id];
                }
            }
            //_yp_inl[yp_inl.length..$] = idx.lightScope.rcmap!(a => yp_oth[a]).asSlice;
            yp_inl = _yp_inl;

            auto _idx_inl = uninitRCslice!size_t(idx_inl.shape[0] + idx.length);
            _idx_inl[0..idx_inl.length] = idx_inl[];
            {
                size_t kk = 0;
                foreach(_id; idx[]){
                    _idx_inl[(kk++) + idx_inl.length] = idx_oth[_id];
                }
            }
            //_idx_inl[idx_inl.length..$] = idx.lightScope.rcmap!(a => idx_oth[a]).asSlice;
            idx_inl = _idx_inl;
        }

        // Check if found model has enough inliers
        if (x_inl.shape[0] >= req_points)
        {
            // Fit a homography again to all found inliers
            H = findHomography(x_inl, y_inl, xp_inl, yp_inl, gn_iters);

            // Evaluate homography on all found inliers
            auto xs_inl_ys_inl = applyHomography(x_inl, y_inl, H);
            auto xs_inl = xs_inl_ys_inl[0];
            auto ys_inl = xs_inl_ys_inl[1];

            auto err = ((xs_inl.lightScope[] - xp_inl.lightScope[]).map!(a => a * a) + 
                        (ys_inl.lightScope[] - yp_inl.lightScope[]).map!(a => a * a)).map!(a => sqrt(a)).mean!double;
            
            // Check if found error is better than the best model
            if (err < err_best)
            {
                // Update best homography, error and inlier points
                H_best = H;
                err_best = err;

                x_best = x_inl;
                y_best = y_inl;
                xp_best = xp_inl;
                yp_best = yp_inl;
                idx_best = idx_inl;
            }
        }
    }
    return tuple(H_best, x_best, y_best, xp_best, yp_best, idx_best);
}

auto stitch(InputSlice1, InputSlice2)
(   
    const ref InputSlice1 img1,
    const ref InputSlice2 img2,
    const ref Array!(Slice!(RCI!double, 2)) H,
    int r_shift_prev, int c_shift_prev, size_t estimation_iters = 1
)
{
    auto img1_rows = img1.shape[0];
    auto img1_cols = img1.shape[1];
    auto img2_rows = img2.shape[0];
    auto img2_cols = img2.shape[1];

    auto img1_transformed_coordinates = uninitRCslice!int(img1_rows, img1_cols, 2);
    
    int r_min = int.max;
    int c_min = int.max;
    int r_max = int.min;
    int c_max = int.min;

    // Transform image one
    foreach(int r; 0..cast(int)img1_rows)
    {
        foreach(int c; 0..cast(int)img1_cols)
        {
            double _xs = cast(double)c;
            double _ys = cast(double)r;

            foreach_reverse( H_i; H)
            {
                auto xs_ys = applyHomography(_xs, _ys, H_i);
                _xs = xs_ys[0];
                _ys = xs_ys[1];
            }
                

            _xs += c_shift_prev;
            _ys += r_shift_prev;
            int xs = cast(int)_xs;
            int ys = cast(int)_ys;

            if (ys < r_min)
                r_min = ys;

            if (ys > r_max)
                r_max = ys;

            if( xs < c_min)
                c_min = xs;

            if (xs > c_max)
                c_max = xs;

            img1_transformed_coordinates[r,c,0] = ys;
            img1_transformed_coordinates[r,c,1] = xs;
        }
    }
    // Calculate the size of the stitched image
    auto out_rows = img2_rows;
    auto out_cols = img2_cols;

    if (r_min < 0)
        out_rows -= r_min;

    if (r_max > img2_rows - 1)
        out_rows += (r_max - img2_rows + 1);

    if (c_min < 0)
        out_cols -= c_min;

    if (c_max > img2_cols - 1)
        out_cols += (c_max - img2_cols + 1);

    auto _out = rcslice!ubyte([out_rows, out_cols, 3], 0);
    auto out_temp = rcslice!ubyte([out_rows, out_cols, 3], 0);
    auto out_temp_map = rcslice!bool([out_rows, out_cols], false);
    auto out_map1 = rcslice!bool([out_rows, out_cols], false);
    auto out_map2 = rcslice!bool([out_rows, out_cols], false);

    int r_shift = 0;
    if (r_min < 0)
        r_shift = - r_min;

    int c_shift = 0;
    if (c_min < 0)
        c_shift = - c_min;

    // Insert image one
    foreach(r; 0..img1_rows){
        foreach(c; 0..img1_cols){
            auto rt = img1_transformed_coordinates[r,c,0];
            auto ct = img1_transformed_coordinates[r,c,1];
            rt += r_shift;
            ct += c_shift;

            out_temp[rt,ct,0..$] = img1[r,c,0..$];

            out_temp_map[rt,ct] = true;
        }
    }
    
    import mir.algorithm.iteration : all;

    // Estimate missing pixel values in image one
    foreach(_; 0..estimation_iters) {
        foreach(r; 1..out_rows-1) {
            foreach(c; 1..out_cols-1) {
                auto patch = out_temp[r-1..r+2, c-1..c+2, 0..$];
                auto patch_map = out_temp_map[r-1..r+2, c-1..c+2];

                if (out_temp_map[r, c] == false && !patch_map.all!(aa => aa == false)) {

                    // compute median pixel based on the neighbor pixels

                    import mir.appender : scopedBuffer;
                    import mir.ndslice.sorting : sort;
                    import std.array : staticArray;

                    auto accumChannel0 = scopedBuffer!ubyte;
                    auto accumChannel1 = scopedBuffer!ubyte;
                    auto accumChannel2 = scopedBuffer!ubyte;
                    
                    foreach (i; 0..patch.shape[0])
                    {
                        foreach (j; 0..patch.shape[1])
                        {
                            if (patch_map[i, j] == true)
                            {
                                accumChannel0.put(patch[i,j,0]);
                                accumChannel1.put(patch[i,j,1]);
                                accumChannel2.put(patch[i,j,2]);
                            }
                        }
                    }
                    
                    accumChannel0.data.sliced.sort;
                    accumChannel1.data.sliced.sort;
                    accumChannel2.data.sliced.sort;

                    const midIndex = accumChannel0.data.length / 2;

                    out_temp[r, c, 0..$] = [
                        accumChannel0.data[midIndex],
                        accumChannel1.data[midIndex],
                        accumChannel2.data[midIndex]].staticArray[];
                    out_map1[r, c] = true;
                }
            }
        }
        
        out_temp_map[] = out_temp_map[] | out_map1[];
    }
    
    out_map1 = out_temp_map;

    // Insert image two
    foreach(r; 0..img2_rows){
        foreach(c; 0..img2_cols){
            auto rt = r + r_shift;
            auto ct = c + c_shift;
            if(!img2[r,c,0..$].all!(aa => aa == 0)){
                _out[rt,ct,0..$] = img2[r,c,0..$];
                out_map2[rt,ct] = true;
            }
        }
    }
    // Merge two maps
    foreach(r; 0..out_rows){
        foreach(c; 0..out_cols){
            if (out_map1[r,c]){
                if (out_map2[r,c]){
                    _out[r,c,0..$] = ((_out[r,c,0..$].as!double + out_temp[r,c,0..$].as!double) / 2.0).as!ubyte;
                }else{
                    _out[r,c,0..$] = out_temp[r,c,0..$];
                }
            }
        }
    }
    return tuple(_out, r_shift_prev + r_shift, c_shift_prev + c_shift);
}

package:

auto get_match_coordinates(KeyPoint)(const ref Array!KeyPoint keypoints1,
                        const ref Array!KeyPoint keypoints2,
                        const ref Array!FeatureMatch matches)
{
    immutable N = matches.length;

    auto x  = uninitRCslice!double(N);
    auto y  = uninitRCslice!double(N);
    auto xp = uninitRCslice!double(N);
    auto yp = uninitRCslice!double(N);

    foreach(k; 0..N){
        auto index1_index2 = matches[k];
        auto index1 = index1_index2[0];
        auto index2 = index1_index2[1];

        x[k] = floor(keypoints1[index1].x); 
        y[k] = floor(keypoints1[index1].y);
        xp[k] = floor(keypoints2[index2].x);
        yp[k] = floor(keypoints2[index2].y);
    }
        

    return tuple(x,y,xp,yp);
}

auto get_random_inliers()(const ref Slice!(RCI!double) x, const ref Slice!(RCI!double) y, const ref Slice!(RCI!double) xp, const ref Slice!(RCI!double) yp, size_t n)
{
    import mir.random.algorithm : sample;
    import mir.appender;

    import std.algorithm.searching : canFind;
    import std.typecons : tuple;

    assert(n <= x.length );
    
    auto inliers_idx = iota(x.length).as!size_t.sample(n).rcarray.moveToSlice;
    //auto outliers_idx = iota(x.length).as!size_t.filter!(a => !canFind(inliers_idx[], a)).rcarray.moveToSlice;
    
    import mir.appender: scopedBuffer;

    auto outBuff = scopedBuffer!size_t;
    foreach (id; 0..x.length)
    {
        if(!canFind(inliers_idx[], id)){
            outBuff.put(id);
        }
    }
    
    auto outliers_idx = outBuff.data.rcslice;

    assert(inliers_idx.length + outliers_idx.length == x.length );
    
    auto x_inliers = inliers_idx.rcmap!(a => cast(double)x[a]).moveToSlice;
    auto y_inliers = inliers_idx.rcmap!(a => cast(double)y[a]).moveToSlice;
    auto xp_inliers = inliers_idx.rcmap!(a => cast(double)xp[a]).moveToSlice;
    auto yp_inliers = inliers_idx.rcmap!(a => cast(double)yp[a]).moveToSlice;

    auto x_outliers = outliers_idx.rcmap!(a => cast(double)x[a]).moveToSlice;
    auto y_outliers = outliers_idx.rcmap!(a => cast(double)y[a]).moveToSlice;
    auto xp_outliers = outliers_idx.rcmap!(a => cast(double)xp[a]).moveToSlice;
    auto yp_outliers = outliers_idx.rcmap!(a => cast(double)yp[a]).moveToSlice;

    return tuple(
        x_inliers, y_inliers, xp_inliers, yp_inliers,
        x_outliers, y_outliers, xp_outliers, yp_outliers,
        inliers_idx,
        outliers_idx
    );
}

auto get_random_inliers_with_index(const ref Slice!(RCI!double) x, const ref Slice!(RCI!double) y, const ref Slice!(RCI!double) xp, const ref Slice!(RCI!double) yp, Slice!(RCI!size_t) idx, size_t n)
{
    import mir.random.algorithm : sample;
    import std.stdio;

    import std.algorithm.searching : canFind;
    import std.typecons : tuple;

    import mir.ndslice.sorting;

    auto inl_unique = idx.rcslice.sort.uniq.rcarray.moveToSlice;

    Slice!(RCI!size_t) inliers_idx;
    
    if(inl_unique.length <= n){
        inliers_idx = inl_unique;
    }else{
        inliers_idx = inl_unique.sample(n).rcarray.moveToSlice;
    }

    // auto outliers_idx = iota(x.length).as!size_t.filter!(a => !canFind(inliers_idx[], a)).rcarray.moveToSlice;
    
    import mir.appender: scopedBuffer;

    auto outBuff = scopedBuffer!size_t;
    foreach (id; 0..x.length)
    {
        if(!canFind(inliers_idx[], id)){
            outBuff.put(id);
        }
    }
    
    auto outliers_idx = outBuff.data.rcslice;

    assert(inliers_idx.length + outliers_idx.length == x.length);
    
    auto x_inliers = inliers_idx.rcmap!(a => cast(double)x[a]).moveToSlice;
    auto y_inliers = inliers_idx.rcmap!(a => cast(double)y[a]).moveToSlice;
    auto xp_inliers = inliers_idx.rcmap!(a => cast(double)xp[a]).moveToSlice;
    auto yp_inliers = inliers_idx.rcmap!(a => cast(double)yp[a]).moveToSlice;

    auto x_outliers = outliers_idx.rcmap!(a => cast(double)x[a]).moveToSlice;
    auto y_outliers = outliers_idx.rcmap!(a => cast(double)y[a]).moveToSlice;
    auto xp_outliers = outliers_idx.rcmap!(a => cast(double)xp[a]).moveToSlice;
    auto yp_outliers = outliers_idx.rcmap!(a => cast(double)yp[a]).moveToSlice;

    return tuple(
        x_inliers, y_inliers, xp_inliers, yp_inliers,
        x_outliers, y_outliers, xp_outliers, yp_outliers,
        inliers_idx,
        outliers_idx
    );
}