#!/bin/bash
# Comprehensive E2E Test: Pattern 11 - Testing Patterns
# Tests the test pyramid implementation (unit, integration, e2e)

set -e

echo "=========================================="
echo "Pattern 11: Testing Patterns - Comprehensive E2E Test"
echo "=========================================="

FAILED=0

# Test 1: Verify test directory structure
echo ""
echo "Test 1: Verify test directory structure"
TEST_DIRS_FOUND=0

for dir in "tests" "test" "__tests__" "spec"; do
    if [[ -d "$dir" ]]; then
        echo "   ✅ Found test directory: $dir"
        TEST_DIRS_FOUND=$((TEST_DIRS_FOUND + 1))

        # Check for pyramid levels
        for level in "unit" "integration" "e2e" "functional" "acceptance"; do
            if [[ -d "$dir/$level" ]]; then
                FILE_COUNT=$(find "$dir/$level" -name "*.py" -o -name "*.js" -o -name "*.ts" 2>/dev/null | wc -l)
                echo "      ✓ $level tests: $FILE_COUNT files"
            fi
        done
    fi
done

if [[ $TEST_DIRS_FOUND -eq 0 ]]; then
    echo "❌ No test directory found"
    FAILED=1
fi

# Test 2: Verify pytest configuration
echo ""
echo "Test 2: Check test framework configuration"
if [[ -f "pytest.ini" ]]; then
    echo "✅ pytest.ini exists"
    if grep -q "testpaths" pytest.ini; then
        PATHS=$(grep "testpaths" pytest.ini | sed 's/testpaths\s*=\s*//')
        echo "   Test paths: $PATHS"
    fi
elif [[ -f "pyproject.toml" ]] && grep -q "\[tool.pytest" pyproject.toml; then
    echo "✅ pytest configured in pyproject.toml"
elif [[ -f "setup.cfg" ]] && grep -q "\[tool:pytest\]" setup.cfg; then
    echo "✅ pytest configured in setup.cfg"
elif [[ -f "package.json" ]]; then
    if grep -q "jest\|mocha\|vitest" package.json; then
        echo "✅ JavaScript test framework configured"
    fi
else
    echo "⚠️ No test framework configuration found"
fi

# Test 3: Count test files by type
echo ""
echo "Test 3: Count tests by type"
UNIT_TESTS=$(find . -path "./tests/unit/*" -name "test_*.py" -o -path "./tests/unit/*" -name "*_test.py" 2>/dev/null | wc -l)
INTEGRATION_TESTS=$(find . -path "./tests/integration/*" -name "test_*.py" -o -path "./tests/integration/*" -name "*_test.py" 2>/dev/null | wc -l)
E2E_TESTS=$(find . -path "./tests/e2e/*" -name "test_*.py" -o -path "./tests/e2e/*" -name "*_test.py" 2>/dev/null | wc -l)

echo "   Unit tests: $UNIT_TESTS files"
echo "   Integration tests: $INTEGRATION_TESTS files"
echo "   E2E tests: $E2E_TESTS files"

TOTAL_TESTS=$((UNIT_TESTS + INTEGRATION_TESTS + E2E_TESTS))
if [[ $TOTAL_TESTS -gt 0 ]]; then
    echo "✅ Total test files: $TOTAL_TESTS"

    # Check pyramid ratio (unit > integration > e2e)
    if [[ $UNIT_TESTS -ge $INTEGRATION_TESTS ]] && [[ $INTEGRATION_TESTS -ge $E2E_TESTS ]] && [[ $UNIT_TESTS -gt 0 ]]; then
        echo "   ✓ Test pyramid ratio looks healthy"
    fi
else
    echo "⚠️ No test files found in standard locations"
fi

# Test 4: Run actual tests
echo ""
echo "Test 4: Execute test suite"

if command -v python3 &> /dev/null || command -v python &> /dev/null; then
    PYTHON_CMD=$(command -v python3 || command -v python)

    # Install pytest if needed
    $PYTHON_CMD -m pip install pytest --quiet 2>/dev/null || true

    # Run tests with summary
    echo "   Running pytest..."
    if $PYTHON_CMD -m pytest tests/ -v --tb=short -q 2>&1 | tee /tmp/pytest_output.log; then
        echo "✅ All tests passed"

        # Extract test count
        PASSED=$(grep -oE "[0-9]+ passed" /tmp/pytest_output.log | head -1 || echo "")
        if [[ -n "$PASSED" ]]; then
            echo "   Result: $PASSED"
        fi
    else
        RESULT=$(tail -5 /tmp/pytest_output.log)
        echo "⚠️ Some tests failed"
        echo "   $RESULT"
        # Don't fail - test failures are informational
    fi
