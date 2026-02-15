#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fixing LUT redefinition conflict"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd code/amd64/Ip

# استعادة blas_u64.h الأصلي
cp blas_u64.h.backup blas_u64.h

# نعمل approach أبسط: نضيف LUT في نهاية الملف فقط
cat >> blas_u64.h << 'LUTCODE'

// ============================================================================
// Vector LUT Support (Conditional replacement)
// ============================================================================

#ifdef USE_GF16_VECTOR_LUT

#include "gf16v_lut.h"

// Override the original implementations
#undef _gf16v_madd_u64
#define _gf16v_madd_u64 gf16v_madd_lut

#undef _gf16v_mul_scalar_u64
#define _gf16v_mul_scalar_u64 gf16v_mul_scalar_lut

#endif

LUTCODE

echo "✅ Fixed blas_u64.h"
echo ""

cd ../../..

# اختبر البناء
echo "Testing build..."
cd code/amd64
make clean > /dev/null 2>&1
echo "Building with Vector LUT..."
make PROJ=Ip CFLAGS="-DUSE_GF16_VECTOR_LUT" 2>&1 | tail -20

if [ -f sign_api-test ]; then
    echo ""
    echo "✅ Build successful!"
else
    echo ""
    echo "❌ Build still failing"
fi

