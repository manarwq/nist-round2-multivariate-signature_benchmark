#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "qr-UOV Profiling - All Levels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# حفظ Makefile
cp Makefile Makefile.backup

# تعديل للـ profiling
cat > Makefile << 'MAKE'
PLATFORM=portable64
CC=gcc
CFLAGS=-pg -O2 -fno-inline -Wno-deprecated-declarations -Wno-unused-result
LDFLAGS=-lcrypto -Wl,-Bstatic -lcrypto -Wl,-Bdynamic -lm -pg
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
	rm -f PQCgenKAT_sign *.o gmon.out
MAKE

for LEVEL in 1 3 5; do
    case $LEVEL in
        1) CONFIG="-DQRUOV_dir=qruov1q127L3v156m54 -DQRUOV_security_strength_category=1 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=156 -DQRUOV_m=54 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        3) CONFIG="-DQRUOV_dir=qruov3q127L3v228m78 -DQRUOV_security_strength_category=3 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=228 -DQRUOV_m=78 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
        5) CONFIG="-DQRUOV_dir=qruov5q127L3v306m105 -DQRUOV_security_strength_category=5 -DQRUOV_q=127 -DQRUOV_L=3 -DQRUOV_v=306 -DQRUOV_m=105 -DQRUOV_fc=1 -DQRUOV_fe=1 -DQRUOV_fc0=1" ;;
    esac
    
    echo "Profiling Level $LEVEL..."
    echo "$CONFIG" > qruov_config.txt
    
    make clean > /dev/null 2>&1
    make > /dev/null 2>&1
    
    echo "  Running..."
    ./PQCgenKAT_sign > /dev/null 2>&1
    
    echo "  Top functions:" | tee profiling_level${LEVEL}.txt
    gprof PQCgenKAT_sign gmon.out 2>/dev/null | \
        grep -A 30 "^  %" | head -35 | tee -a profiling_level${LEVEL}.txt
    
    echo ""
done

# استعادة Makefile
cp Makefile.backup Makefile
rm Makefile.backup

echo "✅ Profiling complete!"
echo "Results: profiling_level*.txt"

