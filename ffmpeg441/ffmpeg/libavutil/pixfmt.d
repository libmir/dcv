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
module ffmpeg.libavutil.pixfmt;
extern (C):

/**
 * @file
 * pixel format definitions
 */

enum AVPALETTE_SIZE = 1024;
enum AVPALETTE_COUNT = 256;

/**
 * Pixel format.
 *
 * @note
 * AV_PIX_FMT_RGB32 is handled in an endian-specific manner. An RGBA
 * color is put together as:
 *  (A << 24) | (R << 16) | (G << 8) | B
 * This is stored as BGRA on little-endian CPU architectures and ARGB on
 * big-endian CPUs.
 *
 * @note
 * If the resolution is not a multiple of the chroma subsampling factor
 * then the chroma plane resolution must be rounded up.
 *
 * @par
 * When the pixel format is palettized RGB32 (AV_PIX_FMT_PAL8), the palettized
 * image data is stored in AVFrame.data[0]. The palette is transported in
 * AVFrame.data[1], is 1024 bytes long (256 4-byte entries) and is
 * formatted the same as in AV_PIX_FMT_RGB32 described above (i.e., it is
 * also endian-specific). Note also that the individual RGB32 palette
 * components stored in AVFrame.data[1] should be in the range 0..255.
 * This is important as many custom PAL8 video codecs that were designed
 * to run on the IBM VGA graphics adapter use 6-bit palette components.
 *
 * @par
 * For all the 8 bits per pixel formats, an RGB32 palette is in data[1] like
 * for pal8. This palette is filled in automatically by the function
 * allocating the picture.
 */
enum AVPixelFormat
{
    AV_PIX_FMT_NONE = -1,
    AV_PIX_FMT_YUV420P = 0, ///< planar YUV 4:2:0, 12bpp, (1 Cr & Cb sample per 2x2 Y samples)
    AV_PIX_FMT_YUYV422 = 1, ///< packed YUV 4:2:2, 16bpp, Y0 Cb Y1 Cr
    AV_PIX_FMT_RGB24 = 2, ///< packed RGB 8:8:8, 24bpp, RGBRGB...
    AV_PIX_FMT_BGR24 = 3, ///< packed RGB 8:8:8, 24bpp, BGRBGR...
    AV_PIX_FMT_YUV422P = 4, ///< planar YUV 4:2:2, 16bpp, (1 Cr & Cb sample per 2x1 Y samples)
    AV_PIX_FMT_YUV444P = 5, ///< planar YUV 4:4:4, 24bpp, (1 Cr & Cb sample per 1x1 Y samples)
    AV_PIX_FMT_YUV410P = 6, ///< planar YUV 4:1:0,  9bpp, (1 Cr & Cb sample per 4x4 Y samples)
    AV_PIX_FMT_YUV411P = 7, ///< planar YUV 4:1:1, 12bpp, (1 Cr & Cb sample per 4x1 Y samples)
    AV_PIX_FMT_GRAY8 = 8, ///<        Y        ,  8bpp
    AV_PIX_FMT_MONOWHITE = 9, ///<        Y        ,  1bpp, 0 is white, 1 is black, in each byte pixels are ordered from the msb to the lsb
    AV_PIX_FMT_MONOBLACK = 10, ///<        Y        ,  1bpp, 0 is black, 1 is white, in each byte pixels are ordered from the msb to the lsb
    AV_PIX_FMT_PAL8 = 11, ///< 8 bits with AV_PIX_FMT_RGB32 palette
    AV_PIX_FMT_YUVJ420P = 12, ///< planar YUV 4:2:0, 12bpp, full scale (JPEG), deprecated in favor of AV_PIX_FMT_YUV420P and setting color_range
    AV_PIX_FMT_YUVJ422P = 13, ///< planar YUV 4:2:2, 16bpp, full scale (JPEG), deprecated in favor of AV_PIX_FMT_YUV422P and setting color_range
    AV_PIX_FMT_YUVJ444P = 14, ///< planar YUV 4:4:4, 24bpp, full scale (JPEG), deprecated in favor of AV_PIX_FMT_YUV444P and setting color_range
    AV_PIX_FMT_UYVY422 = 15, ///< packed YUV 4:2:2, 16bpp, Cb Y0 Cr Y1
    AV_PIX_FMT_UYYVYY411 = 16, ///< packed YUV 4:1:1, 12bpp, Cb Y0 Y1 Cr Y2 Y3
    AV_PIX_FMT_BGR8 = 17, ///< packed RGB 3:3:2,  8bpp, (msb)2B 3G 3R(lsb)
    AV_PIX_FMT_BGR4 = 18, ///< packed RGB 1:2:1 bitstream,  4bpp, (msb)1B 2G 1R(lsb), a byte contains two pixels, the first pixel in the byte is the one composed by the 4 msb bits
    AV_PIX_FMT_BGR4_BYTE = 19, ///< packed RGB 1:2:1,  8bpp, (msb)1B 2G 1R(lsb)
    AV_PIX_FMT_RGB8 = 20, ///< packed RGB 3:3:2,  8bpp, (msb)2R 3G 3B(lsb)
    AV_PIX_FMT_RGB4 = 21, ///< packed RGB 1:2:1 bitstream,  4bpp, (msb)1R 2G 1B(lsb), a byte contains two pixels, the first pixel in the byte is the one composed by the 4 msb bits
    AV_PIX_FMT_RGB4_BYTE = 22, ///< packed RGB 1:2:1,  8bpp, (msb)1R 2G 1B(lsb)
    AV_PIX_FMT_NV12 = 23, ///< planar YUV 4:2:0, 12bpp, 1 plane for Y and 1 plane for the UV components, which are interleaved (first byte U and the following byte V)
    AV_PIX_FMT_NV21 = 24, ///< as above, but U and V bytes are swapped

    AV_PIX_FMT_ARGB = 25, ///< packed ARGB 8:8:8:8, 32bpp, ARGBARGB...
    AV_PIX_FMT_RGBA = 26, ///< packed RGBA 8:8:8:8, 32bpp, RGBARGBA...
    AV_PIX_FMT_ABGR = 27, ///< packed ABGR 8:8:8:8, 32bpp, ABGRABGR...
    AV_PIX_FMT_BGRA = 28, ///< packed BGRA 8:8:8:8, 32bpp, BGRABGRA...

