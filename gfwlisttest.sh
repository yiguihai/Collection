#!/usr/bin/env bash

export HISTCONTROL=ignorespace
export HISTSIZE=0

begin_time=$(date +%s)
white='\033[1;37m'
red='\033[0;31m'
lightred='\033[1;31m'
green='\033[0;32m'
yellow='\033[0;33m'
magenta='\033[0;95m'
cyan='\033[0;96m'
plain='\033[0m'

rm -f $(pwd)/fail.acl
touch $(pwd)/fail.acl
x=0
url_test()(
    if $3 ; then
      m=10
    else
      m=5
    fi
    code=$(curl -L -A "MAUI WAP Browser" -x socks5://127.0.0.1:1080 -m ${m} -s -o /dev/null -w "%{http_code}" "${1}")
    if [[ "${code}" -ge 200 && "${code}" -le 308 ]]; then
      echo -e "${white}${1}${plain} ${green}响应成功! $code ${plain} ${lightred}${x}${plain} "
    else
      if [ -z "$(echo ${1}|grep -E '^(\s|\[|\#|([0-9]{1,3}\.){3}[0-9]{1,3})')" ]; then
       echo -e "${yellow}${1}${plain} ${red}连接失败! $code ${plain} ${lightred}${x}${plain} "
       echo ${2} >> $(pwd)/fail.acl
      fi      
    fi
)
check(){ 
  local domain=$(echo $(echo ${1//\(\^\|\\\.\)/}|sed -e 's/\\././g')|sed -e 's/\$//g')
  #if [ "$(echo ${1}|grep -E '^(\s|\[|\#|([0-9]{1,3}\.){3}[0-9]{1,3})')" ]; then
    #echo ${1} >> $(pwd)/test.acl
  #else
    if [ "${domain}" ]; then
      ((x++))
      if $2 ; then
        (url_test "${domain}" "${1}" ${2})&
      else
        url_test "${domain}" "${1}" ${2}
      fi
    fi
  #fi
}
while IFS= read -r line; do
  check "${line}" true
  sleep 1
done < $(pwd)/gfwlist.acl
wait
#第二次测试
while IFS= read -r line; do
  check "${line}" false
done < $(pwd)/fail.acl

sort -u $(pwd)/fail.acl -o $(pwd)/fail.acl #重新整理

while IFS= read -r line; do
  while IFS= read -r lines; do
    if [[ "${line}" == "${lines}" ]]; then
      sed -i "/${lines}/d" $(pwd)/gfwlist.acl
    fi
  done < $(pwd)/fail.acl
done < $(pwd)/gfwlist.acl
sed -i '/^$/d' $(pwd)/gfwlist.acl #删除空行
history -cw
clear
end_time=$(date +%s)
time_distance=$(($end_time - $begin_time));
hour_distance=$(expr ${time_distance} / 3600)  
hour_remainder=$(expr ${time_distance} % 3600)  
min_distance=$(expr ${hour_remainder} / 60)  
min_remainder=$(expr ${hour_remainder} % 60)
echo -e "测试结果文件: ${lightred}$(pwd)/test.acl${plain}";
echo -e "测试完成！[总数: ${lightred}${x}${plain}] 耗时 ${white}${hour_distance}:${min_distance}:${min_remainder}${plain}";