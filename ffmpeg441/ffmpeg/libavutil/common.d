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

/**
 * @file
 * common internal and external API header
 */
module ffmpeg.libavutil.common;
extern (C):

extern (D) auto AV_NE(T0, T1)(auto ref T0 be, auto ref T1 le)
{
    return le;
}

//rounded division & shift
extern (D) auto RSHIFT(T0, T1)(auto ref T0 a, auto ref T1 b)
{
    return a > 0 ? (a + ((1 << b) >> 1)) >> b : (a + ((1 << b) >> 1) - 1) >> b;
}

/* assume b>0 */
extern (D) auto ROUNDED_DIV(T0, T1)(auto ref T0 a, auto ref T1 b)
{
    return (a >= 0 ? a + (b >> 1) : a - (b >> 1)) / b;
}

/* Fast a/(1<<b) rounded toward +inf. Assume a>=0 and b>=0 */
extern (D) auto AV_CEIL_RSHIFT(T0, T1)(auto ref T0 a, auto ref T1 b)
{
    return /*!av_builtin_constant_p() ?*/ -((-a) >> b) /*: (a + (1 << b) - 1) >> b*/;
}

/* Backwards compat. */
alias FF_CEIL_RSHIFT = AV_CEIL_RSHIFT;

extern (D) auto FFUDIV(T0, T1)(auto ref T0 a, auto ref T1 b)
{
    return (a > 0 ? a : a - b + 1) / b;
}

extern (D) auto FFUMOD(T0, T1)(auto ref T0 a, auto ref T1 b)
{
    return a - b * FFUDIV(a, b);
}

/**
 * Absolute value, Note, INT_MIN / INT64_MIN result in undefined behavior as they
 * are not representable as absolute values of their type. This is the same
 * as with *abs()
 * @see FFNABS()
 */
extern (D) auto FFABS(T)(auto ref T a)
{
    return a >= 0 ? a : (-a);
}

extern (D) int FFSIGN(T)(auto ref T a)
{
    return a > 0 ? 1 : -1;
}

/**
 * Negative Absolute value.
 * this works for all integers of all types.
 * As with many macros, this evaluates its argument twice, it thus must not have
 * a sideeffect, that is FFNABS(x++) has undefined behavior.
 */
extern (D) auto FFNABS(T)(auto ref T a)
{
    return a <= 0 ? a : (-a);
}

/**
 * Unsigned Absolute value.
 * This takes the absolute value of a signed int and returns it as a unsigned.
 * This also works with INT_MIN which would otherwise not be representable
 * As with many macros, this evaluates its argument twice.
 */
extern (D) auto FFABSU(T)(auto ref T a)
{
    return a <= 0 ? -cast(uint) a : cast(uint) a;
}

extern (D) auto FFABS64U(T)(auto ref T a)
{
    return a <= 0 ? -cast(ulong) a : cast(ulong) a;
}

/**
 * Comparator.
 * For two numerical expressions x and y, gives 1 if x > y, -1 if x < y, and 0
 * if x == y. This is useful for instance in a qsort comparator callback.
 * Furthermore, compilers are able to optimize this to branchless code, and
 * there is no risk of overflow with signed types.
 * As with many macros, this evaluates its argument multiple times, it thus
 * must not have a side-effect.
 */
extern (D) auto FFDIFFSIGN(T0, T1)(auto ref T0 x, auto ref T1 y)
{
    return (x > y) - (x < y);
}

extern (D) auto FFMAX(T0, T1)(auto ref T0 a, auto ref T1 b)
{
    return a > b ? a : b;
}

extern (D) auto FFMAX3(T0, T1, T2)(auto ref T0 a, auto ref T1 b, auto ref T2 c)
{
    return FFMAX(FFMAX(a, b), c);
}

extern (D) auto FFMIN(T0, T1)(auto ref T0 a, auto ref T1 b)
{
    return a > b ? b : a;
}

extern (D) auto FFMIN3(T0, T1, T2)(auto ref T0 a, auto ref T1 b, auto ref T2 c)
{
    return FFMIN(FFMIN(a, b), c);
}

extern (D) size_t FF_ARRAY_ELEMS(T)(auto ref T a)
{
    return a.sizeof / (a[0]).sizeof;
}

/* misc math functions */

alias av_ceil_log2 = av_ceil_log2_c;

alias av_clip = av_clip_c;

alias av_clip64 = av_clip64_c;

alias av_clip_uint8 = av_clip_uint8_c;

