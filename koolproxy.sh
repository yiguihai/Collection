#!/usr/bin/env bash

export HISTCONTROL=ignorespace
export HISTSIZE=0
export PATH=$PATH:$(pwd)
alias echo_date='echo $(date +%Y年%m月%d日\ %X)'
shopt -s expand_aliases
url_path='https://dev.tencent.com/u/shaoxia1991/p/koolproxyr/git/raw/master/koolproxyR/koolproxyR'

lan_list=(
0.0.0.0/8
10.0.0.0/8
100.64.0.0/10
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.0.0.0/29
192.0.2.0/24
192.88.99.0/24
192.168.0.0/16
198.18.0.0/15
198.51.100.0/24
203.0.113.0/24
224.0.0.0/3
);

rules_list=(
kpr_video_list.txt
easylistchina.txt
yhosts.txt
fanboy-annoyance.txt
kp.dat
);

ss_nat()
(
  iptables -t nat -N nat_lan
  iptables -t nat -N nat_out
  iptables -t nat -N koolproxy
  for i in ${lan_list[@]}
  do
    iptables -t nat -A nat_lan -d $i -j ACCEPT
  done
  iptables -t nat -A nat_out -j nat_lan
  iptables -t nat -A nat_out -m owner --gid-owner root -j ACCEPT
  iptables -t nat -A nat_out -m owner --uid-owner $(id -u) -j ACCEPT
  iptables -t nat -A nat_out -j koolproxy
  iptables -t nat -A OUTPUT -j nat_out
  read -p "需要拦截https流量吗？ [y/n] " opt
  if [[ "$opt" = 'Y' && "$opt" = 'y' ]]; then
    port='80,443,8080'
  else
    port='80,8080'
  fi
  iptables -t nat -A koolproxy -p tcp -m multiport --dport $port -j REDIRECT --to-ports 3000
);

download_file()(
  filename=$(basename $1)
  wget --no-check-certificate -q -c -t3 -T30 -O $1 $2
  if [ $? -ne 0 ]; then
    echo -e "[${red}Error${plain}] Download ${filename} failed."
    echo_date 下载文件 ${filename} 失败，请检查网络！
    exit $?
  fi
);


_status()(
  if [ "$(pgrep koolproxy)" ] ; then
    echo_date KoolProxy正在运行
  else
    echo_date KoolProxy未运行
  fi
  iptables -vxn -t nat -L nat_lan --line-number
  iptables -vxn -t nat -L nat_out --line-number
  iptables -vxn -t nat -L koolproxy --line-number
);

_stop()(
  if [ "$(pgrep koolproxy)" ] ; then
    pkill koolproxy > /dev/null 2>&1
  fi

  iptables -t nat -D OUTPUT -j nat_out

  iptables -t nat -F nat_lan
  iptables -t nat -F nat_out
  iptables -t nat -F koolproxy
  iptables -t nat -X nat_lan
  iptables -t nat -X nat_out
  iptables -t nat -X koolproxy
);

update_kpr()(
  echo_date 检查版本更新中请耐心等待.....
  download_file koolproxy_now $url_path/koolproxy
  koolproxyR_now_md5=`md5sum koolproxy|awk '{print $1}'`
  koolproxyR_download_md5=`md5sum koolproxy_now|awk '{print $1}'`
  if [[ "$koolproxyR_now_md5" != "$koolproxyR_download_md5" ]]; then     
    echo_date 检查到与线上版本不一致，开始更新.....
    echo_date 移动更新文件
    mv -f koolproxy_now koolproxy
    echo_date 添加文件执行权限
    chmod +x koolproxy
  else
    echo_date KoolProxy并没有更新
  fi
  for i in source.list openssl.cnf
  do
    if [ ! -s data/$i ]; then
      echo_date 正在下载 $i 文件
      download_file data/$i $url_path/data/$i
    fi
  done
  echo_date 配置source.list文件中
  sed -i "s/1|/0|/g" data/source.list  
  for i in ${new_list[@]} user.txt
  do
    sed -i "s/0|$i/1|$i/g" data/source.list
  done
);

update_rule()(  
  echo_date 检查规则更新中请耐心等待.....
  if [ ! -d data/rules ]; then
    echo_date 正在创建rules文件夹.....
    mkdir data/rules
  fi
  if [ ! -s data/rules/user.txt ]; then
    rules_list=(${rules_list[*]} user.txt);
  fi
  
  for i in ${rules_list[@]}
  do
    if [[ "$(md5sum data/rules/$i|awk '{print $1}')" != "$(wget -qO- -t3 -T15 $url_path/data/rules/$i.md5)" ]]; then
      echo_date 更新 $i 规则文件中…
      download_file data/rules/$i $url_path/data/rules/$i
    else
      echo_date $i 无需更新
    fi
  done
);

gen_ca()(
  if [ ! -f data/openssl.cnf ]; then
    echo_date 没有找到openssl.cnf
    exit $?
  fi

  if [ -f data/private/ca.key.pem ]; then
    echo_date 已经有证书了！
    read -p "需要重新生成证书吗? [y/n] " opt    
  else
    opt='Y'
  fi

  case $opt in
    y|Y)
      echo_date 生成证书中...
      rm -rf data/private data/certs
      #step 1, root ca
      mkdir -p data/certs data/private
      rm -f data/serial private/ca.key.pem
      chmod 700 data/private
      echo 1000 > data/serial
      openssl genrsa -aes256 -passout pass:koolshare -out data/private/ca.key.pem 2048
      chmod 400 data/private/ca.key.pem
      openssl req -config data/openssl.cnf -passin pass:koolshare \
      -subj "/C=CN/ST=Beijing/L=KP/O=KoolProxy inc/CN=koolproxy.com" \
      -key data/private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out data/certs/ca.crt

      #step 2, domain rsa key
      openssl genrsa -aes256 -passout pass:koolshare -out data/private/base.key.pem 2048
      echo_date https过滤模式下访问 110.110.110.110 下载导入证书
      echo_date 证书生成完毕...      
    ;;
    *)
      echo_date 取消证书生成...
    ;;
  esac
);

history -cw
clear


while true; do  
  if [ ! -d data ]; then
    echo_date 正在创建data文件夹.....
    mkdir data
  fi
  if [ ! -x koolproxy ]; then
    echo_date 安装KoolProxy中...
    update_kpr
    update_rule
  fi
  menu_list=(开始 运行状态 停止 调试输出 生成证书 检查更新)
  echo "KoolProxyR $(koolproxy -v)"
  select action in ${menu_list[@]}; do  
    case $action in
      开始)
          koolproxy -d
          ss_nat
          ;;
      运行状态)
          _status
          ;;
      停止)
          _stop
          ;;
      调试输出)
          _stop
          ss_nat
         koolproxy -l 0
          ;;
      生成证书)
          gen_ca
          ;;
      检查更新)
          update_kpr
          update_rule
          ;;
      *)
          break 2
          ;;
    esac
  done
done