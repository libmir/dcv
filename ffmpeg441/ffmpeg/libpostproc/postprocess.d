/*
 * Copyright (C) 2001-2003 Michael Niedermayer (michaelni@gmx.at)
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */
module ffmpeg.libpostproc.postprocess;

extern (C):

/**
 * @file
 * @ingroup lpp
 * external API header
 */

/**
 * @defgroup lpp libpostproc
 * Video postprocessing library.
 *
 * @{
 */

/**
 * Return the LIBPOSTPROC_VERSION_INT constant.
 */
uint postproc_version ();

/**
 * Return the libpostproc build-time configuration.
 */
const(char)* postproc_configuration ();

/**
 * Return the libpostproc license.
 */
const(char)* postproc_license ();

enum PP_QUALITY_MAX = 6;

alias pp_context = void;
alias pp_mode = void;

///< a simple help text

extern __gshared const(char)[] pp_help; ///< a simple help text

void pp_postprocess (
    ref const(ubyte)*[3] src,
    ref const(int)[3] srcStride,
    ref ubyte*[3] dst,
    ref const(int)[3] dstStride,
    int horizontalSize,
    int verticalSize,
    const(byte)* QP_store,
    int QP_stride,
    pp_mode* mode,
    pp_context* ppContext,
    int pict_type);

/**
 * Return a pp_mode or NULL if an error occurred.
 *
 * @param name    the string after "-pp" on the command line
 * @param quality a number from 0 to PP_QUALITY_MAX
 */
pp_mode* pp_get_mode_by_name_and_quality (const(char)* name, int quality);
void pp_free_mode (pp_mode* mode);

pp_context* pp_get_context (int width, int height, int flags);
void pp_free_context (pp_context* ppContext);

enum PP_CPU_CAPS_MMX = 0x80000000;
enum PP_CPU_CAPS_MMX2 = 0x20000000;
enum PP_CPU_CAPS_3DNOW = 0x40000000;
enum PP_CPU_CAPS_ALTIVEC = 0x10000000;
enum PP_CPU_CAPS_AUTO = 0x00080000;

enum PP_FORMAT = 0x00000008;
enum PP_FORMAT_420 = 0x00000011 | PP_FORMAT;
enum PP_FORMAT_422 = 0x00000001 | PP_FORMAT;
enum PP_FORMAT_411 = 0x00000002 | PP_FORMAT;
enum PP_FORMAT_444 = 0x00000000 | PP_FORMAT;
enum PP_FORMAT_440 = 0x00000010 | PP_FORMAT;

enum PP_PICT_TYPE_QP2 = 0x00000010; ///< MPEG2 style QScale

/**
 * @}
 */

/* POSTPROC_POSTPROCESS_H */
