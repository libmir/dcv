/*
Copyright (c) 2021- Ferhat Kurtulmuş
Boost Software License - Version 1.0 - August 17th, 2003
*/

module dcv.plot.drawprimitives;

version(UseLegacyGL){ } else:

import std.math;
import std.typecons : Tuple;

import mir.appender;

import dcv.plot.bindings;

alias PlotPoint = Tuple!(float, "x", float, "y"); 
alias PPoint = PlotPoint;

alias PlotColor = float[4];

PlotColor plotRed = [1.0f, 0.0f, 0.0f, 1.0f];
PlotColor plotGreen = [0.0f, 1.0f, 0.0f, 1.0f];
PlotColor plotBlue = [0.0f, 0.0f, 1.0f, 1.0f];
PlotColor plotWhite = [1.0f, 1.0f, 1.0f, 1.0f];
PlotColor plotBlack = [0.0f, 0.0f, 0.0f, 1.0f];
PlotColor plotYellow = [1.0f, 1.0f, 0.0f, 1.0f];
PlotColor plotCyan = [0.0f, 1.0f, 1.0f, 1.0f];
PlotColor plotMagenta = [1.0f, 0.0f, 1.0f, 1.0f];

struct PlotCircle {
    float centerx;
    float centery;
    float radius;
}

package:

// must match with enum ImageFormat
int DISPLAY_FORMAT(int format) @nogc nothrow
{
    if(format == 1){
        return GL_DEPTH_COMPONENT;
    } else 
    if(format == 2){
       return GL_RGB;
    } else
    if(format == 3){
        return GL_BGR;
    } else {
        debug assert(0, "unsopported format for imshow."); // it will never come here :)
        return -1;
    }
}

struct TextureRenderer {

@disable this();

    private {
        ubyte* imptr;
        uint width;
        uint height;
        int dispFormat;
        GLTexturedRect drafter;
        GLuint shaderPrg;
        uint textureId;
    }

    @nogc nothrow:
    this(ubyte* imptr, uint width, uint height, int dformat){
        this.imptr = imptr;
        this.width = width;
        this.height = height;
        dispFormat = dformat;

        textureId = loadTexture(imptr, width, height, DISPLAY_FORMAT(dispFormat));

        shaderPrg = loadShaderTextured();
        drafter = GLTexturedRect(shaderPrg);
    }

    void render(){
        updateTexture(imptr, width, height, textureId, DISPLAY_FORMAT(dispFormat));
        drafter.set(Rect(0,0,width,height), textureId, 0.0f);
        drafter.draw();
    }
}

@nogc nothrow:

GLuint loadTexture(ubyte* imptr, uint w, uint h, int dispFormat){
    GLuint textureId;
    glGenTextures(1, &textureId); 
    glBindTexture(GL_TEXTURE_2D, textureId);
    
    /+
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    +/
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    glTexImage2D(GL_TEXTURE_2D, 0, dispFormat, w, h, 0, dispFormat, GL_UNSIGNED_BYTE, imptr);
    glGenerateMipmap(GL_TEXTURE_2D);

    return textureId;
}

void updateTexture(ubyte* imptr, uint w, uint h, uint textureId, int dispFormat){

    glBindTexture(GL_TEXTURE_2D, textureId);

    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, dispFormat, GL_UNSIGNED_BYTE, imptr);

    glBindTexture( GL_TEXTURE_2D, 0);
}

void launchLine(ref GLLine drafter,
    const ref PlotPoint p1, const ref PlotPoint p2, const ref PlotColor color, const ref float lineWidth)
{
    drafter.set(p1, p2, color, lineWidth);
    drafter.draw();
}

void launchHollowCircle(ref GLCircle drafter,
    const ref PlotCircle circle, const ref PlotColor color)
{  
    drafter.set(circle.centerx, circle.centery, circle.radius, color);
    drafter.draw();
}

void launchSolidCircle(ref GLSolidCircle drafter,
    const ref PlotCircle circle, const ref PlotColor color)
{
    drafter.set(circle.centerx, circle.centery, circle.radius, color);
    drafter.draw();
}

void launchRectangle(ref GLRect drafter,
    const ref PlotPoint[2] r, const ref PlotColor color, const ref float lineWidth)
{
    drafter.set(r, color, lineWidth);
    drafter.draw();
}
/+++++++++++++++++++++++++++++       shader code        +++++++++++++++++++++++++++++++/