    AV_PIX_FMT_GRAY16BE = 29, ///<        Y        , 16bpp, big-endian
    AV_PIX_FMT_GRAY16LE = 30, ///<        Y        , 16bpp, little-endian
    AV_PIX_FMT_YUV440P = 31, ///< planar YUV 4:4:0 (1 Cr & Cb sample per 1x2 Y samples)
    AV_PIX_FMT_YUVJ440P = 32, ///< planar YUV 4:4:0 full scale (JPEG), deprecated in favor of AV_PIX_FMT_YUV440P and setting color_range
    AV_PIX_FMT_YUVA420P = 33, ///< planar YUV 4:2:0, 20bpp, (1 Cr & Cb sample per 2x2 Y & A samples)
    AV_PIX_FMT_RGB48BE = 34, ///< packed RGB 16:16:16, 48bpp, 16R, 16G, 16B, the 2-byte value for each R/G/B component is stored as big-endian
    AV_PIX_FMT_RGB48LE = 35, ///< packed RGB 16:16:16, 48bpp, 16R, 16G, 16B, the 2-byte value for each R/G/B component is stored as little-endian

    AV_PIX_FMT_RGB565BE = 36, ///< packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), big-endian
    AV_PIX_FMT_RGB565LE = 37, ///< packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), little-endian
    AV_PIX_FMT_RGB555BE = 38, ///< packed RGB 5:5:5, 16bpp, (msb)1X 5R 5G 5B(lsb), big-endian   , X=unused/undefined
    AV_PIX_FMT_RGB555LE = 39, ///< packed RGB 5:5:5, 16bpp, (msb)1X 5R 5G 5B(lsb), little-endian, X=unused/undefined

    AV_PIX_FMT_BGR565BE = 40, ///< packed BGR 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), big-endian
    AV_PIX_FMT_BGR565LE = 41, ///< packed BGR 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), little-endian
    AV_PIX_FMT_BGR555BE = 42, ///< packed BGR 5:5:5, 16bpp, (msb)1X 5B 5G 5R(lsb), big-endian   , X=unused/undefined
    AV_PIX_FMT_BGR555LE = 43, ///< packed BGR 5:5:5, 16bpp, (msb)1X 5B 5G 5R(lsb), little-endian, X=unused/undefined

    /** @name Deprecated pixel formats */
    /**@{*/
    AV_PIX_FMT_VAAPI_MOCO = 44, ///< HW acceleration through VA API at motion compensation entry-point, Picture.data[3] contains a vaapi_render_state struct which contains macroblocks as well as various fields extracted from headers
    AV_PIX_FMT_VAAPI_IDCT = 45, ///< HW acceleration through VA API at IDCT entry-point, Picture.data[3] contains a vaapi_render_state struct which contains fields extracted from headers
    AV_PIX_FMT_VAAPI_VLD = 46, ///< HW decoding through VA API, Picture.data[3] contains a VASurfaceID
    /**@}*/
    AV_PIX_FMT_VAAPI = AV_PIX_FMT_VAAPI_VLD,

    /**
     *  Hardware acceleration through VA-API, data[3] contains a
     *  VASurfaceID.
     */

    AV_PIX_FMT_YUV420P16LE = 47, ///< planar YUV 4:2:0, 24bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
    AV_PIX_FMT_YUV420P16BE = 48, ///< planar YUV 4:2:0, 24bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
    AV_PIX_FMT_YUV422P16LE = 49, ///< planar YUV 4:2:2, 32bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    AV_PIX_FMT_YUV422P16BE = 50, ///< planar YUV 4:2:2, 32bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    AV_PIX_FMT_YUV444P16LE = 51, ///< planar YUV 4:4:4, 48bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
    AV_PIX_FMT_YUV444P16BE = 52, ///< planar YUV 4:4:4, 48bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
    AV_PIX_FMT_DXVA2_VLD = 53, ///< HW decoding through DXVA2, Picture.data[3] contains a LPDIRECT3DSURFACE9 pointer

    AV_PIX_FMT_RGB444LE = 54, ///< packed RGB 4:4:4, 16bpp, (msb)4X 4R 4G 4B(lsb), little-endian, X=unused/undefined
    AV_PIX_FMT_RGB444BE = 55, ///< packed RGB 4:4:4, 16bpp, (msb)4X 4R 4G 4B(lsb), big-endian,    X=unused/undefined
    AV_PIX_FMT_BGR444LE = 56, ///< packed BGR 4:4:4, 16bpp, (msb)4X 4B 4G 4R(lsb), little-endian, X=unused/undefined
    AV_PIX_FMT_BGR444BE = 57, ///< packed BGR 4:4:4, 16bpp, (msb)4X 4B 4G 4R(lsb), big-endian,    X=unused/undefined
    AV_PIX_FMT_YA8 = 58, ///< 8 bits gray, 8 bits alpha

    AV_PIX_FMT_Y400A = AV_PIX_FMT_YA8, ///< alias for AV_PIX_FMT_YA8
    AV_PIX_FMT_GRAY8A = AV_PIX_FMT_YA8, ///< alias for AV_PIX_FMT_YA8

    AV_PIX_FMT_BGR48BE = 59, ///< packed RGB 16:16:16, 48bpp, 16B, 16G, 16R, the 2-byte value for each R/G/B component is stored as big-endian
    AV_PIX_FMT_BGR48LE = 60, ///< packed RGB 16:16:16, 48bpp, 16B, 16G, 16R, the 2-byte value for each R/G/B component is stored as little-endian

