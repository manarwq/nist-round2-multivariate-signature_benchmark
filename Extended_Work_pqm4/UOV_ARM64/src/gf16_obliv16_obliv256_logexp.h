// SPDX-License-Identifier: CC0 OR Apache-2.0
/// @file gf16.h
/// @brief Library for arithmetics in GF(16) and GF(256)
///

#ifndef _GF16_H_
#define _GF16_H_

#include <stdint.h>




///////////////////////////////////////////
//
//  Arithmetics for one field element
//
//////////////////////////////////////////




static inline uint8_t gf16_is_nonzero(uint8_t a) {
    unsigned a4 = a & 0xf;
    unsigned r = ((unsigned) 0) - a4;
    r >>= 4;
    return r & 1;
}




// gf16 := gf2[x]/(x^4+x+1)
static const uint8_t gf16_mul_lut[16][16] = {
    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},
    {0,2,4,6,8,10,12,14,3,1,7,5,11,9,15,13},
    {0,3,6,5,12,15,10,9,11,8,13,14,7,4,1,2},
    {0,4,8,12,3,7,11,15,6,2,14,10,5,1,13,9},
    {0,5,10,15,7,2,13,8,14,11,4,1,9,12,3,6},
    {0,6,12,10,11,13,7,1,5,3,9,15,14,8,2,4},
    {0,7,14,9,15,8,1,6,13,10,3,4,2,5,12,11},
    {0,8,3,11,6,14,5,13,12,4,15,7,10,2,9,1},
    {0,9,1,8,2,11,3,10,4,13,5,12,6,15,7,14},
    {0,10,7,13,14,4,9,3,15,5,8,2,1,11,6,12},
    {0,11,5,14,10,1,15,4,7,12,2,9,13,6,8,3},
    {0,12,11,7,5,9,14,2,10,6,1,13,15,3,4,8},
    {0,13,9,4,1,12,8,5,2,15,11,6,3,14,10,7},
    {0,14,15,1,13,3,2,12,9,7,6,8,4,10,11,5},
    {0,15,13,2,9,6,4,11,1,14,12,3,8,7,5,10}
};

// Oblivious LUT - cache-timing attack resistant
// Constant-time equality mask: 0xFF if a==b, 0x00 otherwise (correct for full 0-255 range)
static inline uint8_t gf16_ct_eq_mask(uint8_t a, uint8_t b) {
    uint8_t diff = a ^ b;
    unsigned r = ((unsigned) 0) - (unsigned)diff;
    r >>= 8;
    unsigned is_nz = r & 1;
    return (uint8_t)(is_nz - 1);
}
static inline uint8_t gf16_mul(uint8_t a, uint8_t b) {
    unsigned char result = 0;
    unsigned char a4 = a & 0x0f;
    unsigned char b4 = b & 0x0f;
    for (int i = 0; i < 16; i++) {
        unsigned char mask = gf16_ct_eq_mask(a4, (unsigned char)i);
        result |= mask & gf16_mul_lut[i][b4];
    }
    return result;
}

static inline uint8_t gf16_squ(uint8_t a) {
    uint8_t r4 = a & 1;  // constant term
    r4 ^= (a << 1) & 4;  // x -> x^2
    r4 ^= ((a >> 2) & 1) * 3; // x^2 -> x^4 -> x+1
    r4 ^= ((a >> 3) & 1) * 12; // x^3 -> x^6 -> x^3+x^2
    return r4;
}


static inline uint8_t gf16_inv(uint8_t a) {
    // fermat inversion
    uint8_t a2 = gf16_squ(a);
    uint8_t a4 = gf16_squ(a2);
    uint8_t a8 = gf16_squ(a4);
    uint8_t a6 = gf16_mul(a4, a2);
    return gf16_mul(a8, a6);
}



////////////



static inline uint8_t gf256_is_nonzero(uint8_t a) {
    unsigned a8 = a;
    unsigned r = ((unsigned) 0) - a8;
    r >>= 8;
    return r & 1;
}



