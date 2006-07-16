LD_LIBRARY_PATH=
export LD_LIBRARY_PATH

# those are only used to build a package
# WARNING! do not supply a leading '/' to the directory
TOOLCHAIN     := 0.4.0
TOOLCHAIN_DIR := var/flx-toolchain

TOP           := $(PWD)
DOWNLOAD      := $(TOP)/download
PATCHES       := $(TOP)/patches
SOURCE        := $(TOP)/source

# WARNING! for GCC and binutils to detect cross-compilation,
# HOST and TARGET must be different. Inserting 'host' between
# the CPU and OS field is enough.
#
HOST          := i686-host-linux
HOSTCC        := gcc

TARGET_CPU    := i586
TARGET_ARCH   := i386
TARGET        := $(TARGET_CPU)-linux

GLIBC         := 2.2.5
BINUTILS      := 2.16.1
GCC           := 20011006
GCC_SUFFIX    := 2.95
KHDR          := 2.4.32-wt8
DIETLIBC      := 0.30
UCLIBC        := 0.9.28

# Additionnal GCC versions. Those which will be build are defined by the
# 'GCCVERSIONS' variable below.

GCC33         := 3.3.6
GCC34         := 3.4.6
GCC41         := 4.1.1

GCCVERSIONS   := gcc33 gcc34 gcc41

BUILDDIR      := $(TOP)/$(TARGET)/build-$(HOST)
TOOLDIR       := $(TOP)/$(TARGET)/tool-$(HOST)
ROOTDIR       := $(TOP)/$(TARGET)/root
TOOL_PREFIX   := $(TOOLDIR)/usr
ROOT_PREFIX   := $(ROOTDIR)/usr
TARGET_PATH   := $(TOOLDIR)/usr/bin:$(PATH)
CROSSPFX      := $(TARGET)-

BINUTILS_SDIR := $(SOURCE)/binutils-$(BINUTILS)
BINUTILS_BDIR := $(BUILDDIR)/binutils-$(BINUTILS)

GCC_SDIR      := $(SOURCE)/gcc-$(GCC)
GCC_BDIR      := $(BUILDDIR)/gcc-$(GCC)
GCC_LIBC_BDIR := $(BUILDDIR)/gcc-libc-$(GCC)

GCC33_SDIR    := $(SOURCE)/gcc-$(GCC33)
GCC33_BDIR    := $(BUILDDIR)/gcc-$(GCC33)
GCC33_SUFFIX  := 3.3

GCC34_SDIR    := $(SOURCE)/gcc-$(GCC34)
GCC34_BDIR    := $(BUILDDIR)/gcc-$(GCC34)
GCC34_SUFFIX  := 3.4

GCC41_SDIR    := $(SOURCE)/gcc-$(GCC41)
GCC41_BDIR    := $(BUILDDIR)/gcc-$(GCC41)
GCC41_SUFFIX  := 4.1

KHDR_SDIR     := $(SOURCE)/linux-$(KHDR)

GLIBC_SDIR    := $(SOURCE)/glibc-$(GLIBC)
GLIBC_BDIR    := $(BUILDDIR)/glibc-$(GLIBC)
GLIBC_HDIR    := $(BUILDDIR)/glibc-headers-$(GLIBC)

DIETLIBC_SDIR := $(SOURCE)/dietlibc-$(DIETLIBC)
DIETLIBC_BDIR := $(BUILDDIR)/dietlibc-$(DIETLIBC)

UCLIBC_SDIR   := $(SOURCE)/uClibc-$(UCLIBC)
UCLIBC_BDIR   := $(BUILDDIR)/uClibc-$(UCLIBC)

MFLAGS        :=
MPFLAGS       := -j 2


################# end of configuration ##############

