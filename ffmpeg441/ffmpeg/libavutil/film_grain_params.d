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
module ffmpeg.libavutil.film_grain_params;

import ffmpeg.libavutil.frame;

extern (C):

enum AVFilmGrainParamsType
{
    AV_FILM_GRAIN_PARAMS_NONE = 0,

    /**
     * The union is valid when interpreted as AVFilmGrainAOMParams (codec.aom)
     */
    AV_FILM_GRAIN_PARAMS_AV1 = 1
}

/**
 * This structure describes how to handle film grain synthesis for AOM codecs.
 *
 * @note The struct must be allocated as part of AVFilmGrainParams using
 *       av_film_grain_params_alloc(). Its size is not a part of the public ABI.
 */
struct AVFilmGrainAOMParams
{
    /**
     * Number of points, and the scale and value for each point of the
     * piecewise linear scaling function for the uma plane.
     */
    int num_y_points;
    /* value, scaling */
    ubyte[/* value, scaling */][14] y_points;

    /**
     * Signals whether to derive the chroma scaling function from the luma.
     * Not equivalent to copying the luma values and scales.
     */
    int chroma_scaling_from_luma;

    /**
     * If chroma_scaling_from_luma is set to 0, signals the chroma scaling
     * function parameters.
     */
    /* cb, cr */
    int[/* cb, cr */] num_uv_points;
    /* cb, cr */ /* value, scaling */
    ubyte[/* value, scaling */][10][/* cb, cr */] uv_points;

    /**
     * Specifies the shift applied to the chroma components. For AV1, its within
     * [8; 11] and determines the range and quantization of the film grain.
     */
    int scaling_shift;

    /**
     * Specifies the auto-regression lag.
     */
    int ar_coeff_lag;

    /**
     * Luma auto-regression coefficients. The number of coefficients is given by
     * 2 * ar_coeff_lag * (ar_coeff_lag + 1).
     */
    byte[24] ar_coeffs_y;

    /**
     * Chroma auto-regression coefficients. The number of coefficients is given by
     * 2 * ar_coeff_lag * (ar_coeff_lag + 1) + !!num_y_points.
     */
    /* cb, cr */
    byte[25][/* cb, cr */] ar_coeffs_uv;

    /**
     * Specifies the range of the auto-regressive coefficients. Values of 6,
     * 7, 8 and so on represent a range of [-2, 2), [-1, 1), [-0.5, 0.5) and
     * so on. For AV1 must be between 6 and 9.
     */
    int ar_coeff_shift;

    /**
     * Signals the down shift applied to the generated gaussian numbers during
     * synthesis.
     */
    int grain_scale_shift;

    /**
     * Specifies the luma/chroma multipliers for the index to the component
     * scaling function.
     */
    /* cb, cr */
    int[/* cb, cr */] uv_mult;
    /* cb, cr */
    int[/* cb, cr */] uv_mult_luma;

    /**
     * Offset used for component scaling function. For AV1 its a 9-bit value
     * with a range [-256, 255]
     */
    /* cb, cr */
    int[/* cb, cr */] uv_offset;

    /**
     * Signals whether to overlap film grain blocks.
     */
    int overlap_flag;

    /**
     * Signals to clip to limited color levels after film grain application.
     */
    int limit_output_range;
}

/**
 * This structure describes how to handle film grain synthesis in video
 * for specific codecs. Must be present on every frame where film grain is
 * meant to be synthesised for correct presentation.
 *
 * @note The struct must be allocated with av_film_grain_params_alloc() and
 *       its size is not a part of the public ABI.
 */
struct AVFilmGrainParams
{
    /**
     * Specifies the codec for which this structure is valid.
     */
    AVFilmGrainParamsType type;

    /**
     * Seed to use for the synthesis process, if the codec allows for it.
     */
    ulong seed;

    /**
     * Additional fields may be added both here and in any structure included.
     * If a codec's film grain structure differs slightly over another
     * codec's, fields within may change meaning depending on the type.
     */
    union _Anonymous_0
    {
        AVFilmGrainAOMParams aom;
    }

    _Anonymous_0 codec;
}

/**
 * Allocate an AVFilmGrainParams structure and set its fields to
 * default values. The resulting struct can be freed using av_freep().
 * If size is not NULL it will be set to the number of bytes allocated.
 *
 * @return An AVFilmGrainParams filled with default values or NULL
 *         on failure.
 */
AVFilmGrainParams* av_film_grain_params_alloc (size_t* size);

/**
 * Allocate a complete AVFilmGrainParams and add it to the frame.
 *
 * @param frame The frame which side data is added to.
 *
 * @return The AVFilmGrainParams structure to be filled by caller.
 */
AVFilmGrainParams* av_film_grain_params_create_side_data (AVFrame* frame);

/* AVUTIL_FILM_GRAIN_PARAMS_H */
