apt-get install --no-install-recommends build-essential autoconf libtool automake git unzip
#下载编译器，非常珍贵的记录
wget https://archive.openwrt.org/snapshots/trunk/ramips/mt7620/OpenWrt-Toolchain-ramips-mt7620_gcc-5.3.0_musl-1.1.16.Linux-x86_64.tar.bz2
tar -vjf OpenWrt-Toolchain-ramips-mt7620_gcc-5.3.0_musl-1.1.16.Linux-x86_64.tar.bz2

export PATH=$PATH:~/OpenWrt-Toolchain-ramips-mt7620_gcc-5.3.0_musl-1.1.16.Linux-x86_64/toolchain-mipsel_24kec+dsp_gcc-5.3.0_musl-1.1.16/bin
target_host=mipsel-openwrt-linux
export STAGING_DIR=~/OpenWrt-Toolchain-ramips-mt7620_gcc-5.3.0_musl-1.1.16.Linux-x86_64
export AR=$target_host-ar
export AS=$target_host-gcc
export CC=$target_host-gcc
export CXX=$target_host-c++
export LD=$target_host-ld
export STRIP=$target_host-strip
export LDD=$target_host-readelf

./configure \
--host=$target_host \
--prefix=/root/tmp



./configure --host=$target_host --disable-ssp --disable-documentation --with-ev=/root/tmp --with-sodium=/root/tmp --with-cares=/root/tmp --with-pcre=/root/tmp --with-mbedtls=/root/tmp --prefix=/root/ss

#查找替换

find ~/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev  -lcares -lsodium -lmbedcrypto -lpcre/-l:libev.a  -l:libcares.a -l:libsodium.a -l:libmbedcrypto.a -l:libpcre.a/g' {} +
find ~/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev -lsodium/-l:libev.a -l:libsodium.a/g' {} +
find ~/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lcares/-l:libcares.a/g' {} +

find ~/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs strip
find ~/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs upx --best -v

