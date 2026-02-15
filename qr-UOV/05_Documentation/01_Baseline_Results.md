

# qr-UOV Baseline Results


---

# Build Configuration

```
Compiler: GCC 11.4.0
Flags: -march=native -mtune=native -O3 -fopenmp
```

Note:
`-march=native` automatically enables AVX2 if supported by the CPU.

---

# Detailed Measurements

## Level 1 (NIST Level 1)

```
Run 1:  1.36s    Run 6:  1.36s
Run 2:  1.33s    Run 7:  1.35s
Run 3:  1.34s    Run 8:  1.34s
Run 4:  1.38s    Run 9:  1.41s
Run 5:  1.34s    Run 10: 1.39s

Median: 1.355s
```

---

## Level 3 (NIST Level 3)

```
Run 1:  1.33s    Run 6:  1.35s
Run 2:  1.33s    Run 7:  1.35s
Run 3:  1.33s    Run 8:  1.34s
Run 4:  1.33s    Run 9:  1.36s
Run 5:  1.33s    Run 10: 1.35s

Median: 1.335s
```

---

## Level 5 (NIST Level 5)

```
Run 1:  1.35s    Run 6:  1.33s
Run 2:  1.39s    Run 7:  1.39s
Run 3:  1.34s    Run 8:  1.34s
Run 4:  1.34s    Run 9:  1.35s
Run 5:  1.33s    Run 10: 1.35s

Median: 1.345s
```

---

# Summary

| Level | Median Time | Notes                            |
| ----- | ----------- | -------------------------------- |
| 1     | 1.355s      | AVX2 enabled via `-march=native` |
| 3     | 1.335s      | Very consistent timing           |
| 5     | 1.345s      | Comparable to other levels       |

---

# Observations

* Execution time is stable across security levels (~1.34–1.36s).
* AVX2 is implicitly enabled through `-march=native`.
* OpenMP is included in the baseline build.
* Runtime does not significantly increase with security level.

This indicates that qr-UOV’s workload scales differently compared to MAYO, as execution time remains nearly constant across levels.

---



