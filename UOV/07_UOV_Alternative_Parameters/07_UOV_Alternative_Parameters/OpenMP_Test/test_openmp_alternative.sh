#!/bin/bash
echo "Phase 5: OpenMP Test - Alternative Parameters"
echo ""
RESULTS_CSV="results/openmp_alternative_results.csv"
mkdir -p results
rm -f "$RESULTS_CSV"
cd code/amd64
PARAMS=("_OV256_120_44" "_OV256_196_72" "_OV256_260_96")
PARAM_NAMES=("Category I prime" "Category III prime" "Category V prime")
PARAM_SHORT=("Ip_alt" "III_alt" "V_alt")
for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    SHORT="${PARAM_SHORT[$i]}"
    echo "Testing: $NAME WITH -fopenmp"
    make clean > /dev/null 2>&1
    make PROJ=Ip CFLAGS="-O3 -march=native -fopenmp -D${PARAM}" > /dev/null 2>&1
    if [ ! -f sign_api-test ]; then echo "Build failed"; continue; fi
    echo "Build successful"
    for run in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./sign_api-test 2>&1 >/dev/null | tail -1)
        echo "  Run $run: ${T}s"
        echo "$SHORT,$T" >> ../../$RESULTS_CSV
    done
    echo ""
done
cd ../..
python3 << PY
from collections import defaultdict
import statistics
baseline = defaultdict(list)
with open("../results/alternative_results.csv") as f:
    for line in f:
        param, time = line.strip().split(",")
        baseline[param].append(float(time))
openmp = defaultdict(list)
with open("results/openmp_alternative_results.csv") as f:
    for line in f:
        param, time = line.strip().split(",")
        openmp[param].append(float(time))
param_names = {"Ip_alt": "Category I prime", "III_alt": "Category III prime", "V_alt": "Category V prime"}
print("=" * 70)
print("Parameter Set      | Baseline | OpenMP  | Speedup  | Improvement")
print("=" * 70)
for param in ["Ip_alt", "III_alt", "V_alt"]:
    base = statistics.median(baseline[param])
    omp  = statistics.median(openmp[param])
    speedup = base / omp
    improvement = (speedup - 1) * 100
    status = "OK" if omp < base else "SLOWER"
    print(f"{param_names[param]:18s} | {base:7.3f}s | {omp:6.3f}s | {speedup:6.3f}x | {improvement:+6.1f}% {status}")
print("=" * 70)
PY