import core.stdc.math: cos, sin;
import core.stdc.stdlib: malloc, free, exit;
import core.stdc.stdio: printf;

import mir.ndslice;
import mir.rc;

package __gshared Slice!(RCI!float, 2LU, Contiguous) ortho;

package auto getOrtho(float left, float right, float bottom, float top, float near = -1, float far = 1)
{
    Slice!(RCI!float, 2LU, Contiguous) result = uninitRCslice!(float)(4, 4);
    result[] = 0;

    result[0, 0] = 2.0 / (right - left);
    result[1, 1] = 2.0 / (top - bottom);
    result[2, 2] = 2.0 / (near - far);
    result[3, 3] = 1.0;

    result[3, 0] = (left + right) / (left - right);
    result[3, 1] = (bottom + top) / (bottom - top);
    result[3, 2] = (far + near) / (near - far);

    return result;
}

private auto getModel(const ref Rect r, float angle){
    float[3] zeroTranslation = [-r.x - r.w*0.5, -r.y - r.h*0.5, 0.0f];
    Slice!(RCI!float, 2LU, Contiguous) model = uninitRCslice!(float)(4, 4);
    model[] = 0;
    model.diagonal[] = 1;

    // zero translation
    model[$-1][0 .. 3] += zeroTranslation[0 .. 3];

    // rotateZ
    immutable auto c = cos(angle), s = sin(angle);
    model[0, 0] = c; model[0, 1] = -s;
    model[1, 0] = s; model[1, 1] = c;

    // negative zero translation
    model[$-1][0 .. 3] -= zeroTranslation[0 .. 3];
    
    return model;
}

private enum PI = 3.14159265359f;

struct GLLine{
    float[4] vertices;
    
    GLuint shaderProgram;
    GLuint vbo;

    float lineWidth;

    @nogc nothrow:

    this(GLuint shaderProgram){
        this.shaderProgram = shaderProgram;

        vertices = [0.0f, 0.0f, 0.0f, 0.0f];

        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.ptr, GL_STATIC_DRAW);
    }

    void set(const ref PlotPoint point1, const ref PlotPoint point2, const ref PlotColor color, const ref float lineWidth){
        this.lineWidth = lineWidth;
        
        vertices[0] = float(point1.x);
        vertices[1] = float(point1.y);
        vertices[2] = float(point2.x);
        vertices[3] = float(point2.y);

        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.ptr, GL_STATIC_DRAW);

        glUseProgram(shaderProgram);

        GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
        glEnableVertexAttribArray(posAttrib);
        
        auto vertexSize =float.sizeof*2;
        glVertexAttribPointer(posAttrib, 2, GL_FLOAT, false, cast(uint)vertexSize, null);

        auto pmAtt = glGetUniformLocation(shaderProgram, "projectionMat");
        glUniformMatrix4fv(pmAtt, 1, GL_FALSE, ortho.ptr);

        // set color
        auto cAtt = glGetUniformLocation(shaderProgram, "ucolor");
        glUniform4fv(cAtt, 1, color.ptr);
    }

    void draw() {
        glUseProgram(shaderProgram);
        glLineWidth(lineWidth);
        glDrawArrays(GL_LINES, 0, 2);
        glDisableVertexAttribArray(0);
        glUseProgram(0);
    }

    ~this(){
        
    }
}

struct GLCircle {
    
    ScopedBuffer!float vertices;
    GLuint shaderProgram;
    GLuint vbo;

    @nogc nothrow:

    this(GLuint shaderProgram){
        this.shaderProgram = shaderProgram;

        enum numVertices = 1000;

        float increment = 2.0f * PI / float(numVertices);

        for (float currAngle = 0.0f; currAngle <= 2.0f * PI; currAngle += increment)
        {
            vertices.put(0.0f);
            vertices.put(0.0f);
        }

        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.data.ptr, GL_STATIC_DRAW);
    }

    void set(const ref float x, const ref float y, const ref float radius, const ref PlotColor color){
        enum numVertices = 1000;

        float increment = 2.0f * PI / float(numVertices);

        size_t i;
        for (float currAngle = 0.0f; currAngle <= 2.0f * PI; currAngle += increment)
        {
            vertices.data[i] = radius * cos(currAngle) + float(x);
            vertices.data[i+1] = radius * sin(currAngle) + float(y);
            i += 2;
        }

        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.data.ptr, GL_STATIC_DRAW);
        
        glUseProgram(shaderProgram);

        GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
        auto vertexSize = float.sizeof*2;
        glVertexAttribPointer(posAttrib, 2, GL_FLOAT, false, cast(uint)vertexSize, null);
        glEnableVertexAttribArray(posAttrib);

        auto pmAtt = glGetUniformLocation(shaderProgram, "projectionMat");
        glUniformMatrix4fv(pmAtt, 1, GL_FALSE, ortho.ptr);

        // set color
        auto cAtt = glGetUniformLocation(shaderProgram, "ucolor");
        glUniform4fv(cAtt, 1, color.ptr);
    }

    void draw() {
        glUseProgram(shaderProgram);
        glDrawArrays(GL_LINE_LOOP, 0, cast(int)vertices.length/2);
        glDisableVertexAttribArray(0);
        glUseProgram(0);
    }

    ~this(){
        
    }
}