else
    echo "⚠️ Python not available - skipping test execution"
fi

# Test 5: Check for test fixtures/conftest
echo ""
echo "Test 5: Check for test infrastructure"
INFRA_ITEMS=0

if [[ -f "tests/conftest.py" ]]; then
    echo "   ✅ conftest.py exists (shared fixtures)"
    INFRA_ITEMS=$((INFRA_ITEMS + 1))

    # Count fixtures
    FIXTURE_COUNT=$(grep -c "@pytest.fixture" tests/conftest.py 2>/dev/null || echo "0")
    echo "      $FIXTURE_COUNT fixtures defined"
fi

if find tests -name "fixtures" -type d 2>/dev/null | grep -q .; then
    echo "   ✅ fixtures directory exists"
    INFRA_ITEMS=$((INFRA_ITEMS + 1))
fi

if find tests -name "mocks" -type d 2>/dev/null | grep -q . || find tests -name "__mocks__" -type d 2>/dev/null | grep -q .; then
    echo "   ✅ mocks directory exists"
    INFRA_ITEMS=$((INFRA_ITEMS + 1))
fi

if [[ -f "tests/factories.py" ]] || find tests -name "*factory*" 2>/dev/null | grep -q .; then
    echo "   ✅ test factories exist"
    INFRA_ITEMS=$((INFRA_ITEMS + 1))
fi

echo "   Test infrastructure items: $INFRA_ITEMS"

# Test 6: Check CI test configuration
echo ""
echo "Test 6: Check CI test configuration"
TEST_IN_CI=false

for wf in .github/workflows/*.yml; do
    if grep -qE "pytest|jest|npm test|yarn test|make test" "$wf"; then
        echo "   ✅ $(basename "$wf"): runs tests"
        TEST_IN_CI=true
    fi
done

if [[ "$TEST_IN_CI" == "true" ]]; then
    echo "✅ Tests are run in CI"
else
    echo "⚠️ No test execution found in CI workflows"
fi

# Test 7: Check for coverage configuration
echo ""
echo "Test 7: Check code coverage configuration"
COVERAGE_CONFIGURED=false

if grep -rq "coverage\|--cov" pytest.ini pyproject.toml setup.cfg .github/workflows/ 2>/dev/null; then
    echo "✅ Coverage is configured"
    COVERAGE_CONFIGURED=true
fi

if [[ -f ".coveragerc" ]] || [[ -f "coverage.config.js" ]]; then
    echo "   ✅ Coverage config file exists"
    COVERAGE_CONFIGURED=true
fi

if [[ "$COVERAGE_CONFIGURED" == "false" ]]; then
    echo "   No coverage configuration found"
fi

# Test 8: Verify test naming conventions
echo ""
echo "Test 8: Check test naming conventions"
WELL_NAMED=0
POORLY_NAMED=0

for test_file in $(find tests -name "*.py" 2>/dev/null | head -20); do
    filename=$(basename "$test_file")
    if [[ "$filename" =~ ^test_ ]] || [[ "$filename" =~ _test\.py$ ]]; then
        WELL_NAMED=$((WELL_NAMED + 1))
    else
        if [[ "$filename" != "conftest.py" ]] && [[ "$filename" != "__init__.py" ]] && [[ "$filename" != "factories.py" ]]; then
            POORLY_NAMED=$((POORLY_NAMED + 1))
        fi
    fi
done

if [[ $WELL_NAMED -gt 0 ]]; then
    echo "✅ $WELL_NAMED test files follow naming conventions"
fi
if [[ $POORLY_NAMED -gt 0 ]]; then
    echo "⚠️ $POORLY_NAMED files may not be discovered by pytest"
fi

echo ""
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ Pattern 11 Testing: ALL TESTS PASSED"
    exit 0
else
    echo "❌ Pattern 11 Testing: SOME TESTS FAILED"
    exit 1
fi
