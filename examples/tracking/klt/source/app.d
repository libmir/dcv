module dcv.example.opticalflow;

/** 
 * Kanade-Lucas-Tomasi tracking example, in dcv.
 */

import core.stdc.stdio;
import core.stdc.stdlib : exit, atof, atoi;

import std.algorithm : min;
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
import dcv.videoio;

import dplug.core : CString;

@nogc nothrow:

void printHelp()
{
    printf(`
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

int main(string[] args)
{
    InputStream inStream = mallocNew!InputStream;
    scope(exit) destroyFree(inStream);

    InputStreamType streamType;
    string streamName;

    if (args.length == 1)
    {
        streamName = "../../data/centaur_1.mpg";
        streamType = InputStreamType.FILE;
    }
    else
    {
        if (args.length < 3)
        {
            printf("Invalid argument setup - at least video format and stream name is needed.\n
                   Call program with -h to show detailed info.");
            return 1;
        }

        switch (args[1])
        {
        case "-f":
            streamType = InputStreamType.FILE;
            break;
        case "-l":
            streamType = InputStreamType.LIVE;
            break;
        default:
            printf("Invalid video stream type: use -f for file and -l for webcam live stream\n");
            return 1;
        }

        streamName = args[2];
    }

    if(streamType == InputStreamType.LIVE)
        inStream.setVideoSizeRequest(640, 480);

    inStream.open(streamName, streamType);

    // Check if video has been opened correctly
    if (!inStream.isOpen)
    {
        printf("Cannot open input video stream");
        exit(-1);
    }

    auto cornerW = args.length >= 4 ? cast(float)args[3].CString.atof : 15.0f; // size of the tracking kernel
    auto cornerCount = args.length >= 5 ? args[4].CString.atoi : 20; // numer of corners tracked
    auto frames = args.length >= 6 ? args[5].CString.atoi : 100; // maximum frame count to be tracked
    auto pyrLevels = args.length >= 7 ? args[6].CString.atoi : 3; // number of levels in the optical flow pyramid
    auto iterCount = args.length >= 8 ? args[7].CString.atoi : 10; // number of levels in the optical flow pyramid
    auto eigLim = args.length >= 9 ? cast(float)args[8].CString.atof : 1000.0f; // corner eigenvalue limit, after which the feature is invalid.

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

    Image aframe;
    // read first frame and use it to detect initial corners for tracking
    inStream.readFrame(aframe);

    Slice!(RCI!float, 2) prevFrame, thisFrame; // image frames, for tracking

    // take the r channel and form an image
    prevFrame = aframe.sliced[0..$, 0..$, 0].as!float.rcslice;

    auto h = aframe.height;
    auto w = aframe.width;

    auto buffSlice = rcslice!ubyte([h, w, 3], 0);
    auto figureKLT = imshow(buffSlice, "KLT");

    destroyFree(aframe);
    aframe = null;

    auto frame = 0; // frame counter

    while (inStream.readFrame(aframe))
    {   
        debug printf("Tracking frame no. %d...\n", frame);

        // take the y channel, and form an image of it.
        thisFrame = aframe.sliced[0 .. $, 0 .. $, 0].as!float.rcslice;

        // if corner count has dropped below 50% of original count, try to detect new points.
        if (corners.length < (cornerCount / 2))
        {
            debug printf("Search features again...\n");
            
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
                debug printf("Removing corner no. %zu with score: %f\n", id, e);
            }
        }
        
        // Displace previous corner coordinates with newly estimated flow vectors
        // with nogc lockStep 
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

        // plot tracked points on screen.
        figureKLT.draw(aframe);
        if(corners.data.length)
            figureKLT.plotPoints(corners.data);

        // take this frame as next one's previous
        prevFrame = thisFrame;
        
        scope(exit){
            destroyFree(aframe);
            aframe = null;
        }

        if (waitKey(10) == KEY_ESCAPE)
            break;

        if(++frame >= frames && streamType == InputStreamType.FILE)
            break;
        
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

bool parseArgs(in string[] args, out string path, out InputStreamType type)
{
    if (args.length == 1)
        return true;
    else if (args.length != 3)
        return false;

    type = InputStreamType.FILE;

    switch (args[1])
    {
    case "-file":
    case "-f":
        type = InputStreamType.FILE;
        break;
    case "-live":
    case "-l":
        type = InputStreamType.LIVE;
        break;
    default:
        printf("Invalid input type argument: ", args[2].ptr);
        exit(-1);
    }

    path = args[2];

    return true;
}