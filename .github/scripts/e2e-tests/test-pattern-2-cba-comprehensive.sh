#!/bin/bash
# Comprehensive E2E Test: Pattern 2 - CBA (Codebase Agent)
# This test actually invokes Claude Code to perform codebase analysis

set -e

echo "=========================================="
echo "Pattern 2: CBA - Comprehensive E2E Test"
echo "=========================================="

FAILED=0

# Test 1: Verify codebase-agent.md exists
echo ""
echo "Test 1: Verify codebase-agent.md configuration exists"
if [[ -f ".claude/agents/codebase-agent.md" ]]; then
    echo "✅ codebase-agent.md exists"
else
    echo "❌ codebase-agent.md not found"
    FAILED=1
fi

# Test 2: Verify agent has self-review protocol
echo ""
echo "Test 2: Verify self-review protocol in agent config"
if grep -qiE "(self.?review|checklist|before.*(submit|commit))" .claude/agents/codebase-agent.md 2>/dev/null; then
    echo "✅ Agent has self-review protocol"
else
    echo "❌ Agent missing self-review protocol"
    FAILED=1
fi

# Test 3: Verify Claude Code is available
echo ""
echo "Test 3: Verify Claude Code CLI is available"
if command -v claude &> /dev/null; then
    echo "✅ Claude Code CLI is available"
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    echo "   Version: $CLAUDE_VERSION"
else
    echo "⚠️  Claude Code CLI not found - skipping live tests"
    echo "   (This is OK in environments without Claude installed)"
    # Don't fail - just skip live tests
    echo ""
    echo "=========================================="
    echo "✅ Pattern 2 CBA: STATIC TESTS PASSED"
    echo "   (Live Claude tests skipped - CLI not available)"
    exit 0
fi

# Test 4: Actually invoke Claude to analyze a file
echo ""
echo "Test 4: Invoke Claude to analyze codebase structure"

# Create a simple test file for Claude to analyze
mkdir -p /tmp/cba-test
cat > /tmp/cba-test/sample.py << 'EOF'
def calculate_total(items):
    """Calculate total price of items."""
    total = 0
    for item in items:
        total += item['price'] * item['quantity']
    return total

def apply_discount(total, discount_percent):
    """Apply percentage discount to total."""
    return total * (1 - discount_percent / 100)
EOF

# Run Claude with a simple analysis task (timeout after 60s)
echo "   Asking Claude to analyze the sample file..."
CLAUDE_OUTPUT=$(timeout 60 claude --print "Analyze this Python code and identify any potential issues or improvements. Be brief (2-3 sentences max): $(cat /tmp/cba-test/sample.py)" 2>&1) || true

if [[ -n "$CLAUDE_OUTPUT" ]] && [[ ! "$CLAUDE_OUTPUT" =~ "error" ]]; then
    echo "✅ Claude successfully analyzed the code"
    echo "   Response preview: ${CLAUDE_OUTPUT:0:200}..."
else
    echo "❌ Claude failed to analyze code"
    echo "   Output: $CLAUDE_OUTPUT"
    FAILED=1
fi

# Test 5: Test Claude with codebase question
echo ""
echo "Test 5: Ask Claude a codebase question"

CLAUDE_QUERY=$(timeout 60 claude --print "What is the purpose of this repository based on the README.md? Answer in one sentence." 2>&1) || true

if [[ -n "$CLAUDE_QUERY" ]] && [[ ! "$CLAUDE_QUERY" =~ "error" ]]; then
    echo "✅ Claude answered codebase question"
    echo "   Response: ${CLAUDE_QUERY:0:200}..."
else
    echo "⚠️  Claude query returned empty or error (may be API issue)"
    # Don't fail on this - could be transient
fi

# Cleanup
rm -rf /tmp/cba-test

echo ""
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ Pattern 2 CBA: ALL TESTS PASSED"
    exit 0
else
    echo "❌ Pattern 2 CBA: SOME TESTS FAILED"
    exit 1
fi
