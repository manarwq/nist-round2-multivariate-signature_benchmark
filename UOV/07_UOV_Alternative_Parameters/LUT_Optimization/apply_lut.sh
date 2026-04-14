#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Applying GF(16) LUT to code"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# نسخ gf16_lut.h إلى المجلدات الثلاثة
for param in Ip Is III V; do
    if [ -d "code/amd64/$param" ]; then
        echo "📦 Copying gf16_lut.h to $param..."
        cp gf16_lut.h code/amd64/$param/
    fi
done

echo "✅ LUT files copied"
echo ""

# تعديل gf16.h لإضافة LUT option
echo "📝 Modifying gf16.h to add LUT support..."

cd code/amd64/Ip

# نضيف في بداية gf16.h
cat > gf16_modified.h << 'HEADER'
/// @file gf16.h
/// @brief Library for arithmetics in GF(16) and GF(256)
///

#ifndef _GF16_H_
#define _GF16_H_

#include <stdint.h>

// ============================================================================
// LUT Support (Added for optimization testing)
// ============================================================================

#ifdef USE_GF16_LUT

#include "gf16_lut.h"

// Replace gf16_mul with LUT version
#define gf16_mul gf16_mul_lut

#else

// Original algorithmic implementation
static inline uint8_t gf16_mul(uint8_t a, uint8_t b) {
    uint8_t r8 = (a & 1) * b;
    r8 ^= (a & 2) * b;
    r8 ^= (a & 4) * b;
    r8 ^= (a & 8) * b;

    // reduction
    uint8_t r4 = r8 ^ (((r8 >> 4) & 5) * 3);
    r4 ^= (((r8 >> 5) & 1) * 6);
    return (r4 & 0xf);
}

#endif

HEADER

# نضيف باقي الملف (بدون gf16_mul الأصلي)
tail -n +30 gf16.h | grep -A 9999 "gf16_squ" >> gf16_modified.h

# نستبدل
mv gf16.h gf16.h.backup
mv gf16_modified.h gf16.h

echo "✅ gf16.h modified"
echo ""

cd ../../..

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ready to test!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Test without LUT (baseline)"
echo "  2. Test with LUT (USE_GF16_LUT)"
echo "  3. Compare results"

