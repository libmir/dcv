module dcv.plot.bindings.glfw;

version(GLFW_D){
    public import glfw3.api;

}else{
    public import bindbc.glfw;

    auto loadGLFWLib(){
        auto ret = loadGLFW();
        return ret;
    }
}