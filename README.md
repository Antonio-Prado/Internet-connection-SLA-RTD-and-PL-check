# Internet-connection-SLA-RTD-and-PL-check
Script to check if your Internet connection meets a SLA by checking Round Trip Delay and Packet Loss

Run as root in order to use some ping advanced options.

This code sends ICMP and ICMPv6 packets to RIPE anchors placed in Italy at MIX (Milan Internet Exchange point) and at Namex (Rome Internet Exchange point).

It measures Round trip delay and Packet Loss values in order to meet some SLA policies, for example, as coded in this script:

RTD < 100ms

PL < 0.02%

Usage: ./SLA.sh [amount of ICMP packets to send recommended 10000]

Example: sudo ./SLA.sh 10000
