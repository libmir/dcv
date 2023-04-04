module dcv.plot.bindings.gl;

public import bindbc.opengl;

import mir.exception;
import core.stdc.stdio;
import std.format;

void initGL() @nogc nothrow
{

    GLSupport retVal = loadOpenGL();
    if(retVal > GLSupport.noContext) {
        printf("configure renderer for GL-%d \n", retVal);
    }
    else {
        try enforce!"OpenGl library load failed"(false);
        catch(Exception e) assert(false, e.msg);
    }
}