    /**
     * The following 12 formats have the disadvantage of needing 1 format for each bit depth.
     * Notice that each 9/10 bits sample is stored in 16 bits with extra padding.
     * If you want to support multiple bit depths, then using AV_PIX_FMT_YUV420P16* with the bpp stored separately is better.
     */
    AV_PIX_FMT_YUV420P9BE = 61, ///< planar YUV 4:2:0, 13.5bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
    AV_PIX_FMT_YUV420P9LE = 62, ///< planar YUV 4:2:0, 13.5bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
    AV_PIX_FMT_YUV420P10BE = 63, ///< planar YUV 4:2:0, 15bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
    AV_PIX_FMT_YUV420P10LE = 64, ///< planar YUV 4:2:0, 15bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
    AV_PIX_FMT_YUV422P10BE = 65, ///< planar YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    AV_PIX_FMT_YUV422P10LE = 66, ///< planar YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    AV_PIX_FMT_YUV444P9BE = 67, ///< planar YUV 4:4:4, 27bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
    AV_PIX_FMT_YUV444P9LE = 68, ///< planar YUV 4:4:4, 27bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
    AV_PIX_FMT_YUV444P10BE = 69, ///< planar YUV 4:4:4, 30bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
    AV_PIX_FMT_YUV444P10LE = 70, ///< planar YUV 4:4:4, 30bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
    AV_PIX_FMT_YUV422P9BE = 71, ///< planar YUV 4:2:2, 18bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    AV_PIX_FMT_YUV422P9LE = 72, ///< planar YUV 4:2:2, 18bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    AV_PIX_FMT_GBRP = 73, ///< planar GBR 4:4:4 24bpp
    AV_PIX_FMT_GBR24P = AV_PIX_FMT_GBRP, // alias for #AV_PIX_FMT_GBRP
    AV_PIX_FMT_GBRP9BE = 74, ///< planar GBR 4:4:4 27bpp, big-endian
    AV_PIX_FMT_GBRP9LE = 75, ///< planar GBR 4:4:4 27bpp, little-endian
    AV_PIX_FMT_GBRP10BE = 76, ///< planar GBR 4:4:4 30bpp, big-endian
    AV_PIX_FMT_GBRP10LE = 77, ///< planar GBR 4:4:4 30bpp, little-endian
    AV_PIX_FMT_GBRP16BE = 78, ///< planar GBR 4:4:4 48bpp, big-endian
    AV_PIX_FMT_GBRP16LE = 79, ///< planar GBR 4:4:4 48bpp, little-endian
    AV_PIX_FMT_YUVA422P = 80, ///< planar YUV 4:2:2 24bpp, (1 Cr & Cb sample per 2x1 Y & A samples)
    AV_PIX_FMT_YUVA444P = 81, ///< planar YUV 4:4:4 32bpp, (1 Cr & Cb sample per 1x1 Y & A samples)
    AV_PIX_FMT_YUVA420P9BE = 82, ///< planar YUV 4:2:0 22.5bpp, (1 Cr & Cb sample per 2x2 Y & A samples), big-endian
    AV_PIX_FMT_YUVA420P9LE = 83, ///< planar YUV 4:2:0 22.5bpp, (1 Cr & Cb sample per 2x2 Y & A samples), little-endian
    AV_PIX_FMT_YUVA422P9BE = 84, ///< planar YUV 4:2:2 27bpp, (1 Cr & Cb sample per 2x1 Y & A samples), big-endian
    AV_PIX_FMT_YUVA422P9LE = 85, ///< planar YUV 4:2:2 27bpp, (1 Cr & Cb sample per 2x1 Y & A samples), little-endian
    AV_PIX_FMT_YUVA444P9BE = 86, ///< planar YUV 4:4:4 36bpp, (1 Cr & Cb sample per 1x1 Y & A samples), big-endian
    AV_PIX_FMT_YUVA444P9LE = 87, ///< planar YUV 4:4:4 36bpp, (1 Cr & Cb sample per 1x1 Y & A samples), little-endian
    AV_PIX_FMT_YUVA420P10BE = 88, ///< planar YUV 4:2:0 25bpp, (1 Cr & Cb sample per 2x2 Y & A samples, big-endian)
    AV_PIX_FMT_YUVA420P10LE = 89, ///< planar YUV 4:2:0 25bpp, (1 Cr & Cb sample per 2x2 Y & A samples, little-endian)
    AV_PIX_FMT_YUVA422P10BE = 90, ///< planar YUV 4:2:2 30bpp, (1 Cr & Cb sample per 2x1 Y & A samples, big-endian)
    AV_PIX_FMT_YUVA422P10LE = 91, ///< planar YUV 4:2:2 30bpp, (1 Cr & Cb sample per 2x1 Y & A samples, little-endian)
    AV_PIX_FMT_YUVA444P10BE = 92, ///< planar YUV 4:4:4 40bpp, (1 Cr & Cb sample per 1x1 Y & A samples, big-endian)
    AV_PIX_FMT_YUVA444P10LE = 93, ///< planar YUV 4:4:4 40bpp, (1 Cr & Cb sample per 1x1 Y & A samples, little-endian)
    AV_PIX_FMT_YUVA420P16BE = 94, ///< planar YUV 4:2:0 40bpp, (1 Cr & Cb sample per 2x2 Y & A samples, big-endian)
    AV_PIX_FMT_YUVA420P16LE = 95, ///< planar YUV 4:2:0 40bpp, (1 Cr & Cb sample per 2x2 Y & A samples, little-endian)
    AV_PIX_FMT_YUVA422P16BE = 96, ///< planar YUV 4:2:2 48bpp, (1 Cr & Cb sample per 2x1 Y & A samples, big-endian)
    AV_PIX_FMT_YUVA422P16LE = 97, ///< planar YUV 4:2:2 48bpp, (1 Cr & Cb sample per 2x1 Y & A samples, little-endian)
    AV_PIX_FMT_YUVA444P16BE = 98, ///< planar YUV 4:4:4 64bpp, (1 Cr & Cb sample per 1x1 Y & A samples, big-endian)
    AV_PIX_FMT_YUVA444P16LE = 99, ///< planar YUV 4:4:4 64bpp, (1 Cr & Cb sample per 1x1 Y & A samples, little-endian)

    AV_PIX_FMT_VDPAU = 100, ///< HW acceleration through VDPAU, Picture.data[3] contains a VdpVideoSurface

    AV_PIX_FMT_XYZ12LE = 101, ///< packed XYZ 4:4:4, 36 bpp, (msb) 12X, 12Y, 12Z (lsb), the 2-byte value for each X/Y/Z is stored as little-endian, the 4 lower bits are set to 0
    AV_PIX_FMT_XYZ12BE = 102, ///< packed XYZ 4:4:4, 36 bpp, (msb) 12X, 12Y, 12Z (lsb), the 2-byte value for each X/Y/Z is stored as big-endian, the 4 lower bits are set to 0
    AV_PIX_FMT_NV16 = 103, ///< interleaved chroma YUV 4:2:2, 16bpp, (1 Cr & Cb sample per 2x1 Y samples)
    AV_PIX_FMT_NV20LE = 104, ///< interleaved chroma YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    AV_PIX_FMT_NV20BE = 105, ///< interleaved chroma YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian

    AV_PIX_FMT_RGBA64BE = 106, ///< packed RGBA 16:16:16:16, 64bpp, 16R, 16G, 16B, 16A, the 2-byte value for each R/G/B/A component is stored as big-endian
    AV_PIX_FMT_RGBA64LE = 107, ///< packed RGBA 16:16:16:16, 64bpp, 16R, 16G, 16B, 16A, the 2-byte value for each R/G/B/A component is stored as little-endian
    AV_PIX_FMT_BGRA64BE = 108, ///< packed RGBA 16:16:16:16, 64bpp, 16B, 16G, 16R, 16A, the 2-byte value for each R/G/B/A component is stored as big-endian
    AV_PIX_FMT_BGRA64LE = 109, ///< packed RGBA 16:16:16:16, 64bpp, 16B, 16G, 16R, 16A, the 2-byte value for each R/G/B/A component is stored as little-endian

    AV_PIX_FMT_YVYU422 = 110, ///< packed YUV 4:2:2, 16bpp, Y0 Cr Y1 Cb

    AV_PIX_FMT_YA16BE = 111, ///< 16 bits gray, 16 bits alpha (big-endian)
    AV_PIX_FMT_YA16LE = 112, ///< 16 bits gray, 16 bits alpha (little-endian)

