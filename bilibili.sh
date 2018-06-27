x=0
dns="8.8.8.8"

domain_name="bangumi.bilibili.com"

for i in $domain_name

do

ip_list=`nslookup $i $dns | egrep -o '[0-9]{1,3}(\.[0-9]{1,3}){3}'|egrep -v $dns`

for j in $ip_list

do

iptables -t nat -A out_forward -p tcp -d $j -j DNAT --to-destination 127.0.0.1:3128
((x++))
done

done

echo "$x 個"
