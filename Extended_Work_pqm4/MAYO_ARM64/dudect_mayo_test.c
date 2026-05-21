#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define DUDECT_IMPLEMENTATION
#include "dudect_aarch64.h"

/* MAYO API */
#include "api.h"

/*
 * Design:
 *   Class 0: key A (fixed)
 *   Class 1: key B (different)
 *   Message: same fixed message for both classes
 *
 * Tests whether signing time depends on the secret key structure.
 * CT implementations should show |t| < 4.5.
 */

#define MSG_LEN 32
#define CHUNK_SIZE (MSG_LEN + 1)

static uint8_t fixed_msg[MSG_LEN] = {
    0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
    0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
    0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
    0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
};

static uint8_t pk[2][CRYPTO_PUBLICKEYBYTES];
static uint8_t sk[2][CRYPTO_SECRETKEYBYTES];
static int keys_ready = 0;

uint8_t do_one_computation(uint8_t *data) {
    uint8_t cls = data[0] & 1;
    uint8_t sig[CRYPTO_BYTES + MSG_LEN];
    size_t siglen = 0;
    crypto_sign(sig, &siglen, fixed_msg, MSG_LEN, sk[cls]);
    return sig[0];
}

void prepare_inputs(dudect_config_t *c, uint8_t *input_data, uint8_t *classes) {
    if (!keys_ready) {
        printf("[dudect-mayo] Generating key pairs...\n");
        crypto_sign_keypair(pk[0], sk[0]);
        crypto_sign_keypair(pk[1], sk[1]);
        keys_ready = 1;
        printf("[dudect-mayo] Keys ready. SK=%d bytes, PK=%d bytes\n",
               CRYPTO_SECRETKEYBYTES, CRYPTO_PUBLICKEYBYTES);
    }

    for (size_t i = 0; i < c->number_measurements; i++) {
        classes[i] = randombit();
        input_data[i * c->chunk_size] = classes[i];
    }
}

int run_test(void) {
    printf("[dudect-mayo] Constant-time test: %s\n", CRYPTO_ALGNAME);
    printf("[dudect-mayo] Class 0: key A | Class 1: key B\n");
    printf("[dudect-mayo] Threshold: |t| < 4.5 = constant-time\n\n");

    dudect_config_t config = {
        .chunk_size          = CHUNK_SIZE,
        .number_measurements = 500,
    };

    dudect_ctx_t ctx;
    dudect_init(&ctx, &config);

    dudect_state_t state = DUDECT_NO_LEAKAGE_EVIDENCE_YET;
    int rounds = 0;

    while (state == DUDECT_NO_LEAKAGE_EVIDENCE_YET && rounds < 100) {
        state = dudect_main(&ctx);
        rounds++;
        if (rounds % 10 == 0)
            printf("[dudect-mayo] Round %d\n", rounds);
    }

    dudect_free(&ctx);

    printf("\n");
    if (state == DUDECT_NO_LEAKAGE_EVIDENCE_YET) {
        printf("[dudect-mayo] RESULT: NO LEAKAGE (t < 4.5) — PASS\n");
    } else {
        printf("[dudect-mayo] RESULT: LEAKAGE DETECTED (t >= 4.5) — FAIL\n");
    }

    return (int)state;
}

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    return run_test();
}
