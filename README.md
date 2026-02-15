Benchmarking NIST Round 2 Multivariate Signature Schemes: UOV, MAYO, and QR-UOV


A controlled, same-platform evaluation of NIST Round 2 multivariate signature schemes with full reproducibility
---
##About

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

### Evaluated Schemes
* **UOV** – Unbalanced Oil and Vinegar
* **MAYO** – Multivariate Algorithm over the Vinegar Oil
* **QR-UOV** – Quotient Ring UOV
---
## Key Findings Summary

| Scheme     | Most Effective Optimization | Result                                             | Key Insight                                                |
| ---------- | --------------------------- | -------------------------------------------------- | ---------------------------------------------------------- |
| **MAYO**   | AVX2 Vectorization          | Significant speedup (up to ~4× depending on level) | Scalar baseline enables substantial SIMD gains             |
| **UOV**    | Lookup Tables + OpenMP      | Moderate improvement                               | Baseline already benefits from compiler auto-vectorization |
| **QR-UOV** | Baseline configuration      | OpenMP provides no net benefit                     | Thread management overhead dominates (52–70%)              |

**Critical Discovery:** Profiling revealed that QR-UOV’s OpenMP implementation spends 52–70% of execution time on thread management rather than computation. As a result, enabling OpenMP does not improve overall performance on the evaluated platform.

**Note:** Exact performance numbers and detailed measurements are documented in the accompanying paper to ensure consistency with peer-reviewed results.
---

## Repository Structure

```
├── 00_NIST_Original_Submissions/    # Original NIST submission files
│   ├── MAYO/
│   ├── UOV/
│   └── qr-UOV/
│
├── MAYO/                             # MAYO analysis
│   ├── 01_Baseline/
│   ├── 02_Profiling/
│   ├── 03_AVX2_Optimization/
│   ├── 04_LUT_Optimization/
│   ├── 05_OpenMP_Optimization/
│   └── 06_Documentation/
│
├── UOV/                              # UOV analysis
│   ├── 01_Baseline/
│   ├── 02_Profiling/
│   ├── 03_AVX2_Optimization/
│   ├── 04_LUT_Optimization/
│   ├── 05_OpenMP_Test/
│   └── 06_Documentation/
│
└── qr-UOV/                           # qr-UOV analysis
    ├── 01_Reference_Implementation/
    ├── 02_Optimized_portable64/
    ├── 03_Alternative_avx2/
    ├── 04_Alternative_avx512/
    └── 05_Documentation/
```
   
---

## System Requirements

### Tested Environment

* OS: Ubuntu 22.04 LTS
* Compiler: GCC 11.4.0
* Architecture: x86_64 with AVX2 support
* Hardware: Intel Core i7-10510U @ 1.80 GHz (2 vCPUs, 3.8 GB RAM)
* Virtualization: VMware

### Install Dependencies

```bash
sudo apt update
sudo apt install -y build-essential cmake gcc g++ make \
    valgrind binutils libgomp1
```

### Verify AVX2 Support

```bash
grep avx2 /proc/cpuinfo
```

---

## Quick Start

### UOV

**Baseline:**

```bash
cd UOV/01_Baseline/code/amd64
make PROJ=Ip
./sign_api-test
```

**AVX2 (enabled via -march=native):**

```bash
cd UOV/03_AVX2_Optimization/code/avx2
make PROJ=III
./sign_api-test
```

**Lookup Tables (our implementation):**

```bash
cd UOV/04_LUT_Optimization
make
./sign_api-test
```

---

### MAYO

```bash
cd MAYO/Optimized_Implementation
mkdir build && cd build
cmake -DMAYO=2 ..
make -j
./apps/PQCgenKAT_sign_mayo_2
```

Available variants: `MAYO=1`, `MAYO=2`, `MAYO=3`, `MAYO=5`

---

### QR-UOV

All scripts located in:

```bash
cd qr-UOV/05_Documentation
chmod +x *.sh
```

* Baseline: `./06_Baseline_Code.sh`
* OpenMP: `./07_OpenMP_Code.sh`
* LUT: `./09_LUT_Test.sh`
* Profiling: `./10_Profiling_Code.sh`

---

## Measurement Methodology

### Timing Protocol

* Tool: `/usr/bin/time -f "%e"` (wall-clock time)
* Runs: 10 independent executions per configuration
* Reported Metric: Median execution time
* Variance: <2% across all configurations

### Profiling Tools

* Callgrind (instruction-level): UOV, QR-UOV
* gprof (function-level): MAYO

### Controlled Experimental Conditions

* Identical hardware platform
* Identical compiler (GCC 11.4.0)
* Identical optimization flags (-O3 -march=native)
* Clean rebuild per configuration
* Process isolation
* Median of 10 runs

### Experimental Integrity

* No background processes during measurements
* Full rebuild for each configuration
* Median reporting to reduce outliers
* All implementations pass NIST Known Answer Tests (KATs)

---

## Code Attribution

### Official NIST Code

Located in `00_NIST_Original_Submissions/`

Source:
[https://csrc.nist.gov/projects/post-quantum-cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)

Status: Unmodified reference implementations

### Our Contributions

This repository introduces:

* GF(16) lookup table optimization for UOV
* Automated benchmarking scripts
* Profiling-based bottleneck analysis
* Cross-scheme comparative evaluation framework
* Statistical performance analysis tools

All modifications are isolated from official source code to preserve reproducibility of NIST reference implementations.

---

## Limitations and Threats to Validity

* Results specific to Intel Core i7-10510U
* x86_64 only (no ARM/RISC-V evaluation)
* VMware environment (2 vCPUs)
* Performance-focused evaluation (no energy analysis)
* GCC 11.4.0 used for all experiments

Future work includes multi-core server testing, ARM platforms, and energy profiling.

---

## Citation

If you use this framework in your research, please cite:

```bibtex
@misc{hasan2026mqps,
  author = {Manar Abdulqawi Ahmed Hasan and Sedat Akleylek},
  title  = {Benchmarking NIST Round 2 Multivariate Signature Schemes: UOV, MAYO, and QR-UOV},
  year   = {2026},
  note   = {Preprint}
}
```

Citation will be updated upon publication.

---

## Contact

**Manar Abdulqawi Ahmed Hasan**
Department of Computer Engineering
Istinye University, Istanbul, Turkey
Email: [abdulqawi.hasan@stu.istinye.edu.tr],[manarabdulqawi.hasan@gmail.com]

**Sedat Akleylek**
Department of Computer Engineering, Istinye University
Institute of Computer Science, University of Tartu
Email: [akleylek@gmail.com]

---


## Artifact Checklist

* All configurations compile successfully
* All configurations execute correctly
* Benchmarks reproducible (variance <2%)
* Official NIST code preserved unmodified
* Modifications clearly isolated and documented
* All implementations pass NIST Known Answer Tests (KATs)
* Measurement methodology documented
* Source code attribution provided

---

## Acknowledgments

This research was supported by:

* Estonian Research Council Grant PRG2531
* Estonian Ministry of Defence (grant No 2-2/24/541-1)
* COST project CA22168
---

If you find this work useful for your research, please consider citing our paper and starring this repository.
