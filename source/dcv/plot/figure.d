/**
Module implements on-screen image plotting utilities.

DCV offers simple interface to show an image on screen:

----
Image image = imread("image.png");

// Simply, show the image
image.imshow();

// Optionally, show the image on the figure with given title:
image.imshow("Some Image");

// ... or do some processing, then show it in-line
image
    .sliced
    .as!float
    .slice
    .conv!symmetric(gaussian!float(1.0f, 3, 3))
    .imshow;

// ... or instantiate new figure to setup some useful callbacks, than use the
// Figure interface to draw on it's canvas, and show it:

auto f = figure("Figure title");  // create the figure with given title

// set the mouse move callback
f.setCursorCallback( (Figure figure, double x, double y)
{
    writeln("Mouse moved to: ", [x, y]);
})

// set the mouse button click callback
f.setMouseCallback( (Figure figure, int button, int scancode, int mods)
{
    writeln("Mouse clicked: ", [button, scancode, mods]);
});

f.draw(image); // draw an image to the figure's canvas.
f.show(); // show the figure on screen.

// Once figure's image buffer is drawn out (say you have an image, and few plots drawn on it),
// it can be extracted from the figure, and used in rest of the code:
Image plotImage = figure(title).image;
plotImage.imwrite("my_plot.png");

// And at the end, you can run the event loop for each previously set up figure, to wait
// for key input, or given time to pass.
waitKey!"seconds"(10);
----
Figure mechanism is integrated with ggplotd library, so GGPlotD context can be directly plotted onto existing figure.
To use GGPlotD library integration with DCV $(LINK2 http://dcv.dlang.io/?loc=dcv_plot_figure.html#plo, (dcv.plot.figure.plot)),
define ggplotd subConfiguration of dcv in dub configuration file:
----
"dependencies": {
    "dcv": "~>0.1.2"
},
"subConfigurations":{
    "dcv": "ggplotd"
}
----
This configuration is actually in dcv:plot subpackage, so if you define dcv:plot as dependency, you should define your subConfigurations as:
----
"dependencies": {
    "dcv:plot": "~>0.1.2"
},
"subConfigurations":{
    "dcv:plot": "ggplotd"
}
----
Example:
----
immutable title = "Image With Point Plot";
// show the image
image.imshow(title);
// construct the plot
auto gg = GGPlotD().put(geomPoint(Aes!(double[], "x", double[], "y")([100.00, 200.0], [200.0,100.0])));
// draw it onto the figure with given title...
gg.plot(title);
----

$(DL Module contains:
    $(DD
            $(LINK2 #imshow,imshow)
            $(LINK2 #plot,plot)
            $(LINK2 #waitKey,waitKey)
            $(LINK2 #imdestroy,imdestroy)
            $(LINK2 #Figure,Figure)
    )
)

Copyright: Copyright Relja Ljubobratovic 2016.

Authors: Relja Ljubobratovic

License: $(LINK3 http://www.boost.org/LICENSE_1_0.txt, Boost Software License - Version 1.0).
*/

module dcv.plot.figure;

import std.string : toStringz;
import std.exception;
import std.conv : to;
import std.container : Array;
import std.array : _sa = staticArray;

import mir.ndslice.slice;

import dcv.plot.drawprimitives;
import dcv.plot.ttf;
import dcv.core.utils : dlist;

import dplug.core;

version(ggplotd)
{
    import ggplotd.ggplotd, ggplotd.aes, ggplotd.axes, ggplotd.geom;
}

import dcv.core.image : Image, ImageFormat, BitDepth, asImage;
import dcv.plot.bindings;

/**
Exception thrown if drawing context hasn't been properly initialized.

Note:
    Current implementation of the module utilizes glfw3 library as drawing backend.
    API calls in the module may throw this exception if glfwInit fails at the module
    initialization.

See:
    http://www.glfw.org/docs/latest/group__init.html#ga317aac130a235ab08c6db0834907d85e
*/
class ContextNotInitialized : Exception
{
    this()
    {
        super("Drawing context has not been initialized properly.");
    }
}

/**
Create a plotting figure.

Params:
    title = Title of the window. If none given (default), window is named by "Figure id".

Throws:
    ContextNotInitialized

Returns:
    If figure with given title exists already, that figure is returned,
    otherwise new figure is created and returned.
*/
Figure figure(string title = "")
{
    mixin(checkContextInit);

    Figure f = null;
    if (title == "")
        title = "Figure " ~ _figures.length.to!string;
    foreach (e; _figures)
    {
        if (e.title == title)
        {
            f = e;
            break;
        }
    }
    if (f is null)
    {
        f = new Figure(title);
        if (_figures.length != 0)
        {
            auto p = _figures[$ - 1].position;
            immutable typeof(p[0]) offset = 30;
            // TODO: figure out smarter window cascading.
            f.moveTo(p[0] + offset, p[1] + offset);
        }

        _figures ~= f;
    }
    return f;
}

