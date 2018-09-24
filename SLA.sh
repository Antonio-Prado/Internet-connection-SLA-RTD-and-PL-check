#!/bin/bash
################################################################################
# Simple bash script @SBTAP-AS59715                                            #
# S L A   C H E C K                                                            #
# ./SLA.sh [amount of ICMP packets to send] [round trip delay threshold value] #
# [packet loss value]                                                          #
# Example: sudo ./SLA.sh 1000 90 0.03                                          #
# It means: send 1k ICMP and ICMPv6 packets to the two defined anchor hosts,   #
# do the math and check the                                                    #
# SLA assuming that the average RTD must be less than 100ms and that maximum   #
# PL must be 0.03%.                                                            #
# ICMP packets value must be between 1 and 100k.                               #
################################################################################

# let's check if needed commands are available

if ! [ -x "$(command -v bc)" ]; then
  echo 'bc is needed to do the math' >&2;
  exit 1;
fi

if ! [ -x "$(command -v ping)" ]; then
  echo 'ping is needed to send ICMP' >&2;
  exit 1;
fi

if ! [ -x "$(command -v ping6)" ]; then
  echo 'ping6 is needed to send ICMPv6' >&2;
  exit 1;
fi

# be sure that commands are executed as root
if [ "$(whoami)" != "root" ] && [ "$(id -un)" != "root" ]; then
  echo 'You must be root, use sudo.' >&2;
  exit 1;
fi

# list IPs of the anchor hosts: RIPE ANCHOR at MIX (217.29.76.27) and RIPE
# ANCHOR at NAMEX (193.201.40.210)
AHv4=( "193.201.40.210" "217.29.76.27" );
AHv6=( "2001:7f8:10:f00c::210" "2001:1ac0:0:200:0:a5d1:6004:27" );

