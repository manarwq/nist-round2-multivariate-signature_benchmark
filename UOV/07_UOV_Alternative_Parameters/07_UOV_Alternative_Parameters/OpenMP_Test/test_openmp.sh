#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 5: OpenMP Test - All 3 Levels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Note: No OpenMP directives found in code"
echo "      Testing -fopenmp flag effect (overhead check)"
echo ""

RESULTS_CSV="results/openmp_results.csv"
mkdir -p results
rm -f "$RESULTS_CSV"

cd code/amd64

PARAMS=("Ip" "III" "V")
PARAM_NAMES=("Category I (GF16)" "Category III (GF256)" "Category V (GF256)")

for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    
    # ==========================================
    # Test 1: Without OpenMP flag
    # ==========================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NAME - WITHOUT -fopenmp"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    make clean > /dev/null 2>&1
    make PROJ=$PARAM > /dev/null 2>&1
    
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
        echo "$PARAM,no_openmp,$T" >> ../../$RESULTS_CSV
    done
    echo ""
    
    # ==========================================
    # Test 2: With OpenMP flag
    # ==========================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NAME - WITH -fopenmp"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    make clean > /dev/null 2>&1
    make PROJ=$PARAM CFLAGS="-fopenmp" > /dev/null 2>&1
    
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
echo "Results Summary"
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
with open('results/openmp_results.csv', 'r') as f:
    for line in f:
        param, method, time = line.strip().split(',')
        results[param][method].append(float(time))

param_names = {
    'Ip': 'Category I (GF16)',
    'III': 'Category III (GF256)',
    'V': 'Category V (GF256)'
}

print("=" * 90)
print("Parameter Set         | Phase1   | No OpenMP | With -fopenmp | Change")
print("=" * 90)

for param in ['Ip', 'III', 'V']:
    if param in results:
        phase1 = statistics.median(baseline_phase1[param])
        no_omp = statistics.median(results[param]['no_openmp'])
        with_omp = statistics.median(results[param]['openmp'])
        
        change = no_omp / with_omp
        change_pct = (change - 1) * 100
        
        status = "✅" if with_omp < no_omp else "❌" if with_omp > no_omp else "="
        
        name = param_names[param]
        print(f"{name:21s} | {phase1:7.3f}s | {no_omp:8.3f}s | {with_omp:12.3f}s | "
              f"{change:.2f}x ({change_pct:+.1f}%) {status}")

print("=" * 90)
print()                                  
print("Note: Since code has no OpenMP directives, -fopenmp flag")
print("      should have minimal/no effect. This tests overhead only.")
PY

echo ""
echo "OpenMP testing complete!"
echo "Results: results/openmp_results.csv"

