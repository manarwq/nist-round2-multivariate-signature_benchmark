/// @file gf16v_lut.h
/// @brief LUT-based vector operations for GF(16)

#ifndef _GF16V_LUT_H_
#define _GF16V_LUT_H_

#include <stdint.h>
#include "gf16_lut.h"

#ifdef  __cplusplus
extern  "C" {
#endif

// LUT-based vector multiply-add
static inline void gf16v_madd_lut(uint8_t *accu_c, const uint8_t *a, uint8_t gf16_b, unsigned _num_byte) {
    // Process byte by byte using LUT
    for (unsigned i = 0; i < _num_byte; i++) {
        uint8_t a_byte = a[i];
        
        // Each byte contains 2 GF(16) elements (4 bits each)
        uint8_t a_low = a_byte & 0xf;        // Lower nibble
        uint8_t a_high = (a_byte >> 4) & 0xf; // Upper nibble
        
        // Multiply using LUT
        uint8_t result_low = gf16_mul_lut(a_low, gf16_b);
        uint8_t result_high = gf16_mul_lut(a_high, gf16_b);
        
        // Combine and accumulate
        uint8_t result = result_low | (result_high << 4);
        accu_c[i] ^= result;
    }
}

// LUT-based vector multiply
static inline void gf16v_mul_scalar_lut(uint8_t *a, uint8_t gf16_b, unsigned _num_byte) {
    for (unsigned i = 0; i < _num_byte; i++) {
        uint8_t a_byte = a[i];
        
        uint8_t a_low = a_byte & 0xf;
        uint8_t a_high = (a_byte >> 4) & 0xf;
        
        uint8_t result_low = gf16_mul_lut(a_low, gf16_b);
        uint8_t result_high = gf16_mul_lut(a_high, gf16_b);
        
        a[i] = result_low | (result_high << 4);
    }
}

#ifdef  __cplusplus
}
#endif

#endif // _GF16V_LUT_H_
