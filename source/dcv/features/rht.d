module dcv.features.rht;

import std.experimental.ndslice;
import std.typecons;

/++
    A template that bootstraps a full Randomized Hough transform implementation.
    The basic primitives required are as follows.

    Types: Curve and Key tuples that define curve parameters and accumulator key for the curve.
    Functions: curveKey - accumulator key for a curve, onCurve - test if a point is on curve,
    fitCurve - fit a curve to a given random access range of points.
+/
mixin template BaseRht() {
    alias This = typeof(this);
    alias Point = Tuple!(int, "x", int, "y");
    int _thrd = 2;                    // threshold for a maximum to be detected in accumulator
    int _epouchs = 50;                // number of epouchs to iterate (attempts to find a shape)
    int _iters = 1000;                // iterations in each epouch
    int _minCurve = 25;               // minimal curve length in pixels

    // invalid (or empty) curve if any of parameters is NaN
    static bool isInvalidCurve(Curve c) {
        import std.math;
        foreach(v; c.tupleof)
            if(v.isNaN)
                return true;
        return false;
    }

    /// Set threshold for a curve to be considered in an accumulator
    ref threshold(int threshold) {
        _thrd = threshold;
        return this;
    }

    ref epouchs(int epouchs) {
        _epouchs = epouchs;
        return this;
    }

    ref iterations(int iters) {
        _iters = iters;
        return this;
    }

    ref minCurve(int minimalCurve) {
        _minCurve = minimalCurve;
        return this;
    }

    /// Run RHT using non-zero points in image as edge points.
    auto opCall(T)(Slice!(2, T*) image){
        Point[] points;
        foreach (y; 0..image.length[0])
        foreach (x; 0..image.length[1]) {
            if (image[y, x] > 0){
                points ~= Point(x, y);
            }
        }
        return this(image, points);
    }

    /// Run RHT using prepopullated array of edge points (that may be filtered beforehand).
    auto opCall(T, P)(Slice!(2, T*) image, const(P)[] points) {
        
        auto r = RhtRange!(T, P)(this, points);
        r.popFront(); // prime the detection process
        return r;
    }


    static struct RhtRange(T, P) {
        private:
            This _rht;                      // RHT struct with key primitives and parameters
            Slice!(2, T*) _image;           // image with edge points
            Tuple!(Curve, int)[Key] _accum; // accumulator, parametrized on Key/Curve tuples
            const(P)[] _points;             // extracted edge points
            int _epouch;                    // current epouch of iteration
            Curve _current;                 // current detected curve

            this(This rht, Slice!(2, T*) image, const(P)[] points) {
                _rht = rht;
                _image = image;
                _points = points;
            }

            void accumulate(Curve curve) {
                auto key = _rht.curveKey(curve);
                // if have a curve with the same key 
                // replace it with weighted average
                if (auto p = (key in _accum)) {
                    auto prior = (*p)[0];
                    auto w = (*p)[1];
                    Curve weighted;
                    foreach(i, _; prior.tupleof) {
                        weighted[i] = (prior[i]*w + curve[i])/(w+1.0);
                    }
                    auto newKey = _rht.curveKey(weighted);
                    if(key != newKey) {
                        _accum.remove(key);
                        _accum[newKey] = tuple(weighted, w+1);
                    }
                    else
                        *p = tuple(weighted, w+1);
                }
                // simply add current curve to accum
                else {
                    _accum[key] = tuple(curve, 1);
                }
            }

            Curve bestCurve() {
                Curve best;
                int maxW = 0;
                foreach ( _,v; _accum) {
                    if(v[1] > maxX){
                        maxW = v[1];
                        best = v[0];
                    }
                }
                return best;
            }
        public:
            Curve front() {
                return current;
            }

            bool empty() {
                return current.isInvalidCurve;
            }

            void popFront(){
                import std.algorithm, std.random, std.range;
                auto rng = Xorshift(unpredictableSeed);
                foreach (e; epouch.._rht._epouchs) {
                    accum.clear();
                    Curve best;
                    foreach (i; 0.._rht._iters) {
                        if (_points.length < _rht.sampleSize)
                            break;
                        auto sample = randomSample(_points, _rht.sampleSize, rng);
                        auto curve = _rht.fitCurve(image, sample);
                        if (!curve.isInvalidCurve)
                            accumulate(curve);
                    }
                    best = bestCurve();
                    if (best.isInvalidCurve) continue;
                    auto newPoints = _points.filter!(x => !_rht.onCurve(best, x)).array;
                    if (_points.length - newPoints.length > _rht._minCurve)
                    {
                        _points = newPoints; // remove fitted curve from the set of points
                        current = best;
                        epouch = e + 1; // skip current epouch
                        break; // stop prematurely
                    }
                }
                // spinned through all of epouchs - no more curves to detect
                current = Curve.init;
            }

            /// Resulting points that are not fitted to any shape yet
            @property auto points(){ return _points; }
        }
}

/// Randomized Hough Transform for lines
struct RhtLines {
    alias Key = Tuple!(double, double);
    alias Curve = Tuple!(double, "m", double, "b");
    enum sampleSize = 2;         // sample points to use in each iteration
    double _angleTol = 1.0;      // tolerance in angle calculation (deg) 
    double _interceptTol = 1.0;  // tolerance in intercept calculation (pixels)
    double curveTol = 1.5;       // tolerance of on-curve check 
    mixin BaseRht;

    // does nessesary tolerance coarsening
    auto curveKey(Curve c) {
        import std.math;
        auto angle = atan(c.m)/PI*180;
        return Key(rint(angle/_angleTol), rint(c.b/_interceptTol));
    }


    auto fitCurve(Range, Sample)(Slice!(2, Range) image, Sample sample) {
        int x1 = sample[0].x, y1 = sample[0].y;
        int x2 = sample[1].x, y2 = sample[1].y;
        if (x1 == x2)
            return Curve(double.infinity, x1);
        else {
            auto m = cast(double)(y1-y2)/(x1 - x2);
            auto b = y1 - m*x1;
            return Curve(m, b);
        }
    }

    bool onCurve(Curve curve, Point p) {
        import std.math;
        int x = p.x, y = p.y;
        double m = curve.m, b = curve.b;
        if ( m == double.infinity && fabs(y - b) < curveTol)
            return true;
        else if (fabs(x*m+b - y) < curveTol)
            return true;
        return false;
    }
}
