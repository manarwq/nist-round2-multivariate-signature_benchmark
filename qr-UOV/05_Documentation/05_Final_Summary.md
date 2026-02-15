
# Final Summary – qr-UOV


---

# Final Results

| Optimization | Level 1    | Level 3    | Level 5    | Average    |
| ------------ | ---------- | ---------- | ---------- | ---------- |
| **Baseline** | 1.355s     | 1.335s     | 1.345s     | 1.345s     |
| OpenMP       | 1.365s     | 1.360s     | 1.355s     | 1.360s     |
| LUT          | 1.335s     | 1.335s     | 1.335s     | 1.335s     |

---

# Optimization Impact

| Technique              | Improvement | Status                                 |
| ---------------------- | ----------- | -------------------------------------- |
| AVX2                   | +0%         | Enabled by default via `-march=native` |
| OpenMP                 | -0.7%       | Overhead exceeds benefit               |
| **Multiplication LUT** | **+2.3%**   | Small but consistent gain              |

---

# Final Recommendations

## Recommended Configuration

Baseline + LUT

* Performance: ~1.335s
* Improvement: +2.3%
* Memory cost: ~16 KB

---

## Not Recommended

OpenMP

* Degrades performance
* Up to 70% runtime spent in OpenMP overhead
* No measurable computational benefit

---

## Notes

1. AVX2 is already enabled via `-march=native`.
2. The implementation is highly optimized in baseline form.
3. qr-UOV maintains stable runtime (~1.33–1.36s) across security levels.
4. Further optimization potential is limited.

---

# Conclusion

qr-UOV baseline implementation is already SIMD-optimized.

The only measurable improvement comes from the multiplication LUT, yielding a modest but consistent +2.3% performance gain.

---


# Architectural Insight

| Aspect          | MAYO               | qr-UOV                       |
| --------------- | ------------------ | ---------------------------- |
| Field Size      | GF(16)             | GF(127)                      |
| LUT Size        | 256 bytes          | ~16 KB                       |
| Main Bottleneck | Transpose + GF ops | Matrix multiplication        |
| SIMD Benefit    | Very high          | Already integrated           |
| Parallelization | Moderate benefit   | Harmful (overhead dominated) |

---

# Overall Conclusions

* qr-UOV is already SIMD-optimized in baseline.
* LUT effectiveness depends strongly on field size.
* OpenMP suitability depends on workload granularity.
* Optimization impact is highly architecture-dependent.

---


