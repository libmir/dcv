module dcv.example.plot;

/** 
 * Image plotting example using dcv library.
 */

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

    image.imshow(winStr).setCursorCallback((Figure figure, double x, double y) {
        writeln("Mouse moved to: ", [x, y]);
    }).setMouseCallback((Figure figure, int button, int scancode, int mods) {
        writeln("Mouse clicked: ", [button, scancode, mods]);
    });

    int c = waitKey();

    if (c)
        writeln("Character input: ", cast(char)c);
}
