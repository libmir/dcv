module dcv.plot.bindings.gl;


alias uint GLenum;
alias ubyte GLboolean;
alias uint GLbitfield;
alias void GLvoid;
alias byte GLbyte; /* 1-byte signed */
alias short GLshort; /* 2-byte signed */
alias int GLint; /* 4-byte signed */
alias ubyte GLubyte; /* 1-byte u*/
alias ushort GLushort; /* 2-byte u*/
alias uint GLuint; /* 4-byte u*/
alias int GLsizei; /* 4-byte signed */
alias float GLfloat; /* single precision float */
alias float GLclampf; /* single precision float in [0,1] */
alias double GLdouble; /* double precision float */
alias double GLclampd; /* double precision float in [0,1] */

immutable GL_FALSE = 0;
immutable GL_TRUE = 1;
immutable GL_BYTE = 0x1400;
immutable GL_UNSIGNED_BYTE = 0x1401;
immutable GL_SHORT = 0x1402;
immutable GL_UNSIGNED_SHORT = 0x1403;
immutable GL_INT = 0x1404;
immutable GL_UNSIGNED_INT = 0x1405;
immutable GL_FLOAT = 0x1406;
immutable GL_2_BYTES = 0x1407;
immutable GL_3_BYTES = 0x1408;
immutable GL_4_BYTES = 0x1409;
immutable GL_DOUBLE = 0x140A;

/* Primitives */
immutable GL_POINTS = 0x0000;
immutable GL_LINES = 0x0001;
immutable GL_LINE_LOOP = 0x0002;
immutable GL_LINE_STRIP = 0x0003;
immutable GL_TRIANGLES = 0x0004;
immutable GL_TRIANGLE_STRIP = 0x0005;
immutable GL_TRIANGLE_FAN = 0x0006;
immutable GL_QUADS = 0x0007;
immutable GL_QUAD_STRIP = 0x0008;
immutable GL_POLYGON = 0x0009;

/* Vertex Arrays */
immutable GL_VERTEX_ARRAY = 0x8074;
immutable GL_NORMAL_ARRAY = 0x8075;
immutable GL_COLOR_ARRAY = 0x8076;
immutable GL_INDEX_ARRAY = 0x8077;
immutable GL_TEXTURE_COORD_ARRAY = 0x8078;
immutable GL_EDGE_FLAG_ARRAY = 0x8079;
immutable GL_VERTEX_ARRAY_SIZE = 0x807A;
immutable GL_VERTEX_ARRAY_TYPE = 0x807B;
immutable GL_VERTEX_ARRAY_STRIDE = 0x807C;
immutable GL_NORMAL_ARRAY_TYPE = 0x807E;
immutable GL_NORMAL_ARRAY_STRIDE = 0x807F;
immutable GL_COLOR_ARRAY_SIZE = 0x8081;
immutable GL_COLOR_ARRAY_TYPE = 0x8082;
immutable GL_COLOR_ARRAY_STRIDE = 0x8083;
immutable GL_INDEX_ARRAY_TYPE = 0x8085;
immutable GL_INDEX_ARRAY_STRIDE = 0x8086;
immutable GL_TEXTURE_COORD_ARRAY_SIZE = 0x8088;
immutable GL_TEXTURE_COORD_ARRAY_TYPE = 0x8089;
immutable GL_TEXTURE_COORD_ARRAY_STRIDE = 0x808A;
immutable GL_EDGE_FLAG_ARRAY_STRIDE = 0x808C;
immutable GL_VERTEX_ARRAY_POINTER = 0x808E;
immutable GL_NORMAL_ARRAY_POINTER = 0x808F;
immutable GL_COLOR_ARRAY_POINTER = 0x8090;
immutable GL_INDEX_ARRAY_POINTER = 0x8091;
immutable GL_TEXTURE_COORD_ARRAY_POINTER = 0x8092;
immutable GL_EDGE_FLAG_ARRAY_POINTER = 0x8093;
immutable GL_V2F = 0x2A20;
immutable GL_V3F = 0x2A21;
immutable GL_C4UB_V2F = 0x2A22;
immutable GL_C4UB_V3F = 0x2A23;
immutable GL_C3F_V3F = 0x2A24;
immutable GL_N3F_V3F = 0x2A25;
immutable GL_C4F_N3F_V3F = 0x2A26;
immutable GL_T2F_V3F = 0x2A27;
immutable GL_T4F_V4F = 0x2A28;
immutable GL_T2F_C4UB_V3F = 0x2A29;
immutable GL_T2F_C3F_V3F = 0x2A2A;
immutable GL_T2F_N3F_V3F = 0x2A2B;
immutable GL_T2F_C4F_N3F_V3F = 0x2A2C;
immutable GL_T4F_C4F_N3F_V4F = 0x2A2D;

