# DCV
Computer Vision library for D programming language

## Project idea
The idea behind the project is to write an open source computer vision library in D, by using as much modeling power from D as possible, but in the same time getting the desirable performance. Goal would be to implement tools for solving most common computer vision problems - various image processing tasks, feature detection and tracking, camera calibration, stereo etc. Hopefully other D enthusiasts and computer vision scientists/engineers would like the idea, and help the project!

## Development Stage
Library design stage. Implementing core structures and algorithms.

## Modules
Initial design of the library is to split it into following modules:
* core - Core structures and algorithms (mainly relying on std.experimental.ndslice)
* imgproc - Image processing tasks.
* io - Input/Output support for different image and video formats. 
* plot - Ploting module, showing images, videos, basic 2D shape drawing etc.
* features - Feature detection, description and matching module.
* multiview - Multiview geometry module, camera calibration, stereo, reconstruction etc.

Initial idea for project organization may change in time. If anybody would like to share some advice on that matter, please do!

## Contributions
Any help is much appreciated! If you like the idea of having computer vision library in D, please contact me via email (**ljubobratovic.relja@gmail.com**) .

## Dependencies
Library should be primarilly based on scientific libraries from [DlangScience](https://github.com/DlangScience). Imageformats library from **dub** is used for Image I/O. When library is well formed, list of dependencies will be written plain - at this moment it is unsure which libraries project would depend on.

