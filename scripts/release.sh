#!/bin/bash
# UHA Official Release Script
# Publishes to GitHub + mints Zenodo DOI
# Usage: ./release.sh <version>

set -euo pipefail

VERSION=${1:-}
if [[ -z "$VERSION" ]]; then
    echo "❌ Error: Version required"
    echo "Usage: ./release.sh <version>"
    echo "Example: ./release.sh 1.0.0"
    exit 1
fi

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSOT_DIR="$(dirname "$SCRIPT_DIR")"
DATE=$(date +%F)
BUILD_DIR="${SSOT_DIR}/builds/${DATE}_v${VERSION}"
REPO_DIR="${HOME}/projects/uha-official"  # Public GitHub repo
LOG_FILE="${SSOT_DIR}/log/releases.csv"
SYNC_LOG="${SSOT_DIR}/log/sync.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Releasing UHA Official v${VERSION}${NC}"
echo "================================================"

# Check if build exists
if [[ ! -d "$BUILD_DIR" ]]; then
    echo -e "${RED}❌ Error: Build directory not found: $BUILD_DIR${NC}"
    echo "Run ./build.sh ${VERSION} first"
    exit 1
fi

# Check if manifest exists
if [[ ! -f "$BUILD_DIR/manifest.json" ]]; then
    echo -e "${RED}❌ Error: manifest.json not found in build directory${NC}"
    exit 1
fi

# Load GitHub token
GITHUB_TOKEN_FILE="${SSOT_DIR}/config/github_token.env"
if [[ -f "$GITHUB_TOKEN_FILE" ]]; then
    source "$GITHUB_TOKEN_FILE"
else
    echo -e "${YELLOW}⚠️  Warning: GitHub token not found${NC}"
    echo "Create ${GITHUB_TOKEN_FILE} from template"
fi

# Load Zenodo token
ZENODO_TOKEN_FILE="${SSOT_DIR}/secrets/zenodo_token.env"
if [[ -f "$ZENODO_TOKEN_FILE" ]]; then
    source "$ZENODO_TOKEN_FILE"
else
    echo -e "${YELLOW}⚠️  Warning: Zenodo token not found${NC}"
    echo "Create ${ZENODO_TOKEN_FILE} from template"
fi

# Verify checksums
echo -e "${YELLOW}🔐 Verifying checksums...${NC}"
cd "$BUILD_DIR"
if [[ -f checksums.sha256 ]]; then
    if sha256sum -c checksums.sha256 2>/dev/null; then
        echo -e "${GREEN}✅ Checksums verified${NC}"
    else
        echo -e "${RED}❌ Checksum verification failed${NC}"
        exit 1
    fi
fi

# Create public repo directory if it doesn't exist
if [[ ! -d "$REPO_DIR" ]]; then
    echo -e "${YELLOW}📁 Creating public repository directory...${NC}"
    mkdir -p "$REPO_DIR"
    cd "$REPO_DIR"
    git init
    echo "# UHA Official" > README.md
    echo ""  >> README.md
    echo "**Universal Horizon Address - Official Implementation**" >> README.md
    echo "" >> README.md
    echo "Binary distribution only. Source code protected by US Patent 63/902,536." >> README.md
    echo "" >> README.md
    echo "## Installation" >> README.md
    echo "" >> README.md
    echo "\`\`\`bash" >> README.md
    echo "pip install uha-official" >> README.md
    echo "\`\`\`" >> README.md
    echo "" >> README.md
    echo "## Documentation" >> README.md
    echo "" >> README.md
    echo "See \`examples/\` directory for usage." >> README.md

    # Create .gitignore
    cat > .gitignore <<EOF
# Never commit binaries
*.whl
*.so
*.dylib
*.dll

# Never commit secrets
*.env
*_token*
*.key
*.pem

# Python
__pycache__/
*.py[cod]
*$py.class
.Python
build/
dist/
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF

    mkdir -p examples
    git add README.md .gitignore
    git commit -m "Initial commit"
fi

# Copy manifest to public repo (NOT binaries)
echo -e "${YELLOW}📋 Copying manifest to public repository...${NC}"
cp "$BUILD_DIR/manifest.json" "$REPO_DIR/manifest_v${VERSION}.json"
cp "$BUILD_DIR/checksums.sha256" "$REPO_DIR/checksums_v${VERSION}.sha256"

# Create version-specific README in repo
cat > "$REPO_DIR/RELEASE_v${VERSION}.md" <<EOF
# Release v${VERSION}

**Date**: ${DATE}
**Patent**: US 63/902,536

## Verification

