# Internet-connection-SLA-RTD-and-PL-check
Script to check if your Internet connection meets a SLA by checking Round Trip Delay and Packet Loss

Run as root in order to use some ping advanced options.

This code sends ICMP and ICMPv6 packets to RIPE anchors placed in Italy at MIX (Milan Internet Exchange point) and at Namex (Rome Internet Exchange point).

It measures Round trip delay and Packet Loss values in order to meet some SLA policies, for example, as we recommend:

RTD < 100ms

PL < 0.02%

./SLA.sh [amount of ICMP packets to send] [round trip delay threshold value] [packet loss value]

Example: sudo ./SLA.sh 1000 90 0.03

It implies sending 1000 ICMP and ICMPv6 packets to the two defined anchor hosts, do the math and check the SLA assuming that the average RTD must be less than 100ms and that maximum PL must be 0.03%.      

For an extensive and more accurate test the recommended amount of packets is 10k, but please, be patient: probes can last more than one hour.

Recommended values are 10000 100 0.02

Out of 10k packets it is expected a maximum of 2 lost packets and an average round trip delay value less than 100ms.

Of course you can tune the threshold values by adjusting the script arguments.

To get reliable results, run this script on a box behind the gateway with no other load.
