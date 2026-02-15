

# Multiplication LUT Results – qr-UOV

---

# LUT Implementation Details
```c
// Table size
static const Fq Fq_mul_table[127][127];

// Memory usage:
// 127 × 127 = 16,129 entries (~16 KB)
```

Comparison:

* MAYO GF(16): 16 × 16 = 256 bytes
* qr-UOV GF(127): 127 × 127 ≈ 16 KB

The qr-UOV lookup table is significantly larger and may introduce cache pressure.

---

# Detailed Results

## Level 1

```
No LUT:   1.355s
With LUT: 1.335s

Improvement: +1.5%
```

### Detailed Runs

| Run | No LUT | With LUT |
| --- | ------ | -------- |
| 1   | 1.41s  | 1.34s    |
| 2   | 1.36s  | 1.31s    |
| 3   | 1.34s  | 1.32s    |
| 4   | 1.33s  | 1.33s    |
| 5   | 1.56s  | 1.34s    |
| 6   | 1.43s  | 1.35s    |
| 7   | 1.37s  | 1.36s    |
| 8   | 1.35s  | 1.31s    |
| 9   | 1.34s  | 1.31s    |
| 10  | 1.35s  | 1.34s    |

---

## Level 3

```
No LUT:   1.360s
With LUT: 1.335s

Improvement: +1.9%
```

### Detailed Runs

| Run | No LUT | With LUT |
| --- | ------ | -------- |
| 1   | 1.33s  | 1.36s    |
| 2   | 1.34s  | 1.32s    |
| 3   | 1.39s  | 1.31s    |
| 4   | 1.37s  | 1.33s    |
| 5   | 1.39s  | 1.32s    |
| 6   | 1.36s  | 1.40s    |
| 7   | 1.36s  | 1.40s    |
| 8   | 1.34s  | 1.32s    |
| 9   | 1.37s  | 1.38s    |
| 10  | 1.35s  | 1.34s    |

---

## Level 5

```
No LUT:   1.380s
With LUT: 1.335s

Improvement: +3.4%
```

### Detailed Runs

| Run | No LUT | With LUT |
| --- | ------ | -------- |
| 1   | 1.39s  | 1.34s    |
| 2   | 1.44s  | 1.32s    |
| 3   | 1.37s  | 1.35s    |
| 4   | 1.35s  | 1.36s    |
| 5   | 1.43s  | 1.32s    |
| 6   | 1.42s  | 1.35s    |
| 7   | 1.45s  | 1.33s    |
| 8   | 1.37s  | 1.39s    |
| 9   | 1.34s  | 1.32s    |
| 10  | 1.35s  | 1.32s    |

---

# Summary

| Level       | No LUT     | With LUT   | Improvement |
| ----------- | ---------- | ---------- | ----------- |
| 1           | 1.355s     | 1.335s     | +1.5%       |
| 3           | 1.360s     | 1.335s     | +1.9%       |
| 5           | 1.380s     | 1.335s     | +3.4%       |
| **Average** | **1.365s** | **1.335s** | **+2.3%**   |

---

# Analysis

## Why Is the Improvement Small?

1. AVX2 is already enabled via `-march=native`, making multiplication relatively fast.
2. The LUT occupies ~16 KB, which increases cache pressure.
3. q = 127 is not a power of two, making arithmetic operations more complex than GF(16).

---

# Comparison with MAYO

| Scheme | Field   | LUT Size  | Average Gain |
| ------ | ------- | --------- | ------------ |
| MAYO   | GF(16)  | 256 bytes | +36%         |
| qr-UOV | GF(127) | ~16 KB    | +2.3%        |

The smaller field in MAYO makes LUT highly efficient.
In qr-UOV, the larger field reduces LUT effectiveness due to memory overhead.

---

# Practical Recommendation

The LUT provides a modest but consistent improvement:

* Average gain: +2.3%
* Maximum gain: +3.4% (Level 5)
* Memory cost: ~16 KB

Use is optional and depends on memory constraints and performance requirements.

---

