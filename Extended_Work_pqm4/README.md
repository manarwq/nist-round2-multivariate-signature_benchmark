# ARM64 Evaluation of MAYO and UOV Post-Quantum Signature Schemes

## Overview

This repository contains an ARM64 performance and security-oriented evaluation of two
NIST Round 2 multivariate signature candidates: UOV and MAYO. The evaluation extends
prior x86 benchmarking to the ARM64 architecture using QEMU user-mode emulation, with
a focus on implementation security (cache-timing resistance, constant-time Gaussian
elimination) alongside performance.

---

## Folder Structure

```
Extended_Work_pqm4/
├── README.md                               <- This file
├── MAYO_ARM64/
│   ├── README.md                           <- MAYO build and benchmark guide
│   ├── results_MAYO_ARM64.txt              <- MAYO benchmark results (13 configs x 4 params)
│   └── src/
│       ├── simple_arithmetic_original.h    <- Reference GF(16)
│       ├── simple_arithmetic_lut_basic.h   <- Standard LUT (cache-vulnerable)
│       └── simple_arithmetic_oblivious_lut.h <- Oblivious LUT (cache-safe)
├── UOV_ARM64/
│   ├── README.md                           <- UOV build and benchmark guide (with group details)
│   ├── results_UOV_ARM64.txt              <- UOV benchmark results (all groups)
│   └── src/
│       ├── gf16_original.h                <- Reference GF(16)
│       ├── gf16_lut.h                     <- Standard LUT (cache-vulnerable)
│       ├── gf16_obliv.h                   <- Oblivious LUT (cache-safe)
│       ├── gf16_lut16_lut256_full.h       <- Group 5: LUT16 + Full LUT256
│       ├── gf16_lut16_lut256_logexp.h     <- Group 5: LUT16 + LogExp256
│       ├── gf16_lut16_obliv256_full.h     <- Group 5: LUT16 + Obliv Full256
│       ├── gf16_lut16_obliv256_logexp.h   <- Group 5: LUT16 + Obliv LogExp256
│       ├── gf16_obliv16_obliv256_full.h   <- Group 5: Obliv16 + Obliv Full256
│       ├── gf16_obliv16_obliv256_logexp.h <- Group 5: BEST COMBINATION
│       ├── config.h                       <- fips202 PRNG (for benchmarks)
│       └── config_original.h             <- OpenSSL PRNG (required for KAT)
├── ARM64_Results/
│   └── results_summary.txt               <- Combined results (MAYO + UOV, all groups)
└── docs/
    └── methodology.md                    <- Benchmark methodology
```

---

## Experimental Environment

| Parameter | Value |
|-----------|-------|
| Host OS | Ubuntu 22.04 LTS |
| Host CPU | Intel Core i7-10510U @ 1.80GHz (2 vCPUs) |
| Platform | Virtual Machine |
| Emulator | QEMU aarch64 v6.2.0 (user-mode emulation) |
| Target Architecture | ARM64 (aarch64) |
| Compiler | aarch64-linux-gnu-gcc 11.4.0 |
| OpenSSL (ARM64) | 3.0.2 (built from source for aarch64) |
| Benchmark metric | Minimum of 3 independent runs |

---

## MAYO — 13 Configurations × 4 Parameter Sets

MAYO uses GF(16) arithmetic. All parameter sets (MAYO-1, MAYO-2, MAYO-3, MAYO-5)
operate over the same field, so optimization strategies apply uniformly.

The dominant cost in MAYO signing is **data reorganization** (transpose_16x16_nibbles),
not field arithmetic. This means field-level optimizations have limited impact on Sign
performance, while security measures add overhead to a non-dominant component.

