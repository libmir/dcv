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
module ffmpeg.libavutil.motion_vector;
extern (C):

struct AVMotionVector
{
    /**
     * Where the current macroblock comes from; negative value when it comes
     * from the past, positive value when it comes from the future.
     * XXX: set exact relative ref frame reference instead of a +/- 1 "direction".
     */
    int source;
    /**
     * Width and height of the block.
     */
    ubyte w;
    ubyte h;
    /**
     * Absolute source position. Can be outside the frame area.
     */
    short src_x;
    short src_y;
    /**
     * Absolute destination position. Can be outside the frame area.
     */
    short dst_x;
    short dst_y;
    /**
     * Extra flag information.
     * Currently unused.
     */
    ulong flags;
    /**
     * Motion vector
     * src_x = dst_x + motion_x / motion_scale
     * src_y = dst_y + motion_y / motion_scale
     */
    int motion_x;
    int motion_y;
    ushort motion_scale;
}

/* AVUTIL_MOTION_VECTOR_H */
