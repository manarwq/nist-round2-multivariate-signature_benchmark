#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 4 (LUT) - Final Results vs Phase 1 Baseline"
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

# Load LUT results (vector_lut only)
lut = defaultdict(list)
with open('results/vector_lut_correct_results.csv', 'r') as f:
    for line in f:
        param, method, time = line.strip().split(',')
        if method == 'vector_lut':  # نأخذ LUT فقط
            lut[param].append(float(time))

param_names = {
    'Ip': 'Category I (GF16)',
    'III': 'Category III (GF256)',
    'V': 'Category V (GF256)'
}

print("=" * 75)
print("Parameter Set         | Phase 1 Baseline | LUT Result | Improvement")
print("=" * 75)

for param in ['Ip', 'III', 'V']:
    base = statistics.median(baseline[param])
    lut_time = statistics.median(lut[param])
    
    speedup = base / lut_time
    improvement = (speedup - 1) * 100
    
    if improvement > 5:
        status = "✅"
    elif improvement < -5:
        status = "❌"
    else:
        status = "≈"
    
    name = param_names[param]
    print(f"{name:21s} | {base:15.3f}s | {lut_time:9.3f}s | "
          f"{speedup:.2f}x ({improvement:+6.1f}%) {status}")

print("=" * 75)
PY

echo ""
echo "✅ Phase 4 complete!"