| Configuration | What it does | Branch-free | Cache-safe |
|---------------|-------------|-------------|------------|
| Ref | Reference implementation | Partial | No |
| LUT | GF(16) standard lookup table | Partial | No |
| Obliv.LUT | GF(16) oblivious LUT | Yes | Yes |
| CT | Constant-time (removes volatile blocker) | Yes | No |
| CT+LUT | CT + standard LUT | Yes | No |
| CT+Obliv.LUT | CT + oblivious LUT **(most secure)** | Yes | Yes |
| NEON | ARM NEON SIMD | Partial | No |
| OpenMP | Thread parallelization | Partial | No |
| O3 | -O3 -funroll-loops | Partial | No |
| LUT+O3 | LUT + O3 **(best raw performance)** | Partial | No |
| CT+O3 | CT + O3 | Yes | No |
| CT+LUT+O3 | CT + LUT + O3 | Yes | No |
| CT+Obliv.LUT+O3 | CT + oblivious LUT + O3 | Yes | Yes |

**Key findings (MAYO-1 Sign, vs Ref 11.1 ms):**
- Best performance: LUT+O3 → 9.3 ms (−16%)
- Most secure: CT+Obliv.LUT → 13.0 ms (+17% overhead)
- NEON and OpenMP: no benefit on 2-core platform
- All 13 configurations passed KAT ✓

For build instructions see: `MAYO_ARM64/README.md`

---

## UOV — 5 Groups × 9 Parameter Sets

UOV uses GF(16) at Category I and GF(256) at Categories III and V.
The dominant cost is **matrix multiplication** over finite fields, which is directly
improved by field arithmetic optimization — making security and performance
mutually reinforcing for UOV.

### Group 1 — Compiler Optimization (Baseline)
Tests the effect of compiler flags alone, without code changes.

| Config | Flags |
|--------|-------|
| Ref | (none) |
| O3 | -O3 -funroll-loops |

### Group 2 — GF(16) Lookup Table Optimization
Replaces bitwise GF(16) multiplication with precomputed tables.
The **standard LUT** (256 bytes, fits in L1) is fast but exposes the secret index
through cache access patterns. The **oblivious LUT** scans all 256 entries
unconditionally, hiding the secret index at the cost of O(N) accesses per lookup.

| Config | LUT Type | Cache-Safe | Flags |
|--------|----------|------------|-------|
| LUT | Standard | No | (none) |
| LUT+O3 | Standard | No | -O3 -funroll-loops |
| Obliv.LUT | Oblivious | Yes | (none) |
| Obliv.LUT+O3 | Oblivious | Yes | -O3 -funroll-loops |

### Group 3 — Constant-Time Gaussian Elimination
UOV signing uses Gaussian elimination over secret data. A naive implementation
has secret-dependent branches (pivot search, conditional row swap), leaking through
timing. The CT variant uses arithmetic masking (CADD) — no branches, uniform trace.

| Config | Branch-free GE | Cache-Safe |
|--------|----------------|------------|
| GE_CT | Yes | No |
| GE_CT+O3 | Yes | No |
| GE_CT+LUT | Yes | No |
| GE_CT+Obliv.LUT **(most secure single-field)** | Yes | Yes |

### Group 4 — ARM64 SIMD and Parallelization
Tests ARM NEON vectorization and OpenMP threading.
**Result: no benefit on this 2-core platform** — compiler auto-vectorization already
captures available SIMD opportunities, and thread overhead exceeds gains.

| Config | Method |
|--------|--------|
| NEON | ARM NEON SIMD (-march=armv8-a+simd) |
| NEON+O3 | NEON + -O3 |
| OpenMP | Thread parallelization (-fopenmp) |
| OpenMP+O3 | OpenMP + -O3 |

### Group 5 — Combined GF(16)+GF(256) Optimizations ← Key Contribution

UOV signing involves arithmetic over **both GF(16) and GF(256) simultaneously**.
Optimizing each field independently misses cache interaction effects. This group
evaluates all 6 combinations of GF(16) × GF(256) methods.

