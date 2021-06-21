#!/bin/bash
# Copyright (C) 2021 Canonical
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

RELEASE_VERSION=$(apt-cache show fwts | grep ^Version | egrep -o '[0-9]{2}.[0-9]{2}.[0-9]{2}' | sort -r | head -1)
FWTS_LIVE_IMAGE="fwts-live-${RELEASE_VERSION}-x86.img"
MULTIPASS_SCRIPT="build_fwts-live-multipass.sh"
MULTIPASS_VM="fwts-live"
UBUNTU_VERSION=hirsute

# install multipass
if ! which multipass &> /dev/null ; then
	sudo snap install multipass
fi

if [ $# -ne 0 ] ; then
	UBUNTU_VERSION=$1
fi

# create script for multipass VM ('EOF' is used to avoid expanding variables)
cat <<- EOF > $MULTIPASS_SCRIPT
#!/bin/bash
SELF="\$(readlink -f "\${BASH_SOURCE[0]}")"
[[ \$UID == 0 ]] || exec sudo -- "\$BASH" -- "\$SELF" "\$@"

printf "deb-src http://archive.ubuntu.com/ubuntu/ %s main universe \n" \$(lsb_release -cs){,-updates,-security} | \\
	tee -a /etc/apt/sources.list

apt update && apt -y install build-essential git snapcraft ubuntu-image vmdk-stream-converter
apt-get -y build-dep livecd-rootfs

git clone --depth 1 https://github.com/alexhungce/pc-amd64-gadget-focal.git pc-amd64-gadget
cd pc-amd64-gadget && snapcraft prime && cd ..

git clone --depth 1 https://github.com/alexhungce/fwts-livecd-rootfs-focal.git fwts-livecd-rootfs
cd fwts-livecd-rootfs && debian/rules binary && dpkg -i ../livecd-rootfs_*_amd64.deb && cd ..

ubuntu-image classic -a amd64 -d -p ubuntu-cpc -s $UBUNTU_VERSION -i 850M -O /image --extra-ppas \\
	firmware-testing-team/ppa-fwts-stable pc-amd64-gadget/prime

xz /image/pc.img
EOF

multipass launch 18.04 --cpus 4 --mem 4G --disk 20G --name ${MULTIPASS_VM}

multipass transfer $MULTIPASS_SCRIPT ${MULTIPASS_VM}:/home/ubuntu/$MULTIPASS_SCRIPT
multipass exec ${MULTIPASS_VM}  -- chmod +x $MULTIPASS_SCRIPT
multipass exec ${MULTIPASS_VM}  -- ./$MULTIPASS_SCRIPT

rm $MULTIPASS_SCRIPT

multipass transfer ${MULTIPASS_VM}:/image/pc.img.xz ${FWTS_LIVE_IMAGE}.xz
multipass stop ${MULTIPASS_VM}
multipass delete ${MULTIPASS_VM}
multipass purge

notify-send "building fwts-live is completed..."

if [ -f ${FWTS_LIVE_IMAGE}.xz ] ; then
	sha256sum ${FWTS_LIVE_IMAGE}.xz
	# test built image
	unp ${FWTS_LIVE_IMAGE}.xz
	qemu-system-x86_64 -drive format=raw,file=${FWTS_LIVE_IMAGE} -m 2048 -smp 2
	rm ${FWTS_LIVE_IMAGE}
fi

