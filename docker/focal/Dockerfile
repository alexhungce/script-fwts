FROM ubuntu:focal
RUN sed -i '4,20s/# deb-src/deb-src/' /etc/apt/sources.list && apt update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends vim git libbsd-dev
RUN DEBIAN_FRONTEND=noninteractive apt build-dep -y fwts && git clone git://kernel.ubuntu.com/hwe/fwts.git
RUN cd fwts && autoreconf -ivf && ./configure && make clean && make -j `getconf _NPROCESSORS_ONLN` && make check
