/**
    Original implementation by Josh Chen.
    https://github.com/FreshJesh5/Suzuki-Algorithm
    Authors: Ferhat Kurtulmuş
*/
module dcv.measure.contours;

import dcv.core.utils;

import core.lifetime: move;
import std.math : abs;
import core.stdc.math : pow;
import std.typecons : Tuple, tuple;

import mir.ndslice;
import mir.rc;
import dvector;

alias Contour = Slice!(RCI!size_t, 2LU, Contiguous);

//struct for storing information on the current border, the first child, next sibling, and the parent.
struct HierNode {
    int parent = -1;
    int first_child = -1;
    int next_sibling = -1;

    Border border;

@nogc nothrow:
    void reset() {
        parent = -1;
        first_child = -1;
        next_sibling = -1;
    }
}

struct Rectangle {
    size_t x;
    size_t y;
    size_t width;
    size_t height;
}

alias BoundingBox = Rectangle;

unittest {
    import std.array : staticArray;
    import std.stdio;

    // Create a simple binary image with a single white square in the middle
    Slice!(ubyte*, 2) slice  = [
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 1, 1, 0, 0,
        0, 0, 1, 1, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0
    ].staticArray!(ubyte, 36)[].sliced(6,6);

    // Call findContours
    auto result = findContours(slice, 1);
    
    // Extract contours and hierarchy from the result
    auto contours = result[0];
    auto hierarchy = result[1];

    // Debug: Print the contours and hierarchy
    //writeln("Contours: ", contours);
    //writeln("Hierarchy: ", hierarchy[]);

    // Check that one contour is found
    assert(contours.length == 1);

    // Check that the contour points match the expected square boundary
    auto contour = contours[0];
    //writeln("Detected contour points: ", contour);

    // Update assertions based on actual contour points
    assert(contour.length == 4);
    assert(contour[0][0] == 2 && contour[0][1] == 2);
    assert(contour[1][0] == 3 && contour[1][1] == 2);
    assert(contour[2][0] == 3 && contour[2][1] == 3);
    assert(contour[3][0] == 2 && contour[3][1] == 3);

    // Extract the hierarchy node for the contour
    auto hierNode = hierarchy[0];
    
    // Verify hierarchy details
    assert(hierNode.parent == -1); // No parent, as it's the only contour
    // more tests needed here
}

@nogc nothrow:

