# DCV 

[![Build Status](https://travis-ci.org/ljubobratovicrelja/dcv.svg?branch=master)](https://travis-ci.org/ljubobratovicrelja/dcv) [![codecov.io](https://codecov.io/github/ljubobratovicrelja/dcv/coverage.svg?branch=master)](https://codecov.io/github/ljubobratovicrelja/dcv?branch=master) [![Join the chat at https://gitter.im/ljubobratovicrelja/dcv](https://badges.gitter.im/ljubobratovicrelja/dcv.svg)](https://gitter.im/ljubobratovicrelja/dcv?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Computer Vision Library for D Programming Language

## Project idea
The idea behind the project is to write an open source computer vision library in D, by using as much modeling power from D as possible, but in the same time getting the desirable performance. Goal would be to implement tools for solving most common computer vision problems - various image processing tasks, feature detection and tracking, camera calibration, stereo etc.

## Library Modules
* core - Core structures and algorithms (mainly relying on std.experimental.ndslice);
* imgproc - Image processing tasks;
* io - Input/Output support for different image and video formats;
* plot - Ploting module, showing images, videos, basic 2D shape drawing etc;
* tracking - video tracking module - optical flow and other related methods;
* features - Feature detection, description and matching module;
* multiview - Multiview geometry module, camera calibration, stereo, reconstruction etc.

Please note that the initial idea for project organization may change in time.

## Contributions
If you like the project and would like to contribute, feel free to contact me via [ljubobratovic.relja@gmail.com](ljubobratovic.relja@gmail.com). Also, you can file an issue for feature request, bug report or any other library related inquiry. If you have any sort of quick question, feel free to post it in the gitter room. For more info on current development status, please read on.

## Development Stage
Currently, library is in early development (design) stage. Each module's header should note the **v0.1 norm**, which should list completion goals, after which the library could be used for most basic computer vision tasks. In the v0.1 development state, all algorithms will be naively implemented, without too much care for performance or factoring, but with proper API design. Goal of v0.1 is to have the overall shape of the library with good coverage, so it can be refactored and optimized in future versions.

### v0.1.0 Completion Status

This is the checklist on v0.1.0 completion. More elaborated development status may exist in the header comment of each module. If you see a module that is not checked, and you think you can help out, please let us know.

 - [ ] core
   - [ ] algorithm
   - [x] image
   - [ ] memory
   - [ ] utils
 - [ ] features
   - [x] corner 
     - [x] Harris
     - [x] Shi-Tomasi
     - [x] FAST
   - [ ] A-KAZE
   - [x] RHT (Randomized Hough Transform)
 - [ ] imgproc
   - [x] color
   - [x] convolution
   - [x] filter
   - [x] imgmanip
   - [x] interpolate
   - [ ] threshold
 - [x] io
   - [x] video
   - [x] image
 - [ ] multiview
   - [ ] common
   - [ ] calibration
   - [ ] stereo reconstruction
 - [ ] plot
 - [ ] tracking
   - [x] opticalflow
     - [x] hornschunck
     - [x] lucaskanade
   - [ ] blockmatching
     - [ ] stereo blockmatching

## License
Library is licensed under Boost Software License - Version 1.0. Some modules in the library contain code that is licensed under some other terms. If a module in the library states different license terms in it's header, then the Boost Software License does not apply to that module.