/* Matrix Mode */

immutable GL_MATRIX_MODE = 0x0BA0;
immutable GL_MODELVIEW = 0x1700;
immutable GL_PROJECTION = 0x1701;
immutable GL_TEXTURE = 0x1702;

/* Points */

immutable GL_POINT_SMOOTH = 0x0B10;
immutable GL_POINT_SIZE = 0x0B11;
immutable GL_POINT_SIZE_GRANULARITY = 0x0B13;
immutable GL_POINT_SIZE_RANGE = 0x0B12;

/* Lines */

immutable GL_LINE_SMOOTH = 0x0B20;
immutable GL_LINE_STIPPLE = 0x0B24;
immutable GL_LINE_STIPPLE_PATTERN = 0x0B25;
immutable GL_LINE_STIPPLE_REPEAT = 0x0B26;
immutable GL_LINE_WIDTH = 0x0B21;
immutable GL_LINE_WIDTH_GRANULARITY = 0x0B23;
immutable GL_LINE_WIDTH_RANGE = 0x0B22;

/* Polygons */
immutable GL_POINT = 0x1B00;
immutable GL_LINE = 0x1B01;
immutable GL_FILL = 0x1B02;
immutable GL_CW = 0x0900;
immutable GL_CCW = 0x0901;
immutable GL_FRONT = 0x0404;
immutable GL_BACK = 0x0405;
immutable GL_POLYGON_MODE = 0x0B40;
immutable GL_POLYGON_SMOOTH = 0x0B41;
immutable GL_POLYGON_STIPPLE = 0x0B42;
immutable GL_EDGE_FLAG = 0x0B43;
immutable GL_CULL_FACE = 0x0B44;
immutable GL_CULL_FACE_MODE = 0x0B45;
immutable GL_FRONT_FACE = 0x0B46;
immutable GL_POLYGON_OFFSET_FACTOR = 0x8038;
immutable GL_POLYGON_OFFSET_UNITS = 0x2A00;
immutable GL_POLYGON_OFFSET_POINT = 0x2A01;
immutable GL_POLYGON_OFFSET_LINE = 0x2A02;
immutable GL_POLYGON_OFFSET_FILL = 0x8037;

/* Display Lists */
immutable GL_COMPILE = 0x1300;
immutable GL_COMPILE_AND_EXECUTE = 0x1301;
immutable GL_LIST_BASE = 0x0B32;
immutable GL_LIST_INDEX = 0x0B33;
immutable GL_LIST_MODE = 0x0B30;

/* Depth buffer */
immutable GL_NEVER = 0x0200;
immutable GL_LESS = 0x0201;
immutable GL_EQUAL = 0x0202;
immutable GL_LEQUAL = 0x0203;
immutable GL_GREATER = 0x0204;
immutable GL_NOTEQUAL = 0x0205;
immutable GL_GEQUAL = 0x0206;
immutable GL_ALWAYS = 0x0207;
immutable GL_DEPTH_TEST = 0x0B71;
immutable GL_DEPTH_BITS = 0x0D56;
immutable GL_DEPTH_CLEAR_VALUE = 0x0B73;
immutable GL_DEPTH_FUNC = 0x0B74;
immutable GL_DEPTH_RANGE = 0x0B70;
immutable GL_DEPTH_WRITEMASK = 0x0B72;
immutable GL_DEPTH_COMPONENT = 0x1902;

