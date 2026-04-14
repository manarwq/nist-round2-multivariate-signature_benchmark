#!/bin/bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 4: LUT Test - Alternative Parameters"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_CSV="results/lut_alternative_results.csv"
mkdir -p results
rm -f "$RESULTS_CSV"

cd code/amd64

PARAMS=("_OV256_120_44" "_OV256_196_72" "_OV256_260_96")
PARAM_NAMES=("Category I' (GF256, 120, 44)" "Category III' (GF256, 196, 72)" "Category V' (GF256, 260, 96)")
PARAM_SHORT=("Ip_alt" "III_alt" "V_alt")

for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    SHORT="${PARAM_SHORT[$i]}"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$NAME - WITH LUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    make clean > /dev/null 2>&1
    make PROJ=Ip CFLAGS="-O3 -march=native -D${PARAM} -DUSE_GF16_LUT" > /dev/null 2>&1

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

baseline = defaultdict(list)
with open('../results/alternative_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        baseline[param].append(float(time))

lut_results = defaultdict(list)
with open('results/lut_alternative_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        lut_results[param].append(float(time))

param_names = {
    'Ip_alt':  "Category I'  (GF256, 120, 44)",
    'III_alt': "Category III' (GF256, 196, 72)",
    'V_alt':   "Category V'  (GF256, 260, 96)"
}

print("=" * 75)
print("Parameter Set          | Baseline | With LUT | Speedup  | Improvement")
print("=" * 75)

for param in ['Ip_alt', 'III_alt', 'V_alt']:
    base = statistics.median(baseline[param])
    lut  = statistics.median(lut_results[param])
    speedup = base / lut
    improvement = (speedup - 1) * 100
    name = param_names[param]
    status = "✅" if lut < base else "❌"
    print(f"{name:22s} | {base:7.3f}s | {lut:7.3f}s | {speedup:6.3f}x | {improvement:+6.1f}% {status}")

print("=" * 75)
PY

echo ""
echo "✅ LUT alternative testing complete!"
echo "📄 Results: LUT_Optimization/results/lut_alternative_results.csv"