// gf256 := gf2[X]/ (x^8+x^4+x^3+x+1)   // 0x11b , AES field
// Oblivious Log/Exp LUT — cache-timing resistant (768 bytes)
static const uint8_t gf256_log_table[256] = {0,0,25,1,50,2,26,198,75,199,27,104,51,238,223,3,100,4,224,14,52,141,129,239,76,113,8,200,248,105,28,193,125,194,29,181,249,185,39,106,77,228,166,114,154,201,9,120,101,47,138,5,33,15,225,36,18,240,130,69,53,147,218,142,150,143,219,189,54,208,206,148,19,92,210,241,64,70,131,56,102,221,253,48,191,6,139,98,179,37,226,152,34,136,145,16,126,110,72,195,163,182,30,66,58,107,40,84,250,133,61,186,43,121,10,21,155,159,94,202,78,212,172,229,243,115,167,87,175,88,168,80,244,234,214,116,79,174,233,213,231,230,173,232,44,215,117,122,235,22,11,245,89,203,95,176,156,169,81,160,127,12,246,111,23,196,73,236,216,67,31,45,164,118,123,183,204,187,62,90,251,96,177,134,59,82,161,108,170,85,41,157,151,178,135,144,97,190,220,252,188,149,207,205,55,63,91,209,83,57,132,60,65,162,109,71,20,42,158,93,86,242,211,171,68,17,146,217,35,32,46,137,180,124,184,38,119,153,227,165,103,74,237,222,197,49,254,24,13,99,140,128,192,247,112,7};
static const uint8_t gf256_exp_table[512] = {1,3,5,15,17,51,85,255,26,46,114,150,161,248,19,53,95,225,56,72,216,115,149,164,247,2,6,10,30,34,102,170,229,52,92,228,55,89,235,38,106,190,217,112,144,171,230,49,83,245,4,12,20,60,68,204,79,209,104,184,211,110,178,205,76,212,103,169,224,59,77,215,98,166,241,8,24,40,120,136,131,158,185,208,107,189,220,127,129,152,179,206,73,219,118,154,181,196,87,249,16,48,80,240,11,29,39,105,187,214,97,163,254,25,43,125,135,146,173,236,47,113,147,174,233,32,96,160,251,22,58,78,210,109,183,194,93,231,50,86,250,21,63,65,195,94,226,61,71,201,64,192,91,237,44,116,156,191,218,117,159,186,213,100,172,239,42,126,130,157,188,223,122,142,137,128,155,182,193,88,232,35,101,175,234,37,111,177,200,67,197,84,252,31,33,99,165,244,7,9,27,45,119,153,176,203,70,202,69,207,74,222,121,139,134,145,168,227,62,66,198,81,243,14,18,54,90,238,41,123,141,140,143,138,133,148,167,242,13,23,57,75,221,124,132,151,162,253,28,36,108,180,199,82,246,1,3,5,15,17,51,85,255,26,46,114,150,161,248,19,53,95,225,56,72,216,115,149,164,247,2,6,10,30,34,102,170,229,52,92,228,55,89,235,38,106,190,217,112,144,171,230,49,83,245,4,12,20,60,68,204,79,209,104,184,211,110,178,205,76,212,103,169,224,59,77,215,98,166,241,8,24,40,120,136,131,158,185,208,107,189,220,127,129,152,179,206,73,219,118,154,181,196,87,249,16,48,80,240,11,29,39,105,187,214,97,163,254,25,43,125,135,146,173,236,47,113,147,174,233,32,96,160,251,22,58,78,210,109,183,194,93,231,50,86,250,21,63,65,195,94,226,61,71,201,64,192,91,237,44,116,156,191,218,117,159,186,213,100,172,239,42,126,130,157,188,223,122,142,137,128,155,182,193,88,232,35,101,175,234,37,111,177,200,67,197,84,252,31,33,99,165,244,7,9,27,45,119,153,176,203,70,202,69,207,74,222,121,139,134,145,168,227,62,66,198,81,243,14,18,54,90,238,41,123,141,140,143,138,133,148,167,242,13,23,57,75,221,124,132,151,162,253,28,36,108,180,199,82,246,0,0};

