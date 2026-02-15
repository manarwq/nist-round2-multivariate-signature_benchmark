#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 5: OpenMP Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""


echo "Copying baseline code..."
BASELINE_PATH="$HOME/Downloads/new/UOV_Clean_Analysis/01_Baseline/code/amd64"
mkdir -p code
cp -r "$BASELINE_PATH" ./code/

echo "Code copied"
echo ""


echo "Checking for existing OpenMP directives..."
grep -r "pragma omp" code/amd64/ --include="*.c" --include="*.h" | head -10 || echo "  No OpenMP directives found"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""


echo " Checking Makefile for OpenMP flags..."
grep -n "omp\|openmp" code/amd64/Makefile || echo "  No OpenMP flags in Makefile"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ready for OpenMP testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