/**
    Finds contours in a binary image using border following algorithms.

    This function detects contours in a binary image and returns them along with the contour hierarchy.
    It uses a modified border following algorithm to identify both outer borders and hole borders within the image.
   
    Params:
        binaryImage = The binary image in which contours are to be found.
        fullyConnected = Optional parameter indicating whether to use 8-connected $(LPAREN)true$(RPAREN) or 4-connected $(LPAREN)false$(RPAREN) neighborhood.
        whiteValue = Optional parameter specifying the value representing the white color in the binary image. Default is 255.
   
    Returns:
        Tuple containing:
        - RCArray!Contour: Array of detected contours.
        - RCArray!HierNode: Hierarchical tree structure representing contour relationships.
*/
Tuple!(RCArray!Contour, RCArray!HierNode)
findContours(InputType, bool fullyConnected = true)
(InputType binaryImage, immutable double whiteValue = 255) {
    import mir.ndslice.topology : as;

    // add 1 pix of margins to 2 dims
    immutable numrows = binaryImage.shape[0]+2;
    immutable numcols = binaryImage.shape[1]+2;

    auto image = rcslice!int([numrows, numcols], 0);
    image[1..$-1, 1..$-1] = as!int(binaryImage / whiteValue);
    //auto image = as!int(binaryImage / 255).rcslice;
    
    Border NBD, LNBD;
    //a vector of vectors to store each contour.
    //contour n will be stored in contours[n-2]
    //contour 2 will be stored in contours[0], contour 3 will be stored in contours[1], ad infinitum
    Dvector!(Dvector!Point) contours;

    LNBD.border_type = HOLE_BORDER;
    NBD.border_type = HOLE_BORDER;
    NBD.seq_num = 1;

    //hierarchy tree will be stored as an vector of nodes instead of using an actual tree since we need to access a node based on its index
    //see definition for HierNode
    //-1 denotes NULL
    Dvector!HierNode hierarchy;
    HierNode temp_node = HierNode(-1, -1, -1);
    temp_node.border = NBD;
    hierarchy ~= temp_node;

    Point p2;
    bool border_start_found;
    foreach (r; 0..numrows) {
        LNBD.seq_num = 1;
        LNBD.border_type = HOLE_BORDER;
        foreach (c; 0..numcols) {
            border_start_found = false;
            //Phase 1: Find border
            //If fij = 1 and fi, j-1 = 0, then decide that the pixel (i, j) is the border following starting point
            //of an outer border, increment NBD, and (i2, j2) <- (i, j - 1).
            if ((image[r, c] == 1 && c - 1 < 0) || (image[r, c] == 1 && image[r, c - 1] == 0)) {
                NBD.border_type = OUTER_BORDER;
                NBD.seq_num += 1;
                p2.setPoint(r,c-1);
                border_start_found = true;
            }

            //Else if fij >= 1 and fi,j+1 = 0, then decide that the pixel (i, j) is the border following
            //starting point of a hole border, increment NBD, (i2, j2) ←(i, j + 1), and LNBD ← fij in case fij > 1.
            else if ( c+1 < numcols && (image[r, c] >= 1 && image[r, c + 1] == 0)) {
                NBD.border_type = HOLE_BORDER;
                NBD.seq_num += 1;
                if (image[r, c] > 1) {
                    LNBD.seq_num = image[r, c];
                    LNBD.border_type = hierarchy[LNBD.seq_num-1].border.border_type;
                }
                p2.setPoint(r, c + 1);
                border_start_found = true;
            }

            if (border_start_found) {
                //Phase 2: Store Parent
                temp_node.reset();
                if (NBD.border_type == LNBD.border_type) {
                    temp_node.parent = hierarchy[LNBD.seq_num - 1].parent;
                    temp_node.next_sibling = hierarchy[temp_node.parent - 1].first_child;
                    hierarchy[temp_node.parent - 1].first_child = NBD.seq_num;
                    temp_node.border = NBD;
                    hierarchy ~= temp_node;
                }
                else {
                    if (hierarchy[LNBD.seq_num-1].first_child != -1) {
                        temp_node.next_sibling = hierarchy[LNBD.seq_num-1].first_child;
                    }

                    temp_node.parent = LNBD.seq_num;
                    hierarchy[LNBD.seq_num-1].first_child = NBD.seq_num;
                    temp_node.border = NBD;
                    hierarchy ~= temp_node;
                }

                //Phase 3: Follow border
                alias IMT = typeof(image);
                static if(fullyConnected){
                    followBorder!(IMT, stepCW8, stepCCW8, isExamined8, markExamined8, 8)
                        (image, r, c, p2, NBD, contours);
                } else {
                    followBorder!(IMT, stepCW, stepCCW, isExamined, markExamined, 4)
                        (image, r, c, p2, NBD, contours);
                }
                
            }

            //Phase 4: Continue to next border
            //If fij != 1, then LNBD <- abs( fij ) and resume the raster scan from the pixel(i, j + 1).
            //The algorithm terminates when the scan reaches the lower right corner of the picture.
            if (abs(image[r, c]) > 1) {
                LNBD.seq_num = abs(image[r, c]);
                LNBD.border_type = hierarchy[LNBD.seq_num - 1].border.border_type;
            }
        }

    }

    // prepare return arrays
    size_t i;
    auto ret0 = RCArray!Contour(contours.length);

    foreach (ref _c; contours)
    {
        auto clen = _c.length;
        Contour ctr = uninitRCslice!(size_t)(clen, 2);

        ctr._iterator[0..clen*2][] = (cast(size_t*)_c[].ptr)[0..clen*2];

        ret0[i++] = ctr;

        _c.free;
    }

    i = 0;

    auto ret1 = RCArray!HierNode(hierarchy.length);
    foreach (_h; hierarchy)
        ret1[i++]= _h;

    contours.free;
    hierarchy.free;
    
    return tuple(ret0, ret1);
}

