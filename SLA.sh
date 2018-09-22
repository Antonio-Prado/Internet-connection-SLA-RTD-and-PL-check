#!/bin/bash
##########################################################################################################
# Simple bash script @SBTAP-AS59715                                                                      #
# S L A   C H E C K                                                                                      #
# ./SLA.sh [amount of ICMP packets to send] [round trip delay threshold value] [packet loss value]       #
# Example: sudo ./SLA.sh 1000 90 0.03                                                                    #
# It means: send 1k ICMP and ICMPv6 packets to the two defined anchor hosts, do the math and check the   #
# SLA assuming that the average RTD must be less than 100ms and that maximum PL must be 0.03%.       #
##########################################################################################################
#let's check if needed commands are available

if ! [ -x "$(command -v bc)" ]; then
  echo 'bc is needed to do the math' >&2
  exit 1
fi

if ! [ -x "$(command -v ping)" ]; then
  echo 'ping is needed to send ICMP' >&2
  exit 1
fi

if ! [ -x "$(command -v ping6)" ]; then
  echo 'ping6 is needed to send ICMPv6' >&2
  exit 1
fi

#be sure that commands are executed as root
if [ "$(whoami &2>/dev/null)" != "root" ] && [ "$(id -un &2>/dev/null)" != "root" ]
      then
      echo "You must be root, use sudo."
      exit 1
fi

#list IPs of the anchor hosts: RIPE ANCHOR at MIX (217.29.76.27) and RIPE ANCHOR at NAMEX (193.201.40.210)
ANCHOR_HOSTS_v4=( "193.201.40.210" "217.29.76.27" )
ANCHOR_HOSTS_v6=( "2001:7f8:10:f00c::210" "2001:1ac0:0:200:0:a5d1:6004:27" )

if ! [ $# -ge 3 ]
then
  echo "Usage: ./SLA.sh [amount of ICMP packets to send] [round trip delay threshold value] [packet loss value]"
  echo "Example: sudo ./SLA.sh 1000 90 0.03"
  echo "It means: send 1k ICMP and ICMPv6 packets to the two defined anchor hosts, do the math and check the"
  echo "SLA assuming that the average RTD must be less than 100ms and that maximum PL must be 0.03%."
  echo "Recommended values are 10000 100 0.02"
  exit 1
else
PING_PACKETS=$1
RTD=$2
PL=$3
fi
#here we go

RTD_v4_SUM=0
PL_v4_SUM=0.00
RTD_v6_SUM=0
PL_v6_SUM=0.00
echo "Let's start with IPv4 SLA check"
#v4 probes
for i in ${ANCHOR_HOSTS_v4[@]}
do
  ping -W 200 -i 0.11 -s 56 -c $PING_PACKETS ${i}>>PING_RESULTS_v4.txt;
  RTD_v4_VALUE=`cat PING_RESULTS_v4.txt|tail -n1|cut -d'/' -f5|cut -d. -f1`;
  PL_v4_VALUE=`cat PING_RESULTS_v4.txt|grep loss|cut -d, -f3|cut -d% -f1`;
        echo "RTD ${RTD_v4_VALUE} on ${i}";
        echo "PL ${PL_v4_VALUE} on ${i}";
        rm -f PING_RESULTS_v4.txt;
	echo ##################################
        RTD_v4_SUM=$(( ${RTD_v4_SUM} + ${RTD_v4_VALUE} ))
        PL_v4_SUM=$( echo $PL_v4_SUM + $PL_v4_VALUE | bc )
done

#do the math
let RTD_v4_AVG="${RTD_v4_SUM} / ${#ANCHOR_HOSTS_v4[@]}"

#verify if we meet our v4 SLA
if [[ ( "$RTD_v4_AVG" -gt "$RTD" ) || ( "$PL_v4_SUM" > "$PL" ) ]]
then
        echo "==========> v4 SLA KO <=========="
else
        echo "==========> v4 SLA OK <=========="
fi

#is there any IPv6 connectivity?

echo ##################################
echo Is there any IPv6 connectivity here?
echo Trying to reach google.com
echo ##################################
((count = 3))
while [[ $count -ne 0 ]] ; do
    ping6 -qc 1 2001:1ac0:0:200:0:a5d1:6004:27
    rc=$?
    if [[ $rc -eq 0 ]] ; then
        ((count = 1))
    fi
    ((count = count - 1))
done

if [[ $rc -eq 0 ]] ; then
echo ##################################
echo "Good, there's IPv6 connectivity available"
echo "Let's go ahead with IPv6 SLA check"
echo ##################################
#v6 probes
for i in ${ANCHOR_HOSTS_v6[@]}
do
  ping6 -i 0.11 -s 56 -c $PING_PACKETS ${i}>>PING_RESULTS_v6.txt;
  RTD_v6_VALUE=`cat PING_RESULTS_v6.txt|tail -n1|cut -d'/' -f5|cut -d. -f1`;
  PL_v6_VALUE=`cat PING_RESULTS_v6.txt|grep loss|cut -d, -f3|cut -d% -f1`;
        echo "RTD ${RTD_v6_VALUE} on ${i}";
        echo "PL ${PL_v6_VALUE} on ${i}";
        rm -f PING_RESULTS_v6.txt;
	echo ##################################
        RTD_v6_SUM=$(( ${RTD_v6_SUM} + ${RTD_v6_VALUE} ))
        PL_v6_SUM=$( echo $PL_v6_SUM + $PL_v6_VALUE | bc )
done

#do the math
let RTD_v6_AVG="${RTD_v6_SUM} / ${#ANCHOR_HOSTS_v6[@]}"


#verify if we meet our v6 SLA
if [[ ( "$RTD_v6_AVG" -gt "$RTD" ) || ( "$PL_v6_SUM" > "$PL" ) ]]
then
        echo "==========> v6 SLA KO <=========="
else
        echo "==========> v6 SLA OK <=========="
fi

else
echo ##################################
echo NO IPv6 connectivity available
echo ##################################
fi
