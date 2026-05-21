#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define DUDECT_IMPLEMENTATION
#include "dudect_aarch64.h"

/* UOV API */
#include "api.h"

/* Key pair — generated once, reused across measurements */
static uint8_t pk[CRYPTO_PUBLICKEYBYTES];
static uint8_t sk[CRYPTO_SECRETKEYBYTES];
static int keypair_ready = 0;

#define MSG_LEN 32

/*
 * do_one_computation:
 * Called once per measurement. Signs a message using the secret key.
 * dudect will measure the time this function takes and test whether
 * it varies with the input (which encodes the secret class).
 */
uint8_t do_one_computation(uint8_t *data) {
    uint8_t sig[CRYPTO_BYTES + MSG_LEN];
    size_t siglen = 0;

    /* Sign the input data as the message */
    crypto_sign(sig, &siglen, data, MSG_LEN, sk);

    /* Return one byte to prevent compiler optimization */
    return sig[0];
}

/*
 * prepare_inputs:
 * Two classes of inputs:
 *   class 0: all-zero message  (fixed)
 *   class 1: random message
 * The signing key is the same for both classes.
 * If signing time depends on the message (not just the key),
 * dudect will detect it.
 */
void prepare_inputs(dudect_config_t *c, uint8_t *input_data, uint8_t *classes) {
    /* Generate key pair once */
    if (!keypair_ready) {
        printf("[dudect-uov] Generating key pair...\n");
        crypto_sign_keypair(pk, sk);
        keypair_ready = 1;
        printf("[dudect-uov] Key pair ready. CRYPTO_SECRETKEYBYTES=%d\n",
               CRYPTO_SECRETKEYBYTES);
    }

    randombytes(input_data, c->number_measurements * c->chunk_size);

    for (size_t i = 0; i < c->number_measurements; i++) {
        classes[i] = randombit();
        if (classes[i] == 0) {
            /* class 0: fixed all-zero message */
            memset(input_data + (size_t)i * c->chunk_size, 0x00, c->chunk_size);
        }
        /* class 1: leave random (already set by randombytes above) */
    }
}

int run_test(void) {
    printf("[dudect-uov] Starting constant-time test for UOV signing\n");
    printf("[dudect-uov] Using GE_CONST_TIME_CADD_EARLY_STOP + Oblivious LUT\n");

    dudect_config_t config = {
        .chunk_size       = MSG_LEN,
        .number_measurements = 500,
    };

    dudect_ctx_t ctx;
    dudect_init(&ctx, &config);

    dudect_state_t state = DUDECT_NO_LEAKAGE_EVIDENCE_YET;
    int rounds = 0;

    while (state == DUDECT_NO_LEAKAGE_EVIDENCE_YET && rounds < 100) {
        state = dudect_main(&ctx);
        rounds++;
        if (rounds % 10 == 0) {
            printf("[dudect-uov] Round %d — no leakage detected yet\n", rounds);
        }
    }

    dudect_free(&ctx);

    if (state == DUDECT_NO_LEAKAGE_EVIDENCE_YET) {
        printf("[dudect-uov] RESULT: NO LEAKAGE EVIDENCE FOUND after %d rounds\n", rounds);
        printf("[dudect-uov] UOV signing appears constant-time (t-test passed)\n");
    } else {
        printf("[dudect-uov] RESULT: LEAKAGE DETECTED after %d rounds\n", rounds);
        printf("[dudect-uov] WARNING: timing variation detected\n");
    }

    return (int)state;
}

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;
    return run_test();
}
