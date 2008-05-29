LD_LIBRARY_PATH=
export LD_LIBRARY_PATH

# version is used only for packaging
TOOLCHAIN     := 0.6.0

# WARNING! for GCC and binutils to detect cross-compilation,
# HOST and TARGET must be different. Inserting 'host' between
# the CPU and OS field is enough.

HOST          := i686-host-linux
HOSTCC        := gcc

TARGET_CPU    := i586
TARGET_ARCH   := i386
TARGET        := $(TARGET_CPU)-flx-linux

# It is generally not needed to change this
TOP           := $(PWD)
PATCHES       := $(TOP)/patches
DOWNLOAD      := $(TOP)/download
SOURCE        := $(TOP)/source
BUILD         := $(TOP)/build

# Result will be installed in $(INSTALLDIR)/$(TARGET). This is the definitive
# installation directory. It must be accessible during.
INSTALLDIR    := $(TOP)

GCCVERSIONS   := gcc29 gcc33 gcc34 gcc41
GCCDEFAULT    := $(word 1,$(GCCVERSIONS))
GCCLIBC       := gcc29

GLIBC         := 2.2.5
BINUTILS      := 2.16.1
KHDR          := 2.4.32-wt8
DIETLIBC      := 0.31
UCLIBC        := 0.9.29

# Additionnal GCC versions. Those which will be build are defined by the
# 'GCCVERSIONS' variable below. The version indicated here is the suffix
# of the tar.gz file to extract. Note that GCC29 will always be at least
# partially built for libc.

GCC29         := 20011006
GCC33         := 3.3.6
GCC34         := 3.4.6
GCC41         := 4.1.2

# Everything under TARGETDIR must remain together
TARGETDIR     := $(INSTALLDIR)/$(TARGET)
TOOLDIR       := $(TARGETDIR)/tool-$(HOST)
ROOTDIR       := $(TARGETDIR)/root
POOLDIR       := $(TARGETDIR)/pool
TOOL_PREFIX   := $(TOOLDIR)/usr
ROOT_PREFIX   := $(ROOTDIR)/usr
SYS_ROOT      := $(TOOL_PREFIX)/target-root
TARGET_PATH   := $(TOOL_PREFIX)/bin:$(PATH)
CROSSPFX      := $(TARGET)-

# no need to change this, it will be easier to clean it up
BUILDDIR      := $(BUILD)/$(TARGET)/$(HOST)

BINUTILS_SDIR := $(SOURCE)/binutils-$(BINUTILS)
BINUTILS_BDIR := $(BUILDDIR)/binutils-$(BINUTILS)

# The gcc used for building glibc. The resulting executable will eventually
# be overwritten, so we can use the same suffix as the original one.
GCCLC29_BDIR  := $(BUILDDIR)/gcc-libc-$(GCC29)
GCCLC33_BDIR  := $(BUILDDIR)/gcc-libc-$(GCC33)
GCCLC34_BDIR  := $(BUILDDIR)/gcc-libc-$(GCC34)
GCCLC41_BDIR  := $(BUILDDIR)/gcc-libc-$(GCC41)

GCC29_SUFFIX  := 2.95
GCC29_SDIR    := $(SOURCE)/gcc-$(GCC29)
GCC29_BDIR    := $(BUILDDIR)/gcc-$(GCC29)

GCC33_SUFFIX  := 3.3
GCC33_SDIR    := $(SOURCE)/gcc-$(GCC33)
GCC33_BDIR    := $(BUILDDIR)/gcc-$(GCC33)
GCC33_ADDONS  := AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
                 NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
                 RANLIB_FOR_TARGET=$(TARGET)-ranlib

GCC34_SUFFIX  := 3.4
GCC34_SDIR    := $(SOURCE)/gcc-$(GCC34)
GCC34_BDIR    := $(BUILDDIR)/gcc-$(GCC34)
GCC34_ADDONS  := AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
                 NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
                 RANLIB_FOR_TARGET=$(TARGET)-ranlib

GCC41_SUFFIX  := 4.1
GCC41_SDIR    := $(SOURCE)/gcc-$(GCC41)
GCC41_BDIR    := $(BUILDDIR)/gcc-$(GCC41)
GCC41_ADDONS  := AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
                 NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
                 RANLIB_FOR_TARGET=$(TARGET)-ranlib

ifeq ($(GCCLIBC), gcc33)
GCCLC_BDIR    := $(BUILDDIR)/gcc-libc-$(GCC33)
GCCLC_SUFFIX  := $(GCC33_SUFFIX)
else
ifeq ($(GCCLIBC), gcc34)
GCCLC_BDIR    := $(BUILDDIR)/gcc-libc-$(GCC34)
GCCLC_SUFFIX  := $(GCC34_SUFFIX)
else
ifeq ($(GCCLIBC), gcc41)
GCCLC_BDIR    := $(BUILDDIR)/gcc-libc-$(GCC41)
GCCLC_SUFFIX  := $(GCC41_SUFFIX)
else
GCCLC_BDIR    := $(BUILDDIR)/gcc-libc-$(GCC29)
GCCLC_SUFFIX  := $(GCC29_SUFFIX)
endif  # gcc41
endif  # gcc34
endif  # gcc33

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

help:
	@echo
	@echo "This Makefile supports the following targets :"
	@echo "   - all: dietlibc uclibc glibc $(GCCVERSIONS) default_gcc[$(GCCDEFAULT)]"
	@echo "   - binutils gcc-libc $(GCCVERSIONS)"
	@echo "   - default_gcc29 default_gcc33 default_gcc34 default_gcc41"
	@echo "   - glibc dietlibc uclibc"
	@echo "   - kernel-headers glibc-headers"
	@echo "   - install"
	@echo "   - remove-unneeded space"
	@echo "   - bootstrap-archive git-bootstrap-archive"
	@echo "   - tool-archive root-archive"
	@echo
	@echo "Notes:"
	@echo "   - GCC versions may be changed with GCCVERSIONS=\"gccXX ...\""
	@echo "   - default GCC version is the first of the list (or GCCDEFAULT)"
	@echo "   - parallel build may be changed with MPFLAGS=\"-jXX\""
	@echo "   - using TARGET=$(TARGET) HOST=$(HOST) MPFLAGS=\"$(MPFLAGS)\""
	@echo "   - installing under INSTALLDIR=$(INSTALLDIR)"
	@echo

