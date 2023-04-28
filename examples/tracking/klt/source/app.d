module dcv.example.opticalflow;

/** 
 * Kanade-Lucas-Tomasi tracking example, in dcv.
 */

import std.stdio;
import std.conv : to;
import std.algorithm : copy, map, each, min;
import std.range : lockstep, repeat;
import std.array : staticArray;
import mir.ndslice;
import mir.rc;
import mir.appender;

import dcv.core;
import dcv.imageio;
import dcv.imgproc.filter : filterNonMaximum;
import dcv.imgproc.color : gray2rgb;
import dcv.features.corner.harris : shiTomasiCorners;
import dcv.features.utils : extractCorners;
import dcv.tracking.opticalflow : LucasKanadeFlow, SparsePyramidFlow;
import dcv.plot;

import std.process;

void printHelp()
{
    writeln(`
DCV Lucas-Kanade Sparse Optical Flow Example.

Run example program without arguments. This mode configures the flow algorithm by 
using default parameter set, and for video the dcv/examples/data/centaur_1.mpg file is loaded.

If multiple parameters are given, then parameters are considered to be:

1 - video stream mode (-f for file, -l for webcam or live mode);
2 - video stream name (for file mode it is the path to the file, for webcam it is the name of the stream, e.g. /dev/video0);
3 - tracking kernel width (default 15);
4 - number of corners to be detected and tracked (default 20);
5 - number of frames through which features will be tracked (default 100);
6 - number of pyramid levels through which the flow algorithm will be evaluated (default 3);
7 - number of iterations for each flow evaluation (default 10);
8 - minimal eigenvalue of the corner response during the tracking - if the corner eigenvalue is smaller than given after the tracking, 
    the feature is no longer considered to be valid, and is discarded from further tracking.

Example:
./klt -f ../../data/centaur_1.mpg 19 10 100 3 30 1000.0`);
}
enum H = 240;
enum W = 320;

// @nogc nothrow: // only pipeProcess allocates with GC

int main(string[] args)
{
    auto pipes = pipeProcess(["ffmpeg", "-i", "../../data/centaur_1.mpg", "-f", "image2pipe",
        "-vcodec", "rawvideo", "-pix_fmt", "rgb24", "-"],
        Redirect.stdout);

    Slice!(RCI!float, 2) prevFrame, thisFrame; // image frames, for tracking

    auto cornerW = 15.0f; // size of the tracking kernel
    auto cornerCount = 20; // numer of corners tracked
    auto frames = 100; // maximum frame count to be tracked
    auto pyrLevels = 3; // number of levels in the optical flow pyramid
    auto iterCount = 10; // number of levels in the optical flow pyramid
    auto eigLim = 1000.0f; // corner eigenvalue limit, after which the feature is invalid.

    // initialize and setup the optical flow algorithm
    LucasKanadeFlow lkFlow = mallocNew!LucasKanadeFlow;
    SparsePyramidFlow spFlow = mallocNew!SparsePyramidFlow(lkFlow, pyrLevels);
    scope(exit){
        destroyFree(lkFlow);
        destroyFree(spFlow);
    }
    lkFlow.sigma = 0.80f;
    lkFlow.iterationCount = iterCount;

    auto corners = scopedBuffer!(float[2]);
    float[2][] reg = mallocSlice!(float[2])(cornerCount);
    scope(exit) freeSlice(reg);
    reg[] = [cornerW, cornerW].staticArray;

    auto buffSlice = rcslice!ubyte([H, W, 3], 0);
    auto figureKLT = imshow(buffSlice, "KLT");

    // read first frame and use it to detect initial corners for tracking
    const ubyte[] _dt = pipes.stdout.rawRead(buffSlice.ptr[0..H*W*3]);

    // take the r channel and form an image
    prevFrame = buffSlice[0..$, 0..$, 0].as!float.rcslice;

    auto h = prevFrame.shape[0];
    auto w = prevFrame.shape[1];
    auto frame = 0; // frame counter

    while (1)
    {
        auto thisSlice = uninitRCslice!ubyte(h, w, 3);
        const ubyte[] dt = pipes.stdout.rawRead(thisSlice.ptr[0..h*w*3]);
        
        printf("Tracking frame no. %d...\n", frame);

        // take the y channel, and form an image of it.
        thisFrame = thisSlice[0 .. $, 0 .. $, 0].as!float.rcslice;

        // if corner count has dropped below 50% of original count, try to detect new points.
        if (corners.length < (cornerCount / 2))
        {
            printf("Search features again...\n");
            
            auto c = shiTomasiCorners(prevFrame.lightScope, cast(uint)cornerW)
                .filterNonMaximum.lightScope.extractCorners(cornerCount);

            foreach (v; c)
                corners.put([cast(float)v[0], cast(float)v[1]].staticArray);
        }

        // evaluate the optical flow
        auto flow = spFlow.evaluate(prevFrame.lightScope, thisFrame.lightScope, corners.data, reg);
        
        // discard faulty tracked corners
        float[2][] fback = mallocSlice!(float[2])(corners.length);
        scope(exit) freeSlice(fback);
        fback[] = corners.data;
        corners.reset;
        foreach (id, e; lkFlow.cornerResponse)
        {
            import std.math : isNaN;
            
            if (!isNaN(e) && e > eigLim)
            {
                corners.put(fback[id]);
            }
            else
            {
                printf("Removing corner no. %zu with score: %f\n", id, e);
            }
        }
        
        // Displace previous corner coordinates with newly estimated flow vectors
        // nogc lockStep workaround
        auto A = corners.data.sliced;
        alias B = flow;

        alias ItZ = ZipIterator!(typeof(A._iterator), typeof(B._iterator));
        auto zipp = ItZ(A._iterator, B._iterator);
        auto mlen = min(A.length, B.length);
        
        foreach(_; 0..mlen)
        {
            (*zipp).a[0] = (*zipp).a[0] + (*zipp).b[1];
            (*zipp).a[1] = (*zipp).a[1] + (*zipp).b[0];
            ++zipp;
        }

        // draw tracked corners and write the image
        auto f2c = thisFrame.lightScope.gray2rgb;

        // plot tracked points on screen.
        figureKLT.draw(f2c, ImageFormat.IF_RGB);
        if(corners.data.length)
            figureKLT.plotPoints(corners.data);

        if (waitKey(10) == KEY_ESCAPE)
            break;

        if (++frame >= frames)
            break;

        // take this frame as next one's previous
        prevFrame = thisFrame;

        if (!figureKLT.visible)
            break;
    }

    destroyFigures();
    return 0;
}

void plotPoints(Figure handle, float[2][] corners){
    import std.algorithm.iteration : map;

    auto xs = corners.map!(v => v[1]);
    auto ys = corners.map!(v => v[0]);

    foreach(i; 0..xs.length){
        handle.drawCircle(PlotCircle(xs[i], ys[i], 5.0f), plotRed);
    }
}
