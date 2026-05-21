# UOV ARM64 Evaluation

## Overview

ARM64 evaluation of the UOV (Unbalanced Oil and Vinegar) post-quantum signature scheme.
This evaluation extends prior x86 benchmarking to ARM64, with a focus on both performance
and implementation security (cache-timing resistance, constant-time Gaussian elimination).

## Environment

| Parameter | Value |
|-----------|-------|
| Host OS | Ubuntu 22.04, Intel Core i7-10510U @ 1.80GHz (2 vCPUs) |
| Emulator | QEMU aarch64 v6.2.0 (user-mode) |
| Compiler | aarch64-linux-gnu-gcc 11.4.0 |
| OpenSSL | 3.0.2 (built from source for aarch64) |
| Source | https://github.com/pqov/pqov |

## Parameter Sets (9 total)

UOV defines three NIST security categories, each available in three key compression variants:

| Scheme | Security Level | Field | v | o | n | Signature | Public Key |
|--------|---------------|-------|---|---|---|-----------|------------|
| ov-Ip-classic | NIST-1 | GF(16) | 68 | 17 | 85 | 96 B | 29 KB |
| ov-Ip-pkc | NIST-1 | GF(16) | 68 | 17 | 85 | 96 B | 8.2 KB |
| ov-Ip-pkc-skc | NIST-1 | GF(16) | 68 | 17 | 85 | 96 B | 5.2 KB |
| ov-IIIp-classic | NIST-3 | GF(256) | 120 | 31 | 151 | 151 B | 171 KB |
| ov-IIIp-pkc | NIST-3 | GF(256) | 120 | 31 | 151 | 151 B | 39 KB |
| ov-IIIp-pkc-skc | NIST-3 | GF(256) | 120 | 31 | 151 | 151 B | 4.4 KB |
| ov-Vp-classic | NIST-5 | GF(256) | 172 | 44 | 216 | 216 B | 460 KB |
| ov-Vp-pkc | NIST-5 | GF(256) | 172 | 44 | 216 | 216 B | 96 KB |
| ov-Vp-pkc-skc | NIST-5 | GF(256) | 172 | 44 | 216 | 216 B | 5.8 KB |

Key compression variants:
- **classic**: full public key stored explicitly
- **pkc**: compressed public key (derived from seed)
- **pkc-skc**: compressed public and secret keys

---

## Optimization Groups

This evaluation is organized into 5 groups, each targeting a different optimization dimension.

---

### Group 1 — Compiler Optimization (Baseline)

**What it tests:** Effect of compiler flags alone, without any code changes.

| Config | Description | GF Header | Flags |
|--------|-------------|-----------|-------|
| Ref | Reference implementation | gf16_original.h | (none) |
| O3 | Compiler optimization | gf16_original.h | -O3 -funroll-loops |

**Purpose:** Establish the baseline and measure how much the compiler alone can improve performance.

---

### Group 2 — GF(16) Arithmetic Optimizations

**What it tests:** Replacing bitwise GF(16) multiplication with precomputed lookup tables.

UOV Category I uses GF(16) arithmetic. A lookup table (LUT) precomputes all 16×16=256
multiplication results (256 bytes), fitting entirely in L1 cache.

Two variants are evaluated:
- **Standard LUT**: fast but cache-timing vulnerable (secret index exposed through memory access pattern)
- **Oblivious LUT**: cache-safe (scans all 256 entries unconditionally, hiding the secret index)

| Config | Description | GF Header | Cache-Safe | Flags |
|--------|-------------|-----------|------------|-------|
| LUT | Standard lookup table | gf16_lut.h | No | (none) |
| LUT+O3 | LUT + compiler opt. | gf16_lut.h | No | -O3 -funroll-loops |
| Obliv.LUT | Oblivious LUT | gf16_obliv.h | Yes | (none) |
| Obliv.LUT+O3 | Obliv.LUT + compiler opt. | gf16_obliv.h | Yes | -O3 -funroll-loops |

**Purpose:** Measure the performance gain from LUT-based field arithmetic and the overhead
of making the LUT cache-safe through oblivious access.

---

### Group 3 — Constant-Time Gaussian Elimination

**What it tests:** Securing the Gaussian elimination step against timing side channels.

UOV signing solves a linear system via Gaussian elimination. A naive implementation uses
secret-dependent branches (pivot search, conditional row swap), leaking information about
the secret vinegar variables through timing variations. The constant-time variant replaces
these branches with arithmetic masking (CADD: conditional add without branches).

Combinations with LUT variants show the combined effect of securing both GF arithmetic
and the GE step simultaneously.

