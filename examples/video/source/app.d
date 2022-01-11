module dcv.example.video;

/** 
 * Video streaming example using dcv library.
 */

import std.stdio;
import std.datetime.stopwatch : StopWatch;
import core.stdc.stdlib;

import dcv.io.image;
import dcv.imgproc.color;
import dcv.core.utils;
import dcv.io.video;
import dcv.plot.figure;

// executable -l "video=Lenovo EasyCamera"
// executable -f ../data/centaur_1.mpg

void main(string[] args)
{
    if (args.length == 2 && args[1] == "-h")
    {
        printHelp();
        return;
    }

    //////////// Open the video stream ////////////////

    InputStream inStream = new InputStream;

    string path; // path to the video
    InputStreamType type; // type of the stream (file or live)

    if (!parseArgs(args, path, type))
    {
        writeln("Error occurred while parsing arguments.\n\n");
        printHelp();
        return;
    }

    try
    {
        // Open the example video
        inStream.open(path, type);
    }
    catch(Exception e)
    {
        writeln("Cannot open input video stream: " ~ e.message);
        exit(-1);
    }

    // Check if video has been opened correctly
    if (!inStream.isOpen)
    {
        writeln("Cannot open input video stream");
        exit(-1);
    }

    //////////// Read video frames //////////////////

    Image frame; // frame image buffer, where each next frame of the video is stored.

    // read the frame rate, if info is available.
    double fps = inStream.frameRate ? inStream.frameRate : 30.0;
    // calculate frame wait time in miliseconds - if video is live, set to minimal value.
    double waitFrame = (type == InputStreamType.LIVE) ? 1.0 : 1000.0 / fps;

    StopWatch s;
    s.start;

    // Read each next frame of the video in the loop.
    while (inStream.readFrame(frame))
    {
        import std.algorithm.comparison : max;

        s.reset;

        // If video frame pixel format is YUV, convert the data to RGB, then show it on screen
        if (frame.format == ImageFormat.IF_YUV)
            frame.sliced.yuv2rgb!ubyte.imshow(path);
        else
            frame.imshow(path);

        // Compensate fps wait for lost time on color conversion.
        int wait = max(1, cast(int)waitFrame - cast(int)s.peek.total!"msecs");

        // If user presses escape key, stop the streaming.
        if (waitKey(wait) == KEY_ESCAPE)
            break;

        /*
        Ask if figure with given name is visible.

        Normally, you can close the figure window by pressing the 'x' button.
        That way, figure closes, and visible property will return false.
        So, if user presses the 'x' button, normal behavior would be to break the 
        streaming loop.
        */
        if (!figure(path).visible)
            break;
    }

}

void printHelp()
{
    writeln(`
DCV Video Streaming Example.

Run example program without arguments, to load and show the example video file centaur_1.mpg.

If multiple parameters are given, then parameters are considered to be:

1 - video stream mode (-f for file, -l for webcam or live mode);
2 - video stream name (for file mode it is the path to the file, for webcam it is the name of the stream, e.g. /dev/video0);

Examples:
./video -l /dev/video0
./video -f ../data/centaur_1.mpg

Tip:
To run the example program in best performance, compile with one of the following configurations
dub build --compiler=ldc2 --build=release
dub build --compiler=dmd --build=release-nobounds
`);
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
        writeln("Invalid input type argument: ", args[2]);
        exit(-1);
    }

    path = args[2];

    return true;
}
