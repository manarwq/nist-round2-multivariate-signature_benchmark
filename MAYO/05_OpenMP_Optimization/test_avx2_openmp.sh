#!/bin/bash

echo "═══════════════════════════════════════════════════════════"
echo "  MAYO: AVX2 vs OpenMP Test"
echo "  Comparing advanced optimization techniques"
echo "═══════════════════════════════════════════════════════════"
echo ""

BASE_DIR=$(pwd)
TEST_DIR="${BASE_DIR}/MAYO_AVX2_OpenMP_$(date +%Y%m%d_%H%M%S)"

mkdir -p ${TEST_DIR}/{results,logs}

echo "📁 Test Directory: ${TEST_DIR}"
echo ""

# ==========================================
# تحقق من دعم AVX2
# ==========================================

echo "🔍 Checking CPU capabilities..."
if grep -q avx2 /proc/cpuinfo; then
    echo "  ✅ AVX2 supported"
    HAS_AVX2=1
else
    echo "  ⚠️ AVX2 NOT supported - will skip AVX2 tests"
    HAS_AVX2=0
fi
echo ""

# ==========================================
# PHASE 1: Baseline (من التجربة السابقة)
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 1: Baseline Reference (O3)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cat > ${TEST_DIR}/results/baseline_reference.txt << 'REF'
MAYO-1: 0.295s
MAYO-2: 0.475s
MAYO-3: 0.935s
MAYO-5: 1.630s
REF

echo "Using previous baseline results:"
cat ${TEST_DIR}/results/baseline_reference.txt
echo ""

# ==========================================
# PHASE 2: AVX2 Optimization
# ==========================================

