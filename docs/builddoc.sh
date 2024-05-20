#!/usr/bin/env bash

set DDOCFILE=dcv.ddoc

cd ../

dub --build=docs --compiler=ldc2 dcv:core
dub --build=docs --compiler=ldc2 dcv:imageio
dub --build=docs --compiler=ldc2 dcv:linalg

cd docs
