#下载NDK工具链
wget https://dl.google.com/android/repository/android-ndk-r20-linux-x86_64.zip
unzip android-ndk-r20-linux-x86_64.zip
rm -f android-ndk-r20-linux-x86_64.zip

#API级别
https://developer.android.com/distribute/best-practices/develop/target-sdk?hl=zh-CN

#安装arm位版本
/root/android-ndk-r20/build/tools/make_standalone_toolchain.py \
--arch arm \
--api 21 \
--install-dir /root/android-arm64-toolchain

#安装arm64位版本
/root/android-ndk-r20/build/tools/make_standalone_toolchain.py \
--arch arm64 \
--api 29 \
--install-dir /root/android-arm64-toolchain

#配置交叉编译环境变量(arm32)
# Add the standalone toolchain to the search path.
    export PATH=$PATH:/root/android-arm-toolchain/bin

    # Tell configure what tools to use.
    target_host=arm-linux-androideabi
    export AR=$target_host-ar
    export AS=armv7a-linux-androideabi21-clang
    export CC=armv7a-linux-androideabi21-clang
    export CXX=armv7a-linux-androideabi21-clang++
    export LD=$target_host-ld
    export STRIP=$target_host-strip
    export LDD=$target_host-readelf

    # Tell configure what flags Android requires.
    export CFLAGS="-fPIE -fPIC"
    export LDFLAGS="-pie"
#一般编译   
./configure \
--host=$target_host \
--prefix=/root/android-arm-toolchain/sysroot/usr \
--enable-shared=no

#配置交叉编译环境变量(arm64)
# Add the standalone toolchain to the search path.
    export PATH=$PATH:/root/android-arm64-toolchain/bin

    # Tell configure what tools to use.
    target_host=aarch64-linux-android
    export AR=$target_host-ar
    export AS=aarch64-linux-android29-clang
    export CC=aarch64-linux-android29-clang
    export CXX=aarch64-linux-android29-clang++
    export LD=$target_host-ld
    export STRIP=$target_host-strip
    export LDD=$target_host-readelf

    # Tell configure what flags Android requires.
    export CFLAGS="-fPIE -fPIC"
    export LDFLAGS="-pie"

#一般编译
./configure \
--host=$target_host \
--prefix=/root/android-arm64-toolchain/sysroot/usr \
--enable-shared=no
#查看编译好的二进制链接库了那些库
$LDD -d ss-local
#减小体积
$STRIP ss-local
#upx压缩 3.9.4版本可用 高版本报错
upx --best -v ss-local



#编译openssl
mkdir /root/ssl
export ANDROID_NDK_HOME=/root/android-arm64-toolchain
./Configure -llog no-shared no-comp no-hw no-engine --openssldir=/root/ssl --prefix=/root/ssl android-arm64
make -j8
make install

#编译pcre
./configure \
--host=$target_host \
--prefix=/root/android-arm64-toolchain/sysroot/usr \
--enable-shared=no
#需要注意pcre库编译此动态库是有玄学报错问题所以不编译。一般链接静态库使用即可

#编译shadowsocks
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
./autogen.sh
./configure --disable-documentation --host=$target_host --with-pcre=/root/tmp --with-mbedtls=/root/tmp --with-sodium=/root/tmp --with-cares=/root/tmp --with-ev=/root/tmp LIBS="-llog" --prefix=/root/ss
#查找替换
find /root/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev  -lcares -lsodium -lmbedcrypto -lpcre/-l:libev.a  -l:libcares.a -l:libsodium.a -l:libmbedcrypto.a -l:libpcre.a/g' {} +
find /root/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev -lsodium/-l:libev.a -l:libsodium.a/g' {} +
find /root/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lcares/-l:libcares.a/g' {} +
#修改源码
for i in /root/shadowsocks-libev/src/* ;do
  if [[ $(grep -i 'android' $i) ]];then
    echo ${$i##*/}
  fi
done
#需要修改以上文件的的代码，否则报错
make -j
find /root/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs $STRIP
find /root/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs upx --best -v
make install
make clean

wget https://dl.google.com/go/go1.13.4.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.13.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
#查看支持的平台
go tool dist list
env GOOS=linux GOARCH=amd64 go build -ldflags "-s -w"
#termux
env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w"
