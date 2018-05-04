#!/bin/bash
# Copyright (C) 2016-2018 Canonical
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
shopt -s -o nounset

if [ $# -eq 0 ] ; then
	echo "Please provide release version, ex. 17.04.00."
	exit 1
fi

RELEASE_VERSION=${1}
FWTS_LIVE_SOURCE=fwts-live-trusty-amd64

cat /etc/lsb-release | grep "Ubuntu 14.04" >> /dev/null

if [ $? -ne 0 ] ; then
	echo "Ubuntu 14.04 is required! aborting..."
	exit 1
fi

if [ -e fwts-live ] ; then
	echo "fwts-live directory exists! aborting..."
	exit 1
fi

if ! which lb > /dev/null ; then
	echo "Please install live-build"
	exit 1
fi

if ! which git > /dev/null ; then
	echo "Installing git..."
	sudo apt-get -y install git
fi

if ! which mmd > /dev/null ; then
	echo "Installing mtools..."
	sudo apt-get -y install mtools
fi

# download source code
mkdir fwts-live && cd fwts-live
git clone git://git.launchpad.net/~canonical-hwe-team/+git/$FWTS_LIVE_SOURCE

echo "Visit http://packages.ubuntu.com/trusty/kernel/linux-image and update kernel version in chroot"
echo "Press any key to continue..."
read

# setup
FWTS_LIVE_PATH=$(pwd)/$FWTS_LIVE_SOURCE
mkdir build; cd build; ln -s $FWTS_LIVE_PATH; mv $FWTS_LIVE_SOURCE config; mkdir chroot

# compile
sudo lb clean && sudo lb build

# find the binary
echo ""
find . -name binary.img -exec cp '{}' ~/fwts-live-${RELEASE_VERSION}.img ';'

