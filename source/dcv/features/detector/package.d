module dcv.features.detector;

import std.experimental.ndslice;

public import dcv.core.image : Image;
public import dcv.features.utils : Feature;

/**
 * Feature detector interface.
 * 
 * Each feature detector algorithm
 * implements this interface.
 */
interface Detector
{
    Feature [] detect(in Image image, size_t count) const;
}

