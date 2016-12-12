module dcv.plot.bindings.glfw;

struct GLFWwindow
{
}

struct GLFWmonitor
{
}

/*************************************************************************
 * GLFW API tokens
 *************************************************************************/

immutable GLFW_VERSION_MAJOR = 3;
immutable GLFW_VERSION_MINOR = 1;
immutable GLFW_VERSION_REVISION = 2;
immutable GLFW_RELEASE = 0;
immutable GLFW_PRESS = 1;
immutable GLFW_REPEAT = 2;

immutable GLFW_KEY_UNKNOWN = -1;

immutable GLFW_KEY_SPACE = 32;
immutable GLFW_KEY_APOSTROPHE = 39; /* ' */
immutable GLFW_KEY_COMMA = 44; /* , */
immutable GLFW_KEY_MINUS = 45; /* - */
immutable GLFW_KEY_PERIOD = 46; /* . */
immutable GLFW_KEY_SLASH = 47; /* / */
immutable GLFW_KEY_0 = 48;
immutable GLFW_KEY_1 = 49;
immutable GLFW_KEY_2 = 50;
immutable GLFW_KEY_3 = 51;
immutable GLFW_KEY_4 = 52;
immutable GLFW_KEY_5 = 53;
immutable GLFW_KEY_6 = 54;
immutable GLFW_KEY_7 = 55;
immutable GLFW_KEY_8 = 56;
immutable GLFW_KEY_9 = 57;
immutable GLFW_KEY_SEMICOLON = 59; /* ; */
immutable GLFW_KEY_EQUAL = 61; /* = */
immutable GLFW_KEY_A = 65;
immutable GLFW_KEY_B = 66;
immutable GLFW_KEY_C = 67;
immutable GLFW_KEY_D = 68;
immutable GLFW_KEY_E = 69;
immutable GLFW_KEY_F = 70;
immutable GLFW_KEY_G = 71;
immutable GLFW_KEY_H = 72;
immutable GLFW_KEY_I = 73;
immutable GLFW_KEY_J = 74;
immutable GLFW_KEY_K = 75;
immutable GLFW_KEY_L = 76;
immutable GLFW_KEY_M = 77;
immutable GLFW_KEY_N = 78;
immutable GLFW_KEY_O = 79;
immutable GLFW_KEY_P = 80;
immutable GLFW_KEY_Q = 81;
immutable GLFW_KEY_R = 82;
immutable GLFW_KEY_S = 83;
immutable GLFW_KEY_T = 84;
immutable GLFW_KEY_U = 85;
immutable GLFW_KEY_V = 86;
immutable GLFW_KEY_W = 87;
immutable GLFW_KEY_X = 88;
immutable GLFW_KEY_Y = 89;
immutable GLFW_KEY_Z = 90;
immutable GLFW_KEY_LEFT_BRACKET = 91; /* [ */
immutable GLFW_KEY_BACKSLASH = 92; /* \ */
immutable GLFW_KEY_RIGHT_BRACKET = 93; /* ] */
immutable GLFW_KEY_GRAVE_ACCENT = 96; /* ` */
immutable GLFW_KEY_WORLD_1 = 161; /* non-US #1 */
immutable GLFW_KEY_WORLD_2 = 162; /* non-US #2 */

