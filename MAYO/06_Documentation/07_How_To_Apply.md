

# Optimization Deployment Guide

## Step-by-Step Procedure

### 1. Create a Backup

Before applying any modifications, create a backup of the original file:

```bash
cd MAYO/Optimized_Implementation/src
cp simple_arithmetic.h simple_arithmetic.h.backup
```

---

### 2. Apply the Optimized Code

Replace the file `simple_arithmetic.h` with the contents of:

```
05_Optimized_Code.h
```

Ensure the replacement is completed correctly before proceeding.

---

### 3. Build the Project

```bash
cd MAYO/Optimized_Implementation
mkdir build
cd build
cmake -DMAYO=2 ..
make
```

Adjust the `-DMAYO=` parameter if testing a different security level.

---

### 4. Run the Test

```bash
./apps/PQCgenKAT_sign_mayo_2
```

This will execute the KAT signing benchmark for MAYO-2.

---

### 5. Restore the Original File (If Needed)

If rollback is required:

```bash
cp simple_arithmetic.h.backup simple_arithmetic.h
```

Rebuild the project afterward if necessary.

---

