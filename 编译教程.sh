pkg install -y openssh
cd .ssh
termux-setup-storage
cp /sdcard/id_rsa.pub .
cat id_rsa.pub >> authorized_keys

pkg install -y clang
pkg install -y autoconf
pkg install -y automake
pkg install -y libtool
pkg install -y gettext
pkg install -y pkg-config
pkg install -y git
pkg install -y wget

#重新登录
logout

mkdir /data/data/com.termux/files/home/tmp

#查找替换
#find /data/data/com.termux/files/home/openvpn/ -name "Makefile" -type f -exec sed -i 's/-llzo2/-l:liblzo2.a/g' {} +

cd 

#mbedtls
git clone https://github.com/ARMmbed/mbedtls
cd mbedtls
make no_test -j4
make install DESTDIR=/data/data/com.termux/files/home/tmp
make clean

cd 

#libsodium
wget https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz
tar zxvf libsodium-1.0.16.tar.gz
rm -rf libsodium-1.0.16.tar.gz
cd libsodium-1.0.16
./autogen.sh
./configure --prefix=/data/data/com.termux/files/home/tmp
make -j4
make install
make clean

cd 

#libev
wget http://dist.schmorp.de/libev/libev-4.24.tar.gz
tar zxvf libev-4.24.tar.gz
rm -rf libev-4.24.tar.gz
cd libev-4.24
chmod +x autogen.sh
./autogen.sh
./configure --prefix=/data/data/com.termux/files/home/tmp
make -j4
make install
make clean

cd

#libcares
git clone https://github.com/c-ares/c-ares
cd c-ares
./buildconf
./configure --prefix=/data/data/com.termux/files/home/tmp
make -j4
make install
make clean

cd

#libpcre
wget https://ftp.pcre.org/pub/pcre/pcre-8.42.zip
unzip pcre-8.42.zip
cd pcre-8.42
autoreconf -f -i -v
#cd cmake
#cmake -DCMAKE_INSTALL_PREFIX:PATH=/data/data/com.termux/files/home/tmp ..
./configure --prefix=/data/data/com.termux/files/home/tmp
make -j4
make install
make clean

cd

#shadowsocks
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
./autogen.sh
./configure --disable-documentation --disable-ssp --with-pcre=/data/data/com.termux/files/home/tmp --with-mbedtls=/data/data/com.termux/files/home/tmp --with-sodium=/data/data/com.termux/files/home/tmp --with-cares=/data/data/com.termux/files/home/tmp --with-ev=/data/data/com.termux/files/home/tmp LIBS="-llog" --enable-static=yes --program-prefix=/system

#-l:libev.a  -l:libcares.a -l:libsodium.a -l:libmbedcrypto.a -l:libpcre.a

make -j4
make install
make clean



#openssl
wget https://www.openssl.org/source/openssl-1.1.1.tar.gz
tar zxvf openssl-1.1.1.tar.gz
cd openssl-1.1.1
./config --prefix=/data/data/com.termux/files/home/tmp LIBS=-llog
make -j4
make install_sw