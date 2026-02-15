#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "qr-UOV Final Test - All 3 Levels"
echo "No OpenMP vs OpenMP (both with AVX2 via -march=native)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS="qruov_final_results.csv"
rm -f $RESULTS

# Backup
cp Makefile Makefile.backup 2>/dev/null

# ==========================================
# Part 1: No OpenMP (but AVX2 enabled)
# ==========================================

echo "Part 1: Baseline (AVX2 via -march=native, no OpenMP)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

sed -i 's/ -fopenmp//g' Makefile

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
    
    for i in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
        echo "  Run $i: ${T}s"
        echo "$LEVEL,baseline,$T" >> $RESULTS
    done
    echo ""
done

# ==========================================
# Part 2: With OpenMP (and AVX2)
# ==========================================

echo "Part 2: OpenMP (with AVX2 via -march=native)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

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
    
    for i in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
        echo "  Run $i: ${T}s"
        echo "$LEVEL,openmp,$T" >> $RESULTS
    done
    echo ""
done

# ==========================================
# Analysis
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Final Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

results = defaultdict(lambda: defaultdict(list))

with open('qruov_final_results.csv', 'r') as f:
    for line in f:
        level, opt, time = line.strip().split(',')
        results[level][opt].append(float(time))

print("=" * 70)
print("Level | Baseline  | OpenMP    | Speedup")
print("=" * 70)

for level in ['1', '3', '5']:
    base = statistics.median(results[level]['baseline'])
    omp = statistics.median(results[level]['openmp'])
    speedup = base / omp
    improvement = (speedup - 1) * 100
    
    print(f"  {level}   | {base:8.3f}s | {omp:8.3f}s | {speedup:.2f}x ({improvement:+.1f}%)")

print("=" * 70)
print()
print("Note: AVX2 is enabled in both via -march=native")
PY

cp Makefile.backup Makefile
rm Makefile.backup

echo ""
echo "✅ qr-UOV testing complete!"
echo "Results: qruov_final_results.csv"

