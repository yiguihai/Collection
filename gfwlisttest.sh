#!/usr/bin/env bash

export HISTCONTROL=ignorespace
export HISTSIZE=0
history -cw
clear

begin_time=$(date +%s)
white='\033[1;37m'
red='\033[0;31m'
lightred='\033[1;31m'
green='\033[0;32m'
yellow='\033[0;33m'
magenta='\033[0;95m'
cyan='\033[0;96m'
plain='\033[0m'

rm -f $(pwd)/test.acl
touch $(pwd)/test.acl
rm -f $(pwd)/fail.acl
touch $(pwd)/fail.acl
x=0
w=0
e=0
while IFS= read -r line; do
  domain=$(echo $(echo ${line//\(\^\|\\\.\)/}|sed -e 's/\\././g')|sed -e 's/\$//g')
  if [ "$(echo ${line}|grep -E '^(\[|\#|([0-9]{1,3}\.){3}[0-9]{1,3})')" ]; then
    echo ${line} >> $(pwd)/test.acl
  else
    if [ "${domain}" ]; then
      ((x++))
      code=$(curl -L -A "MAUI WAP Browser" -x socks5://127.0.0.1:1080 -m 6 -s -o /dev/null -w "%{http_code}" "${domain}")
      if [[ "${code}" -ge 100 && "${code}" -lt 400 ]]; then
        ((w++))
        echo -e "${white}${domain}${plain} ${green}响应成功! $code ${plain} ${lightred}${x}${plain} "
        echo ${line} >> $(pwd)/test.acl
      else
        ((e++))
        echo -e "${yellow}${domain}${plain} ${red}连接失败! $code ${plain} ${lightred}${x}${plain} "
        echo ${line} >> $(pwd)/fail.acl
      fi
    fi
  fi
  unset -v domain code
done < $(pwd)/gfwlist.acl
end_time=$(date +%s)
time_distance=$(($end_time - $begin_time));
hour_distance=$(expr ${time_distance} / 3600)  
hour_remainder=$(expr ${time_distance} % 3600)  
min_distance=$(expr ${hour_remainder} / 60)  
min_remainder=$(expr ${hour_remainder} % 60)
history -cw
clear
echo -e "测试结果文件: ${lightred}$(pwd)/test.acl${plain}";
echo -e "测试完成！[总数: ${lightred}${x}${plain}] 共 ${green}${w}${plain} 个响应成功。共 ${red}${e}${plain} 个响应失败。耗时 ${white}${hour_distance}:${min_distance}:${min_remainder}${plain}";


