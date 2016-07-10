#!/bin/bash

function installFFmpeg {
    if [ "$#" -ne 1 ]; then
        echo "Invalid argument count"
    fi

    FFMPEG_VERSION="$1"
    CURR_DIR="$(pwd)"

    cd ${HOME}

    wget https://github.com/FFmpeg/FFmpeg/archive/${FFMPEG_VERSION}.tar.gz
    tar zxf ${FFMPEG_VERSION}.tar.gz

    cd FFmpeg-${FFMPEG_VERSION}
    mkdir -p build
    cd build
    ../configure --disable-yasm --enable-shared --prefix=${HOME}/install

    make
    make install

    cd ${CURR_DIR}
}

function installGlfw {
    if [ "$#" -ne 1 ]; then
        echo "Invalid argument count"
    fi

    GLFW_VERSION="$1"
    CURR_DIR="$(pwd)"

    cd ${HOME}

    wget https://github.com/glfw/glfw/archive/${GLFW_VERSION}.tar.gz
    tar zxf ${GLFW_VERSION}.tar.gz

    cd glfw-${GLFW_VERSION}
    mkdir -p build
    cd build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${HOME}/install -DBUILD_SHARED_LIBS=ON ../

    make
    make install

    cd ${CURR_DIR}
}

function copyLibs {
    cp ${HOME}/install/lib/*.so* ${LD_LIBRARY_PATH//:}/
}

# remember current dir, to return to in the end
CURR_DIR="$(pwd)"

# create install directory for libraries
cd ${HOME}
mkdir install

# compile libs
installFFmpeg n2.6.7
installGlfw 3.2

# copy compiled libraries to ld path.
copyLibs

cd ${CURR_DIR}