/**
Show an image to screen.

Params:
    image = Image that is to be shown on the screen.
    title = Title of the window. If none given (default), window is named by "Figure id".

If figure with given title exists, than the image content is updated with the given image.

Throws:
    ContextNotInitialized

Returns:
    If figure with given title exists already, that figure is returned,
    otherwise new figure is created and returned.
*/
Figure imshow(Image image, string title = "")
{
    auto f = figure(title);
    f.draw(image);
    f.show();
    return f;
}

/// ditto
Figure imshow(SliceKind kind, size_t N, Iterator)
    (Slice!(Iterator, N, kind) slice, string title = "")
{
    auto f = figure(title);
    f.draw(slice, ImageFormat.IF_UNASSIGNED);
    f.show();
    return f;
}

/// ditto
Figure imshow(SliceKind kind, size_t N, Iterator)
    (Slice!(Iterator, N, kind) slice, ImageFormat format, string title = "")
{
    auto f = figure(title);
    f.draw(slice, format);
    f.show();
    return f;
}

version(ggplotd)
{
    /**
    Show given image, and then plot given GGPlotD context on top of it.

    Params:
        image = Image that is to be shown on the screen.
        gg = Plotted data on top of the image.
        title = Title of the window. If none given (default), window is named by "Figure id".

    Throws:
        ContextNotInitialized

    Returns:
        If figure with given title exists already, that figure is returned,
        otherwise new figure is created and returned.
    */
    Figure plot(Image image, GGPlotD gg, string title = "")
    {
        auto f = figure(title);
        f.draw(image);
        f.draw(gg);
        f.show();
        return f;
    }

    /// ditto
    Figure plot(SliceKind kind, size_t N, Iterator)
        (Slice!(Iterator, N, kind) slice, GGPlotD gg, string title = "")
    {
        auto f = figure(title);
        f.draw(slice, ImageFormat.IF_UNASSIGNED);
        f.draw(gg);
        f.show();
        return f;
    }

    /// ditto
    Figure plot(SliceKind kind, size_t N, Iterator)
        (Slice!(Iterator, N, kind) slice, ImageFormat format, GGPlotD gg, string title = "")
    {
        auto f = figure(title);
        f.draw(slice, format);
        f.draw(gg);
        f.show();
        return f;
    }

    /**
    Plot GGPlotD context onto figure with given title.

    Given plot is drawn on top of figure's current image buffer. Size of the figure, and it's image buffer is
    unchanged. If no figure exists with given title, new one is allocated with default setup (500x500, with
    black background), and the plot is drawn on it.

    Params:
        gg = GGPlotD context, to be plotted on figure.
        title = Title of the window. If none given (default), window is named by "Figure id".

    Throws:
        ContextNotInitialized

    Returns:
        If figure with given title exists already, that figure is returned,
        otherwise new figure is created and returned.
    */
    Figure plot(GGPlotD gg, string title = "")
    {
        auto f = figure(title);
        f.draw(gg);
        f.show();
        return f;
    }
}

/**
Run the event loop for each present figure, and wait for key and/or given time.

Params:
    unit = Unit in which time count is given. Same as core.time.Duration unit parameters.
    count = Number of unit ticks to wait for event loop to finish. If left at zero (default), runs indefinitelly.

Throws:
    ContextNotInitialized

Returns:
    Ascii value as int of keyboard press, or 0 if timer runs out.
*/
int waitKey(string unit = "msecs")(ulong count = 0)
{
    import std.datetime.stopwatch : StopWatch;

    mixin(checkContextInit);

    StopWatch stopwatch;
    stopwatch.start;

    _lastKey = -1;
    auto hiddenLoopCheck = 0;

    while (true)
    {
        if (count && count < mixin("stopwatch.peek.total!\"" ~ unit ~ "\"")){
            // showing video frames or similar
            version(UseLegacyGL){ } else {
                foreach (f; _figures){
                    f.inVideoLoop = true;
                    f.clearPrimitives();
                }
                    
            }
            break;
        }    
        
        glfwPollEvents();

        if (_lastKey != -1)
            return _lastKey;

        bool allHidden = true;

        foreach (f; _figures)
        {
            auto glfwWindow = f._glfwWindow;

            if (f.visible == false)
            {
                continue;
            }

            if (glfwWindowShouldClose(glfwWindow))
            {
                f.hide();
                continue;
            }

            allHidden = false;
            f.render();

        }

        if (allHidden)
        {
            /*
            TODO: think this through - its good behavior to end the event loop 
            when no window is opened, but if image is shown right before the 
            waitKey call, glfw doesn't actually show the window, so Figure.visible 
            returns false.

            To bypass this, count event loop calls where all windows are hidden, 
            and if counter reaches enough hits (say 100), break the loop.

            This is temporary solution.
            */
            if (++hiddenLoopCheck > 100)
                break;
        }
    }
    
    return 0;
}

