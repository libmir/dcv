/**
Module introduces methods that compute disparity maps for stereo pairs.

$(DL Stereo Matching Base API:
    $(DD
            $(LINK2 #emptyDisparityMap,emptyDisparityMap)
            $(LINK2 #StereoMatcher,StereoMatcher)
            $(LINK2 #StereoPipelineProperties,StereoPipelineProperties)
            $(LINK2 #StereoPipeline,StereoPipeline)
            $(LINK2 #sumAbsoluteDifferences,sumAbsoluteDifferences)
            $(LINK2 #normalisedCrossCorrelation,normalisedCrossCorrelation)
            $(LINK2 #absoluteDifference,absoluteDifference)
            $(LINK2 #squaredDifference,squaredDifference)
            $(LINK2 #semiGlobalAggregator,semiGlobalAggregator)
            $(LINK2 #winnerTakesAll,winnerTakesAll)
            $(LINK2 #medianDisparityFilter,medianDisparityFilter)
            $(LINK2 #bilateralDisparityFilter,bilateralDisparityFilter)
    )
)
$(DL Stereo Matching Pipelines:
    $(DD
            $(LINK2 #semiGlobalMatchingPipeline,semiGlobalMatchingPipeline)
    )
)

Copyright: Copyright © 2016, Henry Gouk.

Authors: Henry Gouk

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/
module dcv.multiview.stereo.matching;

import mir.math.common;
import mir.math.sum;

import mir.ndslice.slice;
import mir.ndslice.allocation;
import mir.algorithm.iteration;
import mir.ndslice.topology;

import dcv.core;
import dcv.core.image;
import dcv.core.utils : emptySlice, clip;
import dcv.imgproc;

alias DisparityType = uint;
alias CostType = float;
alias DisparityMap = Slice!(DisparityType *, 2LU, SliceKind.contiguous);
alias CostVolume = Slice!(CostType *, 3LU, SliceKind.contiguous);

/**
Creates an empty disparity map
*/
DisparityMap emptyDisparityMap()
{
    return emptySlice!(2, DisparityType);
}

/**
Handles boilerplate code common to all stereo matching methods.
*/
class StereoMatcher
{
    public
    {
        /**
        Compute a disparity map using the method defined by the subclass.

        This method assumes the images have been rectified.
        */
        DisparityMap evaluate(inout Image left, inout Image right, DisparityMap prealloc = emptyDisparityMap())
        in
        {
            assert(left.width == right.width && left.height == right.height, "left and right must have the same dimensions");
            assert(left.channels == right.channels, "left and right must have the same number of channels");
            assert(left.format == right.format, "left and right must have the same pixel format");
            assert(left.depth == right.depth, "left and right must have the same bit depth");
        }
        do
        {
            if(prealloc.empty || prealloc.length!0 != left.height || prealloc.length!1 != left.width)
            {
                prealloc = new uint[left.width * left.height].sliced(left.height, left.width);
            }

            evaluateImpl(left, right, prealloc);

            return prealloc;
        }
    }

    protected
    {
        abstract void evaluateImpl(inout Image left, inout Image right, DisparityMap disp);
    }
}

alias StereoCostFunction = void delegate(const ref StereoPipelineProperties properties, inout Image left, inout Image right, CostVolume cost);
alias StereoCostAggregator = void delegate(const ref StereoPipelineProperties props, CostVolume costVol);
alias DisparityMethod = void delegate(const ref StereoPipelineProperties props, CostVolume costVol, DisparityMap disp);
alias DisparityRefiner = void delegate(const ref StereoPipelineProperties props, DisparityMap disp);

/**
Contains the properties required to build a StereoPipeline
*/
struct StereoPipelineProperties
{
    size_t frameWidth;
    size_t frameHeight;
    size_t frameChannels;
    DisparityType minDisparity;
    DisparityType disparityRange;

    this(size_t frameWidth, size_t frameHeight, size_t frameChannels = 3, DisparityType minDisparity = 0, DisparityType disparityRange = 64)
    {
        this.frameWidth = frameWidth;
        this.frameHeight = frameHeight;
        this.frameChannels = frameChannels;
        this.minDisparity = minDisparity;
        this.disparityRange = disparityRange;
    }
}

/**
This class provides a framework for constructing stereo matching pipelines that conform
to the taxonomy laid out in Scharstein and Szeliski (2002).

According to this taxonomy, stereo matching can be divided into four steps:

- Matching cost computation
- Cost aggregation
- Disparity computation
- Disparity refinement

Implementations of various algorithms that conform to requirements of these components
can be found in this module, as well as several helper functions that will create
commonly used pipelines out of these building blocks.
*/
class StereoPipeline : StereoMatcher
{
    public
    {
        this(const ref StereoPipelineProperties properties, StereoCostFunction costFunc, StereoCostAggregator aggregator, DisparityMethod dispMethod, DisparityRefiner refiner)
        {
            mProperties = properties;
            mCostFunction = costFunc;
            mCostAggregator = aggregator;
            mDisparityMethod = dispMethod;
            mDisparityRefiner = refiner;

            //Preallocate the cost tensor
            mCost = slice!CostType(properties.frameHeight, properties.frameWidth, properties.disparityRange - properties.minDisparity);
        }
    }

