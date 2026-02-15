

# Performance Profiling Results – MAYO

**Objective:** Identify computational bottlenecks in the MAYO implementation.

---

# MAYO-1 Profiling Results

## Most Time-Consuming Functions

| Rank | Percentage | Time  | Calls   | Function Name           |
| ---- | ---------- | ----- | ------- | ----------------------- |
| 1    | 55.56%     | 0.05s | 5,100   | transpose_16x16_nibbles |
| 2    | 22.22%     | 0.02s | 100     | ReadHex                 |
| 3    | 11.11%     | 0.01s | 115,100 | decode                  |
| 4    | 11.11%     | 0.01s | 38,001  | br_aes_ct64_keysched    |

## Critical Function Call Counts

* `mul_table`: 12,253,800 calls (0.00% time)
* `mul_f`: 1,330,500 calls (0.00% time)
* `add_f`: 1,341,600 calls (0.00% time)
* `inverse_f`: 8,100 calls (0.00% time)

### Key Observation

Despite millions of calls, GF(16) arithmetic functions do not appear in total execution time at Level 1.

---

# MAYO-2 Profiling Results

## Most Time-Consuming Functions

| Rank | Percentage | Time  | Calls   | Function Name             |
| ---- | ---------- | ----- | ------- | ------------------------- |
| 1    | 54.55%     | 0.06s | 100     | ReadHex                   |
| 2    | 36.36%     | 0.04s | 3,300   | transpose_16x16_nibbles   |
| 3    | 9.09%      | 0.01s | 342,009 | br_aes_ct64_bitslice_Sbox |

## Critical Function Call Counts

* `mul_table`: 13,609,600 calls (0.00% time)
* `mul_f`: 918,100 calls (0.00% time)
* `add_f`: 908,800 calls (0.00% time)

Observation: Similar to MAYO-1, GF operations do not significantly impact runtime.

---

# MAYO-3 Profiling Results

## Most Time-Consuming Functions

| Rank | Percentage | Time  | Calls      | Function Name           |
| ---- | ---------- | ----- | ---------- | ----------------------- |
| 1    | 80.00%     | 0.36s | 5,400      | transpose_16x16_nibbles |
| 2    | 8.89%      | 0.04s | 100        | ReadHex                 |
| 3    | 6.67%      | 0.03s | 27,491,400 | mul_table               |
| 4    | 2.22%      | 0.01s | 190,005    | add_round_key           |

## Critical Function Call Counts

* `mul_table`: 27,491,400 calls (6.67% time)
* `mul_f`: 2,496,700 calls (0.00% time)
* `add_f`: 2,516,400 calls (0.00% time)

### Key Observation

At Level 3, `mul_table` begins to contribute measurable runtime (6.67%).

---

# MAYO-5 Profiling Results

## Most Time-Consuming Functions

| Rank | Percentage | Time  | Calls      | Function Name           |
| ---- | ---------- | ----- | ---------- | ----------------------- |
| 1    | 75.95%     | 0.60s | 5,700      | transpose_16x16_nibbles |
| 2    | 8.86%      | 0.07s | 54,528,000 | mul_table               |
| 3    | 2.53%      | 0.02s | 3,945,900  | aes128ni_encrypt_x4     |
| 4    | 2.53%      | 0.02s | 12,867     | br_aes_ct64_skey_expand |

## Critical Function Call Counts

* `mul_table`: 54,528,000 calls (8.86% time)
* `mul_f`: 4,240,300 calls (0.00% time)
* `add_f`: 4,288,400 calls (0.00% time)

### Key Observation

At Level 5, `mul_table` consumes nearly 9% of total runtime, representing a clear optimization opportunity.

---

# Bottleneck Analysis

## Primary Bottleneck: `transpose_16x16_nibbles`

| Level  | Runtime Percentage |
| ------ | ------------------ |
| MAYO-1 | 55.56%             |
| MAYO-2 | 36.36%             |
| MAYO-3 | 80.00%             |
| MAYO-5 | 75.95%             |

Description:
Matrix transposition operation on 16×16 nibble matrices.

### Optimization Attempt

Loop unrolling was applied.

Result:
Performance degraded by 43%.

Conclusion:
The original implementation is already highly optimized.

---

## Secondary Bottleneck: GF(16) Arithmetic

| Level  | mul_f Calls | mul_table Calls | Runtime Impact |
| ------ | ----------- | --------------- | -------------- |
| MAYO-1 | 1.3M        | 12.2M           | 0.00%          |
| MAYO-2 | 0.9M        | 13.6M           | 0.00%          |
| MAYO-3 | 2.5M        | 27.5M           | 6.67%          |
| MAYO-5 | 4.2M        | 54.5M           | 8.86%          |

### Interpretation

* Small levels (1,2): arithmetic operations are fast enough to be negligible.
* Larger levels (3,5): very high call counts begin to influence runtime.

---

# Relationship Between Parameters and Performance

## MAYO Parameters

| Level  | n   | m   | o  | k  | GF(16) Volume | LUT Effectiveness |
| ------ | --- | --- | -- | -- | ------------- | ----------------- |
| MAYO-1 | 86  | 78  | 8  | 10 | Low           | Not effective     |
| MAYO-2 | 81  | 64  | 17 | 4  | High          | Excellent         |
| MAYO-3 | 118 | 108 | 10 | 11 | Moderate      | Good              |
| MAYO-5 | 154 | 142 | 12 | 12 | High          | Good              |

### Critical Insight

The parameter **o (oil variables)** directly correlates with the number of GF(16) operations.

* MAYO-1 (o = 8): fewer operations → LUT not beneficial
* MAYO-2 (o = 17): highest GF workload → maximum LUT gain
* MAYO-3 (o = 10): moderate workload → moderate gain
* MAYO-5 (o = 12): moderate-high workload → moderate gain

This explains why MAYO-2 achieved +69.6% improvement despite being smaller than MAYO-3 and MAYO-5.

---

# Final Conclusions

1. Primary bottleneck: `transpose_16x16_nibbles` (55–80% of runtime).
2. Secondary optimization opportunity: GF(16) operations at higher security levels.
3. The oil variable parameter `o` strongly determines GF workload.
4. LUT optimization is most effective when GF(16) operations dominate.

---

