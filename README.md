# Benchmarking NIST Round 2 Multivariate Signature Schemes: UOV, MAYO, and QR-UOV

A controlled, same-platform evaluation of NIST Round 2 multivariate signature schemes with full reproducibility

---

## About

**Title:** Benchmarking NIST Round 2 Multivariate Signature Schemes: UOV, MAYO, and QR-UOV

**Authors:**
* Manar Abdulqawi Ahmed Hasan (Istinye University)
* Sedat Akleylek (Istinye University & University of Tartu)

**Preprint:** Coming Soon

---

## Research Objective

This study addresses a critical gap in post-quantum cryptography evaluation: existing NIST Round 2 multivariate signature benchmarks are performed on heterogeneous platforms (different CPUs, compilers, optimization flags), making meaningful performance comparison infeasible.

### Key Contributions
* Controlled, same-platform evaluation of UOV, MAYO, and QR-UOV under identical conditions
* Systematic profiling revealing scheme-specific bottlenecks
* Quantified optimization effectiveness across AVX2, OpenMP, and lookup tables
* Deployment recommendations based on empirical evidence
* Fully reproducible experimental framework
* **[Extended]** ARM64 evaluation with security-oriented implementations (oblivious LUT, constant-time GE, combined GF(16)+GF(256) optimizations)

### Evaluated Schemes
* **UOV** – Unbalanced Oil and Vinegar
* **MAYO** – Multivariate Algorithm over the Vinegar Oil
* **QR-UOV** – Quotient Ring UOV

---

## Key Findings Summary

### x86 Evaluation

| Scheme | Most Effective Optimization | Result | Key Insight |
|--------|-----------------------------|--------|-------------|
| **MAYO** | AVX2 Vectorization | Up to ~4× speedup | Scalar baseline enables substantial SIMD gains |
| **UOV** | Lookup Tables + OpenMP | Moderate improvement | Baseline already benefits from compiler auto-vectorization |
| **QR-UOV** | Baseline configuration | OpenMP provides no net benefit | Thread management overhead dominates (52–70%) |

**Critical Discovery:** Profiling revealed that QR-UOV's OpenMP implementation spends 52–70% of execution time on thread management rather than computation.

### ARM64 Evaluation (Extended Work)

| Scheme | Best Configuration | KeyGen | Sign | Verify | Memory |
|--------|--------------------|--------|------|--------|--------|
| **UOV** (ov-Ip-classic) | OLut16+OLut256_LogExp+GE_CT+O3 | −70% vs Ref | −72% vs Ref | −90% vs Ref | −52% vs Ref |
| **MAYO-1** | CT+Obliv.LUT (most secure) | −10% vs Ref | +17% vs Ref | −1% vs Ref | stable ~8 MB |

**Key insight:** For UOV, cache-safe and constant-time implementations achieve better performance than the reference — security and efficiency are mutually reinforcing. For MAYO, the data reorganization bottleneck (36–80% of Sign time) limits the effectiveness of field-level security measures.

---

## Repository Structure

```
├── 00_NIST_Original_Submissions/    # Original NIST submission files
│   ├── MAYO/
│   ├── UOV/
│   └── qr-UOV/
│
├── MAYO/                            # MAYO x86 analysis
│   ├── 01_Baseline/
│   ├── 02_Profiling/
│   ├── 03_AVX2_Optimization/
│   ├── 04_LUT_Optimization/
│   ├── 05_OpenMP_Optimization/
│   └── 06_Documentation/
│
├── UOV/                             # UOV x86 analysis
│   ├── 01_Baseline/
│   ├── 02_Profiling/
│   ├── 03_AVX2_Optimization/
│   ├── 04_LUT_Optimization/
│   ├── 05_OpenMP_Test/
│   └── 06_Documentation/
│
├── qr-UOV/                          # QR-UOV x86 analysis
│   ├── 01_Reference_Implementation/
│   ├── 02_Optimized_portable64/
│   ├── 03_Alternative_avx2/
│   ├── 04_Alternative_avx512/
│   └── 05_Documentation/
│
└── Extended_Work_pqm4/              # ARM64 Extended Evaluation
    ├── README.md                    # ARM64 overview and quick start
    ├── MAYO_ARM64/
    │   ├── README.md               # MAYO ARM64 build guide + group explanations
    │   ├── results_MAYO_ARM64.txt  # Full results (13 configs x 4 params)
    │   └── src/                    # GF(16) implementation headers
    ├── UOV_ARM64/
    │   ├── README.md               # UOV ARM64 build guide + group explanations
    │   ├── results_UOV_ARM64.txt   # Full results (all groups x 9 params)
    │   └── src/                    # GF(16) and GF(256) implementation headers
    └── ARM64_Results/
        └── results_summary.txt     # Combined MAYO + UOV summary
```

