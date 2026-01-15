#!/bin/bash
# Comprehensive E2E Test: Pattern 3 - Dependabot Auto-Merge
# Tests the Dependabot configuration and auto-merge workflow

set -e

echo "=========================================="
echo "Pattern 3: Dependabot - Comprehensive E2E Test"
echo "=========================================="

FAILED=0

# Test 1: Verify dependabot.yml configuration exists
echo ""
echo "Test 1: Verify dependabot.yml configuration exists"
if [[ -f ".github/dependabot.yml" ]]; then
    echo "✅ .github/dependabot.yml exists"
else
    echo "❌ .github/dependabot.yml not found"
    FAILED=1
fi

# Test 2: Verify dependabot-auto-merge.yml workflow exists
echo ""
echo "Test 2: Verify dependabot-auto-merge.yml workflow exists"
if [[ -f ".github/workflows/dependabot-auto-merge.yml" ]]; then
    echo "✅ dependabot-auto-merge.yml exists"
else
    echo "❌ dependabot-auto-merge.yml not found"
    FAILED=1
fi

# Test 3: Validate dependabot.yml syntax
echo ""
echo "Test 3: Validate dependabot.yml syntax"
if command -v python3 &> /dev/null; then
    python3 << 'PYTHON_SCRIPT'
import yaml
import sys

try:
    with open('.github/dependabot.yml', 'r') as f:
        config = yaml.safe_load(f)

    if 'version' not in config:
        print("❌ Missing 'version' key")
        sys.exit(1)

    if 'updates' not in config:
        print("❌ Missing 'updates' key")
        sys.exit(1)

    print(f"✅ Valid dependabot.yml with {len(config['updates'])} update configurations")

    for i, update in enumerate(config['updates']):
        eco = update.get('package-ecosystem', 'unknown')
        dir = update.get('directory', '/')
        schedule = update.get('schedule', {}).get('interval', 'unknown')
        print(f"   [{i+1}] {eco} in {dir} - {schedule}")

except yaml.YAMLError as e:
    print(f"❌ YAML syntax error: {e}")
    sys.exit(1)
except FileNotFoundError:
    print("❌ File not found")
    sys.exit(1)
PYTHON_SCRIPT
else
    # Fallback to basic check
    if grep -q "package-ecosystem" .github/dependabot.yml && grep -q "schedule" .github/dependabot.yml; then
        echo "✅ dependabot.yml has required fields"
    else
        echo "❌ dependabot.yml missing required fields"
        FAILED=1
    fi
fi

# Test 4: Verify auto-merge workflow configuration
echo ""
echo "Test 4: Verify auto-merge workflow has correct triggers"
if grep -q "pull_request_target:" .github/workflows/dependabot-auto-merge.yml || \
   grep -q "pull_request:" .github/workflows/dependabot-auto-merge.yml; then
    echo "✅ Workflow has PR trigger"
else
    echo "❌ Workflow missing PR trigger"
    FAILED=1
fi

if grep -qE "dependabot\[bot\]|github.actor.*dependabot" .github/workflows/dependabot-auto-merge.yml; then
    echo "✅ Workflow checks for Dependabot actor"
else
    echo "⚠️  Workflow may not filter for Dependabot PRs"
fi

# Test 5: Check for version update type filtering
echo ""
echo "Test 5: Check for update type filtering (patch, minor, major)"
if grep -qE "(patch|minor|major|semver)" .github/workflows/dependabot-auto-merge.yml; then
    echo "✅ Workflow has version type filtering"

    if grep -qE "patch.*auto|auto.*patch" .github/workflows/dependabot-auto-merge.yml; then
        echo "   - Patch updates: likely auto-merged"
    fi
    if grep -qE "minor" .github/workflows/dependabot-auto-merge.yml; then
        echo "   - Minor updates: configured"
    fi
    if grep -qE "major" .github/workflows/dependabot-auto-merge.yml; then
        echo "   - Major updates: configured"
    fi
else
    echo "⚠️  No version type filtering found (all updates may be treated equally)"
fi

# Test 6: Check for required status checks
echo ""
echo "Test 6: Check for CI status check before merge"
if grep -qE "(status|check|ci|test|needs:)" .github/workflows/dependabot-auto-merge.yml; then
    echo "✅ Workflow appears to wait for status checks"
else
    echo "⚠️  Workflow may not wait for CI checks before merging"
fi

# Test 7: List recent Dependabot PRs (if any)
echo ""
echo "Test 7: Check for recent Dependabot activity"
DEPENDABOT_PRS=$(gh pr list --author "app/dependabot" --limit 5 --json number,title,state 2>/dev/null || echo "[]")

if [[ "$DEPENDABOT_PRS" != "[]" ]] && [[ -n "$DEPENDABOT_PRS" ]]; then
    echo "✅ Found Dependabot PRs:"
    echo "$DEPENDABOT_PRS" | jq -r '.[] | "   #\(.number): \(.title) [\(.state)]"'
else
    echo "   No recent Dependabot PRs found"
    echo "   (This is normal for new repos or repos with up-to-date dependencies)"
fi

# Test 8: Verify merge method configuration
echo ""
echo "Test 8: Check merge method configuration"
if grep -qE "(squash|merge|rebase)" .github/workflows/dependabot-auto-merge.yml; then
    MERGE_METHOD=$(grep -oE "(squash|merge|rebase)" .github/workflows/dependabot-auto-merge.yml | head -1)
    echo "✅ Merge method configured: $MERGE_METHOD"
else
    echo "   Using default merge method"
fi

echo ""
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ Pattern 3 Dependabot: ALL TESTS PASSED"
    exit 0
else
    echo "❌ Pattern 3 Dependabot: SOME TESTS FAILED"
    exit 1
fi
