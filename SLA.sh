#!/usr/bin/env bash
# Internet connection SLA checker (neutral targets, ISP/ticket-friendly)
# - Per-target SLA: fail if any target exceeds RTT threshold or loss threshold
# - Loss computed from TX/RX counters (no rounded percent)
# - RTT keeps decimals
# - Saves raw logs + meta + summary.json in an output bundle directory
#
# Usage: ./SLA.sh <icmp_packets> <rtt_threshold_ms> <loss_threshold_pct>
# Example: ./SLA.sh 1000 50 0.02

set -u
IFS=$' \n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Neutral targets (edit as needed)
AHv4=( "193.201.40.211" "217.29.76.27" )
AHv6=( "2a0f:80:f::211" "2001:1ac0:0:200:0:a5d1:6004:27" )

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "$1 is needed." >&2
    exit 1
  fi
}

is_number() {
  [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

is_root() {
  [ "$(id -u)" -eq 0 ]
}

# Float comparisons using awk (portable)
fgt() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>b)}'; }   # a > b
fle() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a<=b)}'; }  # a <= b

sanitize_filename() {
  # Replace chars that are problematic in filenames
  echo "$1" | tr ':/' '__'
}

progress_bar() {
  # progress_bar <pid> <est_seconds> <label>
  local pid="$1"
  local est="$2"
  local label="$3"

  local width=30
  local start now elapsed pct filled
  start="$(date +%s)"

  while kill -0 "$pid" 2>/dev/null; do
    now="$(date +%s)"
    elapsed=$((now - start))

    pct="$(awk -v e="$elapsed" -v t="$est" 'BEGIN{
      if (t<=0) p=0; else p=int((e/t)*100);
      if (p<0) p=0; if (p>99) p=99; print p
    }')"

    filled=$((pct * width / 100))

    local bar empty
    bar="$(printf "%*s" "$filled" "" | tr ' ' '#')"
    empty="$(printf "%*s" "$((width - filled))" "" | tr ' ' '.')"

    printf "\r%-24s [%s%s] %3s%% (%ss/%ss)" \
      "$label" "$bar" "$empty" "$pct" "$elapsed" "$est" >&2
    sleep 1
  done

  printf "\r%-24s [%s] 100%%\n" \
    "$label" "$(printf "%*s" "$width" "" | tr ' ' '#')" >&2
}


