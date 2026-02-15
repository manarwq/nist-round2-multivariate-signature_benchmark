

```bash
#!/bin/bash

# ================================================
# MAYO LUT Optimization Test Script
# Goal: benchmark performance before and after LUT optimization
# ================================================

echo "=== MAYO LUT Optimization Test ==="
echo ""

MAYO_DIR="~/Downloads/new/MAYO/Optimized_Implementation"
cd "$MAYO_DIR" || exit 1

# ================================================
# PHASE 1: Baseline Testing
# ================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 1: Baseline Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Backup the original file
cp src/simple_arithmetic.h src/simple_arithmetic.h.backup

# Build baseline
rm -rf build-baseline
mkdir build-baseline
cd build-baseline || exit 1

for VARIANT in 1 2 3 5; do
    echo "Testing MAYO-${VARIANT} (Baseline)..."

    cmake -DMAYO="${VARIANT}" .. > /dev/null 2>&1
    make > /dev/null 2>&1

    echo "Running 10 tests:"
    for i in {1..10}; do
        TIME=$(/usr/bin/time -f "%e" \
            ./apps/PQCgenKAT_sign_mayo_"${VARIANT}" 2>&1 >/dev/null | tail -1)
        echo "  Run $i: ${TIME}s"
    done

    echo ""
    sleep 5
done

cd ..

# ================================================
# PHASE 2: Apply LUT Optimization
# ================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 2: Applying LUT Optimization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# The optimized code is stored in a separate file.
# Replace src/simple_arithmetic.h with the contents of 05_Optimized_Code.h
echo "Apply the optimized version of simple_arithmetic.h now."
echo "Source: 05_Optimized_Code.h"
echo ""

# ================================================
# PHASE 3: Optimized Testing
# ================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 3: Optimized Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Build optimized
rm -rf build-optimized
mkdir build-optimized
cd build-optimized || exit 1

for VARIANT in 1 2 3 5; do
    echo "Testing MAYO-${VARIANT} (Optimized)..."

    cmake -DMAYO="${VARIANT}" .. > /dev/null 2>&1
    make > /dev/null 2>&1

    echo "Running 10 tests:"
    for i in {1..10}; do
        TIME=$(/usr/bin/time -f "%e" \
            ./apps/PQCgenKAT_sign_mayo_"${VARIANT}" 2>&1 >/dev/null | tail -1)
        echo "  Run $i: ${TIME}s"
    done

    echo ""
    sleep 5
done

cd ..

echo "Testing Complete"
```