/**
Destroy figure.

Params:
    title = Title of the window to be destroyed. If left as empty string, destroys all windows.

Throws:
    ContextNotInitialized
*/
void imdestroy(string title = "")
{
    mixin(checkContextInit);

    if (title == "")
    {
        foreach (f; _figures)
        {
            f.hide();
            destroy(f);
        }
        _figures = [];
    }
    else
    {
        import std.algorithm.mutation : remove;

        foreach (i, f; _figures)
        {
            if (f.title == title)
            {
                f.hide();
                destroy(f);
                _figures.remove(i);
                break;
            }
        }
    }
}

/// Key press callback function.
alias KeyPressCallback = void delegate(int key, int scancode, int action, int mods) @nogc nothrow;
/// Character callback function.
alias CharCallback = void delegate(uint key) @nogc nothrow;

/**
Assign key press callback function.
*/
void setKeyPressCallback(KeyPressCallback clbck) @nogc nothrow
{
    _keyPressCallback = clbck;
}

/**
Assign character input callback function.
*/
void setCharCallback(CharCallback clbck) @nogc nothrow
{
    _charCallback = clbck;
}

/**
Plotting figure type.
*/
class Figure
{
    /// Mouse button callback function.
    alias MouseCallback = void delegate(Figure figure, int button, int action, int mods) @nogc nothrow;
    /// Cursor movement callback function.
    alias CursorCallback = void delegate(Figure figure, double xpos, double ypos) @nogc nothrow;
    /// Figure closing callback function.
    alias CloseCallback = void delegate(Figure figure) @nogc nothrow;

    private
    {
        GLFWwindow* _glfwWindow = null;

        int _width = 0;
        int _height = 0;
        RCArray!ubyte _data;
        string _title = "";
        int dispFormat = -1;

        MouseCallback _mouseCallback = null;
        CursorCallback _cursorCallback = null;
        CloseCallback _closeCallback = null;

        version(UseLegacyGL){ } else {
            TextureRenderer imageRenderer = null;

            GLuint shaderColor;
            GLuint shaderText;

            dlist!(PrimLauncher) primitiveQueue;

            GLSolidCircle solidCircleDrafter = null;
            GLCircle circleDrafter = null;
            GLLine lineDrafter = null;
            GLRect rectDrafter = null;
            GLTexturedRect!true textDrafter = null;
        }

        Slice!(RCI!float, 2LU, Contiguous) ortho;
    }

    package {
        Array!(uint) allocatedTexts;
        bool inVideoLoop = false;
    }

    @disable this();

    private void setupCallbacks() @nogc nothrow
    {
        glfwSetInputMode(_glfwWindow, GLFW_STICKY_KEYS, 1);

        glfwSetMouseButtonCallback(_glfwWindow, &mouseCallbackWrapper);
        glfwSetCursorPosCallback(_glfwWindow, &cursorCallbackWrapper);
        glfwSetWindowCloseCallback(_glfwWindow, &closeCallbackWrapper);
        glfwSetCharCallback(_glfwWindow, &charCallbackWrapper);
        glfwSetKeyCallback(_glfwWindow, &keyCallbackWrapper);

        setCloseCallback(&defaultCloseCallback);
    }

    /// Construct figure window with given title.
    private this(string title, int width = 512, int height = 512)
    in
    {
        assert(width > 0);
        assert(height > 0);
    }
    do
    {
        _title = title;
        _width = width;
        _height = height;
        _data = RCArray!ubyte(_width * _height * 3);
        
        setupWindow();
        fitWindow();
    }

    /// Construct figure window with given title, and fill it with given image.
    private this(string title, Image image)
    in
    {
        assert(image !is null);
        assert(!image.empty);
    }
    do
    {
        this(title, cast(int)image.width, cast(int)image.height);
        draw(image);
    }