/* Lighting */
immutable GL_LIGHTING = 0x0B50;
immutable GL_LIGHT0 = 0x4000;
immutable GL_LIGHT1 = 0x4001;
immutable GL_LIGHT2 = 0x4002;
immutable GL_LIGHT3 = 0x4003;
immutable GL_LIGHT4 = 0x4004;
immutable GL_LIGHT5 = 0x4005;
immutable GL_LIGHT6 = 0x4006;
immutable GL_LIGHT7 = 0x4007;
immutable GL_SPOT_EXPONENT = 0x1205;
immutable GL_SPOT_CUTOFF = 0x1206;
immutable GL_CONSTANT_ATTENUATION = 0x1207;
immutable GL_LINEAR_ATTENUATION = 0x1208;
immutable GL_QUADRATIC_ATTENUATION = 0x1209;
immutable GL_AMBIENT = 0x1200;
immutable GL_DIFFUSE = 0x1201;
immutable GL_SPECULAR = 0x1202;
immutable GL_SHININESS = 0x1601;
immutable GL_EMISSION = 0x1600;
immutable GL_POSITION = 0x1203;
immutable GL_SPOT_DIRECTION = 0x1204;
immutable GL_AMBIENT_AND_DIFFUSE = 0x1602;
immutable GL_COLOR_INDEXES = 0x1603;
immutable GL_LIGHT_MODEL_TWO_SIDE = 0x0B52;
immutable GL_LIGHT_MODEL_LOCAL_VIEWER = 0x0B51;
immutable GL_LIGHT_MODEL_AMBIENT = 0x0B53;
immutable GL_FRONT_AND_BACK = 0x0408;
immutable GL_SHADE_MODEL = 0x0B54;
immutable GL_FLAT = 0x1D00;
immutable GL_SMOOTH = 0x1D01;
immutable GL_COLOR_MATERIAL = 0x0B57;
immutable GL_COLOR_MATERIAL_FACE = 0x0B55;
immutable GL_COLOR_MATERIAL_PARAMETER = 0x0B56;
immutable GL_NORMALIZE = 0x0BA1;

/* User clipping planes */
immutable GL_CLIP_PLANE0 = 0x3000;
immutable GL_CLIP_PLANE1 = 0x3001;
immutable GL_CLIP_PLANE2 = 0x3002;
immutable GL_CLIP_PLANE3 = 0x3003;
immutable GL_CLIP_PLANE4 = 0x3004;
immutable GL_CLIP_PLANE5 = 0x3005;

/* Accumulation buffer */
immutable GL_ACCUM_RED_BITS = 0x0D58;
immutable GL_ACCUM_GREEN_BITS = 0x0D59;
immutable GL_ACCUM_BLUE_BITS = 0x0D5A;
immutable GL_ACCUM_ALPHA_BITS = 0x0D5B;
immutable GL_ACCUM_CLEAR_VALUE = 0x0B80;
immutable GL_ACCUM = 0x0100;
immutable GL_ADD = 0x0104;
immutable GL_LOAD = 0x0101;
immutable GL_MULT = 0x0103;
immutable GL_RETURN = 0x0102;

/* Alpha testing */
immutable GL_ALPHA_TEST = 0x0BC0;
immutable GL_ALPHA_TEST_REF = 0x0BC2;
immutable GL_ALPHA_TEST_FUNC = 0x0BC1;

/* Blending */
immutable GL_BLEND = 0x0BE2;
immutable GL_BLEND_SRC = 0x0BE1;
immutable GL_BLEND_DST = 0x0BE0;
immutable GL_ZERO = 0;
immutable GL_ONE = 1;
immutable GL_SRC_COLOR = 0x0300;
immutable GL_ONE_MINUS_SRC_COLOR = 0x0301;
immutable GL_SRC_ALPHA = 0x0302;
immutable GL_ONE_MINUS_SRC_ALPHA = 0x0303;
immutable GL_DST_ALPHA = 0x0304;
immutable GL_ONE_MINUS_DST_ALPHA = 0x0305;
immutable GL_DST_COLOR = 0x0306;
immutable GL_ONE_MINUS_DST_COLOR = 0x0307;
immutable GL_SRC_ALPHA_SATURATE = 0x0308;

/* Render Mode */
immutable GL_FEEDBACK = 0x1C01;
immutable GL_RENDER = 0x1C00;
immutable GL_SELECT = 0x1C02;

/* Feedback */
immutable GL_2D = 0x0600;
immutable GL_3D = 0x0601;
immutable GL_3D_COLOR = 0x0602;
immutable GL_3D_COLOR_TEXTURE = 0x0603;
immutable GL_4D_COLOR_TEXTURE = 0x0604;
immutable GL_POINT_TOKEN = 0x0701;
immutable GL_LINE_TOKEN = 0x0702;
immutable GL_LINE_RESET_TOKEN = 0x0707;
immutable GL_POLYGON_TOKEN = 0x0703;
immutable GL_BITMAP_TOKEN = 0x0704;
immutable GL_DRAW_PIXEL_TOKEN = 0x0705;
immutable GL_COPY_PIXEL_TOKEN = 0x0706;
immutable GL_PASS_THROUGH_TOKEN = 0x0700;
immutable GL_FEEDBACK_BUFFER_POINTER = 0x0DF0;
immutable GL_FEEDBACK_BUFFER_SIZE = 0x0DF1;
immutable GL_FEEDBACK_BUFFER_TYPE = 0x0DF2;

/* Selection */
immutable GL_SELECTION_BUFFER_POINTER = 0x0DF3;
immutable GL_SELECTION_BUFFER_SIZE = 0x0DF4;

