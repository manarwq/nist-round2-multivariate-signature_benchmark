#!/bin/bash

OPENSSL=/home/manar/openssl-aarch64
QEMU="/usr/bin/qemu-aarch64 -L /usr/aarch64-linux-gnu -E LD_LIBRARY_PATH=$OPENSSL/lib"
RESULTS=~/Extended_Work_pqm4/UOV_ARM64/dudect_results.txt

echo "=== dudect Constant-Time Verification — All Configurations ===" > $RESULTS
echo "Tool: dudect (Welch t-test, DATE 2017)" >> $RESULTS
echo "Threshold: t < 4.5 = no leakage" >> $RESULTS
echo "Measurements per config: 50,000" >> $RESULTS
echo "" >> $RESULTS

build_and_test() {
    local NAME=$1
    local GF_HEADER=$2
    local EXTRA_FLAGS=$3

    echo ">>> Testing: $NAME"
    cp src/$GF_HEADER src/gf16.h

    aarch64-linux-gnu-gcc \
        -DCONFIG_BENCH_SYSTIME \
        -I$OPENSSL/include \
        -I/home/manar/UOV-C \
        -I./src -I./utils -I./src/ref \
        $EXTRA_FLAGS \
        -O2 -D_OV256_112_44 -D_OV_CLASSIC \
        -o dudect_test_tmp \
        dudect_uov_test.c \
        src/ref/blas_matrix_ref.c src/blas_matrix.c src/ov.c \
        src/ov_keypair.c src/ov_keypair_computation.c \
        src/ov_publicmap.c src/parallel_matrix_op.c src/sign.c \
        utils/aes128_4r_ffs.c utils/fips202.c utils/utils.c \
        utils/utils_hash.c utils/utils_prng.c utils/utils_randombytes.c \
        -L$OPENSSL/lib -lssl -lcrypto -ldl -pthread -lrt -lm 2>/dev/null

    if [ ! -f dudect_test_tmp ]; then
        echo "[$NAME] BUILD FAILED" >> $RESULTS
        return
    fi

    echo "=== $NAME ===" >> $RESULTS
    timeout 200 $QEMU ./dudect_test_tmp 2>&1 | \
        grep -E "RESULT|t-test|no leakage|LEAKAGE|Round 100" >> $RESULTS
    echo "" >> $RESULTS
    rm -f dudect_test_tmp
    echo "    Done: $NAME"
}

# UOV Configurations
build_and_test "Ref (no CT, no LUT)" \
    "gf16_original.h" ""

build_and_test "GE_CT only" \
    "gf16_original.h" "-D_GE_CONST_TIME_CADD_EARLY_STOP_"

build_and_test "Obliv.LUT only" \
    "gf16_obliv.h" ""

build_and_test "GE_CT + Obliv.LUT" \
    "gf16_obliv.h" "-D_GE_CONST_TIME_CADD_EARLY_STOP_"

build_and_test "OLut16+OLut256_LogExp + GE_CT+O3 (BEST)" \
    "gf16_obliv16_obliv256_logexp.h" "-D_GE_CONST_TIME_CADD_EARLY_STOP_ -O3 -funroll-loops"

build_and_test "LUT only (cache-vulnerable)" \
    "gf16_lut.h" ""

build_and_test "LUT + GE_CT" \
    "gf16_lut.h" "-D_GE_CONST_TIME_CADD_EARLY_STOP_"

echo "=== ALL DONE ===" >> $RESULTS
echo ""
echo "Results saved to: $RESULTS"
cat $RESULTS
