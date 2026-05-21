# MAYO ARM64 Evaluation

## Overview

ARM64 evaluation of the MAYO post-quantum signature scheme using QEMU user-mode emulation.
This evaluation covers 13 optimization configurations across 4 parameter sets, with focus
on both performance and implementation security (cache-timing resistance, constant-time behavior).

**Key finding:** MAYO signing is dominated by data reorganization (transpose_16x16_nibbles:
36–80% of execution time), not field arithmetic. This means field-level optimizations have
limited impact on Sign performance, while security measures add overhead without reducing
the primary bottleneck.

## Environment

| Parameter | Value |
|-----------|-------|
| Host OS | Ubuntu 22.04, Intel Core i7-10510U @ 1.80GHz (2 vCPUs) |
| Emulator | QEMU aarch64 v6.2.0 (user-mode) |
| Compiler | aarch64-linux-gnu-gcc 11.4.0 |
| Source | https://github.com/PQCMayo/MAYO-C |
| Metric | Best of 3 runs, 100 iterations per run |

## Parameter Sets (4 total)

All parameter sets operate over GF(16).

| Scheme | n | m | o | Signature | Public Key | Security |
|--------|---|---|---|-----------|------------|----------|
| MAYO-1 | 66 | 64 | 8 | 321 B | 1.2 KB | NIST-1 |
| MAYO-2 | 78 | 64 | 18 | 180 B | 2.7 KB | NIST-1 |
| MAYO-3 | 99 | 96 | 10 | 577 B | 2.2 KB | NIST-3 |
| MAYO-5 | 133 | 128 | 12 | 838 B | 5.5 KB | NIST-5 |

## Configurations (13 total)

### What each configuration does

| Config | GF(16) Method | CT Branch-free | Cache-safe | Notes |
|--------|--------------|----------------|------------|-------|
| Ref | Bitwise (volatile blocker) | Partial | No | Baseline |
| LUT | Standard lookup table | Partial | No | Secret index exposed |
| Obliv.LUT | Oblivious LUT | Partial | Yes | Uniform memory access |
| CT | Bitwise, no volatile | Yes | No | Removes volatile blocker → faster |
| CT+LUT | Standard LUT + CT | Yes | No | CT branches, cache-vulnerable |
| CT+Obliv.LUT | Oblivious LUT + CT | Yes | Yes | **Most secure** |
| NEON | ARM NEON SIMD | Partial | No | No benefit on this platform |
| OpenMP | Thread parallel | Partial | No | No benefit on 2-core platform |
| O3 | Bitwise + -O3 | Partial | No | Compiler optimization only |
| LUT+O3 | Standard LUT + -O3 | Partial | No | **Best raw performance** |
| CT+O3 | CT + -O3 | Yes | No | Good balance |
| CT+LUT+O3 | Standard LUT + CT + -O3 | Yes | No | Fast but cache-vulnerable |
| CT+Obliv.LUT+O3 | Oblivious LUT + CT + -O3 | Yes | Yes | Secure but high overhead |

### Security notes

- **Ref**: Uses a `volatile` blocker to prevent compiler optimization of the CT comparison,
  which itself adds overhead. Cache-vulnerable due to non-oblivious GF(16) access.
- **CT**: Removes the volatile blocker, allowing compiler optimization → slightly faster than Ref.
- **Obliv.LUT**: Scans all 256 table entries unconditionally, hiding the secret index.
- **CT+Obliv.LUT**: Fully secure — branch-free AND cache-safe. Recommended for
  security-sensitive deployments despite 8–17% Sign overhead vs Ref.
- **LUT+O3 / CT+LUT+O3**: Best raw performance but cache-vulnerable (standard LUT
  exposes secret-dependent memory access patterns).

## Source Files

| File | Method | Cache-Safe |
|------|--------|------------|
| simple_arithmetic_original.h | Reference bitwise GF(16) | No |
| simple_arithmetic_lut_basic.h | Standard LUT (256 B) | No |
| simple_arithmetic_oblivious_lut.h | Oblivious LUT (256 B, full scan) | Yes |

## Build Instructions

### Prerequisites
```bash
sudo apt install gcc-aarch64-linux-gnu qemu-user cmake
```

### Step 1: Clone and prepare
```bash
git clone https://github.com/PQCMayo/MAYO-C
cd MAYO-C
mkdir build && cd build
```

### Step 2: Configure (choose one)

