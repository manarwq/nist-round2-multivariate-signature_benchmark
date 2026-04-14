#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Detailed Check - What really happened?"
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

# Phase 5
openmp = defaultdict(lambda: defaultdict(list))
with open('results/openmp_correct_results.csv', 'r') as f:
    for line in f:
        param, method, time = line.strip().split(',')
        openmp[param][method].append(float(time))

print("Category I (Ip) - Detailed:")
print("=" * 60)
print(f"Phase 1 baseline: {sorted(baseline['Ip'])}")
print(f"  Median: {statistics.median(baseline['Ip']):.3f}s")
print()
print(f"Phase 5 no_openmp: {sorted(openmp['Ip']['no_openmp'])}")
print(f"  Median: {statistics.median(openmp['Ip']['no_openmp']):.3f}s")
print()
print(f"Phase 5 with openmp: {sorted(openmp['Ip']['openmp'])}")
print(f"  Median: {statistics.median(openmp['Ip']['openmp']):.3f}s")
print()

# Analysis
phase1_med = statistics.median(baseline['Ip'])
no_omp = statistics.median(openmp['Ip']['no_openmp'])
with_omp = statistics.median(openmp['Ip']['openmp'])

print("Analysis:")
print("-" * 60)
print(f"Phase 1 baseline:     {phase1_med:.3f}s")
print(f"Phase 5 no OpenMP:    {no_omp:.3f}s  (vs Phase1: {(no_omp/phase1_med-1)*100:+.1f}%)")
print(f"Phase 5 with OpenMP:  {with_omp:.3f}s  (vs Phase1: {(with_omp/phase1_med-1)*100:+.1f}%)")
print()

if no_omp > phase1_med * 1.05:
    print("⚠️  Phase 5 'no_openmp' is SLOWER than Phase 1!")
    print("   Possible reasons:")
    print("   - System load during Phase 5 test")
    print("   - Code or Makefile differences")
    print("   - Measurement variance")
    print()
    
if with_omp < phase1_med:
    print("✅ OpenMP version IS faster than Phase 1")
    print("   But without directives, this could be:")
    print("   - Compiler optimization differences")
    print("   - Measurement variance")
    print("   - Or real but unexplained effect")
else:
    print("≈  OpenMP similar to Phase 1")

PY

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

