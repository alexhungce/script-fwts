#!/bin/bash
# Copyright (C) 2015-2021 Canonical
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
TEST_BUILD=false
SOURCE_REPO="ssh+git://kernel.ubuntu.com/srv/kernel.ubuntu.com/git/hwe/fwts.git"
TEST_SOURCE_REPO="https://github.com/alexhungce/fwts"
AUTHOR="Alex Hung <alex.hung@ubuntu.com>"
UBUNTU="jammy"
EDITOR=gedit

if [ $# -eq 0 ] ; then
	echo "Please provide release version, ex. 16.01.00."
	exit 1
fi

read -p "Is this a test build [y/N]?" -n 1 -r -s
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
	TEST_BUILD=true
fi

# == Reminder messages and prerequisites ==
RELEASE_VERSION=${1}
echo "FWTS V${RELEASE_VERSION} is to be released."
echo "Did you update fwts's mkpackage.sh vs. https://wiki.ubuntu.com/Releases?"
read -p "Please [ENTER] to continue or Ctrl+C to abort"

# connect to VPN
nmcli con up canonical-us

echo ""
echo "Please confirm upload rights of kernel.ubuntu.com and fwts.ubuntu.com"
read -p "Please [ENTER] to continue or Ctrl+C to abort"

if ! which dch > /dev/null ; then
	echo "Running \"apt-get install devscripts\""
	sudo apt-get install devscripts
	exit 1
fi

if ! which autopkgtest > /dev/null ; then
	echo "Running \"apt-get install autopkgtest\""
	sudo apt-get install autopkgtest
	exit 1
fi

# == Prepare the source code ==
# download fwts source code
if [ -e fwts ] ; then
	echo "fwts directory exists! aborting..."
	exit 1
fi

git clone git://kernel.ubuntu.com/hwe/fwts.git
cd fwts/

if [ $TEST_BUILD = true ] ; then
	read -p "Please apply patches for testing and press [ENTER] to continue"
	SOURCE_REPO=$TEST_SOURCE_REPO
fi

cat << EOF >> .git/config
[remote "upstream"]
         fetch = +refs/heads/*:refs/remotes/upstream/*
         url = ${SOURCE_REPO}
EOF

if [ $TEST_BUILD = true ] ; then
	git push -f upstream master
fi

# generate changelog based on the previous git tag..HEAD
echo "fwts (${RELEASE_VERSION}-0ubuntu1) $UBUNTU; urgency=medium" > ../fwts_${RELEASE_VERSION}_release_note
echo "" >> ../fwts_${RELEASE_VERSION}_release_note
git shortlog $(git describe --abbrev=0 --tags)..HEAD | sed "s/^     /  */g" | awk -F ' \\([[:digit:]]' ' { if ($0 ~ /^[A-Z]/) { print "  ["$1"]" } else { print } } ' >> ../fwts_${RELEASE_VERSION}_release_note
echo " -- $AUTHOR  $(date -R)" >> ../fwts_${RELEASE_VERSION}_release_note

# add the changelog to the changelog file
echo "1. ensure the format is correct, . names, max 80 characters per line etc."
echo "2. update the version, e.g: \"fwts (15.12.00-0ubuntu0) UNRELEASED; urgency=medium\" to "
echo "   \"fwts (16.01.00-0ubuntu0) xenial; urgency=medium\""
read -p "Please [ENTER] to continue or Ctrl+C to abort"

$EDITOR ../fwts_${RELEASE_VERSION}_release_note &
dch -i
# wait for copying to dch -i
echo "type \"done\" to continue..."
line=""
while true ; do
	read line
	if [ "$line" = "done" ] ; then
		break;
	fi
done

echo ""

# commit changelog
git add debian/changelog
git commit -s -m "debian: update changelog"

# update the version
./update_version.sh V${RELEASE_VERSION}

# generate tarball
git clean -fd
rm -rf m4/*
rm -f ../fwts_*

git archive V${RELEASE_VERSION} -o ../fwts_${RELEASE_VERSION}.orig.tar
gzip ../fwts_${RELEASE_VERSION}.orig.tar

# build the debian package
debuild -S -sa -I -i

# run ADT testing
sudo rm -f /tmp/failure.log
cd ..
sudo autopkgtest ./fwts_${RELEASE_VERSION}-0ubuntu1.dsc -- null || exit 1
cd fwts

# == Build and publish ==
# commit the changelog file and the tag
git push upstream master
git push upstream master --tags

# create a temporary directory to generate the final tarball
mkdir fwts-tarball
cd fwts-tarball/
cp ../auto-packager/mk*sh .
if [ $TEST_BUILD = true ] ; then
	# replace REPO for testing build
	SOURCE_REPO=${SOURCE_REPO//\//\\/}
	sed -i 's/git:\/\/kernel.ubuntu.com\/hwe\/fwts.git/'"$SOURCE_REPO"'/g' *.sh
fi
./mktar.sh V${RELEASE_VERSION}

# copy the final fwts tarball to fwts.ubuntu.com
cd V${RELEASE_VERSION}/
scp fwts-V${RELEASE_VERSION}.tar.gz fwts.ubuntu.com:/srv/fwts.ubuntu.com/www/release/

# update SHA256 on fwts.ubuntu.com
ssh fwts.ubuntu.com "cd /srv/fwts.ubuntu.com/www/release/ ; sha256sum fwts-V${RELEASE_VERSION}.tar.gz >> SHA256SUMS"

# generate the source packages for all supported Ubuntu releases
cd ..
./mkpackage.sh V${RELEASE_VERSION}

# disconnect from VPN
nmcli con down canonical-us

# upload the packages to the unstable-crack PPA to build
cd V${RELEASE_VERSION}

if [ $TEST_BUILD = true ] ; then
	dput ppa:firmware-testing-team/scratch */*es
	echo "Check build status @ https://launchpad.net/~firmware-testing-team/+archive/ubuntu/scratch"
else
	dput ppa:firmware-testing-team/ppa-fwts-unstable-crack */*es
	echo "Check build status @ https://launchpad.net/~firmware-testing-team/+archive/ubuntu/ppa-fwts-unstable-crack"
fi

# finalize
if [ $TEST_BUILD = true ] ; then
	echo "Please remove fwts-V${RELEASE_VERSION}.tar.gz on fwts.ubuntu.com"
	echo "Please remove sha256sum in SHA256SUMS on fwts.ubuntu.com"
else
	echo "When the build finishes, please do the following:"
	echo "  1. copy packages to stage PPA (Firmware Test Suite (Stable) & fwts-release-builds)"
	echo "  2. upload the new FWTS package to the Ubuntu universe archive"
	echo "  3. email to fwts-devel and fwts-announce lists"
	echo "  4. update milestone on https://launchpad.net/fwts"
	echo "  5. update version on https://wiki.ubuntu.com/FirmwareTestSuite"
	echo "  6. build new fwts-live"
	echo "  7. update social media accounts (fb and twitter)"

fi
