/** Authors: dbarac (the original implementor)
    
    Translated to dlang by Ferhat Kurtulmuş
    Converted from the original C++ implementation:
        https://github.com/dbarac/sift-cpp
*/

module dcv.features.sift;

import std.array;
import std.typecons;
import std.algorithm : max, min;
public import std.container.array;
import std.math;
import std.range;
import std.typecons;

import core.lifetime : move;

import mir.ndslice;
import mir.rc;
import mir.math.common : fastmath;

import dcv.core;
import dcv.features.utils;

// due to a small race issue different executions yield slightly different result. This is not a problem for now.
// I tried mutex at several places but could not figure it out yet.

struct SIFTKeypoint {
    // discrete coordinates
    int i;
    int j;
    int octave;
    int scale; //index of gaussian image inside the octave

    // continuous coordinates (interpolated)
    float x; // use x (column) and y (row) for the exact coordinates according to the input image.
    float y; 
    float sigma;
    float extremum_val; //value of interpolated DoG extremum
    
    ubyte[128] descriptor;
}

@nogc nothrow:

import dplug.core.sync;

private __gshared UncheckedMutex mutex;

/++
    Run SIFT feature detection algorithm for a given input slice. The algorithm runs on grayscale images, so
    3 channel inputs (RGB assumed) are implicitly converted to grayscale.
    input slice's pixel value range must be 0-255 (not limited to ubyte). Agnostic to Slice kind (Contigous, Universal or whatsoever). 
    Returns a keypoints vector.
+/

@fastmath
Array!SIFTKeypoint find_SIFTKeypointsAndDescriptors(InputSlice)(auto ref InputSlice inputSlice, 
                                                float sigma_min=SIGMA_MIN,
                                                int num_octaves=N_OCT, 
                                                int scales_per_octave=N_SPO, 
                                                float contrast_thresh=C_DOG,
                                                float edge_thresh=C_EDGE,
                                                float lambda_ori=LAMBDA_ORI,
                                                float lambda_desc=LAMBDA_DESC)
{
    enum N = InputSlice.N;
    static assert(N == 2 || N == 3, 
        "Only 2D and 3D slices are supported. 3D slices will be implicitly converted to grayscale");

    static if(N==3){
        // convert the assumed RGB to gray and normalize it by dividing 255

        /*import dcv.imgproc.color : rgb2gray;
        auto _input = inputSlice.rgb2gray;
        auto input = _input.as!float / 255.0f;*/

        // below is faster
        import mir.algorithm.iteration: each;
        auto input = uninitRCslice!float(inputSlice.shape[0], inputSlice.shape[1]);
        /*size_t kk;
        auto flatIter = inputSlice.flattened;
        input.each!((ref a) { a = (0.299*flatIter[3*kk] + 0.587*flatIter[3*kk+1] + 0.114*flatIter[3*kk+2])/255.0f; kk++;});*/
        
        void worker(int _col, int threadIndex) nothrow @nogc @fastmath 
        {
            auto col = cast(size_t)_col;
            foreach(row; 0 .. inputSlice.shape[0])
            {
                input[row, col] = (0.299f * inputSlice[row, col, 0]
                                 + 0.587f * inputSlice[row, col, 1] 
                                 + 0.114f * inputSlice[row, col, 2])/255.0f;
            }
        }
        pool.parallelFor(cast(int)inputSlice.shape[1], &worker);
        

    } else { // N == 2
        auto input = inputSlice.as!float / 255.0f;
    }

    
    ScaleSpacePyramid gaussian_pyramid = generate_gaussian_pyramid(input, sigma_min, num_octaves,
                                                                   scales_per_octave);
                                                                   
    ScaleSpacePyramid dog_pyramid = generate_dog_pyramid(gaussian_pyramid);
    
    Array!SIFTKeypoint tmp_kps = find_keypoints(dog_pyramid, contrast_thresh, edge_thresh);
    
    ScaleSpacePyramid grad_pyramid = generate_gradient_pyramid(gaussian_pyramid);
    
    Array!SIFTKeypoint kps; kps.reserve(tmp_kps.length);
    
    foreach (const ref kp_tmp; tmp_kps) {
        auto orientations = find_keypoint_orientations(kp_tmp, grad_pyramid,
                                                            lambda_ori, lambda_desc);

        foreach (float theta; orientations) {
            SIFTKeypoint kp = kp_tmp;
            compute_keypoint_descriptor(kp, theta, grad_pyramid, lambda_desc);
            kps ~= kp;
        }
    }
    return kps.move;
}