    /// Construct figure window with given title, and fill it with given image.
    private this(SliceKind kind, size_t N, Iterator)
        (string title, Slice!(Iterator, N, kind) slice, ImageFormat format = ImageFormat.IF_UNASSIGNED)
            if (N == 2 || N == 3)
    {
        this(title, cast(int)slice.length!1, cast(int)slice.length!0);
        draw(slice, format);
    }

    ~this()
    {
        if (_glfwWindow !is null)
        {
            glfwDestroyWindow(_glfwWindow);
        }

        version(UseLegacyGL){} else {
            clearPrimitives();
            if(imageRenderer){
                destroyFree(imageRenderer);
                imageRenderer = null;
            }
            if(solidCircleDrafter !is null){
                destroyFree(solidCircleDrafter);
                solidCircleDrafter = null;
            }
            if(circleDrafter !is null){
                destroyFree(circleDrafter);
                circleDrafter = null;
            }
            if(lineDrafter !is null){
                destroyFree(lineDrafter);
                lineDrafter = null;

            } 
            if(rectDrafter !is null){
                destroyFree(rectDrafter);
                rectDrafter = null;
            }
            if(textDrafter !is null){
                destroyFree(textDrafter);
                textDrafter = null;
            }
        }
    }

    /// Assign mouse callback function.
    Figure setMouseCallback(MouseCallback clbck) @nogc nothrow
    {
        _mouseCallback = clbck;
        return this;
    }

    Figure setCursorCallback(CursorCallback clbck) @nogc nothrow
    {
        _cursorCallback = clbck;
        return this;
    }

    Figure setCloseCallback(CloseCallback clbck) @nogc nothrow
    {
        _closeCallback = clbck;
        return this;
    }

    @property width() inout @nogc nothrow
    {
        return _width;
    }

    @property height() inout @nogc nothrow
    {
        return _height;
    }

    @property title() inout @nogc nothrow
    {
        return _title;
    }

    @property title(inout string newTitle) @nogc nothrow
    {
        if (_glfwWindow)
        {
            glfwSetWindowTitle(_glfwWindow, CString(newTitle));
        }
    }

    @property visible() inout @nogc nothrow
    {
        if (_glfwWindow is null)
            return false;
        return glfwGetWindowAttrib(cast(GLFWwindow*)_glfwWindow, GLFW_VISIBLE) == 1;
    }

    @property int[2] position() const @nogc nothrow
    {
        int x;
        int y;
        glfwGetWindowPos(cast(GLFWwindow*)_glfwWindow, &x, &y);
        return [x, y]._sa;
    }

    @property int[2] size() const @nogc nothrow
    {
        int w, h;
        glfwGetWindowSize(cast(GLFWwindow*)_glfwWindow, &w, &h);
        return [w, h]._sa;
    }


    /// Get a copy of image currently drawn on figure's canvas.
    /*
    @property image() const
    in
    {
        assert(width && height);
    }
    do
    {
        Image im = new Image(width, height, ImageFormat.IF_RGB, BitDepth.BD_8);
        im.data[] = _data[];
        return im;
    }
    */
    /// Show the figure window.
    void show() @nogc nothrow
    {
        if (_glfwWindow)
            glfwShowWindow(_glfwWindow);
    }

    /// Show the figure window.
    void hide() @nogc nothrow
    {
        if (_glfwWindow)
            glfwHideWindow(_glfwWindow);
    }

    /// Clear canvas content of this figure.
    void clear() @nogc nothrow
    {
        _data.asSlice[] = cast(ubyte)0;
    }

    /// Move figure window to given position on screen.
    void moveTo(int x, int y) @nogc nothrow
    {
        glfwSetWindowPos(_glfwWindow, x, y);
    }

    /// ditto
    void moveTo(int[2] pos) @nogc nothrow
    {
        assert(pos.length == 2);
        move(pos[0], pos[1]);
    }

    /// Offset figure window position by given values.
    void move(int x, int y) @nogc nothrow
    {
        auto p = this.position;
        glfwSetWindowPos(_glfwWindow, p[0] + x, p[1] + y);
    }

    /// ditto
    void move(int[2] offset) @nogc nothrow
    {
        move(offset[0], offset[1]);
    }

