#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "qr-UOV Profiling with Callgrind"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# verify valgrind
if ! command -v valgrind &> /dev/null; then
    echo "❌ valgrind not installed!"
    echo "Install: sudo apt install valgrind"
    exit 1
fi

# Original Makefile 
cp Makefile.backup Makefile 2>/dev/null || cp Makefile Makefile.backup

for LEVEL in 1 3 5; do
    case $LEVEL in
        1) CONFIG="-DQRUOV_dir=qruov1q127L3v156m54 -DQRUOV_security_strength_category=1 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=156 -DQRUOV_m=54 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        3) CONFIG="-DQRUOV_dir=qruov3q127L3v228m78 -DQRUOV_security_strength_category=3 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=228 -DQRUOV_m=78 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        5) CONFIG="-DQRUOV_dir=qruov5q127L3v306m105 -DQRUOV_security_strength_category=5 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=306 -DQRUOV_m=105 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
    esac
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Level $LEVEL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "$CONFIG" > qruov_config.txt
    
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1
    
    echo "🔬 Running callgrind (this will be slow)..."
    valgrind --tool=callgrind \
             --callgrind-out-file=callgrind_level${LEVEL}.out \
             ./PQCgenKAT_sign > /dev/null 2>&1
    
    echo "📊 Top functions by instruction count:"
    callgrind_annotate callgrind_level${LEVEL}.out 2>/dev/null | \
        grep -v "^--" | \
        grep -v "^==" | \
        head -40 | \
        tee profiling_callgrind_level${LEVEL}.txt
    
    echo ""
done

echo "✅ Profiling complete!"
echo ""
echo "📄 Files created:"
ls -lh callgrind_level*.out profiling_callgrind_level*.txt

