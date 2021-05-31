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

readonly UBUNTU=( bionic focal groovy hirsute impish )
TAB="$(printf '\t')"

create_dockerfile () {
cat <<- EOF >> Dockerfile
FROM ubuntu:${1}
RUN sed -i '4,20s/# deb-src/deb-src/' /etc/apt/sources.list && apt update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends vim git libbsd-dev
RUN DEBIAN_FRONTEND=noninteractive apt build-dep -y fwts && git clone git://kernel.ubuntu.com/hwe/fwts.git
RUN cd fwts && autoreconf -ivf && ./configure && make clean && make -j \`getconf _NPROCESSORS_ONLN\` && make check
EOF
}
create_makefile () {
cat <<- EOF >> Makefile
all: clean build

build:
${TAB}docker build -t fwts-${1} .
clean:
${TAB}-docker rmi fwts-${1}
${TAB}-docker rmi ubuntu:${1}
EOF
}

if ! which docker > /dev/null ; then
  echo "Installing docker..."
  sudo apt-get -y install docker.io
  sudo usermod -aG docker $USER
  sudo service docker.io restart
  exit
fi

[ -d docker ] || mkdir docker
cd docker
for i in "${UBUNTU[@]}"
do
  if [ ! -d ${i} ] ; then
    mkdir ${i}
    cd ${i}
    create_dockerfile ${i}
    create_makefile ${i}
    cd ..
  fi
  cd ${i}
  make && make clean
  cd ..
done

# if a build fails, the docker image will be available
docker images
