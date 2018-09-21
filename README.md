# Internet-connection-SLA-RTD-and-PL-check
Script to check if your Internet connection meets a SLA by checking Round Trip Delay and Packet Loss

Run as root in order to use some ping advanced options.

This code sends ICMP and ICMPv6 packets to RIPE anchors placed in Italy at MIX (Milan Internet Exchange point) and at Namex (Rome Internet Exchange point).

It measures Round trip delay and Packet Loss values in order to meet some SLA policies, for example, as coded in this script:

RTD < 100ms

PL < 0.02%

Usage: ./SLA.sh [amount of ICMP packets to send recommended 10000]

Example: sudo ./SLA.sh 10000

For an extensive and more accurate test the recommended amount of packets is 10k, but please, be patient: probes can last more than one hour.
Out of 10k packets it is expected a maximum of 2 lost packets and an average round trip delay value less than 100ms.

Of course you can tune the threshold values by adjusting the script arguments.
