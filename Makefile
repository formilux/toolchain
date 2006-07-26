LD_LIBRARY_PATH=
export LD_LIBRARY_PATH

TOP           := $(PWD)
DOWNLOAD      := $(TOP)/download
PATCHES       := $(TOP)/patches
SOURCE        := $(TOP)/source

HOSTCC        := gcc

# WARNING! for GCC and binutils to detect cross-compilation,
# HOST and TARGET must be different
HOST          := i686-linux
TARGET        := i586-linux
BUILDDIR      := $(TOP)/$(TARGET)/build-$(HOST)
TOOLDIR       := $(TOP)/$(TARGET)/tool-$(HOST)
ROOTDIR       := $(TOP)/$(TARGET)/root
TOOL_PREFIX   := $(TOOLDIR)/usr
ROOT_PREFIX   := $(ROOTDIR)/usr
TARGET_PATH   := $(TOOLDIR)/usr/bin:$(PATH)

BINUTILS      := 2.15.94.0.2
BINUTILS_SDIR := $(SOURCE)/binutils-$(BINUTILS)
BINUTILS_BDIR := $(BUILDDIR)/binutils-$(BINUTILS)

GCC           := 20011006
GCC_SDIR      := $(SOURCE)/gcc-$(GCC)
GCC_BDIR      := $(BUILDDIR)/gcc-$(GCC)
GCC_LIBC_BDIR := $(BUILDDIR)/gcc-libc-$(GCC)

KHDR          := 2.4.29-hf2
KHDR_SDIR     := $(SOURCE)/linux-$(KHDR)

GLIBC         := 2.2.5
GLIBC_SDIR    := $(SOURCE)/glibc-$(GLIBC)
GLIBC_BDIR    := $(BUILDDIR)/glibc-$(GLIBC)
GLIBC_HDIR    := $(BUILDDIR)/glibc-headers-$(GLIBC)

MFLAGS        :=
MPFLAGS       := -j 2



all: gcc


binutils: $(BINUTILS_BDIR)/.installed

$(BINUTILS_BDIR)/.installed: $(BINUTILS_BDIR)/.compiled
	(cd $(BINUTILS_BDIR) && \
	 $(MAKE) $(MFLAGS) install INSTALL_PROGRAM="\$${INSTALL} -s" )
	touch $@

$(BINUTILS_BDIR)/.compiled: $(BINUTILS_BDIR)/.configured
	cd $(BINUTILS_BDIR) && $(MAKE) $(MPFLAGS)
	touch $@

$(BINUTILS_BDIR)/.configured: $(BINUTILS_SDIR)/.patched
	mkdir -p $(BINUTILS_BDIR)
	(cd $(BINUTILS_BDIR) && CC=$(HOSTCC) $(BINUTILS_SDIR)/configure \
           --host=$(HOST) --target=$(TARGET) --prefix=$(TOOL_PREFIX) \
	   --with-lib-path="$(TOOLDIR)/usr/i386-linux/lib:$(ROOTDIR)/lib:$(ROOTDIR)/usr/lib" \
	   --disable-shared --disable-locale --disable-nls \
	)
	touch $@

$(BINUTILS_SDIR)/.patched: $(BINUTILS_SDIR)/.extracted
	touch $@

