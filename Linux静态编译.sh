#echo | gcc -v -x c++ -E -
yum install -y gcc 
yum install -y gcc-c++
yum install -y clang
yum install -y autoconf
yum install -y automake
yum install -y libtool
yum install -y gettext
yum install -y pkg-config
yum install -y git
yum install -y wget
yum install -y unzip

#重新登录
logout

mkdir /root/tmp
mkdir /root/ss

cd 

#mbedtls
git clone --recursive https://github.com/ARMmbed/mbedtls.git
cd mbedtls
git submodule update --init crypto
make no_test -j4
make install DESTDIR=/root/tmp
make clean

cd 

#libsodium
git clone https://github.com/jedisct1/libsodium --branch stable
cd libsodium
./autogen.sh
./configure --prefix=/root/tmp
make -j4
make install
make clean

cd 

#libev
wget http://dist.schmorp.de/libev/libev-4.25.tar.gz
tar zxvf libev-4.25.tar.gz
rm -rf libev-4.25.tar.gz
cd libev-4.25
chmod +x autogen.sh
./autogen.sh
./configure --prefix=/root/tmp
make -j4
make install
make clean

cd

#libcares
git clone https://github.com/c-ares/c-ares
cd c-ares
./buildconf
./configure --prefix=/root/tmp
make -j4
make install
make clean

cd

#libpcre
wget https://ftp.pcre.org/pub/pcre/pcre-8.43.zip
unzip pcre-8.43.zip
cd pcre-8.43
autoreconf -f -i -v
#cd cmake
#cmake -DCMAKE_INSTALL_PREFIX:PATH=/root/tmp ..
./configure --prefix=/root/tmp
make -j4
make install
make clean

cd

#openssl
#wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz
#tar zxvf openssl-1.1.1b.tar.gz
#rm -rf openssl-1.1.1b.tar.gz
#cd openssl-1.1.1b
#./config --prefix=/root/tmp LIBS=-llog
#make -j4
#make install_sw

#cd

#zlib
#wget http://zlib.net/zlib-1.2.11.tar.gz
#tar zxvf zlib-1.2.11.tar.gz
#rm -rf zlib-1.2.11.tar.gz
#cd zlib-1.2.11
#./configure --prefix=/root/tmp
#make -j4
#make install
#make clean
#cd

#shadowsocks
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
./autogen.sh
./configure --disable-documentation --disable-libtool-lock --with-ev=/root/tmp --with-sodium=/root/tmp --with-cares=/root/tmp --with-pcre=/root/tmp --with-mbedtls=/root/tmp --prefix=/root/ss

#查找替换
find /root/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev  -lcares -lsodium -lmbedcrypto -lpcre/-l:libev.a  -l:libcares.a -l:libsodium.a -l:libmbedcrypto.a -l:libpcre.a/g' {} +
find /root/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev -lsodium/-l:libev.a -l:libsodium.a/g' {} +
find /root/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lcares/-l:libcares.a/g' {} +
make -j4
find /root/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs strip
#find /root/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs upx --best -v
make install
make clean
