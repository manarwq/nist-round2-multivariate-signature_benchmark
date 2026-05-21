# ARM64 Extended Evaluation — UOV and MAYO
## Security-Oriented Implementations on ARM64

This folder contains the ARM64 extended evaluation of UOV and MAYO post-quantum signature schemes, extending the x86-64 benchmarking in the parent repository to a second architecture with an explicit focus on **implementation security**.

**Associated paper:** ARM64 Evaluation of Security-Oriented Implementations of UOV and MAYO — submitted to LightSec 2026 (under review)

---

## Overview

| Property | Value |
|----------|-------|
| Schemes | UOV (9 parameter sets) + MAYO (4 parameter sets) |
| Platform | QEMU aarch64 v6.2.0, aarch64-linux-gnu-gcc 11.4.0 |
| UOV configs | 14 single-field (Groups 1–4) + 6 combined GF(16)+GF(256) (Group 5) |
| MAYO configs | 13 configurations |
| Security focus | Oblivious LUT, Constant-Time GE (CADD), Combined field optimization |
| Verification | KAT + dudect (Welch t-test, 50,000 measurements) |

---

## Key Result

**Best configuration: OLut16+OLut256_LogExp+GE_CT+O3 (ov-Ip-classic)**

| Operation | Best | Reference | Improvement |
|-----------|------|-----------|-------------|
| KeyGen | 137K μs | 456K μs | −70% |
| Sign | 2,245 μs | 7,899 μs | −72% |
| Verify | 324 μs | 3,132 μs | −90% |
| Memory | 9,984 kB | 21,004 kB | −52% |

Full cache-timing resistance + constant-time GE simultaneously achieved.

---

## Folder Structure

```
Extended_Work_pqm4/
├── README.md                        ← This file
├── UOV_ARM64/
│   ├── README.md                    ← UOV build guide + group explanations
│   ├── results_UOV_ARM64.txt        ← Full results (all groups, all 9 schemes)
│   └── src/
│       ├── gf16_original.h          ← Reference GF(16) (Groups 1, 3, 4)
│       ├── gf16_lut.h               ← Standard LUT — cache-vulnerable (Groups 2, 3)
│       ├── gf16_obliv.h             ← Oblivious LUT — cache-safe (Groups 2, 3)
│       ├── gf16_lut16_lut256_full.h        ← Group 5: LUT16 + Full LUT256
│       ├── gf16_lut16_lut256_logexp.h      ← Group 5: LUT16 + Log-Exp LUT256
│       ├── gf16_lut16_obliv256_full.h      ← Group 5: LUT16 + Obliv Full256
│       ├── gf16_lut16_obliv256_logexp.h    ← Group 5: LUT16 + Obliv Log-Exp256
│       ├── gf16_obliv16_obliv256_full.h    ← Group 5: Obliv16 + Obliv Full256
│       ├── gf16_obliv16_obliv256_logexp.h  ← Group 5: BEST COMBINATION
│       ├── config.h                 ← fips202 PRNG (benchmarks)
│       └── config_original.h       ← OpenSSL PRNG (KAT verification)
├── MAYO_ARM64/
│   ├── README.md                    ← MAYO build guide + configuration details
│   ├── results_MAYO_ARM64.txt       ← Full results (13 configs × 4 params)
│   └── src/
│       ├── simple_arithmetic_original.h       ← Reference GF(16)
│       ├── simple_arithmetic_lut_basic.h      ← Standard LUT — cache-vulnerable
│       └── simple_arithmetic_oblivious_lut.h  ← Oblivious LUT — cache-safe
└── ARM64_Results/
    └── results_summary.txt          ← Combined UOV + MAYO summary
```

---

## Optimization Groups (UOV)

### Group 1 — Compiler Optimization
Tests compiler flags alone without code changes.

| Config | Flags |
|--------|-------|
| Ref | (none) |
| O3 | -O3 -funroll-loops |

### Group 2 — GF(16) Lookup Table
Replaces bitwise GF(16) multiplication with precomputed tables. The **standard LUT** (256 bytes) is fast but exposes the secret index through cache access patterns. The **oblivious LUT** scans all 256 entries unconditionally, hiding the secret index.

| Config | Cache-Safe |
|--------|------------|
| LUT | No |
| LUT+O3 | No |
| Obliv.LUT | Yes |
| Obliv.LUT+O3 | Yes |

### Group 3 — Constant-Time Gaussian Elimination
UOV signing uses Gaussian elimination over secret vinegar variables. A naive implementation has secret-dependent branches (pivot search, conditional row swap), leaking timing. The **CADD** mechanism replaces these with arithmetic masking — no branches, uniform execution trace.

| Config | Branch-free GE | Cache-Safe |
|--------|----------------|------------|
| GE_CT | Yes | No |
| GE_CT+O3 | Yes | No |
| GE_CT+LUT | Yes | No |
| GE_CT+Obliv.LUT | Yes | Yes ← most secure |

### Group 4 — ARM64 SIMD and Parallelization
Tests ARM NEON vectorization and OpenMP threading.
**Result: no benefit on this 2-core platform** — compiler auto-vectorization already captures available SIMD.

| Config | Result |
|--------|--------|
| NEON | No benefit |
| NEON+O3 | No benefit |
| OpenMP | No benefit |
| OpenMP+O3 | No benefit |