| Config | Description | GF Header | Branch-free GE | Cache-Safe |
|--------|-------------|-----------|----------------|------------|
| GE_CT | Constant-time GE only | gf16_original.h | Yes | No |
| GE_CT+O3 | GE_CT + compiler opt. | gf16_original.h | Yes | No |
| GE_CT+LUT | GE_CT + standard LUT | gf16_lut.h | Yes | No |
| GE_CT+Obliv.LUT | GE_CT + oblivious LUT | gf16_obliv.h | Yes | Yes |

**Purpose:** Quantify the overhead of constant-time GE and identify the most secure
single-field configuration.

---

### Group 4 — ARM64 SIMD and Parallelization

**What it tests:** ARM NEON SIMD vectorization and OpenMP thread-level parallelization.

| Config | Description | GF Header | Flags |
|--------|-------------|-----------|-------|
| NEON | ARM NEON SIMD | gf16_original.h | -march=armv8-a+simd |
| NEON+O3 | NEON + compiler opt. | gf16_original.h | -march=armv8-a+simd -O3 |
| OpenMP | Thread parallelization | gf16_original.h | -fopenmp |
| OpenMP+O3 | OpenMP + compiler opt. | gf16_original.h | -fopenmp -O3 |

**Purpose:** Test whether ARM-specific SIMD and multi-threading provide additional
gains beyond the compiler optimizations in Group 1. (Result: neither NEON nor OpenMP
provides measurable benefit on this 2-core platform; see results.)

---

### Group 5 — Combined GF(16)+GF(256) Optimizations

**What it tests:** Joint optimization of both GF(16) and GF(256) arithmetic layers.

UOV Categories III and V use GF(256) arithmetic. Within a single signing operation,
arithmetic occurs over both GF(16) AND GF(256) simultaneously. Optimizing each field
layer independently misses cache interaction effects. This group evaluates all combinations.

**GF(256) methods compared:**
- **Full LUT**: 64 KB table (exceeds L1 cache, spills to L2)
- **Log-Exp**: two 256-byte tables (512 bytes total, fits in L1) using a × b = g^(log a + log b mod 255)
- **Oblivious Full**: 64 KB oblivious scan per lookup (cache-safe but expensive)
- **Oblivious Log-Exp**: two 256-byte oblivious scans (cache-safe AND L1-friendly) ← BEST

| Combination | Source File | GF(16) | GF(256) | Both Cache-Safe |
|-------------|-------------|--------|---------|-----------------|
| LUT16+Full256 | gf16_lut16_lut256_full.h | LUT | Full 64KB | No |
| LUT16+LogExp256 | gf16_lut16_lut256_logexp.h | LUT | Log-Exp 512B | No |
| LUT16+OLut256_Full | gf16_lut16_obliv256_full.h | LUT | Obliv. Full | Partial |
| LUT16+OLut256_LogExp | gf16_lut16_obliv256_logexp.h | LUT | Obliv. Log-Exp | Partial |
| OLut16+OLut256_Full | gf16_obliv16_obliv256_full.h | Obliv. | Obliv. Full | Yes |
| **OLut16+OLut256_LogExp** | **gf16_obliv16_obliv256_logexp.h** | **Obliv.** | **Obliv. Log-Exp** | **Yes ← BEST** |

Each combination was evaluated under 6 build configurations:
`Ref`, `O3`, `GE_CT`, `GE_CT+O3`, `OpenMP`, `OpenMP+O3`

**Best overall result:** OLut16+OLut256_LogExp + GE_CT+O3 (ov-Ip-classic)

| Operation | Best | Ref | Improvement |
|-----------|------|-----|-------------|
| KeyGen | 137K μs | 456K μs | −70% |
| Sign | 2,245 μs | 7,899 μs | −72% |
| Verify | 324 μs | 3,132 μs | −90% |
| Memory | 9,984 kB | 21,004 kB | −52% |

**Why OLut16+OLut256_LogExp outperforms OLut16+OLut256_Full:**
The oblivious full-table scan touches 64 KB per GF(256) multiplication, exceeding L1
cache (32 KB) and competing with the GF(16) table for L2. The log-exp construction
replaces this with two 256-byte scans (512 bytes), allowing both field tables to
reside in L1 simultaneously — a cache co-residency effect that single-layer analysis
cannot predict.

---

## Source Files

### Groups 1–4: Single-Field Headers
| File | Description |
|------|-------------|
| gf16_original.h | Reference bitwise GF(16) arithmetic |
| gf16_lut.h | Standard LUT (cache-vulnerable) |
| gf16_obliv.h | Oblivious LUT (cache-safe) |
| config.h | Modified config (fips202 PRNG, for benchmarks) |
| config_original.h | Original config (OpenSSL PRNG, required for KAT) |

