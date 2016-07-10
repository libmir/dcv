# Video Reading Example


This example should demonstrate how to read video streams using dcv library.


## Modules used
* dcv.core;
* dcv.imgproc.color;
* dcv.io;
* dcv.plot.figure;

## Disclaimer

Video streaming utilities are still heavily a wip. This is merely a preview of what 
these utilities should look like.

### InputStream usage

Input video streaming utility is located in the dcv.io.video.input module, defined as 
InputStream class. In the demo application, we open the input video stream, read the 
video frame by frame, and show its content on the screen.

The demo application takes two arguments to run - type of the input stream, and path to it. Type
can be:

* File (*-f*), for video file on the filesystem.
* Live (*-l*), for live stream (e.g. open and stream web camera feed)

As for the path, when file type is chosen, it is the path to the video file, and for the live type it is the path of the 
webcam (its tested only on linux, where this path is the video4linux device, e.g. */dev/video0*).

In the following lines, we create the `InputStream` instance, and try to open the stream at given path.

```d
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
catch
{
    writeln("Cannot open input video stream");
    exit(-1);
}

// Check if video has been opened correctly
if (!inStream.isOpen)
{
    writeln("Cannot open input video stream");
    exit(-1);
}
```

After successfully opening the video stream, frames can be read with the following loop setup:

```d
Image frame; // frame image buffer, where each next frame of the video is stored.

// read the frame rate, if info is available.
double fps = inStream.frameRate ? inStream.frameRate : 30.0;
// calculate frame wait time in miliseconds - if video is live, set to minimal value.
double waitFrame = (type == InputStreamType.LIVE) ? 1.0 : 1000.0 / fps;

// Read each next frame of the video in the loop.
while (inStream.readFrame(frame))
{
    // Show the image in the screen.
    frame.imshow(path);

    // If user presses escape key, stop the streaming.
    if (waitKey(waitFrame) == KEY_ESCAPE)
        break;
}
```

Some details of implementation have been removed from the example code snippets, for the simplicity's sake. For complete
code, please take a look in the dcv/examples/video/source/app.d file.

### More examples

For more extensive example, please take a look into a unit test in the dcv.io.video module (source/dcv/io/video.package.d file). This is actually a functional test proving the video streaming utilities work as expected. Please keep in mind that these modules are not done yet, and will surely change in future.





