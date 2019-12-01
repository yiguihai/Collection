iptables --flush
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53
iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination 8.8.4.4:53
iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -j MASQUERADE
ip rule add from 192.168.0.0/16 lookup 61
ip route add default dev tun0 scope link table 61
ip route add 192.168.0.0/16 dev wlan0 scope link table 61
ip route add broadcast 255.255.255.255 dev wlan0 scope link table 61

ip rule add pref 12000 from all fwmark 0x0/0x20000 iif lo uidrange 10258-10258 lookup tun0
ip rule add pref 13000 from all fwmark 0x10075/0x1ffff iif lo uidrange 10258-10258 lookup tun0
ip rule add pref 14000 from all iif lo oif tun0 uidrange 10258-10258 lookup tun0
