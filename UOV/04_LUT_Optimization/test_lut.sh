#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 4: LUT Optimization Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# نسخ baseline code
echo "📦 Copying baseline code..."
mkdir -p code
cp -r ../../01_Baseline/code/amd64 ./code/
echo "✅ Code copied"
echo ""

cd code/amd64

# نتحقق من GF operations الموجودة
echo "🔍 Analyzing GF operations in code..."
echo ""

# ابحث عن ملفات GF
echo "GF-related files:"
find . -name "*gf*" -o -name "*blas*" | head -10
echo ""

# نشوف محتوى blas
echo "Checking blas operations..."
ls -la Ip/*blas* 2>/dev/null || ls -la III/*blas* 2>/dev/null || echo "No blas files in subdirs"
echo ""

# نشوف إذا في multiplication tables
echo "Searching for multiplication implementations..."
grep -l "mul\|multiply" Ip/*.c 2>/dev/null | head -5
echo ""

cd ../..

# الخطة
cat > lut_analysis.md << 'DOC'
# LUT Analysis for UOV

## Current Status

Baseline code uses reference implementations.
Need to check if we can add lookup tables for:

1. **GF(16) multiplication** (Category I - Ip)
   - Field: GF(2^4)
   - Table size: 16×16 = 256 bytes

2. **GF(256) multiplication** (Categories III, V)
   - Field: GF(2^8)  
   - Table size: 256×256 = 64 KB

## Implementation Plan

1. Identify GF multiplication functions
2. Generate LUT tables
3. Modify code to use LUT
4. Benchmark and compare

## Expected Results

Since AVX2 already optimized matrix operations (83-90% of time),
LUT may only improve the remaining GF operations (if any).

Realistic expectation: 0-5% additional improvement (if any)
DOC

echo "✅ Analysis document created"
echo ""

# نحتاج نشوف الكود الفعلي
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next: Examine actual GF operations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# نشوف ملف matrix operations
echo "📄 Examining matrix operations file..."
if [ -f code/amd64/Ip/blas_matrix_ref.c ]; then
    echo "Found: Ip/blas_matrix_ref.c"
    echo ""
    echo "First 50 lines:"
    head -50 code/amd64/Ip/blas_matrix_ref.c
elif [ -f code/amd64/III/blas_matrix_ref.c ]; then
    echo "Found: III/blas_matrix_ref.c"
    echo ""
    echo "First 50 lines:"
    head -50 code/amd64/III/blas_matrix_ref.c
fi