    AV_PIX_FMT_GBRAP = 113, ///< planar GBRA 4:4:4:4 32bpp
    AV_PIX_FMT_GBRAP16BE = 114, ///< planar GBRA 4:4:4:4 64bpp, big-endian
    AV_PIX_FMT_GBRAP16LE = 115, ///< planar GBRA 4:4:4:4 64bpp, little-endian
    /**
     *  HW acceleration through QSV, data[3] contains a pointer to the
     *  mfxFrameSurface1 structure.
     */
    AV_PIX_FMT_QSV = 116,
    /**
     * HW acceleration though MMAL, data[3] contains a pointer to the
     * MMAL_BUFFER_HEADER_T structure.
     */
    AV_PIX_FMT_MMAL = 117,

    AV_PIX_FMT_D3D11VA_VLD = 118, ///< HW decoding through Direct3D11 via old API, Picture.data[3] contains a ID3D11VideoDecoderOutputView pointer

    /**
     * HW acceleration through CUDA. data[i] contain CUdeviceptr pointers
     * exactly as for system memory frames.
     */
    AV_PIX_FMT_CUDA = 119,

    AV_PIX_FMT_0RGB = 120, ///< packed RGB 8:8:8, 32bpp, XRGBXRGB...   X=unused/undefined
    AV_PIX_FMT_RGB0 = 121, ///< packed RGB 8:8:8, 32bpp, RGBXRGBX...   X=unused/undefined
    AV_PIX_FMT_0BGR = 122, ///< packed BGR 8:8:8, 32bpp, XBGRXBGR...   X=unused/undefined
    AV_PIX_FMT_BGR0 = 123, ///< packed BGR 8:8:8, 32bpp, BGRXBGRX...   X=unused/undefined

    AV_PIX_FMT_YUV420P12BE = 124, ///< planar YUV 4:2:0,18bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
    AV_PIX_FMT_YUV420P12LE = 125, ///< planar YUV 4:2:0,18bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
    AV_PIX_FMT_YUV420P14BE = 126, ///< planar YUV 4:2:0,21bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
    AV_PIX_FMT_YUV420P14LE = 127, ///< planar YUV 4:2:0,21bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
    AV_PIX_FMT_YUV422P12BE = 128, ///< planar YUV 4:2:2,24bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    AV_PIX_FMT_YUV422P12LE = 129, ///< planar YUV 4:2:2,24bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    AV_PIX_FMT_YUV422P14BE = 130, ///< planar YUV 4:2:2,28bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
    AV_PIX_FMT_YUV422P14LE = 131, ///< planar YUV 4:2:2,28bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
    AV_PIX_FMT_YUV444P12BE = 132, ///< planar YUV 4:4:4,36bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
    AV_PIX_FMT_YUV444P12LE = 133, ///< planar YUV 4:4:4,36bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
    AV_PIX_FMT_YUV444P14BE = 134, ///< planar YUV 4:4:4,42bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
    AV_PIX_FMT_YUV444P14LE = 135, ///< planar YUV 4:4:4,42bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
    AV_PIX_FMT_GBRP12BE = 136, ///< planar GBR 4:4:4 36bpp, big-endian
    AV_PIX_FMT_GBRP12LE = 137, ///< planar GBR 4:4:4 36bpp, little-endian
    AV_PIX_FMT_GBRP14BE = 138, ///< planar GBR 4:4:4 42bpp, big-endian
    AV_PIX_FMT_GBRP14LE = 139, ///< planar GBR 4:4:4 42bpp, little-endian
    AV_PIX_FMT_YUVJ411P = 140, ///< planar YUV 4:1:1, 12bpp, (1 Cr & Cb sample per 4x1 Y samples) full scale (JPEG), deprecated in favor of AV_PIX_FMT_YUV411P and setting color_range

    AV_PIX_FMT_BAYER_BGGR8 = 141, ///< bayer, BGBG..(odd line), GRGR..(even line), 8-bit samples
    AV_PIX_FMT_BAYER_RGGB8 = 142, ///< bayer, RGRG..(odd line), GBGB..(even line), 8-bit samples
    AV_PIX_FMT_BAYER_GBRG8 = 143, ///< bayer, GBGB..(odd line), RGRG..(even line), 8-bit samples
    AV_PIX_FMT_BAYER_GRBG8 = 144, ///< bayer, GRGR..(odd line), BGBG..(even line), 8-bit samples
    AV_PIX_FMT_BAYER_BGGR16LE = 145, ///< bayer, BGBG..(odd line), GRGR..(even line), 16-bit samples, little-endian
    AV_PIX_FMT_BAYER_BGGR16BE = 146, ///< bayer, BGBG..(odd line), GRGR..(even line), 16-bit samples, big-endian
    AV_PIX_FMT_BAYER_RGGB16LE = 147, ///< bayer, RGRG..(odd line), GBGB..(even line), 16-bit samples, little-endian
    AV_PIX_FMT_BAYER_RGGB16BE = 148, ///< bayer, RGRG..(odd line), GBGB..(even line), 16-bit samples, big-endian
    AV_PIX_FMT_BAYER_GBRG16LE = 149, ///< bayer, GBGB..(odd line), RGRG..(even line), 16-bit samples, little-endian
    AV_PIX_FMT_BAYER_GBRG16BE = 150, ///< bayer, GBGB..(odd line), RGRG..(even line), 16-bit samples, big-endian
    AV_PIX_FMT_BAYER_GRBG16LE = 151, ///< bayer, GRGR..(odd line), BGBG..(even line), 16-bit samples, little-endian
    AV_PIX_FMT_BAYER_GRBG16BE = 152, ///< bayer, GRGR..(odd line), BGBG..(even line), 16-bit samples, big-endian

    AV_PIX_FMT_XVMC = 153, ///< XVideo Motion Acceleration via common packet passing

    AV_PIX_FMT_YUV440P10LE = 154, ///< planar YUV 4:4:0,20bpp, (1 Cr & Cb sample per 1x2 Y samples), little-endian
    AV_PIX_FMT_YUV440P10BE = 155, ///< planar YUV 4:4:0,20bpp, (1 Cr & Cb sample per 1x2 Y samples), big-endian
    AV_PIX_FMT_YUV440P12LE = 156, ///< planar YUV 4:4:0,24bpp, (1 Cr & Cb sample per 1x2 Y samples), little-endian
    AV_PIX_FMT_YUV440P12BE = 157, ///< planar YUV 4:4:0,24bpp, (1 Cr & Cb sample per 1x2 Y samples), big-endian
    AV_PIX_FMT_AYUV64LE = 158, ///< packed AYUV 4:4:4,64bpp (1 Cr & Cb sample per 1x1 Y & A samples), little-endian
    AV_PIX_FMT_AYUV64BE = 159, ///< packed AYUV 4:4:4,64bpp (1 Cr & Cb sample per 1x1 Y & A samples), big-endian

