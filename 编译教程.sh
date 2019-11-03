#echo | gcc -v -x c++ -E -
#ln -s /system/lib64/libc.so libresolv.so

pkg install -y openssh
cd .ssh
termux-setup-storage
cp /sdcard/id_rsa.pub .
cat id_rsa.pub >> authorized_keys

pkg update

for i in clang autoconf automake libtool gettext pkg-config git wget; do
  pkg install -y $i
done

#重新登录
logout

mkdir /data/data/com.termux/files/home/tmp
mkdir /data/data/com.termux/files/home/ss

libev_ver="4.27"
libpcre_ver="8.43"

cd 

#mbedtls
git clone --recursive https://github.com/ARMmbed/mbedtls.git
cd mbedtls
git submodule update --init crypto
make no_test -j
make install DESTDIR=/data/data/com.termux/files/home/tmp
make clean

cd 

#libsodium
git clone https://github.com/jedisct1/libsodium --branch stable
cd libsodium
./autogen.sh
./configure --prefix=/data/data/com.termux/files/home/tmp
make -j
make install
make clean

cd 

#libev
wget http://dist.schmorp.de/libev/libev-${libev_ver}.tar.gz
tar zxvf libev-${libev_ver}.tar.gz
rm -rf libev-${libev_ver}.tar.gz
cd libev-${libev_ver}
chmod +x autogen.sh
./autogen.sh
./configure --prefix=/data/data/com.termux/files/home/tmp
make -j
make install
make clean

cd

#libcares
git clone https://github.com/c-ares/c-ares
cd c-ares
./buildconf
./configure --prefix=/data/data/com.termux/files/home/tmp
make -j
make install
make clean

cd

#libpcre
wget https://ftp.pcre.org/pub/pcre/pcre-${libpcre_ver}.zip
unzip pcre-${libpcre_ver}.zip
cd pcre-${libpcre_ver}
autoreconf -f -i -v
#cd cmake
#cmake -DCMAKE_INSTALL_PREFIX:PATH=/data/data/com.termux/files/home/tmp ..
./configure --prefix=/data/data/com.termux/files/home/tmp
make -j
make install
make clean

cd

#openssl
#wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz
#tar zxvf openssl-1.1.1d.tar.gz
#rm -rf openssl-1.1.1d.tar.gz
#cd openssl-1.1.1d
#./config --prefix=/data/data/com.termux/files/home/tmp -llog
#make -j
#make install_sw

#cd

#shadowsocks
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
./autogen.sh
./configure --disable-documentation --with-pcre=/data/data/com.termux/files/home/tmp --with-mbedtls=/data/data/com.termux/files/home/tmp --with-sodium=/data/data/com.termux/files/home/tmp --with-cares=/data/data/com.termux/files/home/tmp --with-ev=/data/data/com.termux/files/home/tmp LIBS="-llog" --prefix=/data/data/com.termux/files/home/ss

#查找替换
find /data/data/com.termux/files/home/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev  -lcares -lsodium -lmbedcrypto -lpcre/-l:libev.a  -l:libcares.a -l:libsodium.a -l:libmbedcrypto.a -l:libpcre.a/g' {} +
find /data/data/com.termux/files/home/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev -lsodium/-l:libev.a -l:libsodium.a/g' {} +
find /data/data/com.termux/files/home/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lcares/-l:libcares.a/g' {} +

#修改源码

make -j
find /data/data/com.termux/files/home/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs strip
find /data/data/com.termux/files/home/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs upx --best -v
make install
make clean
