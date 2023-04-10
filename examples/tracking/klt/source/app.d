module dcv.example.opticalflow;

/** 
 * Kanade-Lucas-Tomasi tracking example, in dcv.
 */

import std.stdio;
import std.conv : to;
import std.algorithm : copy, map, each;
import std.range : lockstep, repeat;
import std.array : staticArray;
import mir.ndslice;
import mir.appender;

import dcv.core;
import dcv.imageio;
import dcv.videoio;
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

int main(string[] args)
{
    auto pipes = pipeProcess(["ffmpeg", "-i", "../../data/centaur_1.mpg", "-f", "image2pipe",
        "-vcodec", "rawvideo", "-pix_fmt", "rgb24", "-"],
        Redirect.stdout);

    Image prevFrame, thisFrame; // image frames, for tracking

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
    prevFrame = buffSlice.asImage(ImageFormat.IF_RGB);
    
    // take the r channel and form an image
    auto _prevFrame = prevFrame.sliced[0 .. $, 0 .. $, 0].asImage(ImageFormat.IF_MONO);
    destroyFree(prevFrame); prevFrame = null;

    auto h = _prevFrame.height;
    auto w = _prevFrame.width;
    auto frame = 0; // frame counter

    while (1)
    {
        auto thisSlice = uninitRCslice!ubyte(h, w, 3);
        const ubyte[] dt = pipes.stdout.rawRead(thisSlice.ptr[0..h*w*3]);
        
        writeln("Tracking frame no. " ~ frame.to!string ~ "...");

        // take the y channel, and form an image of it.
        thisFrame = thisSlice[0 .. $, 0 .. $, 0].asImage(ImageFormat.IF_MONO);

        // if corner count has dropped below 50% of original count, try to detect new points.
        if (corners.length < (cornerCount / 2))
        {
            writeln("Search features again...");
            int err;
            auto c = shiTomasiCorners(_prevFrame.sliced.reshape([h, w], err).as!float.rcslice.lightScope, cast(uint)cornerW)
                .filterNonMaximum.lightScope.extractCorners(cornerCount);
            
            assert(err == 0);

            foreach (v; c)
                corners.put([cast(float)v[0], cast(float)v[1]].staticArray);
        }

        // evaluate the optical flow
        auto flow = spFlow.evaluate(_prevFrame, thisFrame, corners.data, reg);
        
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
                writeln("Removing corner no. ", id, " with score: ", e);
            }
        }
        
        // Displace previous corner coordinates with newly estimated flow vectors
        foreach (ref c, f; lockstep(corners.data, flow))
        {
            c[0] = c[0] + f[1];
            c[1] = c[1] + f[0];
        }

        // draw tracked corners and write the image
        int err;
        auto f2c = thisFrame.sliced.reshape([h, w], err).gray2rgb;
        assert(err == 0);

        // plot tracked points on screen.
        figureKLT.draw(f2c, ImageFormat.IF_RGB);
        if(corners.data.length)
            figureKLT.plotPoints(corners.data);

        if (waitKey(10) == KEY_ESCAPE)
            break;

        if (++frame >= frames)
            break;

        // take this frame as next one's previous
        destroyFree(_prevFrame);
        _prevFrame = thisFrame;

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
