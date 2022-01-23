# ![DCV](https://github.com/libmir/dcv/raw/gh-pages/images/dcv_logo.png)

[![Build Status](https://travis-ci.org/libmir/dcv.svg?branch=master)](https://travis-ci.org/libmir/dcv) 
[![codecov.io](https://codecov.io/github/libmir/dcv/coverage.svg?branch=master)](https://codecov.io/github/libmir/dcv?branch=master) 
[![DUB](https://img.shields.io/dub/v/dcv.svg)](http://code.dlang.org/packages/dcv) 
[![Gitter](https://img.shields.io/gitter/room/libmir/public.svg)](https://gitter.im/libmir/public) 

*Computer Vision Library for D Programming Language*

## API Refactoring Note

Library's **API** is currently under [heavy reconstruction](https://github.com/libmir/dcv/issues/87). Until the API is considered properly designed, **implementation of new features will be put on hold**.

## About

DCV is an open source computer vision library, written in D programming language, with goal to provide tools for solving most common computer vision problems - various image processing tasks, feature detection and tracking, camera calibration, stereo etc.

## Focus

Focus of the library is to present an easy-to-use interface, that would attract computer vision scientists and engineers to prototype their solutions with, but also to provide fast running code that could be used to make production ready tools and applications.

## API

DCV's API heavily utilizes [Mir](https://github.com/libmir/mir) library, and it's `mir.ndslice` package. N-dimensional range view 
structure [Slice](https://github.com/libmir/mir/blob/master/source/mir/ndslice/slice.d) is used for any form of image manipulation 
and processing. But overall shape of the API is adopted from well known computer vision toolkits such as Matlab Image Processing 
Toolbox, and OpenCV library, to be easily familiarized with. But it's also spiced up with D's syntactic sugar, to support pipelined calls:

```d
Image image = imread("/path/to/image.png"); // read an image from filesystem.

auto slice = image.sliced; // slice image data (calls mir.ndslice.slice.sliced on image data)

slice[0..$, 0..$, 1] // take the green channel only.
    .as!float // convert slice data to float.
    .slice // make a copy
    .conv!symmetric(sobel!float(GradientDirection.DIR_X)) // convolve image with horizontal Sobel kernel.
    .ranged(0, 255) // scale values to fit the range between the 0 and 255
    .imshow("Sobel derivatives"); // preview changes on screen.

waitKey();
```

## Documentation

API reference, and examples can be found on the project website: [dcv.dlang.io](http://dcv.dlang.io/). Also project roadmap, news and other related stuff should be always located on the site's home page.

## Contributions
PRs and any form of help is most appreciated. Also, you can file an issue for feature request, bug report or any other library related inquiry. If you have any sort of quick question, feel free to post it in the gitter room.

## License
Library is licensed under Boost Software License - Version 1.0. Some modules in the library contain code that is licensed under some other terms. If a module in the library states different license terms in it's header, then the Boost Software License does not apply to that module.

## dcv revision/revival notes

* This is an effort to make dcv work with the recent versions of LDC, mir libraries and stuff
* I consider this as a temporary git repo which will be deleted after a big PR to the original DCV repo (if the maintainers accept).

## Done so far:

* Slice types were updated as to be Slice!(T*, N, SliceKind).
* Many other updates to comply with recent mir and Phobos libraries.
 uninitialized slice factory was changed to makeUninitSlice!T(GCAllocator.instance, someShape);
* bindbc libraries (bindbc-glfw and bindbc-opengl) replaced internal bindings for plotting.
* FFmpeg 4.4.1 binding was created from scratch.
* dub packaging system was changed to use dcv modules as separate dependecies such as dcv:core, dcv:video, dcv:ffmpeg441

## newly-implemented functionality:
* Otsu's method for threshold calculation
* dcv.measure module with refcounted image types: labelling connected regions, moments, ellipsefit, convexhull, findContours, area, perimeter
* dcv.morphology module with distanceTransform (more planned like watershed, skeletonize, end-points, junctions)
* Switched to modern OpenGL for rendering, by reserving the legacy gl support. use "subConfigurations": {"dcv:core": "legacygl"} for the legacy GL support.
* New plot primitives like drawLine and drawCircle at Opengl rendering level. the function plot2imslice copies the rendered buffer to a slice. Take a look at the convexhull examples for more.

## Need help for
* testing.
* updating unittests.
* solving any issue encountered during tests.
* fixing multiview module. Start here: unrevised/multiview/stereo/matching.d line 242
* re-binding ggplot backend or doing something better (my primitive drawing implementation can be improved)