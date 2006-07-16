These are regression tests. If packages have not been extracted yet, they must
be extracted over those directories.

  - zlib-1.2.3 is just a basic test
  - squashfs-2.1-r2 tests kernel includes
  - openssl-0.9.6m tests several cases of static+dynamic library build
  - p7zip_4.20 tests c++ and dynamic linking to libstdc++.so

Those files are easy to backup :
  $ tar zcf tests.tgz tests/FLXPKG tests/README.txt tests/*/.flxpkg 

When last tested, those pkg --env said this :

FLXHOSTOS=linux
FLXHOSTARCH=i686
FLXHOST=i686-linux
FLXTARGOS=linux
FLXTARGARCH=i586
FLXTARG=i586-linux
FLX_ARCH_CURRENT=i586
FLX_ARCH_COMMON=i586
FLX_ARCH_SMALL=i386
FLXARCH=i586
FLXCROSS=i586-linux-
FLXTOOLDIR=/var/flx-toolchain/i586-linux/tool-i686-x-linux
FLXROOTDIR=/var/flx-toolchain/i586-linux/root
AR=i586-linux-ar
AS=i586-linux-as
CC=i586-linux-gcc
CXX=i586-linux-g++
LD=i586-linux-ld
NM=i586-linux-nm
OBJDUMP=i586-linux-objdump
RANLIB=i586-linux-ranlib
STRIP=i586-linux-strip
GCC_ARCH_CURRENT=-march=i586
GCC_ARCH_COMMON=-march=i586
GCC_ARCH_SMALL=-march=i386
GCC_CPU_CURRENT=-mcpu=i686
GCC_CPU_COMMON=-mcpu=i586
GCC_CPU_SMALL=-mcpu=i386
GCC_OPT_FASTEST=-O3 -fomit-frame-pointer
GCC_OPT_FAST=-O2 -momit-leaf-frame-pointer -mpreferred-stack-boundary=2 -malign-jumps=0
GCC_OPT_SMALL=-Os -momit-leaf-frame-pointer -mpreferred-stack-boundary=2 -malign-jumps=0 -malign-loops=0 -malign-functions=0
HOSTCC=gcc
HOSTCXX=g++
HOSTCC_OPT_FASTEST=-O3 -fomit-frame-pointer
HOSTCC_OPT_FAST=-O2 -momit-leaf-frame-pointer -mpreferred-stack-boundary=2 -fno-align-jumps
HOSTCC_OPT_SMALL=-Os -momit-leaf-frame-pointer -mpreferred-stack-boundary=2 -fno-align-functions -fno-align-loops -fno-align-jumps -fno-align-labels
FLXMAKE=make
FLXPMAKE=make -j 3

