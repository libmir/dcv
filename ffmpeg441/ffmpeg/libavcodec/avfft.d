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
module ffmpeg.libavcodec.avfft;

import ffmpeg.libavcodec;

extern (C):

/**
 * @file
 * @ingroup lavc_fft
 * FFT functions
 */

/**
 * @defgroup lavc_fft FFT functions
 * @ingroup lavc_misc
 *
 * @{
 */

alias FFTSample = float;

struct FFTComplex
{
    FFTSample re;
    FFTSample im;
}

struct FFTContext;

/**
 * Set up a complex FFT.
 * @param nbits           log2 of the length of the input array
 * @param inverse         if 0 perform the forward transform, if 1 perform the inverse
 */
FFTContext* av_fft_init (int nbits, int inverse);

/**
 * Do the permutation needed BEFORE calling ff_fft_calc().
 */
void av_fft_permute (FFTContext* s, FFTComplex* z);

/**
 * Do a complex FFT with the parameters defined in av_fft_init(). The
 * input data must be permuted before. No 1.0/sqrt(n) normalization is done.
 */
void av_fft_calc (FFTContext* s, FFTComplex* z);

void av_fft_end (FFTContext* s);

FFTContext* av_mdct_init (int nbits, int inverse, double scale);
void av_imdct_calc (FFTContext* s, FFTSample* output, const(FFTSample)* input);
void av_imdct_half (FFTContext* s, FFTSample* output, const(FFTSample)* input);
void av_mdct_calc (FFTContext* s, FFTSample* output, const(FFTSample)* input);
void av_mdct_end (FFTContext* s);

/* Real Discrete Fourier Transform */

enum RDFTransformType
{
    DFT_R2C = 0,
    IDFT_C2R = 1,
    IDFT_R2C = 2,
    DFT_C2R = 3
}

struct RDFTContext;

/**
 * Set up a real FFT.
 * @param nbits           log2 of the length of the input array
 * @param trans           the type of transform
 */
RDFTContext* av_rdft_init (int nbits, RDFTransformType trans);
void av_rdft_calc (RDFTContext* s, FFTSample* data);
void av_rdft_end (RDFTContext* s);

/* Discrete Cosine Transform */

struct DCTContext;

enum DCTTransformType
{
    DCT_II = 0,
    DCT_III = 1,
    DCT_I = 2,
    DST_I = 3
}

/**
 * Set up DCT.
 *
 * @param nbits           size of the input array:
 *                        (1 << nbits)     for DCT-II, DCT-III and DST-I
 *                        (1 << nbits) + 1 for DCT-I
 * @param type            the type of transform
 *
 * @note the first element of the input of DST-I is ignored
 */
DCTContext* av_dct_init (int nbits, DCTTransformType type);
void av_dct_calc (DCTContext* s, FFTSample* data);
void av_dct_end (DCTContext* s);

/**
 * @}
 */

/* AVCODEC_AVFFT_H */