# There are files which are not necessary to build anything, and if needed, they
# should be extracted from their respective compiled packages. They don't have
# their place in the toolchain, so we'll remove them.
all: gcc dietlibc uclibc $(TOP)/$(TARGET)/pool $(GCCVERSIONS)
	rm -rf $(TOOL_PREFIX)/usr/{man,info} $(TOOLDIR)/diet/man $(ROOT_PREFIX)/info
	rm -rf $(ROOT_PREFIX)/{bin,info,lib/gconv,sbin,share}

all-noclean: gcc dietlibc uclibc $(TOP)/$(TARGET)/pool $(GCCVERSIONS)

# can be called after all-noclean if needed
remove-unneeded:
	rm -rf $(TOOL_PREFIX)/usr/{man,info} $(TOOLDIR)/diet/man $(ROOT_PREFIX)/info
	rm -rf $(ROOT_PREFIX)/{bin,info,lib/gconv,sbin,share}

# remove everything that's not absolutely necessary
space: remove-unneeded
	rm -rf $(BUILDDIR) $(SOURCE)

# make a bootstrap archive
bootstrap-archive:
	ln -s . toolchain-$(TOOLCHAIN)
	tar cf - toolchain-$(TOOLCHAIN)/{CHANGELOG,HOWTO.txt,Makefile,patches} \
	         toolchain-$(TOOLCHAIN)/tests/{FLXPKG,README.txt,*/.flxpkg} \
	  | gzip -9 >flx-toolchain-$(TOOLCHAIN).tgz
	rm -f toolchain-$(TOOLCHAIN)

# build the archive containing the minimal binary tools.
tool-archive:
	# We'll make a fake directory. This is dirty but works.
	mkdir -p .tmp/$(TOOLCHAIN_DIR)
	rmdir .tmp/$(TOOLCHAIN_DIR)
	ln -s $(TOP) .tmp/$(TOOLCHAIN_DIR)
	tar -C .tmp -cf - $(TOOLCHAIN_DIR)/$(TARGET)/tool-$(HOST) \
	  | bzip2 -9 >flx-toolchain-$(TOOLCHAIN)-tool-$(HOST)_$(TARGET).tbz
	rm -rf .tmp

# build the archive containing the minimal binary root files.
root-archive: $(TOP)/$(TARGET)/pool
	# We'll make a fake directory. This is dirty but works.
	mkdir -p .tmp/$(TOOLCHAIN_DIR)
	rmdir .tmp/$(TOOLCHAIN_DIR)
	ln -s $(TOP) .tmp/$(TOOLCHAIN_DIR)
	tar -C .tmp -cf - $(TOOLCHAIN_DIR)/$(TARGET)/root $(TOOLCHAIN_DIR)/$(TARGET)/pool \
	  | bzip2 -9 >flx-toolchain-$(TOOLCHAIN)-root-$(TARGET).tbz
	rm -rf .tmp

$(TOP)/$(TARGET)/pool:
	mkdir -p $@/{groups,individual}
	cp -al $(TOP)/$(TARGET)/root $@/groups/std-group-0
	echo "base-toolchain-$(TOOLCHAIN)" > $@/groups/std-group-0.txt
	mv $(TOP)/$(TARGET)/root $@/base-toolchain-$(TOOLCHAIN)
	ln -s pool/groups/std-group-0 $(TOP)/$(TARGET)/root


################# start of build system ##############

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
	   --with-sysroot=$(TOOL_PREFIX)/target-root \
	   --with-lib-path="$(TOOLDIR)/usr/$(TARGET_ARCH)-linux/lib:$(ROOTDIR)/lib:$(ROOTDIR)/usr/lib" \
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

	# this one is mis-named
	mv $(TOOL_PREFIX)/bin/cpp $(TOOL_PREFIX)/bin/$(TARGET)-cpp || true; \
	mv $(TOOL_PREFIX)/bin/gcov $(TOOL_PREFIX)/bin/$(TARGET)-gcov || true; \

	# we must protect the gcc binaries from removal	by newer gcc versions
	for i in gcov gcc cpp unprotoize protoize; do \
	    mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC_SUFFIX) && \
	    ln -s $(TARGET)-$$i-$(GCC_SUFFIX) $(TOOL_PREFIX)/bin/$(TARGET)-$$i || true; \
	done

	touch $@

