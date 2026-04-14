#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 5: OpenMP - CORRECT Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_CSV="results/openmp_correct_results.csv"
rm -f "$RESULTS_CSV"

cd code/amd64

PARAMS=("Ip" "III" "V")
PARAM_NAMES=("Category I (GF16)" "Category III (GF256)" "Category V (GF256)")

for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    
    # ==========================================
    # Test 1: Without OpenMP
    # ==========================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NAME - NO OpenMP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    make clean > /dev/null 2>&1
    make PROJ=$PARAM > /dev/null 2>&1
    
    if [ ! -f sign_api-test ]; then
        echo " Build failed"
        continue
    fi
    
    echo "Build successful"
    echo ""
    
    echo "Running 10 tests..."
    for run in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./sign_api-test 2>&1 >/dev/null | tail -1)
        echo "  Run $run: ${T}s"
        echo "$PARAM,no_openmp,$T" >> ../../$RESULTS_CSV
    done
    echo ""
    
    # ==========================================
    # Test 2: With OpenMP (CORRECT FLAGS)
    # ==========================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NAME - WITH OpenMP (correct flags)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    make clean > /dev/null 2>&1
    make PROJ=$PARAM EXTRA_CFLAGS="-fopenmp" > /dev/null 2>&1
    
    if [ ! -f sign_api-test ]; then
        echo "Build failed"
        continue
    fi
    
    echo "Build successful"
    echo ""
    
    echo "Running 10 tests..."
    for run in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./sign_api-test 2>&1 >/dev/null | tail -1)
        echo "  Run $run: ${T}s"
        echo "$PARAM,openmp,$T" >> ../../$RESULTS_CSV
    done
    echo ""
done

cd ../..

# Analysis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results Summary (CORRECT)"
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
with open('results/openmp_correct_results.csv', 'r') as f:
    for line in f:
        param, method, time = line.strip().split(',')
        results[param][method].append(float(time))

param_names = {
    'Ip': 'Category I (GF16)',
    'III': 'Category III (GF256)',
    'V': 'Category V (GF256)'
}

print("=" * 90)
print("Parameter Set         | Phase1   | No OpenMP | With OpenMP | Change")
print("=" * 90)

for param in ['Ip', 'III', 'V']:
    if param in results:
        phase1 = statistics.median(baseline_phase1[param])
        no_omp = statistics.median(results[param]['no_openmp'])
        with_omp = statistics.median(results[param]['openmp'])
        
        speedup = no_omp / with_omp
        change_pct = (speedup - 1) * 100
        
        status = "✅" if with_omp < no_omp else "❌"
        
        name = param_names[param]
        print(f"{name:21s} | {phase1:7.3f}s | {no_omp:8.3f}s | {with_omp:10.3f}s | "
              f"{speedup:.2f}x ({change_pct:+.1f}%) {status}")

print("=" * 90)
print()
print("Note: Code has no OpenMP directives.")
print("      This shows overhead of -fopenmp flag with optimizations intact.")
PY

echo ""
echo "OpenMP testing complete (CORRECT)!"
echo "Results: results/openmp_correct_results.csv"

