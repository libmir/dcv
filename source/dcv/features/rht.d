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

    static auto toInt(double a) {
        import std.math;
        return cast(int)lrint(a);
    }

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

    static auto opCall() {
        This zis;
        return zis;
    }

    /// Run RHT using non-zero points in image as edge points.
    auto opCall(T)(Slice!(2, T*) image){
        Point[] points;
        foreach (y; 0..image.length!0)
        foreach (x; 0..image.length!1) {
            if (image[y, x] > 0){
                points ~= Point(cast(int)x, cast(int)y);
            }
        }
        return this.opCall(image, points);
    }

    /// Run RHT using prepopullated array of edge points (that may be filtered beforehand).
    auto opCall(T, P)(Slice!(2, T*) image, const(P)[] points) {
        auto r = RhtRange!(T, P)(this, image, points);
        r.popFront(); // prime the detection process
        return r;
    }


    static struct RhtRange(T, P) {
        private:
            import std.random;
            This _rht;                      // RHT struct with key primitives and parameters
            Slice!(2, T*) _image;           // image with edge points
            Tuple!(Curve, int)[Key] _accum; // accumulator, parametrized on Key/Curve tuples
            const(P)[] _points;             // extracted edge points
            int _epouch;                    // current epouch of iteration
            Curve _current;                 // current detected curve
            Xorshift rng;
            this(This rht, Slice!(2, T*) image, const(P)[] points) {
                _rht = rht;
                _image = image;
                _points = points;
                rng = Xorshift(unpredictableSeed);
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
                    if(v[1] > maxW){
                        maxW = v[1];
                        best = v[0];
                    }
                }
                return best;
            }
        public:
            Curve front() {
                return _current;
            }

            bool empty() {
                return isInvalidCurve(_current);
            }

            void popFront(){
                import std.algorithm, std.range;
                
                foreach (e; _epouch.._rht._epouchs) {
                    _accum.clear();
                    Curve best;
                    foreach (i; 0.._rht._iters) {
                        if (_points.length < _rht.sampleSize)
                            break;
                        // TODO: avoid heap allocation
                        auto sample = randomSample(_points, _rht.sampleSize, &rng).array;
                        auto curve = _rht.fitCurve(_image, sample);
                        if (!isInvalidCurve(curve))
                            accumulate(curve);
                    }
                    best = bestCurve();
                    import std.stdio;
                    writeln(best);
                    if (isInvalidCurve(best)) continue;
                    auto newPoints = _points.filter!(x => !_rht.onCurve(best, x)).array;
                    writeln("NP ", newPoints.length, " vs ", _points.length);
                    if (_points.length - newPoints.length > _rht._minCurve)
                    {
                        writeln("***");
                        _points = newPoints; // remove fitted curve from the set of points
                        _current = best;
                        writeln(_current);
                        _epouch = e + 1; // skip current epouch
                        return; // stop prematurely
                    }
                }
                // spinned through all of epouchs - no more curves to detect
                _current = Curve.init;
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
    double _angleTol = 1.0;      // tolerance in angle approximation (deg) 
    double _interceptTol = 1.0;  // tolerance in intercept approximation (pixels)
    double _curveTol = 1.5;      // tolerance of on-curve check (pixels)
    mixin BaseRht;

    // does coarsening to the multiple of tolerance
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
        if ( m == double.infinity && fabs(x - b) < _curveTol)
            return true;
        else if (fabs(x*m+b - y) < _curveTol)
            return true;
        return false;
    }
}

struct RhtCircles {
    alias Key = Tuple!(int, int, int);
    alias Curve = Tuple!(double, "x", double, "y", double, "r");
    enum sampleSize = 3;
    double _centerTol = 5.0;  // tolerance of center location (pixels)
    double _radiusTol = 5.0;  // tolerance of radius approfixmation (pixels)
    double _curveTol = 8;  // tolerance of on-curve check (proportional to radius)
    mixin BaseRht;

    // does coarsening to the multiple of tolerance
    auto curveKey(Curve c) {
        return Key(toInt(c.x/_centerTol), toInt(c.y/_centerTol), toInt(c.r/_radiusTol));
    }

    auto fitCurve(Range, Sample)(Slice!(2, Range) image, Sample sample) {
        import std.math : sqrt, pow;
        double x1 = sample[0].x, y1 = sample[0].y;
        double x2 = sample[1].x, y2 = sample[1].y;
        double x3 = sample[2].x, y3 = sample[2].y;
        double ynorm =  (y2*y2 - y3*y3)*(x2 - x1)/2 + (x3-x2)*(y2*y2-y1*y1)/2 + (x1 - x3)*(y2 - y3)*(x2- x1);
        double y = ynorm / ((y2 - y3)*(x2 - x1) + (x3-x2)*(y2-y1));
        double x = (y1 - y2)*(2*y - y1 - y2)/(x2 - x1)/2 + (x1+x2)/2;
        double r = sqrt(pow(x-x1, 2) + pow(y-y1, 2));
        return Curve(x,y,r);
    }

    bool onCurve(Curve curve, Point p) {
        import std.math : fabs;
        double x = p.x, y = p.y;
        double x0  = curve.x, y0 = curve.y, R = curve.r;
        x -= x0;
        y -= y0;
        if(fabs(x*x + y*y - R*R) < _curveTol*_curveTol)
            return true;
        return false;
    }
}

struct RhtEllipses {
    alias Key = Tuple!(int, int, int, int, int);
    alias Curve = Tuple!(double, "x", double, "y", double, "a", double, "b", double, "phi");
    enum sampleSize = 3;
    double _centerTol = 2.0;  // tolerance of center location (pixels)
    double _axisTol = 2.0;    // tolerance of axis approximation (pixels)
    double _phiTol = 5.0;     // tolerance of angle approximation (degrees)
    double _curveTol = 0.05;  // tolerance of on-curve check (proportional to axis)
    mixin BaseRht;

    // does coarsening to the multiple of tolerance
    auto curveKey(Curve c) {
        import std.math;
        return Key(toInt(c.x/_centerTol), toInt(c.y/_centerTol), 
            toInt(c.a/_axisTol), toInt(c.b/_axisTol), toInt(c.phi/_phiTol));
    }

    auto fitCurve(Range, Sample)(Slice!(2, Range) image, Sample sample) {
        Curve c;
        //TODO:
        return c;
    }

    bool onCurve(Curve curve, Point p) {
        import std.math;
        double x = p.x, y = p.y;
        double x0 = curve.x, y0 = curve.y, a = curve.a, b = curve.b;
        x -= x0;
        y -= y0;
        double th = curve.phi*PI/180;
        double nx = x*cos(th) + y*sin(th);
        double ny = -x*sin(th) + y*cos(th);
        if (fabs(nx*nx/(a*a) + ny*ny/(b*b) - 1.0) < _curveTol)
            return true;
        return false;
    }
}