/** 
    Extracts the indices of contours that do not have holes from the hierarchy.
   
    This function scans through the hierarchy and identifies contours that are outer borders (i.e., border type is 2).
    It then returns an array of indices corresponding to these contours.
   
    Params:
        hierarchy = A reference to the hierarchy structure which contains information about the contours.
   
    Returns:
        RCArray!int = An array of integers representing the indices of contours that are outer borders.
*/
RCArray!int indicesWithoutHoles(H)(const ref H hierarchy){
    import mir.appender;
    auto _ret = scopedBuffer!int;
    foreach (h; hierarchy)
    {
        if(h.border.seq_num - 2 >= 0 && h.border.border_type == 2 )
            _ret.put(h.border.seq_num - 2);
        
    }
    return rcarray!int(_ret.data);
}

/**
    Converts contours into a binary image representation.
   
    This function takes an array of contours and converts them into a binary image where the contour points are marked
    with a value of 255 $(LPAREN)white$(RPAREN) and the rest of the image is 0 $(LPAREN)black$(RPAREN).
   
    Params:
        contours = An array of contours $(LPAREN)RCArray!Contour$(RPAREN) to be converted into an image.
        rows = The number of rows in the output image of size_t.
        cols = The number of columns in the output image of size_t.
   
    Returns:
        Slice!(RCI!ubyte, 2LU, Contiguous) = A 2D slice representing the binary image with contours.
*/
auto contours2image(RCArray!Contour contours, size_t rows, size_t cols)
{

    Slice!(RCI!ubyte, 2LU, Contiguous) cimg = uninitRCslice!ubyte(rows, cols);
    cimg[] = 0;

    contours[].each!((cntr){ // TODO: parallelizm here?
        foreach(p; cntr){
            cimg[cast(size_t)p[0], cast(size_t)p[1]] = 255;
        }
    });

    return cimg.move;
}

/**
    Computes the area of a contour using the Shoelace formula.

    This function calculates the area enclosed by a contour, which is defined by a series of points, using the Shoelace formula (also known as Gauss's area formula).
    
    Params:
        contour = A contour represented by a 2D slice or array, where each row is a point and the first column contains the x-coordinates and the second column contains the y-coordinates.
    
    Returns:
        double = The area of the contour.
*/
double contourArea(C)(auto ref C contour)
{
    
    auto xx = contour[0..$, 0];
    auto yy = contour[0..$, 1];

    immutable npoints = contour.shape[0];
    
    double area = 0.0;
    
    foreach(i; 0..npoints){
        auto j = (i + 1) % npoints;
        area += cast(double)xx[i] * cast(double)yy[j];
        area -= cast(double)xx[j] * cast(double)yy[i];
    }
    area = abs(area) / 2.0;
    return area;
}

/**
    Computes the arc length $(LPAREN)perimeter$(RPAREN) of a contour.

    This function calculates the perimeter of a contour, which is defined by a series of points, by summing the Euclidean distances between consecutive points, including the distance between the last and the first point to close the contour.

    Params:
        contour = A contour represented by a 2D slice or array, where each row is a point and the first column contains the x-coordinates and the second column contains the y-coordinates.

    Returns:
        double = The perimeter of the contour.
*/
double arcLength(C)(auto ref C contour)
{
    auto xx = contour[0..$, 0];
    auto yy = contour[0..$, 1];
    
    double perimeter = 0.0, xDiff = 0.0, yDiff = 0.0;
    foreach(k; 0..xx.length-1) {
        xDiff = cast(double)xx[k+1] - cast(double)xx[k];
        yDiff = cast(double)yy[k+1] - cast(double)yy[k];
        perimeter += pow( xDiff*xDiff + yDiff*yDiff, 0.5 );
    }
    xDiff = cast(double)xx[xx.length-1] - cast(double)xx[0];
    yDiff = cast(double)yy[yy.length-1] - cast(double)yy[0];
    perimeter += pow( xDiff*xDiff + yDiff*yDiff, 0.5 );
    
    return perimeter;
}