immutable GLFW_KEY_ESCAPE = 256;
immutable GLFW_KEY_ENTER = 257;
immutable GLFW_KEY_TAB = 258;
immutable GLFW_KEY_BACKSPACE = 259;
immutable GLFW_KEY_INSERT = 260;
immutable GLFW_KEY_DELETE = 261;
immutable GLFW_KEY_RIGHT = 262;
immutable GLFW_KEY_LEFT = 263;
immutable GLFW_KEY_DOWN = 264;
immutable GLFW_KEY_UP = 265;
immutable GLFW_KEY_PAGE_UP = 266;
immutable GLFW_KEY_PAGE_DOWN = 267;
immutable GLFW_KEY_HOME = 268;
immutable GLFW_KEY_END = 269;
immutable GLFW_KEY_CAPS_LOCK = 280;
immutable GLFW_KEY_SCROLL_LOCK = 281;
immutable GLFW_KEY_NUM_LOCK = 282;
immutable GLFW_KEY_PRINT_SCREEN = 283;
immutable GLFW_KEY_PAUSE = 284;
immutable GLFW_KEY_F1 = 290;
immutable GLFW_KEY_F2 = 291;
immutable GLFW_KEY_F3 = 292;
immutable GLFW_KEY_F4 = 293;
immutable GLFW_KEY_F5 = 294;
immutable GLFW_KEY_F6 = 295;
immutable GLFW_KEY_F7 = 296;
immutable GLFW_KEY_F8 = 297;
immutable GLFW_KEY_F9 = 298;
immutable GLFW_KEY_F10 = 299;
immutable GLFW_KEY_F11 = 300;
immutable GLFW_KEY_F12 = 301;
immutable GLFW_KEY_F13 = 302;
immutable GLFW_KEY_F14 = 303;
immutable GLFW_KEY_F15 = 304;
immutable GLFW_KEY_F16 = 305;
immutable GLFW_KEY_F17 = 306;
immutable GLFW_KEY_F18 = 307;
immutable GLFW_KEY_F19 = 308;
immutable GLFW_KEY_F20 = 309;
immutable GLFW_KEY_F21 = 310;
immutable GLFW_KEY_F22 = 311;
immutable GLFW_KEY_F23 = 312;
immutable GLFW_KEY_F24 = 313;
immutable GLFW_KEY_F25 = 314;
immutable GLFW_KEY_KP_0 = 320;
immutable GLFW_KEY_KP_1 = 321;
immutable GLFW_KEY_KP_2 = 322;
immutable GLFW_KEY_KP_3 = 323;
immutable GLFW_KEY_KP_4 = 324;
immutable GLFW_KEY_KP_5 = 325;
immutable GLFW_KEY_KP_6 = 326;
immutable GLFW_KEY_KP_7 = 327;
immutable GLFW_KEY_KP_8 = 328;
immutable GLFW_KEY_KP_9 = 329;
immutable GLFW_KEY_KP_DECIMAL = 330;
immutable GLFW_KEY_KP_DIVIDE = 331;
immutable GLFW_KEY_KP_MULTIPLY = 332;
immutable GLFW_KEY_KP_SUBTRACT = 333;
immutable GLFW_KEY_KP_ADD = 334;
immutable GLFW_KEY_KP_ENTER = 335;
immutable GLFW_KEY_KP_EQUAL = 336;
immutable GLFW_KEY_LEFT_SHIFT = 340;
immutable GLFW_KEY_LEFT_CONTROL = 341;
immutable GLFW_KEY_LEFT_ALT = 342;
immutable GLFW_KEY_LEFT_SUPER = 343;
immutable GLFW_KEY_RIGHT_SHIFT = 344;
immutable GLFW_KEY_RIGHT_CONTROL = 345;
immutable GLFW_KEY_RIGHT_ALT = 346;
immutable GLFW_KEY_RIGHT_SUPER = 347;
immutable GLFW_KEY_MENU = 348;
immutable GLFW_KEY_LAST = GLFW_KEY_MENU;

immutable GLFW_MOD_SHIFT = 0x0001;
immutable GLFW_MOD_CONTROL = 0x0002;
immutable GLFW_MOD_ALT = 0x0004;
immutable GLFW_MOD_SUPER = 0x0008;

immutable GLFW_MOUSE_BUTTON_1 = 0;
immutable GLFW_MOUSE_BUTTON_2 = 1;
immutable GLFW_MOUSE_BUTTON_3 = 2;
immutable GLFW_MOUSE_BUTTON_4 = 3;
immutable GLFW_MOUSE_BUTTON_5 = 4;
immutable GLFW_MOUSE_BUTTON_6 = 5;
immutable GLFW_MOUSE_BUTTON_7 = 6;
immutable GLFW_MOUSE_BUTTON_8 = 7;
immutable GLFW_MOUSE_BUTTON_LAST = GLFW_MOUSE_BUTTON_8;
immutable GLFW_MOUSE_BUTTON_LEFT = GLFW_MOUSE_BUTTON_1;
immutable GLFW_MOUSE_BUTTON_RIGHT = GLFW_MOUSE_BUTTON_2;
immutable GLFW_MOUSE_BUTTON_MIDDLE = GLFW_MOUSE_BUTTON_3;