### Group 5: Combined GF(16)+GF(256) Headers
| File | GF(16) Method | GF(256) Method |
|------|--------------|----------------|
| gf16_lut16_lut256_full.h | Standard LUT | Full 64KB table |
| gf16_lut16_lut256_logexp.h | Standard LUT | Log-Exp 512B |
| gf16_lut16_obliv256_full.h | Standard LUT | Oblivious Full |
| gf16_lut16_obliv256_logexp.h | Standard LUT | Oblivious Log-Exp |
| gf16_obliv16_obliv256_full.h | Oblivious LUT | Oblivious Full |
| gf16_obliv16_obliv256_logexp.h | Oblivious LUT | Oblivious Log-Exp ← BEST |

---

## Build and Benchmark

### Prerequisites
```bash
sudo apt install gcc-aarch64-linux-gnu qemu-user
```
OpenSSL must be built from source for aarch64. See: https://github.com/pqov/pqov

### Step 1: Select GF header
```bash
cd ~/UOV-C

# Group 1 (Ref/O3):
cp src/gf16_original.h src/gf16.h

# Group 2:
cp src/gf16_lut.h src/gf16.h            # LUT
cp src/gf16_obliv.h src/gf16.h          # Obliv.LUT

# Group 5 - Best combination:
cp src/gf16_obliv16_obliv256_logexp.h src/gf16.h
```

### Step 2: Build
```bash
make CC=aarch64-linux-gnu-gcc PROJ=ref \
     CFLAGS="-DCONFIG_BENCH_SYSTIME \
             -I/home/manar/openssl-aarch64/include \
             -D_GE_CONST_TIME_CADD_EARLY_STOP_ \
             -O3 -funroll-loops \
             -D_OV256_112_44 -D_OV_CLASSIC" \
     LIBS="-L/home/manar/openssl-aarch64/lib -lssl -lcrypto -ldl -pthread" \
     sign_api-benchmark
```

### Step 3: Run benchmark
```bash
/usr/bin/qemu-aarch64 -L /usr/aarch64-linux-gnu \
    -E LD_LIBRARY_PATH=/home/manar/openssl-aarch64/lib \
    ./sign_api-benchmark
```

### Step 4: Measure memory
```bash
/usr/bin/time -v /usr/bin/qemu-aarch64 -L /usr/aarch64-linux-gnu \
    -E LD_LIBRARY_PATH=/home/manar/openssl-aarch64/lib \
    ./sign_api-benchmark 2>&1 | grep "Maximum resident"
```

### Parameter set flags
| Scheme | PSET flag | VARIANT flag |
|--------|-----------|--------------|
| ov-Ip-classic | -D_OV256_112_44 | -D_OV_CLASSIC |
| ov-Ip-pkc | -D_OV256_112_44 | -D_OV_PKC |
| ov-Ip-pkc-skc | -D_OV256_112_44 | -D_OV_PKC_SKC |
| ov-IIIp-classic | -D_OV256_184_72 | -D_OV_CLASSIC |
| ov-IIIp-pkc | -D_OV256_184_72 | -D_OV_PKC |
| ov-IIIp-pkc-skc | -D_OV256_184_72 | -D_OV_PKC_SKC |
| ov-Vp-classic | -D_OV256_244_96 | -D_OV_CLASSIC |
| ov-Vp-pkc | -D_OV256_244_96 | -D_OV_PKC |
| ov-Vp-pkc-skc | -D_OV256_244_96 | -D_OV_PKC_SKC |

### Build flags per Group
| Group | Extra CFLAGS |
|-------|-------------|
| Group 1 (Ref) | (none) |
| Group 1 (O3) | -O3 -funroll-loops |
| Group 2 (LUT/Obliv.LUT) | (none or -O3) |
| Group 3 (GE_CT) | -D_GE_CONST_TIME_CADD_EARLY_STOP_ |
| Group 3 (GE_CT+O3) | -D_GE_CONST_TIME_CADD_EARLY_STOP_ -O3 -funroll-loops |
| Group 4 (NEON) | -march=armv8-a+simd |
| Group 4 (OpenMP) | -fopenmp |
| Group 5 (GE_CT+O3) | -D_GE_CONST_TIME_CADD_EARLY_STOP_ -O3 -funroll-loops |

---

## KAT Verification

All 9 schemes × all configurations passed KAT (Known Answer Tests).
KAT requires `config_original.h` (OpenSSL PRNG) instead of `config.h`.

---

## Results

Full benchmark data: `results_UOV_ARM64.txt`
Combined summary (UOV + MAYO): `../ARM64_Results/results_summary.txt`
