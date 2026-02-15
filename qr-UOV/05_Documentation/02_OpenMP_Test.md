

# OpenMP Results – qr-UOV

## Performance Comparison

### Level 1

| Configuration   | Time       | Change    |
| --------------- | ---------- | --------- |
| No OpenMP       | 1.360s     | Baseline  |
| **With OpenMP** | **1.365s** | **-0.4%** |

---

### Level 3

| Configuration   | Time       | Change    |
| --------------- | ---------- | --------- |
| No OpenMP       | 1.335s     | Baseline  |
| **With OpenMP** | **1.360s** | **-1.8%** |

---

### Level 5

| Configuration   | Time       | Change    |
| --------------- | ---------- | --------- |
| No OpenMP       | 1.345s     | Baseline  |
| **With OpenMP** | **1.355s** | **-0.7%** |

---

# Conclusion

OpenMP does not improve performance in qr-UOV.

In all tested security levels, enabling OpenMP resulted in a slight performance degradation.

---

# Profiling Analysis (Callgrind)

## OpenMP Overhead

```
Level 1: 63% of runtime spent in libgomp (OpenMP runtime)
Level 3: 52% of runtime spent in libgomp
Level 5: 70% of runtime spent in libgomp
```

This indicates that thread management overhead dominates execution time.

---

## Actual Computational Hotspots

Real computational bottlenecks (excluding OpenMP overhead):

* MATRIX_MUL_MxV_VxV:     9–13%
* Expand_pk:              4–6%
* MATRIX_MUL_ADD_MxV_VxM: 3–5%

---

# Interpretation

The overhead introduced by OpenMP exceeds any potential benefit from parallelization.

Possible reasons:

1. The workload per parallel region is too small.
2. qr-UOV’s core operations are already highly optimized.
3. The implementation does not expose sufficient coarse-grained parallelism.
4. Thread scheduling and synchronization costs dominate execution time.

---

# Final Statement

For qr-UOV, OpenMP is not recommended.

The implementation performs better in single-threaded mode with AVX2 enabled via `-march=native`.

---


