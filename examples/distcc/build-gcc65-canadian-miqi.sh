#!/bin/sh
# Note: the HOST_CFLAGS are those tested to provide the highest performance
# on the resulting compiler, probably because the A12/A17's pipeline is a bit
# different from others. Also, it turns out that gcc's libiberty wrongly uses
# these flags on the build host and fails to build.
# TC_HOST_CFLAGS="-mthumb -mcpu=cortex-a9 -mtune=cortex-a7 -O3"
TMPDIR=/dev/shm PATH=/f/tc/armv7nthf-gcc47l_glibc218-linux-gnueabi/bin:$PATH PARALLEL=$(nproc) MAKE=/usr/bin/make UCLIBC_PREFERRED_VERSION=none CT_VERSION=1.23.0.528-61687 TC_TMP=/mnt/tmp/ctng TC_SRC=/f/cache/src TC_DST=/mnt/tmp/flx-tc/host-armv7 TC_HOST=armv7nthf-gcc47l_glibc218-linux-gnueabi ./toolchain tc-all newconf/config-x86_64-gcc65_glibc228-linux-gnu newconf/config-armv7nthf-gcc65_glibc228-linux-gnueabi newconf/config-aarch64-gcc65_glibc228-linux-gnu
