#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "qr-UOV Baseline Test - All Levels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_FILE="baseline_results.txt"
rm -f $RESULTS_FILE

# ==========================================
# Level 1
# ==========================================

echo "Testing qr-UOV Level 1..."
echo "-DQRUOV_dir=qruov1q127L3v156m54 -DQRUOV_security_strength_category=1 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=156 -DQRUOV_m=54 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" > qruov_config.txt

make clean > /dev/null 2>&1
make > /dev/null 2>&1

echo "  Running 10 tests..."
for i in {1..10}; do
    T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
    echo "    Run $i: ${T}s"
    echo "1,baseline,$T" >> $RESULTS_FILE
done
echo ""

# ==========================================
# Level 3
# ==========================================

echo "Testing qr-UOV Level 3..."
echo "-DQRUOV_dir=qruov3q127L3v228m78 -DQRUOV_security_strength_category=3 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=228 -DQRUOV_m=78 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" > qruov_config.txt

make clean > /dev/null 2>&1
make > /dev/null 2>&1

echo "  Running 10 tests..."
for i in {1..10}; do
    T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
    echo "    Run $i: ${T}s"
    echo "3,baseline,$T" >> $RESULTS_FILE
done
echo ""

# ==========================================
# Level 5
# ==========================================

echo "Testing qr-UOV Level 5..."
echo "-DQRUOV_dir=qruov5q127L3v306m105 -DQRUOV_security_strength_category=5 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=306 -DQRUOV_m=105 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" > qruov_config.txt

make clean > /dev/null 2>&1
make > /dev/null 2>&1

echo "  Running 10 tests..."
for i in {1..10}; do
    T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
    echo "    Run $i: ${T}s"
    echo "5,baseline,$T" >> $RESULTS_FILE
done
echo ""

# ==========================================
# Summary
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

results = defaultdict(list)

with open('baseline_results.txt', 'r') as f:
    for line in f:
        level, opt, time = line.strip().split(',')
        results[level].append(float(time))

print("Level | Min      | Median   | Max      | Avg")
print("=" * 55)
for level in ['1', '3', '5']:
    times = results[level]
    print(f"  {level}   | {min(times):.3f}s  | {statistics.median(times):.3f}s  | {max(times):.3f}s  | {statistics.mean(times):.3f}s")

print("")
PY

echo "✅ Baseline testing complete!"
echo "Results saved in: baseline_results.txt"