/* Fog */
immutable GL_FOG = 0x0B60;
immutable GL_FOG_MODE = 0x0B65;
immutable GL_FOG_DENSITY = 0x0B62;
immutable GL_FOG_COLOR = 0x0B66;
immutable GL_FOG_INDEX = 0x0B61;
immutable GL_FOG_START = 0x0B63;
immutable GL_FOG_END = 0x0B64;
immutable GL_LINEAR = 0x2601;
immutable GL_EXP = 0x0800;
immutable GL_EXP2 = 0x0801;

/* Logic Ops */
immutable GL_LOGIC_OP = 0x0BF1;
immutable GL_INDEX_LOGIC_OP = 0x0BF1;
immutable GL_COLOR_LOGIC_OP = 0x0BF2;
immutable GL_LOGIC_OP_MODE = 0x0BF0;
immutable GL_CLEAR = 0x1500;
immutable GL_SET = 0x150F;
immutable GL_COPY = 0x1503;
immutable GL_COPY_INVERTED = 0x150C;
immutable GL_NOOP = 0x1505;
immutable GL_INVERT = 0x150A;
immutable GL_AND = 0x1501;
immutable GL_NAND = 0x150E;
immutable GL_OR = 0x1507;
immutable GL_NOR = 0x1508;
immutable GL_XOR = 0x1506;
immutable GL_EQUIV = 0x1509;
immutable GL_AND_REVERSE = 0x1502;
immutable GL_AND_INVERTED = 0x1504;
immutable GL_OR_REVERSE = 0x150B;
immutable GL_OR_INVERTED = 0x150D;

/* Stencil */
immutable GL_STENCIL_BITS = 0x0D57;
immutable GL_STENCIL_TEST = 0x0B90;
immutable GL_STENCIL_CLEAR_VALUE = 0x0B91;
immutable GL_STENCIL_FUNC = 0x0B92;
immutable GL_STENCIL_VALUE_MASK = 0x0B93;
immutable GL_STENCIL_FAIL = 0x0B94;
immutable GL_STENCIL_PASS_DEPTH_FAIL = 0x0B95;
immutable GL_STENCIL_PASS_DEPTH_PASS = 0x0B96;
immutable GL_STENCIL_REF = 0x0B97;
immutable GL_STENCIL_WRITEMASK = 0x0B98;
immutable GL_STENCIL_INDEX = 0x1901;
immutable GL_KEEP = 0x1E00;
immutable GL_REPLACE = 0x1E01;
immutable GL_INCR = 0x1E02;
immutable GL_DECR = 0x1E03;

/* Buffers, Pixel Drawing/Reading */
immutable GL_NONE = 0;
immutable GL_LEFT = 0x0406;
immutable GL_RIGHT = 0x0407;
immutable GL_FRONT_LEFT = 0x0400;
immutable GL_FRONT_RIGHT = 0x0401;
immutable GL_BACK_LEFT = 0x0402;
immutable GL_BACK_RIGHT = 0x0403;
immutable GL_AUX0 = 0x0409;
immutable GL_AUX1 = 0x040A;
immutable GL_AUX2 = 0x040B;
immutable GL_AUX3 = 0x040C;
immutable GL_COLOR_INDEX = 0x1900;
immutable GL_RED = 0x1903;
immutable GL_GREEN = 0x1904;
immutable GL_BLUE = 0x1905;
immutable GL_ALPHA = 0x1906;
immutable GL_LUMINANCE = 0x1909;
immutable GL_LUMINANCE_ALPHA = 0x190A;
immutable GL_ALPHA_BITS = 0x0D55;
immutable GL_RED_BITS = 0x0D52;
immutable GL_GREEN_BITS = 0x0D53;
immutable GL_BLUE_BITS = 0x0D54;
immutable GL_INDEX_BITS = 0x0D51;
immutable GL_SUBPIXEL_BITS = 0x0D50;
immutable GL_AUX_BUFFERS = 0x0C00;
immutable GL_READ_BUFFER = 0x0C02;
immutable GL_DRAW_BUFFER = 0x0C01;
immutable GL_DOUBLEBUFFER = 0x0C32;
immutable GL_STEREO = 0x0C33;
immutable GL_BITMAP = 0x1A00;
immutable GL_COLOR = 0x1800;
immutable GL_DEPTH = 0x1801;
immutable GL_STENCIL = 0x1802;
immutable GL_DITHER = 0x0BD0;
immutable GL_RGB = 0x1907;
immutable GL_RGBA = 0x1908;

