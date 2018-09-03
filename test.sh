#死亡之ping
ping -f -s 65507 192.168.1.2

#快速扫描局域网用户
for i in $(seq 1 253); do
  ping -c 1 -w 3 -n 192.168.5.$i|grep "bytes from" &
done

#获取参数
while getopts "a:b:cdef" opt; do
  case $opt in
    a)
      echo "this is -a the arg is ! $OPTARG" 
      ;;
    b)
      echo "this is -b the arg is ! $OPTARG" 
      ;;
    c)
      echo "this is -c the arg is ! $OPTARG" 
      ;;
    \?)
      echo "Invalid option: -$OPTARG" 
      ;;
  esac
done

#函数测试
function print_msg { 
    local a=$(($1+$2))
    return $a
}
print_msg 2 3
echo $?