auto colMax(S)(auto ref S x, size_t i)
{
    return x[x[0..$, i].maxIndex[0], i];
}

auto colMin(S)(auto ref S x, size_t i)
{
    return x[x[0..$, i].minIndex[0], i];
}

/**
    Computes the bounding box of a contour.

    This function calculates the smallest axis-aligned bounding box that can completely enclose the given contour. The bounding box is represented by its top-left corner coordinates (xMin, yMin) and its width and height.

    Params:
        contour = A contour represented by a 2D slice or array, where each row is a point and the first column contains the x-coordinates and the second column contains the y-coordinates.

    Returns:
        BoundingBox = A BoundingBox struct containing the top-left corner coordinates, width, and height of the bounding box.
*/
BoundingBox boundingBox(C)(C contour)
{
    import std.math;

    auto xMax = cast(size_t)contour.colMax(0).round;
    auto yMax = cast(size_t)contour.colMax(1).round;

    auto xMin = cast(size_t)contour.colMin(0).round;
    auto yMin = cast(size_t)contour.colMin(1).round;

    return BoundingBox(xMin, yMin, xMax - xMin + 1, yMax - yMin + 1);

}

/**
    Finds any point inside the given contour.

    This function attempts to find a point that lies inside the given contour. It iterates over each point in the contour and checks adjacent points in all 8 directions (up, down, left, right, and the four diagonals). The first point found that is inside the contour and not part of the contour itself is returned.

    Params:
        contour = A contour represented by a 2D slice or array, where each row is a point and the first column contains the x-coordinates and the second column contains the y-coordinates.

    Returns:
        Tuple!(size_t, size_t) = A tuple containing the coordinates of an inside point. If no such point is found, it returns (0, 0).
*/
Tuple!(size_t, size_t) anyInsidePoint(C)(auto ref C contour){
    import dcv.morphology.geometry : isPointInPolygon;

    immutable size_t[8] dx8 = [1, -1, 1, 0, -1,  1,  0, -1];
    immutable size_t[8] dy8 = [0,  0, 1, 1,  1, -1, -1, -1];

    foreach (i; 0..contour.shape[0]){
        auto cur = contour[i];
        Tuple!(size_t, size_t) last = tuple(cast(size_t)contour[i][0],
            cast(size_t)contour[i][1]);
        foreach(direction; 0..8){
            Tuple!(size_t, size_t) point = tuple(last[0] + dx8[direction], last[1] + dy8[direction]);
            if(!contour._contains(point) && isPointInPolygon(point, contour))
                return point;
        }
    }
    return tuple(size_t(0), size_t(0));
}

private bool _contains(C, P)(C c, P p){
    foreach (i; 0..c.shape[0]){
        auto cur = c[i];

        if((cast(size_t)cur[0] == cast(size_t)p[0]) && 
            (cast(size_t)cur[1] == cast(size_t)p[1]))
            return true;
    }
    return false;
}

private:

enum HOLE_BORDER = 1;
enum OUTER_BORDER = 2;

struct Border {
    int seq_num;
    int border_type;
}

struct Point {
    size_t row;
    size_t col;

@nogc nothrow:
    void setPoint(size_t r, size_t c) {
        row = r;
        col = c;
    }

    bool samePoint(Point p) {
        return row == p.row && col == p.col;
    }
}

//step around a pixel CCW
private:
void stepCCW(ref Point current, Point pivot) {
    if (current.col > pivot.col)
        current.setPoint(pivot.row - 1, pivot.col);
    else if (current.col < pivot.col)
        current.setPoint(pivot.row + 1, pivot.col);
    else if (current.row > pivot.row)
        current.setPoint(pivot.row, pivot.col + 1);
    else if (current.row < pivot.row)
        current.setPoint(pivot.row, pivot.col - 1);
}