immutable GLFW_NOT_INITIALIZED = 0x00010001;
immutable GLFW_NO_CURRENT_CONTEXT = 0x00010002;
immutable GLFW_INVALID_ENUM = 0x00010003;
immutable GLFW_INVALID_VALUE = 0x00010004;
immutable GLFW_OUT_OF_MEMORY = 0x00010005;
immutable GLFW_API_UNAVAILABLE = 0x00010006;
immutable GLFW_VERSION_UNAVAILABLE = 0x00010007;
immutable GLFW_PLATFORM_ERROR = 0x00010008;
immutable GLFW_FORMAT_UNAVAILABLE = 0x00010009;

immutable GLFW_FOCUSED = 0x00020001;
immutable GLFW_ICONIFIED = 0x00020002;
immutable GLFW_RESIZABLE = 0x00020003;
immutable GLFW_VISIBLE = 0x00020004;
immutable GLFW_DECORATED = 0x00020005;
immutable GLFW_AUTO_ICONIFY = 0x00020006;
immutable GLFW_FLOATING = 0x00020007;

immutable GLFW_RED_BITS = 0x00021001;
immutable GLFW_GREEN_BITS = 0x00021002;
immutable GLFW_BLUE_BITS = 0x00021003;
immutable GLFW_ALPHA_BITS = 0x00021004;
immutable GLFW_DEPTH_BITS = 0x00021005;
immutable GLFW_STENCIL_BITS = 0x00021006;
immutable GLFW_ACCUM_RED_BITS = 0x00021007;
immutable GLFW_ACCUM_GREEN_BITS = 0x00021008;
immutable GLFW_ACCUM_BLUE_BITS = 0x00021009;
immutable GLFW_ACCUM_ALPHA_BITS = 0x0002100A;
immutable GLFW_AUX_BUFFERS = 0x0002100B;
immutable GLFW_STEREO = 0x0002100C;
immutable GLFW_SAMPLES = 0x0002100D;
immutable GLFW_SRGB_CAPABLE = 0x0002100E;
immutable GLFW_REFRESH_RATE = 0x0002100F;
immutable GLFW_DOUBLEBUFFER = 0x00021010;

immutable GLFW_CLIENT_API = 0x00022001;
immutable GLFW_CONTEXT_VERSION_MAJOR = 0x00022002;
immutable GLFW_CONTEXT_VERSION_MINOR = 0x00022003;
immutable GLFW_CONTEXT_REVISION = 0x00022004;
immutable GLFW_CONTEXT_ROBUSTNESS = 0x00022005;
immutable GLFW_OPENGL_FORWARD_COMPAT = 0x00022006;
immutable GLFW_OPENGL_DEBUG_CONTEXT = 0x00022007;
immutable GLFW_OPENGL_PROFILE = 0x00022008;
immutable GLFW_CONTEXT_RELEASE_BEHAVIOR = 0x00022009;

immutable GLFW_OPENGL_API = 0x00030001;
immutable GLFW_OPENGL_ES_API = 0x00030002;

immutable GLFW_NO_ROBUSTNESS = 0;
immutable GLFW_NO_RESET_NOTIFICATION = 0x00031001;
immutable GLFW_LOSE_CONTEXT_ON_RESET = 0x00031002;

immutable GLFW_OPENGL_ANY_PROFILE = 0;
immutable GLFW_OPENGL_CORE_PROFILE = 0x00032001;
immutable GLFW_OPENGL_COMPAT_PROFILE = 0x00032002;

immutable GLFW_CURSOR = 0x00033001;
immutable GLFW_STICKY_KEYS = 0x00033002;
immutable GLFW_STICKY_MOUSE_BUTTONS = 0x00033003;

immutable GLFW_CURSOR_NORMAL = 0x00034001;
immutable GLFW_CURSOR_HIDDEN = 0x00034002;
immutable GLFW_CURSOR_DISABLED = 0x00034003;

