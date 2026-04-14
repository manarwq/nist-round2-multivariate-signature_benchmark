---

# UOV Alternative Parameters — Security-Updated Benchmarking

## Overview

This directory extends the original UOV optimization study (01–05) using
alternative parameter sets proposed by Furue & Ikematsu (ePrint 2026/298).

Their work demonstrated that the intersection attack using the p^l-truncated
polynomial ring framework reduces the security of the original UOV parameters
by 15–50 bits below claimed levels. Specifically:

| Original Parameter | Claimed Security | Actual Security (intersection attack) | Reduction |
|--------------------|-----------------|---------------------------------------|-----------|
| uov-Ip  (256,112,44) | 143 bits | 128 bits | −15 bits |
| uov-III (256,184,72) | 207 bits | 182 bits | −25 bits |
| uov-V   (256,244,96) | 272 bits | 223 bits | −50 bits |

The alternative parameters restore security by increasing the number of
vinegar variables (n) while keeping the number of oil variables (m) fixed.

---

## Alternative Parameter Sets

| Original | Alternative | Change | Signature Size |
|----------|-------------|--------|----------------|
| uov-Ip  (256, n=112, m=44) | uov-Ip'  (256, n=120, m=44) | +8 vinegar vars | 128B → 136B |
| uov-III (256, n=184, m=72) | uov-III' (256, n=196, m=72) | +12 vinegar vars | 200B → 212B |
| uov-V   (256, n=244, m=96) | uov-V'   (256, n=260, m=96) | +16 vinegar vars | 260B → 276B |

Reference: Furue, H. & Ikematsu, Y. "Key Recovery Attacks on UOV Using
p^l-truncated Polynomial Rings." Cryptology ePrint Archive, 2026/298.

---

## Directory Structure

### code/ — Baseline (Alternative Parameters)

Source: NIST Reference Implementation (amd64) with updated parameters.

Modifications from original:
- `Ip/params.h` — added _OV256_120_44, _OV256_196_72, _OV256_260_96 defines
- `Ip/ov_publicmap.c` — _MAX_N increased from 256 to 264
- `Ip/parallel_matrix_op.c` — MAX_V increased from 148 to 164

Build and test:
```bash
cd code/amd64
make clean
make PROJ=Ip CFLAGS="-O3 -march=native -D_OV256_120_44"
./sign_api-test
```

Run benchmark:
```bash
bash test_alternative.sh
```

---

### LUT_Optimization/ — Lookup Table Optimization

Source: Custom LUT implementation (from 04_LUT_Optimization) with updated parameters.

Same modifications applied to params.h, ov_publicmap.c, parallel_matrix_op.c.

Run benchmark:
```bash
cd LUT_Optimization
bash test_lut_alternative.sh
```

---

### AVX2_Optimization/ — AVX2 SIMD Optimization

Source: NIST AVX2 optimized implementation with updated parameters.

Same modifications applied to params.h, ov_publicmap.c, parallel_matrix_op.c.

Run benchmark:
```bash
cd AVX2_Optimization
bash test_avx2_alternative.sh
```

---

### OpenMP_Test/ — OpenMP Parallelization

Source: OpenMP test implementation with updated parameters.

Same modifications applied to params.h, ov_publicmap.c, parallel_matrix_op.c.

Run benchmark:
```bash
cd OpenMP_Test
bash test_openmp_alternative.sh
```

---

## Performance Results Summary

### Original Parameters (reference from 01–05)

| Parameter | Baseline | LUT Δ | OpenMP Δ | AVX2 Δ |
|-----------|----------|-------|----------|--------|
| uov-Ip  (256,112,44) | 1.560s | 1.076× | 1.076× | 9.750× |
| uov-III (256,184,72) | 8.470s | 1.150× | 1.149× | 20.700× |
| uov-V   (256,244,96) | 23.495s | 1.012× | 1.087× | 20.700× |

### Alternative Parameters (this directory)

| Parameter | Baseline | LUT Δ | OpenMP Δ | AVX2 Δ |
|-----------|----------|-------|----------|--------|
| uov-Ip'  (256,120,44) | 2.040s | 1.007× | 1.176× | 19.429× |
| uov-III' (256,196,72) | 10.595s | 1.478× | 1.575× | 19.090× |
| uov-V'   (256,260,96) | 29.940s | 1.582× | 1.601× | 19.131× |

---

## Key Observations

**Performance overhead of security fix:**
Increasing vinegar variables adds ~27-30% to baseline signing time across all categories.

**LUT effectiveness increases with alternative parameters:**
GF(256) LUT provides 1.48-1.58× speedup for III' and V' compared to ~1.01-1.15× for originals.
This is because larger n means more field operations, increasing LUT amortization.

**AVX2 remains the dominant optimization:**
~19× speedup consistent across all alternative parameter sets.

**OpenMP shows improved benefits:**
1.18-1.60× speedup for alternative parameters vs 1.08-1.15× for originals,
reflecting larger work granularity with increased vinegar variables.

---

## Status

All alternative parameter variants successfully compiled and tested.
All 500 functional tests passed for each configuration.
Results saved in respective results/ subdirectories.

