#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Multiplication LUT for qr-UOV Level 1"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Config للـ Level 1
echo "-DQRUOV_dir=qruov1q127L3v156m54 -DQRUOV_security_strength_category=1 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=156 -DQRUOV_m=54 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" > qruov_config.txt

# ==========================================
# Test 1: Original (no LUT)
# ==========================================

echo "Test 1: Original multiplication (no LUT)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cp Fql.h.backup Fql.h
make clean > /dev/null 2>&1
make > /dev/null 2>&1

echo "Running 5 tests..."
for i in {1..5}; do
    T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
    echo "  Run $i: ${T}s"
    echo "original,$T" >> lut_test_results.csv
done

echo ""

# ==========================================
# Test 2: With LUT
# ==========================================

echo "Test 2: With Multiplication LUT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# استخدام الملف الجديد
cp Fql_with_lut.h Fql.h

# تعديل Makefile لإضافة -DUSE_MUL_LUT
sed -i 's/CFLAGS=/CFLAGS=-DUSE_MUL_LUT /' Makefile

make clean > /dev/null 2>&1
make > /dev/null 2>&1

echo "Running 5 tests..."
for i in {1..5}; do
    T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
    echo "  Run $i: ${T}s"
    echo "lut,$T" >> lut_test_results.csv
done

echo ""

# ==========================================
# Analysis
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

results = defaultdict(list)

with open('lut_test_results.csv', 'r') as f:
    for line in f:
        method, time = line.strip().split(',')
        results[method].append(float(time))

orig = statistics.median(results['original'])
lut = statistics.median(results['lut'])

print("=" * 60)
print("Method    | Median Time | Improvement")
print("=" * 60)
print(f"Original  | {orig:10.3f}s |      -")
print(f"With LUT  | {lut:10.3f}s | ", end="")

if lut < orig:
    speedup = orig / lut
    improvement = (speedup - 1) * 100
    print(f"{speedup:.2f}x ({improvement:+.1f}%) ✅")
else:
    slowdown = lut / orig
    degradation = (slowdown - 1) * 100
    print(f"{slowdown:.2f}x ({degradation:+.1f}%) ❌")

print("=" * 60)
PY

# Restore
cp Fql.h.backup Fql.h
sed -i 's/CFLAGS=-DUSE_MUL_LUT /CFLAGS=/' Makefile

echo ""
echo "✅ Test complete!"
echo "Results: lut_test_results.csv"

