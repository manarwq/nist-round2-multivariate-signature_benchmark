#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Vector LUT - All 3 Levels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_CSV="results/vector_lut_all_results.csv"
rm -f "$RESULTS_CSV"

cd code/amd64

PARAMS=("Ip" "III" "V")
PARAM_NAMES=("Category I (GF16)" "Category III (GF256)" "Category V (GF256)")

for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    
    # ==========================================
    # Test 1: Baseline (no LUT)
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
    # Test 2: With Vector LUT
    # ==========================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NAME - WITH Vector LUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    make clean > /dev/null 2>&1
    make PROJ=$PARAM CFLAGS="-DUSE_GF16_VECTOR_LUT" > /dev/null 2>&1
    
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
        echo "$PARAM,vector_lut,$T" >> ../../$RESULTS_CSV
    done
    echo ""
done

cd ../..

# Analysis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Final Results Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

# Load Phase 1 baseline
baseline_phase1 = defaultdict(list)
with open('../01_Baseline/results/baseline_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        baseline_phase1[param].append(float(time))

# Load current results
results = defaultdict(lambda: defaultdict(list))
with open('results/vector_lut_all_results.csv', 'r') as f:
    for line in f:
        param, method, time = line.strip().split(',')
        results[param][method].append(float(time))

param_names = {
    'Ip': 'Category I (GF16)',
    'III': 'Category III (GF256)',
    'V': 'Category V (GF256)'
}

print("=" * 95)
print("Parameter Set         | Phase1   | No LUT  | Vec LUT | LUT vs Phase1 | LUT vs No-LUT")
print("=" * 95)

for param in ['Ip', 'III', 'V']:
    if param in results:
        phase1 = statistics.median(baseline_phase1[param])
        no_lut = statistics.median(results[param]['no_lut'])
        vec_lut = statistics.median(results[param]['vector_lut'])
        
        speedup_phase1 = phase1 / vec_lut
        improvement_phase1 = (speedup_phase1 - 1) * 100
        
        speedup_nolut = no_lut / vec_lut
        improvement_nolut = (speedup_nolut - 1) * 100
        
        status1 = "✅" if vec_lut < phase1 else "❌"
        status2 = "✅" if vec_lut < no_lut else "❌"
        
        name = param_names[param]
        print(f"{name:21s} | {phase1:7.3f}s | {no_lut:6.3f}s | {vec_lut:6.3f}s | "
              f"{speedup_phase1:5.2f}x ({improvement_phase1:+5.1f}%) {status1} | "
              f"{speedup_nolut:5.2f}x ({improvement_nolut:+4.1f}%) {status2}")

print("=" * 95)
PY

echo ""
echo "✅ Vector LUT testing complete (all levels)!"
echo "📄 Results: results/vector_lut_all_results.csv"