package:

struct ScaleSpacePyramid {
    int num_octaves;
    int imgs_per_octave;
    
    union {
        Array!(Array!(Slice!(RCI!float, 2))) octaves;
        Array!(Array!(Slice!(RCI!float, 3))) octaves_grad;
    }
}

enum M_PI = PI;

//*******************************************
// SIFT algorithm parameters, used by default
//*******************************************

// digital scale space configuration and keypoint detection
enum MAX_REFINEMENT_ITERS = 5;
public enum SIGMA_MIN = 0.8f;
enum MIN_PIX_DIST = 0.5f;
enum SIGMA_IN = 0.5f;
public enum N_OCT = 8;
public enum N_SPO = 3;
public enum C_DOG = 0.015f;
public enum C_EDGE = 10.0f;

// computation of the SIFT descriptor
enum N_BINS = 36;
public enum LAMBDA_ORI = 1.5f;
enum N_HIST = 4;
enum N_ORI = 8;
public enum LAMBDA_DESC = 6.0f;

ScaleSpacePyramid generate_gaussian_pyramid(InputSlice)(const ref InputSlice img, float sigma_min = SIGMA_MIN,
                                            int num_octaves = N_OCT, int scales_per_octave = N_SPO)
{
    import dcv.imgproc: resize, nearestNeighbor, bilinear, linear;

    // assume initial sigma is 1.0 (after resizing) and smooth
    // the image with sigma_diff to reach requried base_sigma
    float base_sigma = sigma_min / MIN_PIX_DIST;

    //auto base_img = resize2!(Interpolation.BILINEAR)(img, cast(int)img.shape[0]*2, cast(int)img.shape[1]*2); //.lightScope.scale([2.0f, 2.0f]);
    auto base_img = resize!bilinear(img, [img.shape[0]*2, img.shape[1]*2]);
    float sigma_diff = std.math.sqrt(base_sigma * base_sigma - 1.0f);
    
    base_img = gaussian_blur(base_img, sigma_diff);

    int imgs_per_octave = scales_per_octave + 3;

    // determine sigma values for bluring
    float k = std.math.pow(2, 1.0 / scales_per_octave);
    
    auto sigma_vals = uninitRCslice!float(imgs_per_octave);
    sigma_vals[0] = base_sigma;
    foreach (i; 1..imgs_per_octave) {
        float sigma_prev = base_sigma * std.math.pow(k, i - 1);
        float sigma_total = k * sigma_prev;
        sigma_vals[i] = std.math.sqrt(sigma_total * sigma_total - sigma_prev * sigma_prev);
    }

    // create a scale space pyramid of gaussian images
    // images in each octave are half the size of images in the previous one
    
    auto pyramid = ScaleSpacePyramid(
        num_octaves,
        imgs_per_octave
    );
    pyramid.octaves.length = num_octaves;
    foreach (i; 0..num_octaves) {
        pyramid.octaves[i].length = imgs_per_octave;
        pyramid.octaves[i][0] = base_img.move;

        foreach (j; 1..sigma_vals.length) 
        {
            auto prev_img = pyramid.octaves[i][j-1];
            pyramid.octaves[i][j] = gaussian_blur(prev_img, sigma_vals[j]);
        }
        // prepare base image for next octave
        const next_base_img = pyramid.octaves[i][imgs_per_octave - 3];
        
        //base_img = resize2!(Interpolation.NEAREST)(next_base_img, 
        //    cast(int)next_base_img.shape[0]/2, cast(int)next_base_img.shape[1]/2);//.lightScope.scale([0.5f, 0.5f]);
        
        base_img = resize!nearestNeighbor(next_base_img.lightScope, [next_base_img.shape[0]/2, next_base_img.shape[1]/2]);
    }
    
    return pyramid.move;
}

