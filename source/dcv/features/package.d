module dcv.features;

/**
 * Feature detection and matching module.
 * 
 * v0.1 norm:
 * harris
 * shi-tomasi
 * fast $(LPAREN)wrap C version by author: http://www.edwardrosten.com/work/fast.html$(RPAREN)
 * most popular blob detectors - sift, ???
 * dense features - hog
 * 
 * v0.1+:
 * other popular feature detectors, descriptor, such as surf, brief, orb, akaze, etc.
 */

public import dcv.features.corner, dcv.features.utils, dcv.features.sift;