# check arguments
if !	[ $# -ge 3 ]; then
  echo "Usage: ./SLA.sh [amount of ICMP packets to send] [round trip delay"
  echo "threshold value] [packet loss value]" >&2;
  echo "Example: sudo ./SLA.sh 1000 90 0.03" >&2;
  echo "It means: send 1k ICMP and ICMPv6 packets to the two defined anchor"
  echo "hosts, do the math and check the" >&2;
  echo "SLA assuming that the average RTD must be less than 100ms and that"
  echo "maximum PL must be 0.03%." >&2;
  echo "Recommended values are 10000 100 0.02. But be patient: probe can"
  echo "take more than one hour." >&2;
  exit 1;
else
  PP=$1;
  RTD=$2;
  PL=$3;
fi

# Let's check if PL value is a correct percentage
if
  [[ "$PL" =~ ^[0-9]+$ && "$PP" -ge 1 && "$PP" -le 100 && "$PL" -ge 0 && "$PL" \
  -le 100 ]] || (( "$PP" >= 101 && "$PP" <= 1000 && (( $(echo "$PL >= 0.1" \
  | bc -l) )) && (( $(echo "$PL <= 100" | bc -l) )) )) || (( "$PP" >= 1001 \
  && "$PP" <= 10000 && (( $(echo "$PL >= 0.01" | bc -l) )) && (( $(echo "$PL \
  <= 100" | bc -l) )) )) || (( "$PP" >= 10001 && "$PP" <= 100000 && (( $(echo \
  "$PL >= 0.001" | bc -l) )) && (( $(echo "$PL <= 100" | bc -l) )) )); then

# here we go
  RTD_v4_SUM=0;
  PL_v4_SUM=0.00;
  RTD_v6_SUM=0;
  PL_v6_SUM=0.00;
  echo "Let's start with IPv4 SLA check" >&2;

# v4 probes
    for i in "${AHv4[@]}"; do
      ping -W 200 -i 0.11 -s 56 -c "$PP" "${i}">>PING_RESULTS_v4.txt;
      RTD_v4_VALUE=$(tail -n1 PING_RESULTS_v4.txt|cut -d'/' -f5|cut -d. -f1);
      PL_v4_VALUE=$(grep loss PING_RESULTS_v4.txt|cut -d, -f3|cut -d% -f1);
      echo "RTD ${RTD_v4_VALUE} on ${i}" >&2;
      echo "PL ${PL_v4_VALUE} on ${i}" >&2;
      rm -f PING_RESULTS_v4.txt;
      echo '##################################' >&2;
      RTD_v4_SUM=$(( RTD_v4_SUM + RTD_v4_VALUE ));
      PL_v4_SUM=$( echo $PL_v4_SUM + "$PL_v4_VALUE" | bc );
    done

# do the math
  (( RTD_v4_AVG="${RTD_v4_SUM} / ${#AHv4[@]}" ))

# verify if we meet our v4 SLA
    if [[ ( "$RTD_v4_AVG" -gt "$RTD" ) || ( "$PL_v4_SUM" > "$PL" ) ]]; then
      echo '==========> v4 SLA KO <==========' >&2;
    else
      echo '==========> v4 SLA OK <==========' >&2;
    fi
	
  else
    echo "During ping, packets can get lost. Here we count the percentage of"
    echo "the loss." >&2;
    echo "So, for ICMP between 1 and 100, PL value must be between 0 and 100"
    echo "For ICMP between 101 and 1000, PL value must be between 0.1 and 100"
    echo "For ICMP between 1001 and 10000, PL value must be between 0.01 and"
    echo "100" >&2;
    echo "For ICMP between 10001 and 100000, PL value must be between 0.001"
    echo "and 100" >&2;
    exit 1;
fi

# is there any IPv6 connectivity?;
echo '##################################' >&2;
echo 'Is there any IPv6 connectivity here?' >&2;
echo 'Trying to reach RIPE anchor at MIX' >&2;
echo '##################################' >&2;
((count = 3))
while [[ $count -ne 0 ]]; do
  ping6 -oqc 1 2001:1ac0:0:200:0:a5d1:6004:27
  rc=$?
    if [[ $rc -eq 0 ]]; then
      ((count = 1))
    fi
	((count = count - 1))
done

if [[ $rc -eq 0 ]]; then
  echo '##################################' >&2;
  echo "Good, there's IPv6 connectivity available" >&2;
  echo "Let's go ahead with IPv6 SLA check" >&2;
  echo '##################################' >&2;

# v6 probes
  for i in "${AHv6[@]}"; do
    ping6 -i 0.11 -s 56 -c "$PP" "${i}">>PING_RESULTS_v6.txt;
    RTD_v6_VALUE=$(tail -n1 PING_RESULTS_v6.txt|cut -d'/' -f5|cut -d. -f1);
    PL_v6_VALUE=$(grep loss PING_RESULTS_v6.txt|cut -d, -f3|cut -d% -f1);
    echo "RTD ${RTD_v6_VALUE} on ${i}" >&2;
    echo "PL ${PL_v6_VALUE} on ${i}" >&2;
    rm -f PING_RESULTS_v6.txt;
    echo '##################################' >&2;
    RTD_v6_SUM=$(( RTD_v6_SUM + RTD_v6_VALUE ));
    PL_v6_SUM=$( echo $PL_v6_SUM + "$PL_v6_VALUE" | bc );
   done

# do the math
  (( RTD_v6_AVG="${RTD_v6_SUM} / ${#AHv6[@]}" ));

# verify if we meet our v6 SLA
  if [[ ( "$RTD_v6_AVG" -gt "$RTD" ) || ( "$PL_v6_SUM" > "$PL" ) ]]; then
    echo '==========> v6 SLA KO <==========' >&2;
    else
    echo '==========> v6 SLA OK <==========' >&2;
  fi
  
  else
    echo '##################################' >&2;
    echo 'NO IPv6 connectivity available' >&2;
    echo '##################################' >&2;
fi
