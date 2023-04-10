module dcv.example.plot;

/** 
 * Image plotting example using dcv library.
 */

import core.stdc.stdio;

import dcv.core;
import dcv.imageio;
import dcv.imgproc;
import dcv.plot.figure;

@nogc nothrow:

void main(string[] args)
{
    string path = (args.length == 2) ? args[1] : "../data/lena.png";

    Image image = imread(path);
    scope(exit) destroyFree(image);

    if (image is null)
    {
        printf("Failed reading image at path: %s", path.ptr);
        return;
    }

    immutable winStr = "DCV image";

    image.imshow(winStr).setCursorCallback(delegate(Figure figure, double x, double y) @nogc nothrow {
        printf("Mouse moved to: [%f, %f]\n", x, y);
    }).setMouseCallback(delegate(Figure figure, int button, int scancode, int mods) @nogc nothrow {
        printf("Mouse clicked: [%d, %d, %d]\n", button, scancode, mods);
    });

    int c = waitKey();

    if (c)
        printf("Character input: %c", cast(char)c);
    
    destroyFigures();
}