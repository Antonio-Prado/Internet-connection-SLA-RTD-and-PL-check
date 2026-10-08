# GitHub repo hardening settings (manual)

These settings are applied in the GitHub UI (they are not fully representable as files).

## Allow only squash merges
Go to: Settings → General → Pull Requests

- ✅ Allow squash merging
- ❌ Allow merge commits
- ❌ Allow rebase merging

(Optional)
- ✅ Automatically delete head branches

## Protect `master` (applied)
Go to: Settings → Rules → Rulesets (preferred) or Settings → Branches (classic)

Rules currently applied to `master` (classic branch protection, enforced for admins too):
- Require status checks to pass before merging (branch must be up to date):
  - `Bash lint (syntax + shellcheck) (ubuntu-latest)`
  - `Bash lint (syntax + shellcheck) (macos-latest)`
- Block force pushes
- Block deletions

Not applied (single maintainer cannot approve their own PRs):
- Require at least 1 approval
- Require conversation resolution

Consequence: direct pushes to `master` are rejected; changes go through a branch + PR.

## GitHub Actions hardening
Go to: Settings → Actions → General

- Workflow permissions: **Read repository contents** (read-only)
- **Require actions to be pinned to a full-length commit SHA** (enabled; `ci.yml` pins `actions/checkout` by SHA with the version as a comment, Dependabot keeps it updated)

## Secret scanning / push protection
Go to: Settings → Security (or Code security and analysis)

- Enable Secret scanning
- Enable Push protection

## Dependabot
Enable:
- Dependabot alerts
- Dependabot security updates