// generate pyramid of difference of gaussians (DoG) images
ScaleSpacePyramid generate_dog_pyramid(const ref ScaleSpacePyramid img_pyramid)
{
    //import std.range : iota;

    auto dog_pyramid = ScaleSpacePyramid(
        img_pyramid.num_octaves,
        img_pyramid.imgs_per_octave - 1
    );
    dog_pyramid.octaves.length = img_pyramid.num_octaves;

    void worker(int i, int threadIndex) nothrow @nogc @fastmath 
    //foreach (i; 0..dog_pyramid.num_octaves) 
    {
        dog_pyramid.octaves[i].length = dog_pyramid.imgs_per_octave;
        foreach (j; 1..img_pyramid.imgs_per_octave) 
        {
            auto diff = uninitRCslice!float(img_pyramid.octaves[i][j].shape);
            diff[] = img_pyramid.octaves[i][j][] - img_pyramid.octaves[i][j - 1][];
            dog_pyramid.octaves[i][j-1] = diff.move;
        }
    }
    pool.parallelFor(cast(int)dog_pyramid.num_octaves, &worker);
    return dog_pyramid.move;
}

bool point_is_extremum(SliceArray)(const ref SliceArray octave, int scale, int x, int y)
{
    const img = octave[scale];
    const prev = octave[scale-1];
    const next = octave[scale+1];

    bool is_min = true, is_max = true;
    float val = img.getPixel(y,x);
    float neighbor;

    foreach (dx; [-1,0,1].staticArray) {
        foreach (dy; [-1,0,1].staticArray) {
            neighbor = prev.getPixel(y+dy, x+dx);
            if (neighbor > val) is_max = false;
            if (neighbor < val) is_min = false;

            neighbor = next.getPixel(y+dy, x+dx);
            if (neighbor > val) is_max = false;
            if (neighbor < val) is_min = false;

            neighbor = img.getPixel(y+dy, x+dx);
            if (neighbor > val) is_max = false;
            if (neighbor < val) is_min = false;

            if (!is_min && !is_max) return false;
        }
    }
    return true;
}

pure @fastmath
Tuple!(float, float, float) fit_quadratic(SliceArray)(ref SIFTKeypoint kp,
                                              const ref SliceArray octave,
                                              int scale)
{
    const img = octave[scale];
    const prev = octave[scale-1];
    const next = octave[scale+1];

    float g1, g2, g3;
    float h11, h12, h13, h22, h23, h33;
    int x = kp.i, y = kp.j;

    // gradient 
    g1 = (next.getPixel(y, x) - prev.getPixel(y, x)) * 0.5f;
    g2 = (img.getPixel(y, x+1) - img.getPixel(y, x-1)) * 0.5f;
    g3 = (img.getPixel(y+1, x) - img.getPixel(y-1, x)) * 0.5f;

    // hessian
    h11 = next.getPixel(y, x) + prev.getPixel(y, x) - 2.0*img.getPixel(y, x);
    h22 = img.getPixel(y, x+1) + img.getPixel(y, x-1) - 2.0*img.getPixel(y, x);
    h33 = img.getPixel(y+1, x) + img.getPixel(y-1, x) - 2.0*img.getPixel(y, x);
    h12 = (next.getPixel(y, x+1) - next.getPixel(y, x-1) 
         - prev.getPixel(y, x+1) + prev.getPixel(y, x-1)) * 0.25f;
    h13 = (next.getPixel(y+1, x) - next.getPixel(y-1, x) 
         - prev.getPixel(y+1, x) + prev.getPixel(y-1, x)) * 0.25f;
    h23 = (img.getPixel(y+1, x+1) - img.getPixel(y-1, x+1) 
         - img.getPixel(y+1, x-1) + img.getPixel(y-1, x-1)) * 0.25f;

    // invert hessian
    float hinv11, hinv12, hinv13, hinv22, hinv23, hinv33;
    float det = h11*h22*h33 - h11*h23*h23 - h12*h12*h33 + 2*h12*h13*h23 - h13*h13*h22;
    
    hinv11 = (h22*h33 - h23*h23) / det;
    hinv12 = (h13*h23 - h12*h33) / det;
    hinv13 = (h12*h23 - h13*h22) / det;
    hinv22 = (h11*h33 - h13*h13) / det;
    hinv23 = (h12*h13 - h11*h23) / det;
    hinv33 = (h11*h22 - h12*h12) / det;

    // find offsets of the interpolated extremum from the discrete extremum
    float offset_s = -hinv11*g1 - hinv12*g2 - hinv13*g3;
    float offset_x = -hinv12*g1 - hinv22*g2 - hinv23*g3;
    float offset_y = -hinv13*g1 - hinv23*g3 - hinv33*g3;

    float interpolated_extrema_val = img.getPixel(y, x)
                                + 0.5f*(g1*offset_s + g2*offset_x + g3*offset_y);
    kp.extremum_val = interpolated_extrema_val;
    return tuple(offset_s, offset_x, offset_y);
}