// Oblivious table scan for the log table (256 entries) — no secret-dependent memory access
static inline unsigned int gf256_is_nonzero_wide(unsigned int x) {
    x |= x >> 16; x |= x >> 8; x |= x >> 4; x |= x >> 2; x |= x >> 1;
    return x & 1;
}
static inline uint8_t gf256_obliv_lookup256(const uint8_t *table, uint8_t idx) {
    unsigned int result = 0;
    for (int i = 0; i < 256; i++) {
        unsigned int mask = gf256_is_nonzero_wide((unsigned int)((uint8_t)i ^ idx)) - 1u;
        result |= mask & table[i];
    }
    return (uint8_t)result;
}
// Oblivious table scan for the exp table (512 entries)
static inline uint8_t gf256_obliv_lookup512(const uint8_t *table, unsigned int idx) {
    unsigned int result = 0;
    for (int i = 0; i < 512; i++) {
        unsigned int mask = gf256_is_nonzero_wide(((unsigned int)i) ^ idx) - 1u;
        result |= mask & table[i];
    }
    return (uint8_t)result;
}
static inline uint8_t gf256_mul(uint8_t a, uint8_t b) {
    uint8_t la = gf256_obliv_lookup256(gf256_log_table, a);
    uint8_t lb = gf256_obliv_lookup256(gf256_log_table, b);
    unsigned int log_sum = (unsigned int)la + (unsigned int)lb;
    uint8_t r = gf256_obliv_lookup512(gf256_exp_table, log_sum);
    // branchless zero handling (avoids leaking whether a or b was zero)
    unsigned int keep = gf256_is_nonzero_wide((unsigned int)a) & gf256_is_nonzero_wide((unsigned int)b);
    return (uint8_t)(r & (0u - keep));
}


static inline uint8_t gf256_squ(uint8_t a) {
    uint8_t r8 = a & 1;
    r8 ^= (a << 1) & 4;    // x^1 -> x^2
    r8 ^= (a << 2) & (1 << 4); // x^2 -> x^4
    r8 ^= (a << 3) & (1 << 6); // x^3 -> x^6

    r8 ^= ((a >> 4) & 1) * 0x1b; // x^4 -> x^8  --> 0x1b
    r8 ^= ((a >> 5) & 1) * (0x1b << 2); // x^5 -> x^10  --> (0x1b<<2)
    r8 ^= ((a >> 6) & 1) * (0xab); // x^6 -> x^12  --> (0xab)
    r8 ^= ((a >> 7) & 1) * (0x9a); // x^7 -> x^14  --> (0x9a)

    return r8;
}

#define _GFINV_EXTGCD_

static inline uint8_t gf256_inv(uint8_t a) {
    #ifdef _GFINV_EXTGCD_
    // faster
    // extended GCD
    uint16_t f = 0x11b;
    uint16_t g = ((uint16_t)a) << 1;
    int16_t delta = 1;

    uint16_t r = 0x100;
    uint16_t v = 0;

    for (int i = 0; i < 15; i++) {
        uint16_t g0 = (g >> 8) & 1;
        uint16_t minus_delta = -delta;
        uint16_t swap = (minus_delta >> 15) & g0; // >>15 -> get sign bit
        //uint16_t f0g0 = g0;  // f0 is always 1

        // update delta
        delta = swap * (minus_delta << 1) + delta + 1;

        // update f, g, v, r
        uint16_t f_g = (f ^ g);
        g ^= (f * g0);
        f ^= (f_g) * swap;

        uint16_t v_r = (v ^ r);
        r ^= (v * g0);
        v ^= (v_r) * swap;

        g <<= 1;
        v >>= 1;
    }
    return v & 0xff;

    #else  //     #ifdef _GFINV_EXTGCD_
    // fermat inversion
    // 128+64+32+16+8+4+2 = 254
    uint8_t a2 = gf256_squ(a);
    uint8_t a4 = gf256_squ(a2);
    uint8_t a8 = gf256_squ(a4);
    uint8_t a4_2 = gf256_mul(a4, a2);
    uint8_t a8_4_2 = gf256_mul(a4_2, a8);
    uint8_t a64_ = gf256_squ(a8_4_2);
    a64_ = gf256_squ(a64_);
    a64_ = gf256_squ(a64_);
    uint8_t a64_2 = gf256_mul(a64_, a8_4_2);
    uint8_t a128_ = gf256_squ(a64_2);
    return gf256_mul(a2, a128_);
    #endif  //     #ifdef _GFINV_EXTGCD_
}






