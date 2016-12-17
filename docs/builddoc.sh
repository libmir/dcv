#!/usr/bin/env bash

set DDOCFILE=dcv.ddoc

cd ../

dub --build=docs --compiler=ldc2 dcv:core
dub --build=docs --compiler=ldc2 dcv:io
dub --build=docs --compiler=ldc2 dcv:plot

cd docs
