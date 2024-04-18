module dcv.imgproc.annotations;

import std.typecons;
import std.math;

import mir.ndslice;

alias AColor = ubyte[4]; // RGBA

AColor aRed = [255, 0, 0, 255];
AColor aGreen = [0, 255, 0, 255];
AColor aBlue = [0, 0, 255, 255];
AColor aWhite = [255, 255, 255, 255];
AColor aBlack = [0, 0, 0, 255];
AColor aYellow = [255, 255, 0, 255];
AColor aCyan = [0, 255, 255, 255];
AColor aMagenta = [255, 0, 255, 255];

alias APoint = Tuple!(float, "x", float, "y");

@nogc nothrow:

void putRectangleSolid(InputSlice)(ref InputSlice input, APoint[2] rect, AColor color)
{
    auto x0 = cast(int)rect[0].x;
    auto y0 = cast(int)rect[0].y;
    auto x1 = cast(int)rect[1].x;
    auto y1 = cast(int)rect[1].y;

    // Ensure x0 <= x1 and y0 <= y1
    if (x0 > x1)
    {
        auto temp = x0;
        x0 = x1;
        x1 = temp;
    }
    if (y0 > y1)
    {
        auto temp = y0;
        y0 = y1;
        y1 = temp;
    }

    auto height = input.shape[0];
    auto width = input.shape[1];

    for (int y = y0; y <= y1; ++y)
    {
        for (int x = x0; x <= x1; ++x)
        {
            if (x >= 0 && x < width &&
                y >= 0 && y < height)
            {
                // Set pixel color with alpha blending
                for (int i = 0; i < 3; ++i)
                {
                    auto newColor = (color[i] * color[3] + input[y, x, i] * (255 - color[3])) / 255;
                    input[y, x, i] = cast(ubyte)newColor;
                }
            }
        }
    }
}

void putRectangleHollow(InputSlice)(ref InputSlice input, APoint[2] rect, AColor color, ubyte lineWidth)
{
    auto x0 = cast(int)rect[0].x;
    auto y0 = cast(int)rect[0].y;
    auto x1 = cast(int)rect[1].x;
    auto y1 = cast(int)rect[1].y;

    // Ensure x0 <= x1 and y0 <= y1
    if (x0 > x1)
    {
        auto temp = x0;
        x0 = x1;
        x1 = temp;
    }
    if (y0 > y1)
    {
        auto temp = y0;
        y0 = y1;
        y1 = temp;
    }

    auto height = input.shape[0];
    auto width = input.shape[1];

    for (int x = x0; x <= x1; ++x)
    {
        for (int i = 0; i < lineWidth; ++i)
        {
            int topY = y0 + i;
            int bottomY = y1 - i;
            if (topY >= 0 && topY < height)
            {
                for (int j = 0; j < 3; ++j)
                {
                    auto newColor = (color[j] * color[3] + input[topY, x, j] * (255 - color[3])) / 255;
                    input[topY, x, j] = cast(ubyte)newColor;
                }
            }
            if (bottomY >= 0 && bottomY < height)
            {
                for (int j = 0; j < 3; ++j)
                {
                    auto newColor = (color[j] * color[3] + input[bottomY, x, j] * (255 - color[3])) / 255;
                    input[bottomY, x, j] = cast(ubyte)newColor;
                }
            }
        }
    }

    for (int y = y0; y <= y1; ++y)
    {
        for (int i = 0; i < lineWidth; ++i)
        {
            int leftX = x0 + i;
            int rightX = x1 - i;
            if (leftX >= 0 && leftX < width)
            {
                for (int j = 0; j < 3; ++j)
                {
                    auto newColor = (color[j] * color[3] + input[y, leftX, j] * (255 - color[3])) / 255;
                    input[y, leftX, j] = cast(ubyte)newColor;
                }
            }
            if (rightX >= 0 && rightX < width)
            {
                for (int j = 0; j < 3; ++j)
                {
                    auto newColor = (color[j] * color[3] + input[y, rightX, j] * (255 - color[3])) / 255;
                    input[y, rightX, j] = cast(ubyte)newColor;
                }
            }
        }
    }
}

