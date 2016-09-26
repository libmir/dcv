#!/usr/bin/env bash

if [ $# -lt 1 ]; then
    SHA_PREV=master
    ARGS=""
else
    SHA_PREV=$1
    ARGS=${@:2}
fi

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

function check_file_exists {
	if [ ! -e $1 ]; then
		error "$2"
		exit
	fi
}

function chapter_title {
	echo -e "$GREEN\n-----------------------------------------------------------------------------------"
	echo -e "$1"
	echo -e "-----------------------------------------------------------------------------------\n$NC"
}

function info 
{
	echo -e "$BLUE$1$NC"
}

function error
{
	echo -e "$RED$1$NC"
}

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

chapter_title "Running DCV performance benchmark against: $SHA_PREV"

BIN=performance-tests
PREV_LIB=$SCRIPTPATH/.cache/$SHA_PREV/libdcv.a
PREV_BIN=$SCRIPTPATH/.cache/$SHA_PREV/tests/performance-tests/performance-tests

PREV_PROFILE_RESULT=$SCRIPTPATH/.cache/$SHA_PREV/tests/performance-tests/profile.csv
CURR_PROFILE_RESULT=$SCRIPTPATH/profile.csv

BENCHMARK_RESULT=$SCRIPTPATH/benchmark.csv

# command for running tests
RUN=./$BIN
RUN_PREV=$PREV_BIN

info "Project cleanup..."
rm -rf $BIN profile.csv benchmark.csv dub.selections.json .dub/ dub.userprefs source/dcv/

chapter_title "Building test application..."
dub build --compiler=ldc2 --build=release

check_file_exists $BIN "Building test application failed. Exiting..."

info "Building test application successful..."
chmod u+x $BIN

chapter_title "Running checkout and build..."

info "Checking out $SHA_PREV"
$RUN -m checkout -s $SHA_PREV
check_file_exists $PREV_BIN "Building $SHA_PREV test application failed. Exiting..."
chmod u+x $PREV_BIN

chapter_title "Profiling..."
info "$SHA_PREV:"
$RUN_PREV -m measure $ARGS

if [ -e $PREV_PROFILE_RESULT ]; then
    echo "$SHA_PREV profiling done, results written in $PREV_PROFILE_RESULT"
else
    echo "$SHA_PREV profiling failed."
    exit
fi

info "\nthis:"
$RUN -m measure $ARGS

if [ -e $CURR_PROFILE_RESULT ]; then
    echo "$SHA_CURR profiling done, results written in $CURR_PROFILE_RESULT"
else
    echo "$SHA_CURR profiling failed."
    exit
fi

chapter_title "Comparing and writing comparison results..."
$RUN -m compare --sha $SHA_PREV $ARGS

if [ -e $BENCHMARK_RESULT ]; then
    echo "Comparison done, results written in $BENCHMARK_RESULT"
else
    echo "Benchmark failed."
    exit
fi

chapter_title "Results..."
cat benchmark.csv


