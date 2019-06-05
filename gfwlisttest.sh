#!/usr/bin/env bash

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
x=0
e=0
while IFS= read -r line; do
  domain=$(echo $(echo ${line//\(\^\|\\\.\)/}|sed -e 's/\\././g')|sed -e 's/\$//g')
  if [ "$(echo ${line}|grep -E '^(\[|\#|([0-9]{1,3}\.){3}[0-9]{1,3})')" ]; then
    echo ${line} >> $(pwd)/test.acl
  fi
  url=$(echo ${domain}|grep -E '^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$')
  code=$(curl -x socks5://127.0.0.1:1080 -m 5 -s -o /dev/null -w "%{http_code}" "${url}")
  if [ $? -eq 0 ]; then
    ((x++))
    echo -e "${white}$url${plain} ${green}响应成功! $code ${plain} ${lightred}$x${plain} "
    echo ${line} >> $(pwd)/test.acl
  else
    ((e++))
    echo -e "${yellow}$url${plain} ${red}连接失败! $code ${plain} ${lightred}$x${plain} "
  fi 
  unset -v domain url code
done < $(pwd)/gfwlist.acl
end_time=$(date +%s)
time_distance=$(($end_time - $begin_time));
hour_distance=$(expr ${time_distance} / 3600)  
hour_remainder=$(expr ${time_distance} % 3600)  
min_distance=$(expr ${hour_remainder} / 60)  
min_remainder=$(expr ${hour_remainder} % 60)
echo -e "测试结果文件: ${lightred}$(pwd)/test.acl${plain}";
echo -e "测试完成！共 ${lightred}${x}${plain} 个响应成功。共 ${lightred}${e}${plain} 个响应失败。耗时 ${hour_distance}:${min_distance}:${min_remainder}";


