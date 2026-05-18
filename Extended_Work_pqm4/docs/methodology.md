# Benchmark Methodology

## General
- 3 runs per configuration, best result reported
- Charger connected during all measurements
- Single session for all configurations (same QEMU warm cache)

## MAYO
- Iterations: 100 per run
- Metric: median latency (nanoseconds) via clock_gettime
- Build: CMake cross-compilation for ARM64
- Configurations: 13 (Ref, LUT, Obliv.LUT, CT, CT+LUT, CT+Obliv.LUT,
  NEON, OpenMP, O3, LUT+O3, CT+O3, CT+LUT+O3, CT+Obliv.LUT+O3)

## UOV
- Iterations: 10 (KeyGen), 100 (Sign/Verify)
- Metric: average latency (microseconds) via gettimeofday
- Build: Makefile cross-compilation for ARM64
- OpenSSL 3.0.2 built from source for ARM64
- Configurations: 14 (Ref, O3, LUT, LUT+O3, Obliv.LUT, Obliv.LUT+O3,
  GE_CT, GE_CT+O3, GE_CT+LUT, GE_CT+Obliv.LUT,
  NEON, NEON+O3, OpenMP, OpenMP+O3)

## Memory Measurement
- Tool: /usr/bin/time -v
- Metric: Maximum Resident Set Size (RSS) in kB
- Baseline: QEMU + binary overhead (~10,368 kB for UOV, ~18,704 kB for MAYO)

## KAT Verification
- MAYO: cmake build with ENABLE_TESTS=ON, all configurations passed
- UOV: PQCgenKAT_sign with OpenSSL PRNG, all 9 schemes passed
