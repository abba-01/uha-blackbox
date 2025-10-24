#!/bin/bash
# UHA Official Verification Script
# Verifies build integrity and checksums
# Usage: ./verify.sh <version>

set -euo pipefail

VERSION=${1:-}
if [[ -z "$VERSION" ]]; then
    echo "❌ Error: Version required"
    echo "Usage: ./verify.sh <version>"
    echo "Example: ./verify.sh 1.0.0"
    exit 1
fi

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Verifying UHA Official v${VERSION}${NC}"
echo "================================================"

# Find build directory for this version
BUILD_DIRS=("${SSOT_DIR}"/builds/*_v${VERSION})
if [[ ${#BUILD_DIRS[@]} -eq 0 || ! -d "${BUILD_DIRS[0]}" ]]; then
    echo -e "${RED}❌ Error: No build directory found for v${VERSION}${NC}"
    exit 1
fi

BUILD_DIR="${BUILD_DIRS[0]}"
echo -e "Build directory: ${BLUE}${BUILD_DIR}${NC}"
echo ""

# Initialize counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
pass() {
    echo -e "  ${GREEN}✅ PASS${NC}: $1"
    ((PASSED++))
}

fail() {
    echo -e "  ${RED}❌ FAIL${NC}: $1"
    ((FAILED++))
}

warn() {
    echo -e "  ${YELLOW}⚠️  WARN${NC}: $1"
    ((WARNINGS++))
}

# Test 1: Manifest exists
echo -e "${YELLOW}[1/10] Checking manifest.json...${NC}"
if [[ -f "$BUILD_DIR/manifest.json" ]]; then
    if jq empty "$BUILD_DIR/manifest.json" 2>/dev/null; then
        pass "manifest.json exists and is valid JSON"

        # Verify version in manifest
        MANIFEST_VERSION=$(jq -r '.version' "$BUILD_DIR/manifest.json")
        if [[ "$MANIFEST_VERSION" == "$VERSION" ]]; then
            pass "Version in manifest matches ($VERSION)"
        else
            fail "Version mismatch: manifest=$MANIFEST_VERSION, expected=$VERSION"
        fi
    else
        fail "manifest.json is not valid JSON"
    fi
else
    fail "manifest.json not found"
fi

# Test 2: Checksums file exists
echo ""
echo -e "${YELLOW}[2/10] Checking checksums.sha256...${NC}"
if [[ -f "$BUILD_DIR/checksums.sha256" ]]; then
    pass "checksums.sha256 exists"

    # Verify checksums
    cd "$BUILD_DIR"
    if sha256sum -c checksums.sha256 2>/dev/null >/dev/null; then
        pass "All checksums verified successfully"
    else
        # Try again with verbose output
        if sha256sum -c checksums.sha256 2>&1 | grep -q "FAILED"; then
            fail "One or more checksums failed verification"
        else
            warn "Checksums file exists but no files to verify"
        fi
    fi
else
    fail "checksums.sha256 not found"
fi

# Test 3: Build metadata
echo ""
echo -e "${YELLOW}[3/10] Checking build_metadata.txt...${NC}"
if [[ -f "$BUILD_DIR/build_metadata.txt" ]]; then
    pass "build_metadata.txt exists"
else
    warn "build_metadata.txt not found"
fi

# Test 4: README
echo ""
echo -e "${YELLOW}[4/10] Checking README.md...${NC}"
if [[ -f "$BUILD_DIR/README.md" ]]; then
    pass "README.md exists"
else
    warn "README.md not found"
fi

# Test 5: Wheel files
echo ""
echo -e "${YELLOW}[5/10] Checking wheel files...${NC}"
WHEEL_COUNT=$(find "$BUILD_DIR" -name "*.whl" | wc -l)
if [[ $WHEEL_COUNT -gt 0 ]]; then
    pass "Found $WHEEL_COUNT wheel files"

    # List wheels
    echo "  Wheels:"
    find "$BUILD_DIR" -name "*.whl" -exec basename {} \; | sed 's/^/    - /'
else
    warn "No wheel files found (may be in placeholder mode)"
fi

# Test 6: Manifest schema validation
echo ""
echo -e "${YELLOW}[6/10] Validating manifest schema...${NC}"
if [[ -f "$BUILD_DIR/manifest.json" ]]; then
    # Check required fields
    REQUIRED_FIELDS=("version" "build_date" "patent" "platforms" "python_versions")
    ALL_PRESENT=true

    for FIELD in "${REQUIRED_FIELDS[@]}"; do
        if jq -e ".$FIELD" "$BUILD_DIR/manifest.json" >/dev/null 2>&1; then
            :  # Field exists
        else
            fail "Required field missing: $FIELD"
            ALL_PRESENT=false
        fi
    done

    if $ALL_PRESENT; then
        pass "All required manifest fields present"
    fi
else
    fail "Cannot validate manifest schema (file not found)"
fi

# Test 7: Patent information
echo ""
echo -e "${YELLOW}[7/10] Verifying patent information...${NC}"
if [[ -f "$BUILD_DIR/manifest.json" ]]; then
    PATENT=$(jq -r '.patent' "$BUILD_DIR/manifest.json")
    if [[ "$PATENT" == "US 63/902,536" ]]; then
        pass "Patent information correct: $PATENT"
    else
        fail "Patent information incorrect or missing: $PATENT"
    fi
else
    fail "Cannot verify patent (manifest not found)"
fi

# Test 8: Platform coverage
echo ""
echo -e "${YELLOW}[8/10] Checking platform coverage...${NC}"
if [[ -f "$BUILD_DIR/manifest.json" ]]; then
    PLATFORM_COUNT=$(jq '.platforms | length' "$BUILD_DIR/manifest.json")
    if [[ $PLATFORM_COUNT -ge 4 ]]; then
        pass "Platform coverage: $PLATFORM_COUNT platforms"
    else
        warn "Limited platform coverage: only $PLATFORM_COUNT platforms"
    fi
else
    fail "Cannot check platform coverage (manifest not found)"
fi

# Test 9: Python version coverage
echo ""
echo -e "${YELLOW}[9/10] Checking Python version coverage...${NC}"
if [[ -f "$BUILD_DIR/manifest.json" ]]; then
    PY_VER_COUNT=$(jq '.python_versions | length' "$BUILD_DIR/manifest.json")
    if [[ $PY_VER_COUNT -ge 3 ]]; then
        pass "Python version coverage: $PY_VER_COUNT versions"
    else
        warn "Limited Python version coverage: only $PY_VER_COUNT versions"
    fi
else
    fail "Cannot check Python version coverage (manifest not found)"
fi

# Test 10: File permissions
echo ""
echo -e "${YELLOW}[10/10] Checking file permissions...${NC}"
SECURE_COUNT=0
INSECURE_COUNT=0

while IFS= read -r FILE; do
    PERMS=$(stat -c '%a' "$FILE")
    if [[ "${PERMS:0:1}" -le 6 ]]; then
        ((SECURE_COUNT++))
    else
        ((INSECURE_COUNT++))
        warn "Insecure permissions on $(basename "$FILE"): $PERMS"
    fi
done < <(find "$BUILD_DIR" -type f)

if [[ $INSECURE_COUNT -eq 0 ]]; then
    pass "All files have secure permissions"
else
    warn "$INSECURE_COUNT files have potentially insecure permissions"
fi

# Summary
echo ""
echo "================================================"
echo -e "${BLUE}Verification Summary${NC}"
echo "================================================"
echo -e "${GREEN}✅ Passed:  $PASSED${NC}"
echo -e "${RED}❌ Failed:  $FAILED${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 All critical tests passed!${NC}"
    echo ""
    echo -e "Build v${VERSION} is ready for release."
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo "Please fix the issues before releasing."
    exit 1
fi