# There are files which are not necessary to build anything, and if needed, they
# should be extracted from their respective compiled packages. They don't have
# their place in the toolchain, so we'll remove them.
all: dietlibc uclibc glibc $(GCCVERSIONS) default_$(GCCDEFAULT)
	rm -rf $(TOOL_PREFIX)/{man,info} $(TOOLDIR)/diet/man
	rm -rf $(ROOT_PREFIX)/{bin,info,lib/gconv,sbin,share}

all-noclean: dietlibc uclibc glibc $(POOLDIR) $(GCCVERSIONS)

# finishes the installation.
# "make space" may also be issued to regain all wasted space
install: $(POOLDIR) remove-unneeded

# can be called after all-noclean if needed
remove-unneeded:
	rm -rf $(TOOL_PREFIX)/{man,info} $(TOOLDIR)/diet/man
	rm -rf $(ROOT_PREFIX)/{bin,info,lib/gconv,sbin,share}

# remove everything that's not absolutely necessary
space: remove-unneeded
	rm -rf $(BUILD)
	rm -rf $(SOURCE)

# make a bootstrap archive
bootstrap-archive:
	ln -s . toolchain-$(TOOLCHAIN)
	tar cf - toolchain-$(TOOLCHAIN)/{CHANGELOG,HOWTO.txt,Makefile,patches,tools} \
	         toolchain-$(TOOLCHAIN)/tests/{FLXPKG,README.txt,*/.flxpkg} \
	  | gzip -9 >flx-toolchain-$(TOOLCHAIN).tgz
	rm -f toolchain-$(TOOLCHAIN)

# easier way to make a bootstrap archive based on git
git-bootstrap-archive:
	git tar-tree HEAD toolchain-$(TOOLCHAIN) | gzip -c9 >flx-toolchain-$(TOOLCHAIN).tgz

# build the archive containing the minimal binary tools.
tool-archive: remove-unneeded
	tar -cf - $(TARGETDIR)/tool-$(HOST) \
	  | bzip2 -9 >flx-toolchain-$(TOOLCHAIN)-tool-$(HOST)_$(TARGET).tbz

# build the archive containing the minimal binary root files.
root-archive: remove-unneeded $(POOLDIR)
	tar -cf - $(TARGETDIR)/root $(TARGETDIR)/pool \
	  | bzip2 -9 >flx-toolchain-$(TOOLCHAIN)-root-$(TARGET).tbz

# moves root directory to turn it into a link to a group of profiles
$(POOLDIR):
	mkdir -p $@/{groups,individual}
	cp -al $(ROOTDIR) $@/groups/std-group-0
	echo "base-toolchain-$(TOOLCHAIN)" > $@/groups/std-group-0.txt
	mv $(ROOTDIR) $@/base-toolchain-$(TOOLCHAIN)
	ln -s std-group-0 $@/groups/CURRENT
	ln -s pool/groups/CURRENT $(ROOTDIR)
	cp $(TOP)/tools/list-to-tgz.sh $@/groups/
	cp $(TOP)/tools/list-to-pkgdir.sh $@/groups/

################# start of build system ##############

binutils: $(BINUTILS_BDIR)/.installed

# Note: we link gnm to nm and gstrip to strip because GCC searches them
# first in all of the system directories !
$(BINUTILS_BDIR)/.installed: $(BINUTILS_BDIR)/.compiled
	(cd $(BINUTILS_BDIR) && \
	 $(MAKE) $(MFLAGS) install INSTALL_PROGRAM="\$${INSTALL} -s" )
	 ln -sf nm $(TOOL_PREFIX)/$(TARGET)/bin/gnm
	 ln -sf strip $(TOOL_PREFIX)/$(TARGET)/bin/gstrip
	touch $@

$(BINUTILS_BDIR)/.compiled: $(BINUTILS_BDIR)/.configured
	cd $(BINUTILS_BDIR) && $(MAKE) $(MPFLAGS)
	touch $@

$(BINUTILS_BDIR)/.configured: $(BINUTILS_SDIR)/.patched
	mkdir -p $(BINUTILS_BDIR)
	(cd $(BINUTILS_BDIR) && CC=$(HOSTCC) $(BINUTILS_SDIR)/configure \
           --host=$(HOST) --target=$(TARGET) --prefix=$(TOOL_PREFIX) \
	   --with-sysroot=$(SYS_ROOT) \
	   --with-lib-path="$(TOOL_PREFIX)/$(TARGET)-linux/lib:$(ROOTDIR)/lib:$(ROOT_PREFIX)/lib" \
	   --disable-shared --disable-locale --disable-nls \
	)
	touch $@

$(BINUTILS_SDIR)/.patched: $(BINUTILS_SDIR)/.extracted
	touch $@

