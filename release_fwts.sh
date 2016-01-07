#!/bin/bash
# Copyright (C) 2010-2016 Canonical
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

EDITOR=gedit

if [ $# -eq 0 ] ; then
	echo "Please provide release version, ex. 16.01.00."
	exit 1
fi

if ! which dch > /dev/null ; then
	echo "please run \"apt-get install devscripts\""
	exit 1
fi

RELEASE_VERSION=${1}
echo "FWTS V${RELEASE_VERSION} is to be released."
echo "Please [ENTER] to continue or Ctrl+C to abort"
read 

# == Prepare the source code ==
# download fwts source code
if [ -e fwts ] ; then
	echo "fwts directory exists! aborting..."
	exit 1
fi

git clone git://kernel.ubuntu.com/hwe/fwts.git
cd fwts/

cat << EOF >> .git/config
[remote "upstream"]
         fetch = +refs/heads/*:refs/remotes/upstream/*
         url = ssh+git://kernel.ubuntu.com/srv/kernel.ubuntu.com/git/hwe/fwts.git
EOF

# generate changelog based on the previous git tag..HEAD
git shortlog $(git describe --abbrev=0 --tags)..HEAD | sed "s/^     /  */g" #> ../fwts_${RELEASE_VERSION}_release_note

# add the changelog to the changelog file
echo "ensure the format is correct, . names, max 80 characters per line etc."
echo "update the version, e.g: \"fwts (15.12.00-0ubuntu0) UNRELEASED; urgency=low\" to "
echo "\"fwts (16.01.00-0ubuntu0) xenial; urgency=low\""

# TODO may need to pop a window for above messages
echo "press [ENTER] to continue"
read

$EDITOR ../fwts_${RELEASE_VERSION}_release_note &
dch -i
# wait for copying to dch -i
echo "type \"done\" to continue..."a
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

# == Build and publish ==
# commit the changelog file and the tag
git push upstream master
git push upstream master --tags

# create a temporary directory to generate the final tarball
mkdir fwts-tarball
cd fwts-tarball/
cp ../auto-packager/mk*sh .
./mktar.sh V${RELEASE_VERSION}

# copy the final fwts tarball to fwts.ubuntu.com
cd V${RELEASE_VERSION}/
scp fwts-V${RELEASE_VERSION}.tar.gz fwts.ubuntu.com:/srv/fwts.ubuntu.com/www/release/

# update SHA256 on fwts.ubuntu.com
echo "Run the following commands on fwts.ubuntu.com:"
echo "\tssh fwts.ubuntu.com"
echo "\tcd /srv/fwts.ubuntu.com/www/release/"
echo "\tsha256sum fwts-V${RELEASE_VERSION}.tar.gz >> SHA256SUMS"
echo "\texit"
echo ""

echo "type \"done\" to continue..."a
line=""
while true ; do
	read line
	if [ "$line" = "done" ] ; then
		break;
	fi
done

# generate the source packages for all supported Ubuntu releases
cd ..
./mkpackage.sh V${RELEASE_VERSION}

# upload the packages to the unstable-crack PPA to build
cd V${RELEASE_VERSION}
dput ppa:firmware-testing-team/ppa-fwts-unstable-crack */*es
echo "Check build status @ \
      https://launchpad.net/~firmware-testing-team/+archive/ubuntu/ppa-fwts-unstable-crack"

# finalize
echo "when the build finishes, please do the following:"
echo "\t1. copy packages to stage PPA (Firmware Test Suite (Stable))"
echo "\t2. upload the new FWTS package to the Ubuntu universe archive"
echo "\t3. email to fwts-devel and fwts-announce lists"
echo "\t4. update milestone on https://launchpad.net/fwts"
echo "\t5. build new fwts-live"



