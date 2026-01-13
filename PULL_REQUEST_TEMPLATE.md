# Pull Request

## Summary
Describe what this PR does and why.

## Type of change
Select all that apply:

- [ ] Bug fix
- [ ] New feature
- [ ] Refactor / cleanup
- [ ] Documentation
- [ ] CI / tooling
- [ ] Security fix

## Changes
List the main changes (bullet points).

- 
- 
- 

## Motivation / Context
Link to an issue, ticket, or describe the context.

## How to test
Provide reproducible steps:

1. 
2. 
3. 

### Test matrix (if applicable)
- [ ] macOS (BSD ping)
- [ ] Linux (iputils ping)
- [ ] BusyBox / minimal environment

## Evidence / Output
If relevant, attach or paste snippets from a sample run (redact sensitive data if needed):

- `meta.txt`:
- `summary.json`:
- Raw logs (`ping_*.log`):

## Backward compatibility
- [ ] No breaking changes
- [ ] Potential breaking change (explain):

## Security & Privacy considerations
- [ ] No new data collected
- [ ] Data collected changed (explain what/why)
- [ ] No new external network endpoints introduced
- [ ] New/changed environment variables (list):

## Documentation
- [ ] README updated
- [ ] SECURITY.md updated (if relevant)
- [ ] Comments/help output updated

## Checklist
- [ ] Script runs with `bash -n SLA.sh`
- [ ] Default run works without root privileges
- [ ] Packet loss is derived from TX/RX (no rounded percent parsing)
- [ ] RTT values preserve decimals (no truncation)
- [ ] Output bundle is created and contains `meta.txt` and `summary.json`
- [ ] Progress bar (if modified) can be disabled via `SLA_PROGRESS=0`
- [ ] I have reviewed generated bundles for unintended sensitive data exposure
