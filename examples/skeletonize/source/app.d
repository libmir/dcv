import std.stdio;

import dcv.imageio.image : imread, imwrite;
import dcv.core;
import dcv.plot;
import dcv.imgproc;
import dcv.morphology;

import mir.ndslice;
import mir.rc;

void main() @nogc nothrow
{
    Image img = imread("../data/test_labels.png");
    scope(exit) destroyFree(img);

    Slice!(RCI!ubyte, 2, Contiguous) gray = img.sliced.lightScope.rgb2gray; // the test image is already binary here

    auto skel = skeletonize2D(gray);

    auto to_write = skel.asImage(ImageFormat.IF_MONO);
    scope(exit) destroyFree(to_write);

    imwrite(to_write, "result/skel.png");

    auto points = skel.endsAndjunctions;
    auto junctions = junctions(points, skel);

    auto fig = imshow(skel, "skel");
    
    foreach (row; points)
    {
        fig.drawCircle(PlotCircle(row[1], row[0], 5), plotRed, true);
    }

    foreach (row; junctions)
    {
        fig.drawCircle(PlotCircle(row[1], row[0], 5), plotGreen, true);
    }
    
    imwrite(fig.plot2imslice, ImageFormat.IF_RGB, "result/junctions_ends.png");

    waitKey();

    junctions.clear;

    destroyFigures();
}

auto endsAndjunctions(InputType, int whiteValue = 255)(auto ref InputType binarySkel){
    // https://stackoverflow.com/questions/72164740/how-to-find-the-junction-points-or-segments-in-a-skeletonized-image-python-openc
    import std.array: staticArray;
    import dcv.imgproc.convolution : conv;
    import dcv.imgproc.filter : dilate, boxKernel;
    import dcv.measure : findContours;
    import mir.ndslice;
    import dplug.core;
    import mir.math.stat: mean;

    float[9] _kernelArray = [1.0f, 1.0f, 1.0f, 1.0f, 10.0f, 1.0f, 1.0f, 1.0f, 1.0f];
    auto kernel = _kernelArray[].sliced(3, 3);
    auto _input = binarySkel.lightScope.as!float.map!(a => (a == whiteValue)? 10.0f : 0.0f).rcslice;
    auto imgFiltered = conv(_input, kernel);

    auto pointsMask = rcslice!ubyte(binarySkel.shape, 0);

    foreach (currentThresh; [ubyte(130), ubyte(110), ubyte(40)].staticArray)
    {   
        auto tempMat = uninitRCslice!ubyte(binarySkel.shape);

        auto winSize = tempMat.shape[0]/4;

        auto zip1 = zip!true(imgFiltered, tempMat);

        zip1.each!((p){
            p.b = (p.a == currentThresh)? 255 : 0;
        });

        auto zip2 = zip!true(pointsMask, tempMat);
        zip2.each!((p){
            p.a = (p.a == 255) || (p.b == 255) ? 255 : 0;
        });
    }
    auto morpKernel = boxKernel!ubyte(3);
    pointsMask = dilate(pointsMask, morpKernel);
    pointsMask = dilate(pointsMask, morpKernel);
    pointsMask = dilate(pointsMask, morpKernel);
    pointsMask = dilate(pointsMask, morpKernel);

    auto cntrs_h = findContours(pointsMask);
    auto cntrs = cntrs_h[0];

    auto points = uninitRCslice!size_t([cntrs.length, 2]);
    size_t i;
    foreach(contour; cntrs){
        points[i][0] = cast(size_t)contour[0..$, 0].mean;
        points[i++][1] = cast(size_t)contour[0..$, 1].mean;
    }

    return points;
}

auto junctions(P, S)(P points, S binary){
    import std.container.array;
    import std.array: staticArray;

    immutable size_t[8] dx8 = [1, -1, 1, 0, -1,  1,  0, -1];
    immutable size_t[8] dy8 = [0,  0, 1, 1,  1, -1, -1, -1];

    Array!(size_t[2]) junc;
    foreach(p; points){
        ubyte n_neighbors;
        foreach(n; 0..8){
            if(binary[p[0]+dx8[n], p[1]+dy8[n]] == 255)
                if(++n_neighbors > 1){
                    junc ~= [p[0], p[1]].staticArray;
                    break;
                }
        }
    }

    return junc;
}