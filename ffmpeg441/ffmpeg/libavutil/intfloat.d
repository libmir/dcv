/*
 * Copyright (c) 2011 Mans Rullgard
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
module ffmpeg.libavutil.intfloat;
extern (C):

union av_intfloat32
{
    uint i;
    float f;
}

union av_intfloat64
{
    ulong i;
    double f;
}

/**
 * Reinterpret a 32-bit integer as a float.
 */
float av_int2float (uint i);

/**
 * Reinterpret a float as a 32-bit integer.
 */
uint av_float2int (float f);

/**
 * Reinterpret a 64-bit integer as a double.
 */
double av_int2double (ulong i);

/**
 * Reinterpret a double as a 64-bit integer.
 */
ulong av_double2int (double f);

/* AVUTIL_INTFLOAT_H */