$(GCC_LIBC_BDIR)/.compiled: $(GCC_LIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed

	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/$(TARGET)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/$(TARGET)/
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
# cd /usr/src/linux-2.4.32-wt8
# make allmodconfig
# make dep
# make dep-files
# ln -s . linux-2.4.32-wt8
# tar --exclude='*.stamp' --exclude='*.ver' -c linux-2.4.32-wt8/include/{acpi,asm,asm-i386,linux,math-emu,net,pcmcia,scsi,video} | bzip2 -9 >kernel-headers-i386-2.4.32-wt8.tar.bz2

kernel-headers: $(KHDR_SDIR)/.patched

$(KHDR_SDIR)/.patched: $(KHDR_SDIR)/.extracted
	touch $@

$(KHDR_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/kernel-headers-$(TARGET_ARCH)-$(KHDR).tar.bz2 \
	  || tar -C $(SOURCE) -jxf $(DOWNLOAD)/kernel-headers-$(KHDR).tar.bz2
	touch $@


#### glibc

glibc: $(GLIBC_BDIR)/.installed

$(GLIBC_BDIR)/.installed: $(GLIBC_BDIR)/.compiled $(GLIBC_HDIR)/.installed $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.patched
	(cd $(GLIBC_BDIR) && \
	 $(MAKE) $(MFLAGS) install slibdir=$(ROOTDIR)/lib \
	    INSTALL_PROGRAM="\$${INSTALL} -s" \
	    INSTALL_SCRIPT="\$${INSTALL}" && \
	 rm -rf $(ROOT_PREFIX)/include/{asm,linux} && \
	 (cd $(KHDR_SDIR)/include/ && tar -cf - {asm,linux}/.) | (cd $(ROOT_PREFIX)/include/ && tar xf -) )
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


#### glibc headers only

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
	 (cd $(KHDR_SDIR)/include/ && tar -cf - {asm,linux}/.) | (cd $(ROOT_PREFIX)/include/ && tar xf -) )
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
	echo "###############  installing 'gcc-cross'  ##################"
	(cd $(GCC_BDIR) && \
	 PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install-gcc-cross INSTALL_PROGRAM_ARGS="-s" \
	    gcclibdir="$(TOOL_PREFIX)/lib/gcc-lib" \
	    GCC_FLAGS_TO_PASS='$$(BASE_FLAGS_TO_PASS) $$(EXTRA_GCC_FLAGS) \
	        gcclibdir=$(TOOL_PREFIX)/lib/gcc-lib \
	        libsubdir=$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version) \
	        gcc_gxx_include_dir=\$$(libsubdir)/include' )

	echo "###############  installing 'target'  ##################"
	# Note that we want libstdc++ in the root directory and not in the toolchain,
	# so we will use the 'tooldir' variable to displace the install directory.
	# We also want to move libiberty to gcc-lib because the one in the root is
	# reserved for binutils, so we point libdir to the gcc directory.

	(cd $(GCC_BDIR) && \
	 PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install-target INSTALL_PROGRAM_ARGS="-s" \
	    gcclibdir='$(TOOL_PREFIX)/lib/gcc-lib' \
	    libsubdir='$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)' \
	    libdir='$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)' \
	    tooldir='$(ROOT_PREFIX)' \
	    gcc_gxx_include_dir='\$$(libsubdir)/include' )

	# The libstdc++ links are now bad and must be fixed.
	(old=$$(basename $$(readlink $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/libstdc++.so)) ; \
	 ln -sf ../../../../target-root/usr/lib/$$old $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/libstdc++.so ; \
	 old=$$(basename $$(readlink $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/libstdc++.a)) ; \
	 ln -sf ../../../../target-root/usr/lib/$$old $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/libstdc++.a )

	echo "###############  end of install  ##################"
	# we must reset the 'cross_compile' flag, otherwise the path to crt*.o gets stripped !
	sed '/^\*cross_compile/,/^$$/s/^1/0/' \
		< $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs \
		> $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs-
	mv $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs- $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs

	# this one is mis-named
	mv $(TOOL_PREFIX)/bin/cpp $(TOOL_PREFIX)/bin/$(TARGET)-cpp || true; \
	mv $(TOOL_PREFIX)/bin/gcov $(TOOL_PREFIX)/bin/$(TARGET)-gcov || true; \

	# we must protect the gcc binaries from removal	by newer gcc versions
	for i in gcov g++ c++ gcc cpp c++filt unprotoize protoize; do \
	    mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC_SUFFIX) && \
	    ln -s $(TARGET)-$$i-$(GCC_SUFFIX) $(TOOL_PREFIX)/bin/$(TARGET)-$$i || true; \
	done

	touch $@

