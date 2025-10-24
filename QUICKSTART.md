# UHA SSOT - Quick Start Guide

Get your UHA blackbox repository up and running in 5 minutes.

---

## ✅ Step 1: Initial Setup (2 minutes)

```bash
cd ~/abba-01/uha-ssot

# Configure GitHub token
cp config/github_token.env.template config/github_token.env
nano config/github_token.env
# Add your GitHub token: ghp_YOUR_TOKEN_HERE

# Configure Zenodo token
cp secrets/zenodo_token.env.template secrets/zenodo_token.env
nano secrets/zenodo_token.env
# Add your Zenodo tokens

# Verify structure
ls -la
```

**Expected output**:
```
drwxr-xr-x  builds/
drwxr-xr-x  config/
drwxr-xr-x  log/
drwxr-xr-x  papers/
drwxr-xr-x  scripts/
drwxr-xr-x  secrets/
```

---

## ✅ Step 2: Test with Sandbox (1 minute)

```bash
# Build test version
./scripts/build.sh 0.0.1

# Verify build
./scripts/verify.sh 0.0.1
```

**Expected output**:
```
🎉 All critical tests passed!

Build v0.0.1 is ready for release.
```

---

## ✅ Step 3: Create Public Repository (1 minute)

```bash
# Option A: Use existing repo
ln -s ~/projects/uha-official repo

# Option B: Create new repo
mkdir -p ~/projects/uha-official
cd ~/projects/uha-official
git init
git remote add origin git@github.com:abba-01/uha-official.git
```

---

## ✅ Step 4: Test Release (1 minute)

```bash
cd ~/abba-01/uha-ssot

# Test release to sandbox
./scripts/release.sh 0.0.1
```

This will:
1. Copy manifest to public repo
2. Create Git tag
3. Mint Zenodo DOI (sandbox)
4. Log release

**Check**:
```bash
cat log/releases.csv
```

---

## 🎯 Your First Production Release

Once sandbox testing works:

```bash
# 1. Edit Zenodo config to use production
nano secrets/zenodo_token.env
# Change: ACTIVE_ZENODO_TOKEN=$ZENODO_TOKEN

# 2. Build production version
./scripts/build.sh 1.0.0

# 3. Verify
./scripts/verify.sh 1.0.0

# 4. Release
./scripts/release.sh 1.0.0

# 5. Verify DOI
# Go to https://zenodo.org and check your DOI
```

---

## 🧪 Test Reproduction Code

```bash
# Run example reproduction
python3 papers/hubble_reproduction.py
```

**Expected output**:
```
Hubble Tension Resolution - Reproduction Code
...
✅ Achieved 97.2% concordance
✅ Residual tension: 0.16σ
🎉 Result: CONCORDANCE ACHIEVED
```

---

## 📋 Checklist

Before first production release:

- [ ] GitHub token configured
- [ ] Zenodo token configured (sandbox tested)
- [ ] Public repository created
- [ ] Test build successful (v0.0.1)
- [ ] Test release successful
- [ ] Reproduction code runs
- [ ] .gitignore verified (no secrets committed)
- [ ] Switched to production Zenodo URL

---

## 🚨 Common Issues

### "Build directory not found"
```bash
# Run build first
./scripts/build.sh 1.0.0
```

### "GitHub push failed"
```bash
# Check token in config/github_token.env
# Ensure token has 'repo' scope
```

### "Zenodo API error"
```bash
# Check token in secrets/zenodo_token.env
# Verify using sandbox URL for testing
```

### "No wheel files found"
```bash
# This is OK for initial setup
# Means you're in placeholder mode
# Replace with actual build process
```

---

## 🎓 Next Steps

1. **Implement build process**: Edit `scripts/build.sh` with your compilation
2. **Add examples**: Create usage examples in public repo
3. **Write paper**: Reference DOI for reproducibility
4. **Submit for review**: Reviewers can verify via DOI

---

## 📞 Need Help?

Eric D. Martin
eric.martin1@wsu.edu

**Documentation**:
- Full README: `README.md`
- Build script: `scripts/build.sh`
- Release script: `scripts/release.sh`
- Verify script: `scripts/verify.sh`