//step around a pixel CW
void stepCW(ref Point current, Point pivot) {
    if (current.col > pivot.col)
        current.setPoint(pivot.row + 1, pivot.col);
    else if (current.col < pivot.col)
        current.setPoint(pivot.row - 1, pivot.col);
    else if (current.row > pivot.row)
        current.setPoint(pivot.row, pivot.col - 1);
    else if (current.row < pivot.row)
        current.setPoint(pivot.row, pivot.col + 1);
}

//step around a pixel CCW in the 8-connect neighborhood.
void stepCCW8(ref Point current, Point pivot) {
    if (current.row == pivot.row && current.col > pivot.col)
        current.setPoint(pivot.row - 1, pivot.col + 1);
    else if (current.col > pivot.col && current.row < pivot.row)
        current.setPoint(pivot.row - 1, pivot.col);
    else if (current.row < pivot.row && current.col == pivot.col)
        current.setPoint(pivot.row - 1, pivot.col - 1);
    else if (current.row < pivot.row && current.col < pivot.col)
        current.setPoint(pivot.row, pivot.col - 1);
    else if (current.row == pivot.row && current.col < pivot.col)
        current.setPoint(pivot.row + 1, pivot.col - 1);
    else if (current.row > pivot.row && current.col < pivot.col)
        current.setPoint(pivot.row + 1, pivot.col);
    else if (current.row > pivot.row && current.col == pivot.col)
        current.setPoint(pivot.row + 1, pivot.col + 1);
    else if (current.row > pivot.row && current.col > pivot.col)
        current.setPoint(pivot.row, pivot.col + 1);
}

//step around a pixel CW in the 8-connect neighborhood.
void stepCW8(ref Point current, Point pivot) {
    if (current.row == pivot.row && current.col > pivot.col)
        current.setPoint(pivot.row + 1, pivot.col + 1);
    else if (current.col > pivot.col && current.row < pivot.row)
        current.setPoint(pivot.row, pivot.col + 1);
    else if (current.row < pivot.row && current.col == pivot.col)
        current.setPoint(pivot.row - 1, pivot.col + 1);
    else if (current.row < pivot.row && current.col < pivot.col)
        current.setPoint(pivot.row - 1, pivot.col);
    else if (current.row == pivot.row && current.col < pivot.col)
        current.setPoint(pivot.row - 1, pivot.col - 1);
    else if (current.row > pivot.row && current.col < pivot.col)
        current.setPoint(pivot.row, pivot.col - 1);
    else if (current.row > pivot.row && current.col == pivot.col)
        current.setPoint(pivot.row + 1, pivot.col - 1);
    else if (current.row > pivot.row && current.col > pivot.col)
        current.setPoint(pivot.row + 1, pivot.col);
}

//checks if a given pixel is out of bounds of the image
pragma(inline, true)
bool pixelOutOfBounds(Point p, size_t numrows, size_t numcols) {
    return (p.col >= numcols || p.row >= numrows || p.col < 0 || p.row < 0);
}

//marks a pixel as examined after passing through
void markExamined(Point mark, Point center, ref bool[4] checked) {
    //p3.row, p3.col + 1
    size_t loc = -1;
    //    3
    //  2 x 0
    //    1
    if (mark.col > center.col)
        loc = 0;
    else if (mark.col < center.col)
        loc = 2;
    else if (mark.row > center.row)
        loc = 1;
    else if (mark.row < center.row)
        loc = 3;

    debug assert(loc != -1, "Error: markExamined Failed");

    checked[loc] = true;
    return;
}

//marks a pixel as examined after passing through in the 8-connected case
void markExamined8(Point mark, Point center, ref bool[8] checked) {
    //p3.row, p3.col + 1
    size_t loc = -1;
    //  5 6 7
    //  4 x 0
    //  3 2 1
    if (mark.row == center.row && mark.col > center.col)
        loc = 0;
    else if (mark.col > center.col && mark.row < center.row)
        loc = 7;
    else if (mark.row < center.row && mark.col == center.col)
        loc = 6;
    else if (mark.row < center.row && mark.col < center.col)
        loc = 5;
    else if (mark.row == center.row && mark.col < center.col)
        loc = 4;
    else if (mark.row > center.row && mark.col < center.col)
        loc = 3;
    else if (mark.row > center.row && mark.col == center.col)
        loc = 2;
    else if (mark.row > center.row && mark.col > center.col)
        loc = 1;

    debug assert(loc != -1, "Error: markExamined Failed");

    checked[loc] = true;
    return;
}

