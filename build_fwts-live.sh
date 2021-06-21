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
shopt -s -o nounset

sudo apt update

RELEASE_VERSION=$(apt-cache show fwts | grep ^Version | egrep -o '[0-9]{2}.[0-9]{2}.[0-9]{2}' | sort -r | head -1)
FWTS_LIVE_IMAGE="fwts-live-${RELEASE_VERSION}-x86.img"

if ! which git > /dev/null ; then
	echo "Installing git..."
	sudo apt-get -y install git
fi

if ! which docker > /dev/null ; then
	echo "Installing docker..."
	sudo apt-get -y install docker.io
	# this may require logout/login
	sudo usermod -aG docker $USER
	sudo service docker.io restart
	exit 1
fi

[ -e fwts-live ] || git clone https://github.com/alexhungce/fwts-live-focal fwts-live
cd fwts-live
make

# find the binary
echo ""
find . -name pc.img.xz -exec mv '{}' ${FWTS_LIVE_IMAGE}.xz ';'

sha256sum ${FWTS_LIVE_IMAGE}.xz
notify-send "building fwts-live is completed..."

# test built image
unp ${FWTS_LIVE_IMAGE}.xz
qemu-system-x86_64 -drive format=raw,file=${FWTS_LIVE_IMAGE} -m 2048 -smp 2
rm ${FWTS_LIVE_IMAGE}
