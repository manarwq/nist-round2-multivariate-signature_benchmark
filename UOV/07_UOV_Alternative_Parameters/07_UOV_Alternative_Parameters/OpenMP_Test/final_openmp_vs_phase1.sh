#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 5: OpenMP vs Phase 1 Baseline (Final)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

# Phase 1
baseline = defaultdict(list)
with open('../01_Baseline/results/baseline_results.csv', 'r') as f:
    for line in f:
        param, time = line.strip().split(',')
        baseline[param].append(float(time))

# Phase 5 OpenMP only
openmp = defaultdict(list)
with open('results/openmp_correct_results.csv', 'r') as f:
    for line in f:
        param, method, time = line.strip().split(',')
        if method == 'openmp':  
            openmp[param].append(float(time))

param_names = {
    'Ip': 'Category I (GF16)',
    'III': 'Category III (GF256)',
    'V': 'Category V (GF256)'
}

print("=" * 75)
print("Parameter Set         | Phase 1 Baseline | OpenMP  | Improvement")
print("=" * 75)

for param in ['Ip', 'III', 'V']:
    phase1 = statistics.median(baseline[param])
    omp = statistics.median(openmp[param])
    
    speedup = phase1 / omp
    improvement = (speedup - 1) * 100
    
    if improvement > 5:
        status = "✅"
    elif improvement < -5:
        status = "❌"
    else:
        status = "≈"
    
    name = param_names[param]
    print(f"{name:21s} | {phase1:15.3f}s | {omp:6.3f}s | "
          f"{speedup:.2f}x ({improvement:+6.1f}%) {status}")

print("=" * 75)
print()
print("Note: Code has no OpenMP pragma directives.")
print("      Effect is likely compiler optimization difference or measurement noise.")

PY

echo ""
echo " Phase 5 complete!"