    /// Draw image onto figure canvas.
    void draw(Image image)
    {
        auto tup = adoptImage(image);
        Image showImage = tup[0];
        dispFormat = tup[1];

        if (_width != showImage.width || _height != showImage.height)
        {
            _width = cast(int)showImage.width;
            _height = cast(int)showImage.height;
            _data = rcarray!ubyte(showImage.data[]);
        }
        else
        {
            assert(_data.length == showImage.data.length);
            _data.asSlice[] = showImage.data[];
        }
        
        fitWindow();
        version(UseLegacyGL){ } else {
            prepareRender();
        }
    }

    /// Draw slice of image onto figure canvas.
    void draw(SliceKind kind, size_t N, Iterator)
        (Slice!(Iterator, N, kind) image, ImageFormat format = ImageFormat.IF_UNASSIGNED)
    {
        import std.range.primitives : ElementType;
        import mir.ndslice.topology : as;
        import mir.ndslice.allocation : slice;

        //static assert(packs.length == 1, "Cannot draw packed slices.");

        alias T = ElementType!Iterator;

        Slice!(ubyte*, N, SliceKind.contiguous) showImage;
        static if ( is(T == ubyte) )
            showImage = image.assumeContiguous; // TODO: test if its contiguous
        else
            showImage = image.as!ubyte.slice;

        if (format == ImageFormat.IF_UNASSIGNED)
            draw( showImage.asImage() );
        else
            draw(showImage.asImage(format) );
    }

    /**
    Draw the GGPlotD context on this figure's canvas.

    Important Notes:
        - ggplotd's coordinate system starts from down-left corner. To match
          the image coordinate system (which starts from up-left corner), y axis
          is flipped in the given plot.
        - GGPlotD's margins are zeroed out in this function, and axes hidden.
        - GGPlotD's axes ranges are configured in this function to match figure size (width and height).
    */
    version(ggplotd) void draw(GGPlotD plot)
    {
        drawGGPlotD(plot, _data, _width, _height);
        fitWindow();
    }

    private void fitWindow() @nogc nothrow
    {
        glfwSetWindowSize(_glfwWindow, _width, _height);
        this.ortho = getOrtho(0.0f, cast(float)_width, cast(float)_height, 0.0f);
    }