struct GLSolidCircle {
    
    ScopedBuffer!float vertices;

    GLuint shaderProgram;
    GLuint vbo;

    @nogc nothrow:

    this(GLuint shaderProgram){
        this.shaderProgram = shaderProgram;      

        enum quality = 0.125;
        int triangleAmount = cast(int)(300 * quality);

        foreach(i; 0..triangleAmount) { 
            vertices.put(0.0f);
            vertices.put(0.0f);
        }

        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.data.ptr, GL_STREAM_DRAW);
    }

    void set(const ref float x, const ref float y, const ref float radius, const ref PlotColor color){        
        import std.range : chunks;

        enum quality = 0.125;
        int triangleAmount = cast(int)(300 * quality);
        
        int i;
        foreach(ref c; chunks(vertices.data[], 2)) {
            c[0] = x + (radius * cos(i *  2*PI / float(triangleAmount))); 
            c[1] = y + (radius * sin(i * 2*PI / float(triangleAmount)));
            ++i;
        }

        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.data.ptr, GL_STREAM_DRAW);

        glUseProgram(shaderProgram);

        GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
        glVertexAttribPointer(posAttrib, 2, GL_FLOAT, false, uint(0), null);
        glEnableVertexAttribArray(posAttrib);

        auto pmAtt = glGetUniformLocation(shaderProgram, "projectionMat");
        glUniformMatrix4fv(pmAtt, 1, GL_FALSE, ortho.ptr);

        // set color
        auto cAtt = glGetUniformLocation(shaderProgram, "ucolor");
        glUniform4fv(cAtt, 1, color.ptr);
    }

    void draw() {
        glUseProgram(shaderProgram);
        glDrawArrays(GL_TRIANGLE_FAN, 0, cast(int)vertices.length/2);
        glDisableVertexAttribArray(0);
        glUseProgram(0);
    }

    ~this(){
        
    }
}

private struct Rect {
    int x, y, w, h;
}

struct GLRect {
    float[8] vertices;
    
    GLuint shaderProgram;
    GLuint vbo;

    float lineWidth;

    @nogc nothrow:

    this(GLuint shaderProgram){
        this.shaderProgram = shaderProgram;

        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.ptr, GL_STATIC_DRAW);
    }

    void set(const ref PlotPoint[2] r, const ref PlotColor color, const ref float lineWidth){
        this.lineWidth = lineWidth;

        immutable p1 = r[0];
        immutable p2 = r[1];

        vertices = [p1.x, p1.y,
                    p1.x, p2.y,
                    p2.x, p2.y,
                    p2.x, p1.y
        ];

        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.ptr, GL_STATIC_DRAW);
        
        glUseProgram(shaderProgram);

        GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
        auto vertexSize = float.sizeof*2;
        glVertexAttribPointer(posAttrib, 2, GL_FLOAT, false, cast(uint)vertexSize, null);
        glEnableVertexAttribArray(posAttrib);

        auto pmAtt = glGetUniformLocation(shaderProgram, "projectionMat");
        glUniformMatrix4fv(pmAtt, 1, GL_FALSE, ortho.ptr);

        // set color
        auto cAtt = glGetUniformLocation(shaderProgram, "ucolor");
        glUniform4fv(cAtt, 1, color.ptr);
    }

    void draw() {
        glUseProgram(shaderProgram);
        glDrawArrays(GL_LINE_LOOP, 0, cast(int)vertices.length/2);
        glDisableVertexAttribArray(0);
        glUseProgram(0);
    }
}

struct GLTexturedRect {
    
    GLuint shaderProgram;
    GLuint vao = 0;
    GLuint vbo = 0;

    GLuint textureId;

