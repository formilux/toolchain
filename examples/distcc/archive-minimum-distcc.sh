#!/bin/sh
# to be run from $TC_DST, emits the strict minimum needed to run gcc/cc1/as
# under distccd (at least for gcc-6.5.0)
tar --no-recursion -cf - *-*-linux-gnu*/bin/*-*-linux-gnu*-gcc *-*-linux-gnu*/libexec/gcc/*-*-linux-gnu*/*.*.*/cc1 *-*-linux-gnu*/lib/gcc/*-*-linux-gnu*/*.*.* *-*-linux-gnu*/*-*-linux-gnu*/bin/as


# then place symlinks from /opt/bin to the target gcc binary and everything
# will work by itself:
#
# root@miqi-2:bin# ll /opt/bin/
# total 28
# drwxr-xr-x 2 root root 4096 May 25 14:01 ./
# drwxr-xr-x 5 root root 4096 Dec 11  2016 ../
# lrwxrwxrwx 1 root root   83 May 25 14:01 aarch64-gcc65_glibc228-linux-gnu-gcc -> ../flx-tc/aarch64-gcc65_glibc228-linux-gnu/bin/aarch64-gcc65_glibc228-linux-gnu-gcc*
# lrwxrwxrwx 1 root root   95 May 25 14:01 armv7nthf-gcc65_glibc228-linux-gnueabi-gcc -> ../flx-tc/armv7nthf-gcc65_glibc228-linux-gnueabi/bin/armv7nthf-gcc65_glibc228-linux-gnueabi-gcc*
# lrwxrwxrwx 1 root root   77 May 25 14:01 i586-gcc47_glibc218-linux-gnu-gcc -> ../flx-tc/i586-gcc47_glibc218-linux-gnu/bin/i586-gcc47_glibc218-linux-gnu-gcc*
# lrwxrwxrwx 1 root root   81 May 25 14:01 x86_64-gcc47_glibc218-linux-gnu-gcc -> ../flx-tc/x86_64-gcc47_glibc218-linux-gnu/bin/x86_64-gcc47_glibc218-linux-gnu-gcc*
# lrwxrwxrwx 1 root root   81 May 25 14:01 x86_64-gcc65_glibc228-linux-gnu-gcc -> ../flx-tc/x86_64-gcc65_glibc228-linux-gnu/bin/x86_64-gcc65_glibc228-linux-gnu-gcc*

