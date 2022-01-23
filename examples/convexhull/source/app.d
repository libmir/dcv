import std.stdio;

import dcv.core;
import dcv.imageio.image;
import dcv.plot;
import dcv.imgproc;
import dcv.measure;

import mir.ndslice;
import mir.rc;


// Draw convexhull of randomly-generated points

int main(string[] args)
{
    import std.random;
    
    enum nPoints = 20;

    immutable size_t imWidth = 800;
    immutable size_t imHeight = 800;
    immutable size_t margin = 80;

    // create an empty image
    Slice!(RCI!ubyte, 3LU, Contiguous) img = uninitRCslice!ubyte(imHeight, imWidth, 3);
    
    for(;;){
        img[] = 0;

        // show a dummy image, and get a plot handle
        auto figure = imshow(img, "img");

        // allocate a slice for points
        Slice!(RCI!size_t, 2LU, Contiguous) points = uninitRCslice!size_t(nPoints, 2);
        
        // Generate random points
        auto gen = Random(unpredictableSeed);

        foreach (i; 0..nPoints)
        {
            size_t x = uniform!"[]"(margin, imWidth - margin, gen);
            size_t y = uniform!"[]"(margin, imWidth - margin, gen);
            points[i, 0] = x;
            points[i, 1] = y;

            // plot the points on the displayed figure window
            figure.drawCircle(PlotCircle(cast(float)x, cast(float)y, 5.0f), plotGreen);
        }
        
        // compute point indices of the convex hull
        auto chull_indices = convexHull(points);

        // plot hull lines on the figure
        foreach (i; 0 .. chull_indices.length -1){
            auto p1 = PlotPoint(points[chull_indices[i], 0], points[chull_indices[i], 1]);
            auto p2 = PlotPoint(points[chull_indices[i+1], 0], points[chull_indices[i+1], 1]);
            figure.drawLine(p1, p2, plotBlue, 3.0f);
        }
        auto p1 = PlotPoint(points[chull_indices[0], 0], points[chull_indices[0], 1]);
        auto p2 = PlotPoint(points[chull_indices[$-1], 0], points[chull_indices[$-1], 1]);
        figure.drawLine(p1, p2, plotBlue, 3.0f);

        // scatter points of the convex hull on the figure window
        foreach(index; chull_indices)
            figure.drawCircle(PlotCircle(cast(float)points[index, 0], cast(float)points[index, 1], 5.0f), plotRed, true);

        // rendered plot can be written to a file as image.
        // figure.plot2imslice().imwrite(ImageFormat.IF_RGB, "hull.png");
        
        int key = waitKey();
        if(key == cast(int)'q' || key == cast(int)'Q' )
            break;
    }

    return 0;
}