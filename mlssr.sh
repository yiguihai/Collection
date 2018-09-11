#!/system/bin/sh 
#
#免流混淆Host批量自动化测试脚本
#bash <(curl -sL https://raw.githubusercontent.com/yiguihai/Collection/master/mlssr.sh)
#
dir="/data/data/com.termux/files/home/mlssr"
DARKGRAY='\033[1;30m'
RED='\033[0;31m'    
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'    
YELLOW='\033[1;33m'
BLUE='\033[0;34m'    
PURPLE='\033[0;35m'    
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'    
WHITE='\033[1;37m'
SET='\033[0m'

tool_array=(
curl
egrep
bc
date
netstat
grep
termux-sms-list
termux-vibrate
termux-tts-speak
termux-sms-send
termux-dialog
termux-telephony-deviceinfo
termux-wifi-connectioninfo
jq
nc
printf
pkill
settings
am
wc
cut
base64
)

ciphers=(
none
table
rc4
rc4-md5
rc4-md5-6
aes-128-cfb
aes-192-cfb
aes-256-cfb
aes-128-ctr
aes-192-ctr
aes-256-ctr
bf-cfb
camellia-128-cfb
camellia-192-cfb
camellia-256-cfb
salsa20
chacha20
chacha20-ietf
)

protocols=(
origin
verify_simple
verify_sha1
auth_sha1_v2
auth_sha1_v4
auth_aes128_sha1
auth_aes128_md5
auth_chain_a
auth_chain_b
auth_chain_c
auth_chain_d
auth_chain_e
auth_chain_f
)

obfs=(
plain
http_simple
http_post
tls_simple
tls1.2_ticket_auth
)

mode_list=(
关闭数据网络
打开飞行模式
)

countdown()
(
  IFS=:
  set -- $*
  secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
  while [ $secs -gt 0 ]
  do
    sleep 1 &
    printf "\r${YELLOW}%s${SET} ${WHITE}%02d:%02d:%02d${SET}" "脚本进入休眠状态，等待运营商流量数据更新" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
    secs=$(( $secs - 1 ))
    wait
  done
  echo -ne "\r           \r"
)

waiting()
(
for s in 🕛 🕧 🕐 🕜 🕑 🕝 🕒 🕞 🕓 🕟 🕔 🕠 🕕 🕡 🕖 🕢 🕗 🕣 🕘 🕤 🕙 🕥 🕚 🕦; do 
  echo -ne "$1 $s \033[0K\r"
  sleep 0.041;
  :
done
)

waiting_network()
(
while true; do
local data_state=$(termux-telephony-deviceinfo|jq -r '.["data_state"]') 
if [[ $data_state != "connected" ]]; then
  waiting "等待数据网络恢复"
else
  break
fi
done
)

