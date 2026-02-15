# qr-UOV Optimization Documentation

---

## Documentation Files

| File | Description |
|------|-------------|
| `01_Baseline_Results.md` | Baseline performance measurements |
| `02_OpenMP_Test.md` | OpenMP parallelization test |
| `03_LUT_Results.md` | Multiplication lookup table test |
| `04_Profiling_Results.md` | Callgrind profiling analysis |
| `05_Final_Summary.md` | Complete summary and comparison |

---

##  Quick Results
```
Best Configuration: Baseline + Multiplication LUT
Performance: 1.335s (average across all levels)
Improvement: +2.3%
```

---

## Key Findings

1. ✅ **AVX2** - Already enabled via -march=native
2. ❌ **OpenMP** - 70% overhead, no benefit
3. ✅ **LUT** - Small but consistent +2.3% improvement

---

## Architecture Insights

- **q=127** (not power of 2)
- **16 KB** multiplication table
- **Already highly optimized** baseline
- **OpenMP overhead dominates** (70% of execution time!)

---