# Parse ping output and print: TX RX LOSS_PCT RTT_AVG
# LOSS_PCT is computed from TX/RX to avoid rounding artifacts.
parse_ping() {
  local f="$1"

  local TX RX LOSS RTT_AVG
  TX=$(awk -F'[, ]+' '/packets transmitted/ {print $1; exit}' "$f" 2>/dev/null || true)
  RX=$(awk -F'[, ]+' '/packets transmitted/ {print $4; exit}' "$f" 2>/dev/null || true)
  [ -z "${TX:-}" ] && TX=0
  [ -z "${RX:-}" ] && RX=0

  LOSS=$(awk -v tx="$TX" -v rx="$RX" 'BEGIN{ if (tx==0) printf "100.00000"; else printf "%.5f", ((tx-rx)/tx)*100 }')

  RTT_AVG=$(awk '
    /(rtt|round-trip).*=/ {
      line=$0
      sub(/.*= /,"",line)
      sub(/ ms.*/,"",line)
      n=split(line,a,"/")
      if (n>=3) { printf "%.3f", a[2]; exit }
    }
  ' "$f" 2>/dev/null || true)

  echo "$TX $RX $LOSS $RTT_AVG"
}

need_cmd awk
need_cmd ping
need_cmd date
need_cmd uname
need_cmd hostname
need_cmd grep
need_cmd wc
need_cmd tr

# ping6 may be missing: fall back to "ping -6" when available
PING6_CMD=()
if command -v ping6 >/dev/null 2>&1; then
  PING6_CMD=( ping6 )
elif ping -6 -c 1 ::1 >/dev/null 2>&1; then
  PING6_CMD=( ping -6 )
fi

# Use -W only when ping is iputils (Linux). On macOS/BSD -W semantics differ.
PING4_W=()
if ping -V 2>/dev/null | grep -qi iputils; then
  PING4_W=( -W 2 )
fi

# Defaults (override via env)
INTERVAL_DEFAULT="0.2"
if is_root; then INTERVAL_DEFAULT="0.11"; fi
INTERVAL="${SLA_INTERVAL:-$INTERVAL_DEFAULT}"
PKT_SIZE="${SLA_SIZE:-56}"

# Args
if [ $# -lt 3 ]; then
  echo "Usage: ./SLA.sh <icmp_packets> <rtt_threshold_ms> <loss_threshold_pct>" >&2
  echo "Example: ./SLA.sh 1000 50 0.02" >&2
  exit 1
fi

PP="$1"
RTD="$2"
PL="$3"

if ! [[ "$PP" =~ ^[0-9]+$ ]] || [ "$PP" -lt 1 ] || [ "$PP" -gt 100000 ]; then
  echo "icmp_packets must be an integer between 1 and 100000." >&2
  exit 1
fi
if ! is_number "$RTD"; then
  echo "rtt_threshold_ms must be a number (e.g., 50 or 50.5)." >&2
  exit 1
fi
if ! is_number "$PL" || ! fle "$PL" 100; then
  echo "loss_threshold_pct must be a number between 0 and 100 (e.g., 0.02)." >&2
  exit 1
fi

# Bundle output
RUN_ID="$(date +%Y-%m-%dT%H-%M-%S%z)"
OUTDIR="${SLA_OUTDIR:-sla_results_${RUN_ID}}"
mkdir -p "$OUTDIR"

# Metadata (ticket-friendly)
{
  echo "tool=SLA.sh"
  echo "tool_version=isp-bash-v1"
  echo "run_id=$RUN_ID"
  echo "host=$(hostname 2>/dev/null || echo unknown)"
  echo "os=$(uname -a)"
  echo "ping_version=$(ping -V 2>&1 | head -n1 || true)"
  echo "icmp_packets=$PP"
  echo "interval_s=$INTERVAL"
  echo "packet_size_bytes=$PKT_SIZE"
  echo "threshold_rtt_ms=$RTD"
  echo "threshold_loss_pct=$PL"
  echo "targets_v4=${AHv4[*]}"
  echo "targets_v6=${AHv6[*]}"
} >"$OUTDIR/meta.txt"

run_probes() {
  local family="$1"; shift

  # Build ping command array until "--"
  local cmd=()
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do
    cmd+=( "$1" )
    shift
  done
  shift # consume "--"

  local targets=( "$@" )
  local n_targets="${#targets[@]}"


  local show_progress="${SLA_PROGRESS:-1}"   # 1=on (default), 0=off
  local wopts=()
  if [ "$family" = "v4" ]; then
    wopts=( "${PING4_W[@]}" )
  fi
  if [ "$n_targets" -eq 0 ]; then
    echo "No targets configured for $family." >&2
    echo "" # status line
    return 0
  fi

  # Connectivity pre-check (best-effort)
  echo '##################################' >&2
  echo "Is there any ${family} connectivity here?" >&2
  echo "Trying to reach ${targets[0]}" >&2
  echo '##################################' >&2

  local ok=1
  local tries=3
  while [ $tries -gt 0 ]; do
    if LC_ALL=C "${cmd[@]}" -n -q -c 1 "${targets[0]}" >/dev/null 2>&1; then
      ok=0
      break
    fi
    tries=$((tries-1))
  done

  if [ $ok -ne 0 ]; then
    echo '##################################' >&2
    echo "NO ${family} connectivity available (or ICMP filtered)." >&2
    echo '##################################' >&2
    echo "NO_CONNECTIVITY||"   # status||avg_rtt||avg_loss
    return 0
  fi

  echo '##################################' >&2
  echo "Good, ${family} connectivity is available" >&2
  echo "Let's go ahead with ${family} SLA check" >&2
  echo '##################################' >&2

  local fail=0
  local sum_rtt="0.000"
  local sum_loss="0.00000"
  local resp_rtt=0

  for t in "${targets[@]}"; do
    local safe_t
    safe_t="$(sanitize_filename "$t")"
    local log="$OUTDIR/ping_${family}_${safe_t}.log"

    # Run ping: keep raw output (do not abort on non-zero exit)
    # Estimate duration ~ PP * INTERVAL seconds (ceil), min 1s
    local est pid
    est="$(awk -v pp="$PP" -v i="$INTERVAL" 'BEGIN{e=pp*i; if(e<1)e=1; printf "%d", int(e+0.999)}')"

    LC_ALL=C "${cmd[@]}" -n -q "${wopts[@]}" -i "$INTERVAL" -s "$PKT_SIZE" -c "$PP" "$t" >"$log" 2>&1 &
    pid=$!

    if [ "$show_progress" != "0" ]; then
      progress_bar "$pid" "$est" "$family $t"
    fi

    wait "$pid" || true
    local TX RX LOSS RTT
    IFS=' ' read -r TX RX LOSS RTT <<<"$(parse_ping "$log")"

    if [ -n "${RTT:-}" ]; then
      echo "RTT_avg ${RTT} ms | loss ${LOSS}% on ${t} (tx=${TX} rx=${RX})" >&2
      sum_rtt=$(awk -v s="$sum_rtt" -v x="$RTT" 'BEGIN{printf "%.3f", s+x}')
      resp_rtt=$((resp_rtt+1))
    else
      echo "RTT_avg NA ms | loss ${LOSS}% on ${t} (tx=${TX} rx=${RX})" >&2
    fi
    sum_loss=$(awk -v s="$sum_loss" -v x="$LOSS" 'BEGIN{printf "%.5f", s+x}')

    # Per-target SLA: missing RTT (often 100% loss) is KO
    if [ -z "${RTT:-}" ] || fgt "$RTT" "$RTD" || fgt "$LOSS" "$PL"; then
      fail=1
    fi

    echo '##################################' >&2
  done

  local avg_rtt=""
  if [ "$resp_rtt" -gt 0 ]; then
    avg_rtt=$(awk -v s="$sum_rtt" -v n="$resp_rtt" 'BEGIN{printf "%.3f", s/n}')
  fi
  local avg_loss
  avg_loss=$(awk -v s="$sum_loss" -v n="$n_targets" 'BEGIN{printf "%.5f", s/n}')

  local status="OK"
  if [ "$fail" -eq 1 ]; then status="KO"; fi

  echo "${status}||${avg_rtt}||${avg_loss}"
}

# IPv4
echo "Results directory: $OUTDIR" >&2
echo "Let's start with IPv4 SLA check" >&2
V4_LINE="$(run_probes "v4" ping -- "${AHv4[@]}")"
V4_STATUS="${V4_LINE%%||*}"
V4_REST="${V4_LINE#*||}"
V4_AVG_RTT="${V4_REST%%||*}"
V4_AVG_LOSS="${V4_REST#*||}"

if [ "$V4_STATUS" = "KO" ]; then
  echo -e "${RED}==========> v4 SLA KO <==========${NC}" >&2
elif [ "$V4_STATUS" = "OK" ]; then
  echo -e "${GREEN}==========> v4 SLA OK <==========${NC}" >&2
else
  echo "==========> v4 SLA INCONCLUSIVE (${V4_STATUS}) <==========" >&2
fi

# IPv6
if [ "${#PING6_CMD[@]}" -eq 0 ]; then
  echo '##################################' >&2
  echo 'ping6 not available: skipping IPv6 check' >&2
  echo '##################################' >&2
  V6_STATUS="NO_PING6"
  V6_AVG_RTT=""
  V6_AVG_LOSS=""
else
  echo "Let's start with IPv6 SLA check" >&2
  V6_LINE="$(run_probes "v6" "${PING6_CMD[@]}" -- "${AHv6[@]}")"
  V6_STATUS="${V6_LINE%%||*}"
  V6_REST="${V6_LINE#*||}"
  V6_AVG_RTT="${V6_REST%%||*}"
  V6_AVG_LOSS="${V6_REST#*||}"

  if [ "$V6_STATUS" = "KO" ]; then
    echo -e "${RED}==========> v6 SLA KO <==========${NC}" >&2
  elif [ "$V6_STATUS" = "OK" ]; then
    echo -e "${GREEN}==========> v6 SLA OK <==========${NC}" >&2
  else
    echo "==========> v6 SLA INCONCLUSIVE (${V6_STATUS}) <==========" >&2
  fi
fi

# Write a minimal JSON summary (ticket ingestion)
# Use null for missing RTT averages.
v4_rtt_json="null"; v6_rtt_json="null"
[ -n "${V4_AVG_RTT:-}" ] && v4_rtt_json="$V4_AVG_RTT"
[ -n "${V6_AVG_RTT:-}" ] && v6_rtt_json="$V6_AVG_RTT"

cat >"$OUTDIR/summary.json" <<JSON
{
  "run_id": "$(echo "$RUN_ID" | sed 's/"/\\"/g')",
  "outdir": "$(echo "$OUTDIR" | sed 's/"/\\"/g')",
  "threshold_rtt_ms": $RTD,
  "threshold_loss_pct": $PL,
  "ipv4": { "status": "$V4_STATUS", "avg_rtt_ms": $v4_rtt_json, "avg_loss_pct": ${V4_AVG_LOSS:-0} },
  "ipv6": { "status": "$V6_STATUS", "avg_rtt_ms": $v6_rtt_json, "avg_loss_pct": ${V6_AVG_LOSS:-0} }
}
JSON

exit 0