pure @fastmath
void find_input_img_coords(ref SIFTKeypoint kp, float offset_s, float offset_x, float offset_y,
                                   float sigma_min=SIGMA_MIN,
                                   float min_pix_dist=MIN_PIX_DIST, int n_spo=N_SPO)
{
    kp.sigma = pow(2, kp.octave) * sigma_min * pow(2, (offset_s+kp.scale)/n_spo);
    kp.x = min_pix_dist * pow(2, kp.octave) * (offset_x+kp.i);
    kp.y = min_pix_dist * pow(2, kp.octave) * (offset_y+kp.j);
}

bool refine_or_discard_keypoint(SliceArray)(ref SIFTKeypoint kp, const ref SliceArray octave,
                                float contrast_thresh, float edge_thresh)
{
    int k = 0;
    bool kp_is_valid = false; 
    while (k++ < MAX_REFINEMENT_ITERS) {
        auto offset_s_offset_x_offset_y = fit_quadratic(kp, octave, kp.scale);
        auto offset_s = offset_s_offset_x_offset_y[0];
        auto offset_x = offset_s_offset_x_offset_y[1];
        auto offset_y = offset_s_offset_x_offset_y[2];

        float max_offset = max(abs(offset_s),
                               abs(offset_x),
                               abs(offset_y));
        // find nearest discrete coordinates
        kp.scale += cast(int)round(offset_s);
        kp.i += cast(int)round(offset_x);
        kp.j += cast(int)round(offset_y);

        if (kp.scale >= octave.length-1 || kp.scale < 1)
            break;
        bool valid_contrast = abs(kp.extremum_val) > contrast_thresh;
        if (max_offset < 0.6f && valid_contrast && !point_is_on_edge(kp, octave, edge_thresh)) {
            find_input_img_coords(kp, offset_s, offset_x, offset_y);
            kp_is_valid = true;
            break;
        }
    }

    return kp_is_valid;
}

@fastmath
Array!SIFTKeypoint find_keypoints(const ref ScaleSpacePyramid dog_pyramid, float contrast_thresh=C_DOG, float edge_thresh=C_EDGE)
{
    import std.range : iota;

    Array!SIFTKeypoint keypoints;
    foreach (int i; 0..dog_pyramid.num_octaves) 
    {
        const octave = dog_pyramid.octaves[i];
        
        import std.range : iota;
        auto iterable = iota(1, dog_pyramid.imgs_per_octave-1);

        void worker(int _j, int threadIndex) nothrow @nogc @fastmath
        //foreach (int j; 1..dog_pyramid.imgs_per_octave-1) 
        {
            auto j = iterable[_j];
            const img = octave[j].lightScope.dropBorders;
            
            foreach (flatIndex; 0..img.shape[0]*img.shape[1])
            {
                auto y = cast(int)(flatIndex / img.shape[1]);
                auto x = cast(int)(flatIndex % img.shape[1]);
                if (abs(img.getPixel(y, x)) < 0.8f*contrast_thresh) 
                {
                    continue;
                }
                
                if (point_is_extremum(octave, j, x+1, y+1)) 
                {
                    auto kp = SIFTKeypoint(x+1, y+1, i, j, -1, -1, -1, -1);

                    
                    bool kp_is_valid = refine_or_discard_keypoint(kp, octave, contrast_thresh,
                                                                    edge_thresh);
                    if (kp_is_valid) 
                    {
                        mutex.lockLazy;
                        keypoints ~= kp;
                        mutex.unlock;
                    }
                    
                }
            }
        }
        pool.parallelFor(cast(int)iterable.length, &worker);
    }
    
    return keypoints;
}

