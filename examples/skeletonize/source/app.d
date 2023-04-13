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

    imwrite(skel.asImage(ImageFormat.IF_MONO), "result/skel.png");

    auto points = skel.endsAndjunctions;

    auto fig = imshow(skel, "skel");
    
    foreach (row; points)
    {
        fig.drawCircle(PlotCircle(row[1], row[0], 5), plotGreen, true);
    }
    

    waitKey();

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

    auto points = uninitRCslice!double([cntrs.length, 2]);
    size_t i;
    foreach(contour; cntrs){
        points[i][0] = contour[0..$, 0].mean;
        points[i++][1] = contour[0..$, 1].mean;
    }

    return points;
}