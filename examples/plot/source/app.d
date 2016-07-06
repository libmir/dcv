module dcv.example.plot;

/** 
 * Image plotting example using dcv library.
 */

import std.stdio;
import std.string : toStringz;

import dcv.core;
import dcv.io;
import dcv.imgproc;

import core.stdc.stdlib;
import core.thread;

import dcv.plot.figure;

void main(string [] args) {

    Image image = imread("/home/relja/Pictures/cv/lena.png");
    immutable winStr = "My Window";

    image
        .sliced
        .asType!float
        .conv(gaussian!float(1.0f, 5, 5))
        .imshow(winStr)
        .setCursorCallback( (Figure figure, double x, double y) 
        {
            writeln("Mouse move to: ", [x, y]);
        })
        .setMouseCallback( (Figure figure, int button, int scancode, int mods)
        {
            writeln("Mouse clicked: ", [button, scancode, mods]);
        });

    int c = waitKey();

    writeln(c);

    imdestroy(winStr);

}

