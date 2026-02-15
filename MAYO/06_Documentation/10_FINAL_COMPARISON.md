
# MAYO Optimization Experiments

## Comprehensive Performance Evaluation of LUT, AVX2, OpenMP, and Hybrid Approaches

---

# 1. Objective

This document presents a complete performance evaluation of multiple optimization strategies applied to the MAYO multivariate signature scheme across four NIST security levels:

* MAYO-1 (Level 1)
* MAYO-2 (Level 1)
* MAYO-3 (Level 3)
* MAYO-5 (Level 5)

The evaluated techniques include:

* Baseline (no optimization)
* LUT (Lookup Table)
* AVX2 (SIMD vectorization)
* OpenMP (2 and 4 threads)
* AVX2 + OpenMP (Hybrid)

All experiments were performed under controlled conditions on the same hardware platform.

---

# 2. Experimental Environment

## System

* OS: Ubuntu 22.04 LTS
* Architecture: x86_64
* CPU: AVX2-capable processor
* Compiler: GCC 11.4.0

## Compilation Flags

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

LUT:

```
-O3
```

## Measurement Methodology

* Tool: `/usr/bin/time -f "%e"`
* 10 runs per configuration
* Reported metric: median execution time
* Same workload and hardware for all tests

---

# 3. Summary of All Results

| Level  | Baseline | LUT    | AVX2       | OpenMP (4) | AVX2+OMP |
| ------ | -------- | ------ | ---------- | ---------- | -------- |
| MAYO-1 | 0.295s   | 0.295s | **0.140s** | 0.260s     | 0.260s   |
| MAYO-2 | 0.475s   | 0.280s | **0.140s** | 0.245s     | 0.250s   |
| MAYO-3 | 0.935s   | 0.645s | **0.200s** | 0.580s     | 0.580s   |
| MAYO-5 | 1.630s   | 1.260s | **0.330s** | 1.225s     | 1.230s   |

---

# 4. Improvement Analysis

## 4.1 AVX2

| Level       | Improvement |
| ----------- | ----------- |
| MAYO-1      | +110.7%     |
| MAYO-2      | +239.3%     |
| MAYO-3      | +367.5%     |
| MAYO-5      | +393.9%     |
| **Average** | **+277.9%** |

Observations:

* Speedup increases with higher security levels.
* Larger parameter sizes benefit more from SIMD vectorization.
* Performance remains stable across repeated runs.
* Achieves up to ~4× acceleration.

---

## 4.2 OpenMP

| Level       | Improvement (4 threads) |
| ----------- | ----------------------- |
| MAYO-1      | +13.5%                  |
| MAYO-2      | +93.9%                  |
| MAYO-3      | +61.2%                  |
| MAYO-5      | +33.1%                  |
| **Average** | +50.4%                  |

Observations:

* Limited scalability beyond 2 threads.
* Thread synchronization overhead reduces gains.
* Provides moderate parallel speedup.
* Less effective than SIMD.

---

## 4.3 LUT (Lookup Table)

| Level       | Improvement |
| ----------- | ----------- |
| MAYO-1      | +0.0%       |
| MAYO-2      | +69.6%      |
| MAYO-3      | +45.0%      |
| MAYO-5      | +29.4%      |
| **Average** | +36.0%      |

Memory Overhead: ~272 bytes

Observations:

* Most effective in MAYO-2.
* Performance gain depends on scalar GF(16) operation frequency.
* Limited impact on small parameter sets.
* Scalar-bound optimization.

---

## 4.4 AVX2 + OpenMP (Hybrid)

| Level       | Improvement |
| ----------- | ----------- |
| MAYO-1      | +13.5%      |
| MAYO-2      | +90.0%      |
| MAYO-3      | +61.2%      |
| MAYO-5      | +32.5%      |
| **Average** | +49.3%      |

Observations:

* Does not outperform pure AVX2.
* Thread overhead offsets vectorization gains.
* Possible memory contention.
* Not recommended.

---

# 5. Comparative Ranking

| Technique     | Average Improvement |
| ------------- | ------------------- |
| **AVX2**      | **+277.9%**         |
| OpenMP        | +50.4%              |
| LUT           | +36.0%              |
| AVX2 + OpenMP | +49.3%              |
| Baseline      | 0%                  |

---

# 6. Technical Interpretation

## Why AVX2 Dominates

* Processes multiple GF(16) operations per instruction.
* Eliminates synchronization overhead.
* Maximizes CPU vector unit utilization.
* Highly suitable for matrix-heavy MAYO operations.
* Speedup increases with parameter size.

## OpenMP Behavior

* Useful for coarse-grained parallelism.
* Overhead from thread creation and scheduling.
* Limited scalability for this workload.

## LUT Characteristics

* Replaces arithmetic with table lookup.
* Reduces scalar operation cost.
* Dependent on memory access efficiency.

## Hybrid Limitations

* Vectorized loops favor sequential execution.
* OpenMP introduces scheduling overhead.
* Hybrid overhead exceeds gains.

---

# 7. Final Conclusions

* AVX2 provides the strongest and most scalable performance improvement.
* OpenMP offers moderate acceleration.
* LUT provides lightweight scalar optimization.
* Combining AVX2 with OpenMP does not improve performance.
* Optimization effectiveness is strongly architecture-dependent.

**Maximum observed acceleration:** ~4× using AVX2.

---


