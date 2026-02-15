
```bash
#!/bin/bash

# ================================================
# MAYO Profiling Script
# Goal: Profile all MAYO parameter sets (1,2,3,5)
# ================================================

echo "=== MAYO Profiling Script ==="
echo ""

# Configuration
MAYO_DIR="~/Downloads/new/MAYO/Optimized_Implementation"
cd "$MAYO_DIR" || exit 1

# ================================================
# Profile each variant
# ================================================

for VARIANT in 1 2 3 5; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Profiling MAYO-${VARIANT}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Create a fresh build directory
    BUILD_DIR="build-profile-${VARIANT}"
    rm -rf "$BUILD_DIR"
    mkdir "$BUILD_DIR"
    cd "$BUILD_DIR" || exit 1

    # Build with profiling enabled:
    # -pg        : enable gprof profiling
    # -O2        : moderate optimization
    # -fno-inline: disable inlining for clearer profiling output
    cmake -DCMAKE_C_FLAGS="-pg -O2 -fno-inline" \
          -DMAYO="${VARIANT}" .. > /dev/null 2>&1

    make > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "❌ Build failed for MAYO-${VARIANT}"
        cd ..
        continue
    fi

    echo "✅ Build successful"

    # Run the KAT signing executable to generate profiling data (gmon.out)
    ./apps/PQCgenKAT_sign_mayo_"${VARIANT}" > /dev/null 2>&1

    echo ""
    echo "Top 20 Functions by Time:"
    echo "─────────────────────────────────────────"

    # Print the top functions from gprof output
    gprof apps/PQCgenKAT_sign_mayo_"${VARIANT}" gmon.out 2>/dev/null | \
        grep -A 25 "^  %" | head -30

    echo ""

    # Return to the base directory
    cd ..

    sleep 2
done

echo ""
echo "Profiling Complete"
```


