#!/bin/bash
# Copyright (C) 2020 Canonical
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

if ! which git > /dev/null ; then
	echo "Installing git..."
	sudo apt-get -y install git
fi

if ! which docker > /dev/null ; then
	echo "Installing docker..."
	sudo apt-get -y install docker.io
	exit 1
fi

[ -e fwts-live ] || git clone https://github.com/alexhungce/fwts-live
cd fwts-live
sudo make

# find the binary
echo ""
find . -name pc.img.xz -exec mv '{}' fwts-live-${RELEASE_VERSION}.img.xz ';'