message()
{
local typ=$(termux-sms-list -l 1|jq -r '.[0]["type"]')
local num=$(termux-sms-list -l 1|jq -r '.[0]["number"]')
received=$(termux-sms-list -l 1|jq -r '.[0]["received"]')
local sms=($(termux-sms-list -l 1|jq '.[0]["body"]'|egrep -o '[0-9]{1,5}\.[0-9]{2}'))
if [[ $typ == "inbox" && $num == $cxyys && $sms ]]; then  
  if [[ ! -s $dir/traffic_record ]]; then
    echo -e "找到${CYAN}${#sms[@]}${SET}个匹配的剩余流量信息，请选择:"
    unset -v seleted
    until [ $seleted ]; do
       x=0
       for i in ${sms[@]}; do
         ((x++))
         echo -e "${WHITE}$x${SET}    ${GREEN}$i${SET}"
       done
       read seleted
       if [[ $seleted -gt 0 && $seleted -le ${#sms[@]} ]]; then
         break
       else
         unset -v seleted
       fi
      done
      flow=${sms[$seleted-1]}
      echo -e "你选择了第 $seleted 个 $flow 是否保存记录？[y/n]"
      read save
      if [[ $save == 'Y' || $save == 'y' ]]; then
        echo $seleted > $dir/traffic_record
        if [ $? -eq 0 ]; then
          echo -e "${GREEN}已保存记录文件${SET}"
        fi
      fi
    else
      traffic_record=$(($(cat $dir/traffic_record)))
      flow=${sms[$traffic_record-1]}
    fi
else
  echo -e "${RED}获取流量信息失败!${SET}"
  echo -e "是否发送一条查询短信 ${YELLOW}$cxzl${SET} 到 ${YELLOW}$cxyys${SET}[y/n]"
  read send
  if [[ $y == 'y' || $y == 'Y' ]]; then
    termux-sms-send -n $cxyys "$cxzl"
    echo -e "等待信息返回后再次重试吧！"
  fi
  EXIT
fi
}

local_network()
{
local_ip=$(ip address|egrep -o '10\.([0-9]{1,3}\.){2}[0-9]{1,3}')
local local_ip2=$(echo $local_ip|cut -d '.' -f2)
if [[ $range != "" ]]; then
  local reqsubstr="-"
  for string in "$range"; do
    if [[ -z "${string##*$reqsubstr*}" ]]; then    
      local str1=$(echo $string|cut -d "$reqsubstr" -f1)
      local str2=$(echo $string|cut -d "$reqsubstr" -f2)
      local str3=$(($str2-$str1))
      if [[ $local_ip2 -ge $str1 && $local_ip2 -le $str2 ]]; then
        my_ip=$string
      fi
    else
      if [[ $local_ip2 == $string ]]; then
        my_ip=$string
      fi
    fi
  done
fi
}

write_select()
(
case $1 in
1)
echo -e "###脚本项目配置###"
unset -v pause
until [ $pause ]; do
  echo -e "查询流量时间间隔(如: ${YELLOW}00:15:00${SET} 表示15分钟):" 
  read pause
  pause=$(echo $pause|egrep -o '([0-9]{2}\:){2}[0-9]{2}')
done
echo -e "\n${WHITE}${pause}${SET}\n"
unset -v mode
until [ $mode ]; do
  echo -e "等待期间断网方式:" 
  local x=0
  for i in ${mode_list[@]}; do
    ((x++))
    echo -e "$x $i"
  done
  read mode
  if [[ $mode -gt 0 && $mode -le ${#mode_list[@]} ]]; then
    break
  else
    unset -v mode
  fi
done
echo -e "\n${WHITE}${mode_list[$mode-1]}${SET}\n"
echo -e "短信查询业务指令(如: ${YELLOW}cxll${SET}):"
read cxzl
[ -z $cxzl ]&&cxzl=cxll
echo -e "\n${WHITE}${cxzl}${SET}\n"
unset -v cxyys
until [ $cxyys ]; do
  echo -e "查询服务号码(如: ${YELLOW}10010${SET}):"
  read cxyys
  cxyys=$(echo $cxyys|egrep -o '[0-9]{5,11}')
done
echo -e "\n${WHITE}${cxyys}${SET}\n"
cat > $dir/config.ini <<-EOF
pause="$pause"
mode=$mode
cxzl="$cxzl"
cxyys=$cxyys
EOF
;;
2)
echo -e "###服务器设置###"
unset -v server
until [ $server ]; do
  echo -e "服务器(如: ${YELLOW}1.1.1.1${SET}):"
  read server
  server=$(echo $server|egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}')
done
echo -e "\n${WHITE}${server}${SET}\n"
unset -v server_port
until [ $server_port ]; do
  echo -e "远程端口(如: ${YELLOW}80${SET}):"
  read server_port
  server_port=$(echo $server_port|egrep -o '[0-9]{1,5}')
done
echo -e "\n${WHITE}${server_port}${SET}\n"
echo -e "密码(如: ${YELLOW}admin${SET}):"
read password
[ -z $password ]&&password='admin'
echo -e "\n${WHITE}${password}${SET}\n"
echo -e "加密方法:"
select method in ${ciphers[@]}; do
  if [ $method ]; then
    break
  fi
done
echo -e "\n${WHITE}${method}${SET}\n"
echo -e "协议:"
select protocol in ${protocols[@]}; do
  if [ $protocol ]; then
    break
  fi
done
echo -e "\n${WHITE}${protocol}${SET}\n"
echo -e "混淆方式:"
select obfs in ${obfs[@]}; do
  if [ $obfs ]; then
    break
  fi
done
echo -e "\n${WHITE}${obfs}${SET}\n"
echo -e "协议参数:"
read protocol_param
cat > $dir/server.ini <<-EOF
##服务器设置##
server="$server"          #服务器
server_port=$server_port          #远程端口
password="$password"          #密码
method="$method"          #加密方法
protocol="$protocol"          #协议
obfs="$obfs"          #混淆方式
protocol_param="$protocol_param"          #协议参数
EOF
;;
3)
echo -e "###内网调节配置###"
echo -e "内网限定范围，空格隔开。留空不调节(如: ${YELLOW}1-30 31 35 42${SET})"
read range
if [[ $range != "" ]]; then
  echo -e "\n${WHITE}${range}${SET}\n"
else
  echo -e "\n${WHITE}不调节内网${SET}\n"
fi
echo -e "调节间隔时间/秒(如: ${YELLOW}30${SET})"
read interval
[ -z $interval ]&&interval=30
echo -e "\n${WHITE}${interval}${SET}\n"
echo -e "调节失败上限次数(如: ${YELLOW}50${SET})"
read max
[ -z $max ]&&max=50
echo -e "\n${WHITE}${max}${SET}\n"
cat > $dir/local_network.ini <<-EOF
range="$range"
interval=$interval
max=$max
EOF
;;
esac
)
       
server_r()
(
pkill ssr-local 2> /dev/null
cat > $dir/ssr-local.conf<<-EOF
{
"server": "$server", 
"server_port": $server_port, 
"local_port": 1088, 
"password": "$password", 
"method":"$method", 
"timeout": 600, 
"protocol": "$protocol", 
"obfs": "$obfs", 
"obfs_param": "$1", 
"protocol_param": "$protocol_param"
}
EOF
$dir/ssr-local -l 1088 -b 127.0.0.1 -c $dir/ssr-local.conf -f $dir/ssr.pid 2> /dev/null
if [ $? -ne 0 ]; then
  echo -e "${RED}启动ss-local失败!${SET}"
  EXIT
fi
while true; do
  nc 127.0.0.1 1088 < /dev/null 2> /dev/null
  if [[ $? -eq 0 || $(netstat -lntp|grep 'LISTEN'|grep '127.0.0.1:1088') != "" ]]; then
    break
  else
    waiting "等待确认ssr-local启动成功..."
  fi
done
local response=$(curl -x socks5://127.0.0.1:1088 -sL http://ip.cn)
if [[ "${response}" = *"来自"* ]]; then
  echo -e "${response/当前 /服务器}"
else
  echo -e "${RED}连接到服务器失败！请检查脚本配置的服务器是否正确可用。${SET}"
  EXIT
fi
)

decode()
{
local ssr=$(echo ${1#ssr://}|base64 -d)
server=$(echo $ssr|cut -d: -f1)
server_port=$(echo $ssr|cut -d: -f2)
protocol=$(echo $ssr|cut -d: -f3)
method=$(echo $ssr|cut -d: -f4)
obfs=$(echo $ssr|cut -d: -f5)
password=$(echo $ssr|cut -d: -f6|cut -d/ -f1|base64 -d)
}

download()
(
#dd if=/dev/zero of=/sdcard/5M bs=1M count=5
rm $dir/test.file 2> /dev/null
curl -x socks5://127.0.0.1:1088 -sL https://github.com/yiguihai/Collection/raw/master/5M -o $dir/test.file
if [ $? -ne 0 ]; then
  echo -e "${RED}测试文件下载失败!${SET}"
  EXIT
fi
local size=$(($(wc -c < "$dir/test.file")+0))
if [[ ! -f $dir/test.file||$size -ne 5242880 ]]; then
  echo -e "${RED}下载文件大小不一致!${SET}"
  EXIT
else
  waiting "测试文件下载完成"
fi
)

data()
{
if [[ "$1" == "on" ]];then
  su -c /system/bin/svc data enable
elif [[ "$1" == "off" ]];then
  su -c /system/bin/svc data disable
fi
if [ $? -ne 0 ]; then
  echo -e "${RED}开启或关闭数据网络失败!${SET}"
  EXIT
fi
}

airplane()
(
if [[ "$1" == "on" ]];then
  su -c settings put global airplane_mode_on 1
  su -c am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true 1> /dev/null
elif [[ "$1" == "off" ]];then
  su -c settings put global airplane_mode_on 0
  su -c am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false 1> /dev/null
fi
if [ $? -ne 0 ]; then
  echo -e "${RED}开启或关闭飞行模式失败!${SET}"
  EXIT
fi
)

check()
(
if [[ $1 == "" || $2 == "" ]]; then
  echo -e "${RED}获取传送参数有误!${SET}"
  EXIT
fi
local result=$(printf "%.2f" $(echo "$1-$2"|bc))
if [[ $(echo "($1-$2)>1.50"|bc) -eq 1 ]]; then
  echo -e "${YELLOW}亲测这个混淆Host不免流量${SET}"
fi
if [[ $(echo "($1-$2)<1.50"|bc) -eq 1 ]]; then
  echo -e "${CYAN}这个混淆Host可能免流量${SET}\r"
  termux-tts-speak "发现一个可能免流量的混淆 $3 消耗掉流量 $result"
  termux-vibrate -d 1000
fi
echo -e "测试流量消耗 ${RED}$result${SET}"
)

usage()
(
cat <<-EOF

    Copyright (C) 2018 Guihai Yi <yiguihai@gmail.com>

    Usage: $0 [options]

       -a           使用ssr://加密链接
       -b           重新修改脚本配置
    
    Please visit: http://github.com/yiguihai and contact.
EOF
exit $1
)

edit_ini()
(
echo -ne "====请选择====\033[0K\r"
while true; do
  echo -e "1 ---> 脚本项目配置"
  echo -e "2 ---> 服务器设置"
  echo -e "3 ---> 内网调节配置"
  read opt
  case $opt in 
  1|2|3)  
  break
  ;;
  *)
  unset opt
  ;;
  esac
done
:
write_select $opt
)

EXIT()
(
date +"%Y年%m月%d日 %H:%M:%S 脚本退出。"
rm $dir/test.file 2> /dev/null
pkill ssr-local 2> /dev/null
termux-vibrate -d 1500
kill $$
exit 1
)

for i in ${tool_array[@]}; do
  type $i 1>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "缺少 ${RED}$i${SET} 命令"
    EXIT
  fi
done
if [ ! -d $dir ]; then
  mkdir $dir
fi
if [ ! -s $dir/config.ini ]; then
  write_select 1
fi
if [ ! -s $dir/server.ini ]; then
  write_select 2
fi
if [ ! -s $dir/local_network.ini ]; then
  write_select 3
fi
source $dir/config.ini 2> /dev/null
source $dir/server.ini 2> /dev/null
source $dir/local_network.ini 2> /dev/null
while getopts "a:b" opt; do
  case $opt in
    a)
      decode $OPTARG
      break
      ;;
    b)
      edit_ini $OPTARG
      break
      ;;
    \?)
      usage
      kill $$
      ;;
  esac
done
if [ ! -x $dir/ssr-local ]; then
  echo -ne "开始下载ss-local执行文件...\033[0K\r"
  curl -sL https://github.com/yiguihai/binary/raw/master/ssr-local -o $dir/ssr-local
  chmod +x $dir/ssr-local
  :
fi
echo -e "服务器 ${LIGHTPURPLE}$server${SET} 远程端口 ${LIGHTPURPLE}$server_port${SET} 加密方法 ${LIGHTPURPLE}$method${SET} 协议 ${LIGHTPURPLE}$protocol${SET} 协议参数 ${LIGHTPURPLE}$protocol_param${SET} 混淆方式 ${LIGHTPURPLE}$obfs${SET}\n"
until [ "$host" ]; do
  host=($(termux-dialog -t "请输入需要测试的Host(多个用空格隔开)"|jq -r '.["text"]'|egrep -o '(\w+\.\w+)+'))
done
x=${#host[@]}
for i in ${host[@]}; do
  ((x--))
  echo -e "混淆数量 ${WHITE}${#host[@]}${SET} 剩余 ${PURPLE}$x${SET} 待测试"
  while true; do
    wifi_state=$(termux-wifi-connectioninfo|jq -r '.["ip"]')
    if [[ $wifi_state != "0.0.0.0" ]]; then
      waiting "等待用户主动关闭wifi网络"
    else
      break
    fi
  done
    message
    old_flow=$flow
    old_received=$received
    local_network
    if [[ $local_ip == "" ]]; then
      while true; do
        local_network
        if [[ $local_ip == "" ]]; then
          waiting "等待用户主动打开数据网络"
        else
          break
        fi
      done
    fi 
    if [[ $my_ip == "" && $range != "" ]]; then
      echo -ne "${YELLOW}内网不符合要求！开始调节内网。${SET}\033[0K\r"
      y=$((max))
      while true; do
        ((y--))
        if [ $y -le 0 ]; then
          echo -e "${RED}达到调节失败上限!${SET}"
          EXIT
        fi
        airplane on
        w=$interval
        while [ $w -gt 0 ]; do
          echo -ne "${YELLOW}开关飞行模式中${SET} ${WHITE}$w${SET}\033[0K\r"
          sleep 1
          ((w--))
        done
        airplane off
        waiting_network
        local_network        
        if [[ $my_ip == "" ]]; then
          echo -e "当前内网: ${GREEN}$local_ip${SET} 不符合要求。$y"
        else
          break
        fi
      done
      :
      echo -ne "\r           \r"
    fi
    printf "%s ${CYAN}%.2f${SET} %s ${GREEN}%s${SET}\n" 已使用流量: $old_flow 内网: $local_ip
    echo -e "正在测试: ${GREEN}$i${SET}"
    echo -ne "开始启动执行文件...\033[0K\r"
    server_r $i
    :
    echo -ne "开始下载测试文件...\033[0K\r"
    download
    :
    case $mode in
    1)  
      echo -ne "关闭数据连接...\033[0K\r"
      data off
      :
      countdown $pause
      echo -ne "打开数据连接...\033[0K\r"
      data on
      :
    ;;
    2)  
      echo -ne "打开飞行模式...\033[0K\r"
      airplane on
      :
      countdown $pause
      echo -ne "关闭飞行模式...\033[0K\r"
      airplane off
      :
    ;;
    *)  
      echo -e "${YELLOW}你没有设置好脚本配置mode选项可能会造成测试结果不准确误报等问题！${SET}"
    ;;
    esac
    waiting_network
    echo -ne "开始发送查询短信...\033[0K\r"
    termux-sms-send -n $cxyys $cxzl
    :
    while true; do
      message_state=$(termux-sms-list -l 1|jq -r '.[0]["received"]')
      if [[ $message_state != $old_received ]]; then
        break
      else
        waiting "等待接收返回短信..."
      fi
    done
    echo -ne "开始对比流量信息...\033[0K\r"
    message
    :
    check $flow $old_flow $i
    echo
done
EXIT