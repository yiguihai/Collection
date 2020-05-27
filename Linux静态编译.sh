#echo | gcc -v -x c++ -E -

# Installation of basic build dependencies
## Debian / Ubuntu
sudo apt-get install --no-install-recommends build-essential autoconf libtool automake git unzip
## CentOS / Fedora / RHEL
yum -y install gcc gcc-c++ autoconf libtool automake make git unzip
## Arch
sudo pacman -S gettext gcc autoconf libtool automake make asciidoc xmlto c-ares libev


libev_ver="4.33"
libpcre_ver="8.44"
libmbedtls_ver="2.16.6"
tmp="/tmp"

#重新登录
logout

mkdir $tmp/tmp
mkdir $tmp/ss

cd $tmp

#mbedtls
wget https://tls.mbed.org/download/mbedtls-${libmbedtls_ver}-gpl.tgz
tar xf mbedtls-${libmbedtls_ver}-gpl.tgz
rm -rf mbedtls-${libmbedtls_ver}-gpl.tgz
cd mbedtls-${libmbedtls_ver}
make no_test
make install DESTDIR=$tmp/tmp
make clean

cd $tmp

#libsodium
git clone https://github.com/jedisct1/libsodium --branch stable
cd libsodium
./autogen.sh
./configure --prefix=$tmp/tmp
make
make install
make clean

cd $tmp

#libev
wget http://dist.schmorp.de/libev/libev-${libev_ver}.tar.gz
tar zxvf libev-${libev_ver}.tar.gz
rm -rf libev-${libev_ver}.tar.gz
cd libev-${libev_ver}
chmod +x autogen.sh
./autogen.sh
./configure --prefix=$tmp/tmp
make
make install
make clean

cd $tmp

#libcares
git clone https://github.com/c-ares/c-ares
cd c-ares
./buildconf
./configure --prefix=$tmp/tmp
make
make install
make clean

cd $tmp

#libpcre
wget https://ftp.pcre.org/pub/pcre/pcre-${libpcre_ver}.zip
unzip pcre-${libpcre_ver}.zip
cd pcre-${libpcre_ver}
autoreconf -f -i -v
#cd cmake
#cmake -DCMAKE_INSTALL_PREFIX:PATH=/root/tmp ..
./configure --prefix=$tmp/tmp
make
make install
make clean

cd $tmp

#upx
wget https://github.com/upx/upx/releases/download/v3.96/upx-3.96-amd64_linux.tar.xz
tar -xvJf upx-3.96-amd64_linux.tar.xz
mv -f upx-3.96-amd64_linux/upx /usr/local/bin
rm -rf upx-3.96-amd64_*
#openssl
#wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz
#tar zxvf openssl-1.1.1b.tar.gz
#rm -rf openssl-1.1.1b.tar.gz
#cd openssl-1.1.1b
#./config --prefix=/root/tmp LIBS=-llog
#make
#make install_sw

#cd

#zlib
#wget http://zlib.net/zlib-1.2.11.tar.gz
#tar zxvf zlib-1.2.11.tar.gz
#rm -rf zlib-1.2.11.tar.gz
#cd zlib-1.2.11
#./configure --prefix=/root/tmp
#make
#make install
#make clean

cd $tmp

#shadowsocks
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
./autogen.sh
#静态编译需要链接 libc.a 等库下面是在 /usr/lib 目录路径
./configure \
--disable-ssp \
--disable-documentation \
--with-ev=$tmp/tmp \
--with-sodium=$tmp/tmp \
--with-cares=$tmp/tmp \
--with-pcre=$tmp/tmp \
--with-mbedtls=$tmp/tmp \
--prefix=$tmp/ss \
LDFLAGS="-Wl,-static -static -static-libgcc -L/usr/lib" \
CFLAGS="-I/usr/include" LIBS="-lpthread -lm"

#查找替换 链接第三方静态库
find $tmp/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev  -lcares -lsodium -lmbedcrypto -lpcre/-l:libev.a  -l:libcares.a -l:libsodium.a -l:libmbedcrypto.a -l:libpcre.a/g' {} +
find $tmp/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lev -lsodium/-l:libev.a -l:libsodium.a/g' {} +
find $tmp/shadowsocks-libev/ -name "Makefile" -type f -exec sed -i 's/-lcares/-l:libcares.a/g' {} +
make
find $tmp/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs strip
find $tmp/shadowsocks-libev/src ! -name 'ss-nat' -a -name 'ss-*' -type f | xargs upx --best --ultra-brute -v
make install
make clean