alias av_clip_int8 = av_clip_int8_c;

alias av_clip_uint16 = av_clip_uint16_c;

alias av_clip_int16 = av_clip_int16_c;

alias av_clipl_int32 = av_clipl_int32_c;

alias av_clip_intp2 = av_clip_intp2_c;

alias av_clip_uintp2 = av_clip_uintp2_c;

alias av_mod_uintp2 = av_mod_uintp2_c;

alias av_sat_add32 = av_sat_add32_c;

alias av_sat_dadd32 = av_sat_dadd32_c;

alias av_sat_sub32 = av_sat_sub32_c;

alias av_sat_dsub32 = av_sat_dsub32_c;

alias av_sat_add64 = av_sat_add64_c;

alias av_sat_sub64 = av_sat_sub64_c;

alias av_clipf = av_clipf_c;

alias av_clipd = av_clipd_c;

alias av_popcount = av_popcount_c;

alias av_popcount64 = av_popcount64_c;

alias av_parity = av_parity_c;

int av_log2 (uint v);

int av_log2_16bit (uint v);

/**
 * Clip a signed integer value into the amin-amax range.
 * @param a value to clip
 * @param amin minimum value of the clip range
 * @param amax maximum value of the clip range
 * @return clipped value
 */
int av_clip_c (int a, int amin, int amax);

/**
 * Clip a signed 64bit integer value into the amin-amax range.
 * @param a value to clip
 * @param amin minimum value of the clip range
 * @param amax maximum value of the clip range
 * @return clipped value
 */
long av_clip64_c (long a, long amin, long amax);

/**
 * Clip a signed integer value into the 0-255 range.
 * @param a value to clip
 * @return clipped value
 */
ubyte av_clip_uint8_c (int a);

/**
 * Clip a signed integer value into the -128,127 range.
 * @param a value to clip
 * @return clipped value
 */
byte av_clip_int8_c (int a);

/**
 * Clip a signed integer value into the 0-65535 range.
 * @param a value to clip
 * @return clipped value
 */
ushort av_clip_uint16_c (int a);

/**
 * Clip a signed integer value into the -32768,32767 range.
 * @param a value to clip
 * @return clipped value
 */
short av_clip_int16_c (int a);

/**
 * Clip a signed 64-bit integer value into the -2147483648,2147483647 range.
 * @param a value to clip
 * @return clipped value
 */
int av_clipl_int32_c (long a);

/**
 * Clip a signed integer into the -(2^p),(2^p-1) range.
 * @param  a value to clip
 * @param  p bit position to clip at
 * @return clipped value
 */
int av_clip_intp2_c (int a, int p);

/**
 * Clip a signed integer to an unsigned power of two range.
 * @param  a value to clip
 * @param  p bit position to clip at
 * @return clipped value
 */
uint av_clip_uintp2_c (int a, int p);

/**
 * Clear high bits from an unsigned integer starting with specific bit position
 * @param  a value to clip
 * @param  p bit position to clip at
 * @return clipped value
 */
uint av_mod_uintp2_c (uint a, uint p);

/**
 * Add two signed 32-bit values with saturation.
 *
 * @param  a one value
 * @param  b another value
 * @return sum with signed saturation
 */
int av_sat_add32_c (int a, int b);

/**
 * Add a doubled value to another value with saturation at both stages.
 *
 * @param  a first value
 * @param  b value doubled and added to a
 * @return sum sat(a + sat(2*b)) with signed saturation
 */
int av_sat_dadd32_c (int a, int b);

/**
 * Subtract two signed 32-bit values with saturation.
 *
 * @param  a one value
 * @param  b another value
 * @return difference with signed saturation
 */
int av_sat_sub32_c (int a, int b);

/**
 * Subtract a doubled value from another value with saturation at both stages.
 *
 * @param  a first value
 * @param  b value doubled and subtracted from a
 * @return difference sat(a - sat(2*b)) with signed saturation
 */
int av_sat_dsub32_c (int a, int b);

/**
 * Add two signed 64-bit values with saturation.
 *
 * @param  a one value
 * @param  b another value
 * @return sum with signed saturation
 */
long av_sat_add64_c (long a, long b);

/**
 * Subtract two signed 64-bit values with saturation.
 *
 * @param  a one value
 * @param  b another value
 * @return difference with signed saturation
 */
long av_sat_sub64_c (long a, long b);

/**
 * Clip a float value into the amin-amax range.
 * @param a value to clip
 * @param amin minimum value of the clip range
 * @param amax maximum value of the clip range
 * @return clipped value
 */