```bash
# Ref (baseline)
cmake .. -DMAYO_BUILD_TYPE=ref \
  -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DENABLE_TESTS=ON \
  -DMAYO_MARCH="-march=armv8-a" \
  -DENABLE_STRICT=OFF

# CT (constant-time, removes volatile blocker)
cmake .. -DMAYO_BUILD_TYPE=ref \
  -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DENABLE_TESTS=ON \
  -DMAYO_MARCH="-march=armv8-a" \
  -DENABLE_STRICT=OFF \
  -DENABLE_CT_TESTING=ON

# NEON
cmake .. -DMAYO_BUILD_TYPE=neon \
  -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DENABLE_TESTS=ON \
  -DMAYO_MARCH="-march=armv8-a+simd" \
  -DENABLE_STRICT=OFF

# O3 (add to any config above)
# append: -DCMAKE_C_FLAGS="-O3 -funroll-loops"

# LUT / Obliv.LUT
# Copy the desired header before cmake:
cp /path/to/simple_arithmetic_lut_basic.h src/simple_arithmetic.h        # LUT
cp /path/to/simple_arithmetic_oblivious_lut.h src/simple_arithmetic.h    # Obliv.LUT
```

### Step 3: Build and run
```bash
make -j$(nproc)

# Benchmark
qemu-aarch64 -L /usr/aarch64-linux-gnu ./test/mayo_bench MAYO-1 100
qemu-aarch64 -L /usr/aarch64-linux-gnu ./test/mayo_bench MAYO-2 100
qemu-aarch64 -L /usr/aarch64-linux-gnu ./test/mayo_bench MAYO-3 100
qemu-aarch64 -L /usr/aarch64-linux-gnu ./test/mayo_bench MAYO-5 100

# Memory measurement
/usr/bin/time -v qemu-aarch64 -L /usr/aarch64-linux-gnu \
    ./test/mayo_bench MAYO-1 100 2>&1 | grep "Maximum resident"
```

## Key Results Summary

Times in milliseconds (ms), best of 3 runs.

### Sign Performance (ms) — All Configurations
| Config | MAYO-1 | MAYO-2 | MAYO-3 | MAYO-5 | vs Ref |
|--------|--------|--------|--------|--------|--------|
| Ref | 11.1 | 8.0 | 29.5 | 72.9 | baseline |
| LUT | 16.7 | 9.1 | 29.3 | 59.5 | +50% / −18% |
| Obliv.LUT | 13.3 | 8.3 | 33.0 | 74.5 | +20% / +2% |
| CT | 10.9 | 8.2 | 29.2 | 70.2 | −2% to −4% |
| CT+LUT | 10.2 | 7.3 | 35.6 | 62.5 | −8% to −14% |
| CT+Obliv.LUT | 13.0 | 8.1 | 33.6 | 78.7 | +17% / +8% |
| NEON | 13.8 | 8.9 | 38.9 | 90.4 | worse |
| OpenMP | 10.9 | 8.0 | 29.8 | 69.2 | ~same |
| O3 | 10.8 | 7.8 | 28.7 | 67.1 | −2% to −8% |
| **LUT+O3** | **9.3** | **6.7** | **24.9** | **56.5** | **−16% to −23%** |
| CT+O3 | 10.8 | 7.4 | 28.5 | 66.7 | −3% to −9% |
| CT+LUT+O3 | 9.5 | 6.7 | 25.5 | 58.6 | −14% to −20% |
| CT+Obliv.LUT+O3 | 20.6 | 11.3 | 31.7 | 77.9 | +86% / +7% |

### Memory (RSS kB) — All Configurations
All configurations maintain ~8 MB implementation footprint (stable across all configs).

| Config | MAYO-1 | MAYO-2 | MAYO-3 | MAYO-5 |
|--------|--------|--------|--------|--------|
| Ref | 8,320 | 8,448 | 8,320 | 8,192 |
| LUT | 8,192 | 8,192 | 8,192 | 8,192 |
| Obliv.LUT | 8,192 | 8,192 | 8,192 | 8,192 |
| CT | 8,192 | 8,320 | 8,192 | 8,320 |
| CT+LUT | 8,192 | 8,320 | 8,192 | 8,192 |
| CT+Obliv.LUT | 8,320 | 8,320 | 8,192 | 8,064 |

Note: MAYO's ~8 MB footprint is significantly lower than UOV's 21–28 MB,
due to MAYO's seed-based public key compression.

## Deployment Recommendations

| Threat Model | Recommended Config | Reason |
|-------------|-------------------|--------|
| Full security (CT + cache-safe) | CT+Obliv.LUT | Branch-free + oblivious access |
| CT only (no cache-timing threat) | CT+O3 | Near-reference performance |
| Best raw performance (no security) | LUT+O3 | −16% to −23% Sign improvement |
| Avoid | NEON, OpenMP | No benefit on ≤4 core platforms |

## KAT Verification

All 13 configurations × 4 parameter sets passed KAT (Known Answer Tests) ✓

## Results

Full benchmark data: `results_MAYO_ARM64.txt`