---

## ARM64 Extended Work

The `Extended_Work_pqm4/` folder contains a security-oriented ARM64 evaluation of
UOV and MAYO using QEMU aarch64 emulation. This work extends the x86 benchmarking
with two additional dimensions:

### 1. Cache-Timing Security — Oblivious LUT

Standard lookup table implementations expose secret data through cache access patterns.
An oblivious LUT construction scans all table entries unconditionally, eliminating
secret-dependent memory access patterns.

For UOV at Category I (GF(16), 256-byte table): the overhead is modest.
For UOV at Categories III/V (GF(256)):
- **Full oblivious table** (64 KB scan per lookup): expensive, exceeds L1 cache
- **Oblivious log-exp** (2 × 256-byte scans): cache-safe AND fits in L1 ← used in best config

### 2. Constant-Time Gaussian Elimination

UOV signing involves Gaussian elimination over secret vinegar variables. Naive
implementations leak through secret-dependent branch timing. The constant-time
variant (CADD: conditional add without branches) eliminates all timing side channels.

### 3. Combined GF(16)+GF(256) Optimization (Group 5)

UOV signing uses both GF(16) and GF(256) arithmetic simultaneously. Jointly optimizing
both field layers reveals cache interaction effects invisible to single-layer analysis.

The best combination — **OLut16+OLut256_LogExp+GE_CT+O3** — achieves full cache-timing
resistance and constant-time GE while delivering 70–90% performance improvement
over the reference implementation.

**For full details, build instructions, and group explanations see:**
`Extended_Work_pqm4/README.md` and the per-scheme READMEs inside.

---

## System Requirements

### x86 Evaluation
* OS: Ubuntu 22.04 LTS
* Compiler: GCC 11.4.0
* Architecture: x86_64 with AVX2 support
* Hardware: Intel Core i7-10510U @ 1.80 GHz (2 vCPUs, 3.8 GB RAM)

### ARM64 Extended Evaluation
* OS: Ubuntu 22.04 LTS
* Cross-compiler: aarch64-linux-gnu-gcc 11.4.0
* Emulator: QEMU aarch64 v6.2.0 (user-mode)
* OpenSSL: 3.0.2 (built from source for aarch64)

### Install Dependencies

```bash
# x86 evaluation
sudo apt update
sudo apt install -y build-essential cmake gcc g++ make \
    valgrind binutils libgomp1

# ARM64 extended evaluation
sudo apt install -y gcc-aarch64-linux-gnu qemu-user
```

---

## Quick Start

### x86 — UOV

```bash
cd UOV/01_Baseline/code/amd64
make PROJ=Ip
./sign_api-test
```

### x86 — MAYO

```bash
cd MAYO/Optimized_Implementation
mkdir build && cd build
cmake -DMAYO=2 ..
make -j
./apps/PQCgenKAT_sign_mayo_2
```

### x86 — QR-UOV

```bash
cd qr-UOV/05_Documentation
chmod +x *.sh
./06_Baseline_Code.sh
```

### ARM64 — UOV Best Configuration

```bash
git clone https://github.com/pqov/pqov
cd pqov
cp Extended_Work_pqm4/UOV_ARM64/src/gf16_obliv16_obliv256_logexp.h src/gf16.h

make CC=aarch64-linux-gnu-gcc PROJ=ref \
     CFLAGS="-DCONFIG_BENCH_SYSTIME \
             -I/path/to/openssl-aarch64/include \
             -D_GE_CONST_TIME_CADD_EARLY_STOP_ \
             -O3 -funroll-loops \
             -D_OV256_112_44 -D_OV_CLASSIC" \
     LIBS="-L/path/to/openssl-aarch64/lib -lssl -lcrypto -ldl -pthread" \
     sign_api-benchmark

/usr/bin/qemu-aarch64 -L /usr/aarch64-linux-gnu \
    -E LD_LIBRARY_PATH=/path/to/openssl-aarch64/lib \
    ./sign_api-benchmark
```