/* Implementation limits */
immutable GL_MAX_LIST_NESTING = 0x0B31;
immutable GL_MAX_EVAL_ORDER = 0x0D30;
immutable GL_MAX_LIGHTS = 0x0D31;
immutable GL_MAX_CLIP_PLANES = 0x0D32;
immutable GL_MAX_TEXTURE_SIZE = 0x0D33;
immutable GL_MAX_PIXEL_MAP_TABLE = 0x0D34;
immutable GL_MAX_ATTRIB_STACK_DEPTH = 0x0D35;
immutable GL_MAX_MODELVIEW_STACK_DEPTH = 0x0D36;
immutable GL_MAX_NAME_STACK_DEPTH = 0x0D37;
immutable GL_MAX_PROJECTION_STACK_DEPTH = 0x0D38;
immutable GL_MAX_TEXTURE_STACK_DEPTH = 0x0D39;
immutable GL_MAX_VIEWPORT_DIMS = 0x0D3A;
immutable GL_MAX_CLIENT_ATTRIB_STACK_DEPTH = 0x0D3B;

/* Gets */
immutable GL_ATTRIB_STACK_DEPTH = 0x0BB0;
immutable GL_CLIENT_ATTRIB_STACK_DEPTH = 0x0BB1;
immutable GL_COLOR_CLEAR_VALUE = 0x0C22;
immutable GL_COLOR_WRITEMASK = 0x0C23;
immutable GL_CURRENT_INDEX = 0x0B01;
immutable GL_CURRENT_COLOR = 0x0B00;
immutable GL_CURRENT_NORMAL = 0x0B02;
immutable GL_CURRENT_RASTER_COLOR = 0x0B04;
immutable GL_CURRENT_RASTER_DISTANCE = 0x0B09;
immutable GL_CURRENT_RASTER_INDEX = 0x0B05;
immutable GL_CURRENT_RASTER_POSITION = 0x0B07;
immutable GL_CURRENT_RASTER_TEXTURE_COORDS = 0x0B06;
immutable GL_CURRENT_RASTER_POSITION_VALID = 0x0B08;
immutable GL_CURRENT_TEXTURE_COORDS = 0x0B03;
immutable GL_INDEX_CLEAR_VALUE = 0x0C20;
immutable GL_INDEX_MODE = 0x0C30;
immutable GL_INDEX_WRITEMASK = 0x0C21;
immutable GL_MODELVIEW_MATRIX = 0x0BA6;
immutable GL_MODELVIEW_STACK_DEPTH = 0x0BA3;
immutable GL_NAME_STACK_DEPTH = 0x0D70;
immutable GL_PROJECTION_MATRIX = 0x0BA7;
immutable GL_PROJECTION_STACK_DEPTH = 0x0BA4;
immutable GL_RENDER_MODE = 0x0C40;
immutable GL_RGBA_MODE = 0x0C31;
immutable GL_TEXTURE_MATRIX = 0x0BA8;
immutable GL_TEXTURE_STACK_DEPTH = 0x0BA5;
immutable GL_VIEWPORT = 0x0BA2;

/* Evaluators */
immutable GL_AUTO_NORMAL = 0x0D80;
immutable GL_MAP1_COLOR_4 = 0x0D90;
immutable GL_MAP1_INDEX = 0x0D91;
immutable GL_MAP1_NORMAL = 0x0D92;
immutable GL_MAP1_TEXTURE_COORD_1 = 0x0D93;
immutable GL_MAP1_TEXTURE_COORD_2 = 0x0D94;
immutable GL_MAP1_TEXTURE_COORD_3 = 0x0D95;
immutable GL_MAP1_TEXTURE_COORD_4 = 0x0D96;
immutable GL_MAP1_VERTEX_3 = 0x0D97;
immutable GL_MAP1_VERTEX_4 = 0x0D98;
immutable GL_MAP2_COLOR_4 = 0x0DB0;
immutable GL_MAP2_INDEX = 0x0DB1;
immutable GL_MAP2_NORMAL = 0x0DB2;
immutable GL_MAP2_TEXTURE_COORD_1 = 0x0DB3;
immutable GL_MAP2_TEXTURE_COORD_2 = 0x0DB4;
immutable GL_MAP2_TEXTURE_COORD_3 = 0x0DB5;
immutable GL_MAP2_TEXTURE_COORD_4 = 0x0DB6;
immutable GL_MAP2_VERTEX_3 = 0x0DB7;
immutable GL_MAP2_VERTEX_4 = 0x0DB8;
immutable GL_MAP1_GRID_DOMAIN = 0x0DD0;
immutable GL_MAP1_GRID_SEGMENTS = 0x0DD1;
immutable GL_MAP2_GRID_DOMAIN = 0x0DD2;
immutable GL_MAP2_GRID_SEGMENTS = 0x0DD3;
immutable GL_COEFF = 0x0A00;
immutable GL_ORDER = 0x0A01;
immutable GL_DOMAIN = 0x0A02;

