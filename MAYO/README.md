# MAYO Optimization Analysis

## Overview
MAYO is a multivariate signature scheme selected for NIST PQC standardization.

---

## Directory Structure

### 01_Baseline
**Source**: NIST Reference Implementation
**Description**: Original unoptimized implementation
- Plain C code
- Standard operations without SIMD
- Baseline for all comparisons

### 02_Profiling
**Description**: Performance analysis and bottleneck identification
- Profiling results
- Hotspot analysis

### 03_AVX2_Optimization
**Source**: NIST Additional Implementations/AVX2
**Our Work**: Testing and benchmarking
- Hand-coded AVX2 intrinsics from NIST
- SIMD-optimized Galois field arithmetic
- Performance: ~3.78× average speedup

### 04_LUT_Optimization
**Source**: Our Implementation
**Description**: Custom lookup table optimization for GF(16)

**Our Work**:
- `05_Optimized_Code.h` - LUT-based implementation
- `06_Original_Code.h` - Original code for comparison
- `gf16_mul_lut[16][16]` - Multiplication lookup table

**Performance**: 1.44× average speedup

**Implementation Details**:
```c
// GF(16) Multiplication Lookup Table
// Generated for x^4 + x + 1
static const uint8_t gf16_mul_lut[16][16] = {
// 256 bytes total
// O(1) multiplication instead of O(log n)
};
```

### 05_OpenMP_Optimization
**Description**: Multi-threading testing and benchmarking
- OpenMP pragma testing
- Parallel execution analysis

### 06_Documentation
Complete analysis results and methodology.

---

## Our Contributions

 **LUT Implementation**: Custom GF(16) multiplication tables
 **Benchmarking**: Systematic testing of all variants
 **Analysis**: Performance comparison and documentation

---

## Performance Summary

| Variant | Source | Our Work | Speedup |
|---------|--------|----------|---------|
| Baseline | NIST Reference | Testing | 1.00× |
| AVX2 | NIST Additional | Testing | 3.78× |
| **LUT** | **Our Implementation** | **** | **1.44×** |

---

## Build Instructions

### LUT Version (Our Implementation)
```bash
cd 04_LUT_Optimization/src
make
```

### AVX2 Version (NIST + Our Testing)
```bash
cd 03_AVX2_Optimization/src
make
```


