dns="8.8.8.8"
domain_list=(
#哔哩哔哩(通用)
bangumi.bilibili.com
#腾讯视频(通用)
vv.video.qq.com
sec.video.qq.com
#优酷视频(手机网页版)
api.youku.com
statis.api.3g.youku.com
static.youku.com
#爱奇艺(手机网页版)
data.video.iqiyi.com
cache.m.iqiyi.com
#网易云音乐(安卓客户端)
music.163.com
mam.netease.com
mr.da.netease.com
nstool.netease.com
music.httpdns.c.163.com
#QQ音乐(手机网页版)
c.y.qq.com
u.y.qq.com
#酷狗音乐(手机网页版)
m.kugou.com
#酷我音乐(手机网页版)
m.kuwo.cn
#ip测试
ip.cn
)

x=0
for ((i=1;i<=${#domain_list[@]};i++ )); do
hint="${domain_list[$i-1]}"
ip_list=$(nslookup $hint $dns | egrep -o '[0-9]{1,3}(\.[0-9]{1,3}){3}'|egrep -v $dns)
echo "$hint"
for j in ${ip_list}; do
  ((x++))
  iptables -t nat -A out_forward -p tcp -d $j -j DNAT --to-destination 127.0.0.1:3129
 done
done
echo "共 $[i-1] 个域名，已添加 $x 条规则 (使用 $dns DNS解析)"
#apt-get install dnsutils
#iptables -t nat -N out_forward
#iptables -t nat -A OUTPUT -p tcp ! -d 127.0.0.1 -j out_forward
#bash <(curl -sL https://raw.githubusercontent.com/yiguihai/Collection/master/china_jx.sh)