//checks if given pixel has already been examined
pragma(inline, true)
bool isExamined(const ref bool[4] checked) {
    //p3.row, p3.col + 1
    return checked[0];
}

pragma(inline, true)
bool isExamined8(const ref bool[8] checked) {
    //p3.row, p3.col + 1
    return checked[0];
}

pragma(inline, true)
P removeMargin(P)(P p){
    p.row--;
    p.col--;
    return p;
}

//follows a border from start to finish given a starting point
void followBorder(InputImage, alias cw_fun, alias ccw_fun, alias _isExamined, alias _markExamined, size_t nneighbor)
(ref InputImage image, size_t row, size_t col, Point p2, Border NBD, ref Dvector!(Dvector!Point) contours) {
    size_t numrows = image.shape[0];
    size_t numcols = image.shape[1];
    Point current = Point(p2.row, p2.col);
    Point start = Point(row, col);
    Dvector!Point point_storage;

    //(3.1)
    //Starting from (i2, j2), look around clockwise the pixels in the neighborhood of (i, j) and find a nonzero pixel.
    //Let (i1, j1) be the first found nonzero pixel. If no nonzero pixel is found, assign -NBD to fij and go to (4).
    do {
        cw_fun(current, start);
        if (current.samePoint(p2)) {
            image[start.row, start.col] = -NBD.seq_num;
            point_storage ~= start.removeMargin;
            contours ~= point_storage;
            return;
        }
    } while (pixelOutOfBounds(current, numrows, numcols) || image[current.row, current.col] == 0);
    Point p1 = current;
    
    //(3.2)
    //(i2, j2) <- (i1, j1) and (i3, j3) <- (i, j).
    
    Point p3 = start;
    Point p4;
    p2 = p1;
    bool[nneighbor] checked;

    while (true) {
        //(3.3)
        //Starting from the next element of the pixel(i2, j2) in the counterclockwise order, examine counterclockwise the pixels in the
        //neighborhood of the current pixel(i3, j3) to find a nonzero pixel and let the first one be(i4, j4).
        current = p2;


        checked[] = false;

        do {
            _markExamined(current, p3, checked);
            ccw_fun(current, p3);
        } while (pixelOutOfBounds(current, numrows, numcols) || image[current.row, current.col] == 0);
        p4 = current;

        //Change the value fi3, j3 of the pixel(i3, j3) as follows :
        //    If the pixel(i3, j3 + 1) is a 0 - pixel examined in the substep(3.3) then fi3, j3 <- - NBD.
        //    If the pixel(i3, j3 + 1) is not a 0 - pixel examined in the substep(3.3) and fi3, j3 = 1, then fi3, j3 ←NBD.
        //    Otherwise, do not change fi3, j3.

        if ( (p3.col+1 >= numcols || image[p3.row, p3.col + 1] == 0) && _isExamined(checked)) {
            image[p3.row, p3.col] = -NBD.seq_num;
        }
        else if (p3.col + 1 < numcols && image[p3.row, p3.col] == 1) {
            image[p3.row, p3.col] = NBD.seq_num;
        }

        point_storage ~= p3.removeMargin;

        //(3.5)
        //If(i4, j4) = (i, j) and (i3, j3) = (i1, j1) (coming back to the starting point), then go to(4);
        //otherwise, (i2, j2) <- (i3, j3), (i3, j3) <- (i4, j4), and go back to(3.3).
        if (p4.samePoint(start) && p3.samePoint(p1)) {
            contours ~= point_storage;
            return;
        }

        p2 = p3;
        p3 = p4;
    }
}