    protected
    {
        CostVolume mCost;
        StereoPipelineProperties mProperties;
        StereoCostFunction mCostFunction;
        StereoCostAggregator mCostAggregator;
        DisparityMethod mDisparityMethod;
        DisparityRefiner mDisparityRefiner;

        override void evaluateImpl(inout Image left, inout Image right, DisparityMap disp)
        {
            mCostFunction(mProperties, left, right, mCost);
            mCostAggregator(mProperties, mCost);
            mDisparityMethod(mProperties, mCost, disp);
            mDisparityRefiner(mProperties, disp);
        }
    }
}

/**
Computes the sum of absolute differences between two image patches in order to compute the matching cost.
*/
StereoCostFunction sumAbsoluteDifferences(uint windowSize = 5)
{
    import mir.ndslice.internal;

	static @fastmath CostType sad(CostType a, CostType b, CostType c)
	{
        return a + fabs(b - c);
	}

    return windowCost!((l, r) => reduce!sad(CostType(0), l, r))(windowSize);
}

/**
Computes the normalised cross correlation, also known as the cosine similarity, between image patches.

The resulting values are multiplied by negative one, so as to act as a loss rather than a fitness.
*/
StereoCostFunction normalisedCrossCorrelation(uint windowSize = 5)
{
    import mir.ndslice.internal;

    static @fastmath CostType fma(CostType c, CostType a, CostType b)
	{
        return c + a * b;
    }

    alias dot = reduce!fma;

	static @fastmath CostType ncc(L, R)(L l, R r)
	{   
        // TODO: use mtimes of https://code.dlang.org/packages/lubeck for a faster result
		return -dot(CostType(0), l, r) / sqrt(dot(CostType(0), l, l) * dot(CostType(0), r, r));
	}

    return windowCost!ncc(windowSize);
}

private StereoCostFunction windowCost(alias fun)(uint windowSize)
{
    void costFunc(const ref StereoPipelineProperties props, inout Image left, inout Image right, CostVolume costVol)
    {
        //Get the images as slices
        auto l = left
                .asType!CostType
                .sliced!CostType;

        auto r = right
                .asType!CostType
                .sliced!CostType;

        auto lpad = slice([l.shape[0] + windowSize - 1, l.shape[1] + windowSize - 1, l.shape[2]], CostType(0));
        auto rpad = slice([l.shape[0] + windowSize - 1, l.shape[1] + windowSize - 1, l.shape[2]], CostType(0));
        lpad[windowSize / 2 .. $ - windowSize / 2, windowSize / 2 .. $ - windowSize / 2, 0 .. $] = l[];
        rpad[windowSize / 2 .. $ - windowSize / 2, windowSize / 2 .. $ - windowSize / 2, 0 .. $] = r[];

        for(size_t d = 0; d < props.disparityRange; d++)
        {
            costVol[0 .. $, 0 .. d, d] = CostType.max;
            import mir.ndslice.dynamic : transposed;
            costVol[0 .. $, d .. $, d] = zip!true(lpad[0 .. $, d .. $], rpad[0 .. $, 0 .. $ - d])
                                        .pack!1
                                        .windows(windowSize, windowSize)
                                        .unpack
                                        .unpack
                                        .transposed!(0, 1, 4)
                                        .pack!2
                                        .map!(x => fun(x.unzip!'a', x.unzip!'b'))
                                        .pack!1
                                        .map!sum;
        }
    }

    return &costFunc;
}

/**
Creates a StereoCostFunction that computes the pixelwise absolute difference between intensities in the left and right images
*/
StereoCostFunction absoluteDifference()
{ 
    import std.functional: toDelegate;
    import mir.functional;
    return toDelegate(&pointwiseCost!(pipe!("a - b", fabs)));
}

/**
Creates a StereoCostFunction that computes the pixelwise squared difference between intensities in the left and right images
*/
StereoCostFunction squaredDifference()
{
    import std.functional: toDelegate;
    import mir.functional;
    return toDelegate(&pointwiseCost!(pipe!("a - b", "a * a")));
}

/**
Generic method that can be used for computing pointwise matching costs
*/
private void pointwiseCost(alias fun)(const ref StereoPipelineProperties properties, inout Image left, inout Image right, CostVolume costVol)
{
    //Get the images as slices
    auto l = left
            .asType!CostType
            .sliced!CostType;

    auto r = right
            .asType!CostType
            .sliced!CostType;

    for(size_t d = 0; d < properties.disparityRange; d++)
    {
        //Fill the invalid region of the cost volume with a very high cost
        costVol[0 .. $, 0 .. d, d] = CostType.max;

        //Compute the costs for the current disparity
        costVol[0 .. $, d .. $, d] = zip!true(l[0 .. $, d .. $], r[0 .. $, 0 .. $ - d])
                                    .map!fun
                                    .pack!1
                                    .map!sum;
                                    //.unpack;
    }
}

