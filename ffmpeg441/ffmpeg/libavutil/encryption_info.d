/**
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
module ffmpeg.libavutil.encryption_info;
extern (C):

struct AVSubsampleEncryptionInfo
{
    /** The number of bytes that are clear. */
    uint bytes_of_clear_data;

    /**
     * The number of bytes that are protected.  If using pattern encryption,
     * the pattern applies to only the protected bytes; if not using pattern
     * encryption, all these bytes are encrypted.
     */
    uint bytes_of_protected_data;
}

/**
 * This describes encryption info for a packet.  This contains frame-specific
 * info for how to decrypt the packet before passing it to the decoder.
 *
 * The size of this struct is not part of the public ABI.
 */
struct AVEncryptionInfo
{
    /** The fourcc encryption scheme, in big-endian byte order. */
    uint scheme;

    /**
     * Only used for pattern encryption.  This is the number of 16-byte blocks
     * that are encrypted.
     */
    uint crypt_byte_block;

    /**
     * Only used for pattern encryption.  This is the number of 16-byte blocks
     * that are clear.
     */
    uint skip_byte_block;

    /**
     * The ID of the key used to encrypt the packet.  This should always be
     * 16 bytes long, but may be changed in the future.
     */
    ubyte* key_id;
    uint key_id_size;

    /**
     * The initialization vector.  This may have been zero-filled to be the
     * correct block size.  This should always be 16 bytes long, but may be
     * changed in the future.
     */
    ubyte* iv;
    uint iv_size;

    /**
     * An array of subsample encryption info specifying how parts of the sample
     * are encrypted.  If there are no subsamples, then the whole sample is
     * encrypted.
     */
    AVSubsampleEncryptionInfo* subsamples;
    uint subsample_count;
}

/**
 * This describes info used to initialize an encryption key system.
 *
 * The size of this struct is not part of the public ABI.
 */
struct AVEncryptionInitInfo
{
    /**
     * A unique identifier for the key system this is for, can be NULL if it
     * is not known.  This should always be 16 bytes, but may change in the
     * future.
     */
    ubyte* system_id;
    uint system_id_size;

    /**
     * An array of key IDs this initialization data is for.  All IDs are the
     * same length.  Can be NULL if there are no known key IDs.
     */
    ubyte** key_ids;
    /** The number of key IDs. */
    uint num_key_ids;
    /**
     * The number of bytes in each key ID.  This should always be 16, but may
     * change in the future.
     */
    uint key_id_size;

    /**
     * Key-system specific initialization data.  This data is copied directly
     * from the file and the format depends on the specific key system.  This
     * can be NULL if there is no initialization data; in that case, there
     * will be at least one key ID.
     */
    ubyte* data;
    uint data_size;

    /**
     * An optional pointer to the next initialization info in the list.
     */
    AVEncryptionInitInfo* next;
}

/**
 * Allocates an AVEncryptionInfo structure and sub-pointers to hold the given
 * number of subsamples.  This will allocate pointers for the key ID, IV,
 * and subsample entries, set the size members, and zero-initialize the rest.
 *
 * @param subsample_count The number of subsamples.
 * @param key_id_size The number of bytes in the key ID, should be 16.
 * @param iv_size The number of bytes in the IV, should be 16.
 *
 * @return The new AVEncryptionInfo structure, or NULL on error.
 */
AVEncryptionInfo* av_encryption_info_alloc (uint subsample_count, uint key_id_size, uint iv_size);

/**
 * Allocates an AVEncryptionInfo structure with a copy of the given data.
 * @return The new AVEncryptionInfo structure, or NULL on error.
 */
AVEncryptionInfo* av_encryption_info_clone (const(AVEncryptionInfo)* info);

/**
 * Frees the given encryption info object.  This MUST NOT be used to free the
 * side-data data pointer, that should use normal side-data methods.
 */
void av_encryption_info_free (AVEncryptionInfo* info);

/**
 * Creates a copy of the AVEncryptionInfo that is contained in the given side
 * data.  The resulting object should be passed to av_encryption_info_free()
 * when done.
 *
 * @return The new AVEncryptionInfo structure, or NULL on error.
 */
AVEncryptionInfo* av_encryption_info_get_side_data (const(ubyte)* side_data, size_t side_data_size);

/**
 * Allocates and initializes side data that holds a copy of the given encryption
 * info.  The resulting pointer should be either freed using av_free or given
 * to av_packet_add_side_data().
 *
 * @return The new side-data pointer, or NULL.
 */
ubyte* av_encryption_info_add_side_data (
    const(AVEncryptionInfo)* info,
    size_t* side_data_size);

/**
 * Allocates an AVEncryptionInitInfo structure and sub-pointers to hold the
 * given sizes.  This will allocate pointers and set all the fields.
 *
 * @return The new AVEncryptionInitInfo structure, or NULL on error.
 */
AVEncryptionInitInfo* av_encryption_init_info_alloc (
    uint system_id_size,
    uint num_key_ids,
    uint key_id_size,
    uint data_size);

/**
 * Frees the given encryption init info object.  This MUST NOT be used to free
 * the side-data data pointer, that should use normal side-data methods.
 */
void av_encryption_init_info_free (AVEncryptionInitInfo* info);

/**
 * Creates a copy of the AVEncryptionInitInfo that is contained in the given
 * side data.  The resulting object should be passed to
 * av_encryption_init_info_free() when done.
 *
 * @return The new AVEncryptionInitInfo structure, or NULL on error.
 */
AVEncryptionInitInfo* av_encryption_init_info_get_side_data (
    const(ubyte)* side_data,
    size_t side_data_size);

/**
 * Allocates and initializes side data that holds a copy of the given encryption
 * init info.  The resulting pointer should be either freed using av_free or
 * given to av_packet_add_side_data().
 *
 * @return The new side-data pointer, or NULL.
 */
ubyte* av_encryption_init_info_add_side_data (
    const(AVEncryptionInitInfo)* info,
    size_t* side_data_size);

/* AVUTIL_ENCRYPTION_INFO_H */
