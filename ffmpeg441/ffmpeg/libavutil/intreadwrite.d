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
module ffmpeg.libavutil.intreadwrite;
extern (C):

union av_alias64
{
    ulong u64;
    uint[2] u32;
    ushort[4] u16;
    ubyte[8] u8;
    double f64;
    float[2] f32;
}

union av_alias32
{
    uint u32;
    ushort[2] u16;
    ubyte[4] u8;
    float f32;
}

union av_alias16
{
    ushort u16;
    ubyte[2] u8;
}

/*
 * Arch-specific headers can provide any combination of
 * AV_[RW][BLN](16|24|32|48|64) and AV_(COPY|SWAP|ZERO)(64|128) macros.
 * Preprocessor symbols must be defined, even if these are implemented
 * as inline functions.
 *
 * R/W means read/write, B/L/N means big/little/native endianness.
 * The following macros require aligned access, compared to their
 * unaligned variants: AV_(COPY|SWAP|ZERO)(64|128), AV_[RW]N[8-64]A.
 * Incorrect usage may range from abysmal performance to crash
 * depending on the platform.
 *
 * The unaligned variants are AV_[RW][BLN][8-64] and AV_COPY*U.
 */

/* HAVE_AV_CONFIG_H */

/*
 * Map AV_RNXX <-> AV_R[BL]XX for all variants provided by per-arch headers.
 */

/* AV_HAVE_BIGENDIAN */

/* !AV_HAVE_BIGENDIAN */

/*
 * Define AV_[RW]N helper macros to simplify definitions not provided
 * by per-arch headers.
 */

/* HAVE_FAST_UNALIGNED */

extern (D) auto AV_RN16(T)(auto ref T p)
{
    return AV_RN(16, p);
}

extern (D) auto AV_RN32(T)(auto ref T p)
{
    return AV_RN(32, p);
}

extern (D) auto AV_RN64(T)(auto ref T p)
{
    return AV_RN(64, p);
}

extern (D) auto AV_WN16(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WN(16, p, v);
}

extern (D) auto AV_WN32(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WN(32, p, v);
}

extern (D) auto AV_WN64(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WN(64, p, v);
}

extern (D) auto AV_RB8(T)(auto ref T x)
{
    return (cast(const(ubyte)*) x)[0];
}

alias AV_RL8 = AV_RB8;
//alias AV_WL8 = AV_WB8;

extern (D) auto AV_RB16(T)(auto ref T p)
{
    return AV_RB(16, p);
}

extern (D) auto AV_WB16(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WB(16, p, v);
}

extern (D) auto AV_RL16(T)(auto ref T p)
{
    return AV_RL(16, p);
}

extern (D) auto AV_WL16(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WL(16, p, v);
}

extern (D) auto AV_RB32(T)(auto ref T p)
{
    return AV_RB(32, p);
}

extern (D) auto AV_WB32(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WB(32, p, v);
}

extern (D) auto AV_RL32(T)(auto ref T p)
{
    return AV_RL(32, p);
}

extern (D) auto AV_WL32(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WL(32, p, v);
}

extern (D) auto AV_RB64(T)(auto ref T p)
{
    return AV_RB(64, p);
}

extern (D) auto AV_WB64(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WB(64, p, v);
}

extern (D) auto AV_RL64(T)(auto ref T p)
{
    return AV_RL(64, p);
}

extern (D) auto AV_WL64(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WL(64, p, v);
}

extern (D) auto AV_RB24(T)(auto ref T x)
{
    return ((cast(const(ubyte)*) x)[0] << 16) | ((cast(const(ubyte)*) x)[1] << 8) | (cast(const(ubyte)*) x)[2];
}

extern (D) auto AV_RL24(T)(auto ref T x)
{
    return ((cast(const(ubyte)*) x)[2] << 16) | ((cast(const(ubyte)*) x)[1] << 8) | (cast(const(ubyte)*) x)[0];
}

extern (D) auto AV_RB48(T)(auto ref T x)
{
    return (cast(ulong) (cast(const(ubyte)*) x)[0] << 40) | (cast(ulong) (cast(const(ubyte)*) x)[1] << 32) | (cast(ulong) (cast(const(ubyte)*) x)[2] << 24) | (cast(ulong) (cast(const(ubyte)*) x)[3] << 16) | (cast(ulong) (cast(const(ubyte)*) x)[4] << 8) | cast(ulong) (cast(const(ubyte)*) x)[5];
}

extern (D) auto AV_RL48(T)(auto ref T x)
{
    return (cast(ulong) (cast(const(ubyte)*) x)[5] << 40) | (cast(ulong) (cast(const(ubyte)*) x)[4] << 32) | (cast(ulong) (cast(const(ubyte)*) x)[3] << 24) | (cast(ulong) (cast(const(ubyte)*) x)[2] << 16) | (cast(ulong) (cast(const(ubyte)*) x)[1] << 8) | cast(ulong) (cast(const(ubyte)*) x)[0];
}

/*
 * The AV_[RW]NA macros access naturally aligned data
 * in a type-safe way.
 */

extern (D) auto AV_RN16A(T)(auto ref T p)
{
    return AV_RNA(16, p);
}

extern (D) auto AV_RN32A(T)(auto ref T p)
{
    return AV_RNA(32, p);
}

extern (D) auto AV_RN64A(T)(auto ref T p)
{
    return AV_RNA(64, p);
}

extern (D) auto AV_WN16A(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WNA(16, p, v);
}

extern (D) auto AV_WN32A(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WNA(32, p, v);
}

extern (D) auto AV_WN64A(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WNA(64, p, v);
}

extern (D) auto AV_RL64A(T)(auto ref T p)
{
    return AV_RLA(64, p);
}

extern (D) auto AV_WL64A(T0, T1)(auto ref T0 p, auto ref T1 v)
{
    return AV_WLA(64, p, v);
}

/*
 * The AV_COPYxxU macros are suitable for copying data to/from unaligned
 * memory locations.
 */

extern (D) auto AV_COPY16U(T0, T1)(auto ref T0 d, auto ref T1 s)
{
    return AV_COPYU(16, d, s);
}

extern (D) auto AV_COPY32U(T0, T1)(auto ref T0 d, auto ref T1 s)
{
    return AV_COPYU(32, d, s);
}

extern (D) auto AV_COPY64U(T0, T1)(auto ref T0 d, auto ref T1 s)
{
    return AV_COPYU(64, d, s);
}

/* Parameters for AV_COPY*, AV_SWAP*, AV_ZERO* must be
 * naturally aligned. They may be implemented using MMX,
 * so emms_c() must be called before using any float code
 * afterwards.
 */

extern (D) auto AV_COPY16(T0, T1)(auto ref T0 d, auto ref T1 s)
{
    return AV_COPY(16, d, s);
}

extern (D) auto AV_COPY32(T0, T1)(auto ref T0 d, auto ref T1 s)
{
    return AV_COPY(32, d, s);
}

extern (D) auto AV_COPY64(T0, T1)(auto ref T0 d, auto ref T1 s)
{
    return AV_COPY(64, d, s);
}

extern (D) auto AV_SWAP64(T0, T1)(auto ref T0 a, auto ref T1 b)
{
    return AV_SWAP(64, a, b);
}

extern (D) auto AV_ZERO16(T)(auto ref T d)
{
    return AV_ZERO(16, d);
}

extern (D) auto AV_ZERO32(T)(auto ref T d)
{
    return AV_ZERO(32, d);
}

extern (D) auto AV_ZERO64(T)(auto ref T d)
{
    return AV_ZERO(64, d);
}

/* AVUTIL_INTREADWRITE_H */
