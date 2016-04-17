# Video Reading Example


This example should demonstrate how read video files using dcv library.


## Modules used
* dcv.core;
* dcv.imgproc.color;
* dcv.io;


## Disclaimer
Video streaming utilities are still heavily a wip. This is merely a preview of what I think these utilities should look like. I've stopped working on these modules for now, and will continue in time. If anyone has a suggestion how we could make these utilities more effective, you're more than welcome to help me!


## Demo Application

In this example, video streaming is demonstrated using the demo application, built using GtkD GUI toolkit. Here is a screen Grab of the Demo Video Player running on my system:

![alt tag](https://github.com/ljubobratovicrelja/dcv/blob/master/examples/video/result/screengrab_1.png)


### InputStream usage

Input video streaming utility is located in the dcv.io.video.input module, defined as InputStream class. In the demo application, we've defined a custom gtk.DrawingArea, which is used as a video (frame) canvas. Note that this implementation is simplified for the demonstration purpose - the stream is allocated and opened in our frame canvas. Also, the queue timer for the next frame draw is also installed here. The video stream is opened in the Canvas constructor:

```d
this(in string videoFile) {
	stream = new InputStream; // initialize the stream
	stream.open(videoFile, InputStreamType.FILE); // open the file with given path.

	if (!stream.isOpen) {
		exit(-1);
	}
	// ...
}
```

The ```VideoStreamCanvas.redraw``` method will try to grab next frame of the video, and show it on the canvas. The frame grabbing part is defined in the first part of the method:

```d
// Reading frame image.
Image image = null; 

// Create timer, if not already been created. It'll repeat the frame reading operation in correct time.
if ( timeout is null ) {
	timeout = new Timeout( 1000 / cast(int)(stream.frameRate ? stream.frameRate : 25), &queueNextFrame, false );
}

// Read the frame - exit if theres no more frames.
if (!stream.readFrame(image) || image is null) {
	exit(0);
} 
```

### More examples

For more extensive example, please take a look into a unit test in the dcv.io.video module (source/dcv/io/video.package.d file). This is actually a functional test proving the video streaming utilities work as expected. Please keep in mind that these modules are not done yet, and will surely change in future.