/**
Implements the cost aggregation method described by Hirschmuller (2007), commonly known as Semi-Global Matching.
*/
StereoCostAggregator semiGlobalAggregator(size_t numPaths = 8, CostType p1 = 15, CostType p2 = 100)
in
{
    assert(numPaths == 2 || numPaths == 4 || numPaths == 8 || numPaths == 16, "numPaths must be 2, 4, 8, or 16");
}
do
{
    struct Path
    {
        bool reverseY;
        bool reverseX;
        int deltaY;
        int deltaX;
    }

    static Path[16] paths = [//Horizontal
                            Path(false, false, 0, 1),
                            Path(false, true, 0, 1),
                            //Vertical
                            Path(false, false, 1, 0),
                            Path(true, false, 1, 0),
                            //45 degree angle
                            Path(false, false, 1, 1),
                            Path(false, true, 1, 1),
                            Path(true, false, 1, 1),
                            Path(true, true, 1, 1),
                            //22.5 degree increments
                            Path(false, false, 1, 2),
                            Path(false, true, 1, 2),
                            Path(true, false, 1, 2),
                            Path(true, true, 1, 2),
                            Path(false, false, 2, 1),
                            Path(false, true, 2, 1),
                            Path(true, false, 2, 1),
                            Path(true, true, 2, 1)];

    void aggregator(const ref StereoPipelineProperties props, CostVolume costVol)
    {
        //Create a new cost volume full of zeros
        auto totalCost = slice(costVol.shape, 0.0f);

        auto height = cast(int)costVol.length!0;
        auto width = cast(int)costVol.length!1;

        foreach(path; paths[0 .. numPaths])
        {
            auto tmpCostVol = costVol.universal;
            import mir.ndslice.dynamic;

            if(path.reverseY)
            {
                tmpCostVol = tmpCostVol.reversed!0;
            }

            if(path.reverseX)
            {
                tmpCostVol = tmpCostVol.reversed!1;
            }
            
            auto pathCost = tmpCostVol.slice;

            //Iterate over the y coordinate
            for(int y = path.deltaY; y < height; y++)
            {
                //Iterate over the x coordinate
                for(int x = path.deltaX; x < width; x++)
                {
                    CostType minCost = reduce!fmin(CostType.max, pathCost[y - path.deltaY, x - path.deltaX]);

                    //Iterate over each possible disparity
                    for(int d = 0; d < props.disparityRange; d++)
                    {
                        CostType cost = fmin(pathCost[y - path.deltaY, x - path.deltaX, d], minCost + p2);

                        if(d > 0)
                        {
                            cost = fmin(cost, pathCost[y - path.deltaY, x - path.deltaX, d - 1] + p1);
                        }
                        
                        if(d < props.disparityRange - 1)
                        {
                            cost = fmin(cost, pathCost[y - path.deltaY, x - path.deltaX, d + 1] + p1);
                        }

                        pathCost[y, x, d] += cost - minCost;
                    }
                }
            }

            tmpCostVol = pathCost.universal;

            if(path.reverseY)
            {
                tmpCostVol = tmpCostVol.reversed!0;
            }

            if(path.reverseX)
            {
                tmpCostVol = tmpCostVol.reversed!1;
            }

            totalCost[] += tmpCostVol[];
        }

        costVol[] = totalCost[];
    }

    return &aggregator;
}

/**
Implements the naive winner takes all algorithm for computing a diparity map from a cost volume.

At each (x, y) coordinate the disparity with the lowest cost is selected.
*/
DisparityMethod winnerTakesAll()
{
    void disparityMethod(const ref StereoPipelineProperties props, CostVolume costVol, DisparityMap disp)
    {
        import std.algorithm.searching: minPos;
        disp[] = costVol
                .pack!1
                .map!(x => cast(uint)(x.length - minPos(x).length))[];
    }

    return &disparityMethod;
}

/**
Applies a median filter to the disparity map in order to correct outliers.
*/
DisparityRefiner medianDisparityFilter(size_t windowSize = 3)
{
    void disparityRefiner(const ref StereoPipelineProperties props, DisparityMap disp)
    {
        disp[] = medianFilter(disp, windowSize)[];
    }

    return &disparityRefiner;
}

/**
Applies a bilateral filter to the disparity map in order to correct outliers.
*/
DisparityRefiner bilateralDisparityFilter(uint windowSize, float sigmaCol, float sigmaSpace)
{
    void disparityRefiner(const ref StereoPipelineProperties props, DisparityMap disp)
    {
        disp[] = bilateralFilter!DisparityType(disp, sigmaCol, sigmaSpace, windowSize);
    }

    return &disparityRefiner;
}

/**
Creates a StereoPipeline that performs semi-global matching.

Absolute difference is used for computing costs, and 3x3 median filter is applied to the winner take all disparity map.
*/
StereoPipeline semiGlobalMatchingPipeline(const ref StereoPipelineProperties props, size_t numPaths = 8, CostType p1 = 15, CostType p2 = 100)
{
    return new StereoPipeline(props, absoluteDifference(), semiGlobalAggregator(numPaths, p1, p2), winnerTakesAll(), medianDisparityFilter());
}