    AV_PIX_FMT_VIDEOTOOLBOX = 160, ///< hardware decoding through Videotoolbox

    AV_PIX_FMT_P010LE = 161, ///< like NV12, with 10bpp per component, data in the high bits, zeros in the low bits, little-endian
    AV_PIX_FMT_P010BE = 162, ///< like NV12, with 10bpp per component, data in the high bits, zeros in the low bits, big-endian

    AV_PIX_FMT_GBRAP12BE = 163, ///< planar GBR 4:4:4:4 48bpp, big-endian
    AV_PIX_FMT_GBRAP12LE = 164, ///< planar GBR 4:4:4:4 48bpp, little-endian

    AV_PIX_FMT_GBRAP10BE = 165, ///< planar GBR 4:4:4:4 40bpp, big-endian
    AV_PIX_FMT_GBRAP10LE = 166, ///< planar GBR 4:4:4:4 40bpp, little-endian

    AV_PIX_FMT_MEDIACODEC = 167, ///< hardware decoding through MediaCodec

    AV_PIX_FMT_GRAY12BE = 168, ///<        Y        , 12bpp, big-endian
    AV_PIX_FMT_GRAY12LE = 169, ///<        Y        , 12bpp, little-endian
    AV_PIX_FMT_GRAY10BE = 170, ///<        Y        , 10bpp, big-endian
    AV_PIX_FMT_GRAY10LE = 171, ///<        Y        , 10bpp, little-endian

    AV_PIX_FMT_P016LE = 172, ///< like NV12, with 16bpp per component, little-endian
    AV_PIX_FMT_P016BE = 173, ///< like NV12, with 16bpp per component, big-endian

    /**
     * Hardware surfaces for Direct3D11.
     *
     * This is preferred over the legacy AV_PIX_FMT_D3D11VA_VLD. The new D3D11
     * hwaccel API and filtering support AV_PIX_FMT_D3D11 only.
     *
     * data[0] contains a ID3D11Texture2D pointer, and data[1] contains the
     * texture array index of the frame as intptr_t if the ID3D11Texture2D is
     * an array texture (or always 0 if it's a normal texture).
     */
    AV_PIX_FMT_D3D11 = 174,

    AV_PIX_FMT_GRAY9BE = 175, ///<        Y        , 9bpp, big-endian
    AV_PIX_FMT_GRAY9LE = 176, ///<        Y        , 9bpp, little-endian

    AV_PIX_FMT_GBRPF32BE = 177, ///< IEEE-754 single precision planar GBR 4:4:4,     96bpp, big-endian
    AV_PIX_FMT_GBRPF32LE = 178, ///< IEEE-754 single precision planar GBR 4:4:4,     96bpp, little-endian
    AV_PIX_FMT_GBRAPF32BE = 179, ///< IEEE-754 single precision planar GBRA 4:4:4:4, 128bpp, big-endian
    AV_PIX_FMT_GBRAPF32LE = 180, ///< IEEE-754 single precision planar GBRA 4:4:4:4, 128bpp, little-endian

    /**
     * DRM-managed buffers exposed through PRIME buffer sharing.
     *
     * data[0] points to an AVDRMFrameDescriptor.
     */
    AV_PIX_FMT_DRM_PRIME = 181,
    /**
     * Hardware surfaces for OpenCL.
     *
     * data[i] contain 2D image objects (typed in C as cl_mem, used
     * in OpenCL as image2d_t) for each plane of the surface.
     */
    AV_PIX_FMT_OPENCL = 182,

    AV_PIX_FMT_GRAY14BE = 183, ///<        Y        , 14bpp, big-endian
    AV_PIX_FMT_GRAY14LE = 184, ///<        Y        , 14bpp, little-endian

    AV_PIX_FMT_GRAYF32BE = 185, ///< IEEE-754 single precision Y, 32bpp, big-endian
    AV_PIX_FMT_GRAYF32LE = 186, ///< IEEE-754 single precision Y, 32bpp, little-endian

    AV_PIX_FMT_YUVA422P12BE = 187, ///< planar YUV 4:2:2,24bpp, (1 Cr & Cb sample per 2x1 Y samples), 12b alpha, big-endian
    AV_PIX_FMT_YUVA422P12LE = 188, ///< planar YUV 4:2:2,24bpp, (1 Cr & Cb sample per 2x1 Y samples), 12b alpha, little-endian
    AV_PIX_FMT_YUVA444P12BE = 189, ///< planar YUV 4:4:4,36bpp, (1 Cr & Cb sample per 1x1 Y samples), 12b alpha, big-endian
    AV_PIX_FMT_YUVA444P12LE = 190, ///< planar YUV 4:4:4,36bpp, (1 Cr & Cb sample per 1x1 Y samples), 12b alpha, little-endian

    AV_PIX_FMT_NV24 = 191, ///< planar YUV 4:4:4, 24bpp, 1 plane for Y and 1 plane for the UV components, which are interleaved (first byte U and the following byte V)
    AV_PIX_FMT_NV42 = 192, ///< as above, but U and V bytes are swapped

    /**
     * Vulkan hardware images.
     *
     * data[0] points to an AVVkFrame
     */
    AV_PIX_FMT_VULKAN = 193,

    AV_PIX_FMT_Y210BE = 194, ///< packed YUV 4:2:2 like YUYV422, 20bpp, data in the high bits, big-endian
    AV_PIX_FMT_Y210LE = 195, ///< packed YUV 4:2:2 like YUYV422, 20bpp, data in the high bits, little-endian

    AV_PIX_FMT_X2RGB10LE = 196, ///< packed RGB 10:10:10, 30bpp, (msb)2X 10R 10G 10B(lsb), little-endian, X=unused/undefined
    AV_PIX_FMT_X2RGB10BE = 197, ///< packed RGB 10:10:10, 30bpp, (msb)2X 10R 10G 10B(lsb), big-endian, X=unused/undefined
    AV_PIX_FMT_NB = 198 ///< number of pixel formats, DO NOT USE THIS if you want to link with shared libav* because the number of formats might differ between versions
}
//alias AVPixelFormat = int;

extern (D) static string AV_PIX_FMT_NE(T0, T1)(auto ref T0 be, auto ref T1 le)
{
    version(BigEndian){
        return "AVPixelFormat.AV_PIX_FMT_" ~ be;
    }else{
        return "AVPixelFormat.AV_PIX_FMT_" ~ le;
    }
    
}

