module dcv.example.plot;

/** 
 * Image plotting example using dcv library.
 */

import std.stdio;

import dcv.core;
import dcv.io;
import dcv.imgproc;

import core.stdc.stdlib;
import core.thread;

import dcv.plot.figure;

void main(string [] args) {

    Image image = imread("../data/lena.png");

    immutable winStr = "Blurred Lena";

    image
        .sliced
        .asType!float
        .conv(gaussian!float(1.0f, 5, 5))
        .imshow(winStr)
        .setCursorCallback( (Figure figure, double x, double y)
        {
            writeln("Mouse moved to: ", [x, y]);
        })
        .setMouseCallback( (Figure figure, int button, int scancode, int mods)
        {
            writeln("Mouse clicked: ", [button, scancode, mods]);
        });

    int c = waitKey();

    if (c)
        writeln("Character input: ", cast(char)c);
}