$(BINUTILS_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/binutils-$(BINUTILS).tar.bz2
	touch $@


#### partial GCC needed to build glibc
gcc-libc: $(GCC_LIBC_BDIR)/.installed

$(GCC_LIBC_BDIR)/.installed: $(GCC_LIBC_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	(cd $(GCC_LIBC_BDIR) && \
	 PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install-gcc INSTALL_PROGRAM_ARGS="-s" )
	touch $@

$(GCC_LIBC_BDIR)/.compiled: $(GCC_LIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed
# make cpp0 prefix=/build/buildroot/i386-linux/root/usr

	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	cd $(GCC_LIBC_BDIR) && PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) all-gcc
	touch $@

# note: we will install this first-stage compiler in $PREFIX, but since it
# will be a cross-compiler, gcc will implicitly use $PREFIX/$TARGET for the
# includes, libraries and binaries, and we cannot do anything about that,
# so we must install the glibc headers accordingly.

$(GCC_LIBC_BDIR)/.configured: $(GCC_SDIR)/.patched $(GLIBC_SDIR)/.patched $(GLIBC_HDIR)/.installed $(BINUTILS_BDIR)/.installed

	# this is needed to find the binutils
	# ln -s $(TOOL_PREFIX) $(ROOT_PREFIX)/$(TARGET)
	# ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	mkdir -p $(TOOL_PREFIX)/target-root

	[ -e $(TOOL_PREFIX)/target-root/usr ] || \
	   ln -sf $(ROOTDIR)/usr $(TOOL_PREFIX)/target-root/
	[ -e $(TOOL_PREFIX)/target-root/lib ] || \
	   ln -sf $(ROOTDIR)/lib $(TOOL_PREFIX)/target-root/

	mkdir -p $(ROOT_PREFIX)/include
	rm -f $(ROOT_PREFIX)/sys-include ; ln -sf include $(ROOT_PREFIX)/sys-include
	mkdir -p $(GCC_LIBC_BDIR)
	(cd $(GCC_LIBC_BDIR) && CC=$(HOSTCC) \
	 PATH=$(TARGET_PATH) $(GCC_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) --disable-shared --disable-nls \
	   --disable-__cxa_atexit --disable-haifa \
	   --includedir=$(TOOL_PREFIX)/target-root/usr/include \
	   --enable-languages=c )

	   #--libdir=$(TOOL_PREFIX)/target-root/usr/lib \
	   #--with-gxx-include-dir=$(TOOL_PREFIX)/include/c++ \

	touch $@

$(GCC_SDIR)/.patched: $(GCC_SDIR)/.extracted
	# Patches from Erik Andersen to fix known bugs in gcc-2.95
	bzcat $(DOWNLOAD)/gcc2.95-mega.patch.bz2 | patch -p1 -d $(GCC_SDIR)

	# Patch to allow gcc-2.95 to build on gcc-3
	bzcat $(PATCHES)/gcc-2.95-gcc3-compfix.diff.bz2 | patch -p1 -d $(GCC_SDIR)

	# patches to allow gcc to find includes in $ROOT_PREFIX/include
	for p in patch-gcc295-{prefix-target-root,prefix-usage,displace-gcc-lib}; do \
	   patch -p1 -d $(GCC_SDIR) < $(PATCHES)/$$p ; \
	done

	touch $@

$(GCC_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/gcc-$(GCC).tar.bz2
	touch $@


#### kernel headers
# these headers have been build this way :
# cd /usr/src/linux-2.4.29-hf2
# make allmodconfig
# make dep
# cd ..
# tar c linux-2.4.29-hf2/include/{acpi,asm,asm-i386,linux,math-emu,net,pcmcia,scsi,video} | bzip2 -9 >kernel-headers-2.4.29-hf2.tar.bz2

kernel-headers: $(KHDR_SDIR)/.patched

$(KHDR_SDIR)/.patched: $(KHDR_SDIR)/.extracted
	touch $@

$(KHDR_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/kernel-headers-$(KHDR).tar.bz2
	touch $@


#### glibc
glibc: $(GLIBC_BDIR)/.installed

$(GLIBC_BDIR)/.installed: $(GLIBC_BDIR)/.compiled $(GLIBC_HDIR)/.installed $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.patched
	(cd $(GLIBC_BDIR) && \
	 $(MAKE) $(MFLAGS) install slibdir=$(ROOTDIR)/lib \
	    INSTALL_PROGRAM_ARGS="-s" && \
	 rm -rf $(ROOT_PREFIX)/include/{asm,linux} && \
	 cp -aH $(KHDR_SDIR)/include/{asm,linux} $(ROOT_PREFIX)/include/ )
	touch $@

$(GLIBC_BDIR)/.compiled: $(GCC_LIBC_BDIR)/.installed $(GLIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	cd $(GLIBC_BDIR) && PATH=$(TARGET_PATH) $(MAKE) $(MPFLAGS)
	touch $@

$(GLIBC_BDIR)/.configured: $(GCC_LIBC_BDIR)/.installed $(GLIBC_SDIR)/.patched $(KHDR_SDIR)/.patched $(BINUTILS_BDIR)/.installed
	mkdir -p $(GLIBC_BDIR)
	(cd $(GLIBC_BDIR) && \
	 PATH=$(TARGET_PATH) CC=$(TOOL_PREFIX)/bin/$(TARGET)-gcc \
	   $(GLIBC_SDIR)/configure \
	   --build=$(HOST) --host=$(TARGET) --target=$(TARGET) \
	   --prefix=$(ROOT_PREFIX) --libexecdir=$(ROOT_PREFIX)/bin \
	   --libdir=$(ROOT_PREFIX)/lib \
	   --with-headers=$(KHDR_SDIR)/include --disable-debug \
	   --disable-profile --enable-versioning --enable-omitfp \
	   --without-cvs --without-gd --without-gmp \
	   --with-gettext --with-elf --enable-add-ons \
	   --enable-kernel=2.4.0 )
	 touch $@


# glibc headers only
glibc-headers: $(GLIBC_HDIR)/.installed

$(GLIBC_HDIR)/.installed: $(GLIBC_HDIR)/.configured $(GLIBC_SDIR)/.patched $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.patched
	(cd $(GLIBC_HDIR) && \
	 PATH=$(TARGET_PATH) \
	   $(MAKE) $(MFLAGS) cross-compiling=yes \
	     install_root=$(ROOTDIR) prefix=/usr slibdir=/lib \
	     libdir=/usr/lib libexecdir=/usr/bin install-headers && \
	 cp $(GLIBC_SDIR)/include/features.h $(ROOT_PREFIX)/include/ && \
	 mkdir -p $(ROOT_PREFIX)/include/gnu && \
	 touch $(ROOT_PREFIX)/include/gnu/stubs.h && \
	 rm -rf $(ROOT_PREFIX)/include/{asm,linux} && \
	 cp -aH $(KHDR_SDIR)/include/{asm,linux} $(ROOT_PREFIX)/include/ )
	touch $@

$(GLIBC_HDIR)/.configured: $(GLIBC_SDIR)/.patched $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.patched
	mkdir -p $(GLIBC_HDIR)
	(cd $(GLIBC_HDIR) && \
	 PATH=$(TARGET_PATH) CC=$(HOSTCC) \
	 $(GLIBC_SDIR)/configure \
	   --build=$(HOST) --host=$(TARGET) --target=$(TARGET) \
	   --prefix=/usr --libexecdir=/usr/bin --libdir=/usr/lib \
	   --with-headers=$(KHDR_SDIR)/include --disable-debug \
	   --disable-profile --enable-versioning --enable-omitfp \
	   --without-cvs --without-gd --without-gmp \
	   --with-gettext --with-elf \
	   --disable-sanity-checks --enable-add-ons \
	   --enable-kernel=2.4.0 --enable-hacker-mode && \
	 if grep -q GLIBC_2.3 $(GLIBC_SDIR)/ChangeLog; then \
	   PATH=$(TARGET_PATH) $(MAKE) sysdeps/gnu/errlist.c ; \
	   mkdir -p stdio-common ; \
	   touch stdio-common/errlist-compat.c ; \
	 fi )
	touch $@

$(GLIBC_SDIR)/.patched: $(GLIBC_SDIR)/.extracted
	touch $@

$(GLIBC_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/glibc-$(GLIBC).tar.bz2
	tar -C $(GLIBC_SDIR) -jxf $(DOWNLOAD)/glibc-linuxthreads-$(GLIBC).tar.bz2
	touch $@

#### full GCC
gcc: $(GCC_BDIR)/.installed

$(GCC_BDIR)/.installed: $(GCC_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	(cd $(GCC_BDIR) && \
	 PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install INSTALL_PROGRAM_ARGS="-s" \
	    gcclibdir="$(TOOL_PREFIX)/lib/gcc-lib" \
	    GCC_FLAGS_TO_PASS='$$(BASE_FLAGS_TO_PASS) $$(EXTRA_GCC_FLAGS) \
	        gcclibdir=$(TOOL_PREFIX)/lib/gcc-lib \
	        libsubdir=$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)' )

	# we must reset the 'cross_compile' flag, otherwise the path to crt*.o gets stripped !
	sed '/^\*cross_compile/,/^$$/s/^1/0/' \
		< $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs \
		> $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs-
	mv $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs- $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs
	touch $@

$(GCC_BDIR)/.compiled: $(GLIBC_BDIR)/.installed $(GCC_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	cd $(GCC_BDIR) && PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) \
	   gcclibdir="$(TOOL_PREFIX)/lib/gcc-lib" \
	    GCC_FLAGS_TO_PASS='$$(BASE_FLAGS_TO_PASS) $$(EXTRA_GCC_FLAGS) \
	        gcclibdir=$(TOOL_PREFIX)/lib/gcc-lib \
	        libsubdir=$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)'

	# As usual, C++ is a pile of shit which does not know where to find its
	# includes. If C++ is needed, you have to start from the chunks. I'm giving up.

	# cd $(GCC_BDIR) && PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) all-gcc
	# cd $(GCC_BDIR) && PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) -C i386-linux/libio CINCLUDES="-I. -I\$$(srcdir) -I$(ROOT_PREFIX)/include"  CXXINCLUDES="-I. -I\$$(srcdir) -I$(ROOT_PREFIX)/include"
	touch $@

$(GCC_BDIR)/.configured: $(GLIBC_BDIR)/.installed $(GCC_SDIR)/.patched $(BINUTILS_BDIR)/.installed
	mkdir -p $(GCC_BDIR)

	[ -e $(TOOL_PREFIX)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/
	# (cd $(GCC_BDIR) && CC="$(HOSTCC) -I$(TOOL_PREFIX)/target-root/usr/include"


	(cd $(GCC_BDIR) && CC="$(HOSTCC)" \
	 PATH=$(TARGET_PATH) $(GCC_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) --disable-locale --disable-nls \
	   --enable-shared --disable-__cxa_atexit --with-gnu-ld \
	   --with-gxx-include-dir=$(TOOL_PREFIX)/target-root/usr/include/c++ \
	   --libdir=$(TOOL_PREFIX)/target-root/usr/lib \
	   --enable-languages=c --enable-threads )
	touch $@

	# WARNING! do not enable target-optspace, it corrupts CXX_FLAGS
	# in mt-frags which break c++ build.
	#   --enable-target-optspace 
	#   --libdir=$(TOOL_PREFIX)/target-root/usr/lib \
	#   --enable-languages=c,c++

