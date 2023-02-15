/++ Authors: Adrian Rosebrock
    Ported by Ferhat Kurtulmuş
    based on: https://pyimagesearch.com/2018/07/23/simple-object-tracking-with-opencv/
+/
module dcv.tracking.centroidtracker;

import std.math : sqrt;
import std.algorithm.sorting : sort;
import std.typecons : Tuple, tuple;
import std.container.array : Array;
import std.range : walkLength;
import std.array : staticArray;
import std.algorithm.setops : setDifference;

import dcv.core.utils : dlist;

import mir.appender : scopedBuffer;
import dplug.core.map;

alias CenterCoord = Tuple!(int, "x", int, "y");
alias Box = int[4];
alias Object = Tuple!(int, "id", CenterCoord, "centroid", Box, "box");

struct CentroidTracker {
    @disable this();

@nogc nothrow:

public:
    this(int maxDisappeared){
        this.nextObjectID = 0;
        this.maxDisappeared = maxDisappeared;

        pathKeeper = makeMap!(int, Array!(CenterCoord));
        disappeared = makeMap!(int, int);
    }

    ~this(){
        foreach(v; pathKeeper.byValue)
            v.clear();
        pathKeeper.clearContents();
        disappeared.clearContents();
        objects.clear();
    }
    void registerObject(int cX, int cY, Box b){
        int object_ID = this.nextObjectID;
        this.objects.insertBack(Object(object_ID, CenterCoord(cX, cY), b));
        this.disappeared[object_ID] = 0;
        this.nextObjectID += 1;
    }

