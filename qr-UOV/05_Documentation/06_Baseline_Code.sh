#!/bin/bash

# ============================================================================
# qr-UOV Baseline Test
# Tests performance with default optimization flags
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "qr-UOV Baseline Test - All Levels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_FILE="baseline_results.csv"
rm -f $RESULTS_FILE

# Test all 3 levels
for LEVEL in 1 3 5; do
    case $LEVEL in
        1) CONFIG="-DQRUOV_dir=qruov1q127L3v156m54 -DQRUOV_security_strength_category=1 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=156 -DQRUOV_m=54 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        3) CONFIG="-DQRUOV_dir=qruov3q127L3v228m78 -DQRUOV_security_strength_category=3 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=228 -DQRUOV_m=78 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        5) CONFIG="-DQRUOV_dir=qruov5q127L3v306m105 -DQRUOV_security_strength_category=5 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=306 -DQRUOV_m=105 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
    esac
    
    echo "Testing Level ${LEVEL}..."
    echo "$CONFIG" > qruov_config.txt
    
    # Build
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1
    
    # Run 10 tests
    echo "  Running 10 tests..."
    for i in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
        echo "    Run $i: ${T}s"
        echo "$LEVEL,baseline,$T" >> $RESULTS_FILE
    done
    echo ""
done

# Analysis
python3 << 'PY'
from collections import defaultdict
import statistics

results = defaultdict(list)

with open('baseline_results.csv', 'r') as f:
    for line in f:
        level, method, time = line.strip().split(',')
        results[level].append(float(time))

print("=" * 60)
print("Level | Median Time")
print("=" * 60)
for level in ['1', '3', '5']:
    median = statistics.median(results[level])
    print(f"  {level}   | {median:.3f}s")
print("=" * 60)
PY

echo ""
echo "Baseline testing complete!"
echo "Results: baseline_results.csv"
