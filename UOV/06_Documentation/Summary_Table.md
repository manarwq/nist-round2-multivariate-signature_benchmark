

---

# Results Summary – All Phases (UOV)

This document summarizes the performance results of all evaluated optimization phases for UOV across the three NIST categories tested.

---

## 1) Complete Performance Comparison

### Category I (GF16) – NIST Level 1

| Phase | Configuration   | Median Time |   vs Baseline | Status                   |
| ----: | --------------- | ----------: | ------------: | ------------------------ |
|     1 | Baseline        |      1.560s |             – | Baseline                 |
|     2 | AVX2 (explicit) |      1.560s |  1.00× (0.0%) | ≈ Same (already enabled) |
|     4 | LUT             |      1.450s | 1.08× (+7.6%) | ✅ Improved               |
|     5 | OpenMP flag     |      1.450s | 1.08× (+7.6%) | ✅ Improved               |

**Note:** Phase 2 shows no improvement because the baseline build already enabled AVX2 (e.g., via `-march=native`).

---

### Category III (GF256) – NIST Level 3

| Phase | Configuration   | Median Time |    vs Baseline | Status                   |
| ----: | --------------- | ----------: | -------------: | ------------------------ |
|     1 | Baseline        |      8.470s |              – | Baseline                 |
|     2 | AVX2 (explicit) |      8.470s |   1.00× (0.0%) | ≈ Same (already enabled) |
|     4 | LUT             |      7.365s | 1.15× (+15.0%) | ✅ Improved               |
|     5 | OpenMP flag     |      7.370s | 1.15× (+14.9%) | ✅ Improved               |

---

### Category V (GF256) – NIST Level 5

| Phase | Configuration   | Median Time |   vs Baseline | Status                   |
| ----: | --------------- | ----------: | ------------: | ------------------------ |
|     1 | Baseline        |     23.495s |             – | Baseline                 |
|     2 | AVX2 (explicit) |     23.495s |  1.00× (0.0%) | ≈ Same (already enabled) |
|     4 | LUT             |     23.215s | 1.01× (+1.2%) | ≈ No meaningful change   |
|     5 | OpenMP flag     |     21.610s | 1.09× (+8.7%) | ✅ Improved               |

---

## 2) Overall Summary

### Improvement Range

* **Minimum:** +1.2% (Category V with LUT)
* **Maximum:** +15.0% (Category III with LUT)
* **Typical:** ~8–10% improvement (excluding AVX2)

### Best Configurations (Per Category)

1. **Category I:** LUT or OpenMP flag (+7.6%)
2. **Category III:** LUT or OpenMP flag (~+15%)
3. **Category V:** OpenMP flag (+8.7%)

---

## 3) Technique Effectiveness Ranking

| Technique       | Cat I | Cat III | Cat V | Average | Notes                            |
| --------------- | ----: | ------: | ----: | ------: | -------------------------------- |
| AVX2 (explicit) |  0.0% |    0.0% |  0.0% |    0.0% | Baseline already used AVX2       |
| LUT             | +7.6% |  +15.0% | +1.2% |   +7.9% | ✅ Effective (category-dependent) |
| OpenMP flag     | +7.6% |  +14.9% | +8.7% |  +10.4% | ✅Most consistent overall        |

---

## 4) Statistical Confidence (Variance Notes)

### Phase 1 – Baseline

* Category I: 1.49–1.66s (**~11% range**)
* Category III: 7.65–9.05s (**~18% range**)
* Category V: 22.69–24.32s (**~7% range**)

### Phase 2 – AVX2

* Identical to Phase 1 (same effective SIMD configuration)

### Phase 4 – LUT

* Category I: 1.44–1.46s (**~1.4% range**) → very stable
* Category III: 7.31–7.41s (**~1.4% range**) → very stable
* Category V: 21.37–27.57s (**~29% range**) → less stable

### Phase 5 – OpenMP flag

* Category I: 1.44–1.48s (**~2.8% range**) → stable
* Category III: 7.31–7.41s (**~1.4% range**) → very stable
* Category V: 21.37–27.57s (**~29% range**) → less stable

---

## 5) Key Insights

### Why AVX2 Showed No Improvement

The baseline build already enabled AVX2 (e.g., via `-march=native`).
This is not a failure; it confirms the baseline was already well optimized at the SIMD level.

### What Actually Improved Performance

1. **LUT:** Reduced cost of finite-field operations (strongest at Category III).
2. **OpenMP flag:** Produced the most consistent improvements across categories (even when true multi-thread scaling is limited).

---




