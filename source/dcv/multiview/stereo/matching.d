/**
Contains methods that compute disparity maps for stereo pairs.
*/
module dcv.multiview.stereo.matching;

import std.algorithm;

import mir.ndslice;

import dcv.core;
import dcv.core.image;
import dcv.core.utils : emptySlice;
import dcv.imgproc;

alias DisparityType = uint;
alias CostType = float;
alias DisparityMap = Slice!(2, DisparityType *);
alias CostVolume = Slice!(3, CostType *);

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
        body
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

1) Matching cost computation
2) Cost aggregation
3) Disparity computation
4) Disparity refinement

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
Creates a StereoCostFunction that computes the pixelwise absolute difference between intensities in the left and right images
*/
StereoCostFunction absoluteDifference()
{
    import std.functional;
    import std.math;
    return toDelegate(&pointwiseCost!(x => abs(x[0] - x[1])));
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

    //TODO: rewrite the rest of this function to use mir.ndslice.algorithm, etc.
    for(size_t y = 0; y < properties.frameHeight; y++)
    {
        for(size_t x = 0; x < properties.frameWidth; x++)
        {
            for(size_t d = 0; d < properties.disparityRange; d++)
            {
                if(x >= properties.minDisparity + d)
                {
                    import std.algorithm;
                    import std.range;

                    costVol[y, x, d] = zip(l[y, x], r[y, x - properties.minDisparity - d])
                                      .map!(fun)
                                      .fold!((a, b) => a + b)(cast(CostType)0);
                }
                else
                {
                    costVol[y, x, d] = CostType.max;
                }
            }
        }
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
body
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
            CostVolume tmpCostVol = costVol;

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
                    CostType minCost = pathCost[y - path.deltaY, x - path.deltaX].ndFold!"min(a, b)"(CostType.max);

                    //Iterate over each possible disparity
                    for(int d = 0; d < props.disparityRange; d++)
                    {
                        CostType cost = min(pathCost[y - path.deltaY, x - path.deltaX, d], minCost + p2);

                        if(d > 0)
                        {
                            cost = min(cost, pathCost[y - path.deltaY, x - path.deltaX, d - 1] + p1);
                        }
                        
                        if(d < props.disparityRange - 1)
                        {
                            cost = min(cost, pathCost[y - path.deltaY, x - path.deltaX, d + 1] + p1);
                        }

                        pathCost[y, x, d] += cost - minCost;
                    }
                }
            }

            if(path.reverseY)
            {
                tmpCostVol = pathCost.reversed!0;
            }

            if(path.reverseX)
            {
                tmpCostVol = pathCost.reversed!1;
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
        disp[] = costVol
                .pack!1
                .ndMap!(x => cast(uint)(x.length - minPos(x).length))[];
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
        //disp[] = medianFilter(disp, windowSize)[];
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

