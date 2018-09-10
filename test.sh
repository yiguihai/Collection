#!/system/bin/sh 
#
#免流混淆Host批量自动化测试脚本
#bash <(curl -sL https://raw.githubusercontent.com/yiguihai/Collection/master/mlssr.sh)
#
dir="/data/data/com.termux/files/home"
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
array=(
"curl"
"egrep"
"bc"
"termux-sms-list"
"termux-vibrate"
"termux-tts-speak"
"termux-sms-send"
"termux-dialog"
"termux-telephony-deviceinfo"
"termux-wifi-connectioninfo"
"jq"
"nc"
"printf"
"pkill"
"settings"
"am"
"wc"
"cut"
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

waiting(){
local secs=$(($1))
while [ $secs -gt 0 ]; do
   echo -ne "$2 $secs\033[0K\r"
   sleep 1
   : $((secs--))
done
}

waiting_network(){
while true; do
local data_state=$(termux-telephony-deviceinfo|jq -r '.["data_state"]') 
if [[ $data_state != "connected" ]]; then
  waiting 5 "等待数据网络恢复"
else
  break
fi
done
}

message(){
local typ=$(termux-sms-list -l 1|jq -r '.[0]["type"]')
local num=$(termux-sms-list -l 1|jq -r '.[0]["number"]')
export received=$(termux-sms-list -l 1|jq -r '.[0]["received"]')
local sms=$(termux-sms-list -l 1|jq '.[0]["body"]'|egrep -o '[0-9]{1,5}\.[0-9][1-9]')
if [[ $typ == "inbox" && $num == $cxyys && $(echo "$sms > 0"|bc) -eq 1 ]]; then
  export flow=$sms
else
  echo -e "${RED}获取流量信息失败!${SET}"
  echo -e "正在发送短信 $cxzl 到 $cxyys"
  termux-sms-send -n $cxyys "$cxzl"
  echo -e "等待信息返回后再次重试，如果还失败就无能为力了"
  EXIT
fi
}

local_network(){
export local_ip=$(ip address|egrep -o '10\.([0-9]{1,3}\.){2}[0-9]{1,3}')
local local_ip2=$(echo $local_ip|cut -d '.' -f2)
if [[ $range != "" ]]; then
local reqsubstr="-"
for string in "$range"; do
  if [[ -z "${string##*$reqsubstr*}" ]]; then    
    local str1=$(echo $string|cut -d "$reqsubstr" -f1)
    local str2=$(echo $string|cut -d "$reqsubstr" -f2)
    local str3=$(($str2-$str1))
    if [[ $local_ip2 -ge $str1 && $local_ip2 -le $str2 ]]; then
        export my_ip=$string
    fi
  else
    if [[ $local_ip2 == $string ]]; then
        export my_ip=$string
    fi
  fi
done
fi
}

config(){
cat > /sdcard/mlssr.ini<<-EOF
##短信查询##
cxzl="1501"          #短信查询业务指令
cxyys=10010          #服务号

##内网范围限定##
#留空不自动调节内网。多个用空格隔开，如 1-30 31 35 42
range=""
#调节间隔时间(秒)
interval=30

##时间设置##
#下载测试文件完成后暂停多少秒再查询，防止流量延迟错报。
pause="00:15:00"          #15分钟
#下载测试文件完成后断开网络连接方式。
mode=1           #1 关闭网络 2 打开飞行模式


##服务器设置##
server="13.67.65.168"          #服务器
server_port=80          #远程端口
password="94ish.men"          #密码
method="none"          #加密方法
protocol="auth_chain_a"          #协议
obfs="http_simple"          #混淆方式
protocol_param="1473:wentian"          #协议参数
EOF
if [ ! -s /sdcard/mlssr.ini ]; then
  echo -e "${RED}脚本配置写出失败！${SET}"
  EXIT
fi
echo -e "脚本配置文件在${CYAN}/sdcard/mlssr.ini${SET}"
}
       
ssr(){
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
  echo -e "${RED}启动ssr失败!${SET}"
  EXIT
fi
while true; do
  nc 127.0.0.1 1088 < /dev/null 2> /dev/null
  if [[ $? -eq 0 || $(netstat -lntp|grep 'LISTEN'|grep '127.0.0.1:1088') != "" ]]; then
    break
  else
    echo -ne "等待确认ssr-local启动成功...\033[0K\r"
    sleep 1
    :
  fi
done
}

download(){
#dd if=/dev/zero of=/sdcard/5M bs=1M count=5
rm $dir/test.file 2> /dev/null
curl -x socks5://127.0.0.1:1088 -sL https://github.com/yiguihai/Collection/raw/master/5M -o $dir/test.file
if [ $? -ne 0 ]; then
  echo -e "${RED}下载失败!${SET}"
  EXIT
fi
local size=$(($(wc -c < "$dir/test.file")+0))
if [[ ! -f $dir/test.file||$size -ne 5242880 ]]; then
  echo -e "${RED}下载文件大小不一致!${SET}"
  EXIT
else
  echo -ne "下载测试文件完成\033[0K\r"
  sleep 1
  :
fi
}

data(){
if [[ "$1" == "on" ]];then
  su -c /system/bin/svc data enable
elif [[ "$1" == "off" ]];then
  su -c /system/bin/svc data disable
fi
}

airplane(){
if [[ "$1" == "on" ]];then
su -c settings put global airplane_mode_on 1
su -c am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true 1> /dev/null
elif [[ "$1" == "off" ]];then
su -c settings put global airplane_mode_on 0
su -c am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false 1> /dev/null
fi
}

check(){
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
  echo -e "$3\n" >> /sdcard/测试结果.txt
fi
echo -e "测试流量消耗 ${RED}$result${SET}"
echo -e "测试结果写出在${CYAN}/sdcard/测试结果.txt${SET}"
}

EXIT(){
date +"%Y年%m月%d日 %H:%M:%S 脚本退出"
rm $dir/test.file 2> /dev/null
pkill ssr-local 2> /dev/null
termux-vibrate -d 1500
kill $$
exit 1
}

echo -ne "开始检测运行环境...\033[0K\r"
if [ ! -d $dir ]; then
  echo -e "${RED}请安装使用Termux运行脚本${SET}"
  EXIT 
fi
:
echo -e "${RED}脚本使用正则匹配短信内容，如果发现获取的剩余流量有误请立即停止运行!!!${SET}"
for i in ${array[@]}; do
  type $i 1>/dev/null
  if [ $? -ne 0 ]; then
    echo -ne "缺少 ${RED}$i${SET} 命令\033[0K\r"
    pkg install -y $i 1> /dev/null
    :
    if [ $? -ne 0 ]; then
      echo -e "安装 ${RED}$i${SET} 失败"
      EXIT
    fi
  fi
done
if [ ! -x $dir/ssr-local ]; then
  echo -ne "开始下载执行文件...\033[0K\r"
  curl -sL https://github.com/yiguihai/binary/raw/master/ssr-local -o $dir/ssr-local
  chmod +x $dir/ssr-local
  :
fi
if [ ! -s /sdcard/mlssr.ini ]; then
  echo -ne "开始写出脚本配置...\033[0K\r"
  config
  :
fi
source /sdcard/mlssr.ini
echo -e "服务器 ${LIGHTPURPLE}$server${SET} 远程端口 ${LIGHTPURPLE}$server_port${SET} 加密方法 ${LIGHTPURPLE}$method${SET} 协议 ${LIGHTPURPLE}$protocol${SET} 协议参数 ${LIGHTPURPLE}$protocol_param${SET} 混淆方式 ${LIGHTPURPLE}$obfs${SET}\n"
rm /sdcard/测试结果.txt 2> /dev/null
host=($(termux-dialog -t "请输入需要测试的Host(多个用空格隔开)"|jq -r '.["text"]'))
x=${#host[@]}
for i in ${host[@]}; do
  ((x--))
  echo -e "混淆数量 ${WHITE}${#host[@]}${SET} 剩余 ${LIGHTPURPLE}$x${SET} 待测试"
  while true; do
      wifi_state=$(termux-wifi-connectioninfo|jq -r '.["ip"]')
      if [[ $wifi_state != "0.0.0.0" ]]; then
        waiting 5 "等待用户主动关闭wifi网络"
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
          waiting 5 "等待用户主动打开数据网络"
        else
          break
        fi
      done
    fi    
    if [[ $my_ip == "" && $range != "" ]]; then
      echo -ne "${RED}内网不符合要求！开始调节内网。${SET}\033[0K\r"
      while true; do
        airplane on
        waiting $interval "${YELLOW}开关飞行模式中${SET}" 2> /dev/null
        airplane off
        waiting_network
        local_network
        if [[ $my_ip == "" ]]; then
          echo -e "当前内网: ${GREEN}$local_ip${SET} 不符合要求"
        else
          break
        fi
      done
      :
    fi
    printf "%s ${CYAN}%.2f${SET} %s ${GREEN}%s${SET}\n" 已使用流量 $old_flow 内网: $local_ip
    echo -e "正在测试: ${GREEN}$i${SET}"
    echo -ne "开始启动执行文件...\033[0K\r"
    ssr $i
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
    *)  echo -e "${YELLOW}你没有设置脚本配置mode选项可能会造成测试结果不准确误报等问题！${SET}"
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
        waiting 5 "等待接收返回短信..."
      fi
    done
    echo -ne "开始对比流量信息...\033[0K\r"
    message
    :
    check $flow $old_flow $i
    echo
done
EXIT
