#!/bin/bash

CURR_DIR="$(pwd)"
CACHE_ARCHIVE="dcv.tar.gz"

cd ${HOME}

wget -O ${CACHE_ARCHIVE} https://drive.google.com/uc?id=0ByTt1Q1eZW5WVk50MS1sWU9wYTg&export=download
tar -zxf ${CACHE_ARCHIVE} -C ${LD_LIBRARY_PATH}/

cd ${CURR_DIR}
