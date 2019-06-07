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

check(){    
  local domain=$(echo $(echo ${1//\(\^\|\\\.\)/}|sed -e 's/\\././g')|sed -e 's/\$//g')
  if [ "${domain}" ]; then
    ((x--))
    (
    code=$(curl -L --retry 3 -A "MAUI WAP Browser" -x socks5://127.0.0.1:1080 --connect-timeout 20 -m 60 -s -o /dev/null -w "%{http_code}" "${domain}")
    if [[ "${code}" -ge 200 ]]; then
      echo -e "${white}${domain}${plain} ${green}响应成功! $code ${plain} ${lightred}${x}${plain} "
    else
      if [ -z "$(echo ${domain}|grep -E '^(\s|\[|\#|([0-9]{1,3}\.){3}[0-9]{1,3})')" ]; then
       echo -e "${yellow}${domain}${plain} ${red}连接失败! $code ${plain} ${lightred}${x}${plain} "
       if $2 ; then
         echo ${1} >> $(pwd)/fail.acl
       else
         echo ${1} >> $(pwd)/fail2.acl
       fi
      fi      
    fi
    )&
  fi
}

_quantity()(
n=0
while IFS= read -r line; do
  ((n++))
done < ${1}
echo ${n}
)

_time()(
  end_time=$(date +%s)
  time_distance=$(($end_time - $begin_time));
  hour_distance=$(expr ${time_distance} / 3600)  
  hour_remainder=$(expr ${time_distance} % 3600)  
  min_distance=$(expr ${hour_remainder} / 60)  
  min_remainder=$(expr ${hour_remainder} % 60)
  echo -e "[${yellow}提示${plain}] 执行耗时: ${white}${hour_distance}:${min_distance}:${min_remainder}${plain}";
)

_test(){
rm -f $(pwd)/fail.acl
touch $(pwd)/fail.acl
x=$(_quantity "$(pwd)/gfwlist.acl")
while IFS= read -r line; do
  check "${line}" true
  sleep 0.1
done < $(pwd)/gfwlist.acl
wait
_time
}

_check(){
rm -f $(pwd)/fail2.acl
touch $(pwd)/fail2.acl
x=$(_quantity "$(pwd)/fail.acl")
while IFS= read -r line; do
  check "${line}" false
done < $(pwd)/fail.acl
wait
mv -f $(pwd)/fail2.acl $(pwd)/fail.acl
#sort -u $(pwd)/fail.acl -o $(pwd)/fail.acl #重新整理
_time
}

_write(){
x=0
while IFS= read -r line; do
  ((x++))
  while IFS= read -r lines; do
    if [[ "${line}" == "${lines}" ]]; then
      echo -e "[${yellow}提示${plain}] 正在删除第 ${x} 行 ${lines}"
      sed -i "${x}d" $(pwd)/gfwlist.acl
    fi
  done < $(pwd)/fail.acl
done < $(pwd)/gfwlist.acl
sed -i '/^$/d' $(pwd)/gfwlist.acl #删除空行
_time
}

history -cw
clear

action=$1
case "${action}" in
    test)
        _${action}
        ;;
    check)
        _${action}
        ;;
    write)
        _${action}
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: $(basename $0) [test|check|write]"
        ;;
esac