
# MAYO Performance Optimization Results

## AVX2 vs OpenMP vs AVX2+OpenMP

---

# Overview

This document summarizes the performance evaluation of different optimization techniques applied to the **MAYO multivariate signature scheme**, including:

* Baseline (no optimization)
* AVX2 (SIMD vectorization)
* OpenMP (multi-threading with 2 and 4 threads)
* AVX2 + OpenMP (combined approach)

All benchmarks were conducted under controlled conditions on the same hardware platform.

---

# Summary of Results

| Level  | Baseline | AVX2          | OpenMP (2) | OpenMP (4) | AVX2+OMP |
| ------ | -------- | ------------- | ---------- | ---------- | -------- |
| MAYO-1 | 0.295s   | **0.140s** 🏆 | 0.260s     | 0.260s     | 0.260s   |
| MAYO-2 | 0.475s   | **0.140s** 🏆 | 0.255s     | 0.245s     | 0.250s   |
| MAYO-3 | 0.935s   | **0.200s** 🏆 | 0.580s     | 0.580s     | 0.580s   |
| MAYO-5 | 1.630s   | **0.330s** 🏆 | 1.225s     | 1.225s     | 1.230s   |

---

# Detailed Performance Analysis

## AVX2 Optimization

AVX2 consistently delivers the strongest performance improvements across all parameter sets.

| Level       | Improvement    |
| ----------- | -------------- |
| MAYO-1      | +110.7%        |
| MAYO-2      | +239.3%        |
| MAYO-3      | +367.5%        |
| MAYO-5      | +393.9%        |
| **Average** | **+277.9%** 🏆 |

### Why AVX2 Performs Best

AVX2 (SIMD – Single Instruction Multiple Data):

* Processes multiple GF(16) operations per instruction
* Utilizes vector execution units efficiently
* Eliminates thread management overhead
* Well-suited for matrix-heavy computations in MAYO

---

## OpenMP Optimization

OpenMP provides moderate performance gains but remains significantly behind AVX2.

| Level       | OpenMP (4 threads) Improvement |
| ----------- | ------------------------------ |
| MAYO-1      | +13.5%                         |
| MAYO-2      | +93.9%                         |
| MAYO-3      | +61.2%                         |
| MAYO-5      | +33.1%                         |
| **Average** | **+50.4%**                     |

### Observations

* Increasing threads from 2 → 4 yields minimal improvement.
* Thread creation and synchronization overhead limits scalability.
* MAYO’s internal structure may not be highly parallelizable at this granularity.

---

## AVX2 + OpenMP (Combined)

Contrary to expectations, combining AVX2 with OpenMP does not improve performance.

In most cases, it performs worse than AVX2 alone.

### Why the Combination Fails

* AVX2 relies on efficient sequential vector processing.
* OpenMP introduces thread scheduling and synchronization overhead.
* Memory contention and vector pipeline interference may occur.
* Result: added overhead outweighs potential parallel gains.

---

# Final Comparison

| Technique          | Average Improvement |
| ------------------ | ------------------- |
| **AVX2**           | **+277.9%** 🏆      |
| OpenMP (4 threads) | +50.4%              |
| OpenMP (2 threads) | +48.5%              |
| AVX2 + OpenMP      | +49.3%              |

---

# Recommendations

## Best Choice

**Use AVX2 only (if supported by the CPU).**

* ~278% average performance improvement
* Most consistent results across all levels
* No thread overhead

---

## Alternative

**Use OpenMP if AVX2 is unavailable.**

* ~50% improvement on average
* Moderate scalability
* Platform-independent

---

## Not Recommended

**Avoid combining AVX2 with OpenMP.**

* No additional benefit
* May degrade performance
* Adds unnecessary complexity

---

# Benchmark Environment

### System

* OS: Ubuntu 22.04 LTS
* Architecture: x86_64
* CPU: AVX2-capable processor
* Compiler: GCC 11.4.0

### Compilation Flags

AVX2:

```
-O3 -mavx2 -march=native
```

OpenMP:

```
-O3 -fopenmp
```

AVX2 + OpenMP:

```
-O3 -mavx2 -fopenmp -march=native
```

---

# Measurement Methodology

* Tool: `/usr/bin/time -f "%e"`
* Repetitions: 10 runs per configuration
* Reported metric: Median execution time

All tests were performed on the same hardware platform under identical conditions.

---