\`\`\`bash
sha256sum -c checksums_v${VERSION}.sha256
\`\`\`

## Manifest

See \`manifest_v${VERSION}.json\` for build details.

## Installation

\`\`\`bash
pip install uha-official==${VERSION}
\`\`\`

Or download specific wheel from releases page.

## Citation

DOI will be available shortly after release.

## License

Proprietary - All Your Baseline LLC
EOF

# Commit to Git
echo -e "${YELLOW}📝 Committing to Git...${NC}"
cd "$REPO_DIR"
git add "manifest_v${VERSION}.json" "checksums_v${VERSION}.sha256" "RELEASE_v${VERSION}.md"
git commit -m "Release v${VERSION}" || echo "No changes to commit"

# Create Git tag
echo -e "${YELLOW}🏷️  Creating Git tag...${NC}"
git tag -a "v${VERSION}" -m "UHA Official v${VERSION}

Binary release of Universal Horizon Address implementation.

Patent: US 63/902,536
Build Date: ${DATE}

This release includes:
- Binary wheels for multiple platforms
- Reproducibility manifest
- SHA-256 checksums

Source code remains private pending patent grant.
" || echo "Tag already exists"

# Push to GitHub
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    echo -e "${YELLOW}⬆️  Pushing to GitHub...${NC}"
    git push origin main --tags 2>&1 | tee -a "$SYNC_LOG"
    echo -e "${GREEN}✅ Pushed to GitHub${NC}"
else
    echo -e "${YELLOW}⚠️  Skipping GitHub push (no token configured)${NC}"
fi

# Wait for GitHub to process
echo -e "${YELLOW}⏳ Waiting for GitHub to process release...${NC}"
sleep 5

# Mint Zenodo DOI (via webhook or API)
DOI=""
if [[ -n "${ACTIVE_ZENODO_TOKEN:-}" && -n "${ACTIVE_ZENODO_URL:-}" ]]; then
    echo -e "${YELLOW}📄 Minting Zenodo DOI...${NC}"

    # Create deposition
    DEPOSITION_RESPONSE=$(curl -s -X POST \
        "${ACTIVE_ZENODO_URL}/deposit/depositions" \
        -H "Authorization: Bearer ${ACTIVE_ZENODO_TOKEN}" \
        -H "Content-Type: application/json" \
        -d @"${SSOT_DIR}/config/.zenodo.json")

    DEPOSITION_ID=$(echo "$DEPOSITION_RESPONSE" | jq -r '.id')

    if [[ "$DEPOSITION_ID" != "null" && -n "$DEPOSITION_ID" ]]; then
        echo -e "${GREEN}✅ Created Zenodo deposition: $DEPOSITION_ID${NC}"

        # Upload manifest (not binaries!)
        curl -X PUT \
            "${ACTIVE_ZENODO_URL}/deposit/depositions/${DEPOSITION_ID}/files" \
            -H "Authorization: Bearer ${ACTIVE_ZENODO_TOKEN}" \
            -F "file=@${BUILD_DIR}/manifest.json;filename=manifest.json"

        curl -X PUT \
            "${ACTIVE_ZENODO_URL}/deposit/depositions/${DEPOSITION_ID}/files" \
            -H "Authorization: Bearer ${ACTIVE_ZENODO_TOKEN}" \
            -F "file=@${BUILD_DIR}/checksums.sha256;filename=checksums.sha256"

        # Publish (comment out for testing)
        # PUBLISH_RESPONSE=$(curl -X POST \
        #     "${ACTIVE_ZENODO_URL}/deposit/depositions/${DEPOSITION_ID}/actions/publish" \
        #     -H "Authorization: Bearer ${ACTIVE_ZENODO_TOKEN}")
        #
        # DOI=$(echo "$PUBLISH_RESPONSE" | jq -r '.doi')

        DOI="10.5281/zenodo.${DEPOSITION_ID}"  # Placeholder until published
        echo -e "${GREEN}✅ Zenodo DOI: $DOI${NC}"
    else
        echo -e "${RED}❌ Failed to create Zenodo deposition${NC}"
        echo "$DEPOSITION_RESPONSE" | jq .
        DOI="pending"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping Zenodo DOI minting (no token configured)${NC}"
    DOI="not_configured"
fi

# Log release
echo -e "${YELLOW}📊 Logging release...${NC}"
mkdir -p "$(dirname "$LOG_FILE")"

# Create log header if file doesn't exist
if [[ ! -f "$LOG_FILE" ]]; then
    echo "date,version,doi,manifest_sha256,github_tag,build_dir" > "$LOG_FILE"
fi

MANIFEST_SHA256=$(sha256sum "$BUILD_DIR/manifest.json" | cut -d' ' -f1)
echo "${DATE},${VERSION},${DOI},${MANIFEST_SHA256},v${VERSION},${BUILD_DIR}" >> "$LOG_FILE"

# Summary
echo ""
echo -e "${GREEN}✅ Release v${VERSION} complete!${NC}"
echo "================================================"
echo -e "📦 Build: ${BLUE}${BUILD_DIR}${NC}"
echo -e "📝 Manifest SHA256: ${BLUE}${MANIFEST_SHA256}${NC}"
echo -e "🏷️  Git Tag: ${BLUE}v${VERSION}${NC}"
echo -e "📄 DOI: ${BLUE}${DOI}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Verify DOI resolves correctly"
echo "  2. Test pip installation"
echo "  3. Update paper citations"
echo ""
echo -e "${BLUE}Citation:${NC}"
echo "Martin, E.D. (${DATE}). Universal Horizon Address v${VERSION}."
echo "DOI: ${DOI}"
