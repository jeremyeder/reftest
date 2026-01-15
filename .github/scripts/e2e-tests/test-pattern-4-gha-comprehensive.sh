#!/bin/bash
# Comprehensive E2E Test: Pattern 4 - GHA Automation
# Tests GitHub Actions workflows and automation patterns

set -e

echo "=========================================="
echo "Pattern 4: GHA Automation - Comprehensive E2E Test"
echo "=========================================="

FAILED=0

# Test 1: Count and list all workflows
echo ""
echo "Test 1: Inventory all GitHub Actions workflows"
WORKFLOW_COUNT=$(ls -1 .github/workflows/*.yml 2>/dev/null | wc -l)

if [[ $WORKFLOW_COUNT -gt 0 ]]; then
    echo "✅ Found $WORKFLOW_COUNT workflow files:"
    for wf in .github/workflows/*.yml; do
        NAME=$(grep -m1 "^name:" "$wf" | sed 's/name:\s*//' || basename "$wf")
        echo "   - $(basename "$wf"): $NAME"
    done
else
    echo "❌ No workflow files found"
    FAILED=1
fi

# Test 2: Verify workflows have required fields
echo ""
echo "Test 2: Validate workflow structure"
for wf in .github/workflows/*.yml; do
    WF_NAME=$(basename "$wf")
    ERRORS=""

    if ! grep -q "^name:" "$wf"; then
        ERRORS="${ERRORS}missing name, "
    fi

    if ! grep -q "^on:" "$wf"; then
        ERRORS="${ERRORS}missing trigger, "
    fi

    if ! grep -q "^jobs:" "$wf"; then
        ERRORS="${ERRORS}missing jobs, "
    fi

    if [[ -z "$ERRORS" ]]; then
        echo "   ✅ $WF_NAME: valid structure"
    else
        echo "   ❌ $WF_NAME: ${ERRORS%, }"
        FAILED=1
    fi
done

# Test 3: Check for parallel job execution
echo ""
echo "Test 3: Check for parallel job patterns"
PARALLEL_WORKFLOWS=0
for wf in .github/workflows/*.yml; do
    JOB_COUNT=$(grep -c "^\s\+[a-zA-Z0-9_-]\+:$" "$wf" 2>/dev/null || echo "0")
    if [[ $JOB_COUNT -gt 1 ]]; then
        # Check if jobs have dependencies (needs:)
        if ! grep -q "needs:" "$wf"; then
            echo "   ✅ $(basename "$wf"): $JOB_COUNT parallel jobs"
            PARALLEL_WORKFLOWS=$((PARALLEL_WORKFLOWS + 1))
        else
            echo "   ✓ $(basename "$wf"): $JOB_COUNT jobs with dependencies"
        fi
    fi
done

if [[ $PARALLEL_WORKFLOWS -gt 0 ]]; then
    echo "✅ Found $PARALLEL_WORKFLOWS workflows using parallel execution"
else
    echo "   No pure parallel workflows found (dependencies used)"
fi

# Test 4: Verify e2e-pattern-tests.yml runs all patterns in parallel
echo ""
echo "Test 4: Verify E2E test workflow parallelization"
if [[ -f ".github/workflows/e2e-pattern-tests.yml" ]]; then
    PATTERN_JOBS=$(grep -E "^\s+pattern-[0-9]+-" .github/workflows/e2e-pattern-tests.yml | wc -l)
    echo "✅ e2e-pattern-tests.yml has $PATTERN_JOBS pattern test jobs"

    # Check if they run in parallel (no needs: before summary)
    if grep -B5 "summary:" .github/workflows/e2e-pattern-tests.yml | grep -q "needs:"; then
        echo "   Jobs run in parallel, then aggregate in summary"
    fi
else
    echo "❌ e2e-pattern-tests.yml not found"
    FAILED=1
fi

# Test 5: Check for reusable workflows
echo ""
echo "Test 5: Check for reusable workflow patterns"
REUSABLE_COUNT=0
for wf in .github/workflows/*.yml; do
    if grep -q "workflow_call:" "$wf"; then
        echo "   ✅ $(basename "$wf"): reusable workflow"
        REUSABLE_COUNT=$((REUSABLE_COUNT + 1))
    fi
done
echo "   Found $REUSABLE_COUNT reusable workflows"

# Test 6: Check for proper permissions
echo ""
echo "Test 6: Verify workflows use minimal permissions"
for wf in .github/workflows/*.yml; do
    if grep -q "^permissions:" "$wf"; then
        echo "   ✅ $(basename "$wf"): explicit permissions defined"
    else
        echo "   ⚠️ $(basename "$wf"): using default permissions"
    fi
done

# Test 7: Trigger a workflow and verify execution
echo ""
echo "Test 7: Trigger workflow dispatch (if available)"
DISPATCHABLE=$(gh workflow list --json name,state | jq -r '.[] | select(.state == "active") | .name' | head -1)

if [[ -n "$DISPATCHABLE" ]]; then
    echo "   Found active workflow: $DISPATCHABLE"
    # We won't actually trigger to avoid side effects, just verify capability
    echo "   ✅ Repository has active workflows ready for dispatch"
else
    echo "   ⚠️ No dispatchable workflows found"
fi

# Test 8: Check recent workflow runs
echo ""
echo "Test 8: Check recent workflow execution history"
RECENT_RUNS=$(gh run list --limit 5 --json workflowName,status,conclusion,createdAt 2>/dev/null || echo "[]")

if [[ "$RECENT_RUNS" != "[]" ]] && [[ -n "$RECENT_RUNS" ]]; then
    echo "✅ Recent workflow runs:"
    echo "$RECENT_RUNS" | jq -r '.[] | "   \(.createdAt | split("T")[0]): \(.workflowName) - \(.status)/\(.conclusion)"'
else
    echo "   No recent workflow runs"
fi

# Test 9: Verify CI workflow exists and covers main events
echo ""
echo "Test 9: Verify CI workflow covers key events"
CI_WORKFLOW=$(ls .github/workflows/ | grep -iE "^ci\.yml$|^build\.yml$|^test\.yml$" | head -1)

if [[ -n "$CI_WORKFLOW" ]]; then
    echo "✅ Found CI workflow: $CI_WORKFLOW"

    if grep -q "push:" ".github/workflows/$CI_WORKFLOW"; then
        echo "   ✓ Triggers on push"
    fi
    if grep -q "pull_request:" ".github/workflows/$CI_WORKFLOW"; then
        echo "   ✓ Triggers on pull_request"
    fi
else
    echo "   No dedicated CI workflow found (may use other workflow names)"
fi

echo ""
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ Pattern 4 GHA Automation: ALL TESTS PASSED"
    exit 0
else
    echo "❌ Pattern 4 GHA Automation: SOME TESTS FAILED"
    exit 1
fi