/* Hints */
immutable GL_PERSPECTIVE_CORRECTION_HINT = 0x0C50;
immutable GL_POINT_SMOOTH_HINT = 0x0C51;
immutable GL_LINE_SMOOTH_HINT = 0x0C52;
immutable GL_POLYGON_SMOOTH_HINT = 0x0C53;
immutable GL_FOG_HINT = 0x0C54;
immutable GL_DONT_CARE = 0x1100;
immutable GL_FASTEST = 0x1101;
immutable GL_NICEST = 0x1102;

/* Scissor box */
immutable GL_SCISSOR_BOX = 0x0C10;
immutable GL_SCISSOR_TEST = 0x0C11;

/* Pixel Mode / Transfer */
immutable GL_MAP_COLOR = 0x0D10;
immutable GL_MAP_STENCIL = 0x0D11;
immutable GL_INDEX_SHIFT = 0x0D12;
immutable GL_INDEX_OFFSET = 0x0D13;
immutable GL_RED_SCALE = 0x0D14;
immutable GL_RED_BIAS = 0x0D15;
immutable GL_GREEN_SCALE = 0x0D18;
immutable GL_GREEN_BIAS = 0x0D19;
immutable GL_BLUE_SCALE = 0x0D1A;
immutable GL_BLUE_BIAS = 0x0D1B;
immutable GL_ALPHA_SCALE = 0x0D1C;
immutable GL_ALPHA_BIAS = 0x0D1D;
immutable GL_DEPTH_SCALE = 0x0D1E;
immutable GL_DEPTH_BIAS = 0x0D1F;
immutable GL_PIXEL_MAP_S_TO_S_SIZE = 0x0CB1;
immutable GL_PIXEL_MAP_I_TO_I_SIZE = 0x0CB0;
immutable GL_PIXEL_MAP_I_TO_R_SIZE = 0x0CB2;
immutable GL_PIXEL_MAP_I_TO_G_SIZE = 0x0CB3;
immutable GL_PIXEL_MAP_I_TO_B_SIZE = 0x0CB4;
immutable GL_PIXEL_MAP_I_TO_A_SIZE = 0x0CB5;
immutable GL_PIXEL_MAP_R_TO_R_SIZE = 0x0CB6;
immutable GL_PIXEL_MAP_G_TO_G_SIZE = 0x0CB7;
immutable GL_PIXEL_MAP_B_TO_B_SIZE = 0x0CB8;
immutable GL_PIXEL_MAP_A_TO_A_SIZE = 0x0CB9;
immutable GL_PIXEL_MAP_S_TO_S = 0x0C71;
immutable GL_PIXEL_MAP_I_TO_I = 0x0C70;
immutable GL_PIXEL_MAP_I_TO_R = 0x0C72;
immutable GL_PIXEL_MAP_I_TO_G = 0x0C73;
immutable GL_PIXEL_MAP_I_TO_B = 0x0C74;
immutable GL_PIXEL_MAP_I_TO_A = 0x0C75;
immutable GL_PIXEL_MAP_R_TO_R = 0x0C76;
immutable GL_PIXEL_MAP_G_TO_G = 0x0C77;
immutable GL_PIXEL_MAP_B_TO_B = 0x0C78;
immutable GL_PIXEL_MAP_A_TO_A = 0x0C79;
immutable GL_PACK_ALIGNMENT = 0x0D05;
immutable GL_PACK_LSB_FIRST = 0x0D01;
immutable GL_PACK_ROW_LENGTH = 0x0D02;
immutable GL_PACK_SKIP_PIXELS = 0x0D04;
immutable GL_PACK_SKIP_ROWS = 0x0D03;
immutable GL_PACK_SWAP_BYTES = 0x0D00;
immutable GL_UNPACK_ALIGNMENT = 0x0CF5;
immutable GL_UNPACK_LSB_FIRST = 0x0CF1;
immutable GL_UNPACK_ROW_LENGTH = 0x0CF2;
immutable GL_UNPACK_SKIP_PIXELS = 0x0CF4;
immutable GL_UNPACK_SKIP_ROWS = 0x0CF3;
immutable GL_UNPACK_SWAP_BYTES = 0x0CF0;
immutable GL_ZOOM_X = 0x0D16;
immutable GL_ZOOM_Y = 0x0D17;

