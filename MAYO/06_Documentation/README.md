
# MAYO Optimization Documentation – Complete Package

This directory contains the complete documentation for the MAYO optimization project.

---

# Directory Contents

| #  | File                           | Description                          |
| -- | ------------------------------ | ------------------------------------ |
| 1  | `01_Optimization_Results.md`   | LUT optimization results             |
| 2  | `02_Profiling_Results.md`      | Performance profiling results        |
| 3  | `03_Profiling_Code.sh`         | Profiling scripts                    |
| 4  | `04_Optimization_Test_Code.sh` | LUT testing scripts                  |
| 5  | `05_Optimized_Code.h`          | Optimized implementation (LUT)       |
| 6  | `06_Original_Code.h`           | Original implementation              |
| 7  | `07_How_To_Apply.md`           | Optimization deployment guide        |
| 8  | `08_AVX2_OpenMP_Results.md`    | AVX2 and OpenMP benchmarking results |
| 9  | `09_AVX2_OpenMP_Code.sh`       | AVX2 and OpenMP test scripts         |
| 10 | `10_FINAL_COMPARISON.md`       | Comprehensive final comparison       |

---

# Quick Summary

## Average Performance Improvements

| Technique  | Average Improvement | Rank |
| ---------- | ------------------- | ---- |
| **AVX2**   | **+277.9%**         | 1    |
| **OpenMP** | **+50.4%**          | 2    |
| **LUT**    | **+36.0%**          | 3    |

## Recommendation

* Use **AVX2** when supported → up to ~3.8× faster
* Use **OpenMP** as a fallback → ~1.5× faster
* Use **LUT** for lightweight scalar optimization → ~1.4× faster

---

# How to Use This Documentation

## To Review Experimental Results

* `01_Optimization_Results.md` → LUT results
* `08_AVX2_OpenMP_Results.md` → AVX2 & OpenMP results
* `10_FINAL_COMPARISON.md` → Full comparative analysis

## To Understand Performance Bottlenecks

Read:

* `02_Profiling_Results.md`

## To Reproduce the Experiments

Use:

* `03_Profiling_Code.sh` → Profiling scripts
* `04_Optimization_Test_Code.sh` → LUT testing
* `09_AVX2_OpenMP_Code.sh` → AVX2 and OpenMP testing

## To Apply the Optimizations

Follow:

* `07_How_To_Apply.md`

---

# Notable Results

* **AVX2:** Up to +393.9% improvement (MAYO-5)
* **OpenMP:** Up to +93.9% improvement (MAYO-2)
* **LUT:** Up to +69.6% improvement (MAYO-2)

---

# Important Notes

1. AVX2 requires a modern CPU with SIMD support (2013 or newer).
2. OpenMP works on any multi-core processor.
3. LUT requires approximately 272 bytes of additional memory.
4. Combining AVX2 and OpenMP is not recommended, as it reduces efficiency.

---