enum AV_PIX_FMT_RGB32 = mixin(AV_PIX_FMT_NE("ARGB", "BGRA"));
enum AV_PIX_FMT_RGB32_1 = mixin(AV_PIX_FMT_NE("RGBA", "ABGR"));
enum AV_PIX_FMT_BGR32 = mixin(AV_PIX_FMT_NE("ABGR", "RGBA"));
enum AV_PIX_FMT_BGR32_1 = mixin(AV_PIX_FMT_NE("BGRA", "ARGB"));
enum AV_PIX_FMT_0RGB32 = mixin(AV_PIX_FMT_NE("0RGB", "BGR0"));
enum AV_PIX_FMT_0BGR32 = mixin(AV_PIX_FMT_NE("0BGR", "RGB0"));

enum AV_PIX_FMT_GRAY9 = mixin(AV_PIX_FMT_NE("GRAY9BE", "GRAY9LE"));
enum AV_PIX_FMT_GRAY10 = mixin(AV_PIX_FMT_NE("GRAY10BE", "GRAY10LE"));
enum AV_PIX_FMT_GRAY12 = mixin(AV_PIX_FMT_NE("GRAY12BE", "GRAY12LE"));
enum AV_PIX_FMT_GRAY14 = mixin(AV_PIX_FMT_NE("GRAY14BE", "GRAY14LE"));
enum AV_PIX_FMT_GRAY16 = mixin(AV_PIX_FMT_NE("GRAY16BE", "GRAY16LE"));
enum AV_PIX_FMT_YA16 = mixin(AV_PIX_FMT_NE("YA16BE", "YA16LE"));
enum AV_PIX_FMT_RGB48 = mixin(AV_PIX_FMT_NE("RGB48BE", "RGB48LE"));
enum AV_PIX_FMT_RGB565 = mixin(AV_PIX_FMT_NE("RGB565BE", "RGB565LE"));
enum AV_PIX_FMT_RGB555 = mixin(AV_PIX_FMT_NE("RGB555BE", "RGB555LE"));
enum AV_PIX_FMT_RGB444 = mixin(AV_PIX_FMT_NE("RGB444BE", "RGB444LE"));
enum AV_PIX_FMT_RGBA64 = mixin(AV_PIX_FMT_NE("RGBA64BE", "RGBA64LE"));
enum AV_PIX_FMT_BGR48 = mixin(AV_PIX_FMT_NE("BGR48BE", "BGR48LE"));
enum AV_PIX_FMT_BGR565 = mixin(AV_PIX_FMT_NE("BGR565BE", "BGR565LE"));
enum AV_PIX_FMT_BGR555 = mixin(AV_PIX_FMT_NE("BGR555BE", "BGR555LE"));
enum AV_PIX_FMT_BGR444 = mixin(AV_PIX_FMT_NE("BGR444BE", "BGR444LE"));
enum AV_PIX_FMT_BGRA64 = mixin(AV_PIX_FMT_NE("BGRA64BE", "BGRA64LE"));

enum AV_PIX_FMT_YUV420P9 = mixin(AV_PIX_FMT_NE("YUV420P9BE", "YUV420P9LE"));
enum AV_PIX_FMT_YUV422P9 = mixin(AV_PIX_FMT_NE("YUV422P9BE", "YUV422P9LE"));
enum AV_PIX_FMT_YUV444P9 = mixin(AV_PIX_FMT_NE("YUV444P9BE", "YUV444P9LE"));
enum AV_PIX_FMT_YUV420P10 = mixin(AV_PIX_FMT_NE("YUV420P10BE", "YUV420P10LE"));
enum AV_PIX_FMT_YUV422P10 = mixin(AV_PIX_FMT_NE("YUV422P10BE", "YUV422P10LE"));
enum AV_PIX_FMT_YUV440P10 = mixin(AV_PIX_FMT_NE("YUV440P10BE", "YUV440P10LE"));
enum AV_PIX_FMT_YUV444P10 = mixin(AV_PIX_FMT_NE("YUV444P10BE", "YUV444P10LE"));
enum AV_PIX_FMT_YUV420P12 = mixin(AV_PIX_FMT_NE("YUV420P12BE", "YUV420P12LE"));
enum AV_PIX_FMT_YUV422P12 = mixin(AV_PIX_FMT_NE("YUV422P12BE", "YUV422P12LE"));
enum AV_PIX_FMT_YUV440P12 = mixin(AV_PIX_FMT_NE("YUV440P12BE", "YUV440P12LE"));
enum AV_PIX_FMT_YUV444P12 = mixin(AV_PIX_FMT_NE("YUV444P12BE", "YUV444P12LE"));
enum AV_PIX_FMT_YUV420P14 = mixin(AV_PIX_FMT_NE("YUV420P14BE", "YUV420P14LE"));
enum AV_PIX_FMT_YUV422P14 = mixin(AV_PIX_FMT_NE("YUV422P14BE", "YUV422P14LE"));
enum AV_PIX_FMT_YUV444P14 = mixin(AV_PIX_FMT_NE("YUV444P14BE", "YUV444P14LE"));
enum AV_PIX_FMT_YUV420P16 = mixin(AV_PIX_FMT_NE("YUV420P16BE", "YUV420P16LE"));
enum AV_PIX_FMT_YUV422P16 = mixin(AV_PIX_FMT_NE("YUV422P16BE", "YUV422P16LE"));
enum AV_PIX_FMT_YUV444P16 = mixin(AV_PIX_FMT_NE("YUV444P16BE", "YUV444P16LE"));

enum AV_PIX_FMT_GBRP9 = mixin(AV_PIX_FMT_NE("GBRP9BE", "GBRP9LE"));
enum AV_PIX_FMT_GBRP10 = mixin(AV_PIX_FMT_NE("GBRP10BE", "GBRP10LE"));
enum AV_PIX_FMT_GBRP12 = mixin(AV_PIX_FMT_NE("GBRP12BE", "GBRP12LE"));
enum AV_PIX_FMT_GBRP14 = mixin(AV_PIX_FMT_NE("GBRP14BE", "GBRP14LE"));
enum AV_PIX_FMT_GBRP16 = mixin(AV_PIX_FMT_NE("GBRP16BE", "GBRP16LE"));
enum AV_PIX_FMT_GBRAP10 = mixin(AV_PIX_FMT_NE("GBRAP10BE", "GBRAP10LE"));
enum AV_PIX_FMT_GBRAP12 = mixin(AV_PIX_FMT_NE("GBRAP12BE", "GBRAP12LE"));
enum AV_PIX_FMT_GBRAP16 = mixin(AV_PIX_FMT_NE("GBRAP16BE", "GBRAP16LE"));

enum AV_PIX_FMT_BAYER_BGGR16 = mixin(AV_PIX_FMT_NE("BAYER_BGGR16BE", "BAYER_BGGR16LE"));
enum AV_PIX_FMT_BAYER_RGGB16 = mixin(AV_PIX_FMT_NE("BAYER_RGGB16BE", "BAYER_RGGB16LE"));
enum AV_PIX_FMT_BAYER_GBRG16 = mixin(AV_PIX_FMT_NE("BAYER_GBRG16BE", "BAYER_GBRG16LE"));
enum AV_PIX_FMT_BAYER_GRBG16 = mixin(AV_PIX_FMT_NE("BAYER_GRBG16BE", "BAYER_GRBG16LE"));

