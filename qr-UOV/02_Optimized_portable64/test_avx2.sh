#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "qr-UOV: AVX2 Optimization Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESULTS_FILE="avx2_results.csv"
rm -f $RESULTS_FILE

# حفظ Makefile الأصلي
cp Makefile Makefile.backup 2>/dev/null || cp Makefile Makefile.backup

# تعديل Makefile لإضافة AVX2
cat > Makefile << 'MAKE'
PLATFORM=portable64
CC=gcc
CFLAGS=-march=native -mtune=native -O3 -mavx2 -fomit-frame-pointer -fwrapv -fPIC -fPIE -fopenmp -Wno-deprecated-declarations -Wno-unused-result
LDFLAGS=-lcrypto -Wl,-Bstatic -lcrypto -Wl,-Bdynamic -lm
OBJS=Fql.o PQCgenKAT_sign.o qruov.o rng.o sign.o matrix.o mgf.o

.SUFFIXES:
.SUFFIXES: .c .o

.PHONY: all clean

all: qruov_config.h api.h PQCgenKAT_sign

PQCgenKAT_sign: ${OBJS}
	${CC} ${OBJS} ${CFLAGS} ${LDFLAGS} -o $@

qruov_config.h: qruov_config_h_gen.c
	${CC} @qruov_config.txt -DQRUOV_PLATFORM=${PLATFORM} -DQRUOV_CONFIG_H_GEN ${CFLAGS} ${LDFLAGS} qruov_config_h_gen.c
	./a.out > qruov_config.h
	rm a.out

api.h: api_h_gen.c
	${CC} -DAPI_H_GEN ${CFLAGS} ${LDFLAGS} api_h_gen.c
	./a.out > api.h
	rm a.out

%.o: %.c
	${CC} ${CFLAGS} -c $

clean:
	rm -f PQCgenKAT_sign *.o
MAKE

echo "Testing with AVX2 + OpenMP..."
echo ""

for LEVEL in 1 3 5; do
    case $LEVEL in
        1) CONFIG="-DQRUOV_dir=qruov1q127L3v156m54 -DQRUOV_security_strength_category=1 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=156 -DQRUOV_m=54 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        3) CONFIG="-DQRUOV_dir=qruov3q127L3v228m78 -DQRUOV_security_strength_category=3 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=228 -DQRUOV_m=78 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        5) CONFIG="-DQRUOV_dir=qruov5q127L3v306m105 -DQRUOV_security_strength_category=5 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=306 -DQRUOV_m=105 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
    esac
    
    echo "Level $LEVEL with AVX2..."
    echo "$CONFIG" > qruov_config.txt
    
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1
    
    echo "  Running 10 tests..."
    for i in {1..10}; do
        T=$(/usr/bin/time -f "%e" ./PQCgenKAT_sign 2>&1 >/dev/null | tail -1)
        echo "    Run $i: ${T}s"
        echo "$LEVEL,avx2,$T" >> $RESULTS_FILE
    done
    echo ""
done

# استعادة Makefile
cp Makefile.backup Makefile
rm Makefile.backup

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Comparison with previous results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

# قراءة النتائج السابقة
prev_results = defaultdict(lambda: defaultdict(list))
try:
    with open('baseline_vs_openmp.csv', 'r') as f:
        for line in f:
            level, opt, time = line.strip().split(',')
            prev_results[level][opt].append(float(time))
except:
    pass

# قراءة نتائج AVX2
avx2_results = defaultdict(list)
with open('avx2_results.csv', 'r') as f:
    for line in f:
        level, opt, time = line.strip().split(',')
        avx2_results[level].append(float(time))

print("=" * 80)
print("Level | No OpenMP | OpenMP    | AVX2+OMP  | Best      | vs Baseline")
print("=" * 80)

for level in ['1', '3', '5']:
    no_omp = statistics.median(prev_results[level]['no_openmp']) if prev_results[level]['no_openmp'] else 0
    with_omp = statistics.median(prev_results[level]['openmp']) if prev_results[level]['openmp'] else 0
    avx2 = statistics.median(avx2_results[level]) if avx2_results[level] else 0
    
    if no_omp > 0 and avx2 > 0:
        speedup = no_omp / avx2
        improvement = (speedup - 1) * 100
        
        best = min(no_omp, with_omp, avx2)
        best_name = "No OpenMP" if best == no_omp else ("OpenMP" if best == with_omp else "AVX2+OMP")
        
        print(f"  {level}   | {no_omp:8.3f}s | {with_omp:8.3f}s | {avx2:8.3f}s | {best_name:9s} | {speedup:.2f}x ({improvement:+.1f}%)")

print("=" * 80)
PY

echo ""
echo "✅ AVX2 testing complete!"
echo "Results: avx2_results.csv"

