# ![DCV](http://ljubobratovicrelja.github.io/dcv/images/dcv_logo.png)

[![Build Status](https://travis-ci.org/ljubobratovicrelja/dcv.svg?branch=master)](https://travis-ci.org/ljubobratovicrelja/dcv) [![codecov.io](https://codecov.io/github/ljubobratovicrelja/dcv/coverage.svg?branch=master)](https://codecov.io/github/ljubobratovicrelja/dcv?branch=master) [![Join the chat at https://gitter.im/ljubobratovicrelja/dcv](https://badges.gitter.im/ljubobratovicrelja/dcv.svg)](https://gitter.im/ljubobratovicrelja/dcv?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

*Computer Vision Library for D Programming Language*

## Project idea
The idea behind the project is to write an open source computer vision library in D, by using as much modeling power from D as possible, but in the same time getting the desirable performance. Goal would be to implement tools for solving most common computer vision problems - various image processing tasks, feature detection and tracking, camera calibration, stereo etc.

## Documentation
API reference, and examples can be found in project gh-pages: [https://ljubobratovicrelja.github.io/dcv/](https://ljubobratovicrelja.github.io/dcv/). Also project roadmap, news and other related stuff should be always located on the site's home page.

## Library Modules
* core - Core structures and algorithms (mainly relying on std.experimental.ndslice);
* imgproc - Image processing tasks;
* io - Input/Output support for different image and video formats;
* plot - Ploting module, showing images, videos, basic 2D shape drawing etc;
* tracking - video tracking module - optical flow and other related methods;
* features - Feature detection, description and matching module;
* multiview - Multiview geometry module, camera calibration, stereo, reconstruction etc.

## Contributions
PRs and any form of help is most appreciated. Also, you can file an issue for feature request, bug report or any other library related inquiry. If you have any sort of quick question, feel free to post it in the gitter room.

## License
Library is licensed under Boost Software License - Version 1.0. Some modules in the library contain code that is licensed under some other terms. If a module in the library states different license terms in it's header, then the Boost Software License does not apply to that module.