enum AV_PIX_FMT_GBRPF32 = mixin(AV_PIX_FMT_NE("GBRPF32BE", "GBRPF32LE"));
enum AV_PIX_FMT_GBRAPF32 = mixin(AV_PIX_FMT_NE("GBRAPF32BE", "GBRAPF32LE"));

enum AV_PIX_FMT_GRAYF32 = mixin(AV_PIX_FMT_NE("GRAYF32BE", "GRAYF32LE"));

enum AV_PIX_FMT_YUVA420P9 = mixin(AV_PIX_FMT_NE("YUVA420P9BE", "YUVA420P9LE"));
enum AV_PIX_FMT_YUVA422P9 = mixin(AV_PIX_FMT_NE("YUVA422P9BE", "YUVA422P9LE"));
enum AV_PIX_FMT_YUVA444P9 = mixin(AV_PIX_FMT_NE("YUVA444P9BE", "YUVA444P9LE"));
enum AV_PIX_FMT_YUVA420P10 = mixin(AV_PIX_FMT_NE("YUVA420P10BE", "YUVA420P10LE"));
enum AV_PIX_FMT_YUVA422P10 = mixin(AV_PIX_FMT_NE("YUVA422P10BE", "YUVA422P10LE"));
enum AV_PIX_FMT_YUVA444P10 = mixin(AV_PIX_FMT_NE("YUVA444P10BE", "YUVA444P10LE"));
enum AV_PIX_FMT_YUVA422P12 = mixin(AV_PIX_FMT_NE("YUVA422P12BE", "YUVA422P12LE"));
enum AV_PIX_FMT_YUVA444P12 = mixin(AV_PIX_FMT_NE("YUVA444P12BE", "YUVA444P12LE"));
enum AV_PIX_FMT_YUVA420P16 = mixin(AV_PIX_FMT_NE("YUVA420P16BE", "YUVA420P16LE"));
enum AV_PIX_FMT_YUVA422P16 = mixin(AV_PIX_FMT_NE("YUVA422P16BE", "YUVA422P16LE"));
enum AV_PIX_FMT_YUVA444P16 = mixin(AV_PIX_FMT_NE("YUVA444P16BE", "YUVA444P16LE"));

enum AV_PIX_FMT_XYZ12 = mixin(AV_PIX_FMT_NE("XYZ12BE", "XYZ12LE"));
enum AV_PIX_FMT_NV20 = mixin(AV_PIX_FMT_NE("NV20BE", "NV20LE"));
enum AV_PIX_FMT_AYUV64 = mixin(AV_PIX_FMT_NE("AYUV64BE", "AYUV64LE"));
enum AV_PIX_FMT_P010 = mixin(AV_PIX_FMT_NE("P010BE", "P010LE"));
enum AV_PIX_FMT_P016 = mixin(AV_PIX_FMT_NE("P016BE", "P016LE"));

enum AV_PIX_FMT_Y210 = mixin(AV_PIX_FMT_NE("Y210BE", "Y210LE"));
enum AV_PIX_FMT_X2RGB10 = mixin(AV_PIX_FMT_NE("X2RGB10BE", "X2RGB10LE"));

/**
  * Chromaticity coordinates of the source primaries.
  * These values match the ones defined by ISO/IEC 23001-8_2013 § 7.1.
  */
enum AVColorPrimaries
{
    AVCOL_PRI_RESERVED0 = 0,
    AVCOL_PRI_BT709 = 1, ///< also ITU-R BT1361 / IEC 61966-2-4 / SMPTE RP177 Annex B
    AVCOL_PRI_UNSPECIFIED = 2,
    AVCOL_PRI_RESERVED = 3,
    AVCOL_PRI_BT470M = 4, ///< also FCC Title 47 Code of Federal Regulations 73.682 (a)(20)

    AVCOL_PRI_BT470BG = 5, ///< also ITU-R BT601-6 625 / ITU-R BT1358 625 / ITU-R BT1700 625 PAL & SECAM
    AVCOL_PRI_SMPTE170M = 6, ///< also ITU-R BT601-6 525 / ITU-R BT1358 525 / ITU-R BT1700 NTSC
    AVCOL_PRI_SMPTE240M = 7, ///< functionally identical to above
    AVCOL_PRI_FILM = 8, ///< colour filters using Illuminant C
    AVCOL_PRI_BT2020 = 9, ///< ITU-R BT2020
    AVCOL_PRI_SMPTE428 = 10, ///< SMPTE ST 428-1 (CIE 1931 XYZ)
    AVCOL_PRI_SMPTEST428_1 = AVCOL_PRI_SMPTE428,
    AVCOL_PRI_SMPTE431 = 11, ///< SMPTE ST 431-2 (2011) / DCI P3
    AVCOL_PRI_SMPTE432 = 12, ///< SMPTE ST 432-1 (2010) / P3 D65 / Display P3
    AVCOL_PRI_EBU3213 = 22, ///< EBU Tech. 3213-E / JEDEC P22 phosphors
    AVCOL_PRI_JEDEC_P22 = AVCOL_PRI_EBU3213,
    AVCOL_PRI_NB = 23 ///< Not part of ABI
}

/**
 * Color Transfer Characteristic.
 * These values match the ones defined by ISO/IEC 23001-8_2013 § 7.2.
 */
enum AVColorTransferCharacteristic
{
    AVCOL_TRC_RESERVED0 = 0,
    AVCOL_TRC_BT709 = 1, ///< also ITU-R BT1361
    AVCOL_TRC_UNSPECIFIED = 2,
    AVCOL_TRC_RESERVED = 3,
    AVCOL_TRC_GAMMA22 = 4, ///< also ITU-R BT470M / ITU-R BT1700 625 PAL & SECAM
    AVCOL_TRC_GAMMA28 = 5, ///< also ITU-R BT470BG
    AVCOL_TRC_SMPTE170M = 6, ///< also ITU-R BT601-6 525 or 625 / ITU-R BT1358 525 or 625 / ITU-R BT1700 NTSC
    AVCOL_TRC_SMPTE240M = 7,
    AVCOL_TRC_LINEAR = 8, ///< "Linear transfer characteristics"
    AVCOL_TRC_LOG = 9, ///< "Logarithmic transfer characteristic (100:1 range)"
    AVCOL_TRC_LOG_SQRT = 10, ///< "Logarithmic transfer characteristic (100 * Sqrt(10) : 1 range)"
    AVCOL_TRC_IEC61966_2_4 = 11, ///< IEC 61966-2-4
    AVCOL_TRC_BT1361_ECG = 12, ///< ITU-R BT1361 Extended Colour Gamut
    AVCOL_TRC_IEC61966_2_1 = 13, ///< IEC 61966-2-1 (sRGB or sYCC)
    AVCOL_TRC_BT2020_10 = 14, ///< ITU-R BT2020 for 10-bit system
    AVCOL_TRC_BT2020_12 = 15, ///< ITU-R BT2020 for 12-bit system
    AVCOL_TRC_SMPTE2084 = 16, ///< SMPTE ST 2084 for 10-, 12-, 14- and 16-bit systems
    AVCOL_TRC_SMPTEST2084 = AVCOL_TRC_SMPTE2084,
    AVCOL_TRC_SMPTE428 = 17, ///< SMPTE ST 428-1
    AVCOL_TRC_SMPTEST428_1 = AVCOL_TRC_SMPTE428,
    AVCOL_TRC_ARIB_STD_B67 = 18, ///< ARIB STD-B67, known as "Hybrid log-gamma"
    AVCOL_TRC_NB = 19 ///< Not part of ABI
}

