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
 * error code definitions
 */
module ffmpeg.libavutil.error;

import ffmpeg.libavutil.common;

extern (C):

/**
 * @addtogroup lavu_error
 *
 * @{
 */

/* error handling */
extern (D) auto AVERROR(T)(auto ref T e)
{
    return -e;
} ///< Returns a negative error code from a POSIX error code, to return from library functions.
extern (D) auto AVUNERROR(T)(auto ref T e)
{
    return -e;
} ///< Returns a POSIX error code from a library function error return value.

/* Some platforms have E* and errno already negated. */

extern (D) auto FFERRTAG(T0, T1, T2, T3)(auto ref T0 a, auto ref T1 b, auto ref T2 c, auto ref T3 d)
{
    return -cast(int) MKTAG(a, b, c, d);
}

enum AVERROR_BSF_NOT_FOUND = FFERRTAG(0xF8, 'B', 'S', 'F'); ///< Bitstream filter not found
enum AVERROR_BUG = FFERRTAG('B', 'U', 'G', '!'); ///< Internal bug, also see AVERROR_BUG2
enum AVERROR_BUFFER_TOO_SMALL = FFERRTAG('B', 'U', 'F', 'S'); ///< Buffer too small
enum AVERROR_DECODER_NOT_FOUND = FFERRTAG(0xF8, 'D', 'E', 'C'); ///< Decoder not found
enum AVERROR_DEMUXER_NOT_FOUND = FFERRTAG(0xF8, 'D', 'E', 'M'); ///< Demuxer not found
enum AVERROR_ENCODER_NOT_FOUND = FFERRTAG(0xF8, 'E', 'N', 'C'); ///< Encoder not found
enum AVERROR_EOF = FFERRTAG('E', 'O', 'F', ' '); ///< End of file
enum AVERROR_EXIT = FFERRTAG('E', 'X', 'I', 'T'); ///< Immediate exit was requested; the called function should not be restarted
enum AVERROR_EXTERNAL = FFERRTAG('E', 'X', 'T', ' '); ///< Generic error in an external library
enum AVERROR_FILTER_NOT_FOUND = FFERRTAG(0xF8, 'F', 'I', 'L'); ///< Filter not found
enum AVERROR_INVALIDDATA = FFERRTAG('I', 'N', 'D', 'A'); ///< Invalid data found when processing input
enum AVERROR_MUXER_NOT_FOUND = FFERRTAG(0xF8, 'M', 'U', 'X'); ///< Muxer not found
enum AVERROR_OPTION_NOT_FOUND = FFERRTAG(0xF8, 'O', 'P', 'T'); ///< Option not found
enum AVERROR_PATCHWELCOME = FFERRTAG('P', 'A', 'W', 'E'); ///< Not yet implemented in FFmpeg, patches welcome
enum AVERROR_PROTOCOL_NOT_FOUND = FFERRTAG(0xF8, 'P', 'R', 'O'); ///< Protocol not found

enum AVERROR_STREAM_NOT_FOUND = FFERRTAG(0xF8, 'S', 'T', 'R'); ///< Stream not found
/**
 * This is semantically identical to AVERROR_BUG
 * it has been introduced in Libav after our AVERROR_BUG and with a modified value.
 */
enum AVERROR_BUG2 = FFERRTAG('B', 'U', 'G', ' ');
enum AVERROR_UNKNOWN = FFERRTAG('U', 'N', 'K', 'N'); ///< Unknown error, typically from an external library
enum AVERROR_EXPERIMENTAL = -0x2bb2afa8; ///< Requested feature is flagged experimental. Set strict_std_compliance if you really want to use it.
enum AVERROR_INPUT_CHANGED = -0x636e6701; ///< Input changed between calls. Reconfiguration is required. (can be OR-ed with AVERROR_OUTPUT_CHANGED)
enum AVERROR_OUTPUT_CHANGED = -0x636e6702; ///< Output changed between calls. Reconfiguration is required. (can be OR-ed with AVERROR_INPUT_CHANGED)
/* HTTP & RTSP errors */
enum AVERROR_HTTP_BAD_REQUEST = FFERRTAG(0xF8, '4', '0', '0');
enum AVERROR_HTTP_UNAUTHORIZED = FFERRTAG(0xF8, '4', '0', '1');
enum AVERROR_HTTP_FORBIDDEN = FFERRTAG(0xF8, '4', '0', '3');
enum AVERROR_HTTP_NOT_FOUND = FFERRTAG(0xF8, '4', '0', '4');
enum AVERROR_HTTP_OTHER_4XX = FFERRTAG(0xF8, '4', 'X', 'X');
enum AVERROR_HTTP_SERVER_ERROR = FFERRTAG(0xF8, '5', 'X', 'X');

enum AV_ERROR_MAX_STRING_SIZE = 64;

/**
 * Put a description of the AVERROR code errnum in errbuf.
 * In case of failure the global variable errno is set to indicate the
 * error. Even in case of failure av_strerror() will print a generic
 * error message indicating the errnum provided to errbuf.
 *
 * @param errnum      error code to describe
 * @param errbuf      buffer to which description is written
 * @param errbuf_size the size in bytes of errbuf
 * @return 0 on success, a negative value if a description for errnum
 * cannot be found
 */
int av_strerror (int errnum, char* errbuf, size_t errbuf_size);

/**
 * Fill the provided buffer with a string containing an error string
 * corresponding to the AVERROR code errnum.
 *
 * @param errbuf         a buffer
 * @param errbuf_size    size in bytes of errbuf
 * @param errnum         error code to describe
 * @return the buffer in input, filled with the error description
 * @see av_strerror()
 */
char* av_make_error_string (char* errbuf, size_t errbuf_size, int errnum);

/**
 * Convenience macro, the return value should be used only directly in
 * function arguments but never stand-alone.
 */

/**
 * @}
 */

/* AVUTIL_ERROR_H */
