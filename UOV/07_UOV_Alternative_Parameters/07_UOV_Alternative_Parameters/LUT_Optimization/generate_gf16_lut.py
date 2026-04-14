#!/usr/bin/env python3
"""
Generate GF(16) multiplication lookup table
GF(16) = GF(2)[x] / (x^4 + x + 1)
"""

def gf16_mul(a, b):
    """GF(16) multiplication - same algorithm as C code"""
    r = (a & 1) * b
    r ^= (a & 2) * b
    r ^= (a & 4) * b
    r ^= (a & 8) * b
    
    # reduction: x^4 = x+1, x^5 = x^2+x, x^6 = x^3+x^2
    r4 = r ^ (((r >> 4) & 5) * 3)
    r4 ^= (((r >> 5) & 1) * 6)
    return r4 & 0xf

# Generate table
print("// GF(16) Multiplication Lookup Table")
print("// Generated for x^4 + x + 1")
print("// Size: 16x16 = 256 bytes")
print()
print("static const uint8_t gf16_mul_table[16][16] = {")

for a in range(16):
    print("    {", end="")
    for b in range(16):
        result = gf16_mul(a, b)
        print(f"{result}", end="")
        if b < 15:
            print(", ", end="")
    print("},")

print("};")
print()

# Generate inline function
print("// LUT-based multiplication")
print("static inline uint8_t gf16_mul_lut(uint8_t a, uint8_t b) {")
print("    return gf16_mul_table[a & 0xf][b & 0xf];")
print("}")

