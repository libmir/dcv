# DCV [![Build Status](https://travis-ci.org/ljubobratovicrelja/dcv.svg?branch=master)](https://travis-ci.org/ljubobratovicrelja/dcv) [![codecov.io](https://codecov.io/github/ljubobratovicrelja/dcv/coverage.svg?branch=master)](https://codecov.io/github/ljubobratovicrelja/dcv?branch=master)
Computer Vision library for D programming language



## Project idea
The idea behind the project is to write an open source computer vision library in D, by using as much modeling power from D as possible, but in the same time getting the desirable performance. Goal would be to implement tools for solving most common computer vision problems - various image processing tasks, feature detection and tracking, camera calibration, stereo etc. Hopefully other D enthusiasts and computer vision scientists/engineers would like the idea, and help the project!

## Development Stage
Currently, library is in early development (design) stage. Each module's header should note the **v0.1 norm**, which should list completion goals, after which the library could be used for most basic computer vision tasks. Also, the v0.1 should mark the version at which the library base is well formed, and the library itself is actually presentable. **Please note that v0.1 norm may be changing at first.**

## Modules
Initial design of the library is to split it into following modules:
* core - Core structures and algorithms (mainly relying on std.experimental.ndslice);
* imgproc - Image processing tasks;
* io - Input/Output support for different image and video formats;
* plot - Ploting module, showing images, videos, basic 2D shape drawing etc;
* tracking - video tracking module - optical flow and other related methods;
* features - Feature detection, description and matching module;
* multiview - Multiview geometry module, camera calibration, stereo, reconstruction etc.

Initial idea for project organization may change in time. If anybody would like to share some advice on that matter, please do!

## Contributions
Any help is much appreciated! If you like the idea of having computer vision library in D, please contact me via email (**ljubobratovic.relja@gmail.com**) .

## Dependencies
Library should be primarilly based on scientific libraries from [DlangScience](https://github.com/DlangScience). Imageformats library from **dub** is used for Image I/O. When library is well formed, list of dependencies will be written plain - at this moment it is unsure which libraries project would depend on.

