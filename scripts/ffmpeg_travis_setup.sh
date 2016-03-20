#!/usr/bin/bash
cd ${HOME}
wget https://github.com/FFmpeg/FFmpeg/archive/n2.7.6.tar.gz
tar zxf n2.7.6.tar.gz
mkdir install
cd FFmpeg-n2.7.6
mkdir -p build
cd build
../configure --disable-yasm --enable-shared --prefix=${HOME}/install
make
make install
cp ${HOME}/install/lib/*.so* ~/dmd2/linux/lib64/
cd ${HOME}
