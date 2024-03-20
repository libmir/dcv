module dcv.example.video;

/** 
 * Video streaming example using dcv library.
 */

import core.stdc.stdio;
import core.stdc.stdlib;

import std.datetime.stopwatch : StopWatch;

import dcv.videoio;
import dcv.imgproc.color;
import dcv.core;
import dcv.plot;

import mir.ndslice;

// video -l "video=Lenovo EasyCamera"
// video -f ../data/centaur_1.mpg

@nogc nothrow:

ulong frameCount = 0;
double elapsedTime = 0.0;
double realTimeFPS = 0.0;

TtfFont font;

void main(string[] args)
{
    if (args.length < 2 || (args.length == 2 && args[1] == "-h"))
    {
        printHelp();
        return;
    }

    font = TtfFont(cast(ubyte[])import("Nunito-Regular.ttf"));
    //////////// Open the video stream ////////////////

    InputStream inStream = mallocNew!InputStream(false); // set forceRGB false to make RGB conversion using dcv
    scope(exit) destroyFree(inStream);

    string path; // path to the video
    InputStreamType type; // type of the stream (file or live)

    if (!parseArgs(args, path, type))
    {
        printf("Error occurred while parsing arguments.\n\n");
        printHelp();
        return;
    }
    enum W = 640;
    enum H = 480;
    inStream.setVideoSizeRequest(W, H);
    // inStream.setFPSRequest(60); // you can set a FPS value supported by your device

    // Open the example video
    inStream.open(path, type);

    // Check if video has been opened correctly
    if (!inStream.isOpen)
    {
        printf("Cannot open input video stream");
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

    auto fig = imshow(rcslice!ubyte(H, W, 3), path);

    // Read each next frame of the video in the loop.
    while (inStream.readFrame(frame))
    {
        import std.algorithm.comparison : max;

        // If video frame pixel format is YUV, convert the data to RGB, then show it on screen
        if (frame.format == ImageFormat.IF_YUV){
            auto toShow = frame.sliced.yuv2rgb!ubyte;
            fig.draw(toShow, ImageFormat.IF_RGB);
        }else{
            fig.draw(frame); // it never comes here since forceRGB is false in InputStream(false)
        }

        destroyFree(frame);
        frame = null;
        // Compensate fps wait for lost time on color conversion.
        int wait = max(1, cast(int)waitFrame - cast(int)s.peek.total!"msecs");
        
        // If user presses escape key, stop the streaming.
        if (waitKey(wait) == KEY_ESCAPE)
            break;

        drawFPS(fig, s);
        s.reset;
        /*
        Ask if figure with given name is visible.

        Normally, you can close the figure window by pressing the 'x' button.
        That way, figure closes, and visible property will return false.
        So, if user presses the 'x' button, normal behavior would be to break the 
        streaming loop.
        */
        if (!fig.visible)
            break;
    }
    destroyFigures(); // destroy all figures allocated
}

void drawFPS(Figure fig, ref StopWatch s){
    frameCount++;
    elapsedTime += s.peek.total!"msecs";

    // Calculate FPS if elapsed time is non-zero
    if (elapsedTime > 0)
    {
        realTimeFPS = cast(double)frameCount / (elapsedTime / 1000.0); // Convert milliseconds to seconds
    }
    
    import core.stdc.stdio;
    char[32] buff;
    snprintf(buff.ptr, buff.length, "FPS: %.2f", realTimeFPS);

    fig.drawText(font, buff[], PlotPoint(20.0f, 20.0f),
                0.0f, 30, plotGreen);
    
    if (elapsedTime > 1.0) {
        frameCount = 0;
        elapsedTime = 0.0;
    }
}

void printHelp()
{
    printf(`
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
        printf("Invalid input type argument: ", args[2].ptr);
        exit(-1);
    }

    path = args[2];

    return true;
}

/+ alternative approach using ffmpeg executable. Neither videoio nor ffmpeg static linking is required.

import std.stdio;
import std.process;

import dcv.imgproc.color;
import dcv.core;
import dcv.plot.figure;

import mir.ndslice;

// compile release for speed: dub -b release
// Video resolution
enum W = 640;
enum H = 480;

void main()
{
    // for video file as input
    /*auto pipes = pipeProcess(["ffmpeg", "-i", "file_example_MP4_640_3MG.mp4", "-f", "image2pipe",
     "-vcodec", "rawvideo", "-pix_fmt", "rgb24", "-"], // yuv420p
        Redirect.stdout);*/
    // for camera device as input
    auto pipes = pipeProcess(["ffmpeg", "-y", "-f", "dshow", "-video_size", "640x480", "-i",
        `video=Lenovo EasyCamera`, "-framerate", "30", "-f", "image2pipe", "-vcodec", "rawvideo", 
        "-pix_fmt", "rgb24", "-"], Redirect.stdout);
    
    // scope(exit) wait(pipes.pid);
     
    // Process video frames
    auto frame = slice!ubyte([H, W, 3], 0);

    while(1)
    {
        
        // Read a frame from the input pipe into the buffer
        ubyte[] dt = pipes.stdout.rawRead(frame.ptr[0..H*W*3]);
        // If we didn't get a frame of video, we're probably at the end
        if (dt.length != H*W*3) break;
        
        // do image processing here
        
        imshow(frame, "video");
        waitKey(2);

        if (!figure("video").visible)
            break;
    }
    
    
}
+/