$(GCC_BDIR)/.compiled: $(GLIBC_BDIR)/.installed $(GCC_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	# this is because of bugs in the libstdc++ path configuration
	( rmdir $(GCC_BDIR)/$(TARGET) && ln -s . $(GCC_BDIR)/$(TARGET) || true ) 2>/dev/null 

	# first, we will only build gcc
	cd $(GCC_BDIR) && PATH=$(TARGET_PATH) $(MAKE) all-gcc $(MFLAGS) \
	   gcclibdir="$(TOOL_PREFIX)/lib/gcc-lib" \
	    GCC_FLAGS_TO_PASS='$$(BASE_FLAGS_TO_PASS) $$(EXTRA_GCC_FLAGS) \
	        gcclibdir=$(TOOL_PREFIX)/lib/gcc-lib \
	        libsubdir=$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)'

	# we must reset the 'cross_compile' flag, otherwise the path to crt*.o gets stripped and
	# components such as libstdc++ cannot be built !
	sed '/^\*cross_compile/,/^$$/s/^1/0/' < $(GCC_BDIR)/gcc/specs > $(GCC_BDIR)/gcc/specs-
	mv $(GCC_BDIR)/gcc/specs- $(GCC_BDIR)/gcc/specs

	# now we can make everything else (libio, libstdc++, ...)
	cd $(GCC_BDIR) && PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) \
	   gcclibdir="$(TOOL_PREFIX)/lib/gcc-lib" \
	    GCC_FLAGS_TO_PASS='$$(BASE_FLAGS_TO_PASS) $$(EXTRA_GCC_FLAGS) \
	        gcclibdir=$(TOOL_PREFIX)/lib/gcc-lib \
	        libsubdir=$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)'
	touch $@