immutable GLFW_ANY_RELEASE_BEHAVIOR = 0;
immutable GLFW_RELEASE_BEHAVIOR_FLUSH = 0x00035001;
immutable GLFW_RELEASE_BEHAVIOR_NONE = 0x00035002;
immutable GLFW_ARROW_CURSOR = 0x00036001;
immutable GLFW_IBEAM_CURSOR = 0x00036002;
immutable GLFW_CROSSHAIR_CURSOR = 0x00036003;
immutable GLFW_HAND_CURSOR = 0x00036004;
immutable GLFW_HRESIZE_CURSOR = 0x00036005;
immutable GLFW_VRESIZE_CURSOR = 0x00036006;

immutable GLFW_CONNECTED = 0x00040001;
immutable GLFW_DISCONNECTED = 0x00040002;

immutable GLFW_DONT_CARE = -1;

/*************************************************************************
 * GLFW API types
 *************************************************************************/

alias GLFWcharfun = void function(uint key, GLFWwindow* window);
alias GLFWcharmodsfun = void function(int mods, uint key, GLFWwindow*);
alias GLFWkeyfun = void function(int mods, int action, int scancode, int key, GLFWwindow* window);
alias GLFWwindowclosefun = void function(GLFWwindow* window);
alias GLFWmousebuttonfun = void function(int mods, int action, int button, GLFWwindow*);
alias GLFWcursorposfun = void function(double ypos, double xpos, GLFWwindow*);
alias GLFWwindowposfun = void function(int ypos, int xpos, GLFWwindow*);
alias GLFWwindowsizefun = void function(int height, int width, GLFWwindow* window);

extern (C)
{
    /*************************************************************************
     * GLFW functions definitions.
     *************************************************************************/
    int glfwInit();
    GLFWwindow* glfwCreateWindow(int width, int height, const char* title, GLFWmonitor* monitor, GLFWwindow* share);
    void glfwShowWindow(GLFWwindow* window);
    void glfwHideWindow(GLFWwindow* window);
    void glfwDestroyWindow(GLFWwindow* window);
    void glfwTerminate();
    void glfwMakeContextCurrent(GLFWwindow* window);
    void glfwSwapBuffers(GLFWwindow* window);
    void glfwPollEvents();
    void glfwWaitEvents();
    int glfwWindowShouldClose(GLFWwindow* window);
    void glfwSetWindowTitle(GLFWwindow* window, const char* title);
    int glfwGetWindowAttrib(GLFWwindow* window, int attrib);
    void glfwSetWindowPos(GLFWwindow* window, int xpos, int ypos);
    void glfwGetWindowPos(GLFWwindow* window, int* xpos, int* ypos);
    void glfwSetInputMode(GLFWwindow* window, int mode, int value);
    int glfwGetInputMode(GLFWwindow* window, int mode);
    void glfwGetWindowSize(GLFWwindow* window, int* width, int* height);
    void glfwSetWindowSize(GLFWwindow* window, int width, int height);
    void glfwWindowHint(int target, int hint);
    void glfwGetFramebufferSize (GLFWwindow * window, int *width, int *height);

    GLFWcharfun glfwSetCharCallback(GLFWwindow* window, GLFWcharfun cbfun);
    GLFWcharmodsfun glfwSetCharModsCallback(GLFWwindow* window, GLFWcharmodsfun cbfun);
    GLFWkeyfun glfwSetKeyCallback(GLFWwindow* window, GLFWkeyfun cbfun);
    GLFWwindowclosefun glfwSetWindowCloseCallback(GLFWwindow* window, GLFWwindowclosefun cbfun);
    GLFWmousebuttonfun glfwSetMouseButtonCallback(GLFWwindow* window, GLFWmousebuttonfun cbfun);
    GLFWcursorposfun glfwSetCursorPosCallback(GLFWwindow* window, GLFWcursorposfun cbfun);
    GLFWwindowposfun glfwSetWindowPosCallback(GLFWwindow* window, GLFWwindowposfun cbfun);
    GLFWwindowsizefun glfwSetWindowSizeCallback(GLFWwindow* window, GLFWwindowsizefun cbfun);
}
