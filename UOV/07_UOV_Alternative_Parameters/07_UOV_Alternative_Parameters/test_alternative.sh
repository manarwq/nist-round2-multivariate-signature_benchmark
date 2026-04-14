#!/bin/bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 1: UOV Alternative Parameters Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
RESULTS_CSV="results/alternative_results.csv"
mkdir -p results
rm -f "$RESULTS_CSV"
PARAMS=("_OV256_120_44" "_OV256_196_72" "_OV256_260_96")
PARAM_NAMES=("Category I' (GF256, 120, 44)" "Category III' (GF256, 196, 72)" "Category V' (GF256, 260, 96)")
PARAM_SHORT=("Ip_alt" "III_alt" "V_alt")
cd code/amd64
for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    SHORT="${PARAM_SHORT[$i]}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: $NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Building..."
    make clean > /dev/null 2>&1
    make PROJ=Ip CFLAGS="-O3 -march=native -D${PARAM}" > /dev/null 2>&1
    if [ ! -f sign_api-test ]; then
        echo "❌ Build failed for $NAME"
        continue
    fi
    echo "✅ Build successful"
    echo ""
    echo "Running 10 tests..."
    for run in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./sign_api-test 2>&1 >/dev/null | tail -1)
        echo "  Run $run: ${T}s"
        echo "$SHORT,$T" >> ../../$RESULTS_CSV
    done
    echo ""
done
cd ../..
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
python3 << 'PY'
from collections import defaultdict
import statistics
results = defaultdict(list)
with open('results/alternative_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        results[param].append(float(time))
param_names = {
    'Ip_alt':  "Category I'  (GF256, 120, 44)",
    'III_alt': "Category III' (GF256, 196, 72)",
    'V_alt':   "Category V'  (GF256, 260, 96)"
}
print("=" * 70)
print("Parameter Set               | Median Time | Min     | Max")
print("=" * 70)
for param in ['Ip_alt', 'III_alt', 'V_alt']:
    if param in results:
        times = results[param]
        median = statistics.median(times)
        min_t = min(times)
        max_t = max(times)
        name = param_names[param]
        print(f"{name:27s} | {median:10.3f}s | {min_t:.3f}s | {max_t:.3f}s")
print("=" * 70)
PY
echo ""
echo "✅ Alternative parameters testing complete!"
echo "📄 Results saved: results/alternative_results.csv"