/* Texture mapping */
immutable GL_TEXTURE_ENV = 0x2300;
immutable GL_TEXTURE_ENV_MODE = 0x2200;
immutable GL_TEXTURE_1D = 0x0DE0;
immutable GL_TEXTURE_2D = 0x0DE1;
immutable GL_TEXTURE_WRAP_S = 0x2802;
immutable GL_TEXTURE_WRAP_T = 0x2803;
immutable GL_TEXTURE_MAG_FILTER = 0x2800;
immutable GL_TEXTURE_MIN_FILTER = 0x2801;
immutable GL_TEXTURE_ENV_COLOR = 0x2201;
immutable GL_TEXTURE_GEN_S = 0x0C60;
immutable GL_TEXTURE_GEN_T = 0x0C61;
immutable GL_TEXTURE_GEN_R = 0x0C62;
immutable GL_TEXTURE_GEN_Q = 0x0C63;
immutable GL_TEXTURE_GEN_MODE = 0x2500;
immutable GL_TEXTURE_BORDER_COLOR = 0x1004;
immutable GL_TEXTURE_WIDTH = 0x1000;
immutable GL_TEXTURE_HEIGHT = 0x1001;
immutable GL_TEXTURE_BORDER = 0x1005;
immutable GL_TEXTURE_COMPONENTS = 0x1003;
immutable GL_TEXTURE_RED_SIZE = 0x805C;
immutable GL_TEXTURE_GREEN_SIZE = 0x805D;
immutable GL_TEXTURE_BLUE_SIZE = 0x805E;
immutable GL_TEXTURE_ALPHA_SIZE = 0x805F;
immutable GL_TEXTURE_LUMINANCE_SIZE = 0x8060;
immutable GL_TEXTURE_INTENSITY_SIZE = 0x8061;
immutable GL_NEAREST_MIPMAP_NEAREST = 0x2700;
immutable GL_NEAREST_MIPMAP_LINEAR = 0x2702;
immutable GL_LINEAR_MIPMAP_NEAREST = 0x2701;
immutable GL_LINEAR_MIPMAP_LINEAR = 0x2703;
immutable GL_OBJECT_LINEAR = 0x2401;
immutable GL_OBJECT_PLANE = 0x2501;
immutable GL_EYE_LINEAR = 0x2400;
immutable GL_EYE_PLANE = 0x2502;
immutable GL_SPHERE_MAP = 0x2402;
immutable GL_DECAL = 0x2101;
immutable GL_MODULATE = 0x2100;
immutable GL_NEAREST = 0x2600;
immutable GL_REPEAT = 0x2901;
immutable GL_CLAMP = 0x2900;
immutable GL_S = 0x2000;
immutable GL_T = 0x2001;
immutable GL_R = 0x2002;
immutable GL_Q = 0x2003;

/* Utility */
immutable GL_VENDOR = 0x1F00;
immutable GL_RENDERER = 0x1F01;
immutable GL_VERSION = 0x1F02;
immutable GL_EXTENSIONS = 0x1F03;

/* Errors */
immutable GL_NO_ERROR = 0;
immutable GL_INVALID_ENUM = 0x0500;
immutable GL_INVALID_VALUE = 0x0501;
immutable GL_INVALID_OPERATION = 0x0502;
immutable GL_STACK_OVERFLOW = 0x0503;
immutable GL_STACK_UNDERFLOW = 0x0504;
immutable GL_OUT_OF_MEMORY = 0x0505;

/* glPush/PopAttrib bits */
immutable GL_CURRENT_BIT = 0x00000001;
immutable GL_POINT_BIT = 0x00000002;
immutable GL_LINE_BIT = 0x00000004;
immutable GL_POLYGON_BIT = 0x00000008;
immutable GL_POLYGON_STIPPLE_BIT = 0x00000010;
immutable GL_PIXEL_MODE_BIT = 0x00000020;
immutable GL_LIGHTING_BIT = 0x00000040;
immutable GL_FOG_BIT = 0x00000080;
immutable GL_DEPTH_BUFFER_BIT = 0x00000100;
immutable GL_ACCUM_BUFFER_BIT = 0x00000200;
immutable GL_STENCIL_BUFFER_BIT = 0x00000400;
immutable GL_VIEWPORT_BIT = 0x00000800;
immutable GL_TRANSFORM_BIT = 0x00001000;
immutable GL_ENABLE_BIT = 0x00002000;
immutable GL_COLOR_BUFFER_BIT = 0x00004000;
immutable GL_HINT_BIT = 0x00008000;
immutable GL_EVAL_BIT = 0x00010000;
immutable GL_LIST_BIT = 0x00020000;
immutable GL_TEXTURE_BIT = 0x00040000;
immutable GL_SCISSOR_BIT = 0x00080000;
immutable GL_ALL_ATTRIB_BITS = 0xFFFFFFFF;

