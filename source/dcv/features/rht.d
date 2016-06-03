module dcv.features.rht;

import std.experimental.ndslice;
import std.typecons;

/// A template that bootstraps a full Randomized Hough transform implementation
mixin template BaseRht()
{
    alias This = typeof(this);
    alias Point = Tuple!(int, "x", int "y");
    Tuple!(Curve, int)[Key] _accum;   // accumulator, parametrized on Key/Curve tuples
    int _thrd = 2;                    // threshold for a maximum to be detected in accumulator
    int _epouchs = 50;                // number of epouchs to iterate (attempts to find a shape)
    int _iters = 1000;                // iterations in each epouch
    int _minCurve = 25;               // minimal curve length in pixels

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

    void accumulate(Curve curve)
    {
        auto key = curveKey(curve);
        if (auto p = (key in _accum))
        {
            auto prior = (*p)[0];
            auto w = (*p)[1];
            
        }
    }
}


struct RhtLines
{
    alias Key = Tuple!(double, double);
    alias Curve = Tuple!(double, "m", double, "b");
    enum sampleSize = 2;         // sample points to use in each iteration
    double _angleTol = 1.0;      // tolerance in angle calculation (deg) 
    double _interceptTol = 1.0;  // tolerance in intercept calculation (pixels)
    double curveTol = 1.5;       // tolerance of on-curve check 
    mixin BaseRht;

    // does nessesary tolerance coarsening
    auto curveKey(Curve c)
    {
        import std.math;
        auto angle = atan(c.m)/M_PI*180;
        return Key(rint(angle/_angleTol), rint(c.b/_interceptTol));
    }


    auto fitCurve(size_t size, Range, Sample)(Slice!(size, Range) image, Sample sample)
    {
        int x1 = sample[0].x, y1 = sample[0].y;
        int x2 = sample[1].x, y2 = sample[1].y;
        if (x1 == x2)
            return Curve(double.inf, x1);
        else
        {
            auto m = (double)(y1-y2)/(x1 - x2);
            auto b = y1 - m*x1
            return Curve(m, b);
        }
    }

    bool onCurve(Curve curve, Point p)
    {
        import std.math;
        int x = p.x, y = p.y;
        double m = curve.m, b = curve.b;
        if ( m == double.inf && fabs(y - b) < curveTol)
            return true;
        else if (fabs(x*m+b - y) < curveTol)
            return true;
        return false;
    }
}
