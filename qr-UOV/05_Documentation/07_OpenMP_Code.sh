#!/bin/bash

# ============================================================================
# qr-UOV OpenMP Test
# Compares performance with and without OpenMP parallelization
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "qr-UOV OpenMP Test - All Levels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_FILE="openmp_results.csv"
rm -f $RESULTS_FILE

# Backup Makefile
cp Makefile Makefile.backup

for LEVEL in 1 3 5; do
    case $LEVEL in
        1) CONFIG="-DQRUOV_dir=qruov1q127L3v156m54 -DQRUOV_security_strength_category=1 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=156 -DQRUOV_m=54 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        3) CONFIG="-DQRUOV_dir=qruov3q127L3v228m78 -DQRUOV_security_strength_category=3 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=228 -DQRUOV_m=78 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        5) CONFIG="-DQRUOV_dir=qruov5q127L3v306m105 -DQRUOV_security_strength_category=5 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=306 -DQRUOV_m=105 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
    esac
    
    # Without OpenMP
    echo "Level $LEVEL - WITHOUT OpenMP..."
    echo "$CONFIG" > qruov_config.txt
    
    sed -i 's/ -fopenmp//g' Makefile
    
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1
    
    for i in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
        echo "  Run $i: ${T}s"
        echo "$LEVEL,no_openmp,$T" >> $RESULTS_FILE
    done
    echo ""
    
    # With OpenMP
    echo "Level $LEVEL - WITH OpenMP..."
    
    cp Makefile.backup Makefile
    
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1
    
    for i in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
        echo "  Run $i: ${T}s"
        echo "$LEVEL,openmp,$T" >> $RESULTS_FILE
    done
    echo ""
done

cp Makefile.backup Makefile
rm Makefile.backup

python3 << 'PY'
from collections import defaultdict
import statistics

results = defaultdict(lambda: defaultdict(list))

with open('openmp_results.csv', 'r') as f:
    for line in f:
        level, opt, time = line.strip().split(',')
        results[level][opt].append(float(time))

print("=" * 70)
print("Level | No OpenMP | With OpenMP | Change")
print("=" * 70)

for level in ['1', '3', '5']:
    no_omp = statistics.median(results[level]['no_openmp'])
    with_omp = statistics.median(results[level]['openmp'])
    
    change = (no_omp / with_omp - 1) * 100
    print(f"  {level}   | {no_omp:.3f}s   | {with_omp:.3f}s     | {change:+.1f}%")

print("=" * 70)
PY

echo " OpenMP testing complete!"