if [ $HAS_AVX2 -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PHASE 2: AVX2 Optimization"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # التحقق من وجود AVX2 implementation
    if [ -d "Additional_Implementations/AVX2" ]; then
        cd Additional_Implementations/AVX2
        
        for VARIANT in 1 2 3 5; do
            echo "Testing MAYO-${VARIANT} with AVX2..."
            
            rm -rf build-avx2-${VARIANT}
            mkdir build-avx2-${VARIANT}
            cd build-avx2-${VARIANT}
            
            cmake -DCMAKE_BUILD_TYPE=Release \
                  -DCMAKE_C_FLAGS="-O3 -mavx2 -march=native" \
                  -DENABLE_AESNI=ON \
                  -DMAYO=${VARIANT} .. > ${TEST_DIR}/logs/cmake_avx2_${VARIANT}.log 2>&1
            
            make > ${TEST_DIR}/logs/make_avx2_${VARIANT}.log 2>&1
            
            if [ $? -eq 0 ]; then
                echo "  Running 10 tests..."
                for i in {1..10}; do
                    T=$(/usr/bin/time -f "%e" ./apps/PQCgenKAT_sign_mayo_${VARIANT} 2>&1 >/dev/null | tail -1)
                    echo "    Run $i: ${T}s"
                    echo "${VARIANT},avx2,${T}" >> ${TEST_DIR}/results/all_times.csv
                done
            else
                echo "  ❌ Build failed - check logs"
            fi
            
            cd ..
            echo ""
        done
        
        cd ${BASE_DIR}
    else
        echo "  ⚠️ AVX2 implementation not found"
        echo "  Looking for AVX2 code in Optimized_Implementation..."
        
        cd Optimized_Implementation
        
        for VARIANT in 1 2 3 5; do
            echo "Testing MAYO-${VARIANT} with AVX2 flags..."
            
            rm -rf build-avx2-${VARIANT}
            mkdir build-avx2-${VARIANT}
            cd build-avx2-${VARIANT}
            
            cmake -DCMAKE_BUILD_TYPE=Release \
                  -DCMAKE_C_FLAGS="-O3 -mavx2 -march=native -mtune=native" \
                  -DMAYO=${VARIANT} .. > ${TEST_DIR}/logs/cmake_avx2_${VARIANT}.log 2>&1
            
            make > ${TEST_DIR}/logs/make_avx2_${VARIANT}.log 2>&1
            
            if [ $? -eq 0 ]; then
                echo "  Running 10 tests..."
                for i in {1..10}; do
                    T=$(/usr/bin/time -f "%e" ./apps/PQCgenKAT_sign_mayo_${VARIANT} 2>&1 >/dev/null | tail -1)
                    echo "    Run $i: ${T}s"
                    echo "${VARIANT},avx2,${T}" >> ${TEST_DIR}/results/all_times.csv
                done
            else
                echo "  ❌ Build failed"
            fi
            
            cd ..
            echo ""
        done
        
        cd ${BASE_DIR}
    fi
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PHASE 2: AVX2 - SKIPPED (not supported)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

# ==========================================
# PHASE 3: OpenMP Parallelization
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 3: OpenMP Parallelization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd Optimized_Implementation

for VARIANT in 1 2 3 5; do
    echo "Testing MAYO-${VARIANT} with OpenMP..."
    
    rm -rf build-openmp-${VARIANT}
    mkdir build-openmp-${VARIANT}
    cd build-openmp-${VARIANT}
    
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_C_FLAGS="-O3 -fopenmp -march=native" \
          -DMAYO=${VARIANT} .. > ${TEST_DIR}/logs/cmake_openmp_${VARIANT}.log 2>&1
    
    make > ${TEST_DIR}/logs/make_openmp_${VARIANT}.log 2>&1
    
    if [ $? -eq 0 ]; then
        # اختبار مع عدد مختلف من الخيوط
        for THREADS in 2 4; do
            export OMP_NUM_THREADS=$THREADS
            echo "  Testing with $THREADS threads..."
            
            for i in {1..10}; do
                T=$(/usr/bin/time -f "%e" ./apps/PQCgenKAT_sign_mayo_${VARIANT} 2>&1 >/dev/null | tail -1)
                echo "    Run $i: ${T}s"
                echo "${VARIANT},openmp_${THREADS},${T}" >> ${TEST_DIR}/results/all_times.csv
            done
        done
    else
        echo "  ❌ Build failed"
    fi
    
    cd ..
    echo ""
done

cd ${BASE_DIR}

# ==========================================
# PHASE 4: Combined (AVX2 + OpenMP)
# ==========================================

if [ $HAS_AVX2 -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PHASE 4: Combined (AVX2 + OpenMP)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    cd Optimized_Implementation
    
    for VARIANT in 1 2 3 5; do
        echo "Testing MAYO-${VARIANT} with AVX2 + OpenMP..."
        
        rm -rf build-combined-${VARIANT}
        mkdir build-combined-${VARIANT}
        cd build-combined-${VARIANT}
        
        cmake -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_C_FLAGS="-O3 -mavx2 -fopenmp -march=native -mtune=native" \
              -DMAYO=${VARIANT} .. > ${TEST_DIR}/logs/cmake_combined_${VARIANT}.log 2>&1
        
        make > ${TEST_DIR}/logs/make_combined_${VARIANT}.log 2>&1
        
        if [ $? -eq 0 ]; then
            export OMP_NUM_THREADS=4
            echo "  Running 10 tests (4 threads)..."
            
            for i in {1..10}; do
                T=$(/usr/bin/time -f "%e" ./apps/PQCgenKAT_sign_mayo_${VARIANT} 2>&1 >/dev/null | tail -1)
                echo "    Run $i: ${T}s"
                echo "${VARIANT},avx2_openmp,${T}" >> ${TEST_DIR}/results/all_times.csv
            done
        else
            echo "  ❌ Build failed"
        fi
        
        cd ..
        echo ""
    done
    
    cd ${BASE_DIR}
fi

# ==========================================
# ANALYSIS
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ANALYSIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PY'
from collections import defaultdict
import statistics

# Baseline reference
baseline = {
    '1': 0.295,
    '2': 0.475,
    '3': 0.935,
    '5': 1.630
}

results = defaultdict(lambda: defaultdict(list))

try:
    with open('MAYO_AVX2_OpenMP_*/results/all_times.csv', 'r') as f:
        pass
except:
    import glob
    files = glob.glob('MAYO_AVX2_OpenMP_*/results/all_times.csv')
    if files:
        with open(files[0], 'r') as f:
            for line in f:
                parts = line.strip().split(',')
                if len(parts) == 3:
                    variant, opt, time = parts[0], parts[1], float(parts[2])
                    results[variant][opt].append(time)

print("=" * 100)
print(" " * 30 + "MAYO: AVX2 vs OpenMP Results")
print("=" * 100)
print()
print("Variant | Baseline  | AVX2      | OpenMP(2) | OpenMP(4) | AVX2+OMP  | Best      | Speedup")
print("=" * 100)

for v in ['1', '2', '3', '5']:
    b = baseline[v]
    
    line = f"MAYO-{v}  | {b:8.3f}s"
    
    best_time = b
    best_method = "Baseline"
    
    # AVX2
    if 'avx2' in results[v] and results[v]['avx2']:
        avx2 = statistics.median(results[v]['avx2'])
        line += f" | {avx2:8.3f}s"
        if avx2 < best_time:
            best_time = avx2
            best_method = "AVX2"
    else:
        line += " |     N/A  "
    
    # OpenMP 2 threads
    if 'openmp_2' in results[v] and results[v]['openmp_2']:
        omp2 = statistics.median(results[v]['openmp_2'])
        line += f" | {omp2:8.3f}s"
        if omp2 < best_time:
            best_time = omp2
            best_method = "OpenMP(2)"
    else:
        line += " |     N/A  "
    
    # OpenMP 4 threads
    if 'openmp_4' in results[v] and results[v]['openmp_4']:
        omp4 = statistics.median(results[v]['openmp_4'])
        line += f" | {omp4:8.3f}s"
        if omp4 < best_time:
            best_time = omp4
            best_method = "OpenMP(4)"
    else:
        line += " |     N/A  "
    
    # Combined
    if 'avx2_openmp' in results[v] and results[v]['avx2_openmp']:
        comb = statistics.median(results[v]['avx2_openmp'])
        line += f" | {comb:8.3f}s"
        if comb < best_time:
            best_time = comb
            best_method = "AVX2+OMP"
    else:
        line += " |     N/A  "
    
    speedup = b / best_time
    improvement = (speedup - 1) * 100
    
    line += f" | {best_method:9s} | {speedup:.2f}x ({improvement:+.1f}%)"
    print(line)

print("=" * 100)
PY

echo ""
echo "✅ Testing Complete!"
echo "Results saved in: ${TEST_DIR}/"

