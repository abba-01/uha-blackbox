# UHA Official - Single Source of Truth (SSOT)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.17388283.svg)](https://doi.org/10.5281/zenodo.17388283)

**Universal Horizon Address - Official Implementation**

> Private repository for building, releasing, and tracking UHA binary distributions.
> Implementation protected by US Patent 63/902,536.

---

## 🎯 Purpose

This SSOT repository enables:

1. **Security First**: Private implementation, public DOI + citation
2. **Academic Legitimacy**: Citable, permanent, reproducible
3. **Control & Automation**: Single command releases with audit trails
4. **Patent Strategy**: Maximum protection + maximum transparency

---

## 📁 Structure

```
~/abba-01/uha-ssot/
├── config/
│   ├── .zenodo.json              # Embargoed metadata (until 2099)
│   ├── github_token.env.template # GitHub API token template
│   └── cosmological_params.yml   # Default H₀, Ω values
│
├── builds/
│   └── 2025-10-24_v1.0.0/        # Versioned build artifacts
│       ├── manifest.json         # Build manifest
│       ├── checksums.sha256      # SHA-256 checksums
│       ├── *.whl                 # Binary wheels (not in git)
│       └── README.md             # Build-specific docs
│
├── repo/ -> ~/projects/uha-official/  # Symlink to public GitHub repo
│
├── secrets/
│   ├── signing_key.pem           # Binary signing key
│   └── zenodo_token.env.template # Zenodo API token template
│
├── scripts/
│   ├── build.sh                  # Build binaries
│   ├── release.sh                # Tag + push + mint DOI
│   └── verify.sh                 # Verify build integrity
│
├── papers/
│   └── hubble_reproduction.py    # Exact reproduction code
│
└── log/
    ├── releases.csv              # Release audit trail
    └── sync.log                  # Sync operations log
```

---

## 🚀 Quick Start

### 1. Initial Setup

```bash
cd ~/abba-01/uha-ssot

# Copy token templates and fill in your tokens
cp config/github_token.env.template config/github_token.env
cp secrets/zenodo_token.env.template secrets/zenodo_token.env

# Edit tokens (NEVER commit these files!)
nano config/github_token.env
nano secrets/zenodo_token.env

# Create symlink to public repo (if exists)
ln -s ~/projects/uha-official repo
```

### 2. Build Release

```bash
# Build version 1.0.0
cd ~/abba-01/uha-ssot
./scripts/build.sh 1.0.0
```

This creates `builds/2025-10-24_v1.0.0/` with:
- Binary wheels (`.whl`)
- Manifest (`manifest.json`)
- Checksums (`checksums.sha256`)
- Metadata

### 3. Verify Build

```bash
# Verify build integrity
./scripts/verify.sh 1.0.0
```

Runs 10 validation tests:
- ✅ Manifest schema
- ✅ Checksum verification
- ✅ Patent information
- ✅ Platform coverage
- ✅ Python version coverage
- ✅ File permissions

### 4. Release to Public

```bash
# Release to GitHub + mint Zenodo DOI
./scripts/release.sh 1.0.0
```

This will:
1. Copy manifest (NOT binaries) to public repo
2. Create Git tag `v1.0.0`
3. Push to GitHub
4. Mint Zenodo DOI
5. Log release in `log/releases.csv`

---

## 🔐 Security Model

### What's Private (This Repo)

❌ **NEVER EXPOSED**:
- Source code
- Compilation process
- Signing keys
- API tokens
- Binary wheels (`.whl` files)

### What's Public (GitHub Repo)

✅ **PUBLICLY AVAILABLE**:
- Manifest files
- Checksums
- Example usage code
- Documentation
- Git tags (version history)

### What's on Zenodo

✅ **EMBARGOED UNTIL 2099**:
- Manifest + checksums only
- DOI for citation
- Patent reference
- No implementation details

---

## 📊 Workflow

### Standard Release Cycle

```bash
# 1. Build
./scripts/build.sh 1.0.0

# 2. Verify
./scripts/verify.sh 1.0.0

# 3. Test locally
pip install builds/2025-10-24_v1.0.0/uha_official-1.0.0-*.whl
python papers/hubble_reproduction.py

# 4. Release
./scripts/release.sh 1.0.0
```

### Patch Release

```bash
# Build patch
./scripts/build.sh 1.0.1

# Verify + release
./scripts/verify.sh 1.0.1 && ./scripts/release.sh 1.0.1
```

---

## 📄 Files You Must Configure

### 1. GitHub Token (`config/github_token.env`)

```bash
GITHUB_TOKEN=ghp_YOUR_TOKEN_HERE
GITHUB_REPO=abba-01/uha-official
GITHUB_USER=abba-01
```

**Generate at**: https://github.com/settings/tokens
**Required scopes**: `repo`, `workflow`