@fastmath
void compute_keypoint_descriptor(ref SIFTKeypoint kp, float theta,
                                 const ref ScaleSpacePyramid grad_pyramid,
                                 float lambda_desc=LAMBDA_DESC)
{
    const float pix_dist = MIN_PIX_DIST * pow(2, kp.octave);
    const img_grad = grad_pyramid.octaves_grad[kp.octave][kp.scale];

    auto histograms = rcslice!float([N_HIST, N_HIST, N_ORI], 0);

    //find start and end coords for loops over image patch
    const float half_size = 1.41421f*lambda_desc*kp.sigma*(N_HIST+1.0f)/N_HIST;
    const x_start = cast(int)round((kp.x-half_size) / pix_dist);
    const x_end = cast(int)round((kp.x+half_size) / pix_dist);
    const y_start = cast(int)round((kp.y-half_size) / pix_dist);
    const y_end = cast(int)round((kp.y+half_size) / pix_dist);

    const cos_t = cos(theta), sin_t = sin(theta);
    const patch_sigma = lambda_desc * kp.sigma;
    //accumulate samples into histograms
    import std.range : iota;
    
    auto iterable = iota(x_start, x_end+1);

    void worker(int _m, int threadIndex) nothrow @nogc @fastmath 
    //for (int m = x_start; m <= x_end; m++) 
    {
        int m = iterable[_m];
        for (int n = y_start; n <= y_end; n++) {
            // find normalized coords w.r.t. kp position and reference orientation
            float x = ((m*pix_dist - kp.x)*cos_t+(n*pix_dist - kp.y)*sin_t) / kp.sigma;
            float y = (-(m*pix_dist - kp.x)*sin_t+(n*pix_dist - kp.y)*cos_t) / kp.sigma;

            // verify (x, y) is inside the description patch
            if (max(abs(x), abs(y)) > lambda_desc*(N_HIST+1.0f)/N_HIST)
                continue;

            float gx = img_grad.getPixel(n, m, 0), gy = img_grad.getPixel(n, m, 1);
            float theta_mn = fmod(atan2(gy, gx)-theta+4*M_PI, 2*M_PI);
            float grad_norm = sqrt(gx*gx + gy*gy);
            float weight = exp(-(pow(m*pix_dist-kp.x, 2)+pow(n*pix_dist-kp.y, 2))
                                    /(2*patch_sigma*patch_sigma));
            float contribution = weight * grad_norm;
            
            
            update_histograms(histograms, x, y, contribution, theta_mn, lambda_desc);
        }
    }
    pool.parallelFor(cast(int)iterable.length, &worker);

    // build feature vector (descriptor) from histograms
    hists_to_vec(histograms, kp.descriptor);
}

pure @fastmath
void hists_to_vec(ref Slice!(RCI!float, 3) histograms, ref ubyte[128] feature_vec)
{
    const size = N_HIST*N_HIST*N_ORI;
    auto hist = histograms.flattened;

    float norm = 0;
    for (int i = 0; i < size; i++) {
        norm += hist[i] * hist[i];
    }
    norm = sqrt(norm);
    float norm2 = 0;
    for (int i = 0; i < size; i++) {
        hist[i] = min(hist[i], 0.2f*norm);
        norm2 += hist[i] * hist[i];
    }
    norm2 = sqrt(norm2);
    for (int i = 0; i < size; i++) {
        float val = floor(512*hist[i]/norm2);
        feature_vec[i] = cast(ubyte)min(cast(ubyte)val, 255);
    }
}

