#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 5 (OpenMP) - Detailed Analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

# Load Phase 1 baseline
baseline = defaultdict(list)
with open('../01_Baseline/results/baseline_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        baseline[param].append(float(time))

# Load OpenMP results (CORRECT file)
openmp = defaultdict(lambda: defaultdict(list))
with open('results/openmp_correct_results.csv', 'r') as f:
    for line in f:
        param, method, time = line.strip().split(',')
        openmp[param][method].append(float(time))

param_names = {
    'Ip': 'Category I (GF16)',
    'III': 'Category III (GF256)',
    'V': 'Category V (GF256)'
}

print("=" * 90)
print("Parameter Set         | Phase1   | No OpenMP | With OpenMP | Change")
print("=" * 90)

for param in ['Ip', 'III', 'V']:
    phase1 = statistics.median(baseline[param])
    no_omp = statistics.median(openmp[param]['no_openmp'])
    with_omp = statistics.median(openmp[param]['openmp'])
    
    # Compare OpenMP vs Phase 1
    speedup = phase1 / with_omp
    improvement = (speedup - 1) * 100
    
    if improvement > 5:
        status = "✅"
    elif improvement < -5:
        status = "❌"
    else:
        status = "≈"
    
    name = param_names[param]
    print(f"{name:21s} | {phase1:7.3f}s | {no_omp:8.3f}s | {with_omp:10.3f}s | "
          f"{speedup:.2f}x ({improvement:+5.1f}%) {status}")

print("=" * 90)
print()

# Note
print("Note: Code has no OpenMP directives.")
print("      OpenMP flag effect = minimal overhead only")

PY

echo ""
echo "✅ Analysis complete!"