    private void render()
    {
        version(UseLegacyGL){
            import dvc.plot.drawPrimitives : DISPLAY_FORMAT;
            
            glfwMakeContextCurrent(_glfwWindow);

            int fBufWidth, fBufHeight;
            glfwGetFramebufferSize(_glfwWindow, &fBufWidth, &fBufHeight);

            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glDisable(GL_DEPTH_TEST);

            glViewport(0, 0, fBufWidth, fBufHeight);

            glMatrixMode(GL_PROJECTION);
            glLoadIdentity();

            glOrtho(0, width, 0, height, 0.1, 1);

            glPixelZoom(fBufWidth / width, -fBufHeight / height);

            glRasterPos3f(0, height - 1, -0.3);

            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            glDrawPixels(_width, _height, DISPLAY_FORMAT(dispFormat), GL_UNSIGNED_BYTE, _data.ptr);

            glFlush();
            glEnable(GL_DEPTH_TEST);

            glfwSwapBuffers(_glfwWindow);

        } else {

            glfwMakeContextCurrent(_glfwWindow);

            int fBufWidth, fBufHeight;
            glfwGetFramebufferSize(_glfwWindow, &fBufWidth, &fBufHeight);
            glViewport(0, 0, fBufWidth, fBufHeight);

            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            glClearColor(0.5f, 0.0f, 0.5f, 1.0f);

            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            
            imageRenderer.render();

            drawPrimitives();
        
            glfwSwapBuffers(_glfwWindow);
        }
    }

version(UseLegacyGL){ } else {

    private void prepareRender() @nogc nothrow
    {
        if(imageRenderer is null){
            imageRenderer = mallocNew!TextureRenderer(ortho, _data.ptr, width, height, dispFormat);
        }

        if(solidCircleDrafter is null)
            solidCircleDrafter = mallocNew!GLSolidCircle(ortho, shaderColor);
        if(circleDrafter is null)
            circleDrafter = mallocNew!GLCircle(ortho, shaderColor);
        if(lineDrafter is null)
            lineDrafter = mallocNew!GLLine(ortho, shaderColor);
        if(rectDrafter is null)
            rectDrafter = mallocNew!GLRect(ortho, shaderColor);
        if(textDrafter is null)
            textDrafter = mallocNew!(GLTexturedRect!true)(ortho, shaderText);
    }

    private void drawPrimitives() @nogc nothrow
    {
        import std.range;
        auto primRange = primitiveQueue[];
        while(!primRange.empty){
            auto launcher = primRange.back;
            launcher.drafter.set(launcher.params);
            launcher.drafter.draw();
            primRange.popBackN(1);
        }
    }

    void clearPrimitives() @nogc nothrow
    {
        import std.range;
        import core.stdc.stdlib : free;

        auto primRange = primitiveQueue[];
        while(!primRange.empty){
            auto launcher = primRange.back;
            if(launcher.params)
                free(launcher.params);
            primRange.popBackN(1);
        }
        primitiveQueue.clear();
        
        foreach (tid; allocatedTexts.data)
        {
            glDeleteTextures(1, &tid);
        }
        allocatedTexts.clear;
    }

    @nogc nothrow
    void drawCircle(PlotCircle circle, PlotColor color = [1.0f, 0.0f, 0.0f, 0.5f], bool filled = false, float lineWidth = 1.0f){
        if(filled){
            GLSolidCircleParams* params = mallocNew!GLSolidCircleParams(circle.centerx, circle.centery, circle.radius, color);
            PrimLauncher launcher = PrimLauncher(solidCircleDrafter, cast(void*)params);
            primitiveQueue.insertFront(launcher);

        }else{
            GLCircleParams* params = mallocNew!GLCircleParams(circle.centerx, circle.centery, circle.radius, color, lineWidth);
            PrimLauncher launcher = PrimLauncher(circleDrafter, cast(void*)params);
            primitiveQueue.insertFront(launcher);
        }
    }

    @nogc nothrow
    void drawLine(PlotPoint point1, PlotPoint point2, PlotColor color, float lineWidth){
        GLLineParams* params = mallocNew!GLLineParams(point1, point2, color, lineWidth);
        PrimLauncher launcher = PrimLauncher(lineDrafter, cast(void*)params);
        primitiveQueue.insertFront(launcher);
    }

    @nogc nothrow
    void drawRectangle(PlotPoint[2] rect, PlotColor color, float lineWidth){
        GLRectParams* params = mallocNew!GLRectParams(rect, color, lineWidth);
        PrimLauncher launcher = PrimLauncher(rectDrafter, cast(void*)params);
        primitiveQueue.insertFront(launcher);
        
    }
    
    @nogc nothrow
    void drawText(ref TtfFont font, in char[] text, in PlotPoint posTopLeft, 
            float orientation = 0.0f, int size = 20, PlotColor color = plotRed){
        
        import mir.rc;
        import std.container.array;

        int w, h;
        RCArray!ubyte bitmap;

        // handle null termination
        Array!char buff;
        if(text[$] != '\0'){
            buff.length = text.length + 1;
            buff.data[0..$-1] = text[];
            bitmap = font.renderString(buff.data[], size, w, h);
            buff.clear;
        }else{
            bitmap = font.renderString(text, size, w, h);
        }

        auto tid = loadTexture(bitmap.ptr, w, h, GL_DEPTH_COMPONENT);
        this.allocatedTexts ~= tid;

        GLTexturedRectParams* params = mallocNew!GLTexturedRectParams(Rect(cast(int)posTopLeft.x, 
            cast(int)posTopLeft.y, w, h), tid, orientation, color);
        PrimLauncher launcher = PrimLauncher(textDrafter, cast(void*)params);
        primitiveQueue.insertFront(launcher);
    }

    /** 
        copy rendered figure to a slice. Useful with plot primitives.
    */
    auto plot2imslice() @nogc nothrow
    {
        import mir.rc;

        glfwMakeContextCurrent(_glfwWindow);
        
        Slice!(RCI!ubyte, 3LU, Contiguous) imgslice = uninitRCslice!ubyte(width, height, 3);
        imgslice[] = 0;

        glReadPixels(0, 0, width, height, GL_RGB, GL_UNSIGNED_BYTE, imgslice.ptr);

        return imgslice;
    }

}
    
    private void setupWindow()
    {
        glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
        _glfwWindow = glfwCreateWindow(_width, _height, toStringz(_title), null, null);
        if (!_glfwWindow)
        {
            throw new Exception("Cannot create window of size " ~ [_width, height].to!string);
        }
        
        glfwMakeContextCurrent(_glfwWindow);
        initGL();
        
        version(UseLegacyGL){}else{
            shaderColor = loadShaderColor();
            shaderText = loadShaderText();
        }
    }

    private void defaultCloseCallback(Figure figure) @nogc nothrow
    {
        glfwHideWindow(figure._glfwWindow);
    }
}

// Constants ////////////////////////////

