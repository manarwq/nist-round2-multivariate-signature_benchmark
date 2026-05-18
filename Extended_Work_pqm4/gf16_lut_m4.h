// GF(16) multiplication via lookup table
// Table size: 256 bytes — fits entirely in L1 cache
static uint8_t gf16_mul_table[16][16];

static void init_gf16_lut(void) {
    for (int a = 0; a < 16; a++) {
        for (int b = 0; b < 16; b++) {
            uint8_t p = 0, aa = a, bb = b;
            for (int i = 0; i < 4; i++) {
                if (bb & 1) p ^= aa;
                uint8_t msb = aa & 8;
                aa = (aa << 1) & 0xF;
                if (msb) aa ^= 3;
                bb >>= 1;
            }
            gf16_mul_table[a][b] = p;
        }
    }
}

static inline uint8_t mul_f_lut(uint8_t a, uint8_t b) {
    return gf16_mul_table[a & 0xF][b & 0xF];
}
