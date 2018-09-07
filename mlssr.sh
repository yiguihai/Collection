#!/system/bin/sh 
#
#免流Host自动化测试脚本
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
"termux-sms-send"
"termux-dialog"
"jq"
"printf"
"pkill"
"settings"
"am"
)

analysis(){
echo $1 | while read line
do
local flow=$(echo $line|egrep -o '[0-9]{2,}\.[1-9][0-9]')
if [[ $flow != "" ]]; then
  echo $flow
  break
fi
done
}

ssr(){
pkill ssr-local 2> /dev/null
cat > /sdcard/ssr-local.conf<<-EOF
{
"server": "155.94.190.151", 
"server_port": 9999, 
"local_port": 1088, 
"password": "9999", 
"method":"chacha20", 
"timeout": 600, 
"protocol": "auth_sha1_v4", 
"obfs": "http_simple", 
"obfs_param": "$1", 
"protocol_param": ""
}
EOF
$dir/ssr-local -l 1088 -b 127.0.0.1 -c /sdcard/ssr-local.conf -f $dir/ssr.pid 2> /dev/null
if [ $? -ne 0 ]; then
  echo -e "${RED}启动ssr失败!${SET}"
  EXIT
fi
}

download(){
rm $dir/test.file 2> /dev/null
curl -x socks5://127.0.0.1:1088 -sL https://github.com/yiguihai/binary/raw/master/10M > $dir/test.file
if [ $? -ne 0 ]; then
  echo -e "${RED}下载失败!${SET}"
  EXIT
fi
local size=$(($(wc -c < "$dir/test.file")+0))
if [[ ! -f $dir/test.file||$size -ne 10485760 ]]; then
  echo -e "${RED}下载文件大小不一致!${SET}"
  EXIT
else
  echo "下载测试完成"
fi
}

airplane(){
echo "打开飞行模式"
su -c settings put global airplane_mode_on 1
su -c am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true 1> /dev/null
echo "脚本进入休眠状态，等待运营商流量数据更新(20分钟)…"
sleep $1 2> /dev/null
echo "关闭飞行模式(1分钟)"
su -c settings put global airplane_mode_on 0
su -c am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false 1> /dev/null
}

flow(){
local typ=$(termux-sms-list -l 1|jq -r '.[0]["type"]')
local num=$(termux-sms-list -l 1|jq -r '.[0]["number"]')
local sms=$(termux-sms-list -l 1|jq -r '.[0]["body"]')
if [[ $typ == "inbox" && $num == "10010" ]]; then
  local flow=$(analysis "$sms")
else
  echo -e "${RED}获取流量短信失败！${SET}"
  EXIT
fi
if [[ $(echo "$flow > 0"|bc) -le 0 ]]; then
  echo -e "${RED}获取流量信息异常${SET}"
  EXIT
fi
printf "%.2f" $flow
}

check(){
if [[ $(echo "($1 - $2) > 4096"|bc) -eq 1 ]]; then
  echo -e "${YELLOW}亲测这个Host不免流量${SET}"
fi
if [[ $(echo "($1 - $2) < 1024"|bc) -eq 1 ]]; then
  echo -e "${CYAN}这个混淆Host可能免流量${SET}"
  termux-tts-speak "发现一个可能免流量的混淆"
  termux-vibrate -d 1000
fi
}

EXIT(){
date +"%Y年%m月%d日 %H:%M:%S 脚本退出"
rm $dir/test.file 2> /dev/null
pkill ssr-local 2> /dev/null
termux-vibrate -d 1500
exit 1
}
clear
echo -e "开始检测运行环境 ${YELLOW}$$${SET}"
echo -e "${RED}脚本使用正则匹配短信内容，如果发现获取的剩余流量有误请立即停止运行${SET}\n"
for ((i=1;i<=${#array[@]};i++)); do
  type ${array[$i]} 1>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "缺少 ${RED}${array[$i]}${SET} 命令"
    EXIT
  fi
done
if [ ! -x $dir/ssr-local ]; then
  echo "开始下载ssr-local"
  chmod +x $dir/ssr-local
fi
if [ ! -s /sdcard/ssr-local.conf ]; then
  echo "开始下载ssr-local.conf"
  echo -e "请到配置好${RED}/sdcard/ssr-local.conf${SET}文件再运行！"
  EXIT
fi
host=($(termux-dialog -t "输入需要测试的Host"|jq -r '.["text"]'))
for ((i=${#host[@]};i>=1;i--)); do
  echo -e "共 ${WHITE}${#host[@]}${SET} 剩余数量 ${BLUE}$i${SET} 待测试"
  hosts=${host[$i-1]}
  flow=$(flow)
  if [[ $hosts != "" ]]; then
    echo "获取已使用流量 $flow"
    echo -e "正在测试: ${GREEN}$hosts${SET}"
    echo "开始启动SSRR"
    ssr $hosts
    echo "开始下载测试文件..."
    download
    #关闭网络20分钟后再查询
    airplane 1200
    #等待1分钟恢复信号
    sleep 60
    echo "开始发送查询短信(5分钟)"
    termux-sms-send -n 10010 "1501"
    #设定发送5分钟后再查返回短信
    sleep 300
    echo "开始对比流量信息\n"
    check $(flow) $flow
    echo
  fi
done
EXIT
#dd if=/dev/zero of=/sdcard/10M bs=1M count=10