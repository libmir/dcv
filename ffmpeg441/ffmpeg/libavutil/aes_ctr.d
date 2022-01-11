/*
 * AES-CTR cipher
 * Copyright (c) 2015 Eran Kornblau <erankor at gmail dot com>
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
module ffmpeg.libavutil.aes_ctr;

extern (C):

enum AES_CTR_KEY_SIZE = 16;
enum AES_CTR_IV_SIZE = 8;

struct AVAESCTR;

/**
 * Allocate an AVAESCTR context.
 */
AVAESCTR* av_aes_ctr_alloc ();

/**
 * Initialize an AVAESCTR context.
 * @param key encryption key, must have a length of AES_CTR_KEY_SIZE
 */
int av_aes_ctr_init (AVAESCTR* a, const(ubyte)* key);

/**
 * Release an AVAESCTR context.
 */
void av_aes_ctr_free (AVAESCTR* a);

/**
 * Process a buffer using a previously initialized context.
 * @param dst destination array, can be equal to src
 * @param src source array, can be equal to dst
 * @param size the size of src and dst
 */
void av_aes_ctr_crypt (AVAESCTR* a, ubyte* dst, const(ubyte)* src, int size);

/**
 * Get the current iv
 */
const(ubyte)* av_aes_ctr_get_iv (AVAESCTR* a);

/**
 * Generate a random iv
 */
void av_aes_ctr_set_random_iv (AVAESCTR* a);

/**
 * Forcefully change the 8-byte iv
 */
void av_aes_ctr_set_iv (AVAESCTR* a, const(ubyte)* iv);

/**
 * Forcefully change the "full" 16-byte iv, including the counter
 */
void av_aes_ctr_set_full_iv (AVAESCTR* a, const(ubyte)* iv);

/**
 * Increment the top 64 bit of the iv (performed after each frame)
 */
void av_aes_ctr_increment_iv (AVAESCTR* a);

/**
 * @}
 */

/* AVUTIL_AES_CTR_H */
