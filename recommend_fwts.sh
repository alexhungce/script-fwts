#!/bin/bash
# Copyright (C) 2016-2021 Canonical
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

RECOMMEND_TESTS="version cpufreq maxfreq msr mtrr nx virt aspm dmicheck apicedge klog oops esrt uefibootpath uefirtvariable uefirttime uefirtmisc --acpitests --log-level=high"
HWE_TESTS="version mtrr virt apicedge klog oops interrupt"
S3_TESTS="s3 --s3-min-delay=60 --s3-max-delay=90 --s3-sleep-delay=90 --s3-multiple=30"
S4_TESTS="s4 --s4-min-delay=60 --s4-max-delay=90 --s4-multiple=30"

# add PPA for and install latest stable release (only once)
if ! grep -q ppa-fwts-stable /etc/apt/sources.list /etc/apt/sources.list.d/* ; then
	sudo add-apt-repository -y ppa:firmware-testing-team/ppa-fwts-stable
	sudo apt-get update
	sudo apt-get install -y fwts
fi

if [ $# -ne 1 ] ; then
	echo "Usage: recommend_fwts.sh oem|hwe|s3|s4"
	exit 1
fi

# run specific tests from user inputs
if [ $1 == "oem" ] ; then
	sudo fwts $RECOMMEND_TESTS
elif [ $1 == "ifv" ] ; then
	sudo fwts $RECOMMEND_TESTS --ifv
elif [ $1 == "hwe" ] ; then
	sudo fwts $HWE_TESTS
elif [ $1 == "s3" ] ; then
	sudo fwts $S3_TESTS
elif [ $1 == "s4" ] ; then
	sudo fwts $S4_TESTS
else
	echo "invalid arguments!"
	exit 1
fi