    float[24] vertices;

    @nogc nothrow:

    this(GLuint shaderProgram){
        this.shaderProgram = shaderProgram;

        glGenVertexArrays(1, &vao);
        glGenBuffers(1, &vbo);
        
    }

    void set(Rect r, GLuint textureId, float angle){
        this.textureId = textureId;

        vertices = [
            r.x, r.y+r.h,      0.0f, 1.0f,
            r.x+r.w, r.y,      1.0f, 0.0f,
            r.x, r.y,          0.0f, 0.0f,
            
            r.x, r.y+r.h,      0.0f, 1.0f,
            r.x+r.w, r.y+r.h,  1.0f, 1.0f,
            r.x+r.w, r.y,      1.0f, 0.0f
        ];
        
        auto model = getModel(r, angle);
        
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.ptr, GL_STATIC_DRAW);
        
        glBindVertexArray(vao);

        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 4 * float.sizeof, cast(void*)0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);

        glUseProgram(shaderProgram);
        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "projectionMat"), 1, GL_FALSE, ortho.ptr);
        glUniform1i(glGetUniformLocation(shaderProgram, "userTexture"), 0);
        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "modelMat"), 1, GL_FALSE, model.ptr);

        glBindVertexArray(0);
    }

    void draw(){
        glBindTexture(GL_TEXTURE_2D, textureId);
        glBindVertexArray(vao);
        
        glDrawArrays(GL_TRIANGLES, 0, 6);

        glBindVertexArray(0);
    }
}

GLuint initShader(const char* vShader, const char* fShader) {
    struct Shader {
        GLenum type;
        const char* source;
    }
    Shader[2] shaders = [
        Shader(GL_VERTEX_SHADER, vShader),
        Shader(GL_FRAGMENT_SHADER, fShader)
    ];

    GLuint program = glCreateProgram();

    for ( int i = 0; i < 2; ++i ) {
        Shader s = shaders[i];
        GLuint shader = glCreateShader( s.type );
        glShaderSource( shader, 1, &s.source, null );
        glCompileShader( shader );

        GLint  compiled;
        glGetShaderiv( shader, GL_COMPILE_STATUS, &compiled );
        if ( !compiled ) {
            printf(" failed to compile: ");
            GLint  logSize;
            glGetShaderiv( shader, GL_INFO_LOG_LENGTH, &logSize );
            char* logMsg = cast(char*)malloc(char.sizeof*logSize);
            glGetShaderInfoLog( shader, logSize, null, logMsg );
            printf("%s \n", logMsg);
            free(cast(void*)logMsg);

            exit( -1 );
        }

        glAttachShader( program, shader );
    }

    /* link  and error check */
    glLinkProgram(program);

    GLint linked;
    glGetProgramiv( program, GL_LINK_STATUS, &linked );
    if ( !linked ) {
        printf("Shader program failed to link");
        GLint  logSize;
        glGetProgramiv( program, GL_INFO_LOG_LENGTH, &logSize);
        char* logMsg = cast(char*)malloc(char.sizeof*logSize);
        glGetProgramInfoLog( program, logSize, null, logMsg );
        printf("%s \n", logMsg);
        free(cast(void*)logMsg);
        exit( -1 );
    }

    /* use program object */
    glUseProgram(program);

    return program;
}


enum verth = "#version 140\n
";
enum fragh = "#version 140\n";

GLuint loadShaderTextured(){
    enum vert = verth ~ q{
        in vec4 vertex;
        out vec2 TexCoords;

        uniform mat4 projectionMat;
        uniform mat4 modelMat;

        void main()
        {
            TexCoords = vertex.zw;
            gl_Position = projectionMat * modelMat * vec4(vertex.xy, 0.0, 1.0);
        }
    };
    enum frag = fragh ~ `
        in vec2 TexCoords;
        out vec4 FragColor;

        uniform sampler2D userTexture;

        void main()
        {   
            FragColor = texture(userTexture, TexCoords.xy);
        }
    `;

    return initShader(vert, frag);
}

GLuint loadShaderColor(){
    enum vert = verth ~ q{
        in vec4 position;
        uniform mat4 projectionMat;
        void main() {
            gl_Position = projectionMat * vec4(position.xyz, 1.0);
        }
    };
    enum frag = fragh ~ `
        uniform vec4 ucolor;
        out vec4 FragColor;
        void main() {
            FragColor = ucolor;
        }
    `;
    
    return initShader(vert, frag);
    
}