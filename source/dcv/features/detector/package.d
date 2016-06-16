/**
Module introduces the API that defines Feature Detector utilities in the dcv library.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/ 
module dcv.features.detector;

import std.experimental.ndslice;

public import dcv.core.image : Image;
public import dcv.features.utils : Feature;

/**
Feature detector interface.

Each feature detector algorithm
implements this interface.
*/
interface Detector
{
    /**
    Detector features in the image.

    params:
    image = Image in which features are looked for.
    count = How many features are to be extracted from given image.
    */
    Feature [] detect(in Image image, size_t count) const;
}

