#!/bin/bash

#tcp_list=($(grep " accepted" /var/log/redsocks.log|egrep -o "[0-9]{1,3}(\.[0-9]{1,3}){3}"))
#udp_list=($(grep "Starting UDP relay" /var/log/redsocks.log|egrep -o "[0-9]{1,3}(\.[0-9]{1,3}){3}"))
ip_array=($(grep -E " accepted|Starting UDP relay" /var/log/redsocks.log|egrep -o "[0-9]{1,3}(\.[0-9]{1,3}){3}"|egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\."))
if [ ! -f /root/ip.log ]; then
    touch /root/ip.log
fi
if [ ! -f /root/CN.txt ]; then
    touch /root/CN.txt
fi

#数据保存好
for ((i=0;i<${#ip_array[@]};i++)); do
	repeat=$(grep -o "${ip_array[i]}" /root/ip.log)
	address=${ip_array[i]}
	if [ "${repeat%%.*}" != "${address%%.*}" ]; then
		echo -e "$address\c"
		x=0
		until [ -n "$data_json" -o $x -ge 5 ]; do
		    ((x++))
		    data_json=$(wget -qO- --no-check-certificate -U 'curl/7.65.0' http://ip-api.com/json/$address 2>/dev/null)
		    country=$(jsonfilter -s "$data_json" -e '@.countryCode' 2> /dev/null)
		    if [ "${country:-null}" = "CN" ]; then
            echo "$address" >> /root/CN.txt
		    fi
		done
		echo "$address" >> /root/ip.log
		[ "$country" ]&&echo " -> $(jsonfilter -s "$data_json" -e '@.country') $i/${#ip_array[@]}"||echo " -> fail!"
	fi
	unset repeat address x data_json country
done
echo > /var/log/redsocks.log
echo "done"
