#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 4: LUT Test - Baseline vs LUT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_CSV="results/lut_comparison.csv"
mkdir -p results
rm -f "$RESULTS_CSV"

cd code/amd64

PARAMS=("Ip")  # نختبر Ip فقط (يستخدم GF16)
PARAM_NAMES=("Category I (GF16)")

for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    
    # ==========================================
    # Test 1: Without LUT
    # ==========================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NAME - WITHOUT LUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    make clean > /dev/null 2>&1
    make PROJ=$PARAM > /dev/null 2>&1
    
    if [ ! -f sign_api-test ]; then
        echo "❌ Build failed"
        continue
    fi
    
    echo "✅ Build successful (no LUT)"
    echo ""
    
    echo "Running 10 tests..."
    for run in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./sign_api-test 2>&1 >/dev/null | tail -1)
        echo "  Run $run: ${T}s"
        echo "$PARAM,no_lut,$T" >> ../../$RESULTS_CSV
    done
    echo ""
    
    # ==========================================
    # Test 2: With LUT
    # ==========================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NAME - WITH LUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    make clean > /dev/null 2>&1
    make PROJ=$PARAM CFLAGS="-DUSE_GF16_LUT" > /dev/null 2>&1
    
    if [ ! -f sign_api-test ]; then
        echo "❌ Build failed"
        continue
    fi
    
    echo "✅ Build successful (with LUT)"
    echo ""
    
    echo "Running 10 tests..."
    for run in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./sign_api-test 2>&1 >/dev/null | tail -1)
        echo "  Run $run: ${T}s"
        echo "$PARAM,lut,$T" >> ../../$RESULTS_CSV
    done
    echo ""
done

cd ../..

# Analysis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: LUT vs Baseline"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

results = defaultdict(lambda: defaultdict(list))

with open('results/lut_comparison.csv', 'r') as f:
    for line in f:
        param, opt, time = line.strip().split(',')
        results[param][opt].append(float(time))

# Load baseline from Phase 1
baseline_times = []
with open('../01_Baseline/results/baseline_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        if param == 'Ip':
            baseline_times.append(float(time))

baseline_med = statistics.median(baseline_times)

print("=" * 80)
print("Optimization  | Median Time | vs Baseline | Improvement")
print("=" * 80)

no_lut = statistics.median(results['Ip']['no_lut'])
lut = statistics.median(results['Ip']['lut'])

print(f"Baseline      | {baseline_med:10.3f}s |      -      |      -")
print(f"No LUT        | {no_lut:10.3f}s | {baseline_med/no_lut:10.2f}x | {((baseline_med/no_lut-1)*100):+6.1f}%")
print(f"With LUT      | {lut:10.3f}s | {baseline_med/lut:10.2f}x | {((baseline_med/lut-1)*100):+6.1f}%")

print("=" * 80)
print()

# LUT vs No LUT
if lut < no_lut:
    speedup = no_lut / lut
    improvement = (speedup - 1) * 100
    print(f"LUT improvement over no-LUT: {speedup:.2f}x ({improvement:+.1f}%) ✅")
else:
    slowdown = lut / no_lut
    degradation = (slowdown - 1) * 100
    print(f"LUT slower than no-LUT: {slowdown:.2f}x ({degradation:+.1f}%) ❌")

PY

echo ""
echo "✅ LUT testing complete!"
echo "📄 Results: results/lut_comparison.csv"