@fastmath
void update_histograms(ref Slice!(RCI!float, 3) hist, float x, float y,
                       float contrib, float theta_mn, float lambda_desc)
{
    float x_i, y_j;
    for (int i = 1; i <= N_HIST; i++) {
        x_i = (i-(1+cast(float)N_HIST)/2) * 2*lambda_desc/N_HIST;
        if (abs(x_i-x) > 2*lambda_desc/N_HIST)
            continue;
        
        for (int j = 1; j <= N_HIST; j++) {
            y_j = (j-(1+cast(float)N_HIST)/2) * 2*lambda_desc/N_HIST;
            if (abs(y_j-y) > 2*lambda_desc/N_HIST)
                continue;
            
            float hist_weight = (1 - N_HIST*0.5/lambda_desc*abs(x_i-x))
                               *(1 - N_HIST*0.5/lambda_desc*abs(y_j-y));
            
            for (int k = 1; k <= N_ORI; k++) {
                float theta_k = 2*M_PI*(k-1)/N_ORI;
                float theta_diff = fmod(theta_k-theta_mn+2*M_PI, 2*M_PI);
                if (abs(theta_diff) >= 2*M_PI/N_ORI)
                    continue;
                float bin_weight = 1 - N_ORI*0.5/M_PI*abs(theta_diff);
                
                hist[i-1, j-1, k-1] += hist_weight*bin_weight*contrib;
                
            }   
        }
    }
}

@fastmath
Array!float find_keypoint_orientations(const ref SIFTKeypoint kp, const ref ScaleSpacePyramid grad_pyramid,
                                        float lambda_ori=LAMBDA_ORI, float lambda_desc=LAMBDA_DESC)
{
    float pix_dist = MIN_PIX_DIST * pow(2, kp.octave);
    const img_grad = grad_pyramid.octaves_grad[kp.octave][kp.scale];

    // discard kp if too close to image borders 
    float min_dist_from_border = min(kp.x, kp.y, pix_dist*img_grad.shape[1]-kp.x,
                                           pix_dist*img_grad.shape[0]-kp.y);
    if (min_dist_from_border <= /*sqrt(2.0f)*/ 1.41421f*lambda_desc*kp.sigma) {
        return Array!float();
    }
    
    float[N_BINS] hist; hist[] = 0.0f;
    int bin;
    float gx, gy, grad_norm, weight, theta;
    float patch_sigma = lambda_ori * kp.sigma;
    float patch_radius = 3 * patch_sigma;
    int x_start = cast(int)round((kp.x - patch_radius)/pix_dist);
    int x_end = cast(int)round((kp.x + patch_radius)/pix_dist);
    int y_start = cast(int)round((kp.y - patch_radius)/pix_dist);
    int y_end = cast(int)round((kp.y + patch_radius)/pix_dist);

    // accumulate gradients in orientation histogram
    for (int x = x_start; x <= x_end; x++) {
        for (int y = y_start; y <= y_end; y++) {
            gx = img_grad.getPixel(y, x, 0);
            gy = img_grad.getPixel(y, x, 1);
            grad_norm = sqrt(gx*gx + gy*gy);
            weight = exp(-(pow(x*pix_dist-kp.x, 2)+pow(y*pix_dist-kp.y, 2))
                              /(2*patch_sigma*patch_sigma));
            theta = fmod(atan2(gy, gx)+2*M_PI, 2*M_PI);
            bin = cast(int)round(cast(float)N_BINS/(2*M_PI)*theta) % N_BINS;
            hist[bin] += weight * grad_norm;
        }
    }
    
    smooth_histogram(hist);

    // extract reference orientations
    float ori_thresh = 0.8f, ori_max = 0.0f;
    Array!float orientations;
    for (int j = 0; j < N_BINS; j++) {
        if (hist[j] > ori_max) {
            ori_max = hist[j];
        }
    }
    for (int j = 0; j < N_BINS; j++) {
        if (hist[j] >= ori_thresh * ori_max) {
            float prev = hist[(j-1+N_BINS)%N_BINS], next = hist[(j+1)%N_BINS];
            if (prev > hist[j] || next > hist[j])
                continue;
            float _theta = 2*M_PI*(j+1)/N_BINS + M_PI/N_BINS*(prev-next)/(prev-2*hist[j]+next);
            orientations ~= _theta;
        }
    }
    return orientations.move;
}

