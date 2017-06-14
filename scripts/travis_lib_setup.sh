#!/bin/bash

CURR_DIR="$(pwd)"
CACHE_ARCHIVE="${HOME}/dcv.tar.gz"

cd ${HOME}

echo Downloading cached archives to ${CACHE_ARCHIVE}
wget -O ${CACHE_ARCHIVE} "https://drive.google.com/uc?id=0ByTt1Q1eZW5WVk50MS1sWU9wYTg&export=download"

echo Copying to LD_LIBRARY_PATH...
tar -zxf ${CACHE_ARCHIVE} -C ${LD_LIBRARY_PATH//:}/
ls ${LD_LIBRARY_PATH//:}

cd ${CURR_DIR}
