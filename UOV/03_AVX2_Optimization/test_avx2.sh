#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 3: AVX2 Optimization Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_CSV="results/avx2_results.csv"
mkdir -p results
rm -f "$RESULTS_CSV"

cd code/avx2

PARAMS=("Ip" "III" "V")
PARAM_NAMES=("Category I (GF16)" "Category III (GF256)" "Category V (GF256)")

for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing AVX2: $NAME ($PARAM)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Clean and build
    echo "Building with AVX2..."
    make clean > /dev/null 2>&1
    make PROJ=$PARAM > /dev/null 2>&1
    
    if [ ! -f sign_api-test ]; then
        echo "❌ Build failed for $PARAM"
        continue
    fi
    
    echo "✅ Build successful"
    echo ""
    
    # Run 10 tests
    echo "Running 10 tests..."
    for run in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./sign_api-test 2>&1 >/dev/null | tail -1)
        echo "  Run $run: ${T}s"
        echo "$PARAM,$T" >> ../../$RESULTS_CSV
    done
    echo ""
done

cd ../..

# Comparison with baseline
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: AVX2 vs Baseline"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

# Load baseline
baseline = defaultdict(list)
with open('../01_Baseline/results/baseline_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        baseline[param].append(float(time))

# Load AVX2
avx2 = defaultdict(list)
with open('results/avx2_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        avx2[param].append(float(time))

param_names = {
    'Ip': 'Category I (GF16)',
    'III': 'Category III (GF256)',
    'V': 'Category V (GF256)'
}

print("=" * 80)
print("Parameter Set         | Baseline | AVX2    | Speedup | Improvement")
print("=" * 80)

for param in ['Ip', 'III', 'V']:
    if param in baseline and param in avx2:
        base_med = statistics.median(baseline[param])
        avx2_med = statistics.median(avx2[param])
        speedup = base_med / avx2_med
        improvement = (speedup - 1) * 100
        
        name = param_names[param]
        status = "✅" if speedup > 1 else "❌"
        
        print(f"{name:21s} | {base_med:7.3f}s | {avx2_med:6.3f}s | {speedup:6.2f}x | {improvement:+6.1f}% {status}")

print("=" * 80)
PY

echo ""
echo "✅ AVX2 testing complete!"
echo "📄 Results: results/avx2_results.csv"

