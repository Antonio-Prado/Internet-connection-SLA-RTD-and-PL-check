# Internet connection SLA checker (RTT & Packet Loss)

A small Bash tool to verify an **access SLA** by measuring **ICMP Round-Trip Time (RTT)** and **Packet Loss (PL)** towards a set of **neutral reference targets** (e.g., RIPE Atlas anchors hosted at Internet Exchange Points).

It is intended for:

- **Customer-side checks** (internal validation / troubleshooting)
- **Evidence for tickets** opened to an ISP when the guaranteed SLA is not met

The script saves **raw measurement logs** plus a **machine-readable summary** into a bundle directory that can be attached to a support request.

## What changed in the current version

Compared to the original version, the script is now more suitable for SLA verification:

- **No root required by default** (root is only useful to use shorter ping intervals)
- **Packet loss is computed from TX/RX counters** (not from the rounded “X% packet loss” field)
- **RTT keeps decimals** (no integer truncation)
- **Per-target SLA evaluation** (if any neutral target violates the threshold, the SLA is marked as **KO**)
- Generates a **result bundle directory** with:
  - raw per-target ping logs
  - `meta.txt` (environment + run parameters)
  - `summary.json` (easy to ingest or paste into a ticket)
- Optional **progress bar** while `ping` runs (useful because `ping -q` is silent until completion)

## Requirements

- Bash
- `ping`
- `awk`, `grep`, `wc`, `tr`
- `python3` is **not required** to run the script (it was only used to apply edits during development)

The script works on common Linux distributions and macOS. On systems without `ping6`, it tries `ping -6`.

## Usage

```bash
./SLA.sh <icmp_packets> <rtt_threshold_ms> <loss_threshold_pct>
```

Example (acceptance test: RTT <= 50 ms, loss <= 0.02%):

```bash
./SLA.sh 1000 50 0.02
```

Notes:

- With `-q` (quiet), `ping` prints only a summary at the end. The script therefore shows a progress bar per target (estimated from `packets * interval`).
- For a quick sanity check use small counts (e.g., 20–50). For a more solid sample, use 1000 or more. Very large counts may take a long time.

## Output bundle (attach to ISP tickets)

Each run creates a directory (default name includes timestamp), for example:

```
sla_results_2026-01-13T20-58-56+0100/
  meta.txt
  summary.json
  ping_v4_193.201.40.210.log
  ping_v4_217.29.76.27.log
  ping_v6_2001_7f8_10_f00c__210.log
  ...
```

- **`meta.txt`** includes: OS, ping version (if available), thresholds, packet count, interval, target list, run ID.
- **`ping_*.log`** are **raw outputs** from `ping` (useful as evidence).
- **`summary.json`** contains a compact result summary (status + averages for reporting).

### SLA decision logic

The SLA is evaluated **per target**:

- **KO** if for any target:
  - RTT average is missing (often indicates 100% loss / no replies), or
  - RTT average is **greater** than the threshold, or
  - packet loss is **greater** than the threshold
- **OK** only if all configured targets meet the thresholds

Averages reported in `summary.json` are for convenience; they do not override the per-target decision.

## Configuration

Targets are defined at the top of `SLA.sh`:

```bash
AHv4=( "193.201.40.210" "217.29.76.27" )
AHv6=( "2001:7f8:10:f00c::210" "2001:1ac0:0:200:0:a5d1:6004:27" )
```

You can edit/add targets as needed.

### Environment variables

You can override some runtime parameters without editing the script:

- `SLA_OUTDIR` — set the output directory name/path
- `SLA_INTERVAL` — seconds between probes (default: `0.2`, root default: `0.11`)
- `SLA_SIZE` — ICMP payload size (default: `56`)
- `SLA_PROGRESS` — set to `0` to disable the progress bar

Example:

```bash
SLA_OUTDIR=/tmp/sla_run_001 SLA_INTERVAL=0.5 SLA_PROGRESS=0 ./SLA.sh 1000 50 0.02
```

## Notes and limitations

- Some networks and remote hosts may **deprioritize or filter ICMP**. If ICMP is filtered, results may be inconclusive even if user traffic works.
- The tool measures **RTT to the chosen neutral targets**, not end-to-end application performance.
- If IPv6 is not available, the IPv6 section is reported as **INCONCLUSIVE** (unless your SLA explicitly requires IPv6, in which case treat it as KO at the process/policy level).

## License

See `LICENSE`.

## Credits

Original project: SLA check script by SBTAP-AS59715, with thanks to @mphilosopher.
