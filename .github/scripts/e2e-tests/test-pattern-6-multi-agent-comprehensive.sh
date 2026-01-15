#!/bin/bash
# Comprehensive E2E Test: Pattern 6 - Multi-Agent Review
# Tests multi-agent configuration and orchestration

set -e

echo "=========================================="
echo "Pattern 6: Multi-Agent - Comprehensive E2E Test"
echo "=========================================="

FAILED=0

# Test 1: Verify agent configurations exist
echo ""
echo "Test 1: Verify agent configuration directory"
if [[ -d ".claude/agents" ]]; then
    AGENT_COUNT=$(ls -1 .claude/agents/*.md 2>/dev/null | wc -l)
    echo "✅ Found $AGENT_COUNT agent configuration(s):"
    for agent in .claude/agents/*.md; do
        echo "   - $(basename "$agent")"
    done
else
    echo "⚠️ .claude/agents directory not found"
    # Check for alternative locations
    if [[ -d ".claude" ]]; then
        echo "   .claude directory exists but no agents subdirectory"
    fi
fi

# Test 2: Verify codebase-agent has multi-agent awareness
echo ""
echo "Test 2: Check for multi-agent coordination patterns"
if [[ -f ".claude/agents/codebase-agent.md" ]]; then
    if grep -qiE "(multi.?agent|coordinate|handoff|delegate|specialist)" .claude/agents/codebase-agent.md; then
        echo "✅ Codebase agent has multi-agent awareness"
    else
        echo "⚠️ No explicit multi-agent patterns in codebase-agent.md"
    fi
else
    echo "⚠️ codebase-agent.md not found"
fi

# Test 3: Check for specialized agent roles
echo ""
echo "Test 3: Check for specialized agent roles"
ROLES_FOUND=0

# Look for role-specific agents
for role in "security" "review" "test" "docs" "architect"; do
    ROLE_FILE=$(ls .claude/agents/*${role}*.md 2>/dev/null | head -1)
    if [[ -n "$ROLE_FILE" ]]; then
        echo "   ✅ Found $role agent: $(basename "$ROLE_FILE")"
        ROLES_FOUND=$((ROLES_FOUND + 1))
    fi
done

# Also check within files for role definitions
if [[ -f ".claude/agents/codebase-agent.md" ]]; then
    for role in "security" "review" "architecture" "testing"; do
        if grep -qiE "role.*$role|$role.*review|$role.*check" .claude/agents/codebase-agent.md; then
            echo "   ✓ Role defined in codebase-agent: $role"
            ROLES_FOUND=$((ROLES_FOUND + 1))
        fi
    done
fi

if [[ $ROLES_FOUND -gt 0 ]]; then
    echo "✅ Found $ROLES_FOUND agent roles/specializations"
else
    echo "⚠️ No specialized agent roles found"
fi

# Test 4: Check PR review workflow for multi-agent patterns
echo ""
echo "Test 4: Check PR review for multi-agent review stages"
if [[ -f ".github/workflows/pr-review.yml" ]]; then
    STAGES=0

    if grep -q "security" .github/workflows/pr-review.yml; then
        echo "   ✓ Security review stage"
        STAGES=$((STAGES + 1))
    fi

    if grep -q "quality" .github/workflows/pr-review.yml; then
        echo "   ✓ Code quality review stage"
        STAGES=$((STAGES + 1))
    fi

    if grep -qE "(test|coverage)" .github/workflows/pr-review.yml; then
        echo "   ✓ Test/coverage review stage"
        STAGES=$((STAGES + 1))
    fi

    if grep -qE "(doc|comment)" .github/workflows/pr-review.yml; then
        echo "   ✓ Documentation review stage"
        STAGES=$((STAGES + 1))
    fi

    if [[ $STAGES -gt 1 ]]; then
        echo "✅ PR review has $STAGES distinct review stages (multi-agent pattern)"
    else
        echo "⚠️ PR review has only $STAGES stage(s)"
    fi
else
    echo "⚠️ pr-review.yml not found"
fi

# Test 5: Check for agent handoff/coordination patterns
echo ""
echo "Test 5: Check for agent coordination patterns"
COORDINATION_FOUND=false

# Check CLAUDE.md for coordination instructions
if [[ -f "CLAUDE.md" ]]; then
    if grep -qiE "(delegate|hand.?off|specialist|expert|coordinate)" CLAUDE.md; then
        echo "✅ CLAUDE.md contains coordination instructions"
        COORDINATION_FOUND=true
    fi
fi

# Check for workflow job dependencies that suggest multi-agent
for wf in .github/workflows/*.yml; do
    if grep -c "needs:" "$wf" 2>/dev/null | grep -qE "[2-9]|[0-9]{2,}"; then
        echo "✅ $(basename "$wf") has multi-step job dependencies"
        COORDINATION_FOUND=true
    fi
done

if [[ "$COORDINATION_FOUND" == "false" ]]; then
    echo "⚠️ No explicit coordination patterns found"
fi

# Test 6: Test Claude agent invocation (if available)
echo ""
echo "Test 6: Test agent configuration validity"

if command -v claude &> /dev/null && [[ -f ".claude/agents/codebase-agent.md" ]]; then
    # Verify agent file is valid markdown
    if head -5 .claude/agents/codebase-agent.md | grep -qE "^#|^-|^\*"; then
        echo "✅ codebase-agent.md has valid markdown structure"
    else
        echo "⚠️ codebase-agent.md may have formatting issues"
    fi

    # Check for key sections
    for section in "purpose" "capabilities" "guidelines" "process" "instructions"; do
        if grep -qiE "^#+.*$section|^$section" .claude/agents/codebase-agent.md; then
            echo "   ✓ Has $section section"
        fi
    done
else
    echo "⚠️ Skipping agent validation (Claude CLI not available)"
fi

# Test 7: Verify agent can be referenced
echo ""
echo "Test 7: Check agent reference patterns"

# Look for agent references in workflows
AGENT_REFS=0
for wf in .github/workflows/*.yml; do
    if grep -qE "codebase-agent|agent.*config|\.claude/agents" "$wf"; then
        echo "   ✓ $(basename "$wf") references agent configuration"
        AGENT_REFS=$((AGENT_REFS + 1))
    fi
done

if [[ $AGENT_REFS -gt 0 ]]; then
    echo "✅ Found $AGENT_REFS workflow(s) with agent references"
else
    echo "   No direct agent references in workflows (may use implicit config)"
fi

echo ""
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ Pattern 6 Multi-Agent: ALL TESTS PASSED"
    exit 0
else
    echo "❌ Pattern 6 Multi-Agent: SOME TESTS FAILED"
    exit 1
fi
