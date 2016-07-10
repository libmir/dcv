/**
Module implements I/O mechanisms for image, video and various file formats.

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/ 

module dcv.io;

public import dcv.io.image, 
    dcv.io.video;

/*
TODO: split sub-modules. (image, video, filestorage etc.)

v0.1 norm:
image write, read (most used formats)
video write, read -||-

v0.2norm:
data storage io (xml, csv etc)
*/
