/*
 * copyright (c) 2006 Michael Niedermayer <michaelni@gmx.at>
 *
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
 * Macro definitions for various function/variable attributes
 */
module ffmpeg.libavutil.attributes;

extern (C):

extern (D) int AV_GCC_VERSION_AT_LEAST(T0, T1)(auto ref T0 x, auto ref T1 y)
{
    return 0;
}

extern (D) int AV_GCC_VERSION_AT_MOST(T0, T1)(auto ref T0 x, auto ref T1 y)
{
    return 0;
}

//alias AV_HAS_BUILTIN = __has_builtin;

/**
 * Disable warnings about deprecated features
 * This is useful for sections of code kept for backward compatibility and
 * scheduled for removal.
 */

/**
 * Mark a variable as used and prevent the compiler from optimizing it
 * away.  This is useful for variables accessed only from inline
 * assembler without the compiler being aware.
 */

//enum av_builtin_constant_p = __builtin_constant_p;

/* AVUTIL_ATTRIBUTES_H */
