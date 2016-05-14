module dcv.io;

/**
 * Input/Output module.
 * 
 * Implements I/O mechanisms for image, video and various file formats.
 * 
 * TODO: split sub-modules. (image, video, filestorage etc.)
 * 
 * v0.1 norm:
 * image write, read (most used formats)
 * video write, read -||-
 * data storage io (xml, csv?)
 * 
 */

public import dcv.io.image, 
    dcv.io.video;