$(GCC_BDIR)/.configured: $(GLIBC_BDIR)/.installed $(GCC_SDIR)/.patched $(BINUTILS_BDIR)/.installed
	mkdir -p $(GCC_BDIR)

	# Those directories are important : gcc looks for "limits.h" there to
	# know if it must chain to it or impose its own.
	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/$(TARGET)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/
	[ -e $(TOOL_PREFIX)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/

	# WARNING! do not enable target-optspace, it corrupts CXX_FLAGS
	# in mt-frags which break c++ build.
	(cd $(GCC_BDIR) && CC="$(HOSTCC)" \
	 PATH=$(TARGET_PATH) $(GCC_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) --disable-locale --disable-nls \
	   --enable-shared --disable-__cxa_atexit --with-gnu-ld \
	   --with-gxx-include-dir=$(TOOL_PREFIX)/target-root/usr/include/c++ \
	   --libdir=$(TOOL_PREFIX)/target-root/usr/lib \
	   --enable-languages=c,c++ --enable-threads )
	touch $@



#### GCC-3.3
#### it is provided here because there are packages which do not build anymore
#### on older GCC versions. GCC>=3.3 is easy to build for such an environment ;
#### we just have to use --with-sysroot to indicate where the root is.
#### We set a dependency on previous GCC to be sure to complete after it.

GCC33_ADDONS = AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
               NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
               RANLIB_FOR_TARGET=$(TARGET)-ranlib

gcc33: $(GCC33_BDIR)/.installed

$(GCC33_BDIR)/.installed: $(GCC33_BDIR)/.compiled $(BINUTILS_BDIR)/.installed $(GCC_BDIR)/.installed
	# we must protect older gcc binaries from removal
	for i in gcov gccbug g++ c++ gcc cpp; do \
	    mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-pre-$(GCC33_SUFFIX) || true; \
	done

	cd $(GCC33_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install INSTALL_PROGRAM_ARGS="-s" $(GCC33_ADDONS)

	# this one is redundant
	-rm -f $(TOOL_PREFIX)/bin/$(TARGET)-gcc-$(GCC33)

	# now we set the version on the binaries
	for i in gcov gccbug g++ c++ gcc cpp; do \
	    mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC33_SUFFIX) || true; \
	done

	# and we restore original binaries
	for i in gcov gccbug g++ c++ gcc cpp; do \
	    mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i-pre-$(GCC33_SUFFIX) $(TOOL_PREFIX)/bin/$(TARGET)-$$i || true; \
	done

	touch $@

$(GCC33_BDIR)/.compiled: $(GLIBC_BDIR)/.installed $(GCC33_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	cd $(GCC33_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) all $(MPFLAGS) $(GCC33_ADDONS)
	touch $@


$(GCC33_BDIR)/.configured: $(GLIBC_BDIR)/.installed $(GCC33_SDIR)/.patched $(BINUTILS_BDIR)/.installed
	mkdir -p $(GCC33_BDIR)
	(cd $(GCC33_BDIR) && CC="$(HOSTCC)" \
	 AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
         NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
	 RANLIB_FOR_TARGET=$(TARGET)-ranlib \
	 PATH=$(TARGET_PATH) $(GCC33_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) --disable-locale --disable-nls \
	   --enable-shared --with-gnu-ld --with-gnu-as \
	   --enable-version-specific-runtime-libs --enable-threads \
	   --with-sysroot=$(TOOL_PREFIX)/target-root \
	   --with-headers=$(ROOT_PREFIX)/include \
	   --with-libs=$(ROOT_PREFIX)/lib \
	   --with-gxx-include-dir=$(ROOT_PREFIX)/include/c++ \
	   --libdir=$(ROOT_PREFIX)/lib \
	   --enable-languages=c,c++ \
	   --program-suffix=-$(GCC33_SUFFIX) --program-prefix=$(TARGET)- \
	   --with-cpu=$(TARGET_CPU))

	touch $@


$(GCC33_SDIR)/.patched: $(GCC33_SDIR)/.extracted
	# patches to allow gcc to find includes in $ROOT_PREFIX/include
	for p in patch-gcc33-install-script; do \
	   patch -p1 -d $(GCC33_SDIR) < $(PATCHES)/$$p ; \
	done
	touch $@

$(GCC33_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/gcc-$(GCC33).tar.bz2
	touch $@



#### GCC-3.4
#### it is provided here because there are packages which do not build anymore
#### on older GCC versions. GCC>=3.3 is easy to build for such an environment ;
#### we just have to use --with-sysroot to indicate where the root is.

GCC34_ADDONS = AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
               NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
               RANLIB_FOR_TARGET=$(TARGET)-ranlib

gcc34: $(GCC34_BDIR)/.installed

$(GCC34_BDIR)/.installed: $(GCC34_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	cd $(GCC34_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install INSTALL_PROGRAM='$${INSTALL} -s' $(GCC34_ADDONS)

	# this one is redundant
	-rm -f $(TOOL_PREFIX)/bin/$(TARGET)-gcc-$(GCC34)

	touch $@

$(GCC34_BDIR)/.compiled: $(GLIBC_BDIR)/.installed $(GCC34_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	cd $(GCC34_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) all $(MPFLAGS) $(GCC34_ADDONS)
	touch $@


$(GCC34_BDIR)/.configured: $(GLIBC_BDIR)/.installed $(GCC34_SDIR)/.patched $(BINUTILS_BDIR)/.installed
	mkdir -p $(GCC34_BDIR)
	(cd $(GCC34_BDIR) && CC="$(HOSTCC)" \
	 AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
         NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
	 RANLIB_FOR_TARGET=$(TARGET)-ranlib \
	 PATH=$(TARGET_PATH) $(GCC34_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) --disable-locale --disable-nls \
	   --enable-shared --with-gnu-ld --with-gnu-as \
	   --enable-version-specific-runtime-libs --enable-threads \
	   --with-sysroot=$(TOOL_PREFIX)/target-root \
	   --with-headers=$(ROOT_PREFIX)/include \
	   --with-libs=$(ROOT_PREFIX)/lib \
	   --with-gxx-include-dir=$(ROOT_PREFIX)/include/c++ \
	   --libdir=$(ROOT_PREFIX)/lib \
	   --enable-languages=c,c++ \
	   --program-suffix=-$(GCC34_SUFFIX) --program-prefix=$(TARGET)- \
	   --with-cpu=$(TARGET_CPU))
	touch $@

$(GCC34_SDIR)/.patched: $(GCC34_SDIR)/.extracted
	touch $@

$(GCC34_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/gcc-$(GCC34).tar.bz2
	touch $@



#### GCC-4.1
#### it is provided here because there are packages which do not build anymore
#### on older GCC versions. GCC>=3.3 is easy to build for such an environment ;
#### we just have to use --with-sysroot to indicate where the root is.

GCC41_ADDONS = AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
               NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
               RANLIB_FOR_TARGET=$(TARGET)-ranlib

gcc41: $(GCC41_BDIR)/.installed

$(GCC41_BDIR)/.installed: $(GCC41_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	cd $(GCC41_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install INSTALL_PROGRAM_ARGS="-s" $(GCC41_ADDONS)

	# this one is redundant
	-rm -f $(TOOL_PREFIX)/bin/$(TARGET)-gcc-$(GCC41)

	touch $@

$(GCC41_BDIR)/.compiled: $(GLIBC_BDIR)/.installed $(GCC41_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	cd $(GCC41_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) all $(MPFLAGS) $(GCC41_ADDONS)
	touch $@


$(GCC41_BDIR)/.configured: $(GLIBC_BDIR)/.installed $(GCC41_SDIR)/.patched $(BINUTILS_BDIR)/.installed
	mkdir -p $(GCC41_BDIR)
	(cd $(GCC41_BDIR) && CC="$(HOSTCC)" \
	 AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
         NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
	 RANLIB_FOR_TARGET=$(TARGET)-ranlib \
	 PATH=$(TARGET_PATH) $(GCC41_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) --disable-locale --disable-nls \
	   --enable-shared --with-gnu-ld --with-gnu-as \
	   --enable-version-specific-runtime-libs --enable-threads \
	   --with-sysroot=$(TOOL_PREFIX)/target-root \
	   --with-headers=$(ROOT_PREFIX)/include \
	   --with-libs=$(ROOT_PREFIX)/lib \
	   --with-gxx-include-dir=$(ROOT_PREFIX)/include/c++ \
	   --libdir=$(ROOT_PREFIX)/lib \
	   --enable-languages=c,c++ \
	   --program-suffix=-$(GCC41_SUFFIX) --program-prefix=$(TARGET)- \
	   --with-cpu=$(TARGET_CPU))
	touch $@

$(GCC41_SDIR)/.patched: $(GCC41_SDIR)/.extracted
	touch $@

$(GCC41_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/gcc-$(GCC41).tar.bz2
	touch $@


#### dietlibc
#### Cannot be fully cross-compiled yet, the 'diet' program uses the
#### cross-compiler while it should not.

dietlibc: $(DIETLIBC_BDIR)/.installed

$(DIETLIBC_BDIR)/.installed: $(DIETLIBC_BDIR)/.compiled
	cd $(DIETLIBC_BDIR) && \
	   $(MAKE) $(MFLAGS) install ARCH=$(TARGET_ARCH) CROSS=$(CROSSPFX) prefix=$(TOOLDIR)/diet
	touch $@

$(DIETLIBC_BDIR)/.compiled: $(GCC_BDIR)/.installed $(DIETLIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.patched
	cd $(DIETLIBC_BDIR) && PATH=$(TARGET_PATH) \
	   $(MAKE) $(MPFLAGS) ARCH=$(TARGET_ARCH) CROSS=$(CROSSPFX) prefix=$(TOOLDIR)/diet
	touch $@

$(DIETLIBC_BDIR)/.configured: $(DIETLIBC_SDIR)/.patched
	-rm -f $(DIETLIBC_BDIR) >/dev/null 2>&1
	mkdir -p $(BUILDDIR)
	tar -C $(SOURCE) -cf - dietlibc-$(DIETLIBC) | tar -C $(BUILDDIR) -xUf -
	touch $@

$(DIETLIBC_SDIR)/.patched: $(DIETLIBC_SDIR)/.extracted
	patch -d $(DIETLIBC_SDIR) -p1 < $(PATCHES)/patch-dietlibc-0.28-cross-gcc
	touch $@

$(DIETLIBC_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/dietlibc-$(DIETLIBC).tar.bz2
	touch $@

#### uclibc
#### it is built with default gcc. The result is good enough.

uclibc: $(UCLIBC_BDIR)/.installed

$(UCLIBC_BDIR)/.installed: $(UCLIBC_BDIR)/.compiled
	cd $(UCLIBC_BDIR) && \
	   $(MAKE) $(MFLAGS) install ARCH=$(TARGET_ARCH) CROSS=$(CROSSPFX)
	sed -e 's@%%TOOLDIR%%@$(TOOLDIR)@g' $(PATCHES)/uclibc.wrap >$(TOOLDIR)/usr/bin/uclibc
	chmod 755 $(TOOLDIR)/usr/bin/uclibc
	touch $@

$(UCLIBC_BDIR)/.compiled: $(GCC_BDIR)/.installed $(UCLIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.patched
	cd $(UCLIBC_BDIR) && PATH=$(TARGET_PATH) $(MAKE) clean

	cd $(UCLIBC_BDIR) && PATH=$(TARGET_PATH) \
	   $(MAKE) $(MPFLAGS) ARCH=$(TARGET_ARCH) CROSS=$(CROSSPFX)
	touch $@

$(UCLIBC_BDIR)/.configured: $(UCLIBC_SDIR)/.patched
	-rm -rf $(UCLIBC_BDIR) >/dev/null 2>&1
	mkdir -p $(BUILDDIR)
	tar -C $(SOURCE) -cf - uClibc-$(UCLIBC) | tar -C $(BUILDDIR) -xUf -
	echo 'KERNEL_SOURCE="$(KHDR_SDIR)"' >> $(BUILDDIR)/uClibc-$(UCLIBC)/.config
	echo 'RUNTIME_PREFIX="$(TOOLDIR)/uclibc/"' >> $(BUILDDIR)/uClibc-$(UCLIBC)/.config
	echo 'DEVEL_PREFIX="$(TOOLDIR)/uclibc/usr/"' >> $(BUILDDIR)/uClibc-$(UCLIBC)/.config
	cd $(BUILDDIR)/uClibc-$(UCLIBC) && $(MAKE) oldconfig
	touch $@

$(UCLIBC_SDIR)/.patched: $(UCLIBC_SDIR)/.extracted
	cp $(PATCHES)/uclibc-$(UCLIBC).config $(UCLIBC_SDIR)/.config
	touch $@

$(UCLIBC_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/uClibc-$(UCLIBC).tar.bz2
	touch $@