$(BINUTILS_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/binutils-$(BINUTILS).tar.bz2
	touch $@


#### partial GCC needed to build glibc. The correct version to use is
#### determined by the GCCLIBC variable, which means that GCCLC_BDIR will
#### point to one of the GCCLC*_BDIR directories.

gcc-libc: $(GCCLC_BDIR)/.installed

# GCC-2.95 for GLIBC

$(GCCLC29_BDIR)/.installed: $(GCCLC29_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	@# we must first protect possibly existing gcc binaries from removal
	@echo "Saving previous gcc binaries into .gcclc29/"
	mkdir -p $(TOOL_PREFIX)/bin/.gcclc29
	-mv $(TOOL_PREFIX)/bin/$(TARGET)-{gcov,gcc,cpp,unprotoize,protoize} \
	    $(TOOL_PREFIX)/bin/.gcclc29/ >/dev/null 2>&1

	(cd $(GCCLC29_BDIR) && \
	 PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install-gcc INSTALL_PROGRAM_ARGS="-s" )

	@# this one is mis-named
	mv $(TOOL_PREFIX)/bin/cpp $(TOOL_PREFIX)/bin/$(TARGET)-cpp || true; \
	mv $(TOOL_PREFIX)/bin/gcov $(TOOL_PREFIX)/bin/$(TARGET)-gcov || true; \

	@# we must protect the gcc binaries from removal by newer gcc versions
	for i in gcov gcc cpp unprotoize protoize; do \
	    mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC29_SUFFIX) || true; \
	done

	@# we can now restore previous gcc binaries
	-mv $(TOOL_PREFIX)/bin/.gcclc29/$(TARGET)-{gcov,gcc,cpp,unprotoize,protoize} \
	    $(TOOL_PREFIX)/bin/ >/dev/null 2>&1
	rmdir $(TOOL_PREFIX)/bin/.gcclc29 >/dev/null 2>&1
	touch $@

$(GCCLC29_BDIR)/.compiled: $(GCCLC29_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/$(TARGET)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/$(TARGET)/
	cd $(GCCLC29_BDIR) && PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) all-gcc
	touch $@

# note: we will install this first-stage compiler in $PREFIX, but since it
# will be a cross-compiler, gcc will implicitly use $PREFIX/$TARGET for the
# includes, libraries and binaries, and we cannot do anything about that,
# so we must install the glibc headers accordingly.
#
# Note: try to build this in a different directory with different options, such
# as --enable-__cxa_atexit, --disable-threads, --with-newlib, --disable-multilib

$(GCCLC29_BDIR)/.configured: $(GCC29_SDIR)/.patched $(GLIBC_SDIR)/.patched $(GLIBC_HDIR)/.installed $(BINUTILS_BDIR)/.installed
	@# this is needed to find the binutils
	@# ln -s $(TOOL_PREFIX) $(ROOT_PREFIX)/$(TARGET)
	@# ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	mkdir -p $(SYS_ROOT)

	[ -e $(SYS_ROOT)/usr ] || \
	   ln -sf $(ROOT_PREFIX) $(SYS_ROOT)/
	[ -e $(SYS_ROOT)/lib ] || \
	   ln -sf $(ROOTDIR)/lib $(SYS_ROOT)/

	mkdir -p $(ROOT_PREFIX)/include
	rm -f $(ROOT_PREFIX)/sys-include ; ln -sf include $(ROOT_PREFIX)/sys-include
	mkdir -p $(GCCLC29_BDIR)
	(cd $(GCCLC29_BDIR) && PATH=$(TARGET_PATH) \
	 CC=$(HOSTCC) CC_FOR_BUILD=$(HOSTCC) \
	 AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
	 NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
         RANLIB_FOR_TARGET=$(TARGET)-ranlib \
	 $(GCC29_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) --disable-shared --disable-nls \
	   --disable-__cxa_atexit --disable-haifa \
	   --includedir=$(SYS_ROOT)/usr/include \
	   --enable-languages=c )
	touch $@


# GCC-3.3 for GLIBC

$(GCCLC33_BDIR)/.installed: $(GCCLC33_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	@# we must first protect possibly existing gcc binaries from removal
	@echo "Saving previous gcc binaries into .gcclc33/"
	mkdir -p $(TOOL_PREFIX)/bin/.gcclc33
	-mv $(TOOL_PREFIX)/bin/$(TARGET)-{gcov,gccbug,gcc,cpp} \
	    $(TOOL_PREFIX)/bin/.gcclc33/ >/dev/null 2>&1

	(cd $(GCCLC33_BDIR) && \
	 PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install-gcc INSTALL_PROGRAM_ARGS="-s" )

	@# this one is mis-named
	mv $(TOOL_PREFIX)/bin/cpp $(TOOL_PREFIX)/bin/$(TARGET)-cpp || true; \
	mv $(TOOL_PREFIX)/bin/gcov $(TOOL_PREFIX)/bin/$(TARGET)-gcov || true; \

	@# we must protect the gcc binaries from removal by newer gcc versions
	for i in gcov gccbug gcc cpp; do \
	    mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC33_SUFFIX) || true; \
	done

	@# we can now restore previous gcc binaries
	-mv $(TOOL_PREFIX)/bin/.gcclc33/$(TARGET)-{gcov,gccbug,gcc,cpp} \
	    $(TOOL_PREFIX)/bin/ >/dev/null 2>&1
	rmdir $(TOOL_PREFIX)/bin/.gcclc33 >/dev/null 2>&1
	touch $@

$(GCCLC33_BDIR)/.compiled: $(GCCLC33_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	mkdir -p $(TOOL_PREFIX)/$(TARGET)
	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/$(TARGET)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/$(TARGET)/
	cd $(GCCLC33_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) all $(MPFLAGS) $(GCC33_ADDONS)
	touch $@

$(GCCLC33_BDIR)/.configured: $(GCC33_SDIR)/.patched $(GLIBC_SDIR)/.patched $(GLIBC_HDIR)/.installed $(BINUTILS_BDIR)/.installed
	@# this is needed to find the binutils
	@# ln -s $(TOOL_PREFIX) $(ROOT_PREFIX)/$(TARGET)
	@# ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	mkdir -p $(SYS_ROOT)

	[ -e $(SYS_ROOT)/usr ] || \
	   ln -sf $(ROOT_PREFIX) $(SYS_ROOT)/
	[ -e $(SYS_ROOT)/lib ] || \
	   ln -sf $(ROOTDIR)/lib $(SYS_ROOT)/

	mkdir -p $(ROOT_PREFIX)/include
	rm -f $(ROOT_PREFIX)/sys-include ; ln -sf include $(ROOT_PREFIX)/sys-include
	mkdir -p $(GCCLC33_BDIR)
	(cd $(GCCLC33_BDIR) && CC="$(HOSTCC)" CC_FOR_BUILD=$(HOSTCC) \
	 AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
         NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
	 RANLIB_FOR_TARGET=$(TARGET)-ranlib \
	 PATH=$(TARGET_PATH) $(GCC33_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) \
	   --libdir=$(TOOL_PREFIX)/lib --libexecdir=$(TOOL_PREFIX)/lib \
	   --disable-locale --disable-nls --disable-shared \
	   --with-gnu-ld --with-gnu-as \
	   --with-as=$(TOOL_PREFIX)/$(TARGET)/bin/as \
	   --with-ld=$(TOOL_PREFIX)/$(TARGET)/bin/ld \
	   --enable-version-specific-runtime-libs \
	   --disable-multilib --with-newlib \
	   --enable-symvers=gnu --enable-c99 --enable-long-long \
	   --with-sysroot=$(SYS_ROOT) \
	   --with-local-prefix=$(SYS_ROOT) \
	   --enable-languages=c \
	   --program-suffix=-$(GCC33_SUFFIX) --program-prefix=$(TARGET)- \
	   --with-cpu=$(TARGET_CPU))
	touch $@


$(GCCLC34_BDIR)/.installed: $(GCCLC34_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	@# we must first protect possibly existing gcc binaries from removal
	@echo "Saving previous gcc binaries into .gcclc34/"
	mkdir -p $(TOOL_PREFIX)/bin/.gcclc34
	-mv $(TOOL_PREFIX)/bin/$(TARGET)-{gcov,gccbug,gcc,cpp} \
	    $(TOOL_PREFIX)/bin/.gcclc34/ >/dev/null 2>&1

	(cd $(GCCLC34_BDIR) && \
	 PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install-gcc INSTALL_PROGRAM_ARGS="-s" )

	@# this one is mis-named
	mv $(TOOL_PREFIX)/bin/cpp $(TOOL_PREFIX)/bin/$(TARGET)-cpp || true; \
	mv $(TOOL_PREFIX)/bin/gcov $(TOOL_PREFIX)/bin/$(TARGET)-gcov || true; \

	@# we must protect the gcc binaries from removal by newer gcc versions
	for i in gcov gccbug gcc cpp; do \
	    mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC34_SUFFIX) || true; \
	done

	@# we can now restore previous gcc binaries
	-mv $(TOOL_PREFIX)/bin/.gcclc34/$(TARGET)-{gcov,gccbug,gcc,cpp} \
	    $(TOOL_PREFIX)/bin/ >/dev/null 2>&1
	rmdir $(TOOL_PREFIX)/bin/.gcclc34 >/dev/null 2>&1
	touch $@

$(GCCLC34_BDIR)/.compiled: $(GCCLC34_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	mkdir -p $(TOOL_PREFIX)/$(TARGET)
	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/$(TARGET)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/$(TARGET)/
	cd $(GCCLC34_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) all $(MPFLAGS) $(GCC34_ADDONS)
	touch $@

$(GCCLC34_BDIR)/.configured: $(GCC34_SDIR)/.patched $(GLIBC_SDIR)/.patched $(GLIBC_HDIR)/.installed $(BINUTILS_BDIR)/.installed
	@# this is needed to find the binutils
	@# ln -s $(TOOL_PREFIX) $(ROOT_PREFIX)/$(TARGET)
	@# ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	mkdir -p $(SYS_ROOT)

	[ -e $(SYS_ROOT)/usr ] || \
	   ln -sf $(ROOT_PREFIX) $(SYS_ROOT)/
	[ -e $(SYS_ROOT)/lib ] || \
	   ln -sf $(ROOTDIR)/lib $(SYS_ROOT)/

	mkdir -p $(ROOT_PREFIX)/include
	rm -f $(ROOT_PREFIX)/sys-include ; ln -sf include $(ROOT_PREFIX)/sys-include
	mkdir -p $(GCCLC34_BDIR)
	(cd $(GCCLC34_BDIR) && CC="$(HOSTCC)" CC_FOR_BUILD=$(HOSTCC) \
	 AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
         NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
	 RANLIB_FOR_TARGET=$(TARGET)-ranlib \
	 PATH=$(TARGET_PATH) $(GCC34_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) \
	   --libdir=$(TOOL_PREFIX)/lib --libexecdir=$(TOOL_PREFIX)/lib \
	   --disable-locale --disable-nls --disable-shared \
	   --with-gnu-ld --with-gnu-as \
	   --with-as=$(TOOL_PREFIX)/$(TARGET)/bin/as \
	   --with-ld=$(TOOL_PREFIX)/$(TARGET)/bin/ld \
	   --enable-version-specific-runtime-libs \
	   --disable-multilib --with-newlib \
	   --enable-symvers=gnu --enable-c99 --enable-long-long \
	   --with-sysroot=$(SYS_ROOT) \
	   --with-local-prefix=$(SYS_ROOT) \
	   --enable-languages=c \
	   --program-suffix=-$(GCC34_SUFFIX) --program-prefix=$(TARGET)- \
	   --with-cpu=$(TARGET_CPU))
	touch $@


$(GCCLC41_BDIR)/.installed: $(GCCLC41_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	@# we must first protect possibly existing gcc binaries from removal
	@echo "Saving previous gcc binaries into .gcclc41/"
	mkdir -p $(TOOL_PREFIX)/bin/.gcclc41
	-mv $(TOOL_PREFIX)/bin/$(TARGET)-{gcov,gccbug,gcc,cpp} \
	    $(TOOL_PREFIX)/bin/.gcclc41/ >/dev/null 2>&1

	(cd $(GCCLC41_BDIR) && \
	 PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install-gcc INSTALL_PROGRAM_ARGS="-s" )

	@# this one is mis-named
	mv $(TOOL_PREFIX)/bin/cpp $(TOOL_PREFIX)/bin/$(TARGET)-cpp || true; \
	mv $(TOOL_PREFIX)/bin/gcov $(TOOL_PREFIX)/bin/$(TARGET)-gcov || true; \

	@# we must protect the gcc binaries from removal by newer gcc versions
	for i in gcov gccbug gcc cpp; do \
	    mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC41_SUFFIX) || true; \
	done

	@# we can now restore previous gcc binaries
	-mv $(TOOL_PREFIX)/bin/.gcclc41/$(TARGET)-{gcov,gccbug,gcc,cpp} \
	    $(TOOL_PREFIX)/bin/ >/dev/null 2>&1
	rmdir $(TOOL_PREFIX)/bin/.gcclc41 >/dev/null 2>&1
	touch $@

$(GCCLC41_BDIR)/.compiled: $(GCCLC41_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	mkdir -p $(TOOL_PREFIX)/$(TARGET)
	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/$(TARGET)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/$(TARGET)/
	cd $(GCCLC41_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) all $(MPFLAGS) $(GCC41_ADDONS)
	touch $@

$(GCCLC41_BDIR)/.configured: $(GCC41_SDIR)/.patched $(GLIBC_SDIR)/.patched $(GLIBC_HDIR)/.installed $(BINUTILS_BDIR)/.installed
	@# this is needed to find the binutils
	@# ln -s $(TOOL_PREFIX) $(ROOT_PREFIX)/$(TARGET)
	@# ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	mkdir -p $(SYS_ROOT)

	[ -e $(SYS_ROOT)/usr ] || \
	   ln -sf $(ROOT_PREFIX) $(SYS_ROOT)/
	[ -e $(SYS_ROOT)/lib ] || \
	   ln -sf $(ROOTDIR)/lib $(SYS_ROOT)/

	mkdir -p $(ROOT_PREFIX)/include
	rm -f $(ROOT_PREFIX)/sys-include ; ln -sf include $(ROOT_PREFIX)/sys-include
	mkdir -p $(GCCLC41_BDIR)
	(cd $(GCCLC41_BDIR) && CC="$(HOSTCC)" CC_FOR_BUILD=$(HOSTCC) \
	 AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
         NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
	 RANLIB_FOR_TARGET=$(TARGET)-ranlib \
	 PATH=$(TARGET_PATH) $(GCC41_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) \
	   --libdir=$(TOOL_PREFIX)/lib --libexecdir=$(TOOL_PREFIX)/lib \
	   --disable-locale --disable-nls --disable-shared \
	   --with-gnu-ld --with-gnu-as \
	   --with-as=$(TOOL_PREFIX)/$(TARGET)/bin/as \
	   --with-ld=$(TOOL_PREFIX)/$(TARGET)/bin/ld \
	   --enable-version-specific-runtime-libs \
	   --disable-multilib --with-newlib \
	   --enable-symvers=gnu --enable-c99 --enable-long-long \
	   --with-sysroot=$(SYS_ROOT) \
	   --with-local-prefix=$(SYS_ROOT) \
	   --enable-languages=c \
	   --program-suffix=-$(GCC41_SUFFIX) --program-prefix=$(TARGET)- \
	   --with-cpu=$(TARGET_CPU))
	touch $@



#### kernel headers
# these headers have been build this way :
# cd /usr/src/linux-2.4.32-wt8
# make allmodconfig
# make dep
# make dep-files
# ln -s . linux-2.4.32-wt8
# tar --exclude='*.stamp' --exclude='*.ver' -c linux-2.4.32-wt8/include/{acpi,asm,asm-i386,linux,math-emu,net,pcmcia,scsi,video} | bzip2 -9 >kernel-headers-i386-2.4.32-wt8.tar.bz2
#
# Note: try this way instead of dep+dep-files :
# make ARCH=$(TARGET_ARCH) allmodconfig symlinks include/linux/version.h

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

$(GLIBC_BDIR)/.compiled: $(GCCLC_BDIR)/.installed $(GLIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	cd $(GLIBC_BDIR) && PATH=$(TARGET_PATH) $(MAKE) $(MPFLAGS)
	touch $@

$(GLIBC_BDIR)/.configured: $(GCCLC_BDIR)/.installed $(GLIBC_SDIR)/.patched $(KHDR_SDIR)/.patched $(BINUTILS_BDIR)/.installed
	mkdir -p $(GLIBC_BDIR)
	(cd $(GLIBC_BDIR) && \
	 PATH=$(TARGET_PATH) CC=$(TOOL_PREFIX)/bin/$(TARGET)-gcc-$(GCCLC_SUFFIX) \
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
	 cp $(GLIBC_HDIR)/bits/stdio_lim.h $(ROOT_PREFIX)/include/bits/ && \
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
	patch -p1 -d $(GLIBC_SDIR) < $(PATCHES)/glibc-2.3.2-csu-Makefile.patch
	patch -p1 -d $(GLIBC_SDIR) < $(PATCHES)/glibc-2.2.5-support-gcc4.diff
	touch $@

$(GLIBC_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/glibc-$(GLIBC).tar.bz2
	tar -C $(GLIBC_SDIR) -jxf $(DOWNLOAD)/glibc-linuxthreads-$(GLIBC).tar.bz2
	touch $@

#### We also want to set a default GCC. For this, pick one of
#### "default_gcc29", "default_gcc33", "default_gcc34", "default_gcc41"

default_gcc: default_$(GCCDEFAULT)


#### GCC-2.95

default_gcc29: $(GCC29_BDIR)/.default_gcc

$(GCC29_BDIR)/.default_gcc: $(GCC29_BDIR)/.installed
	for i in gcov g++ c++ gcc cpp c++filt unprotoize protoize; do \
	    ln -snf $(TARGET)-$$i-$(GCC29_SUFFIX) $(TOOL_PREFIX)/bin/$(TARGET)-$$i || true; \
	done
	echo $@ > $(GCC29_BDIR)/.default_gcc

gcc29: $(GCC29_BDIR)/.installed
$(GCC29_BDIR)/.installed: $(GCC29_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	@# we must first protect possibly existing gcc binaries from removal
	@echo "Saving previous gcc binaries into .gcc29/"
	mkdir -p $(TOOL_PREFIX)/bin/.gcc29
	-mv $(TOOL_PREFIX)/bin/$(TARGET)-{gcov,g++,c++,gcc,cpp,c++filt,unprotoize,protoize} \
	    $(TOOL_PREFIX)/bin/.gcc29/ >/dev/null 2>&1

	echo "###############  installing 'gcc-cross'  ##################"
	(cd $(GCC29_BDIR) && \
	 PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install-gcc-cross INSTALL_PROGRAM_ARGS="-s" \
	    gcclibdir="$(TOOL_PREFIX)/lib/gcc-lib" \
	    GCC_FLAGS_TO_PASS='$$(BASE_FLAGS_TO_PASS) $$(EXTRA_GCC_FLAGS) \
	        gcclibdir=$(TOOL_PREFIX)/lib/gcc-lib \
	        libsubdir=$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version) \
	        gcc_gxx_include_dir=\$$(libsubdir)/include' )

	echo "###############  installing 'target'  ##################"
	@# Note that we want libstdc++ in the root directory and not in the toolchain,
	@# so we will use the 'tooldir' variable to displace the install directory.
	@# We also want to move libiberty to gcc-lib because the one in the root is
	@# reserved for binutils, so we point libdir to the gcc directory.

	(cd $(GCC29_BDIR) && \
	 PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install-target INSTALL_PROGRAM_ARGS="-s" \
	    gcclibdir='$(TOOL_PREFIX)/lib/gcc-lib' \
	    libsubdir='$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)' \
	    libdir='$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)' \
	    tooldir='$(ROOT_PREFIX)' \
	    gcc_gxx_include_dir='\$$(libsubdir)/include' )

	@# The libstdc++ links are now bad and must be fixed.
	(old=$$(basename $$(readlink $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/libstdc++.so)) ; \
	 ln -sf ../../../../target-root/usr/lib/$$old $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/libstdc++.so ; \
	 old=$$(basename $$(readlink $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/libstdc++.a)) ; \
	 ln -sf ../../../../target-root/usr/lib/$$old $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/libstdc++.a )

	echo "###############  end of install  ##################"
	@# we must reset the 'cross_compile' flag, otherwise the path to crt*.o gets stripped !
	sed '/^\*cross_compile/,/^$$/s/^1/0/' \
		< $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs \
		> $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs-
	mv $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs- $(TOOL_PREFIX)/lib/gcc-lib/$(TARGET)/2.95.4/specs

	@# this one is mis-named
	mv $(TOOL_PREFIX)/bin/cpp $(TOOL_PREFIX)/bin/$(TARGET)-cpp || true; \
	mv $(TOOL_PREFIX)/bin/gcov $(TOOL_PREFIX)/bin/$(TARGET)-gcov || true; \

	@# we must protect the gcc binaries from removal	by newer gcc versions
	for i in gcov g++ c++ gcc cpp c++filt unprotoize protoize; do \
	    mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC29_SUFFIX) || true; \
	done

	@# we can now restore previous gcc binaries
	-mv $(TOOL_PREFIX)/bin/.gcc29/$(TARGET)-{gcov,g++,c++,gcc,cpp,c++filt,unprotoize,protoize} \
	    $(TOOL_PREFIX)/bin/ >/dev/null 2>&1
	rmdir $(TOOL_PREFIX)/bin/.gcc29 >/dev/null 2>&1
	touch $@

$(GCC29_BDIR)/.compiled: $(GLIBC_BDIR)/.installed $(GCC29_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	@# this is because of bugs in the libstdc++ path configuration
	( rmdir $(GCC29_BDIR)/$(TARGET) && ln -s . $(GCC29_BDIR)/$(TARGET) || true ) 2>/dev/null 

	@# first, we will only build gcc
	cd $(GCC29_BDIR) && PATH=$(TARGET_PATH) $(MAKE) all-gcc $(MFLAGS) \
	   gcclibdir="$(TOOL_PREFIX)/lib/gcc-lib" \
	    GCC_FLAGS_TO_PASS='$$(BASE_FLAGS_TO_PASS) $$(EXTRA_GCC_FLAGS) \
	        gcclibdir=$(TOOL_PREFIX)/lib/gcc-lib \
	        libsubdir=$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)'

	@# we must reset the 'cross_compile' flag, otherwise the path to crt*.o gets stripped and
	@# components such as libstdc++ cannot be built !
	sed '/^\*cross_compile/,/^$$/s/^1/0/' < $(GCC29_BDIR)/gcc/specs > $(GCC29_BDIR)/gcc/specs-
	mv $(GCC29_BDIR)/gcc/specs- $(GCC29_BDIR)/gcc/specs

	@# now we can make everything else (libio, libstdc++, ...)
	cd $(GCC29_BDIR) && PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) \
	   gcclibdir="$(TOOL_PREFIX)/lib/gcc-lib" \
	    GCC_FLAGS_TO_PASS='$$(BASE_FLAGS_TO_PASS) $$(EXTRA_GCC_FLAGS) \
	        gcclibdir=$(TOOL_PREFIX)/lib/gcc-lib \
	        libsubdir=$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)'
	touch $@

$(GCC29_BDIR)/.configured: $(GLIBC_BDIR)/.installed $(GCC29_SDIR)/.patched $(BINUTILS_BDIR)/.installed
	mkdir -p $(GCC29_BDIR)

	@# Those directories are important : gcc looks for "limits.h" there to
	@# know if it must chain to it or impose its own.
	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/$(TARGET)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/
	[ -e $(TOOL_PREFIX)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/

	@# WARNING! do not enable target-optspace, it corrupts CXX_FLAGS
	@# in mt-frags which break c++ build. Also, we cannot use program-suffix
	@# because it applies it to binutils too!
	(cd $(GCC29_BDIR) && CC="$(HOSTCC)" \
	 PATH=$(TARGET_PATH) $(GCC29_SDIR)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) --disable-locale --disable-nls \
	   --enable-shared --disable-__cxa_atexit --with-gnu-ld \
	   --with-gxx-include-dir=$(SYS_ROOT)/usr/include/c++ \
	   --libdir=$(SYS_ROOT)/usr/lib \
	   --enable-languages=c,c++ --enable-threads )
	touch $@

$(GCC29_SDIR)/.patched: $(GCC29_SDIR)/.extracted
	@# Patches from Erik Andersen to fix known bugs in gcc-2.95
	[ -s "$(DOWNLOAD)/gcc2.95-mega.patch.bz2" ] && \
		bzcat $(DOWNLOAD)/gcc2.95-mega.patch.bz2 | patch -p1 -d $(GCC29_SDIR)

	@# Patch to allow gcc-2.95 to build on gcc-3
	bzcat $(PATCHES)/gcc-2.95-gcc3-compfix.diff.bz2 | patch -p1 -d $(GCC29_SDIR)

	@# patches to allow gcc to find includes in $ROOT_PREFIX/include
	for p in patch-gcc295-{prefix-target-root,prefix-usage,displace-gcc-lib}; do \
	   patch -p1 -d $(GCC29_SDIR) < $(PATCHES)/$$p ; \
	done
	touch $@

$(GCC29_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/gcc-$(GCC29).tar.bz2
	touch $@


#### GCC-3.3

default_gcc33: $(GCC33_BDIR)/.default_gcc

$(GCC33_BDIR)/.default_gcc: $(GCC33_BDIR)/.installed
	for i in gcov gccbug g++ c++ gcc cpp; do \
	    ln -snf $(TARGET)-$$i-$(GCC33_SUFFIX) $(TOOL_PREFIX)/bin/$(TARGET)-$$i || true; \
	done
	echo $@ > $(GCC33_BDIR)/.default_gcc

gcc33: $(GCC33_BDIR)/.installed
$(GCC33_BDIR)/.installed: $(GCC33_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	@# we must first protect possibly existing gcc binaries from removal
	@echo "Saving previous gcc binaries into .gcc33/"
	mkdir -p $(TOOL_PREFIX)/bin/.gcc33
	-mv $(TOOL_PREFIX)/bin/$(TARGET)-{gcov,gccbug,g++,c++,gcc,cpp} \
	    $(TOOL_PREFIX)/bin/.gcc33/ >/dev/null 2>&1

	cd $(GCC33_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install INSTALL_PROGRAM_ARGS="-s" $(GCC33_ADDONS)

	@# this one is redundant
	-rm -f $(TOOL_PREFIX)/bin/$(TARGET)-gcc-$(GCC33)

	@# now we set the version on the binaries, because make install
	@# does not do it in gcc-3.3.
	for i in gcov gccbug g++ c++ gcc cpp; do \
	    [ -e "$(TOOL_PREFIX)/bin/$(TARGET)-$$i" ] && \
	       mv $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC33_SUFFIX) || true; \
	done

	@# we can now restore previous gcc binaries
	-mv $(TOOL_PREFIX)/bin/.gcc33/$(TARGET)-{gcov,gccbug,g++,c++,gcc,cpp} \
	    $(TOOL_PREFIX)/bin/ >/dev/null 2>&1
	rmdir $(TOOL_PREFIX)/bin/.gcc33 >/dev/null 2>&1
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
	   --prefix=$(TOOL_PREFIX) \
	   --libdir=$(TOOL_PREFIX)/lib --libexecdir=$(TOOL_PREFIX)/lib \
	   --disable-locale --disable-nls \
	   --enable-shared --with-gnu-ld --with-gnu-as \
	   --with-as=$(TOOL_PREFIX)/$(TARGET)/bin/as \
	   --with-ld=$(TOOL_PREFIX)/$(TARGET)/bin/ld \
	   --enable-version-specific-runtime-libs --enable-threads \
	   --enable-symvers=gnu --enable-c99 --enable-long-long \
	   --with-sysroot=$(SYS_ROOT) \
	   --with-local-prefix=$(SYS_ROOT) \
	   --enable-languages=c,c++ \
	   --program-suffix=-$(GCC33_SUFFIX) --program-prefix=$(TARGET)- \
	   --with-cpu=$(TARGET_CPU))
	touch $@

$(GCC33_SDIR)/.patched: $(GCC33_SDIR)/.extracted
	@# patches to allow gcc to find includes in $ROOT_PREFIX/include
	for p in patch-gcc33-{install-script,fix-tooldir,not-outside-root}; do \
	   patch -p1 -d $(GCC33_SDIR) < $(PATCHES)/$$p ; \
	done
	touch $@

$(GCC33_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/gcc-$(GCC33).tar.bz2
	touch $@


#### GCC-3.4

default_gcc34: $(GCC34_BDIR)/.default_gcc

$(GCC34_BDIR)/.default_gcc: $(GCC34_BDIR)/.installed
	for i in gcov gccbug g++ c++ gcc cpp; do \
	    ln -snf $(TARGET)-$$i-$(GCC34_SUFFIX) $(TOOL_PREFIX)/bin/$(TARGET)-$$i || true; \
	done
	echo $@ > $(GCC34_BDIR)/.default_gcc

gcc34: $(GCC34_BDIR)/.installed
$(GCC34_BDIR)/.installed: $(GCC34_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	cd $(GCC34_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install INSTALL_PROGRAM='$${INSTALL} -s' INSTALL_SCRIPT='$${INSTALL}' $(GCC34_ADDONS)

	@# this one is redundant
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
	   --prefix=$(TOOL_PREFIX) \
	   --libdir=$(TOOL_PREFIX)/lib --libexecdir=$(TOOL_PREFIX)/lib \
	   --disable-locale --disable-nls \
	   --enable-shared --with-gnu-ld --with-gnu-as \
	   --with-as=$(TOOL_PREFIX)/$(TARGET)/bin/as \
	   --with-ld=$(TOOL_PREFIX)/$(TARGET)/bin/ld \
	   --enable-version-specific-runtime-libs --enable-threads \
	   --enable-symvers=gnu --enable-c99 --enable-long-long \
	   --with-sysroot=$(SYS_ROOT) \
	   --with-local-prefix=$(SYS_ROOT) \
	   --enable-languages=c,c++ \
	   --program-suffix=-$(GCC34_SUFFIX) --program-prefix=$(TARGET)- \
	   --with-cpu=$(TARGET_CPU))
	touch $@

$(GCC34_SDIR)/.patched: $(GCC34_SDIR)/.extracted
	for p in patch-gcc34-fix-tooldir patch-gcc34-not-outside-root; do \
	   patch -p1 -d $(GCC34_SDIR) < $(PATCHES)/$$p ; \
	done
	touch $@

$(GCC34_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	tar -C $(SOURCE) -jxf $(DOWNLOAD)/gcc-$(GCC34).tar.bz2
	touch $@


#### GCC-4.1

default_gcc41: $(GCC41_BDIR)/.default_gcc

$(GCC41_BDIR)/.default_gcc: $(GCC41_BDIR)/.installed
	for i in gcov gccbug g++ c++ gcc cpp; do \
	    ln -snf $(TARGET)-$$i-$(GCC41_SUFFIX) $(TOOL_PREFIX)/bin/$(TARGET)-$$i || true; \
	done
	echo $@ > $(GCC41_BDIR)/.default_gcc


gcc41: $(GCC41_BDIR)/.installed
$(GCC41_BDIR)/.installed: $(GCC41_BDIR)/.compiled $(BINUTILS_BDIR)/.installed
	cd $(GCC41_BDIR) && \
	  PATH=$(TARGET_PATH) $(MAKE) $(MFLAGS) install INSTALL_PROGRAM_ARGS="-s" $(GCC41_ADDONS)

	@# this one is redundant
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
	   --prefix=$(TOOL_PREFIX) \
	   --libdir=$(TOOL_PREFIX)/lib --libexecdir=$(TOOL_PREFIX)/lib \
	   --disable-locale --disable-nls \
	   --enable-shared --with-gnu-ld --with-gnu-as \
	   --with-as=$(TOOL_PREFIX)/$(TARGET)/bin/as \
	   --with-ld=$(TOOL_PREFIX)/$(TARGET)/bin/ld \
	   --enable-version-specific-runtime-libs --enable-threads \
	   --enable-symvers=gnu --enable-c99 --enable-long-long \
	   --with-sysroot=$(SYS_ROOT) \
	   --with-local-prefix=$(SYS_ROOT) \
	   --enable-languages=c,c++ \
	   --program-suffix=-$(GCC41_SUFFIX) --program-prefix=$(TARGET)- \
	   --with-cpu=$(TARGET_CPU))
	touch $@

$(GCC41_SDIR)/.patched: $(GCC41_SDIR)/.extracted
	for p in patch-gcc41-{fix-tooldir,not-outside-root}; do \
	   patch -p1 -d $(GCC41_SDIR) < $(PATCHES)/$$p ; \
	done
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

$(DIETLIBC_BDIR)/.compiled: default_gcc $(DIETLIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.patched
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
	cd $(UCLIBC_BDIR) && PATH=$(TARGET_PATH) \
	   $(MAKE) $(MFLAGS) install ARCH=$(TARGET_ARCH) CROSS=$(CROSSPFX)
	sed -e 's@%%TOOLDIR%%@$(TOOLDIR)@g' $(PATCHES)/uclibc.wrap >$(TOOL_PREFIX)/bin/uclibc
	chmod 755 $(TOOL_PREFIX)/bin/uclibc
	touch $@

$(UCLIBC_BDIR)/.compiled: default_gcc $(UCLIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.patched
	cd $(UCLIBC_BDIR) && PATH=$(TARGET_PATH) $(MAKE) clean

	cd $(UCLIBC_BDIR) && PATH=$(TARGET_PATH) \
	   $(MAKE) $(MPFLAGS) ARCH=$(TARGET_ARCH) CROSS=$(CROSSPFX)
	touch $@

$(UCLIBC_BDIR)/.configured: $(UCLIBC_SDIR)/.patched
	-rm -rf $(UCLIBC_BDIR) >/dev/null 2>&1
	mkdir -p $(BUILDDIR)
	tar -C $(SOURCE) -cf - uClibc-$(UCLIBC) | tar -C $(BUILDDIR) -xUf -
	echo 'KERNEL_SOURCE="$(KHDR_SDIR)"' >> $(BUILDDIR)/uClibc-$(UCLIBC)/.config
	echo 'KERNEL_HEADERS="$(KHDR_SDIR)/include"' >> $(BUILDDIR)/uClibc-$(UCLIBC)/.config
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