/* OpenGL 1.1 */
immutable GL_PROXY_TEXTURE_1D = 0x8063;
immutable GL_PROXY_TEXTURE_2D = 0x8064;
immutable GL_TEXTURE_PRIORITY = 0x8066;
immutable GL_TEXTURE_RESIDENT = 0x8067;
immutable GL_TEXTURE_BINDING_1D = 0x8068;
immutable GL_TEXTURE_BINDING_2D = 0x8069;
immutable GL_TEXTURE_INTERNAL_FORMAT = 0x1003;
immutable GL_ALPHA4 = 0x803B;
immutable GL_ALPHA8 = 0x803C;
immutable GL_ALPHA12 = 0x803D;
immutable GL_ALPHA16 = 0x803E;
immutable GL_LUMINANCE4 = 0x803F;
immutable GL_LUMINANCE8 = 0x8040;
immutable GL_LUMINANCE12 = 0x8041;
immutable GL_LUMINANCE16 = 0x8042;
immutable GL_LUMINANCE4_ALPHA4 = 0x8043;
immutable GL_LUMINANCE6_ALPHA2 = 0x8044;
immutable GL_LUMINANCE8_ALPHA8 = 0x8045;
immutable GL_LUMINANCE12_ALPHA4 = 0x8046;
immutable GL_LUMINANCE12_ALPHA12 = 0x8047;
immutable GL_LUMINANCE16_ALPHA16 = 0x8048;
immutable GL_INTENSITY = 0x8049;
immutable GL_INTENSITY4 = 0x804A;
immutable GL_INTENSITY8 = 0x804B;
immutable GL_INTENSITY12 = 0x804C;
immutable GL_INTENSITY16 = 0x804D;
immutable GL_R3_G3_B2 = 0x2A10;
immutable GL_RGB4 = 0x804F;
immutable GL_RGB5 = 0x8050;
immutable GL_RGB8 = 0x8051;
immutable GL_RGB10 = 0x8052;
immutable GL_RGB12 = 0x8053;
immutable GL_RGB16 = 0x8054;
immutable GL_RGBA2 = 0x8055;
immutable GL_RGBA4 = 0x8056;
immutable GL_RGB5_A1 = 0x8057;
immutable GL_RGBA8 = 0x8058;
immutable GL_RGB10_A2 = 0x8059;
immutable GL_RGBA12 = 0x805A;
immutable GL_RGBA16 = 0x805B;
immutable GL_CLIENT_PIXEL_STORE_BIT = 0x00000001;
immutable GL_CLIENT_VERTEX_ARRAY_BIT = 0x00000002;
immutable GL_ALL_CLIENT_ATTRIB_BITS = 0xFFFFFFFF;
immutable GL_CLIENT_ALL_ATTRIB_BITS = 0xFFFFFFFF;

extern (C)
{

    /*************************************************************************
     * GL functions definitions.
     *************************************************************************/

    GLenum glGetError();
    void glClearIndex(GLfloat c);
    void glClearColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
    void glClear(GLbitfield mask);
    void glBegin(GLenum mode);
    void glEnd();
    void glVertex2f(GLfloat x, GLfloat y);
    void glVertex3f(GLfloat x, GLfloat y, GLfloat z);
    void glColor3f(GLfloat red, GLfloat green, GLfloat blue);
    void glTexCoord2f( GLfloat s, GLfloat t );
    void glEnable( GLenum cap );
    void glDisable( GLenum cap );
    void glTexEnvf( GLenum target, GLenum pname, GLfloat param );
    void glGenTextures( GLsizei n, GLuint *textures );
    void glDeleteTextures( GLsizei n, const GLuint *textures);
    void glBindTexture( GLenum target, GLuint texture );
    void glFlush();
    void glShadeModel( GLenum mode );
    void glPixelStorei( GLenum pname, GLint param );
    void glTexParameteri( GLenum target, GLenum pname, GLint param );
    void glTexImage2D( GLenum target, GLint level,
            GLint internalFormat,
            GLsizei width, GLsizei height,
            GLint border, GLenum format, GLenum type,
            const GLvoid *pixels );
    void glTexSubImage2D( GLenum target, GLint level,
            GLint xoffset, GLint yoffset,
            GLsizei width, GLsizei height,
            GLenum format, GLenum type,
            const GLvoid *pixels );
    void glGenerateMipmap(GLenum);
}
