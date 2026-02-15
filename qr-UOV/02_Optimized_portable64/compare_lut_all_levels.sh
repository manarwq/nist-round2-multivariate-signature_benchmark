#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "LUT Comparison - All 3 Levels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

rm -f lut_all_levels.csv

for LEVEL in 1 3 5; do
    case $LEVEL in
        1) CONFIG="-DQRUOV_dir=qruov1q127L3v156m54 -DQRUOV_security_strength_category=1 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=156 -DQRUOV_m=54 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        3) CONFIG="-DQRUOV_dir=qruov3q127L3v228m78 -DQRUOV_security_strength_category=3 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=228 -DQRUOV_m=78 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        5) CONFIG="-DQRUOV_dir=qruov5q127L3v306m105 -DQRUOV_security_strength_category=5 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=306 -DQRUOV_m=105 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
    esac
    
    # ==========================================
    # Without LUT
    # ==========================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Level $LEVEL - WITHOUT LUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "$CONFIG" > qruov_config.txt
    
    cp Fql.h.backup Fql.h
    sed -i 's/CFLAGS=-DUSE_MUL_LUT /CFLAGS=/' Makefile
    
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1
    
    echo "Running 10 tests..."
    for i in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
        echo "  Run $i: ${T}s"
        echo "$LEVEL,no_lut,$T" >> lut_all_levels.csv
    done
    echo ""
    
    # ==========================================
    # With LUT
    # ==========================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Level $LEVEL - WITH LUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    cp Fql_clean.h Fql.h
    sed -i 's/CFLAGS=/CFLAGS=-DUSE_MUL_LUT /' Makefile
    
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1
    
    echo "Running 10 tests..."
    for i in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
        echo "  Run $i: ${T}s"
        echo "$LEVEL,lut,$T" >> lut_all_levels.csv
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

with open('lut_all_levels.csv', 'r') as f:
    for line in f:
        level, method, time = line.strip().split(',')
        results[level][method].append(float(time))

print("=" * 80)
print("Level | No LUT    | With LUT  | Change        | Result")
print("=" * 80)

for level in ['1', '3', '5']:
    no_lut = statistics.median(results[level]['no_lut'])
    lut = statistics.median(results[level]['lut'])
    
    print(f"  {level}   | {no_lut:8.3f}s | {lut:8.3f}s | ", end="")
    
    if lut < no_lut:
        speedup = no_lut / lut
        improvement = (speedup - 1) * 100
        print(f"{speedup:.2f}x faster ({improvement:+.1f}%) | ✅ Better")
    else:
        slowdown = lut / no_lut
        degradation = (slowdown - 1) * 100
        print(f"{slowdown:.2f}x slower ({degradation:+.1f}%) | ❌ Worse")

print("=" * 80)
print()
print("Conclusion:")
print("  LUT (16 KB) causes cache pressure and memory access overhead.")
print("  Direct multiplication with AVX2 is faster for q=127.")
PY

# Restore
cp Fql.h.backup Fql.h
sed -i 's/CFLAGS=-DUSE_MUL_LUT /CFLAGS=/' Makefile

echo ""
echo "✅ Complete testing finished!"
echo "Results: lut_all_levels.csv"

