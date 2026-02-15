#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "qr-UOV: Baseline vs OpenMP Comparison"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_FILE="baseline_vs_openmp.csv"
rm -f $RESULTS_FILE

# حفظ Makefile الأصلي
cp Makefile Makefile.backup

# ==========================================
# PART 1: Baseline WITHOUT OpenMP
# ==========================================

echo "PART 1: Testing WITHOUT OpenMP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# تعديل Makefile (نشيل -fopenmp)
sed 's/-fopenmp//g' Makefile.backup > Makefile

for LEVEL in 1 3 5; do
    case $LEVEL in
        1) CONFIG="-DQRUOV_dir=qruov1q127L3v156m54 -DQRUOV_security_strength_category=1 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=156 -DQRUOV_m=54 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        3) CONFIG="-DQRUOV_dir=qruov3q127L3v228m78 -DQRUOV_security_strength_category=3 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=228 -DQRUOV_m=78 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        5) CONFIG="-DQRUOV_dir=qruov5q127L3v306m105 -DQRUOV_security_strength_category=5 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=306 -DQRUOV_m=105 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
    esac
    
    echo "Level $LEVEL (no OpenMP)..."
    echo "$CONFIG" > qruov_config.txt
    
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1
    
    echo "  Running 10 tests..."
    for i in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
        echo "    Run $i: ${T}s"
        echo "$LEVEL,no_openmp,$T" >> $RESULTS_FILE
    done
    echo ""
done

# ==========================================
# PART 2: Baseline WITH OpenMP
# ==========================================

echo "PART 2: Testing WITH OpenMP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# استعادة Makefile الأصلي (مع -fopenmp)
cp Makefile.backup Makefile

for LEVEL in 1 3 5; do
    case $LEVEL in
        1) CONFIG="-DQRUOV_dir=qruov1q127L3v156m54 -DQRUOV_security_strength_category=1 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=156 -DQRUOV_m=54 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        3) CONFIG="-DQRUOV_dir=qruov3q127L3v228m78 -DQRUOV_security_strength_category=3 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=228 -DQRUOV_m=78 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        5) CONFIG="-DQRUOV_dir=qruov5q127L3v306m105 -DQRUOV_security_strength_category=5 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=306 -DQRUOV_m=105 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
    esac
    
    echo "Level $LEVEL (with OpenMP)..."
    echo "$CONFIG" > qruov_config.txt
    
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1
    
    echo "  Running 10 tests..."
    for i in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
        echo "    Run $i: ${T}s"
        echo "$LEVEL,openmp,$T" >> $RESULTS_FILE
    done
    echo ""
done

# ==========================================
# Analysis
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

results = defaultdict(lambda: defaultdict(list))

with open('baseline_vs_openmp.csv', 'r') as f:
    for line in f:
        level, opt, time = line.strip().split(',')
        results[level][opt].append(float(time))

print("=" * 70)
print("Level | No OpenMP | With OpenMP | Speedup")
print("=" * 70)

for level in ['1', '3', '5']:
    no_omp = statistics.median(results[level]['no_openmp'])
    with_omp = statistics.median(results[level]['openmp'])
    speedup = no_omp / with_omp
    improvement = (speedup - 1) * 100
    
    print(f"  {level}   | {no_omp:8.3f}s | {with_omp:8.3f}s   | {speedup:.2f}x ({improvement:+.1f}%)")

print("=" * 70)
PY

echo ""
echo "✅ Testing complete!"
echo "Results: baseline_vs_openmp.csv"

# استعادة Makefile
cp Makefile.backup Makefile
rm Makefile.backup