    typeof(objects).Range update(ref Array!Box boxes){
        if (boxes.empty) {
            auto ks = scopedBuffer!int;
            foreach (ref k_v; disappeared.byKeyValue) {
                auto k = k_v.key;
                const v = k_v.value;
                disappeared[k] += 1;
                if (v > maxDisappeared){
                    for (auto rn = objects[]; !rn.empty;)
                        if (rn.front[0] == k)
                            objects.popFirstOf(rn);
                        else
                            rn.popFront();
                    pathKeeper[k].clear;
                    pathKeeper.remove(k);
                    ks.put(k);
                }
            }

            if(ks.data.length){
                foreach (k; ks.data)
                    disappeared.remove(k);
            }
             
            return objects[];
        }

        alias CenterBoxPtr = Tuple!(CenterCoord, "center", Box*, "boxptr");
        // initialize an array of input centroids for the current frame
        Array!(CenterBoxPtr) inputCentroids; inputCentroids.length = boxes.length;
        scope(exit) inputCentroids.clear();
        
        for (auto bi = 0; bi < boxes.length; bi++) {
            immutable b = boxes[bi];
            int cX = cast(int)((b[0] + b[2]) / 2.0);
            int cY = cast(int)((b[1] + b[3]) / 2.0);
            inputCentroids[bi] = CenterBoxPtr(CenterCoord(cX, cY), &boxes.data.ptr[bi]);
        }

        //if we are currently not tracking any objects take the input centroids and register each of them
        if (this.objects[].empty) {
            foreach (ref cb; inputCentroids) {
                this.registerObject(cb.center.x, cb.center.y, *cb.boxptr);
            }
        }

            // otherwise, there are currently tracking objects so we need to try to match the
            // input centroids to existing object centroids
        else {
            const _len = walkLength(objects[]);
            Array!int objectIDs; objectIDs.length = _len;
            Array!CenterCoord objectCentroids; objectCentroids.length = _len;
            scope(exit){
                objectIDs.clear;
                objectCentroids.clear;
            } 
            size_t oi;
            foreach (ref ob; objects[]){
                objectIDs[oi] = ob.id;
                objectCentroids[oi] = ob.centroid;
                oi++;
            }

    //        Calculate Distances
            Array!(Array!float) Distances; Distances.length = objectCentroids.length;
            scope(exit){
                foreach (a; Distances.data)
                {
                    a.clear();
                }
                Distances.clear;
            }
            foreach (size_t i; 0..objectCentroids.length) {
                Array!float temp_D; temp_D.length = inputCentroids.length;
                foreach (size_t j; 0..inputCentroids.length) {
                    const dist = calcDistance(objectCentroids[i].x, objectCentroids[i].y, inputCentroids[j].center.x,
                                            inputCentroids[j].center.y);

                    temp_D[j] = cast(float)dist;
                }
                Distances[i] = temp_D;
            }

            // load rows and cols
            Array!size_t cols; cols.length = Distances.length;
            Array!size_t rows;

            scope(exit){
                rows.clear;
                cols.clear;
            }

            //find indices for cols
            foreach (c, v; Distances.data) {
                const temp = findMin(v);
                cols[c] = temp;
            }

            //rows calculation
            //sort each mat row for rows calculation
            Array!(Array!float) D_copy; D_copy.length = Distances.length;
            foreach (i, v; Distances.data) {
                v.data.sort();
                D_copy[i] = v;
            }

            // use cols calc to find rows
            // slice first elem of each column
            
            Array!(Tuple!(float, int)) temp_rows; temp_rows.length = D_copy.length;
            scope(exit) D_copy.clear;
            
            foreach (i, el; D_copy.data) {
                temp_rows[i] = tuple(el[0], cast(int)i);
            }
            //print sorted indices of temp_rows
            rows.length = temp_rows.length;
            foreach (i, ref f_i ; temp_rows.data) {
                rows[i] = f_i[1];
            }

            temp_rows.clear;

            Set!size_t usedRows;
            Set!size_t usedCols;

            //loop over the combination of the (rows, columns) index tuples
            for (size_t i = 0; i < rows.length; i++) {
                //if we have already examined either the row or column value before, ignore it
                if (rows[i] in usedRows || cols[i] in usedCols) { continue; }
                //otherwise, grab the object ID for the current row, set its new centroid,
                // and reset the disappeared counter
                int objectID = objectIDs[rows[i]];

                foreach (ref id_coord_box ; objects[]){
                    if (id_coord_box.id == objectID) {
                        id_coord_box.centroid.x = inputCentroids[cols[i]].center.x;
                        id_coord_box.centroid.y = inputCentroids[cols[i]].center.y;
                        id_coord_box.box = *inputCentroids[cols[i]].boxptr; // update rectangle for new position
                    }
                }
                this.disappeared[objectID] = 0;

                usedRows.insert(rows[i]);
                usedCols.insert(cols[i]);
            }

            // compute indexes we have NOT examined yet
            import std.range : iota;

            auto objRows = iota(0, cast(int)objectCentroids.length);
            auto inpCols = iota(0, cast(int)inputCentroids.length);

            Array!int unusedRows = Array!int(setDifference(objRows, usedRows[]));
            Array!int unusedCols = Array!int(setDifference(inpCols, usedCols[]));
            scope(exit){
                unusedRows.clear;
                unusedCols.clear;
            }
            //If objCentroids > InpCentroids, we need to check and see if some of these objects have potentially disappeared
            if (objectCentroids.length >= inputCentroids.length) {
                // loop over unused row indexes

                foreach (row; unusedRows) {
                    int objectID = objectIDs[row];
                    this.disappeared[objectID] += 1;

                    if (this.disappeared[objectID] > this.maxDisappeared) {

                        for (auto rn = objects[]; !rn.empty;)
                            if (rn.front.id == objectID)
                                objects.popFirstOf(rn);
                            else
                                rn.popFront();

                        pathKeeper[objectID].clear;
                        pathKeeper.remove(objectID);
                        disappeared.remove(objectID);
                    }
                }
            } else {
                foreach (col; unusedCols) {
                    this.registerObject(inputCentroids[col].center.x, inputCentroids[col].center.y, 
                        *inputCentroids[col].boxptr);
                }
            }
        }
        //loading path tracking points
        if (!objects[].empty) {
            foreach (ob; objects[]){                
                if(auto ptr = ob.id in pathKeeper){
                    if ((*ptr).length > 30)
                        (*ptr).clear;

                    (*ptr) ~= ob.centroid;
                }else
                    pathKeeper[ob.id] = Array!(CenterCoord)([ob.centroid].staticArray);
            }
        }

        return objects[];
    }
    
    Map!(int, Array!(CenterCoord)) pathKeeper;
    
private:
    private dlist!(Object) objects;
    
    Map!(int, int) disappeared;

    int maxDisappeared;
    int nextObjectID;
    // <ID, count>
    

    static double calcDistance(double x1, double y1, double x2, double y2){
        const double x = x1 - x2;
        const double y = y1 - y2;
        double dist = sqrt((x * x) + (y * y));       //calculating Euclidean distance

        return dist;
    }
}

private size_t findMin(A)(const A v, size_t pos = 0) @nogc nothrow
{
    if (v.length <= pos) return (v.length);
    size_t min = pos;
    for (size_t i = pos + 1; i < v.length; i++) {
        if (v[i] < v[min]) min = i;
    }
    return min;
}