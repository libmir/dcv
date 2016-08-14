module dcv.example.opticalflow;

/** 
 * Kanade-Lucas-Tomasi tracking example, in dcv.
 */

import std.stdio;
import std.conv : to;
import std.algorithm : copy, map, each;
import std.range : lockstep, repeat;
import std.array : array;
import std.experimental.ndslice;

import dcv.core;
import dcv.io;
import dcv.imgproc.filter : filterNonMaximum;
import dcv.imgproc.color : gray2rgb;
import dcv.features.corner.harris : shiTomasiCorners;
import dcv.features.utils : extractCorners;
import dcv.tracking.opticalflow : LucasKanadeFlow, SparsePyramidFlow;
import dcv.plot.figure;

import ggplotd.aes;
import ggplotd.geom;
import ggplotd.ggplotd;


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

int main(string[] args)
{
    if (args.length == 2 && args[1] == "-h")
    {
        printHelp();
        return 0;
    }

    // open video stream
    InputStream stream = new InputStream;

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
            writeln("Invalid argument setup - at least video format and stream name is needed."
                    ~ "\nCall program with -h to show detailed info.");
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
            writeln("Invalid video stream type: use -f for file and -l for webcam live stream");
            return 1;
        }

        streamName = args[2];
    }

    stream.open(streamName, streamType);

    if (!stream.isOpen)
    {
        writeln("Cannot open stream named: ", streamName, ", typed as: ", streamType);
        return 1;
    }

    Image prevFrame, thisFrame; // image frames, for tracking

    auto cornerW = args.length >= 4 ? args[3].to!float : 15.0f; // size of the tracking kernel
    auto cornerCount = args.length >= 5 ? args[4].to!uint : 20; // numer of corners tracked
    auto frames = args.length >= 6 ? args[5].to!uint : 100; // maximum frame count to be tracked
    auto pyrLevels = args.length >= 7 ? args[6].to!uint : 3; // number of levels in the optical flow pyramid
    auto iterCount = args.length >= 8 ? args[7].to!uint : 10; // number of levels in the optical flow pyramid
    auto eigLim = args.length >= 9 ? args[8].to!float : 1000.0f; // corner eigenvalue limit, after which the feature is invalid.

    auto frame = 0; // frame counter

    // initialize and setup the optical flow algorithm
    LucasKanadeFlow lkFlow = new LucasKanadeFlow;
    SparsePyramidFlow spFlow = new SparsePyramidFlow(lkFlow, pyrLevels);

    lkFlow.sigma = 0.80f;
    lkFlow.iterationCount = iterCount;

    // read first frame and use it to detect initial corners for tracking
    stream.readFrame(prevFrame);

    // take the y channel and form an image
    prevFrame = prevFrame.sliced[0 .. $, 0 .. $, 0].asImage(ImageFormat.IF_MONO);

    auto h = prevFrame.height;
    auto w = prevFrame.width;

    // detect corners to track
    writeln("Search features...");
    auto f1f = prevFrame.sliced.reshape(h, w).asType!float;
    auto corners = f1f.shiTomasiCorners(cast(uint)cornerW)
        .filterNonMaximum.extractCorners(cornerCount).map!(v => cast(float[2])[cast(float)v[0], cast(float)v[1]]).array;

    auto reg = new float[2][corners.length].map!(v => cast(float[2])[cornerW, cornerW]).array;

    while (stream.readFrame(thisFrame))
    {
        writeln("Tracking frame no. " ~ frame.to!string ~ "...");

        // take the y channel, and form an image of it.
        thisFrame = thisFrame.sliced[0 .. $, 0 .. $, 0].asImage(ImageFormat.IF_MONO);

        // if corner count has dropped below 50% of original count, try to detect new points.
        if (corners.length < (cornerCount / 2))
        {
            writeln("Search features again...");
            auto c = shiTomasiCorners(prevFrame.sliced.reshape(h, w).asType!float, cast(uint)cornerW)
                .filterNonMaximum.extractCorners(cornerCount);

            foreach (v; c)
                corners ~= [cast(float)v[0], cast(float)v[1]];
        }

        // evaluate the optical flow
        auto flow = spFlow.evaluate(prevFrame, thisFrame, corners, reg);

        // discard faulty tracked corners
        auto fback = corners;
        corners.length = 0;
        foreach (id, e; lkFlow.cornerResponse)
        {
            import std.math : isNaN;
            import std.algorithm : remove;

            if (!isNaN(e) && e > eigLim)
            {
                corners ~= fback[id];
            }
            else
            {
                writeln("Removing corner no. ", id, " with score: ", e);
            }
        }

        foreach (ref c, f; lockstep(corners, flow))
        {
            c[0] = c[0] + f[1];
            c[1] = c[1] + f[0];
        }

        // draw tracked corners and write the image
        auto f2c = thisFrame.sliced.reshape(h, w).gray2rgb.asType!float;

        // plot tracked points on screen.
        f2c.plot(plotPoints(corners), "KLT");

        if (waitKey(10) == KEY_ESCAPE)
            break;

        if (++frame >= frames)
            break;

        // take this frame as next one's previous
        prevFrame = thisFrame;

        if (!figure("KLT").visible)
            break;
    }

    return 0;
}

GGPlotD plotPoints(float[2][] corners)
{
    auto xs = corners.map!(v => v[1]);
    auto ys = corners.map!(v => v[0]);

    return GGPlotD().put(geomPoint(Aes!(typeof(xs), "x", typeof(ys), "y", bool[], "fill", string[], "colour")
            (xs, ys, false.repeat(xs.length).array, "red".repeat(xs.length).array)));
}
