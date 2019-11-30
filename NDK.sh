wget https://dl.google.com/android/repository/android-ndk-r20-linux-x86_64.zip
export NDK=/root/android-ndk-r20
$NDK/build/tools/make_standalone_toolchain.py \
--arch arm \
--api 16 \
--install-dir /root/android-arm-toolchain

# Add the standalone toolchain to the search path.
    export PATH=$PATH:/root/android-arm-toolchain/bin

    # Tell configure what tools to use.
    target_host=arm-linux-androideabi
    export AR=$target_host-ar
    export AS=armv7a-linux-androideabi16-clang
    export CC=armv7a-linux-androideabi16-clang
    export CXX=armv7a-linux-androideabi16-clang++
    export LD=$target_host-ld
    export STRIP=$target_host-strip

    # Tell configure what flags Android requires.
    export CFLAGS="-fPIE -fPIC"
    export LDFLAGS="-pie"
    
./configure \
--host=$target_host \
--prefix=/root/tmp \
--enable-shared=no
