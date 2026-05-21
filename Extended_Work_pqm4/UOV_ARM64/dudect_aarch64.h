/*
 * dudect_aarch64.h — ARM64 port of dudect
 * Original: https://github.com/oreparaz/dudect
 * Modified for aarch64: replaced rdtsc with clock_gettime
 */

#ifndef DUDECT_AARCH64_H
#define DUDECT_AARCH64_H

#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <time.h>

/* ── Configuration ── */
#ifndef DUDECT_ENOUGH_MEASUREMENTS
#define DUDECT_ENOUGH_MEASUREMENTS 10000
#endif

#ifndef DUDECT_NUMBER_PERCENTILES
#define DUDECT_NUMBER_PERCENTILES 100
#endif

#define DUDECT_TESTS (1 + DUDECT_NUMBER_PERCENTILES)

/* ── Types ── */
typedef struct {
  size_t chunk_size;
  size_t number_measurements;
} dudect_config_t;

typedef struct {
  double mean[2];
  double m2[2];
  double n[2];
} ttest_ctx_t;

typedef struct {
  int64_t *ticks;
  int64_t *exec_times;
  uint8_t *input_data;
  uint8_t *classes;
  ttest_ctx_t *ttest_ctxs[DUDECT_TESTS];
  int64_t percentiles[DUDECT_NUMBER_PERCENTILES];
  dudect_config_t config;
} dudect_ctx_t;

typedef enum {
  DUDECT_NO_LEAKAGE_EVIDENCE_YET = 0,
  DUDECT_LEAKAGE_FOUND           = 1,
} dudect_state_t;

/* ── CPU cycles via clock_gettime (ARM64) ── */
static inline int64_t cpucycles(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (int64_t)ts.tv_sec * 1000000000LL + (int64_t)ts.tv_nsec;
}

/* ── Random bytes ── */
static inline void randombytes(uint8_t *buf, size_t len) {
  for (size_t i = 0; i < len; i++)
    buf[i] = (uint8_t)(rand() & 0xFF);
}

static inline uint8_t randombit(void) {
  return (uint8_t)(rand() & 1);
}

/* ── t-test ── */
static void t_push(ttest_ctx_t *ctx, double x, uint8_t clazz) {
  ctx->n[clazz]++;
  double delta = x - ctx->mean[clazz];
  ctx->mean[clazz] += delta / ctx->n[clazz];
  ctx->m2[clazz] += delta * (x - ctx->mean[clazz]);
}

static double t_compute(ttest_ctx_t *ctx) {
  double var[2];
  var[0] = ctx->m2[0] / (ctx->n[0] - 1);
  var[1] = ctx->m2[1] / (ctx->n[1] - 1);
  double num = ctx->mean[0] - ctx->mean[1];
  double den = sqrt(var[0] / ctx->n[0] + var[1] / ctx->n[1]);
  if (den == 0) return 0;
  return num / den;
}

static void t_init(ttest_ctx_t *ctx) {
  memset(ctx, 0, sizeof(ttest_ctx_t));
}

/* ── Percentiles ── */
static void prepare_percentiles(dudect_ctx_t *ctx) {
  for (int i = 0; i < DUDECT_NUMBER_PERCENTILES; i++) {
    ctx->percentiles[i] = (int64_t)((i + 1) / 100.0 *
      ctx->config.number_measurements);
  }
}

/* ── Forward declarations (user must implement) ── */
uint8_t do_one_computation(uint8_t *data);
void prepare_inputs(dudect_config_t *c, uint8_t *input_data, uint8_t *classes);

/* ── Measure ── */
static void measure(dudect_ctx_t *ctx) {
  prepare_inputs(&ctx->config, ctx->input_data, ctx->classes);
  size_t n = ctx->config.number_measurements;
  size_t chunk = ctx->config.chunk_size;

  for (size_t i = 0; i < n; i++) {
    ctx->ticks[i] = cpucycles();
    (void)do_one_computation(ctx->input_data + i * chunk);
  }
  ctx->ticks[n] = cpucycles();

  for (size_t i = 0; i < n; i++)
    ctx->exec_times[i] = ctx->ticks[i + 1] - ctx->ticks[i];
}

/* ── Update statistics ── */
static void update_statistics(dudect_ctx_t *ctx) {
  size_t n = ctx->config.number_measurements;
  for (size_t i = 0; i < n; i++) {
    int64_t d = ctx->exec_times[i];
    if (d < 0) continue;
    uint8_t clazz = ctx->classes[i];
    /* uncropped test */
    t_push(ctx->ttest_ctxs[0], (double)d, clazz);
    /* percentile tests */
    for (int p = 0; p < DUDECT_NUMBER_PERCENTILES; p++) {
      if (d < ctx->percentiles[p])
        t_push(ctx->ttest_ctxs[p + 1], (double)d, clazz);
    }
  }
}

/* ── Max t value ── */
static ttest_ctx_t *max_test(dudect_ctx_t *ctx) {
  ttest_ctx_t *ret = ctx->ttest_ctxs[0];
  double max = fabs(t_compute(ctx->ttest_ctxs[0]));
  for (int i = 1; i < DUDECT_TESTS; i++) {
    double v = fabs(t_compute(ctx->ttest_ctxs[i]));
    if (v > max) { max = v; ret = ctx->ttest_ctxs[i]; }
  }
  return ret;
}

/* ── Report ── */
static dudect_state_t report(dudect_ctx_t *ctx) {
  ttest_ctx_t *t = max_test(ctx);
  double tval = fabs(t_compute(t));
  double n = t->n[0] + t->n[1];
  printf("  t = %+7.2f, n = %.0f  ", tval, n);
  if (n < DUDECT_ENOUGH_MEASUREMENTS) {
    printf("(not enough measurements)\n");
    return DUDECT_NO_LEAKAGE_EVIDENCE_YET;
  }
  if (tval < 4.5) {
    printf("no leakage detected (t < 4.5)\n");
    return DUDECT_NO_LEAKAGE_EVIDENCE_YET;
  } else {
    printf("*** LEAKAGE DETECTED (t >= 4.5) ***\n");
    return DUDECT_LEAKAGE_FOUND;
  }
}

/* ── Init / Main / Free ── */
int dudect_init(dudect_ctx_t *ctx, dudect_config_t *conf) {
  ctx->config = *conf;
  size_t n = conf->number_measurements;
  ctx->ticks      = calloc(n + 1, sizeof(int64_t));
  ctx->exec_times = calloc(n,     sizeof(int64_t));
  ctx->input_data = calloc(n * conf->chunk_size, 1);
  ctx->classes    = calloc(n, 1);
  for (int i = 0; i < DUDECT_TESTS; i++) {
    ctx->ttest_ctxs[i] = calloc(1, sizeof(ttest_ctx_t));
    t_init(ctx->ttest_ctxs[i]);
  }
  prepare_percentiles(ctx);
  return 0;
}

dudect_state_t dudect_main(dudect_ctx_t *ctx) {
  measure(ctx);
  update_statistics(ctx);
  return report(ctx);
}

int dudect_free(dudect_ctx_t *ctx) {
  free(ctx->ticks);
  free(ctx->exec_times);
  free(ctx->input_data);
  free(ctx->classes);
  for (int i = 0; i < DUDECT_TESTS; i++)
    free(ctx->ttest_ctxs[i]);
  return 0;
}

#endif /* DUDECT_AARCH64_H */
