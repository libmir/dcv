/*
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

/**
 * @file
 * @ingroup lavu
 * Utility Preprocessor macros
 */
module ffmpeg.libavutil.macros;
extern (C):

/**
 * @addtogroup preproc_misc Preprocessor String Macros
 *
 * String manipulation macros
 *
 * @{
 */

alias AV_STRINGIFY = AV_TOSTRING;

extern (D) string AV_TOSTRING(T)(auto ref T s)
{
    import std.conv : to;

    return to!string(s);
}

extern (D) string AV_GLUE(T0, T1)(auto ref T0 a, auto ref T1 b)
{
    import std.conv : to;

    return to!string(a) ~ to!string(b);
}

alias AV_JOIN = AV_GLUE;

/**
 * @}
 */

extern (D) auto AV_PRAGMA(T)(auto ref T s)
{
    import std.conv : to;

    return _Pragma(to!string(s));
}

extern (D) auto FFALIGN(T0, T1)(auto ref T0 x, auto ref T1 a)
{
    return (x + a - 1) & ~(a - 1);
}

/* AVUTIL_MACROS_H */
