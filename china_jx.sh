dns="114.114.114.114"
domain_name=(
	vv.video.qq.com
	sec.video.qq.com
	api.youku.com
	statis.api.3g.youku.com
	static.youku.com
	data.video.iqiyi.com
	cache.m.iqiyi.com
	music.163.com
	nstool.netease.com
	music.httpdns.c.163.com
	c.y.qq.com
	u.y.qq.com
	m.kugou.com
	m.kuwo.cn
)

x=0
for ((i=1;i<=${#domain_name[@]};i++ )); do
hint="${domain_name[$i-1]}"
ip_list=$(nslookup $hint $dns | egrep -o '[0-9]{1,3}(\.[0-9]{1,3}){3}'|egrep -v $dns)
echo "$hint"
for j in ${ip_list}; do
  ((x++))
  iptables -t nat -A out_forward -p tcp -d $j -j DNAT --to-destination 127.0.0.1:3129
	done
done
echo "共 $i 个域名，已添加 $x 条规则 (使用 $dns DNS解析)"