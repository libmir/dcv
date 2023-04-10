/**
Module introduces Randomized Hough Transform implementation.

Example:
----

// Load an image from filesystem.
Image image = imread("/path/to/image.png");

// Calculate edges by use of canny algorithm
auto edges = image
                .sliced
                .rgb2gray
                .as!float
                .slice
                .conv(gaussian!float(1.0f, 3, 3))
                .canny!ubyte(100);

// Setup RHT line extraction context
auto lines = RhtLines().epouchs(50).iterations(250).minCurve(25);

// Lazily iterate and detect lines in pre-processed image
foreach(line; lines(edges)) {
    // do stuff with lines..
}
----

For more elaborated module description visit the $(LINK2 http://dcv.dlang.io/?loc=example_rht,RHT example).

Copyright: Copyright © 2016, Dmitry Olshansky

Authors: Dmitry Olshansky

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.features.rht;

import std.typecons, std.range.primitives;

import mir.ndslice, mir.rc;
import mir.ndslice : filter;

@nogc nothrow:

/++
    A template that bootstraps a full Randomized Hough transform implementation.
    The basic primitives required are as follows.

    Types: Curve and Key tuples that define curve parameters and accumulator key for the curve.
    Functions: curveKey - accumulator key for a curve, onCurve - test if a point is on curve,
    fitCurve - fit a curve to a given random access range of points.
+/
mixin template BaseRht()
{
    alias This = typeof(this);
    alias Point = Tuple!(int, "x", int, "y");
    int _thrd = 2; // threshold for a maximum to be detected in accumulator
    int _epouchs = 50; // number of epouchs to iterate (attempts to find a shape)
    int _iters = 1000; // iterations in each epouch
    int _minCurve = 25; // minimal curve length in pixels

    @nogc nothrow:

    static auto toInt(double a)
    {
        import std.math;

        return cast(int)lrint(a);
    }

    // invalid (or empty) curve if any of parameters is NaN
    static bool isInvalidCurve(Curve c)
    {
        import std.math;

        foreach (v; c.tupleof)
            if (v.isNaN)
                return true;
        return false;
    }

    /// Set threshold for a curve to be considered in an accumulator
    ref threshold(int threshold)
    {
        _thrd = threshold;
        return this;
    }

    ref epouchs(int epouchs)
    {
        _epouchs = epouchs;
        return this;
    }

    ref iterations(int iters)
    {
        _iters = iters;
        return this;
    }

    ref minCurve(int minimalCurve)
    {
        _minCurve = minimalCurve;
        return this;
    }

    static auto opCall()
    {
        This zis;
        return zis;
    }

    /// Run RHT using non-zero points in image as edge points.
    auto opCall(T, SliceKind kind)(Slice!(T*, 2LU, kind) image)
    {
        import mir.appender : scopedBuffer;

        auto points = scopedBuffer!Point;
        int x, y = 0;

        foreach(row; image)
        {
            x = 0;
            foreach(e; row)
            {
                if (e > 0)
                    points.put(Point(x, y));
                ++x;
            }
            ++y;
        }
        return this.opCall(image, points.data);
    }

    /// Run RHT using prepopullated array of edge points (that may be filtered beforehand).
    auto opCall(T, SliceKind kind, Range)(Slice!(T*, 2LU, kind) image, Range points) if (isInputRange!Range)
    {
        auto r = RhtRange!(T, kind, ElementType!Range)(this, image, points);
        r.popFront(); // prime the detection process
        return r;
    }

    static struct RhtRange(T, SliceKind kind, P)
    {
    private:
        import std.container;
        import mir.random;
        import mir.random.engine.xorshift;

        import std.typecons : RefCounted, refCounted, RefCountedAutoInitialize;
        import std.algorithm.mutation : move;
        import bcaa : Bcaa;

        This _rht; // RHT struct with key primitives and parameters
        Slice!(T*, 2LU, kind) _image; // image with edge points
        Bcaa!(Key, Tuple!(Curve, int)) _accum; // accumulator, parametrized on Key/Curve tuples
        Array!P _points; // extracted edge points
        int _epouch; // current epouch of iteration
        Curve _current; // current detected curve
        RefCounted!(Xorshift, RefCountedAutoInitialize.no) _rng;

        @nogc nothrow:

        this(Range)(This rht, Slice!(T*, 2LU, kind) image, Range points)
        {
            _rht = rht;
            _image = image;
            _points = make!(Array!P)(points);
           _rng = Xorshift(cast(uint)unpredictableSeed);
        }

        void accumulate(Curve curve)
        {
            auto key = _rht.curveKey(curve);
            // if have a curve with the same key 
            // replace it with weighted average
            if (auto p = (key in _accum))
            {
                auto prior = (*p)[0];
                auto w = (*p)[1];
                Curve weighted;
                foreach (i, _; prior.tupleof)
                {
                    weighted[i] = (prior[i] * w + curve[i]) / (w + 1.0);
                }
                auto newKey = _rht.curveKey(weighted);
                if (key != newKey)
                {
                    _accum.remove(key);
                    _accum[newKey] = tuple(weighted, w + 1);
                }
                else
                    *p = tuple(weighted, w + 1);
            }
            // simply add current curve to accum
            else
            {
                _accum[key] = tuple(curve, 1);
            }
        }

        Curve bestCurve()
        {
            Curve best;
            int maxW = 0;
            foreach (v; _accum.byValue)
            {
                if (v[1] > maxW)
                {
                    maxW = v[1];
                    best = v[0];
                }
            }
            return best;
        }

    public:
        Curve front()
        {
            return _current;
        }

        bool empty()
        {
            return isInvalidCurve(_current);
        }

        void popFront()
        {
            import std.algorithm, std.range;
            import mir.random.algorithm : sample;

            foreach (e; _epouch .. _rht._epouchs)
            {
                _accum.free();
                Curve best;
                foreach (i; 0 .. _rht._iters)
                {
                    if (_points.length < _rht.sampleSize)
                        break;
                    
                    auto _sample = sample(_rng, _points[], _rht.sampleSize);
                    typeof(_points[0])[_rht.sampleSize] samplesa;

                    size_t _i;
                    foreach (s; _sample)
                        samplesa[_i++] = s;

                    auto curve = _rht.fitCurve(_image, samplesa[]);
                    if (!isInvalidCurve(curve))
                        accumulate(curve);
                }
                best = bestCurve();
                if (isInvalidCurve(best))
                    continue;
                //auto newPoints = make!Array(_points.filter!(x => !onCurve(best, x, _rht._curveTol)));
                import mir.appender : scopedBuffer;
                auto newPoints = scopedBuffer!(typeof(_points[0]));
                foreach (po; _points)
                {
                    if(!.onCurve(best, po, _rht._curveTol))
                        newPoints.put(po);
                }

                if (_points.length - newPoints.length > _rht._minCurve)
                {
                    // remove fitted curve from the set of points
                    _points.data[0 .. newPoints.length] = newPoints.data[];
                    //copy(newPoints[], _points[0 .. newPoints.length]);
                    _points.length = newPoints.length;
                    _current = best;
                    _epouch = e + 1; // skip current epouch
                    return; // stop prematurely
                }
            }
            // spinned through all of epouchs - no more curves to detect
            _current = Curve.init;
        }

        /// Resulting points that are not fitted to any shape yet
        @property auto points()
        {
            return _points;
        }
    }
}

/// Randomized Hough Transform for lines
struct RhtLines
{
    alias Key = Tuple!(double, double);
    alias Curve = Tuple!(double, "m", double, "b");
    enum sampleSize = 2; // sample points to use in each iteration
    double _angleTol = 1.0; // tolerance in angle approximation (deg) 
    double _interceptTol = 1.0; // tolerance in intercept approximation (pixels)
    double _curveTol = 1.5; // tolerance of on-curve check (pixels)
    mixin BaseRht;

    @nogc nothrow:

    // does coarsening to the multiple of tolerance
    auto curveKey(Curve c)
    {
        import std.math;

        auto angle = atan(c.m) / PI * 180;
        return Key(rint(angle / _angleTol), rint(c.b / _interceptTol));
    }

    auto fitCurve(Range, SliceKind kind, Sample)(Slice!(Range, 2LU, kind) image, Sample sample)
    {
        int x1 = sample[0].x, y1 = sample[0].y;
        int x2 = sample[1].x, y2 = sample[1].y;
        if (x1 == x2)
            return Curve(double.infinity, x1);
        else
        {
            auto m = cast(double)(y1 - y2) / (x1 - x2);
            auto b = y1 - m * x1;
            return Curve(m, b);
        }
    }

    
}

private bool onCurve(Curve, Point)(Curve curve, Point p, double _curveTol)
{
    import std.math;

    int x = p.x, y = p.y;
    double m = curve[0], b = curve[1];
    if (m == double.infinity && fabs(x - b) < _curveTol)
        return true;
    else if (fabs(x * m + b - y) < _curveTol)
        return true;
    return false;
}

struct RhtCircles
{
    alias Key = Tuple!(int, int, int);
    alias Curve = Tuple!(double, "x", double, "y", double, "r");
    enum sampleSize = 3;
    double _centerTol = 5.0; // tolerance of center location (pixels)
    double _radiusTol = 5.0; // tolerance of radius approfixmation (pixels)
    double _curveTol = 8; // tolerance of on-curve check (proportional to radius)
    mixin BaseRht;

    @nogc nothrow:

    // does coarsening to the multiple of tolerance
    auto curveKey(Curve c)
    {
        return Key(toInt(c.x / _centerTol), toInt(c.y / _centerTol), toInt(c.r / _radiusTol));
    }

    auto fitCurve(Range, SliceKind kind, Sample)(Slice!(Range, 2LU, kind) image, Sample sample)
    {
        import std.math : sqrt, pow;

        double x1 = sample[0].x, y1 = sample[0].y;
        double x2 = sample[1].x, y2 = sample[1].y;
        double x3 = sample[2].x, y3 = sample[2].y;
        double ynorm = (y2 * y2 - y3 * y3) * (x2 - x1) / 2 + (x3 - x2) * (y2 * y2 - y1 * y1) / 2 + (
                x1 - x3) * (y2 - y3) * (x2 - x1);
        double y = ynorm / ((y2 - y3) * (x2 - x1) + (x3 - x2) * (y2 - y1));
        double x = (y1 - y2) * (2 * y - y1 - y2) / (x2 - x1) / 2 + (x1 + x2) / 2;
        double r = sqrt(pow(x - x1, 2) + pow(y - y1, 2));
        return Curve(x, y, r);
    }

    bool onCurve(Curve curve, Point p)
    {
        import std.math : fabs;

        double x = p.x, y = p.y;
        double x0 = curve.x, y0 = curve.y, R = curve.r;
        x -= x0;
        y -= y0;
        if (fabs(x * x + y * y - R * R) < _curveTol * _curveTol)
            return true;
        return false;
    }
}

struct RhtEllipses
{
    alias Key = Tuple!(int, int, int, int, int);
    alias Curve = Tuple!(double, "x", double, "y", double, "a", double, "b", double, "phi");
    enum sampleSize = 3;
    double _centerTol = 2.0; // tolerance of center location (pixels)
    double _axisTol = 2.0; // tolerance of axis approximation (pixels)
    double _phiTol = 5.0; // tolerance of angle approximation (degrees)
    double _curveTol = 0.05; // tolerance of on-curve check (proportional to axis)
    mixin BaseRht;

    @nogc nothrow:
    // does coarsening to the multiple of tolerance
    auto curveKey(Curve c)
    {
        import std.math;

        return Key(toInt(c.x / _centerTol), toInt(c.y / _centerTol), toInt(c.a / _axisTol),
                toInt(c.b / _axisTol), toInt(c.phi / _phiTol));
    }

    auto fitCurve(Range, SliceKind kind, Sample)(Slice!(Range, 2, kind) image, Sample sample)
    {
        Curve c;
        //TODO:
        return c;
    }

    bool onCurve(Curve curve, Point p)
    {
        import std.math;

        double x = p.x, y = p.y;
        double x0 = curve.x, y0 = curve.y, a = curve.a, b = curve.b;
        x -= x0;
        y -= y0;
        double th = curve.phi * PI / 180;
        double nx = x * cos(th) + y * sin(th);
        double ny = -x * sin(th) + y * cos(th);
        if (fabs(nx * nx / (a * a) + ny * ny / (b * b) - 1.0) < _curveTol)
            return true;
        return false;
    }
}
