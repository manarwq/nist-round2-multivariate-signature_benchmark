#!/usr/bin/env python3

# Generate multiplication LUT for q=127
q = 127

print("Generating Fq_mul_table for q=127...")
print(f"Size: {q}x{q} = {q*q} bytes (~{q*q//1024} KB)")
print()

# Function to reduce modulo q (q = 2^7 - 1 = 127)
def Fq_reduction(z):
    z = (z & q) + ((z & ~q) >> 7)
    c = ((z + 1) & ~q)
    z += (c >> 7)
    z -= c
    return z

# Generate table
print("Generating table...")
table = []
for a in range(q):
    row = []
    for b in range(q):
        result = Fq_reduction(a * b)
        row.append(result)
    table.append(row)

# Write to C code
print()
print("Writing to C format...")
print()
print("// Multiplication LUT for q=127")
print(f"static const Fq Fq_mul_table[{q}][{q}] = {{")

for i in range(q):
    if i % 8 == 0:
        print("  // Row", i)
    print("  {", end="")
    for j in range(q):
        print(f"{table[i][j]:3d}", end="")
        if j < q-1:
            print(",", end="")
    print("},")

print("};")
print()
print("✅ Done!")

