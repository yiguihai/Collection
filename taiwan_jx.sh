 x=0

	ip_list=$(nslookup bangumi.bilibili.com 8.8.8.8 | egrep -o '[0-9]{1,3}(\.[0-9]{1,3}){3}'|egrep -v 8.8.8.8)
	
	for j in ${ip_list}; do

		((x++))

		iptables -t nat -A out_forward -p tcp -d $j -j DNAT --to-destination 127.0.0.1:3128

	done

echo "已添加 $x 条规则"
#apt-get install dnsutils
#iptables -t nat -N out_forward

#iptables -t nat -A OUTPUT -p tcp ! -d 127.0.0.1 -j out_forward

#bash <(curl -sL https://raw.githubusercontent.com/yiguihai/Collection/master/taiwan_jx.sh)
