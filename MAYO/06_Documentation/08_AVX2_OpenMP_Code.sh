

```bash
#!/bin/bash

# ================================================
# AVX2 and OpenMP Benchmark Script (MAYO
# Goal: evaluate advanced optimization techniques:
#       - AVX2
#       - OpenMP (2 and 4 threads)
#       - AVX2 + OpenMP (combined)
# ================================================

echo "=== MAYO: AVX2 vs OpenMP Test ==="
echo ""

BASE_DIR="~/Downloads/new/MAYO"
cd "$BASE_DIR" || exit 1

# Check AVX2 support
if grep -q avx2 /proc/cpuinfo; then
    echo " AVX2 supported"
    HAS_AVX2=1
else
    echo " AVX2 NOT supported"
    HAS_AVX2=0
fi

# ================================================
# Test AVX2
# ================================================

if [ "$HAS_AVX2" -eq 1 ]; then
    echo ""
    echo "=== Testing AVX2 ==="

    cd Optimized_Implementation || exit 1

    for VARIANT in 1 2 3 5; do
        echo "MAYO-${VARIANT} with AVX2..."

        rm -rf "build-avx2-${VARIANT}"
        mkdir "build-avx2-${VARIANT}"
        cd "build-avx2-${VARIANT}" || exit 1

        # Build with AVX2 enabled
        cmake -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_C_FLAGS="-O3 -mavx2 -march=native -mtune=native" \
              -DMAYO="${VARIANT}" .. > /dev/null 2>&1

        make > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            for i in {1..10}; do
                T=$(/usr/bin/time -f "%e" \
                    ./apps/PQCgenKAT_sign_mayo_"${VARIANT}" 2>&1 >/dev/null | tail -1)
                echo "  Run $i: ${T}s"
            done
        else
            echo "❌ Build failed for MAYO-${VARIANT} (AVX2)"
        fi

        cd ..
    done
fi

# ================================================
# Test OpenMP
# ================================================

echo ""
echo "=== Testing OpenMP ==="

cd Optimized_Implementation || exit 1

for VARIANT in 1 2 3 5; do
    echo "MAYO-${VARIANT} with OpenMP..."

    rm -rf "build-openmp-${VARIANT}"
    mkdir "build-openmp-${VARIANT}"
    cd "build-openmp-${VARIANT}" || exit 1

    # Build with OpenMP enabled
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_C_FLAGS="-O3 -fopenmp -march=native" \
          -DMAYO="${VARIANT}" .. > /dev/null 2>&1

    make > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        # Run with 2 and 4 threads
        for THREADS in 2 4; do
            export OMP_NUM_THREADS="$THREADS"
            echo "  With $THREADS threads:"

            for i in {1..10}; do
                T=$(/usr/bin/time -f "%e" \
                    ./apps/PQCgenKAT_sign_mayo_"${VARIANT}" 2>&1 >/dev/null | tail -1)
                echo "    Run $i: ${T}s"
            done
        done
    else
        echo "❌ Build failed for MAYO-${VARIANT} (OpenMP)"
    fi

    cd ..
done

# ================================================
# Test AVX2 + OpenMP (Combined)
# ================================================

if [ "$HAS_AVX2" -eq 1 ]; then
    echo ""
    echo "=== Testing AVX2 + OpenMP ==="

    cd Optimized_Implementation || exit 1

    for VARIANT in 1 2 3 5; do
        echo "MAYO-${VARIANT} with AVX2 + OpenMP..."

        rm -rf "build-combined-${VARIANT}"
        mkdir "build-combined-${VARIANT}"
        cd "build-combined-${VARIANT}" || exit 1

        # Build with both AVX2 and OpenMP enabled
        cmake -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_C_FLAGS="-O3 -mavx2 -fopenmp -march=native" \
              -DMAYO="${VARIANT}" .. > /dev/null 2>&1

        make > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            # Use a fixed thread count for the combined test
            export OMP_NUM_THREADS=4

            for i in {1..10}; do
                T=$(/usr/bin/time -f "%e" \
                    ./apps/PQCgenKAT_sign_mayo_"${VARIANT}" 2>&1 >/dev/null | tail -1)
                echo "  Run $i: ${T}s"
            done
        else
            echo "Build failed for MAYO-${VARIANT} (AVX2 + OpenMP)"
        fi

        cd ..
    done
fi

echo ""
echo " Testing Complete"
```


