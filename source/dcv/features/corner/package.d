/**
Module introduces various corner detection algorithms.

<big>Currently present corner detectors:</big>
<ul>
<li>Harris</li>
<li>Shi-Tomasi</li>
<li>FAST</li>
</ul>

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/ 

module dcv.features.corner;

public import dcv.features.corner.harris, 
    dcv.features.corner.fast;

/*
Corner detection module.

v0.1 norm: (done)
harris (done)
shi-tomasi (done)
fast (done)
*/