void drawCircleSolid(InputSlice)(ref InputSlice input, APoint center, float radius, AColor color)
{
    auto centerX = cast(int)center.x;
    auto centerY = cast(int)center.y;

    auto height = input.shape[0];
    auto width = input.shape[1];

    auto sqrRadius = radius * radius;

    for (int y = centerY - cast(int)radius; y <= centerY + radius; ++y)
    {
        for (int x = centerX - cast(int)radius; x <= centerX + radius; ++x)
        {
            if (x >= 0 && x < width &&
                y >= 0 && y < height)
            {
                auto distanceSquared = (x - centerX) * (x - centerX) + (y - centerY) * (y - centerY);
                if (distanceSquared <= sqrRadius)
                {
                    // Set pixel color with alpha blending
                    for (int i = 0; i < 3; ++i)
                    {
                        auto newColor = (color[i] * color[3] + input[y, x, i] * (255 - color[3])) / 255;
                        input[y, x, i] = cast(ubyte)newColor;
                    }
                }
            }
        }
    }
}

void drawCircleHollow(InputSlice)(ref InputSlice input, APoint center, float radius, AColor color, ubyte lineWidth)
{
    auto centerX = cast(int)center.x;
    auto centerY = cast(int)center.y;

    auto height = input.shape[0];
    auto width = input.shape[1];

    auto sqrRadius = radius * radius;

    for (int y = centerY - cast(int)radius; y <= centerY + radius; ++y)
    {
        for (int x = centerX - cast(int)radius; x <= centerX + radius; ++x)
        {
            if (x >= centerX - lineWidth && x <= centerX + lineWidth &&
                y >= centerY - lineWidth && y <= centerY + lineWidth)
            {
                continue; // Skip pixels within the line width area
            }

            if (x >= 0 && x < width &&
                y >= 0 && y < height)
            {
                auto distanceSquared = (x - centerX) * (x - centerX) + (y - centerY) * (y - centerY);
                auto distance = sqrt(float(distanceSquared));

                if (distance >= radius - lineWidth && distance <= radius)
                {
                    // Set pixel color with alpha blending
                    for (int i = 0; i < 3; ++i)
                    {
                        auto newColor = (color[i] * color[3] + input[y, x, i] * (255 - color[3])) / 255;
                        input[y, x, i] = cast(ubyte)newColor;
                    }
                }
            }
        }
    }
}

import dcv.core.ttf;

void putText(InputSlice)(ref InputSlice input, auto ref TtfFont font, in char[] text, APoint position,
                        int size = 20, AColor color = [255, 0, 0, 255])
{
    int width, height;

    auto rstr = font.renderString(text, size, width, height);

    auto textImg2D = rstr.asSlice.sliced([height, width]);

    immutable textHeight = textImg2D.shape[0];
    immutable textWidth = textImg2D.shape[1];

    immutable offsetX = cast(int)position.x;
    immutable offsetY = cast(int)position.y;

    for (int y = 0; y < textHeight; ++y)
    {
        for (int x = 0; x < textWidth; ++x)
        {
            auto inputX = offsetX + x;
            auto inputY = offsetY + y;

            if (inputX >= 0 && inputX < input.shape[1] &&
                inputY >= 0 && inputY < input.shape[0])
            {
                immutable textPixel = textImg2D[y, x];
                immutable alpha = color[3] * textPixel / 255; // Adjust alpha based on textPixel

                if (alpha != 0)
                {
                    for (int i = 0; i < 3; ++i)
                    {
                        auto newColor = (color[i] * alpha + input[inputY, inputX, i] * (255 - alpha)) / 255;
                        input[inputY, inputX, i] = cast(ubyte)newColor;
                    }
                }
            }
        }
    }
}