// convolve 6x with box filter
pure @fastmath void smooth_histogram(ref float[N_BINS] hist)
{
    float[N_BINS] tmp_hist; tmp_hist[] = 0.0f;
    
    for (int i = 0; i < 6; i++) 
    {
        for (int j = 0; j < N_BINS; j++) 
        {
            int prev_idx = (j-1+N_BINS)%N_BINS;
            int next_idx = (j+1)%N_BINS;
            tmp_hist[j] = (hist[prev_idx] + hist[j] + hist[next_idx]) / 3.0f;
        }
        
        for (int j = 0; j < N_BINS; j++) {
            hist[j] = tmp_hist[j];
        }
    }
}

// calculate x and y derivatives for all images in the input pyramid
@fastmath
ScaleSpacePyramid generate_gradient_pyramid(const ref ScaleSpacePyramid pyramid)
{
    auto grad_pyramid = ScaleSpacePyramid(
        pyramid.num_octaves,
        pyramid.imgs_per_octave
    );
    grad_pyramid.octaves_grad.length = pyramid.num_octaves;

    for (int i = 0; i < pyramid.num_octaves; i++) {
        grad_pyramid.octaves_grad[i].length = grad_pyramid.imgs_per_octave;
        const int width = cast(int)pyramid.octaves[i][0].shape[1];
        const int height = cast(int)pyramid.octaves[i][0].shape[0];
        
        void worker(int j, int threadIndex) nothrow @nogc @fastmath 
        //for (int j = 0; j < pyramid.imgs_per_octave; j++) 
        {   
            auto grad = uninitRCslice!float(height, width, 2);
            float gx, gy;
            for (int x = 1; x < grad.shape[1]-1; x++) {
                for (int y = 1; y < grad.shape[0]-1; y++) {
                    gx = (pyramid.octaves[i][j].getPixel(y, x+1)
                         -pyramid.octaves[i][j].getPixel(y, x-1)) * 0.5f;
                    grad[y, x, 0] = gx;
                    gy = (pyramid.octaves[i][j].getPixel(y+1, x)
                         -pyramid.octaves[i][j].getPixel(y-1, x)) * 0.5f;
                    grad[y, x, 1] = gy;
                }
            }
            grad_pyramid.octaves_grad[i][j] = grad.move;
        }
        pool.parallelFor(cast(int)pyramid.imgs_per_octave, &worker);
    }
    return grad_pyramid.move;
}

pure @fastmath bool point_is_on_edge(SliceArray)(const ref SIFTKeypoint kp, const ref SliceArray octave, float edge_thresh=C_EDGE)
{
    const img = octave[kp.scale];
    float h11, h12, h22;
    int x = kp.i, y = kp.j;

    h11 = img.getPixel(y, x+1) + img.getPixel(y, x-1) - 2*img.getPixel(y, x);
    h22 = img.getPixel(y+1, x) + img.getPixel(y-1, x) - 2*img.getPixel(y, x);
    h12 = (img.getPixel(y+1, x+1) - img.getPixel(y-1, x+1) 
         - img.getPixel(y+1, x-1) + img.getPixel(y-1, x-1)) * 0.25f;


    float det_hessian = h11*h22 - h12*h12;
    float tr_hessian = h11 + h22;
    float edgeness = tr_hessian*tr_hessian / det_hessian;

    if (edgeness > pow(edge_thresh+1, 2)/edge_thresh)
        return true;
    else
        return false;
}

