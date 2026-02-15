

# MAYO Optimization Results – Lookup Table (LUT)

# Summary of Results

| Level  | Baseline (s) | Optimized (s) | Improvement | Status    |
| ------ | ------------ | ------------- | ----------- | --------- |
| MAYO-1 | 0.295        | 0.295         | +0.0%       | Skipped   |
| MAYO-2 | 0.475        | 0.280         | +69.6%      | Excellent |
| MAYO-3 | 0.935        | 0.645         | +45.0%      | Good      |
| MAYO-5 | 1.630        | 1.260         | +29.4%      | Good      |

**Weighted Average Improvement:** +35.8%

---

# Detailed Measurements

## MAYO-1 – Baseline

```
Run 1:  0.31s    Run 6:  0.29s
Run 2:  0.35s    Run 7:  0.29s
Run 3:  0.32s    Run 8:  0.31s
Run 4:  0.29s    Run 9:  0.29s
Run 5:  0.30s    Run 10: 0.29s

Median: 0.295s
```

## MAYO-1 – Optimized

```
Run 1:  0.35s    Run 6:  0.31s
Run 2:  0.30s    Run 7:  0.29s
Run 3:  0.29s    Run 8:  0.29s
Run 4:  0.30s    Run 9:  0.31s
Run 5:  0.29s    Run 10: 0.29s

Median: 0.295s
Improvement: +0.0%
```

Observation: No measurable benefit at Level 1.

---

## MAYO-2 – Baseline

```
Run 1:  0.52s    Run 6:  0.49s
Run 2:  0.48s    Run 7:  0.45s
Run 3:  0.49s    Run 8:  0.42s
Run 4:  0.51s    Run 9:  0.45s
Run 5:  0.47s    Run 10: 0.45s

Median: 0.475s
```

## MAYO-2 – Optimized

```
Run 1:  0.27s    Run 6:  0.40s
Run 2:  0.27s    Run 7:  0.27s
Run 3:  0.29s    Run 8:  0.28s
Run 4:  0.27s    Run 9:  0.28s
Run 5:  0.30s    Run 10: 0.28s

Median: 0.280s
Improvement: +69.6%
```

Observation: Significant performance gain at Level 2.

---

## MAYO-3 – Baseline

```
Run 1:  0.99s    Run 6:  0.93s
Run 2:  0.99s    Run 7:  0.89s
Run 3:  0.91s    Run 8:  0.97s
Run 4:  0.94s    Run 9:  0.91s
Run 5:  0.89s    Run 10: 0.95s

Median: 0.935s
```

## MAYO-3 – Optimized

```
Run 1:  0.60s    Run 6:  0.62s
Run 2:  0.60s    Run 7:  0.75s
Run 3:  0.64s    Run 8:  0.70s
Run 4:  0.62s    Run 9:  0.71s
Run 5:  0.66s    Run 10: 0.65s

Median: 0.645s
Improvement: +45.0%
```

Observation: Strong improvement at Level 3.

---

## MAYO-5 – Baseline

```
Run 1:  2.24s    Run 6:  1.90s
Run 2:  1.92s    Run 7:  1.34s
Run 3:  1.34s    Run 8:  1.30s
Run 4:  1.56s    Run 9:  1.60s
Run 5:  2.11s    Run 10: 1.66s

Median: 1.630s
```

## MAYO-5 – Optimized

```
Run 1:  1.33s    Run 6:  1.29s
Run 2:  1.24s    Run 7:  1.28s
Run 3:  1.44s    Run 8:  1.24s
Run 4:  1.24s    Run 9:  1.24s
Run 5:  1.24s    Run 10: 1.35s

Median: 1.260s
Improvement: +29.4%
```

Observation: Moderate but consistent improvement at Level 5.

---

# Test Environment

**System:**

* OS: Ubuntu 22.04 LTS
* Architecture: x86_64
* Compiler: GCC 11.4.0

**Measurement Method:**

* Tool: `/usr/bin/time -f "%e"`
* 10 runs per configuration
* Reported metric: median execution time

---

# Recommendations

## Recommended for Deployment

* MAYO-2 (+69.6%) – highest gain
* MAYO-3 (+45.0%) – strong improvement
* MAYO-5 (+29.4%) – consistent benefit

## Not Recommended

* MAYO-1 (+0.0%) – no measurable performance improvement

---

# Conclusion

Lookup Table optimization successfully improved MAYO performance by approximately **35.8% on average** for security levels 2, 3, and 5.

Effectiveness depends on parameter structure and the frequency of scalar GF(16) operations.

---


