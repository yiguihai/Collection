iptables --flush
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53
iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination 8.8.4.4:53
iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -j MASQUERADE
ip rule add from 192.168.43.0/24 lookup 61
ip route add default dev tun0 scope link table 61
ip route add 192.168.43.0/24 dev wlan0 scope link table 61
ip route add broadcast 255.255.255.255 dev wlan0 scope link table 61
