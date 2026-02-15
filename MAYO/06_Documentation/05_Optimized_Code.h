
// File: simple_arithmetic.h
// Location: src/simple_arithmetic.h
// Purpose: Optimize GF(16) arithmetic using Lookup Tables (LUT)
// ================================================

// SPDX-License-Identifier: Apache-2.0

#ifndef SIMPLE_ARITHMETIC_H
#define SIMPLE_ARITHMETIC_H

#include <mem.h>

// ================================================
// Lookup Tables (LUT)
// ================================================

// GF(16) Multiplication Table
// Size: 16 x 16 = 256 bytes
static const uint8_t gf16_mul_lut[16][16] = {
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
    {0, 2, 4, 6, 8, 10, 12, 14, 3, 1, 7, 5, 11, 9, 15, 13},
    {0, 3, 6, 5, 12, 15, 10, 9, 11, 8, 13, 14, 7, 4, 1, 2},
    {0, 4, 8, 12, 3, 7, 11, 15, 6, 2, 14, 10, 5, 1, 13, 9},
    {0, 5, 10, 15, 7, 2, 13, 8, 14, 11, 4, 1, 9, 12, 3, 6},
    {0, 6, 12, 10, 11, 13, 7, 1, 5, 3, 9, 15, 14, 8, 2, 4},
    {0, 7, 14, 9, 15, 8, 1, 6, 13, 10, 3, 4, 2, 5, 12, 11},
    {0, 8, 3, 11, 6, 14, 5, 13, 12, 4, 15, 7, 10, 2, 9, 1},
    {0, 9, 1, 8, 2, 11, 3, 10, 4, 13, 5, 12, 6, 15, 7, 14},
    {0, 10, 7, 13, 14, 4, 9, 3, 15, 5, 8, 2, 1, 11, 6, 12},
    {0, 11, 5, 14, 10, 1, 15, 4, 7, 12, 2, 9, 13, 6, 8, 3},
    {0, 12, 11, 7, 5, 9, 14, 2, 10, 6, 1, 13, 15, 3, 4, 8},
    {0, 13, 9, 4, 1, 12, 8, 5, 2, 15, 11, 6, 3, 14, 10, 7},
    {0, 14, 15, 1, 13, 3, 2, 12, 9, 7, 6, 8, 4, 10, 11, 5},
    {0, 15, 13, 2, 9, 6, 4, 11, 1, 14, 12, 3, 8, 7, 5, 10}
};

// GF(16) Multiplicative Inverse Table
// Size: 16 bytes
static const uint8_t gf16_inv_lut[16] = {
    0, 1, 9, 14, 13, 11, 7, 6, 15, 2, 12, 5, 10, 4, 3, 8
};

// ================================================
// Optimized GF(16) Functions
// ================================================

// GF(16) multiplication using LUT
static inline unsigned char mul_f(unsigned char a, unsigned char b) {
    return gf16_mul_lut[a & 0xf][b & 0xf];
}

// GF(16) multiplicative inverse using LUT
static inline unsigned char inverse_f(unsigned char a) {
    return gf16_inv_lut[a & 0xf];
}

// ================================================
// Other Arithmetic Functions (Unmodified)
// ================================================

static inline uint64_t mul_fx8(unsigned char a, uint64_t b) {
    uint64_t p;
    p  = (a & 1)*b;
    p ^= (a & 2)*b;
    p ^= (a & 4)*b;
    p ^= (a & 8)*b;
    uint64_t top_p = p & 0xf0f0f0f0f0f0f0f0ULL;
    uint64_t out = (p ^ (top_p >> 4) ^ (top_p >> 3)) & 0x0f0f0f0f0f0f0f0fULL;
    return out;
}

static inline unsigned char add_f(unsigned char a, unsigned char b) {
    return a ^ b;
}

static inline unsigned char sub_f(unsigned char a, unsigned char b) {
    return a ^ b;
}

static inline unsigned char neg_f(unsigned char a) {
    return a;
}

static inline unsigned char lincomb(const unsigned char *a,
                                    const unsigned char *b,
                                    int n, int m) {
    unsigned char ret = 0;
    for (int i = 0; i < n; ++i, b += m) {
        ret = add_f(mul_f(a[i], *b), ret);
    }
    return ret;
}

static inline void mat_mul(const unsigned char *a,
                           const unsigned char *b,
                           unsigned char *c,
                           int colrow_ab,
                           int row_a,
                           int col_b) {
    for (int i = 0; i < row_a; ++i, a += colrow_ab) {
        for (int j = 0; j < col_b; ++j, ++c) {
            *c = lincomb(a, b + j, colrow_ab, col_b);
        }
    }
}

static inline void mat_add(const unsigned char *a,
                           const unsigned char *b,
                           unsigned char *c,
                           int m, int n) {
    for (int i = 0; i < m; ++i) {
        for (int j = 0; j < n; ++j) {
            *(c + i * n + j) =
                add_f(*(a + i * n + j), *(b + i * n + j));
        }
    }
}

// Vectorized GF(16) multiplication (unchanged)
static inline uint64_t gf16v_mul_u64(uint64_t a, uint8_t b) {

    uint64_t mask_msb = 0x8888888888888888ULL;
    uint64_t a_msb;
    uint64_t a64 = a;

#if !(((defined(__clang__) && __clang_major__ < 15) || \
(!defined(__clang__) && defined(__GNUC__) && __GNUC__ <= 12)) && \
(defined(__x86_64__) || defined(_M_X64)))
    uint64_t b32 = b ^ unsigned_char_blocker;
#else
    uint64_t b32 = b;
#endif

    uint64_t r64 = a64 * (b32 & 1);

    for (int i = 1; i < 4; i++) {
        a_msb = a64 & mask_msb;
        a64 ^= a_msb;
        a64 = (a64 << 1) ^ ((a_msb >> 3) * 3);
        r64 ^= a64 * ((b32 >> i) & 1);
    }

    return r64;
}

static inline uint32_t mul_table(uint8_t b){
    uint32_t x = ((uint32_t) b) * 0x08040201;
    uint32_t high_nibble_mask = 0xf0f0f0f0;
    uint32_t high_half = x & high_nibble_mask;
    return (x ^ (high_half >> 4) ^ (high_half >> 3));
}

#endif
```

---

