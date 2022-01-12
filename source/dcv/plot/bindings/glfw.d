module dcv.plot.bindings.glfw;

public import bindbc.glfw;

auto loadGLFWLib(){
    auto ret = loadGLFW();
    return ret;
}