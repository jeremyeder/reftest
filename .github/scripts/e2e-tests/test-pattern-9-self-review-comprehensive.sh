#!/bin/bash
# Comprehensive E2E Test: Pattern 9 - Self-Review
# Tests self-review checklist and verification patterns

set -e

echo "=========================================="
echo "Pattern 9: Self-Review - Comprehensive E2E Test"
echo "=========================================="

FAILED=0

# Test 1: Verify self-review is documented
echo ""
echo "Test 1: Verify self-review documentation exists"
SELF_REVIEW_FOUND=false

if [[ -f ".claude/agents/codebase-agent.md" ]]; then
    if grep -qiE "self.?review|before.*(submit|commit|push)|checklist" .claude/agents/codebase-agent.md; then
        echo "✅ Self-review documented in codebase-agent.md"
        SELF_REVIEW_FOUND=true
    fi
fi

if [[ -f "CLAUDE.md" ]]; then
    if grep -qiE "self.?review|before.*(submit|commit|push)|checklist" CLAUDE.md; then
        echo "✅ Self-review documented in CLAUDE.md"
        SELF_REVIEW_FOUND=true
    fi
fi

if [[ "$SELF_REVIEW_FOUND" == "false" ]]; then
    echo "❌ Self-review not documented"
    FAILED=1
fi

# Test 2: Verify checklist items exist
echo ""
echo "Test 2: Check for specific self-review checklist items"
CHECKLIST_ITEMS=0

for file in CLAUDE.md .claude/agents/codebase-agent.md CONTRIBUTING.md; do
    if [[ -f "$file" ]]; then
        # Look for checklist patterns
        if grep -qE "^\s*[-*]\s*\[.\]" "$file"; then
            COUNT=$(grep -cE "^\s*[-*]\s*\[.\]" "$file")
            echo "   ✓ $file has $COUNT checklist items"
            CHECKLIST_ITEMS=$((CHECKLIST_ITEMS + COUNT))
        fi

        # Look for numbered checklist
        if grep -qE "^\s*[0-9]+\." "$file" | head -10 | grep -qiE "(review|check|verify|ensure|test)"; then
            echo "   ✓ $file has numbered review steps"
            CHECKLIST_ITEMS=$((CHECKLIST_ITEMS + 1))
        fi
    fi
done

if [[ $CHECKLIST_ITEMS -gt 0 ]]; then
    echo "✅ Found $CHECKLIST_ITEMS checklist items"
else
    echo "⚠️ No explicit checklist items found"
fi

# Test 3: Verify key review areas are covered
echo ""
echo "Test 3: Verify key review areas are covered"
AREAS_COVERED=0

REVIEW_AREAS=(
    "test|testing"
    "security|vulnerabilit"
    "document|comment"
    "lint|format|style"
    "type|typing"
    "error|exception"
    "performance|optim"
)

for area_pattern in "${REVIEW_AREAS[@]}"; do
    AREA_NAME=$(echo "$area_pattern" | cut -d'|' -f1)
    for file in CLAUDE.md .claude/agents/codebase-agent.md; do
        if [[ -f "$file" ]] && grep -qiE "$area_pattern" "$file"; then
            echo "   ✓ $AREA_NAME review covered"
            AREAS_COVERED=$((AREAS_COVERED + 1))
            break
        fi
    done
done

if [[ $AREAS_COVERED -ge 4 ]]; then
    echo "✅ Good coverage: $AREAS_COVERED/7 review areas documented"
else
    echo "⚠️ Limited coverage: $AREAS_COVERED/7 review areas documented"
fi

# Test 4: Check for pre-commit hooks
echo ""
echo "Test 4: Check for pre-commit hooks"
if [[ -f ".pre-commit-config.yaml" ]]; then
    echo "✅ pre-commit configuration exists"
    HOOK_COUNT=$(grep -c "repo:" .pre-commit-config.yaml 2>/dev/null || echo "0")
    echo "   Found $HOOK_COUNT hook repositories configured"
elif [[ -f ".git/hooks/pre-commit" ]]; then
    echo "✅ Git pre-commit hook exists"
else
    echo "   No pre-commit hooks configured"
fi

# Test 5: Check for CI self-review steps
echo ""
echo "Test 5: Check CI for self-review enforcement"
ENFORCEMENT_FOUND=false

for wf in .github/workflows/*.yml; do
    # Look for lint, type-check, format verification
    if grep -qiE "(lint|pylint|eslint|flake8)" "$wf"; then
        echo "   ✓ $(basename "$wf"): lint check"
        ENFORCEMENT_FOUND=true
    fi
    if grep -qiE "(type.?check|mypy|pyright|tsc.*--noEmit)" "$wf"; then
        echo "   ✓ $(basename "$wf"): type check"
        ENFORCEMENT_FOUND=true
    fi
    if grep -qiE "(format|prettier|black.*--check)" "$wf"; then
        echo "   ✓ $(basename "$wf"): format check"
        ENFORCEMENT_FOUND=true
    fi
    if grep -qiE "(test|pytest|jest|mocha)" "$wf"; then
        echo "   ✓ $(basename "$wf"): test execution"
        ENFORCEMENT_FOUND=true
    fi
done

if [[ "$ENFORCEMENT_FOUND" == "true" ]]; then
    echo "✅ CI enforces self-review items"
else
    echo "⚠️ No automated self-review enforcement in CI"
fi

# Test 6: Validate self-review process with Claude (if available)
echo ""
echo "Test 6: Test self-review with Claude"

if command -v claude &> /dev/null; then
    # Create a sample code change
    cat > /tmp/sample_change.py << 'EOF'
def process_data(data):
    result = []
    for item in data:
        if item > 0:
            result.append(item * 2)
    return result
EOF

    echo "   Asking Claude to perform self-review on sample code..."
    REVIEW_OUTPUT=$(timeout 60 claude --print "Perform a self-review of this code. Check for: 1) Tests needed 2) Error handling 3) Documentation 4) Type hints. Be brief (3-4 bullet points max):

$(cat /tmp/sample_change.py)" 2>&1) || true

    if [[ -n "$REVIEW_OUTPUT" ]] && [[ ! "$REVIEW_OUTPUT" =~ "error" ]]; then
        echo "✅ Claude performed self-review"
        echo "   Review points: ${REVIEW_OUTPUT:0:200}..."
    else
        echo "⚠️ Claude self-review unavailable"
    fi

    rm -f /tmp/sample_change.py
else
    echo "⚠️ Claude CLI not available - skipping live test"
fi

# Test 7: Check for review request template
echo ""
echo "Test 7: Check for PR template with review checklist"
PR_TEMPLATE=""
for template in ".github/PULL_REQUEST_TEMPLATE.md" ".github/pull_request_template.md" "PULL_REQUEST_TEMPLATE.md"; do
    if [[ -f "$template" ]]; then
        PR_TEMPLATE="$template"
        break
    fi
done

if [[ -n "$PR_TEMPLATE" ]]; then
    echo "✅ PR template exists: $PR_TEMPLATE"
    if grep -qE "\[.\]" "$PR_TEMPLATE"; then
        CHECKLIST_ITEMS=$(grep -cE "\[.\]" "$PR_TEMPLATE")
        echo "   Contains $CHECKLIST_ITEMS checklist items"
    fi
else
    echo "   No PR template found (optional)"
fi

echo ""
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ Pattern 9 Self-Review: ALL TESTS PASSED"
    exit 0
else
    echo "❌ Pattern 9 Self-Review: SOME TESTS FAILED"
    exit 1
fi
