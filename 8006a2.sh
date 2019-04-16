#!/bin/bash
echo "ip tables"

##USER CONFIG
TCPPORT="80,443,53,22,21,23"
UDPPORT="53,67,68,7000"
ICMPPORT=" 0 3 8 "
FIREWALLIP="192.168.10.1"
hostif="192.168.10.2"
fwif="eno1"



iptables -F
iptables -X

#Set default policy to drop all
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP


#DROP TELNET
iptables -A FORWARD -p TCP --sport 23 -j DROP
iptables -A FORWARD -p TCP --dport 23 -j DROP


#DROP SYN AND FYN
iptables -A FORWARD -p TCP --tcp-flags SYN,FIN SYN,FIN -j DROP

#DROP PACKETS WITH ADRESS FROM OUTSIDE THAT HAS SOURCE ADDRESS OF INTERNAL NETWORK
iptables -A FORWARD -s 192.168.10.0/24 -j DROP

#DROP PACKETS FROM OUTSIDE FOR FIREWALL
iptables -A FORWARD -i $fwif -d $FIREWALLIP -j DROP


#DROP FROM PORTS
iptables -A FORWARD -p TCP --dport 32768:32775 -j DROP
iptables -A FORWARD -p TCP --dport 137:139 -j DROP
iptables -A FORWARD -p TCP -m multiport --dport 111,515 -j DROP
iptables -A FORWARD -p UDP --dport 32768:32775 -j DROP
iptables -A FORWARD -p UDP --dport 137:139


#INBOUND/OUTBOUND TCP CUSTOM PORTS
iptables -A FORWARD -p TCP -m multiport --dport $TCPPORT -j ACCEPT -m state --state NEW,ESTABLISHED
iptables -A FORWARD -p TCP -m multiport --sport $TCPPORT -j ACCEPT -m state --state NEW,ESTABLISHED

#INBOUND/OUTBOUND UDP PORTS
iptables -A FORWARD -p UDP -m multiport --dport $UDPPORT -j ACCEPT -m state --state NEW,ESTABLISHED
iptables -A FORWARD -p UDP -m multiport --sport $UDPPORT -j ACCEPT -m state --state NEW,ESTABLISHED

#SSHTO
iptables -A PREROUTING -t mangle -p tcp -m multiport --sport 21,22 -j TOS --set-tos Minimize-Delay
iptables -A PREROUTING -t mangle -p tcp -m multiport --sport 21,22 -j TOS --set-tos Maximize-Throughput

#ICMP
for p in $ICMPPORT;
do
    iptables -A FORWARD -p icmp --icmp-type $p -j ACCEPT
done

iptables -A POSTROUTING -t nat -j SNAT -s 192.168.10.0/24 -o eno1 --to-source $FIREWALLIP
iptables -A PREROUTING -t nat -j DNAT -i eno1 --to-destination 192.168.10.2






echo "IPtables now set";