**GF(256) methods:**
- **Full LUT**: 64 KB table — exceeds L1 cache (32 KB), spills to L2
- **Log-Exp**: two 256-byte tables (512 B total) — fits in L1 alongside GF(16) table
- **Oblivious Full**: 64 KB oblivious scan — cache-safe but expensive
- **Oblivious Log-Exp**: two 256-byte oblivious scans — cache-safe AND L1-friendly ← BEST

| Combination | GF(16) | GF(256) | Cache-Safe | Source File |
|-------------|--------|---------|------------|-------------|
| LUT16+Full256 | Standard | Full 64KB | No | gf16_lut16_lut256_full.h |
| LUT16+LogExp256 | Standard | Log-Exp 512B | No | gf16_lut16_lut256_logexp.h |
| LUT16+OLut256_Full | Standard | Obliv. Full | Partial | gf16_lut16_obliv256_full.h |
| LUT16+OLut256_LogExp | Standard | Obliv. Log-Exp | Partial | gf16_lut16_obliv256_logexp.h |
| OLut16+OLut256_Full | Oblivious | Obliv. Full | Yes | gf16_obliv16_obliv256_full.h |
| **OLut16+OLut256_LogExp** | **Obliv.** | **Obliv. Log-Exp** | **Yes** | **gf16_obliv16_obliv256_logexp.h** |

Each combination was evaluated under 6 build configs: Ref, O3, GE_CT, GE_CT+O3, OpenMP, OpenMP+O3.

**Why OLut16+OLut256_LogExp outperforms OLut16+OLut256_Full:**
The full-table oblivious scan (64 KB) exceeds L1 capacity and competes with the
GF(16) table for L2. The log-exp construction (512 bytes) allows both tables to
fit in L1 simultaneously — a cache co-residency effect invisible to single-layer analysis.

**Best overall: OLut16+OLut256_LogExp + GE_CT+O3 (ov-Ip-classic)**

| Operation | Best | Ref | Improvement |
|-----------|------|-----|-------------|
| KeyGen | 137K μs | 456K μs | −70% |
| Sign | 2,245 μs | 7,899 μs | −72% |
| Verify | 324 μs | 3,132 μs | −90% |
| Memory | 9,984 kB | 21,004 kB | −52% |

Full details and all 9 parameter sets: `UOV_ARM64/README.md`
All benchmark data: `UOV_ARM64/results_UOV_ARM64.txt`

---

## Quick Start

### MAYO
```bash
git clone https://github.com/PQCMayo/MAYO-C
cd MAYO-C && mkdir build && cd build
cmake .. -DMAYO_BUILD_TYPE=ref \
  -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DENABLE_TESTS=ON \
  -DMAYO_MARCH="-march=armv8-a" \
  -DENABLE_STRICT=OFF
make
qemu-aarch64 -L /usr/aarch64-linux-gnu ./test/mayo_bench MAYO-1 100
```

### UOV — Best Configuration (Group 5)
```bash
git clone https://github.com/pqov/pqov
cd pqov

# Copy best combined GF header
cp src/gf16_obliv16_obliv256_logexp.h src/gf16.h

# Build (example: ov-Ip-classic with GE_CT+O3)
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

# Measure memory
/usr/bin/time -v /usr/bin/qemu-aarch64 -L /usr/aarch64-linux-gnu \
    -E LD_LIBRARY_PATH=/path/to/openssl-aarch64/lib \
    ./sign_api-benchmark 2>&1 | grep "Maximum resident"
```

---

## KAT Verification

- UOV: All 9 schemes × all configurations passed KAT ✓
- MAYO: All 13 configurations passed KAT ✓

Note: KAT for UOV requires `config_original.h` (OpenSSL PRNG).

---

## References

- MAYO C implementation: https://github.com/PQCMayo/MAYO-C
- UOV C implementation: https://github.com/pqov/pqov
- NIST Round 2 submissions: https://csrc.nist.gov/Projects/pqc-dig-sig