////////////////////////////////////////
//
//  library 32 bit vectors
//
////////////////////////////////////////



// gf16 := gf2[x]/(x^4+x+1)

static inline uint32_t gf16v_mul_u32(uint32_t a, uint8_t b) {
    uint32_t a_msb;
    uint32_t a32 = a;
    uint32_t b32 = b;
    uint32_t r32 = a32 * (b32 & 1);

    a_msb = a32 & 0x88888888; // MSB, 3rd bits
    a32 ^= a_msb;   // clear MSB
    a32 = (a32 << 1) ^ ((a_msb >> 3) * 3);
    r32 ^= (a32) * ((b32 >> 1) & 1);

    a_msb = a32 & 0x88888888; // MSB, 3rd bits
    a32 ^= a_msb;   // clear MSB
    a32 = (a32 << 1) ^ ((a_msb >> 3) * 3);
    r32 ^= (a32) * ((b32 >> 2) & 1);

    a_msb = a32 & 0x88888888; // MSB, 3rd bits
    a32 ^= a_msb;   // clear MSB
    a32 = (a32 << 1) ^ ((a_msb >> 3) * 3);
    r32 ^= (a32) * ((b32 >> 3) & 1);

    return r32;

}


static inline uint32_t gf16v_squ_u32(uint32_t a) {
    uint32_t a01 = (a & 0x11111111) + ((a << 1) & 0x44444444);
    uint32_t a23 = (((a >> 2) & 0x11111111) + ((a >> 1) & 0x44444444)) * 3;
    return a01 ^ a23;
}



static inline uint32_t _gf16v_mul_u32_u32(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t b0, uint32_t b1, uint32_t b2, uint32_t b3) {
    uint32_t c0 = a0 & b0;
    uint32_t c1 = (a0 & b1) ^ (a1 & b0);
    uint32_t c2 = (a0 & b2) ^ (a1 & b1) ^ (a2 & b0);
    uint32_t c3 = (a0 & b3) ^ (a1 & b2) ^ (a2 & b1) ^ (a3 & b0);
    uint32_t c4 = (a1 & b3) ^ (a2 & b2) ^ (a3 & b1);
    uint32_t c5 = (a2 & b3) ^ (a3 & b2);
    uint32_t c6 = a3 & b3;

    return c0 ^ (c1 << 1) ^ (c2 << 2) ^ (c3 << 3) ^ (c4 * 3) ^ (c5 * 6) ^ (c6 * 12);
}

static inline uint32_t gf16v_mul_u32_u32(uint32_t a, uint32_t b) {
    uint32_t a0 = a & 0x11111111;
    uint32_t a1 = (a >> 1) & 0x11111111;
    uint32_t a2 = (a >> 2) & 0x11111111;
    uint32_t a3 = (a >> 3) & 0x11111111;
    uint32_t b0 = b & 0x11111111;
    uint32_t b1 = (b >> 1) & 0x11111111;
    uint32_t b2 = (b >> 2) & 0x11111111;
    uint32_t b3 = (b >> 3) & 0x11111111;

    return _gf16v_mul_u32_u32(a0, a1, a2, a3, b0, b1, b2, b3);
}



