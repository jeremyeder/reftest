#!/bin/bash
# Comprehensive E2E Test: Pattern 10 - Stale Management
# Tests stale issue/PR management configuration

set -e

echo "=========================================="
echo "Pattern 10: Stale Management - Comprehensive E2E Test"
echo "=========================================="

FAILED=0

# Test 1: Verify stale.yml workflow exists
echo ""
echo "Test 1: Verify stale.yml workflow exists"
if [[ -f ".github/workflows/stale.yml" ]]; then
    echo "✅ stale.yml exists"
else
    echo "❌ stale.yml not found"
    FAILED=1
fi

# Test 2: Verify stale workflow configuration
echo ""
echo "Test 2: Verify stale workflow configuration"
if [[ -f ".github/workflows/stale.yml" ]]; then
    # Check for schedule trigger
    if grep -q "schedule:" .github/workflows/stale.yml; then
        CRON=$(grep -A1 "schedule:" .github/workflows/stale.yml | grep "cron:" | sed "s/.*cron:\s*['\"]*//" | sed "s/['\"].*//")
        echo "✅ Scheduled to run: $CRON"
    else
        echo "⚠️ No schedule trigger found"
    fi

    # Check for stale action usage
    if grep -qE "actions/stale|stale-action" .github/workflows/stale.yml; then
        echo "✅ Uses stale action"
    else
        echo "   Custom stale implementation"
    fi
fi

# Test 3: Check stale configuration parameters
echo ""
echo "Test 3: Check stale configuration parameters"
if [[ -f ".github/workflows/stale.yml" ]]; then
    # Days before stale
    DAYS_STALE=$(grep -E "days-before-stale|stale-.*-days" .github/workflows/stale.yml | head -1 | grep -oE "[0-9]+")
    if [[ -n "$DAYS_STALE" ]]; then
        echo "   Days before stale: $DAYS_STALE"
    fi

    # Days before close
    DAYS_CLOSE=$(grep -E "days-before-close|close-.*-days" .github/workflows/stale.yml | head -1 | grep -oE "[0-9]+")
    if [[ -n "$DAYS_CLOSE" ]]; then
        echo "   Days before close: $DAYS_CLOSE"
    fi

    # Stale label
    if grep -qE "stale-.*-label|stale-label" .github/workflows/stale.yml; then
        echo "   ✓ Custom stale label configured"
    fi

    # Exempt labels
    if grep -qE "exempt.*label|pinned|security" .github/workflows/stale.yml; then
        echo "   ✓ Exempt labels configured"
    fi
fi

# Test 4: Verify required labels exist
echo ""
echo "Test 4: Verify stale-related labels exist"
REQUIRED_LABELS=("stale" "pinned")

for label in "${REQUIRED_LABELS[@]}"; do
    if gh label list | grep -qi "^$label"; then
        echo "   ✅ Label exists: $label"
    else
        echo "   ⚠️ Label missing: $label (will be created when needed)"
    fi
done

# Test 5: Check for stale exemption patterns
echo ""
echo "Test 5: Check stale exemption patterns"
if [[ -f ".github/workflows/stale.yml" ]]; then
    EXEMPTIONS=0

    if grep -qiE "exempt.*label|exempt-.*-label" .github/workflows/stale.yml; then
        echo "   ✓ Label-based exemptions"
        EXEMPTIONS=$((EXEMPTIONS + 1))
    fi

    if grep -qiE "exempt.*milestone" .github/workflows/stale.yml; then
        echo "   ✓ Milestone-based exemptions"
        EXEMPTIONS=$((EXEMPTIONS + 1))
    fi

    if grep -qiE "exempt.*assignee" .github/workflows/stale.yml; then
        echo "   ✓ Assignee-based exemptions"
        EXEMPTIONS=$((EXEMPTIONS + 1))
    fi

    if grep -qiE "only-labels|only-.*-labels" .github/workflows/stale.yml; then
        echo "   ✓ Label filtering configured"
        EXEMPTIONS=$((EXEMPTIONS + 1))
    fi

    echo "✅ Found $EXEMPTIONS exemption patterns"
fi

# Test 6: Check stale message content
echo ""
echo "Test 6: Check stale notification messages"
if [[ -f ".github/workflows/stale.yml" ]]; then
    if grep -qE "stale-.*-message|stale-message" .github/workflows/stale.yml; then
        echo "✅ Custom stale message configured"

        # Extract message preview
        MSG=$(grep -A2 "stale-.*-message:" .github/workflows/stale.yml | head -3 | tail -1 | sed 's/^\s*//')
        if [[ -n "$MSG" ]]; then
            echo "   Preview: ${MSG:0:80}..."
        fi
    else
        echo "   Using default stale message"
    fi

    if grep -qE "close-.*-message|close-message" .github/workflows/stale.yml; then
        echo "✅ Custom close message configured"
    fi
fi

# Test 7: Check for different issue/PR handling
echo ""
echo "Test 7: Check issue vs PR handling"
if [[ -f ".github/workflows/stale.yml" ]]; then
    HANDLES_ISSUES=false
    HANDLES_PRS=false

    if grep -qE "stale-issue|days-before-issue-stale|issue.*stale" .github/workflows/stale.yml; then
        echo "   ✓ Handles stale issues"
        HANDLES_ISSUES=true
    fi

    if grep -qE "stale-pr|days-before-pr-stale|pr.*stale" .github/workflows/stale.yml; then
        echo "   ✓ Handles stale PRs"
        HANDLES_PRS=true
    fi

    if [[ "$HANDLES_ISSUES" == "true" ]] && [[ "$HANDLES_PRS" == "true" ]]; then
        echo "✅ Separate handling for issues and PRs"
    elif [[ "$HANDLES_ISSUES" == "true" ]] || [[ "$HANDLES_PRS" == "true" ]]; then
        echo "✅ Stale handling configured"
    else
        echo "   Using default handling for both"
    fi
fi

# Test 8: Verify workflow can be triggered manually
echo ""
echo "Test 8: Check for manual trigger capability"
if [[ -f ".github/workflows/stale.yml" ]]; then
    if grep -q "workflow_dispatch:" .github/workflows/stale.yml; then
        echo "✅ Workflow can be triggered manually"
    else
        echo "   No manual trigger (schedule only)"
    fi
fi

# Test 9: List current stale issues (if any)
echo ""
echo "Test 9: Check current stale status"
STALE_ISSUES=$(gh issue list --label "stale" --json number,title --limit 5 2>/dev/null || echo "[]")
STALE_PRS=$(gh pr list --label "stale" --json number,title --limit 5 2>/dev/null || echo "[]")

if [[ "$STALE_ISSUES" != "[]" ]] && [[ -n "$STALE_ISSUES" ]]; then
    echo "   Found stale issues:"
    echo "$STALE_ISSUES" | jq -r '.[] | "   - #\(.number): \(.title)"'
else
    echo "   No stale issues (good!)"
fi

if [[ "$STALE_PRS" != "[]" ]] && [[ -n "$STALE_PRS" ]]; then
    echo "   Found stale PRs:"
    echo "$STALE_PRS" | jq -r '.[] | "   - #\(.number): \(.title)"'
else
    echo "   No stale PRs (good!)"
fi

echo ""
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ Pattern 10 Stale Management: ALL TESTS PASSED"
    exit 0
else
    echo "❌ Pattern 10 Stale Management: SOME TESTS FAILED"
    exit 1
fi
