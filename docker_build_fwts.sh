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

readonly UBUNTU=( xenial bionic focal groovy hirsute )

if ! which docker > /dev/null ; then
  echo "Installing docker..."
  sudo apt-get -y install docker.io
  sudo usermod -aG docker $USER
  sudo service docker.io restart
  exit
fi

cd docker
for i in "${UBUNTU[@]}"
do
  cd $i
  make && make clean
  cd ..
done

# if a build fails, the docker image will be available
docker images
