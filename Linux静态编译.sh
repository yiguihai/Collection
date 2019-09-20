#echo | gcc -v -x c++ -E -

for i in gcc gcc-c++ clang autoconf automake pkg-config git wget curl unzip
do
  yum install $i
done
apt-get -y update
apt -y install build-essential unzip gzip wget curl autoconf automake gcc make git


libev_ver="4.27"
libpcre_ver="8.43"

#重新登录
logout

mkdir /root/tmp
mkdir /root/ss

cd 

#mbedtls
git clone --recursive https://github.com/ARMmbed/mbedtls.git
cd mbedtls
git submodule update --init crypto
make no_test -j
make install DESTDIR=/root/tmp
make clean

cd 

#libsodium
git clone https://github.com/jedisct1/libsodium --branch stable
cd libsodium
./autogen.sh
./configure --prefix=/root/tmp
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
./configure --prefix=/root/tmp
make -j
make install
make clean

cd

#libcares
git clone https://github.com/c-ares/c-ares
cd c-ares
./buildconf
./configure --prefix=/root/tmp
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
#cmake -DCMAKE_INSTALL_PREFIX:PATH=/root/tmp ..
./configure --prefix=/root/tmp
make -j
make install
make clean

cd

#openssl
#wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz
#tar zxvf openssl-1.1.1b.tar.gz
#rm -rf openssl-1.1.1b.tar.gz
#cd openssl-1.1.1b
#./config --prefix=/root/tmp LIBS=-llog
#make -j
#make install_sw

#cd

#zlib
#wget http://zlib.net/zlib-1.2.11.tar.gz
#tar zxvf zlib-1.2.11.tar.gz
#rm -rf zlib-1.2.11.tar.gz
#cd zlib-1.2.11
#./configure --prefix=/root/tmp
#make -j
#make install
#make clean
#cd

#shadowsocks
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
./autogen.sh
./configure --disable-documentation --with-ev=/root/tmp --with-sodium=/root/tmp --with-cares=/root/tmp --with-pcre=/root/tmp --with-mbedtls=/root/tmp --prefix=/root/ss

#查找替换
find /root/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev  -lcares -lsodium -lmbedcrypto -lpcre/-l:libev.a  -l:libcares.a -l:libsodium.a -l:libmbedcrypto.a -l:libpcre.a/g' {} +
find /root/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev -lsodium/-l:libev.a -l:libsodium.a/g' {} +
find /root/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lcares/-l:libcares.a/g' {} +
make -j
find /root/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs strip
#find /root/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs upx --best -v
make install
make clean
