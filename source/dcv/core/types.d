module dcv.core.types;

import std.typecons: Tuple;

public import std.experimental.color;
public import std.experimental.color.rgb;
public import std.experimental.color.hsx;
public import std.experimental.color.lab;
public import std.experimental.color.xyz;
public import std.experimental.normint;


///////////////////////////////////////////////////////////////////
// Image (Pixel) format type trait collection.                   //
//                                                               //
// Mainly relies on std.experimental.color library's constructs. //
///////////////////////////////////////////////////////////////////


/// 8-bit bitdepth image base type.
alias Pixel8u = ubyte;
/// 16-bit bitdepth image base type.
alias Pixel16u = ushort;
/// Integral representative type of 32-bit bitdepth image.
alias Pixel32u = uint;
/// Floating point representative type of 32-bit bitdepth image.
alias Pixel32f = float;


/**
   Get basis type for a given pixel type.
 */
template BaseType(T)
{
    static assert(isPixel!T, "Only pixel types are allowed.");

    static if (isColor!T)
    {
        static if (is (T.ComponentType == NormalizedInt!U, U))
        {
            alias BaseType = T.ComponentType.IntType;
        }
        else
        {
            alias BaseType = T.ComponentType;
        }
    }
    else
    {
        alias BaseType = T;
    }
}

/**
   Check if given type is a valid pixel type in mono (single channel) image.
 */
template isMonoPixel(T)
{
    enum isMonoPixel = (is (T == Pixel32f)) ||
                       (is (T == Pixel32u)) ||
                       (is (T == Pixel16u)) ||
                       (is (T == Pixel8u)) ||
                       (is (T == NormalizedInt!U, U)) ||
                       (is (T == RGB!("l", U), U));
}

/**
   Check pixel (image) bitdepth for the given type.

   Note:
      For convenience reasons returns size in bytes of the contained type.
 */
template pixelDepth(T)
{
    static assert(isPixel!T, "Given type is not a valid pixel type.");
    static if (isColor!T)
    {
        enum pixelDepth = T.ComponentType.sizeof;
    }
    else
    {
        enum pixelDepth = T.sizeof;
    }
}

/**
   Check number of channels of the pixel (image) type.
 */
template channelCount(T)
{
    static assert(isPixel!T, "Given type is not a valid pixel type.");
    static if (isRGB!T)
    {
        enum channelCount = T.components.length;
    }
    else static if (isHSx!T || isLab!T || isLCh!T || isXYZ!T)
    {
        enum channelCount = 3;
    }
    else
    {
        enum channelCount = 1;
    }
}

/**
   Check if T is any of types that could be a pixel representative.

   This includes simple scalar values that can represent single-channel image,
   such as ubute (8bit mono), ushort (16bit), uint (32bit), float (32bit hdr image).
   Pixel type is also any type that satisfies std.experimental.color.isColor check and
   is NormalizedInt type from the color library.
 */
template isPixel(T)
{
    enum isPixel = isMonoPixel!T || isColor!T;
}

///////////////////////////////////////////////////////////
// Basic geometric type representatives for DCV library. //
///////////////////////////////////////////////////////////

/// Two dimensional point representation.
template Point(T)
{
    alias Point = Tuple!(T, "x", T, "y");
}

/// Convenience alias for Point.
alias Vector = Point;

/// Two dimensional rectangle (region or block) representation.
template Rect(T)
{
    alias Rect = Tuple!(T, "x", T, "y", T, "width", T, "height");
}

