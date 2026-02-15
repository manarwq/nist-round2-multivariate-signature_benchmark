
---

# UOV Optimization Analysis

## Overview

This document summarizes the optimization study conducted on the Unbalanced Oil and Vinegar (UOV) signature scheme implementation, including reference, AVX2, LUT, and OpenMP configurations.

All variants were compiled, executed, and benchmarked successfully.

---

# Verified Implementations

The following configurations were built and verified:

* Baseline (amd64 reference implementation)
* AVX2 optimized implementation (NIST)
* LUT optimization (our custom implementation)
* OpenMP testing

All configurations passed functional testing.

---

# Directory Structure

## 01_Baseline

Source: NIST Reference Implementation (amd64)
Status: Verified working

Build and test:

```bash
cd 01_Baseline/code/amd64
make PROJ=Ip
./sign_api-test
```

This serves as the performance reference point.

---

## 02_Profiling

Purpose: Performance analysis and bottleneck identification.

Includes:

* Instruction-level profiling
* Hotspot detection
* Overhead analysis

---

## 03_AVX2_Optimization

Source: NIST Optimized Implementation
Status: Verified working

Contains:

* `blas_avx2.h` – Hand-written AVX2 intrinsics
* `blas_matrix_avx2.c` – SIMD matrix routines
* Usage of `__m256i` and `_mm256_*` intrinsics

Build and test:

```bash
cd 03_AVX2_Optimization/code/avx2
make PROJ=III
./sign_api-test
```

Important:
These AVX2 optimizations are official NIST implementations and are not custom-developed in this work.

---

## 04_LUT_Optimization

Source: Custom implementation (our contribution)
Status: Verified working

Description:
Custom lookup table for accelerating GF(16) multiplication.

Our contribution:

* Introduced `gf16_lut.h` (not part of the NIST submission)
* Implemented GF(16) multiplication lookup table
* Integrated LUT-based arithmetic into the existing codebase
* Benchmarked and validated correctness

Example:

```c
// GF(16) Multiplication Lookup Table
// Irreducible polynomial: x^4 + x + 1
// Size: 16 x 16 = 256 bytes

static const uint8_t gf16_mul_table[16][16] = {
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
    // ...
};
```

Observed performance improvement:
Approximately 1.08× average speedup (category-dependent).

---

## 05_OpenMP_Test

Purpose:
Evaluation of compiler-level and multi-threading optimizations using OpenMP.

Includes:

* Performance comparison with and without OpenMP
* Instruction-level profiling
* Runtime overhead analysis

---

# Our Contributions

The following components represent original work in this study:

* LUT implementation (`gf16_lut.h`)
* Integration into the UOV codebase
* Systematic benchmarking across NIST levels
* Comparative analysis across optimization strategies

The AVX2 implementation originates from NIST and was used for evaluation only.

---

# Performance Summary

| Variant  | Source                | Our Work | Status   | Typical Speedup                                    |
| -------- | --------------------- | -------- | -------- | -------------------------------------------------- |
| Baseline | NIST Reference        | Testing  | Verified | 1.00×                                              |
| AVX2     | NIST Optimized        | Testing  | Verified | Varies (already enabled in baseline in some cases) |
| LUT      | Custom Implementation | Yes      | Verified | ~1.08×                                             |

---

# Implementation Notes

## AVX2

* Provided by NIST optimized implementation
* Uses explicit SIMD intrinsics
* Includes optimized matrix arithmetic
* Not developed as part of this work

## LUT

* Custom-developed lookup table
* Targets GF(16) arithmetic
* Lightweight memory footprint (256 bytes)
* Best improvements observed in mid-range parameter sets

---

# Repository Size

* Total files: 2,465
* C source files: 915
* Header files: 1,501
* Custom LUT file: `gf16_lut.h`

---

# Status

All variants successfully compiled and executed.
All performance results reproducible.
Optimization study complete.

---


