module dcv.example.plot;

/** 
 * Image plotting example using dcv library.
 */

import core.stdc.stdio;
import std.stdio;

import dcv.core;
import dcv.io;
import dcv.imgproc;
import dcv.plot.figure;

void main(string[] args)
{
    string path = (args.length == 2) ? args[1] : "../data/lena.png";

    Image image = imread(path);

    if (image is null)
    {
        writeln("Failed reading image at path: ", path);
        return;
    }

    immutable winStr = "DCV image";

    image.imshow(winStr).setCursorCallback(delegate(Figure figure, double x, double y) nothrow {
        printf("Mouse moved to: [%f, %f]\n", x, y);
    }).setMouseCallback(delegate(Figure figure, int button, int scancode, int mods) nothrow {
        printf("Mouse clicked: [%d, %d, %d]\n", button, scancode, mods);
    });

    int c = waitKey();

    if (c)
        writeln("Character input: ", cast(char)c);
}