/////////////////////////////



// gf256 := gf2[X]/ (x^8+x^4+x^3+x+1)   // 0x11b , AES field


static inline uint32_t gf256v_mul_u32(uint32_t a, uint8_t b) {
    uint32_t a_msb;
    uint32_t a32 = a;
    uint32_t b32 = b;
    uint32_t r32 = a32 * (b32 & 1);

    a_msb = a32 & 0x80808080; // MSB, 7th bits
    a32 ^= a_msb;   // clear MSB
    a32 = (a32 << 1) ^ ((a_msb >> 7) * 0x1b);
    r32 ^= (a32) * ((b32 >> 1) & 1);

    a_msb = a32 & 0x80808080; // MSB, 7th bits
    a32 ^= a_msb;   // clear MSB
    a32 = (a32 << 1) ^ ((a_msb >> 7) * 0x1b);
    r32 ^= (a32) * ((b32 >> 2) & 1);

    a_msb = a32 & 0x80808080; // MSB, 7th bits
    a32 ^= a_msb;   // clear MSB
    a32 = (a32 << 1) ^ ((a_msb >> 7) * 0x1b);
    r32 ^= (a32) * ((b32 >> 3) & 1);

    a_msb = a32 & 0x80808080; // MSB, 7th bits
    a32 ^= a_msb;   // clear MSB
    a32 = (a32 << 1) ^ ((a_msb >> 7) * 0x1b);
    r32 ^= (a32) * ((b32 >> 4) & 1);

    a_msb = a32 & 0x80808080; // MSB, 7th bits
    a32 ^= a_msb;   // clear MSB
    a32 = (a32 << 1) ^ ((a_msb >> 7) * 0x1b);
    r32 ^= (a32) * ((b32 >> 5) & 1);

    a_msb = a32 & 0x80808080; // MSB, 7th bits
    a32 ^= a_msb;   // clear MSB
    a32 = (a32 << 1) ^ ((a_msb >> 7) * 0x1b);
    r32 ^= (a32) * ((b32 >> 6) & 1);

    a_msb = a32 & 0x80808080; // MSB, 7th bits
    a32 ^= a_msb;   // clear MSB
    a32 = (a32 << 1) ^ ((a_msb >> 7) * 0x1b);
    r32 ^= (a32) * ((b32 >> 7) & 1);

    return r32;
}

static inline uint32_t gf256v_squ_u32(uint32_t a) {

    uint32_t r32 = a & 0x01010101;
    r32 ^= (a << 1)   & 0x04040404; // x^1 -> x^2
    r32 ^= (a << 2)   & 0x10101010; // x^2 -> x^4
    r32 ^= (a << 3)   & 0x40404040; // x^3 -> x^6

    r32 ^= ((a >> 4) & 0x01010101) * 0x1b; // x^4 -> x^8  --> 0x1b
    r32 ^= ((a >> 5) & 0x01010101) * (0x1b << 2); // x^5 -> x^10  --> (0x1b<<2)
    r32 ^= ((a >> 6) & 0x01010101) * (0xab); // x^6 -> x^12  --> (0xab)
    r32 ^= ((a >> 7) & 0x01010101) * (0x9a); // x^7 -> x^14  --> (0x9a)

    return r32;
}





//////////////////////////////



//  return v[0]^v[1]^v[2]^v[3]
static inline uint8_t gf256v_reduce_u32(uint32_t a) {
    uint16_t *aa = (uint16_t *) (&a);
    uint16_t r = aa[0] ^ aa[1];
    uint8_t *rr = (uint8_t *) (&r);
    return rr[0] ^ rr[1];
}


static inline uint8_t gf16v_reduce_u32(uint32_t a) {
    uint8_t r256 = gf256v_reduce_u32(a);
    return (r256 & 0xf) ^ (r256 >> 4);
}










#endif // _GF16_H_

