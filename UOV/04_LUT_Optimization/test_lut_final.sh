#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 4: LUT Test - All 3 Levels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_CSV="results/lut_results.csv"
mkdir -p results
rm -f "$RESULTS_CSV"

cd code/amd64

PARAMS=("Ip" "III" "V")
PARAM_NAMES=("Category I (GF16)" "Category III (GF256)" "Category V (GF256)")

for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    
    # ==========================================
    # Test 1: Baseline code (no LUT)
    # ==========================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NAME - NO LUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    make clean > /dev/null 2>&1
    make PROJ=$PARAM > /dev/null 2>&1
    
    if [ ! -f sign_api-test ]; then
        echo "❌ Build failed"
        continue
    fi
    
    echo "✅ Build successful"
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
    
    echo "✅ Build successful"
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
echo "Results Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

# Load baseline from Phase 1
baseline = defaultdict(list)
with open('../01_Baseline/results/baseline_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        baseline[param].append(float(time))

# Load LUT results
lut_results = defaultdict(lambda: defaultdict(list))
with open('results/lut_results.csv', 'r') as f:
    for line in f:
        param, opt, time = line.strip().split(',')
        lut_results[param][opt].append(float(time))

param_names = {
    'Ip': 'Category I (GF16)',
    'III': 'Category III (GF256)',
    'V': 'Category V (GF256)'
}

print("=" * 90)
print("Parameter Set         | Baseline | No LUT  | With LUT | LUT vs Baseline | LUT Benefit")
print("=" * 90)

for param in ['Ip', 'III', 'V']:
    base = statistics.median(baseline[param])
    no_lut = statistics.median(lut_results[param]['no_lut'])
    with_lut = statistics.median(lut_results[param]['lut'])
    
    speedup_base = base / with_lut
    improvement_base = (speedup_base - 1) * 100
    
    speedup_lut = no_lut / with_lut
    improvement_lut = (speedup_lut - 1) * 100
    
    name = param_names[param]
    status = "✅" if with_lut < no_lut else "❌"
    
    print(f"{name:21s} | {base:7.3f}s | {no_lut:6.3f}s | {with_lut:7.3f}s | "
          f"{speedup_base:6.2f}x ({improvement_base:+5.1f}%) | "
          f"{speedup_lut:5.2f}x ({improvement_lut:+4.1f}%) {status}")

print("=" * 90)
PY

echo ""
echo "✅ LUT testing complete!"
echo "📄 Results: results/lut_results.csv"

