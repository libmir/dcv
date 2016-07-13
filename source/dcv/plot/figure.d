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
    .asType!float
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

// run the event loop for each previously set up figure, and wait 
// for key input, or given time to pass.
waitKey!"seconds"(10); 
----


$(DL Module contains:
    $(DD 
            $(LINK2 #imshow,imshow)
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
import std.experimental.ndslice;
import std.exception;
import std.conv : to;

import dcv.core.image : Image, ImageFormat, BitDepth, asImage;
import dcv.core.utils : asType;

import dcv.plot.bindings;

/**
Create a plotting figure.

Params:
    title = Title of the window. If none given (default), window is named by "Figure id".

Returns:
    If figure with given title exists already, that figure is returned, 
    otherwise new figure is created and returned.
*/
Figure figure(string title = "")
{
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
            // TODO: figure out smarter window cascading.
            f.move(50, 50);
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
Figure imshow(size_t N, T)(Slice!(N, T*) slice, string title = "")
{
    auto f = figure(title);
    f.draw(slice, ImageFormat.IF_UNASSIGNED);
    f.show();
    return f;
}

/// ditto
Figure imshow(size_t N, T)(Slice!(N, T*) slice, ImageFormat format, string title = "")
{
    auto f = figure(title);
    f.draw(slice, format);
    f.show();
    return f;
}

/**
Run the event loop for each present figure, and wait for key and/or given time.

Params:
    unit = Unit in which time count is given. Same as core.time.Duration unit parameters.
    count = Number of unit ticks to wait for event loop to finish. If left at zero (default), runs indefinitelly.

Returns:
    Ascii value as int of keyboard press, or 0 if timer runs out.
*/
int waitKey(string unit = "msecs")(ulong count = 0)
{
    import std.datetime : StopWatch;

    StopWatch stopwatch;
    stopwatch.start;

    _lastKey = -1;
    auto hiddenLoopCheck = 0;

    while (true)
    {
        if (count && count < mixin("stopwatch.peek." ~ unit))
            break;

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
*/
void imdestroy(string title = "")
{
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
alias KeyPressCallback = void delegate(int key, int scancode, int action, int mods);
/// Character callback function.
alias CharCallback = void delegate(uint key);

/**
Assign key press callback function.
*/
void setKeyPressCallback(KeyPressCallback clbck)
{
    _keyPressCallback = clbck;
}

/**
Assign character input callback function.
*/
void setCharCallback(CharCallback clbck)
{
    _charCallback = clbck;
}

/**
Plotting figure type.
*/
class Figure
{
    /// Mouse button callback function.
    alias MouseCallback = void delegate(Figure figure, int button, int action, int mods);
    /// Cursor movement callback function.
    alias CursorCallback = void delegate(Figure figure, double xpos, double ypos);
    /// Figure closing callback function.
    alias CloseCallback = void delegate(Figure figure);

    private
    {
        GLFWwindow* _glfwWindow = null;

        int _width = 0;
        int _height = 0;
        ubyte[] _data = void;
        string _title = "";

        MouseCallback _mouseCallback = null;
        CursorCallback _cursorCallback = null;
        CloseCallback _closeCallback = null;
    }

    @disable this();

    private void setupCallbacks()
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
    this(string title, int width = 512, int height = 512)
    in
    {
        assert(width > 0);
        assert(height > 0);
    }
    body
    {
        _title = title;
        _width = width;
        _height = height;
        _data = new ubyte[_width * _height * 3];

        setupWindow();
        fitWindow();

        setupCallbacks();
    }

    /// Construct figure window with given title, and fill it with given image.
    this(string title, Image image)
    in
    {
        assert(image !is null);
        assert(!image.empty);
    }
    body
    {
        this(title, cast(int)image.width, cast(int)image.height);
        draw(image);
    }

    /// Construct figure window with given title, and fill it with given image.
    this(size_t N, T)(string title, Slice!(N, T*) slice, ImageFormat format = ImageFormat.IF_UNASSIGNED)
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
    }

    /// Assign mouse callback function.
    Figure setMouseCallback(MouseCallback clbck)
    {
        _mouseCallback = clbck;
        return this;
    }

    Figure setCursorCallback(CursorCallback clbck)
    {
        _cursorCallback = clbck;
        return this;
    }

    Figure setCloseCallback(CloseCallback clbck)
    {
        _closeCallback = clbck;
        return this;
    }

    @property width() inout
    {
        return _width;
    }

    @property height() inout
    {
        return _height;
    }

    @property title() inout
    {
        return _title;
    }

    @property title(inout string newTitle)
    {
        if (_glfwWindow)
        {
            glfwSetWindowTitle(_glfwWindow, toStringz(newTitle));
        }
    }

    /// Show the figure window.
    void show()
    {
        if (_glfwWindow)
            glfwShowWindow(_glfwWindow);
    }

    /// Show the figure window.
    void hide()
    {
        if (_glfwWindow)
            glfwHideWindow(_glfwWindow);
    }

    @property visible() inout
    {
        if (_glfwWindow is null)
            return false;
        return glfwGetWindowAttrib(cast(GLFWwindow*)_glfwWindow, GLFW_VISIBLE) == 1;
    }

    @property position() const
    {
        int x;
        int y;
        glfwGetWindowPos(cast(GLFWwindow*)_glfwWindow, &x, &y);
        return [x, y];
    }

    @property size() const
    {
        int w, h;
        glfwGetWindowSize(cast(GLFWwindow*)_glfwWindow, &w, &h);
        return [w, h];
    }

    /// Clear canvas content of this figure.
    void clear()
    {
        _data[] = cast(ubyte)0;
    }

    /// Move figure window to given position on screen.
    void moveTo(int x, int y)
    {
        glfwSetWindowPos(_glfwWindow, x, y);
    }

    /// ditto
    void moveTo(int[] pos)
    {
        assert(pos.length == 2);
        move(pos[0], pos[1]);
    }

    /// Offset figure window position by given values.
    void move(int x, int y)
    {
        auto p = this.position;
        glfwSetWindowPos(_glfwWindow, p[0] + x, p[1] + y);
    }

    /// ditto
    void move(int[] offset)
    {
        move(offset[0], offset[1]);
    }

    /// Draw image onto figure canvas.
    void draw(Image image)
    {
        Image showImage = adoptImage(image);

        if (_width != showImage.width || _height != showImage.height)
        {
            _width = cast(int)showImage.width;
            _height = cast(int)showImage.height;
            _data = showImage.data.dup;
        }
        else
        {
            assert(_data.length == showImage.data.length);
            _data[] = showImage.data[];
        }

        fitWindow();
    }

    /// Draw slice of image onto figure canvas.
    void draw(size_t N, T)(Slice!(N, T*) slice, ImageFormat format = ImageFormat.IF_UNASSIGNED)
    {
        Slice!(N, ubyte*) showSlice;
        static if (is(T == ubyte))
            showSlice = slice;
        else
            showSlice = slice.asType!ubyte;

        if (format == ImageFormat.IF_UNASSIGNED)
            draw(showSlice.asImage());
        else
            draw(showSlice.asImage(format));
    }

    private void fitWindow()
    {
        glfwSetWindowSize(_glfwWindow, _width, _height);
    }

    private void render()
    {
        glfwMakeContextCurrent(_glfwWindow);

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glDisable(GL_DEPTH_TEST);

        glViewport(0, 0, width, height);

        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();

        glOrtho(0, width, 0, height, 0.1, 1);
        glPixelZoom(1, -1);
        glRasterPos3f(0, height - 1, -0.3);

        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glDrawPixels(_width, _height, GL_RGB, GL_UNSIGNED_BYTE, _data.ptr);

        glFlush();
        glEnable(GL_DEPTH_TEST);

        glfwSwapBuffers(_glfwWindow);
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
    }

    private void defaultCloseCallback(Figure figure)
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

// initialize glfw and global callbacks
static this()
{
    import std.stdio;

    if (!glfwInit())
    {
        throw new Exception("Invalid glfwInit call");
    }

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

private
{
    Figure[] _figures; // book-keeping of each running figure.
    int _lastKey = -1; // last hit key

    KeyPressCallback _keyPressCallback; // global key press callback
    CharCallback _charCallback; // global char callback
}

void keyCallbackWrapper(int mods, int action, int scancode, int key, GLFWwindow* window)
{
    if (_keyPressCallback)
        _keyPressCallback(key, scancode, action, mods);
}

void charCallbackWrapper(uint key, GLFWwindow* window)
{
    if (_charCallback)
        _charCallback(key);
}

void cursorCallbackWrapper(double y, double x, GLFWwindow* window)
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

void mouseCallbackWrapper(int mods, int action, int button, GLFWwindow* window)
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

Image adoptImage(Image image)
{
    import dcv.imgproc.color : yuv2rgb, gray2rgb;

    Image showImage = (image.depth != BitDepth.BD_8) ? image.asType!ubyte : image;

    switch (showImage.format)
    {
    case ImageFormat.IF_RGB_ALPHA:
        showImage = showImage.sliced[0 .. $, 0 .. $, 0 .. 2].asImage(ImageFormat.IF_RGB);
        break;
    case ImageFormat.IF_BGR:
        foreach (e; showImage.sliced.pack!1.byElement)
        {
            auto t = e[0];
            e[0] = e[2];
            e[2] = t;
        }
        break;
    case ImageFormat.IF_BGR_ALPHA:
        foreach (e; showImage.sliced.pack!1.byElement)
        {
            auto t = e[0];
            e[0] = e[2];
            e[2] = t;
        }
        showImage = showImage.sliced[0 .. $, 0 .. $, 0 .. 2].asImage(ImageFormat.IF_RGB);
        break;
    case ImageFormat.IF_YUV:
        showImage = showImage.sliced.yuv2rgb!ubyte.asImage(ImageFormat.IF_RGB);
        break;
    case ImageFormat.IF_MONO:
        showImage = showImage.sliced.reshape(image.height, image.width)
            .gray2rgb!ubyte.asImage(ImageFormat.IF_RGB);
        break;
    default:
        break;
    }
    return showImage;
}
