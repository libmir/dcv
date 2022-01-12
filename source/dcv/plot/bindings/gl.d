module dcv.plot.bindings.gl;

public import bindbc.opengl;

import std.stdio;
import std.format;

void initGL(){

    GLSupport retVal = loadOpenGL();
    if(retVal > GLSupport.noContext) {
        debug writefln("configure renderer for GL-%d \n", retVal);
    }
    else {
        throw new Exception(format("OpenGl library load failed due to: GLSupport - %d", retVal));
    }
}