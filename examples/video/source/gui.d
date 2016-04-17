module dcv.example.video.gui;


import std.stdio;
import std.c.stdlib : exit;

import gtk.Widget;
import gtk.DrawingArea;
import gtk.MainWindow;

import gdk.Event;

import glib.Timeout;

import cairo.ImageSurface;
import cairo.Context;

import dcv.io.image;
import dcv.imgproc.color;
import dcv.core.utils;
import dcv.io.video;


/**
 * Video stream canvas.
 * 
 * Most basic implementation which demonstrates
 * how to open the video stream from video, grab it's frames
 * and show them on the screen using GtkD GUI library.
 */
class VideoStreamCanvas : DrawingArea {


	private InputStream stream = null; // video stream object.
	private Timeout timeout = null; // timeout used to queue next frame grab


	this(in string videoFile) {
		stream = new InputStream; // initialize the stream
		stream.open(videoFile, InputStreamType.FILE); // open the file with given path.

		if (!stream.isOpen) {
			exit(-1);
		}

		addOnDraw(&redraw);
	}

	bool redraw(Scoped!Context cr, Widget widget) {

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

		// If the video is yuv, as the example video actually is, convert it to rgb.

		if (image.format == ImageFormat.IF_YUV) {
			auto rgb = image.sliced.yuv2rgb;
			image = rgb.asImage(ImageFormat.IF_RGB);
		}

		// Create ImageSurface object from the frame data

		int w = cast(int)image.width;
		int h = cast(int)image.height;
		int r = w*3;

		auto imsurface = ImageSurface.create(CairoFormat.RGB24, w, h);
		auto imsurfaceData = imsurface.getData();
		auto imdata = image.data;
		int rowStride = w*4;

		foreach(row; 0..h) {
			foreach(col; 0..w) {
				foreach(channel; 0..3) {
					imsurfaceData[row*rowStride + col*4 + channel] = imdata[row*w*3 + col*3 + channel];
				}
			}
		}

		// Draw the ImageSurface object to the screen.

		cr.setSourceSurface(imsurface, 0, 0);
		cr.paint();
		queueDrawArea(0, 0, w, h);
		setSizeRequest(w, h);

		// Release the image surface memory

		imsurface.destroy();

		return true;
	}

	bool queueNextFrame() {
		GtkAllocation area;
		getAllocation(area);
		
		queueDrawArea(area.x, area.y, area.width, area.height);
		
		return true;
	}
}

/**
 * Video player utility window.
 * 
 */
class VideoPlayer : MainWindow {
	VideoStreamCanvas videoCanvas;
	this(string [] args) { 
		super("DCV-GtkD Video Player"); 

		// Create the canvas, assuming first argument in the program is the video file on the file system.
		videoCanvas = new VideoStreamCanvas(args[1]);
		add(videoCanvas);
		videoCanvas.show();

		// Add the exit signal on 'q' keypress.
		addOnKeyPress (delegate bool(Event event, Widget width) {
				auto v = cast(char)event.key.keyval;
				if (v == 'q' || v == 'Q')
					std.c.stdlib.exit(0);
				return true;
			});
	}
}
