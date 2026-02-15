

# NIST Original Submissions

This directory contains the original, unmodified algorithm submissions from the NIST Post-Quantum Cryptography (PQC) project.

---

## Purpose

This directory serves the following roles:

* Baseline reference for all optimization experiments
* Verification that all modifications are derived from official NIST code
* Proper attribution to the original algorithm designers
* Clean separation between original submissions and experimental work

---
## Directory Structure

```
NIST_Original/
│
├── MAYO/     → Original MAYO submission
├── UOV/      → Original UOV submission
└── qr-UOV/   → Original qr-UOV submission
```

Each subdirectory contains the official NIST implementation files as downloaded, without modification.

---

## Source

All files were obtained from the NIST Post-Quantum Cryptography Project:

NIST PQC Project
[https://csrc.nist.gov/projects/post-quantum-cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)

Only publicly released submission packages were used.

---

## Integrity Note

* These files are NOT modified.
* No optimization patches were applied inside this directory.
* All experimental changes (LUT, AVX2 flags, OpenMP testing, profiling instrumentation) are located in separate directories.

This separation ensures:

* Reproducibility
* Code traceability
* Clear differentiation between official code and experimental contributions

---


