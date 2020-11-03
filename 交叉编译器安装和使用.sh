#下载NDK工具链
str=$(wget -qO- https://developer.android.com/ndk/downloads/ | grep 'Latest Stable Version')
str=${str##*\(}
latest_version=${str%\)*}
wget --quiet --continue --show-progress https://dl.google.com/android/repository/android-ndk-${latest_version}-linux-x86_64.zip
unzip android-ndk-${latest_version}-linux-x86_64.zip
rm -f android-ndk-${latest_version}-linux-x86_64.zip

#API级别
https://developer.android.com/distribute/best-practices/develop/target-sdk?hl=zh-CN

#安装upx压缩
wget https://github.com/upx/upx/releases/download/v3.94/upx-3.94-amd64_linux.tar.xz
tar -xvJf upx-3.94-amd64_linux.tar.xz
mv -f upx-3.94-amd64_linux/upx /usr/local/bin
rm -rf upx-3.94-amd64_*

#安装arm64位版本
/root/android-ndk-r20/build/tools/make_standalone_toolchain.py \
--arch arm64 \
--api 29 \
--install-dir /root/android-arm64-29-toolchain

#配置交叉编译环境变量(arm64)
# Add the standalone toolchain to the search path.
    export PATH=$PATH:/root/android-arm64-29-toolchain/bin

    # Tell configure what tools to use.
    target_host=aarch64-linux-android
    export AR=$target_host-ar
    export AS=$target_host-gcc
    export CC=$target_host-gcc
    export CXX=$target_host-gcc++
    export LD=$target_host-ld
    export STRIP=$target_host-strip
    export LDD=$target_host-readelf

    # Tell configure what flags Android requires.
    export CFLAGS="-fPIE -fPIC"
    export LDFLAGS="-pie"

#一般编译
./configure \
--host=$target_host \
--prefix=/root/android-arm64-29-toolchain/sysroot/usr \
--enable-shared=no

#https://blog.csdn.net/qq_15437629/article/details/85808229
#Makefile选项CFLAGS,LDFLAGS,LIBS
#    CFLAGS 表示用于 C 编译器的选项，CXXFLAGS 表示用于 C++ 编译器的选项。这两个变量实际上涵盖了编译和汇编两个步骤。
#    CFLAGS： 指定头文件（.h文件）的路径，如：CFLAGS=-I /usr/include -I /path/include。同样地，安装一个包时会在安装路径下建立一个include目录，当安装过程中出现问题时，试着把以前安装的包的include目录加入到该变量中来。
#    LDFLAGS：gcc 等编译器会用到的一些优化参数，也可以在里面指定库文件的位置。用法：LDFLAGS=-static -L /usr/lib -L /path/to/your/lib。每安装一个包都几乎一定的会在安装目录里建立一个lib目录。如果明明安装了某个包，而安装另一个包时，它愣是说找不到，可以抒那个包的lib路径加入的LDFALGS中试一下。
#    LIBS：告诉链接器要链接哪些库文件，如LIBS = -lpthread -liconv

#查看编译好的二进制链接库了那些库
$LDD -d ss-local

#减小体积
$STRIP ss-local

#upx压缩 3.9.4版本可用 高版本报错
upx --best -v ss-local



#编译openssl
#不要设置CC等全局编译环境变量，会自动查找编译器设置了会报错
export ANDROID_NDK_HOME=/root/android-arm64-29-toolchain
git clone --depth 1 https://github.com/openssl/openssl
cd openssl
git submodule update --init --recursive
./Configure android-arm64 -D__ANDROID_API__=29 --prefix=/tmp/ssl
make -j8
make install_sw

#编译pcre
autoreconf -f -i -v
./configure \
--host=$target_host \
--prefix=/root/android-arm64-29-toolchain/sysroot/usr \
--enable-shared=no
#需要关闭一些选项不然编译不通过 --disable-cpp

#编译shadowsocks-libev
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
    echo ${i##*/}
  fi
done
#需要修改以上文件的的代码，否则报错
make -j
find /root/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs $STRIP
find /root/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs upx --best -v
make install
make clean

#编译shadowsocks-rust
#先安装rust并编译好openssl依赖
git clone --depth 1 https://github.com/shadowsocks/shadowsocks-rust.git
cd shadowsocks-rust
#rustup target list|grep android
rustup target add aarch64-linux-android
mkdir -p .cargo
cat >.cargo/config <<EOF
[target.aarch64-linux-android]
linker = "aarch64-linux-android-gcc"
ar = "aarch64-linux-android-ar"
EOF
env OPENSSL_STATIC=yes \
OPENSSL_LIB_DIR=/tmp/ssl/lib \
OPENSSL_INCLUDE_DIR=/tmp/ssl/include \
cargo build --release --target aarch64-linux-android

#cmake交叉编译
#在cmake目录创建一个 CrossCompile.cmake 文件写入
#set(CMAKE_SYSTEM_NAME Linux)
#set(CMAKE_C_COMPILER "arm-openwrt-linux-gcc")
#set(CMAKE_CXX_COMPILER "arm-openwrt-linux-g++") 
#set(CMAKE_FIND_ROOT_PATH /tmp/tmp /tmp/openwrt-sdk-19.07.3-bcm53xx_gcc-7.5.0_musl_eabi.Linux-x86_64/staging_dir/toolchain-arm_cortex-a9_gcc-7.5.0_musl_eabi)
#然后返回源码目录创建build目录进入，输入 cmake -DCMAKE_TOOLCHAIN_FILE=刚才的路径/CrossCompile.cmake ..
#参考 https://zhuanlan.zhihu.com/p/100367053

#golang工具链安装
latest_version="$(wget -qO- https://golang.org/dl/|grep 'download downloadBox' | grep -oP '\d+\.\d+(\.\d+)?' | head -n 1)"
wget --quiet --continue --show-progress https://dl.google.com/go/go${latest_version}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${latest_version}.linux-amd64.tar.gz
rm -f go${latest_version}.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin GOROOT="/usr/local/go" GOTOOLDIR="/usr/local/go/pkg/tool/linux_amd64"
#查看编译支持的平台
go tool dist list
#交叉编译不同平台时需要配置ndk工具链($cc与$home)
env CGO_ENABLED=1 GOOS=android GOARCH=arm64 go build -ldflags "-s -w"
#termux
env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w"