### 2. Zenodo Token (`secrets/zenodo_token.env`)

```bash
ZENODO_TOKEN=YOUR_ZENODO_TOKEN_HERE
ZENODO_SANDBOX_TOKEN=YOUR_SANDBOX_TOKEN_HERE

# Use sandbox for testing
ACTIVE_ZENODO_URL=$ZENODO_SANDBOX_URL
ACTIVE_ZENODO_TOKEN=$ZENODO_SANDBOX_TOKEN
```

**Generate at**: https://zenodo.org/account/settings/applications/tokens/new/
**Required scopes**: `deposit:write`, `deposit:actions`

### 3. Signing Key (Optional but Recommended)

```bash
# Generate RSA key for binary signing
openssl genrsa -out secrets/signing_key.pem 4096
chmod 600 secrets/signing_key.pem
```

---

## 📝 Release Log

All releases are logged in `log/releases.csv`:

```csv
date,version,doi,manifest_sha256,github_tag,build_dir
2025-10-24,1.0.0,10.5281/zenodo.XXXXXXX,baf1c3...,v1.0.0,/root/abba-01/uha-ssot/builds/2025-10-24_v1.0.0
```

This provides:
- ✅ Complete audit trail
- ✅ Cryptographic verification
- ✅ Build provenance
- ✅ DOI tracking

---

## 🎓 Citation

When you publish papers using UHA, include:

```bibtex
@software{martin2025uha,
  author = {Martin, Eric D.},
  title = {Universal Horizon Address - Official Implementation},
  version = {1.0.0},
  year = {2025},
  doi = {10.5281/zenodo.XXXXXXX},
  url = {https://github.com/abba-01/uha-official},
  license = {Proprietary},
  note = {Patent US 63/902,536}
}
```

---

## ✅ What Reviewers See

When you submit papers with UHA results:

### Installation
```python
pip install uha-official==1.0.0
```

### Verification
```bash
# Download checksums from DOI
curl -O https://zenodo.org/record/XXXXXXX/files/checksums.sha256

# Verify installation
pip show uha-official | grep Version
sha256sum -c checksums.sha256
```

### Reproduction
```python
# Run your reproduction code
python hubble_reproduction.py
```

### What They Get
✅ Working library
✅ Reproducible results
✅ Verified checksums
✅ Citable DOI

### What They Don't Get
❌ Source code
❌ Implementation details
❌ Compilation process
❌ Your patent-protected algorithms

---

## 🛡️ Patent Information

**Number**: US Provisional Patent 63/902,536
**Filed**: September 15, 2024
**Owner**: All Your Baseline LLC
**Status**: Provisional (utility application pending)

**Protection Strategy**:
1. **Trade Secret**: Implementation details never disclosed
2. **Patent**: Method and system claims filed
3. **Embargo**: Zenodo DOI embargoed until 2099
4. **Binary Distribution**: Only compiled code released

This combination provides:
- ✅ Academic legitimacy (DOI, citations)
- ✅ Commercial value (licensing possible)
- ✅ Innovation protection (patent + trade secret)
- ✅ Reproducibility (verifiable checksums)

---

## 🚨 Important Security Notes

### NEVER Commit These Files

```
# Add to .gitignore
*.env
*_token*
*.key
*.pem
*.whl
*.so
*.dylib
*.dll
```

### Keep Private

- Source code
- Compilation scripts
- API tokens
- Signing keys
- Binary wheels

### Public is OK

- Manifests
- Checksums
- Documentation
- Example usage code
- Git tags

---

## 📚 Documentation

### For Users
- See `repo/README.md` (public repository)
- Example code in `repo/examples/`
- API documentation (if generated)

### For You
- Build process: `scripts/build.sh`
- Release process: `scripts/release.sh`
- Verification: `scripts/verify.sh`
- Reproduction: `papers/hubble_reproduction.py`

---

## 🤝 Support

**Owner**: Eric D. Martin
**Affiliation**: All Your Baseline LLC
**Email**: eric.martin1@wsu.edu
**ORCID**: 0009-0006-5944-1742

**For**:
- Licensing inquiries: eric.martin1@wsu.edu
- Bug reports: GitHub Issues (public repo)
- Academic collaboration: eric.martin1@wsu.edu

---

## 📅 Version History

| Version | Date | DOI | Notes |
|---------|------|-----|-------|
| 1.0.0 | 2025-10-24 | TBD | Initial release |

---

## 📖 Related Work

**N/U Algebra**: [10.5281/zenodo.17172694](https://doi.org/10.5281/zenodo.17172694)
**Validation Dataset**: [10.5281/zenodo.17221863](https://doi.org/10.5281/zenodo.17221863)
**Hubble Tension Paper**: In preparation

---

**Last Updated**: 2025-10-24
**License**: Proprietary - All Your Baseline LLC
**Patent**: US 63/902,536
