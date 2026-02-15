#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Applying Multiplication LUT to Fql.h"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# إضافة الجدول في Fql.h بعد السطر الذي يحتوي على Fq_inv_table
# نبحث عن نهاية تعريف Fq_mul الحالي ونستبدله

# إنشاء نسخة محدثة
cat > Fql_with_lut.h << 'FQL'
#pragma once
#include "qruov_misc.h"
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

typedef          __int128  INT128_T ;
typedef unsigned __int128 UINT128_T ;

#define Fql_reduction(X)   Fql_reduction_1(X)
#define Fql_acc_refresh(X) Fql_acc_refresh_1(X)
#define Fql_acc_reduce(X)  Fql_acc_reduce_1(X)
#define Fql_mul(X,Y)       Fql_mul_1(X,Y)

// ============================================================================
// F_q  (q = 2^c - 1)
// ============================================================================

typedef uint8_t Fq ;

// ============================================================================
// Fq add/sub ...
// ============================================================================

inline static int Fq_reduction(int Z){
      Z = (Z & QRUOV_q) + ((Z & ~QRUOV_q) >> QRUOV_ceil_log_2_q) ;
  int C = ((Z+1) & ~QRUOV_q) ;
      Z += (C>>QRUOV_ceil_log_2_q) ;
      Z -= C ;
  return Z ;
}

inline static Fq Fq_add(Fq X, Fq Y){ return (Fq)Fq_reduction((int)X+(int)Y) ; }
inline static Fq Fq_sub(Fq X, Fq Y){ return (Fq)Fq_reduction((int)X-(int)Y+QRUOV_q) ; }

// ============================================================================
// Multiplication LUT (NEW!)
// ============================================================================

#ifdef USE_MUL_LUT

FQL

# إضافة الجدول
cat fq_mul_table.h >> Fql_with_lut.h

# إكمال الملف
cat >> Fql_with_lut.h << 'FQL2'

inline static Fq Fq_mul(Fq X, Fq Y){ return Fq_mul_table[X][Y]; }

#else

// Original multiplication (fallback)
inline static Fq Fq_mul(Fq X, Fq Y){ return (Fq)Fq_reduction((int)X*(int)Y) ; }

#endif

inline static Fq Fq_inv(Fq X){ extern Fq Fq_inv_table[QRUOV_q] ; return Fq_inv_table[X] ; }

FQL2

# نسخ باقي الملف الأصلي (من السطر 40 وما بعد)
tail -n +40 Fql.h.backup >> Fql_with_lut.h

echo "✅ Created Fql_with_lut.h"
echo ""
echo "Preview of changes:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep -A 5 "USE_MUL_LUT\|Fq_mul" Fql_with_lut.h | head -20