immutable KEY_UNKNOWN = -1;
immutable KEY_SPACE = 32;
immutable KEY_APOSTROPHE = 39; /* ' */
immutable KEY_COMMA = 44; /* , */
immutable KEY_MINUS = 45; /* - */
immutable KEY_PERIOD = 46; /* . */
immutable KEY_SLASH = 47; /* / */
immutable KEY_SEMICOLON = 59; /* ; */
immutable KEY_EQUAL = 61; /* = */
immutable KEY_LEFT_BRACKET = 91; /* [ */
immutable KEY_BACKSLASH = 92; /* \ */
immutable KEY_RIGHT_BRACKET = 93; /* ] */
immutable KEY_GRAVE_ACCENT = 96; /* ` */
immutable KEY_ESCAPE = 256;
immutable KEY_ENTER = 257;
immutable KEY_TAB = 258;
immutable KEY_BACKSPACE = 259;
immutable KEY_INSERT = 260;
immutable KEY_DELETE = 261;
immutable KEY_RIGHT = 262;
immutable KEY_LEFT = 263;
immutable KEY_DOWN = 264;
immutable KEY_UP = 265;
immutable KEY_PAGE_UP = 266;
immutable KEY_PAGE_DOWN = 267;
immutable KEY_HOME = 268;
immutable KEY_END = 269;
immutable KEY_CAPS_LOCK = 280;
immutable KEY_SCROLL_LOCK = 281;
immutable KEY_NUM_LOCK = 282;
immutable KEY_PRINT_SCREEN = 283;
immutable KEY_PAUSE = 284;
immutable KEY_F1 = 290;
immutable KEY_F2 = 291;
immutable KEY_F3 = 292;
immutable KEY_F4 = 293;
immutable KEY_F5 = 294;
immutable KEY_F6 = 295;
immutable KEY_F7 = 296;
immutable KEY_F8 = 297;
immutable KEY_F9 = 298;
immutable KEY_F10 = 299;
immutable KEY_F11 = 300;
immutable KEY_F12 = 301;
immutable KEY_F13 = 302;
immutable KEY_F14 = 303;
immutable KEY_F15 = 304;
immutable KEY_F16 = 305;
immutable KEY_F17 = 306;
immutable KEY_F18 = 307;
immutable KEY_F19 = 308;
immutable KEY_F20 = 309;
immutable KEY_F21 = 310;
immutable KEY_F22 = 311;
immutable KEY_F23 = 312;
immutable KEY_F24 = 313;
immutable KEY_F25 = 314;
immutable KEY_KP_0 = 320;
immutable KEY_KP_1 = 321;
immutable KEY_KP_2 = 322;
immutable KEY_KP_3 = 323;
immutable KEY_KP_4 = 324;
immutable KEY_KP_5 = 325;
immutable KEY_KP_6 = 326;
immutable KEY_KP_7 = 327;
immutable KEY_KP_8 = 328;
immutable KEY_KP_9 = 329;
immutable KEY_KP_DECIMAL = 330;
immutable KEY_KP_DIVIDE = 331;
immutable KEY_KP_MULTIPLY = 332;
immutable KEY_KP_SUBTRACT = 333;
immutable KEY_KP_ADD = 334;
immutable KEY_KP_ENTER = 335;
immutable KEY_KP_EQUAL = 336;
immutable KEY_LEFT_SHIFT = 340;
immutable KEY_LEFT_CONTROL = 341;
immutable KEY_LEFT_ALT = 342;
immutable KEY_LEFT_SUPER = 343;
immutable KEY_RIGHT_SHIFT = 344;
immutable KEY_RIGHT_CONTROL = 345;
immutable KEY_RIGHT_ALT = 346;
immutable KEY_RIGHT_SUPER = 347;
immutable KEY_MENU = 348;
immutable KEY_LAST = KEY_MENU;

immutable MOD_SHIFT = 0x0001;
immutable MOD_CONTROL = 0x0002;
immutable MOD_ALT = 0x0004;
immutable MOD_SUPER = 0x0008;

immutable MOUSE_BUTTON_1 = 0;
immutable MOUSE_BUTTON_2 = 1;
immutable MOUSE_BUTTON_3 = 2;
immutable MOUSE_BUTTON_4 = 3;

private:

static int GLFW_STATUS;

// Checks if drawing context has been initialized.
enum checkContextInit = q{
    if (GLFW_STATUS == GLFW_FALSE) {
        throw new ContextNotInitialized();
    }
};

