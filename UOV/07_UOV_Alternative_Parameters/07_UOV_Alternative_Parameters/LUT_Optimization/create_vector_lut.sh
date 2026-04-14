#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Creating Vector-based LUT Implementation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# إنشاء vector LUT implementation
cat > gf16v_lut.h << 'HEADER'
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
HEADER

echo "✅ Created gf16v_lut.h"
echo ""

# نضيفها للمجلدات
for param in Ip Is; do
    if [ -d "code/amd64/$param" ]; then
        echo "📦 Copying to $param..."
        cp gf16v_lut.h code/amd64/$param/
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# نعدل blas_u64.h لاستخدام LUT
echo "📝 Modifying blas_u64.h to use vector LUT..."

cd code/amd64/Ip

# نضيف في بداية blas_u64.h
cat > blas_u64_modified.h << 'HEADER2'
/// @file blas_u64.h
/// @brief Inlined functions for implementing basic linear algebra functions for uint64 arch.
///

#ifndef _BLAS_U64_H_
#define _BLAS_U64_H_

#include <string.h>
#include <stdint.h>
#include <stdio.h>

#include <stdint.h>

#include "gf16.h"

#include "gf16_u64.h"

#include "blas_u32.h"

// ============================================================================
// Vector LUT Support (Added for optimization)
// ============================================================================

#ifdef USE_GF16_VECTOR_LUT

#include "gf16v_lut.h"

// Replace vector operations with LUT versions
#define _gf16v_madd_u64 gf16v_madd_lut
#define _gf16v_mul_scalar_u64 gf16v_mul_scalar_lut

#endif

#ifdef  __cplusplus
extern  "C" {
#endif

HEADER2

# نضيف باقي الملف
tail -n +29 blas_u64.h >> blas_u64_modified.h

mv blas_u64.h blas_u64.h.backup
mv blas_u64_modified.h blas_u64.h

echo "✅ Modified blas_u64.h"
echo ""

cd ../../..

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ready to test Vector LUT!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Build with: make CFLAGS=\"-DUSE_GF16_VECTOR_LUT\""

