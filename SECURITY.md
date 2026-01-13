# Security Policy

This repository contains a small client-side measurement script intended to verify access SLAs (RTT and packet loss) towards neutral targets and to produce evidence bundles attachable to ISP support tickets.

## Supported Versions

This project is provided as-is. Only the latest version on the default branch is supported.

## Reporting a Vulnerability

If you believe you have found a security issue, please report it privately.

**Please do not open a public issue for security vulnerabilities.**

Send a report including:

- A clear description of the vulnerability and its impact
- Steps to reproduce (proof-of-concept)
- Affected versions/commits (if known)
- Any suggested mitigation or patch (optional)

## What counts as a security issue

Examples include:

- Command injection or unsafe shell evaluation
- Path traversal or unsafe file writes outside the intended output directory
- Insecure handling of environment variables that could lead to code execution
- Leakage of sensitive data beyond what the user expects (see “Data collected”)

## Data collected

The script is designed to be safe for end users and collects minimal diagnostic metadata:

- Hostname (best effort)
- OS/kernel string (`uname -a`)
- Ping implementation/version string (if available)
- Run parameters (packet count, interval, size, thresholds)
- Target list used for the run
- Raw `ping` outputs for each target

The script **does not** intentionally collect:

- User credentials
- Browser/application data
- Packet payload contents beyond ICMP echo request sizes
- Full network configuration beyond basic metadata

### Privacy note

`meta.txt` contains system information useful for ticketing. If you consider hostname or OS string sensitive, redact it before sharing bundles externally.

## Security best practices for users

- Run the script as a normal user. Root is **not required**.  
  If you choose to run as root to use a shorter interval, do so knowingly.
- Prefer running in a dedicated directory so the output bundle is easy to manage.
- Review the generated bundle before attaching it to third parties.

## Coordinated disclosure timeline

We aim to acknowledge reports within **7 days** and provide a fix or mitigation within **30 days** where feasible.

## Security updates

Security fixes will be released as normal commits. If a vulnerability is severe, we may also publish a brief advisory in the release notes or repository documentation.

Thank you for helping improve the security of this project.