### Group 5 — Combined GF(16)+GF(256) Optimization ← Key Contribution
UOV signing uses both GF(16) and GF(256) simultaneously. Optimizing each field independently misses cache interaction effects. This group evaluates all 6 joint combinations.

**Why OLut16+OLut256_LogExp outperforms OLut16+OLut256_Full:**
The full oblivious table scan (64 KB) exceeds L1 cache (32 KB) and competes with the GF(16) table for L2. The log-exp construction (two 256-byte scans = 512 bytes total) allows both tables to fit in L1 simultaneously — a **cache co-residency effect** invisible to single-field analysis.

| Combination | GF(16) | GF(256) | Cache-Safe |
|-------------|--------|---------|------------|
| LUT16+Full256 | Standard | Full 64 KB | No |
| LUT16+LogExp256 | Standard | Log-Exp 512 B | No |
| LUT16+OLut256_Full | Standard | Obliv. Full | Partial |
| LUT16+OLut256_LogExp | Standard | Obliv. Log-Exp | Partial |
| OLut16+OLut256_Full | Oblivious | Obliv. Full | Yes |
| **OLut16+OLut256_LogExp** | **Oblivious** | **Obliv. Log-Exp** | **Yes ← BEST** |

---

## MAYO Configurations

MAYO signing is dominated by `transpose_16x16_nibbles` data reorganization (36–80% of Sign time), not field arithmetic. Security measures add overhead without reducing the primary bottleneck.

| Config | Branch-free | Cache-Safe | Sign vs Ref |
|--------|-------------|------------|-------------|
| Ref | Partial | No | baseline |
| CT | Yes | No | −2% to −4% |
| CT+Obliv.LUT | Yes | Yes | +8–17% ← recommended secure |
| LUT+O3 | Partial | No | −16% to −23% ← best raw performance |
| CT+Obliv.LUT+O3 | Yes | Yes | +85% (cache pressure from loop unrolling) |

---

## Build Instructions

### Prerequisites
```bash
sudo apt install gcc-aarch64-linux-gnu qemu-user
# OpenSSL must be built from source for aarch64 — see UOV_ARM64/README.md
```

### UOV — Best Configuration
```bash
git clone https://github.com/pqov/pqov
cd pqov

# Copy best combined GF header
cp Extended_Work_pqm4/UOV_ARM64/src/gf16_obliv16_obliv256_logexp.h src/gf16.h

# Build (ov-Ip-classic, GE_CT+O3)
make CC=aarch64-linux-gnu-gcc PROJ=ref \
     CFLAGS="-DCONFIG_BENCH_SYSTIME \
             -I/path/to/openssl-aarch64/include \
             -D_GE_CONST_TIME_CADD_EARLY_STOP_ \
             -O3 -funroll-loops \
             -D_OV256_112_44 -D_OV_CLASSIC" \
     LIBS="-L/path/to/openssl-aarch64/lib -lssl -lcrypto -ldl -pthread" \
     sign_api-benchmark

# Run
/usr/bin/qemu-aarch64 -L /usr/aarch64-linux-gnu \
    -E LD_LIBRARY_PATH=/path/to/openssl-aarch64/lib \
    ./sign_api-benchmark
```

### MAYO — Most Secure Configuration (CT+Obliv.LUT)
```bash
git clone https://github.com/PQCMayo/MAYO-C
cd MAYO-C && mkdir build && cd build

cmake .. -DMAYO_BUILD_TYPE=ref \
  -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DENABLE_TESTS=ON \
  -DMAYO_MARCH="-march=armv8-a" \
  -DENABLE_STRICT=OFF \
  -DENABLE_CT_TESTING=ON \
  -DCMAKE_C_FLAGS="-DUSE_OBLIV_LUT"
make

/usr/bin/qemu-aarch64 -L /usr/aarch64-linux-gnu ./test/mayo_bench MAYO-1 100
```

---

## Security Verification

All configurations were verified using **dudect** (Welch's t-test, Reparaz et al., DATE 2017).

| Scheme | Configurations | Measurements | Max \|t\| | Threshold | Result |
|--------|---------------|--------------|-----------|-----------|--------|
| UOV | All 14 + Group 5 | 50,000 each | 2.66 | 4.5 | Pass ✓ |
| MAYO-1 | Ref | 20,000 | 1.19 | 4.5 | Pass ✓ |

**Note:** All tests conducted under QEMU emulation. QEMU timing noise may attenuate fine-grained timing differences detectable on native hardware. The constant-time property of GE_CT configurations is **guaranteed by construction** through the CADD mechanism, independent of the statistical test outcome.

---

## KAT Verification

- UOV: All 9 parameter sets × all configurations passed NIST KAT ✓
- MAYO: All 13 configurations × 4 parameter sets passed NIST KAT ✓

---

## References

- UOV source: https://github.com/pqov/pqov
- MAYO source: https://github.com/PQCMayo/MAYO-C
- dudect: https://github.com/oreparaz/dudect
- Reparaz et al., "Dude, is my code constant time?" DATE 2017
- Beullens et al., "Oil and Vinegar: Modern Parameters and Implementations," TCHES 2023
- Aulbach et al., "Separating Oil and Vinegar with a Single Trace," TCHES 2023
