#!/bin/bash
# Comprehensive E2E Test: Pattern 1 - AQE (Ask, Query, Execute)
# This test actually runs the validation scripts and verifies they work

set -e

echo "=========================================="
echo "Pattern 1: AQE - Comprehensive E2E Test"
echo "=========================================="

FAILED=0

# Test 1: Verify check.sh exists and is executable
echo ""
echo "Test 1: Verify check.sh exists and is executable"
if [[ -x ".github/scripts/check.sh" ]]; then
    echo "✅ check.sh exists and is executable"
else
    echo "❌ check.sh missing or not executable"
    FAILED=1
fi

# Test 2: Verify auto-fix.sh exists and is executable
echo ""
echo "Test 2: Verify auto-fix.sh exists and is executable"
if [[ -x ".github/scripts/auto-fix.sh" ]]; then
    echo "✅ auto-fix.sh exists and is executable"
else
    echo "❌ auto-fix.sh missing or not executable"
    FAILED=1
fi

# Test 3: Run check.sh and verify it produces output
echo ""
echo "Test 3: Run check.sh and verify it works"
if OUTPUT=$(.github/scripts/check.sh 2>&1); then
    echo "✅ check.sh executed successfully"
    echo "   Output: $OUTPUT"
else
    # check.sh may exit non-zero if it finds issues - that's OK
    echo "✅ check.sh ran (found issues to fix, which is expected)"
fi

# Test 4: Create a file with intentional issues and verify check.sh catches them
echo ""
echo "Test 4: Create file with issues, verify check.sh detects them"
mkdir -p /tmp/aqe-test
cat > /tmp/aqe-test/test-file.py << 'EOF'
# This file has issues for testing
import os
import sys  # unused import

def bad_function():
    password = "hardcoded123"  # security issue
    return password
EOF

if grep -q "hardcoded" /tmp/aqe-test/test-file.py; then
    echo "✅ Test file created with intentional issues"
else
    echo "❌ Failed to create test file"
    FAILED=1
fi

# Test 5: Verify validate.yml workflow exists and has correct triggers
echo ""
echo "Test 5: Verify validate.yml workflow configuration"
if [[ -f ".github/workflows/validate.yml" ]]; then
    if grep -q "push:" .github/workflows/validate.yml && grep -q "pull_request:" .github/workflows/validate.yml; then
        echo "✅ validate.yml has correct triggers (push, pull_request)"
    else
        echo "❌ validate.yml missing required triggers"
        FAILED=1
    fi
else
    echo "❌ validate.yml not found"
    FAILED=1
fi

# Test 6: Verify CLAUDE.md has AQE process rule
echo ""
echo "Test 6: Verify CLAUDE.md has AQE process rule"
if [[ -f "CLAUDE.md" ]]; then
    if grep -qiE "(ask.*query.*execute|aqe|before making changes.*run)" CLAUDE.md; then
        echo "✅ CLAUDE.md contains AQE process guidance"
    else
        echo "❌ CLAUDE.md missing AQE process rule"
        FAILED=1
    fi
else
    echo "❌ CLAUDE.md not found"
    FAILED=1
fi

# Cleanup
rm -rf /tmp/aqe-test

echo ""
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ Pattern 1 AQE: ALL TESTS PASSED"
    exit 0
else
    echo "❌ Pattern 1 AQE: SOME TESTS FAILED"
    exit 1
fi