/**
 * YUV colorspace type.
 * These values match the ones defined by ISO/IEC 23001-8_2013 § 7.3.
 */
enum AVColorSpace
{
    AVCOL_SPC_RGB = 0, ///< order of coefficients is actually GBR, also IEC 61966-2-1 (sRGB)
    AVCOL_SPC_BT709 = 1, ///< also ITU-R BT1361 / IEC 61966-2-4 xvYCC709 / SMPTE RP177 Annex B
    AVCOL_SPC_UNSPECIFIED = 2,
    AVCOL_SPC_RESERVED = 3,
    AVCOL_SPC_FCC = 4, ///< FCC Title 47 Code of Federal Regulations 73.682 (a)(20)
    AVCOL_SPC_BT470BG = 5, ///< also ITU-R BT601-6 625 / ITU-R BT1358 625 / ITU-R BT1700 625 PAL & SECAM / IEC 61966-2-4 xvYCC601
    AVCOL_SPC_SMPTE170M = 6, ///< also ITU-R BT601-6 525 / ITU-R BT1358 525 / ITU-R BT1700 NTSC
    AVCOL_SPC_SMPTE240M = 7, ///< functionally identical to above
    AVCOL_SPC_YCGCO = 8, ///< Used by Dirac / VC-2 and H.264 FRext, see ITU-T SG16
    AVCOL_SPC_YCOCG = AVCOL_SPC_YCGCO,
    AVCOL_SPC_BT2020_NCL = 9, ///< ITU-R BT2020 non-constant luminance system
    AVCOL_SPC_BT2020_CL = 10, ///< ITU-R BT2020 constant luminance system
    AVCOL_SPC_SMPTE2085 = 11, ///< SMPTE 2085, Y'D'zD'x
    AVCOL_SPC_CHROMA_DERIVED_NCL = 12, ///< Chromaticity-derived non-constant luminance system
    AVCOL_SPC_CHROMA_DERIVED_CL = 13, ///< Chromaticity-derived constant luminance system
    AVCOL_SPC_ICTCP = 14, ///< ITU-R BT.2100-0, ICtCp
    AVCOL_SPC_NB = 15 ///< Not part of ABI
}

/**
 * Visual content value range.
 *
 * These values are based on definitions that can be found in multiple
 * specifications, such as ITU-T BT.709 (3.4 - Quantization of RGB, luminance
 * and colour-difference signals), ITU-T BT.2020 (Table 5 - Digital
 * Representation) as well as ITU-T BT.2100 (Table 9 - Digital 10- and 12-bit
 * integer representation). At the time of writing, the BT.2100 one is
 * recommended, as it also defines the full range representation.
 *
 * Common definitions:
 *   - For RGB and luminance planes such as Y in YCbCr and I in ICtCp,
 *     'E' is the original value in range of 0.0 to 1.0.
 *   - For chrominance planes such as Cb,Cr and Ct,Cp, 'E' is the original
 *     value in range of -0.5 to 0.5.
 *   - 'n' is the output bit depth.
 *   - For additional definitions such as rounding and clipping to valid n
 *     bit unsigned integer range, please refer to BT.2100 (Table 9).
 */
enum AVColorRange
{
    AVCOL_RANGE_UNSPECIFIED = 0,

    /**
     * Narrow or limited range content.
     *
     * - For luminance planes:
     *
     *       (219 * E + 16) * 2^(n-8)
     *
     *   F.ex. the range of 16-235 for 8 bits
     *
     * - For chrominance planes:
     *
     *       (224 * E + 128) * 2^(n-8)
     *
     *   F.ex. the range of 16-240 for 8 bits
     */
    AVCOL_RANGE_MPEG = 1,

    /**
     * Full range content.
     *
     * - For RGB and luminance planes:
     *
     *       (2^n - 1) * E
     *
     *   F.ex. the range of 0-255 for 8 bits
     *
     * - For chrominance planes:
     *
     *       (2^n - 1) * E + 2^(n - 1)
     *
     *   F.ex. the range of 1-255 for 8 bits
     */
    AVCOL_RANGE_JPEG = 2,
    AVCOL_RANGE_NB = 3 ///< Not part of ABI
}

/**
 * Location of chroma samples.
 *
 * Illustration showing the location of the first (top left) chroma sample of the
 * image, the left shows only luma, the right
 * shows the location of the chroma sample, the 2 could be imagined to overlay
 * each other but are drawn separately due to limitations of ASCII
 *
 *                1st 2nd       1st 2nd horizontal luma sample positions
 *                 v   v         v   v
 *                 ______        ______
 *1st luma line > |X   X ...    |3 4 X ...     X are luma samples,
 *                |             |1 2           1-6 are possible chroma positions
 *2nd luma line > |X   X ...    |5 6 X ...     0 is undefined/unknown position
 */
enum AVChromaLocation
{
    AVCHROMA_LOC_UNSPECIFIED = 0,
    AVCHROMA_LOC_LEFT = 1, ///< MPEG-2/4 4:2:0, H.264 default for 4:2:0
    AVCHROMA_LOC_CENTER = 2, ///< MPEG-1 4:2:0, JPEG 4:2:0, H.263 4:2:0
    AVCHROMA_LOC_TOPLEFT = 3, ///< ITU-R 601, SMPTE 274M 296M S314M(DV 4:1:1), mpeg2 4:2:2
    AVCHROMA_LOC_TOP = 4,
    AVCHROMA_LOC_BOTTOMLEFT = 5,
    AVCHROMA_LOC_BOTTOM = 6,
    AVCHROMA_LOC_NB = 7 ///< Not part of ABI
}

/* AVUTIL_PIXFMT_H */
