#!/bin/bash

# نأخذ الجزء قبل Fq_mul (حتى السطر 33)
head -33 Fql.h.backup > Fql_clean.h

# نضيف LUT
cat >> Fql_clean.h << 'LUTCODE'

// ============================================================================
// Fq multiplication - with optional LUT
// ============================================================================

#ifdef USE_MUL_LUT

LUTCODE

# نضيف الجدول
cat fq_mul_table_clean.h >> Fql_clean.h

# نضيف الدالة
cat >> Fql_clean.h << 'LUTCODE2'

inline static Fq Fq_mul(Fq X, Fq Y){ return Fq_mul_table[X][Y]; }

#else

inline static Fq Fq_mul(Fq X, Fq Y){ return (Fq)Fq_reduction((int)X*(int)Y) ; }

#endif

LUTCODE2

# نضيف الباقي (من سطر 35 وما بعد، ونتخطى Fq_mul)
tail -n +35 Fql.h.backup >> Fql_clean.h

echo "✅ Created Fql_clean.h"
wc -l Fql_clean.h

