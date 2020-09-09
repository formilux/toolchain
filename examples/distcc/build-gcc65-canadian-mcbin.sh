#!/bin/sh
# Note: the HOST_CFLAGS are those tested to provide the highest performance
# on the resulting compiler. However, it turns out that gcc's libiberty
# wrongly uses these flags on the build host and fails to build.
# TC_HOST_CFLAGS="-O3 -mcpu=cortex-a72.cortex-a53"
TMPDIR=/dev/shm PATH=/f/tc/gcc-linaro-7.5.0-2019.12-x86_64_armv8l-linux-gnueabihf/bin:$PATH PARALLEL=$(nproc) MAKE=/usr/bin/make UCLIBC_PREFERRED_VERSION=none CT_VERSION=1.23.0.528-61687 TC_TMP=/mnt/tmp/ctng TC_SRC=/f/cache/src TC_DST=/mnt/tmp/flx-tc/host-armv8 TC_HOST=armv8l-linux-gnueabihf ./toolchain tc-all newconf/config-x86_64-gcc65_glibc228-linux-gnu newconf/config-armv7nthf-gcc65_glibc228-linux-gnueabi newconf/config-aarch64-gcc65_glibc228-linux-gnu
