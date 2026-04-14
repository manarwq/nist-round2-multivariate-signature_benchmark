#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 1: UOV Baseline Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_CSV="results/baseline_results.csv"
rm -f "$RESULTS_CSV"

# Parameter sets to test
PARAMS=("Ip" "III" "V")
PARAM_NAMES=("Category I (GF16)" "Category III (GF256)" "Category V (GF256)")

cd code/amd64

for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: $NAME ($PARAM)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Clean and build
    echo "Building..."
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

# Analysis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

results = defaultdict(list)

with open('results/baseline_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        results[param].append(float(time))

param_names = {
    'Ip': 'Category I (GF16, 160, 64)',
    'III': 'Category III (GF256, 184, 72)',
    'V': 'Category V (GF256, 244, 96)'
}

print("=" * 70)
print("Parameter Set              | Median Time | Min     | Max")
print("=" * 70)

for param in ['Ip', 'III', 'V']:
    if param in results:
        times = results[param]
        median = statistics.median(times)
        min_t = min(times)
        max_t = max(times)
        name = param_names[param]
        print(f"{name:26s} | {median:10.3f}s | {min_t:.3f}s | {max_t:.3f}s")

print("=" * 70)
PY

echo ""
echo "✅ Baseline testing complete!"
echo "📄 Results saved: results/baseline_results.csv"

