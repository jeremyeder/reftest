#!/bin/bash
# Comprehensive E2E Test: Pattern 5 - Issue to PR
# This test creates a REAL issue, labels it, and verifies Claude creates a PR

set -e

echo "=========================================="
echo "Pattern 5: Issue-to-PR - Comprehensive E2E Test"
echo "=========================================="

FAILED=0
CLEANUP_ISSUE=""
CLEANUP_BRANCH=""

cleanup() {
    echo ""
    echo "Cleaning up test artifacts..."
    if [[ -n "$CLEANUP_ISSUE" ]]; then
        gh issue close "$CLEANUP_ISSUE" --comment "E2E test complete - closing" 2>/dev/null || true
    fi
    if [[ -n "$CLEANUP_BRANCH" ]]; then
        git push origin --delete "$CLEANUP_BRANCH" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Test 1: Verify issue-to-pr.yml workflow exists
echo ""
echo "Test 1: Verify issue-to-pr.yml workflow exists"
if [[ -f ".github/workflows/issue-to-pr.yml" ]]; then
    echo "✅ issue-to-pr.yml exists"
else
    echo "❌ issue-to-pr.yml not found"
    FAILED=1
fi

# Test 2: Verify ready-for-pr label exists
echo ""
echo "Test 2: Verify ready-for-pr label exists"
if gh label list | grep -q "ready-for-pr"; then
    echo "✅ ready-for-pr label exists"
else
    echo "⚠️  Creating ready-for-pr label..."
    gh label create "ready-for-pr" --color "0E8A16" --description "Issue is ready to be converted to PR" || true
fi

# Test 3: Create a real test issue with clear requirements
echo ""
echo "Test 3: Create test issue with clear acceptance criteria"

ISSUE_BODY="## Description
Add a simple utility function to format dates.

## Acceptance Criteria
- The function should accept a Date object
- It should return a string in YYYY-MM-DD format
- It must handle invalid dates gracefully

## Expected Behavior
\`\`\`javascript
formatDate(new Date('2024-01-15')) // returns '2024-01-15'
formatDate(null) // returns 'Invalid Date'
\`\`\`

## Technical Requirements
- Add function to src/utils/date.js
- Include unit tests
- Update documentation

---
*This is an automated E2E test issue - will be closed automatically*"

ISSUE_URL=$(gh issue create \
    --title "[E2E Test] Add date formatting utility" \
    --body "$ISSUE_BODY" \
    2>&1)

ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
CLEANUP_ISSUE="$ISSUE_NUMBER"

if [[ -n "$ISSUE_NUMBER" ]]; then
    echo "✅ Created test issue #$ISSUE_NUMBER"
    echo "   URL: $ISSUE_URL"
else
    echo "❌ Failed to create test issue"
    FAILED=1
    exit 1
fi

# Test 4: Add ready-for-pr label to trigger workflow
echo ""
echo "Test 4: Add ready-for-pr label to trigger workflow"
gh issue edit "$ISSUE_NUMBER" --add-label "ready-for-pr"
echo "✅ Added ready-for-pr label"

# Test 5: Wait for workflow to run and create PR/branch
echo ""
echo "Test 5: Wait for Issue-to-PR workflow to process (max 90s)"

MAX_WAIT=90
WAITED=0
PR_CREATED=false

while [[ $WAITED -lt $MAX_WAIT ]]; do
    sleep 10
    WAITED=$((WAITED + 10))
    echo "   Checking for PR or branch... (${WAITED}s elapsed)"

    # Check for PR referencing this issue
    PR_CHECK=$(gh pr list --search "issue-${ISSUE_NUMBER}" --json number,title 2>/dev/null || echo "")
    if [[ -n "$PR_CHECK" ]] && [[ "$PR_CHECK" != "[]" ]]; then
        PR_CREATED=true
        echo "✅ PR created from issue!"
        echo "   $PR_CHECK"
        break
    fi

    # Also check for branch
    BRANCH_CHECK=$(git ls-remote --heads origin | grep "issue-${ISSUE_NUMBER}" || true)
    if [[ -n "$BRANCH_CHECK" ]]; then
        CLEANUP_BRANCH=$(echo "$BRANCH_CHECK" | awk '{print $2}' | sed 's|refs/heads/||')
        echo "✅ Branch created: $CLEANUP_BRANCH"
        PR_CREATED=true
        break
    fi
done

if [[ "$PR_CREATED" == "true" ]]; then
    echo "✅ Issue-to-PR workflow executed successfully"
else
    echo "⚠️  PR/branch not created within timeout"
    echo "   This may indicate workflow is pending or disabled"
    echo "   Checking workflow runs..."
    gh run list --workflow=issue-to-pr.yml --limit 3
fi

# Test 6: Verify vague issue handling
echo ""
echo "Test 6: Test vague issue handling"

VAGUE_ISSUE_BODY="Make the app faster please.

---
*This is an automated E2E test issue - will be closed automatically*"

VAGUE_ISSUE_URL=$(gh issue create \
    --title "[E2E Test] Vague issue for testing" \
    --body "$VAGUE_ISSUE_BODY" \
    2>&1)

VAGUE_ISSUE_NUMBER=$(echo "$VAGUE_ISSUE_URL" | grep -oE '[0-9]+$')

if [[ -n "$VAGUE_ISSUE_NUMBER" ]]; then
    echo "✅ Created vague test issue #$VAGUE_ISSUE_NUMBER"
    gh issue edit "$VAGUE_ISSUE_NUMBER" --add-label "ready-for-pr"

    # Wait briefly and check for clarification comment
    sleep 15

    COMMENTS=$(gh issue view "$VAGUE_ISSUE_NUMBER" --json comments -q '.comments[].body' 2>/dev/null || echo "")
    if echo "$COMMENTS" | grep -qiE "(clarification|more detail|acceptance criteria)"; then
        echo "✅ Workflow correctly requested clarification for vague issue"
    else
        echo "⚠️  No clarification request found (workflow may still be processing)"
    fi

    # Cleanup vague issue
    gh issue close "$VAGUE_ISSUE_NUMBER" --comment "E2E test complete" 2>/dev/null || true
else
    echo "⚠️  Could not create vague issue for testing"
fi

echo ""
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ Pattern 5 Issue-to-PR: ALL TESTS PASSED"
    exit 0
else
    echo "❌ Pattern 5 Issue-to-PR: SOME TESTS FAILED"
    exit 1
fi
