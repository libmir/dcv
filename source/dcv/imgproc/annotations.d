module dcv.imgproc.annotations;

import std.typecons;
import mir.ndslice;

alias AColor = ubyte[3]; // RGB
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
                // Set pixel color
                for (int i = 0; i < 3; ++i)
                {
                    input[y, x, i] = color[i];
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
                    input[topY, x, j] = color[j];
                }
            }
            if (bottomY >= 0 && bottomY < height)
            {
                for (int j = 0; j < 3; ++j)
                {
                    input[bottomY, x, j] = color[j];
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
                    input[y, leftX, j] = color[j];
                }
            }
            if (rightX >= 0 && rightX < width)
            {
                for (int j = 0; j < 3; ++j)
                {
                    input[y, rightX, j] = color[j];
                }
            }
        }
    }
}

import dcv.core.ttf;

void putText(InputSlice)(ref InputSlice input, auto ref TtfFont font, in char[] text, APoint position,
                        int size = 20, AColor color = [255, 0, 0])
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

                if (textPixel != 0)
                {
                    for (int i = 0; i < 3; ++i)
                    {
                        input[inputY, inputX, i] = cast(ubyte)((color[i] * textPixel + input[inputY, inputX, i] * (255 - textPixel)) / 255);
                    }
                }
            }
        }
    }
}