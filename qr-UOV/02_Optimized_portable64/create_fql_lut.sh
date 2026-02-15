#!/bin/bash

# نأخذ أول 35 سطر من الأصلي (قبل Fq_mul)
head -35 Fql.h.backup > Fql_with_lut_v2.h

# نضيف الـ LUT
cat >> Fql_with_lut_v2.h << 'LUTCODE'

// ============================================================================
// Multiplication LUT (conditional)
// ============================================================================

#ifdef USE_MUL_LUT

LUTCODE

# نضيف الجدول النظيف
cat fq_mul_table_clean.h >> Fql_with_lut_v2.h

# نضيف الدالة مع LUT
cat >> Fql_with_lut_v2.h << 'LUTCODE2'

inline static Fq Fq_mul(Fq X, Fq Y){ return Fq_mul_table[X][Y]; }

#else

// Original multiplication
inline static Fq Fq_mul(Fq X, Fq Y){ return (Fq)Fq_reduction((int)X*(int)Y) ; }

#endif

LUTCODE2

# نضيف باقي الملف الأصلي (من سطر 36 وما بعد، بدون Fq_mul الأصلي)
tail -n +36 Fql.h.backup | grep -v "inline static Fq Fq_mul" >> Fql_with_lut_v2.h

echo "✅ Created Fql_with_lut_v2.h"