@fastmath auto gaussian_blur(InputSlice)(const ref InputSlice img, float sigma)
{
    int size = cast(int) ceil(6 * sigma);
    if (size % 2 == 0)
        size++;
    int center = size / 2;
    auto kernel = uninitRCslice!float(1, size);
    
    float sum = 0;
    foreach (k; -center .. center + 1)
    {
        float val = exp(-(k * k) / (2 * sigma * sigma));
        kernel[0, center + k] = val;
        sum += val;
    }
    
    kernel[] /= sum;

    auto tmp = uninitRCslice!float(img.shape);
    auto filtered = uninitRCslice!float(img.shape);

    // convolve vertical
    import std.range : iota;
    auto iterableLength0 = img.shape[1] ;

    void worker0(int x, int threadIndex) nothrow @nogc @fastmath 
    //for (int x = 0; x < img.shape[1]; x++) 
    {
        foreach_reverse (y; 0 .. img.shape[0])
        {
            float _sum = 0;
            foreach (k; 0 .. size)
            {
                int dy = -center + k;
                _sum += img.getPixel(y + dy, x) * kernel[0, k];
            }
            tmp[y, x] = _sum;
        }
    }
    pool.parallelFor(cast(int)iterableLength0, &worker0);
    // convolve horizontal
    auto iterableLength1 = img.shape[0] ;
    void worker1(int y, int threadIndex) nothrow @nogc @fastmath
    //for (int y = 0; y < img.shape[0]; y++) 
    {
        foreach (x; 0 .. img.shape[1])
        {
            float sum_ = 0;
            foreach (k; 0 .. size)
            {
                int dx = -center + k;
                sum_ += tmp.getPixel(y, x + dx) * kernel[0, k];
            }
            filtered[y, x] = sum_;
        }
    }
    pool.parallelFor(cast(int)iterableLength1, &worker1);
    
    return filtered;
}

// use this particular image resizing to obtain the same exact results as the reference implementation.

private:

enum Interpolation {
    BILINEAR,
    NEAREST
}

//map coordinate from 0-current_max range to 0-new_max range
pragma(inline, true)
pure @fastmath float map_coordinate(float new_max, float current_max, float coord)
{
    float a = new_max / current_max;
    float b = -0.5f + a*0.5f;
    return a*coord + b;
}

auto resize2(Interpolation method, S)(const ref S img, int new_h, int new_w)
{
    import std.range : iota;
    import dplug.core.sync;

    auto resized = uninitRCslice!float(new_h, new_w);

    void worker(int x, int threadIndex) nothrow @nogc
    //for (int x = 0; x < new_w; x++) 
    {
        for (int y = 0; y < new_h; y++) {
            float old_x = map_coordinate(img.shape[1], new_w, x);
            float old_y = map_coordinate(img.shape[0], new_h, y);

            static if (method == Interpolation.BILINEAR)
                float value = bilinear_interpolate(img, old_x, old_y);
            else static if (method == Interpolation.NEAREST)
                float value = nn_interpolate(img, old_x, old_y);
            else
                static assert(false, "Please provide a supported interpolation method as template argument.");
            resized[y, x] = value;
        }
    }
    pool.parallelFor(new_w, &worker);
    return resized;
}

pure @fastmath float bilinear_interpolate(S)(const ref S img, float x, float y)
{
    import mir.math.common : floor;
    float p1, p2, p3, p4, q1, q2;
    float x_floor = floor(x), y_floor = floor(y);
    float x_ceil = x_floor + 1, y_ceil = y_floor + 1;
    p1 = img.getPixel(cast(int)y_floor, cast(int)x_floor);
    p2 = img.getPixel(cast(int)y_floor, cast(int)x_ceil);
    p3 = img.getPixel(cast(int)y_ceil, cast(int)x_floor);
    p4 = img.getPixel(cast(int)y_ceil, cast(int)x_ceil);
    q1 = (y_ceil-y)*p1 + (y-y_floor)*p3;
    q2 = (y_ceil-y)*p2 + (y-y_floor)*p4;
    return (x_ceil-x)*q1 + (x-x_floor)*q2;
}

pure @fastmath float nn_interpolate(S)(const ref S img, float x, float y)
{
    import mir.math.common : round;
    return img.getPixel(cast(int)round(y), cast(int)round(x));
}

// easy and safe way for boundary conditions
pragma(inline, true)
float getPixel(S, I)(const ref S s, I row, I col, I ch = 0){
    auto yy = row;
    auto xx = col;
    if (xx < 0)
        xx = 0;
    if (xx >= s.shape[1])
        xx = cast(int)s.shape[1] - 1;
    if (yy < 0)
        yy = 0;
    if (yy >= s.shape[0])
        yy = cast(int)s.shape[0] - 1;

    static if (s.N==2){
        return s[yy, xx];
    }else{
        return s[yy, xx, ch];
    }
}