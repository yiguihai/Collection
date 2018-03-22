ss_url=ss://eGNoYWNoYTIwLWlldGYtcG9seTEzMDU6eWdoMTUxNzc1NDI0OTM@96.8.118.245:80?plugin=obfs-local%3Bobfs%3Dhttp%3Bobfs-host%3Dwx.qlogo.cn
a=${ss_url#ss:\/\/} #删除ss://
a1=$(echo $a|base64 -d 2>&-) #解密base64得到加密方法和密码
a2=${a##*@} #删除@前面段落
method=${a1%%:*} #获得加密方式
password=${a1##*:} #获得密码
#判断有无混淆插件
if [[ $(echo -n "$a"|grep 'plugin=obfs-local') ]] then
a3=${a2%%?plugin=obfs-local*} #获得服务器＋端口部分
a4=${a2##*?plugin=obfs-local} #获得混淆方式和混淆Host部分
server=${a3%%:*} #获得服务器
server_port=${a3##*:} #获得远程端口
a5=${a4//%3B/;} #替换
a6=${a5//%3D/=} #替换
a7=${a6##*obfs-host=} #从前面段落删除
obfs_host=${a7%%;*}
obfs=${a6##*obfs=} #从前面段落删除
else
server=${a2%%:*}
server_port=${a2##*:}
