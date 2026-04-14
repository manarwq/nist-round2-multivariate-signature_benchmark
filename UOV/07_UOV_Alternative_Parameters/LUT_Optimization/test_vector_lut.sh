#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Vector LUT Implementation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_CSV="results/vector_lut_results.csv"
rm -f "$RESULTS_CSV"

cd code/amd64

# اختبر Category I فقط (يستخدم GF16)
PARAM="Ip"

# ==========================================
# Test 1: Baseline (no LUT)
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Category I - NO LUT (Baseline)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

make clean > /dev/null 2>&1
make PROJ=$PARAM > /dev/null 2>&1

if [ ! -f sign_api-test ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful"
echo ""

echo "Running 10 tests..."
for run in {1..10}; do
    T=$(/usr/bin/time -f "%e" ./sign_api-test 2>&1 >/dev/null | tail -1)
    echo "  Run $run: ${T}s"
    echo "baseline,$T" >> ../../$RESULTS_CSV
done
echo ""

# ==========================================
# Test 2: With Vector LUT
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Category I - WITH Vector LUT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

make clean > /dev/null 2>&1
make PROJ=$PARAM CFLAGS="-DUSE_GF16_VECTOR_LUT" > /dev/null 2>&1

if [ ! -f sign_api-test ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful"
echo ""

echo "Running 10 tests..."
for run in {1..10}; do
    T=$(/usr/bin/time -f "%e" ./sign_api-test 2>&1 >/dev/null | tail -1)
    echo "  Run $run: ${T}s"
    echo "vector_lut,$T" >> ../../$RESULTS_CSV
done
echo ""

cd ../..

# Analysis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

results = defaultdict(list)

with open('results/vector_lut_results.csv', 'r') as f:
    for line in f:
        method, time = line.strip().split(',')
        results[method].append(float(time))

# Load Phase 1 baseline
baseline_phase1 = []
with open('../01_Baseline/results/baseline_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        if param == 'Ip':
            baseline_phase1.append(float(time))

orig_baseline = statistics.median(baseline_phase1)
baseline = statistics.median(results['baseline'])
vector_lut = statistics.median(results['vector_lut'])

print("=" * 80)
print("Method              | Median Time | vs Phase1 Baseline | Change")
print("=" * 80)
print(f"Phase 1 Baseline    | {orig_baseline:10.3f}s |         -          |   -")
print(f"Current Baseline    | {baseline:10.3f}s | {orig_baseline/baseline:17.2f}x | {((orig_baseline/baseline-1)*100):+6.1f}%")
print(f"Vector LUT          | {vector_lut:10.3f}s | {orig_baseline/vector_lut:17.2f}x | {((orig_baseline/vector_lut-1)*100):+6.1f}%")
print("=" * 80)
print()

# LUT vs baseline comparison
if vector_lut < baseline:
    speedup = baseline / vector_lut
    improvement = (speedup - 1) * 100
    status = "✅ IMPROVEMENT"
    print(f"Vector LUT vs Current Baseline: {speedup:.2f}x faster ({improvement:+.1f}%) {status}")
else:
    slowdown = vector_lut / baseline
    degradation = (slowdown - 1) * 100
    status = "❌ SLOWER"
    print(f"Vector LUT vs Current Baseline: {slowdown:.2f}x slower ({degradation:+.1f}%) {status}")

PY

echo ""
echo "✅ Vector LUT testing complete!"
echo "📄 Results: results/vector_lut_results.csv"