// initialize glfw and global callbacks
static this()
{
    import std.stdio;
version(GLFW_D){}else{
    enforce(loadGLFWLib() == glfwSupport, "Problem loading GLFW dynamic library!");
}
    GLFW_STATUS = glfwInit();

    setCharCallback((uint key) { _lastKey = key; });

    setKeyPressCallback((int key, int scancode, int action, int mods) {
        /*
        char callback takes priority with character keyboard inputs,
        so only override the _lastKey value if its -1, which means there
        was no char callback previously.
        */
        if (_lastKey == -1)
            _lastKey = key;
    });
}

private:

Figure[] _figures; // book-keeping of each running figure.
int _lastKey = -1; // last hit key

KeyPressCallback _keyPressCallback; // global key press callback
CharCallback _charCallback; // global char callback

extern (C) @nogc nothrow {
    void keyCallbackWrapper(GLFWwindow* window, int mods, int action, int scancode, int key)
    {
        if (_keyPressCallback)
            _keyPressCallback(key, scancode, action, mods);
    }

    void charCallbackWrapper(GLFWwindow* window, uint key)
    {
        if (_charCallback)
            _charCallback(key);
    }

    void cursorCallbackWrapper(GLFWwindow* window, double y, double x)
    {
        foreach (f; _figures)
        {
            if (f._glfwWindow == window)
            {
                if (f._cursorCallback)
                    f._cursorCallback(f, x, y);
                break;
            }
        }
    }

    void mouseCallbackWrapper(GLFWwindow* window, int mods, int action, int button)
    {
        foreach (f; _figures)
        {
            if (f._glfwWindow == window)
            {
                if (f._mouseCallback)
                    f._mouseCallback(f, button, action, mods);
                break;
            }
        }
    }

    void closeCallbackWrapper(GLFWwindow* window)
    {
        foreach (f; _figures)
        {
            if (f._glfwWindow == window)
            {
                if (f._closeCallback)
                    f._closeCallback(f);
                break;
            }
        }
    }
}

import std.typecons : Tuple, tuple;

Tuple!(Image, int) adoptImage(Image image)
{
    import dcv.imgproc.color : yuv2rgb, gray2rgb;

    Image showImage = (image.depth != BitDepth.BD_8) ? image.asType!ubyte : image;
    import mir.ndslice.topology;

    int dispFormat = cast(int)ImageFormat.IF_RGB;

    switch (showImage.format)
    {
    case ImageFormat.IF_BGR:
        dispFormat = cast(int)ImageFormat.IF_BGR;
        break;
    case ImageFormat.IF_YUV:
        showImage = showImage.sliced.yuv2rgb!ubyte.asImage(ImageFormat.IF_RGB);
        dispFormat = cast(int)ImageFormat.IF_RGB;
        break;
    case ImageFormat.IF_MONO:
        dispFormat = cast(int)ImageFormat.IF_MONO;
        break;
    default:
        break;
    }
    return tuple(showImage, dispFormat);
}

version(ggplotd) void drawGGPlotD(GGPlotD gg,  ubyte[] data,  int width, int height)
{
    import std.range : iota;
    import cairo = cairo;

    gg.put(xaxisRange(0, width)).put(yaxisRange(0, height)); // fit range to image size.
    gg.put(xaxisOffset(-10)).put(yaxisOffset(-10)); // change offset to hide axes.
    gg.put(Margins(0, 0, 0, 0)); // Change margins, to match image coordinates.

    cairo.Surface surface = new cairo.ImageSurface(cairo.Format.CAIRO_FORMAT_RGB24, width, height);
    gg.drawToSurface(surface, width, height);

    surface.flush();

    auto imSurface = cast(cairo.ImageSurface)surface; 
    auto surfData = imSurface.getData();

    foreach (r; iota(height))
        foreach (c; 0 .. width)
        {
            auto pixpos = (height - r - 1) * width * 4 + c * 4;
            auto dpixpos = r * width * 3 + c * 3;
            auto alpha = surfData[pixpos + 3];
            if (alpha)
            {
                auto af = cast(float)alpha / 255.0f;
                data[dpixpos + 0] = cast(ubyte)(data[dpixpos + 0] * (1.0f - af) + surfData[pixpos + 2] * af);
                data[dpixpos + 1] = cast(ubyte)(data[dpixpos + 1] * (1.0f - af) + surfData[pixpos + 1] * af);
                data[dpixpos + 2] = cast(ubyte)(data[dpixpos + 2] * (1.0f - af) + surfData[pixpos + 0] * af);
            }
        }
}