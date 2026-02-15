
# Profiling Results – qr-UOV

# Level 1

```
Total Instructions: 24,507,226,436
```

## Top Functions

* 63.2%  OpenMP runtime overhead (libgomp)
* 9.97%  MATRIX_MUL_MxV_VxV
* 5.05%  Expand_pk
* 3.80%  MATRIX_MUL_ADD_MxV_VxM
* 3.45%  MATRIX_MUL_MxV_VxM
* 1.08%  QRUOV_Sign (wrapper)
* 0.76%  VERIFY_i

---

# Level 3

```
Total Instructions: 18,688,560,237
```

## Top Functions

* 51.8%  OpenMP runtime overhead (libgomp)
* 13.07% MATRIX_MUL_MxV_VxV
* 6.63%  Expand_pk
* 4.98%  MATRIX_MUL_ADD_MxV_VxM
* 4.53%  MATRIX_MUL_MxV_VxM
* 1.08%  QRUOV_Sign (wrapper)
* 0.99%  VERIFY_i

---

# Level 5

```
Total Instructions: 30,008,768,629
```

## Top Functions

* 70.0%  OpenMP runtime overhead (libgomp)
* 8.14%  MATRIX_MUL_MxV_VxV
* 4.13%  Expand_pk
* 3.10%  MATRIX_MUL_ADD_MxV_VxM
* 2.82%  MATRIX_MUL_MxV_VxM
* 0.67%  QRUOV_Sign (wrapper)
* 0.62%  VERIFY_i

---

# Analysis and Conclusions

## 1. Massive OpenMP Overhead

| Level   | OpenMP Overhead |
| ------- | --------------- |
| Level 1 | 63%             |
| Level 3 | 52%             |
| Level 5 | 70%             |

The OpenMP runtime (libgomp) dominates instruction count.

This directly explains why enabling OpenMP degraded performance in qr-UOV.

---

## 2. Actual Computational Hotspots

After excluding OpenMP overhead, the true hotspots are:

* MATRIX_MUL_* functions (9–13%)
* MATRIX_MUL_ADD_* functions (3–5%)
* Expand_pk (4–6%)

These matrix operations represent the real optimization targets.

---

## 3. Why AVX2 Did Not Improve Performance

AVX2 was already enabled in the baseline build via:

```
-march=native
```

Since SIMD support was already active, explicitly adding `-mavx2` does not provide additional gains.

---

## 4. Why LUT Provided Limited Improvement

* LUT reduces arithmetic cost inside MATRIX_MUL operations.
* However, the table size (~16 KB) introduces cache pressure.
* Arithmetic was already optimized with AVX2.
* Resulting average gain: ~2.3%.

---

# Final Interpretation

For qr-UOV:

* OpenMP is counterproductive due to excessive runtime overhead.
* AVX2 is already fully utilized in the baseline.
* The true optimization opportunities lie in matrix multiplication routines.
* LUT provides only marginal gains due to memory trade-offs.

---