float av_clipf_c (float a, float amin, float amax);

/**
 * Clip a double value into the amin-amax range.
 * @param a value to clip
 * @param amin minimum value of the clip range
 * @param amax maximum value of the clip range
 * @return clipped value
 */
double av_clipd_c (double a, double amin, double amax);

/** Compute ceil(log2(x)).
 * @param x value used to compute ceil(log2(x))
 * @return computed ceiling of log2(x)
 */
int av_ceil_log2_c (int x);

/**
 * Count number of bits set to one in x
 * @param x value to count bits of
 * @return the number of bits set to one in x
 */
int av_popcount_c (uint x);

/**
 * Count number of bits set to one in x
 * @param x value to count bits of
 * @return the number of bits set to one in x
 */
int av_popcount64_c (ulong x);

int av_parity_c (uint v);

extern (D) auto MKTAG(T0, T1, T2, T3)(auto ref T0 a, auto ref T1 b, auto ref T2 c, auto ref T3 d)
{
    return a | (b << 8) | (c << 16) | (cast(uint) d << 24);
}

extern (D) auto MKBETAG(T0, T1, T2, T3)(auto ref T0 a, auto ref T1 b, auto ref T2 c, auto ref T3 d)
{
    return d | (c << 8) | (b << 16) | (cast(uint) a << 24);
}

/**
 * Convert a UTF-8 character (up to 4 bytes) to its 32-bit UCS-4 encoded form.
 *
 * @param val      Output value, must be an lvalue of type uint32_t.
 * @param GET_BYTE Expression reading one byte from the input.
 *                 Evaluated up to 7 times (4 for the currently
 *                 assigned Unicode range).  With a memory buffer
 *                 input, this could be *ptr++, or if you want to make sure
 *                 that *ptr stops at the end of a NULL terminated string then
 *                 *ptr ? *ptr++ : 0
 * @param ERROR    Expression to be evaluated on invalid input,
 *                 typically a goto statement.
 *
 * @warning ERROR should not contain a loop control statement which
 * could interact with the internal while loop, and should force an
 * exit from the macro code (e.g. through a goto or a return) in order
 * to prevent undefined results.
 */

/**
 * Convert a UTF-16 character (2 or 4 bytes) to its 32-bit UCS-4 encoded form.
 *
 * @param val       Output value, must be an lvalue of type uint32_t.
 * @param GET_16BIT Expression returning two bytes of UTF-16 data converted
 *                  to native byte order.  Evaluated one or two times.
 * @param ERROR     Expression to be evaluated on invalid input,
 *                  typically a goto statement.
 */

/**
 * @def PUT_UTF8(val, tmp, PUT_BYTE)
 * Convert a 32-bit Unicode character to its UTF-8 encoded form (up to 4 bytes long).
 * @param val is an input-only argument and should be of type uint32_t. It holds
 * a UCS-4 encoded Unicode character that is to be converted to UTF-8. If
 * val is given as a function it is executed only once.
 * @param tmp is a temporary variable and should be of type uint8_t. It
 * represents an intermediate value during conversion that is to be
 * output by PUT_BYTE.
 * @param PUT_BYTE writes the converted UTF-8 bytes to any proper destination.
 * It could be a function or a statement, and uses tmp as the input byte.
 * For example, PUT_BYTE could be "*output++ = tmp;" PUT_BYTE will be
 * executed up to 4 times for values in the valid UTF-8 range and up to
 * 7 times in the general case, depending on the length of the converted
 * Unicode character.
 */

/**
 * @def PUT_UTF16(val, tmp, PUT_16BIT)
 * Convert a 32-bit Unicode character to its UTF-16 encoded form (2 or 4 bytes).
 * @param val is an input-only argument and should be of type uint32_t. It holds
 * a UCS-4 encoded Unicode character that is to be converted to UTF-16. If
 * val is given as a function it is executed only once.
 * @param tmp is a temporary variable and should be of type uint16_t. It
 * represents an intermediate value during conversion that is to be
 * output by PUT_16BIT.
 * @param PUT_16BIT writes the converted UTF-16 data to any proper destination
 * in desired endianness. It could be a function or a statement, and uses tmp
 * as the input byte.  For example, PUT_BYTE could be "*output++ = tmp;"
 * PUT_BYTE will be executed 1 or 2 times depending on input character.
 */

/* HAVE_AV_CONFIG_H */

/* AVUTIL_COMMON_H */
