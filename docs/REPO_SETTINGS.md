# GitHub repo hardening settings (manual)

These settings are applied in the GitHub UI (they are not fully representable as files).

## Allow only squash merges
Go to: Settings → General → Pull Requests

- ✅ Allow squash merging
- ❌ Allow merge commits
- ❌ Allow rebase merging

(Optional)
- ✅ Automatically delete head branches

## Protect `main` (recommended)
Go to: Settings → Rules → Rulesets (preferred) or Settings → Branches (classic)

Recommended rules for `main`:
- Require a pull request before merging
- Require at least 1 approval
- Require conversation resolution
- Require status checks to pass:
  - CI / lint (this repo’s workflow)
- Block force pushes
- Block deletions

## GitHub Actions hardening
Go to: Settings → Actions → General

- Workflow permissions: **Read repository contents** (read-only)

## Secret scanning / push protection
Go to: Settings → Security (or Code security and analysis)

- Enable Secret scanning
- Enable Push protection

## Dependabot
Enable:
- Dependabot alerts
- Dependabot security updates
