#!/bin/bash
# Comprehensive E2E Test Suite Runner
# Runs all pattern tests with detailed output

set -e

echo "============================================================"
echo "     COMPREHENSIVE E2E PATTERN VALIDATION SUITE"
echo "============================================================"
echo ""
echo "Started: $(date)"
echo "Repository: $(git remote get-url origin 2>/dev/null || echo 'local')"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSED=0
FAILED=0
SKIPPED=0

# Array of tests with descriptions
declare -A TESTS
TESTS["test-pattern-1-aqe-comprehensive.sh"]="Pattern 1: AQE (Ask, Query, Execute)"
TESTS["test-pattern-2-cba-comprehensive.sh"]="Pattern 2: CBA (Codebase Agent)"
TESTS["test-pattern-3-dependabot-comprehensive.sh"]="Pattern 3: Dependabot Auto-Merge"
TESTS["test-pattern-4-gha-comprehensive.sh"]="Pattern 4: GHA Automation"
TESTS["test-pattern-5-issue-to-pr-comprehensive.sh"]="Pattern 5: Issue-to-PR"
TESTS["test-pattern-6-multi-agent-comprehensive.sh"]="Pattern 6: Multi-Agent Review"
TESTS["test-pattern-7-pr-review-comprehensive.sh"]="Pattern 7: PR Auto-Review"
TESTS["test-pattern-8-security-comprehensive.sh"]="Pattern 8: Security Patterns"
TESTS["test-pattern-9-self-review-comprehensive.sh"]="Pattern 9: Self-Review"
TESTS["test-pattern-10-stale-comprehensive.sh"]="Pattern 10: Stale Management"
TESTS["test-pattern-11-testing-comprehensive.sh"]="Pattern 11: Testing Patterns"
TESTS["test-pattern-claude-fix-comprehensive.sh"]="Claude Fix Issue Workflow"

RESULTS=()

for test_script in "${!TESTS[@]}"; do
    test_name="${TESTS[$test_script]}"
    test_path="$SCRIPT_DIR/$test_script"

    echo ""
    echo "============================================================"
    echo "Running: $test_name"
    echo "============================================================"

    if [[ ! -f "$test_path" ]]; then
        echo "⚠️  Test script not found: $test_script"
        SKIPPED=$((SKIPPED + 1))
        RESULTS+=("⚠️  $test_name: SKIPPED (not found)")
        continue
    fi

    chmod +x "$test_path"

    if timeout 300 "$test_path" 2>&1; then
        PASSED=$((PASSED + 1))
        RESULTS+=("✅ $test_name: PASSED")
    else
        EXIT_CODE=$?
        if [[ $EXIT_CODE -eq 124 ]]; then
            echo "⚠️  Test timed out after 300s"
            RESULTS+=("⚠️  $test_name: TIMEOUT")
            SKIPPED=$((SKIPPED + 1))
        else
            FAILED=$((FAILED + 1))
            RESULTS+=("❌ $test_name: FAILED")
        fi
    fi
done

echo ""
echo "============================================================"
echo "                    TEST RESULTS SUMMARY"
echo "============================================================"
echo ""

for result in "${RESULTS[@]}"; do
    echo "$result"
done

echo ""
echo "------------------------------------------------------------"
echo "Total: $((PASSED + FAILED + SKIPPED)) tests"
echo "  ✅ Passed:  $PASSED"
echo "  ❌ Failed:  $FAILED"
echo "  ⚠️  Skipped: $SKIPPED"
echo "------------------------------------------------------------"
echo ""
echo "Completed: $(date)"
echo ""

if [[ $FAILED -gt 0 ]]; then
    echo "❌ SOME TESTS FAILED"
    exit 1
else
    echo "✅ ALL TESTS PASSED"
    exit 0
fi
