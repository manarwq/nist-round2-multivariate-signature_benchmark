# Simple Arithmetic Files Guide

| File | Description |
|------|-------------|
| simple_arithmetic_original.h | Original ref implementation — DO NOT MODIFY |
| simple_arithmetic_lut_basic.h | Basic GF(16) LUT (not cache-timing secure) |
| simple_arithmetic_oblivious_lut.h | Oblivious LUT — fully constant-time, cache-secure |
| simple_arithmetic.h | Active file — copy from above before building |

# How to use:
# For ref build:
cp simple_arithmetic_original.h simple_arithmetic.h
# For LUT build:
cp simple_arithmetic_lut_basic.h simple_arithmetic.h
# For Oblivious LUT build:
cp simple_arithmetic_oblivious_lut.h simple_arithmetic.h
