#!/bin/bash

if [ -f /root/ss/conf/dns2.log ]; then
    rm -f /root/ss/conf/dns2.log
fi
while IFS= read -r line; do
    data=${line##* }
    domain=${data:-null}
    if [[ "$domain" == *"."* ]]; then
      echo $domain >> /root/ss/conf/dns2.log
    fi
done < /root/ss/conf/dns.log

sort /root/ss/conf/dns2.log|uniq > /root/ss/conf/dns.txt
all_line=$(wc -l /root/ss/conf/dns.txt|cut -d' ' -f1)

if [ -f /root/ss/conf/dns2.log ]; then
    rm -f /root/ss/conf/dns2.log
fi
if [ -f /root/ss/conf/CN.txt ]; then
    rm -f /root/ss/conf/CN.txt
fi
if [ -f /root/ss/conf/Fail.log ]; then
    rm -f /root/ss/conf/Fail.log
fi
thread()(
    r=0
    until [ -n "$data" -o $r -ge 5 ]; do
        ((r++))
        data=$(nslookup $1|grep 'Address ')
        sleep $r
    done
	data=$(nslookup $1|grep 'Address ')
    if [ -n "$data" ]; then
        for i in $data; do
            if [[ "$i" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
                x=0
                until [ -n "$country_id" -o $x -ge 5 ]; do
                    ((x++))
                    echo "$1 $x $m/${all_line:-0}"
                    data_json=$(wget -qO- --no-check-certificate -T3 -U 'curl/7.65.0' http://ip.taobao.com/service/getIpInfo.php?ip=$i 2>/dev/null)
                    country_id=$(jsonfilter -s $data_json -e '@.data.country_id')
					region=$(jsonfilter -s $data_json -e '@.data.region')
                    sleep $x
                done
                if [ "$country_id" = "CN" -a "$region" != "香港" -a "$region" != "澳门" -a "$region" != "台湾" ]; then
                    echo $i >> /root/ss/conf/CN.txt
                fi
                if [ -z "data_json" -o -z  "$country_id" ]; then
                    echo "$1 查询失败"
                    echo "$1 查询失败" >> /root/ss/conf/Fail.log
                fi
            fi
        done
        #unset -v data data_json country_id
	else
	    echo "$1 解析失败"
        echo "$1 解析失败" >> /root/ss/conf/Fail.log
	fi
)

m=0
s=0
t=5 #并发数
while IFS= read -r line; do
  ((m++))
  ((s++))
  if [ $s -ge $t ]; then
    s=0
    wait
  fi
  thread $line &
done < /root/ss/conf/dns.txt

sort /root/ss/conf/CN.txt|uniq > /root/ss/conf/CN2.txt
mv -f /root/ss/conf/CN2.txt /root/ss/conf/CN.txt
