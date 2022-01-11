﻿/**
Module introduces various corner detection algorithms.

<big>Currently present corner detectors:</big>
<ul>
<li>$(LINK2 https://dcv.dlang.io/?loc=dcv.features.corner.harris.html,Harris)</li>
<li>$(LINK2 https://dcv.dlang.io/?loc=dcv.features.corner.harris.html,Shi-Tomasi)</li>
<li>$(LINK2 https://dcv.dlang.io/?loc=dcv.features.corner.fast.package.html,FAST)</li>
</ul>

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.features.corner;

public import dcv.features.corner.harris, dcv.features.corner.fast;
