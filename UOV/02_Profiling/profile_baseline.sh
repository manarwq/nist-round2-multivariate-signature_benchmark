#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 2: UOV Profiling"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check valgrind
if ! command -v valgrind &> /dev/null; then
    echo "❌ valgrind not installed!"
    echo "Install: sudo apt install valgrind"
    exit 1
fi

# Copy code
cp -r ../01_Baseline/code ./
cd code/amd64

PARAMS=("Ip" "III" "V")
PARAM_NAMES=("Category I" "Category III" "Category V")

for i in "${!PARAMS[@]}"; do
    PARAM="${PARAMS[$i]}"
    NAME="${PARAM_NAMES[$i]}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Profiling: $NAME ($PARAM)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Build
    echo "Building..."
    make clean > /dev/null 2>&1
    make PROJ=$PARAM > /dev/null 2>&1
    
    if [ ! -f sign_api-test ]; then
        echo "❌ Build failed"
        continue
    fi
    
    echo "✅ Build successful"
    echo ""
    
    # Profile
    echo "🔬 Running callgrind (this will be slow)..."
    valgrind --tool=callgrind \
             --callgrind-out-file=../../results/callgrind_${PARAM}.out \
             ./sign_api-test > /dev/null 2>&1
    
    echo "✅ Profiling complete"
    echo ""
    
    # Analyze
    echo "📊 Top 30 functions:"
    callgrind_annotate ../../results/callgrind_${PARAM}.out 2>/dev/null | \
        grep -v "^--" | \
        grep -v "^==" | \
        head -50 | \
        tee ../../results/profile_${PARAM}.txt
    
    echo ""
done

cd ../..

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Profiling complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📄 Files created:"
ls -lh results/