### ARM64 — MAYO

```bash
git clone https://github.com/PQCMayo/MAYO-C
cd MAYO-C && mkdir build && cd build
cmake .. -DMAYO_BUILD_TYPE=ref \
  -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DENABLE_TESTS=ON \
  -DMAYO_MARCH="-march=armv8-a" \
  -DENABLE_STRICT=OFF
make
qemu-aarch64 -L /usr/aarch64-linux-gnu ./test/mayo_bench MAYO-1 100
```

---

## Measurement Methodology

### x86 Protocol
* Tool: `/usr/bin/time -f "%e"` (wall-clock time)
* Runs: 10 independent executions per configuration
* Reported Metric: Median execution time
* Variance: <2% across all configurations
* Profiling: Callgrind (UOV, QR-UOV), gprof (MAYO)

### ARM64 Protocol
* Tool: sign_api-benchmark with CONFIG_BENCH_SYSTIME (clock_gettime)
* Runs: 3 independent executions per configuration
* Reported Metric: Minimum of 3 runs
* Memory: Peak RSS via /usr/bin/time -v
* KAT: All configurations verified against NIST Known Answer Tests

---

## KAT Verification

* x86: All implementations pass NIST Known Answer Tests ✓
* ARM64 UOV: All 9 schemes × all configurations passed KAT ✓
* ARM64 MAYO: All 13 configurations × 4 parameter sets passed KAT ✓

---

## Code Attribution

### Official NIST Code
Located in `00_NIST_Original_Submissions/` — unmodified reference implementations.
Source: https://csrc.nist.gov/projects/post-quantum-cryptography

### Our Contributions
* GF(16) lookup table optimization for UOV (x86)
* Automated benchmarking scripts
* Profiling-based bottleneck analysis
* Cross-scheme comparative evaluation framework
* **[ARM64]** Oblivious LUT implementations for GF(16) and GF(256)
* **[ARM64]** Constant-time Gaussian elimination integration and benchmarking
* **[ARM64]** Combined GF(16)+GF(256) optimization headers (6 combinations)
* **[ARM64]** Security-performance analysis across 14 UOV + 13 MAYO configurations

---

## Limitations

* x86 results specific to Intel Core i7-10510U
* ARM64 results measured under QEMU emulation (relative ordering valid, absolute values are upper bounds)
* VMware environment (2 vCPUs) — OpenMP benefits may differ on many-core hardware
* Performance-focused evaluation (no energy analysis)
* GCC 11.4.0 used for all experiments

---

## Citation

```bibtex
@misc{hasan2026mqps,
  author = {Manar Abdulqawi Ahmed Hasan and Sedat Akleylek},
  title  = {Benchmarking NIST Round 2 Multivariate Signature Schemes: UOV, MAYO, and QR-UOV},
  year   = {2026},
  note   = {Preprint}
}
```

---

## Contact

**Manar Abdulqawi Ahmed Hasan**
Department of Computer Engineering, Istinye University, Istanbul, Turkey
Email: abdulqawi.hasan@stu.istinye.edu.tr

**Sedat Akleylek**
Department of Computer Engineering, Istinye University
Institute of Computer Science, University of Tartu
Email: akleylek@gmail.com

---

## Acknowledgments

This research was supported by:
* Estonian Research Council Grant PRG2531
* Estonian Ministry of Defence (grant No 2-2/24/541-1)
* COST project CA22168

---

## Artifact Checklist

* All x86 configurations compile and execute successfully ✓
* All ARM64 configurations compile and execute successfully ✓
* All implementations pass NIST Known Answer Tests ✓
* Benchmarks reproducible (variance <2% for x86, min of 3 runs for ARM64) ✓
* Official NIST code preserved unmodified ✓
* Modifications clearly isolated and documented ✓
* Source code attribution provided ✓
* Security analysis (cache-timing, constant-time) documented ✓
