// ================================================
// الملف الأصلي: simple_arithmetic.h
// قبل التحسين
// ================================================

// SPDX-License-Identifier: Apache-2.0

#ifndef SIMPLE_ARITHMETIC_H
#define SIMPLE_ARITHMETIC_H
#include <mem.h>

// الدوال الأصلية - قبل التحسين

static inline unsigned char mul_f(unsigned char a, unsigned char b) {
    unsigned char p;

#if !(((defined(__clang__) && __clang_major__ < 15) || (!defined(__clang__) && defined(__GNUC__) && __GNUC__ <= 12)) && (defined(__x86_64__) || defined(_M_X64)))
    a ^= unsigned_char_blocker;
#endif

    p  = (a & 1)*b;
    p ^= (a & 2)*b;
    p ^= (a & 4)*b;
    p ^= (a & 8)*b;

    unsigned char top_p = p & 0xf0;
    unsigned char out = (p ^ (top_p >> 4) ^ (top_p >> 3)) & 0x0f;
    return out;
}

static inline unsigned char inverse_f(unsigned char a) {
    unsigned char a2 = mul_f(a, a);
    unsigned char a4 = mul_f(a2, a2);
    unsigned char a8 = mul_f(a4, a4);
    unsigned char a6 = mul_f(a2, a4);
    unsigned char a14 = mul_f(a8, a6);
    return a14;
}

// باقي الدوال نفس الكود المحسّن (لم تتغير)

#endif
