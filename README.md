# DCV
Computer Vision library for D programming language

## Project idea
The idea behind the project is to write an open source Computer Vision library in D, which could be used to help solve different sort of computer vision problems. Library is to be designed by using as much modeling power from D as possible, but in the same time getting the desirable performance. Hopefully other D enthusiasts and computer vision scientists/engineers would like the idea, and help the project!

## Development Stage
Library design stage. I'll try to commit examples to try to demonstrate the current status of development in this early stages.

## Modules
Initial design of the library is to split it into following modules:
* core - Core structures and algorithms (mainly relying on std.experimental.ndslice from DMD 2.0.70)
* imgproc - Image processing tasks.
* io - Input/Output support for different image and video formats. 
* plot - Ploting module, showing images, videos, basic 2D shape drawing etc.
* features - Feature detection, description and matching module.
* multiview - Multiview geometry module, camera calibration, stereo, reconstruction etc.

Initial idea for project organization may change in time. If anybody would like to share some advice on that matter, please do!

## Contributions
Help is much appreciated in every aspect, but I'd mainly ask for help in:
* Library design in D (any help and advice regarding language features - I'm primarilly using c++/python, and D still feels like new to me) 
* Algorithm implementation - there are lots of algorithms that could be implemented as part of this library. I'll try to implement most needed ones, at least the basic version. But to share this job with someone would be a huge deal!
* Algorithm optimization in D by parallelism, SIMD and other well known methods in computer vision. Although it is premature to talk about optimization (most of algorithms don't even exist), I believe it is important to design the algorithms from ground up with these optimizations in mind - e.g. aligned memory allocation should probably be used throughout library for SIMD to work, etc.

## Dependencies
Library should be primarilly based on scientific libraries from [DlangScience](https://github.com/DlangScience). Imageformats library from **dub** is used for Image I/O. When library is well formed, list of dependencies will be written plain - at this moment it is unsure which libraries project would depend on.

