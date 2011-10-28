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
TOOLS         := $(TOP)/tools
ADDONS        := $(TOP)/addons
DOWNLOAD      := $(TOP)/download
SOURCE        := $(TOP)/source
BUILD         := $(TOP)/build

# Result will be installed in $(INSTALLDIR)/$(TARGET). This is the definitive
# installation directory. It must be accessible during and after build.
INSTALLDIR    := $(TOP)

# GCCVERSIONS indicates the list of compiler branches to be built for "gcc".
# The default one may be forced by GCCDEFAULT, though that's rarely needed as
# it is by default the first one in the list.
GCCVERSIONS   := 2.95 3.3 3.4 4.1
GCCDEFAULT    := $(word 1,$(GCCVERSIONS))

# Exact versions of GCC. Those which will be build are defined by the
# 'GCCVERSIONS' variable above. The version indicated here is the suffix
# of the tar.gz file to extract which must also match the source directory
# name after extraction
GCC29         := 20011006
GCC33         := 3.3.6
GCC34         := 3.4.6
GCC41         := 4.1.2

# Default suffixes assigned to resulting GCC versions
GCC29_BRANCH  := 2.95
GCC33_BRANCH  := 3.3
GCC34_BRANCH  := 3.4
GCC41_BRANCH  := 4.1

# various other packages (libc, binutils, kernel headers)
GLIBC         := 2.2.5
BINUTILS      := 2.16.1
KHDR          := 2.4.32-wt8
DIETLIBC      := 0.31
UCLIBC        := 0.9.29

# Suffix of the compiler to use for building glibc. 2.95 is used by default,
# but be aware that it is not much portable and may not build at all on recent
# systems.
GCCLIBC       := 2.95

# various commands and options which can be overridden by the command line.

cmd_gzip      := gzip
cmd_tar       := tar
cmd_bzip2     := bzip2
cmd_find      := find
cmd_patch     := patch
cmd_make      := $(MAKE)
cmd_readall   := $(TOOLS)/readall

MFLAGS        :=
MPFLAGS       := -j 2


##### There are very little chances that you find anything to change below #####

# map back the GCC suffixes from the versions
GCC_BRANCH-$(GCC29) := $(GCC29_BRANCH)
GCC_BRANCH-$(GCC33) := $(GCC33_BRANCH)
GCC_BRANCH-$(GCC34) := $(GCC34_BRANCH)
GCC_BRANCH-$(GCC41) := $(GCC41_BRANCH)

# map the versions GCC from the suffixes
GCC_VERSION-$(GCC29_BRANCH) := $(GCC29)
GCC_VERSION-$(GCC33_BRANCH) := $(GCC33)
GCC_VERSION-$(GCC34_BRANCH) := $(GCC34)
GCC_VERSION-$(GCC41_BRANCH) := $(GCC41)

# determine exact GCC version used for the glibc
GCCLC         := $(GCC_VERSION-$(GCCLIBC))

# Everything under TARGETDIR must remain together
TARGETDIR     := $(INSTALLDIR)/$(TARGET)
TOOLDIR       := $(TARGETDIR)/tool-$(HOST)
ROOTDIR       := $(TARGETDIR)/root
POOLDIR       := $(TARGETDIR)/pool
TOOL_PREFIX   := $(TOOLDIR)/usr
ROOT_PREFIX   := $(ROOTDIR)/usr
SYS_ROOT      := $(TOOL_PREFIX)/target-root
TARGET_PATH   := $(TOOL_PREFIX)/bin:$(PATH)

# no need to change this, it will be easier to clean it up
BUILDDIR      := $(BUILD)/$(TARGET)/$(HOST)
BINUTILS_SDIR := $(SOURCE)/binutils-$(BINUTILS)
BINUTILS_BDIR := $(BUILDDIR)/binutils-$(BINUTILS)

# During gcc configuration, the program-prefix also affects binutils names, so
# we have to enforce them.
GCC_BU_NAMES  := AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
                 NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
                 RANLIB_FOR_TARGET=$(TARGET)-ranlib

KHDR_SDIR     := $(SOURCE)/linux-$(KHDR)

GLIBC_SDIR    := $(SOURCE)/glibc-$(GLIBC)
GLIBC_BDIR    := $(BUILDDIR)/glibc-$(GLIBC)
GLIBC_HDIR    := $(BUILDDIR)/glibc-headers-$(GLIBC)

DIETLIBC_SDIR := $(SOURCE)/dietlibc-$(DIETLIBC)
DIETLIBC_BDIR := $(BUILDDIR)/dietlibc-$(DIETLIBC)

UCLIBC_SDIR   := $(SOURCE)/uClibc-$(UCLIBC)
UCLIBC_BDIR   := $(BUILDDIR)/uClibc-$(UCLIBC)

################# end of configuration ##############

help:
	@echo
	@echo "This Makefile supports the following targets :"
	@echo "   - all, all-noclean: dietlibc uclibc glibc gcc default_gcc"
	@echo "   - binutils gcc-libc $(addprefix gcc-,$(GCCVERSIONS))"
	@echo "   - $(addprefix default_gcc-,$(GCCVERSIONS))"
	@echo "   - kernel-headers glibc-headers glibc dietlibc uclibc"
	@echo "   - install remove-unneeded space"
	@echo "   - bootstrap-archive git-bootstrap-archive"
	@echo "   - tool-archive root-archive"
	@echo "   - help showconf"
	@echo
	@echo "Notes:"
	@echo "   - GCC branches may be changed with GCCVERSIONS=\"2.95 3.3 ...\""
	@echo "   - default GCC branch is the first of the list (or GCCDEFAULT)"
	@echo "   - GCC used for libc may be changed with GCCLIBC=\"3.4\""
	@echo "   - installation directory may be changed with INSTALLDIR=\"/...\""
	@echo "   - parallel build may be changed with MPFLAGS=\"-jXX\""
	@echo "   - using TARGET=$(TARGET) HOST=$(HOST) MPFLAGS=\"$(MPFLAGS)\""
	@echo "   - using GCCVERSIONS=\"$(GCCVERSIONS)\" GCCDEFAULT=$(GCCDEFAULT) GCCLIBC=$(GCCLIBC)"
	@echo "   - using INSTALLDIR=$(INSTALLDIR)"
	@echo

showconf:
	@echo   "TOOLCHAIN : version $(TOOLCHAIN)"
	@echo   "HOST      : $(HOST)  HOSTCC=$(HOSTCC)  (version: $(shell $(HOSTCC) -dumpversion))"
	@echo   "TARGET    : $(TARGET)  TARGET_CPU=$(TARGET_CPU)  TARGET_ARCH=$(TARGET_ARCH)"
	@echo   "INSTALLDIR:$(INSTALLDIR)"
	@echo   "MAKE      : $(MAKE)  MFLAGS=\"$(MFLAGS)\"  MPFLAGS=\"$(MPFLAGS)\""
	@printf "GLIBC     : version : %-10s  patches : %d  GCCLIBC : %s ($(GCCLC))\n" \
	  $(GLIBC) $$(/bin/ls -1 $(PATCHES)/glibc-$(GLIBC) 2>/dev/null |wc -l) $(GCCLIBC)
	@printf "BINUTILS  : version : %-10s  patches : %d\n" \
	  $(BINUTILS) $$(/bin/ls -1 $(PATCHES)/binutils-$(BINUTILS) 2>/dev/null |wc -l)
	@printf "DIETLIBC  : version : %-10s  patches : %d\n" \
	  $(DIETLIBC) $$(/bin/ls -1 $(PATCHES)/dietlibc-$(DIETLIBC) 2>/dev/null |wc -l)
	@printf "UCLIBC    : version : %-10s  patches : %d\n" \
	  $(UCLIBC) $$(/bin/ls -1 $(PATCHES)/uClibc-$(UCLIBC) 2>/dev/null |wc -l)
	@printf "KHDR      : version : %-10s  patches : %d\n" \
	  $(KHDR) $$(/bin/ls -1 $(PATCHES)/kernel-headers-$(KHDR) 2>/dev/null |wc -l)
	@echo   "GCC       : GCCVERSIONS=\"$(GCCVERSIONS)\"  GCCDEFAULT=$(GCCDEFAULT)"
	@printf "  branch  : %-4s  version : %-8s  patches : %d\n" \
	  $(GCC29_BRANCH) $(GCC29) $$(/bin/ls -1 $(PATCHES)/gcc-$(GCC29) 2>/dev/null |wc -l)
	@printf "  branch  : %-4s  version : %-8s  patches : %d\n" \
	  $(GCC33_BRANCH) $(GCC33) $$(/bin/ls -1 $(PATCHES)/gcc-$(GCC33) 2>/dev/null |wc -l)
	@printf "  branch  : %-4s  version : %-8s  patches : %d\n" \
	  $(GCC34_BRANCH) $(GCC34) $$(/bin/ls -1 $(PATCHES)/gcc-$(GCC34) 2>/dev/null |wc -l)
	@printf "  branch  : %-4s  version : %-8s  patches : %d\n" \
	  $(GCC41_BRANCH) $(GCC41) $$(/bin/ls -1 $(PATCHES)/gcc-$(GCC41) 2>/dev/null |wc -l)

# The "all" target builds everything and removes a number of useless files.
# These files are not necessary to build anything, and if needed, they should
# be extracted from their respective compiled packages. They don't have their
# place in the toolchain, so we remove them. If you want to keep them, use the
# "all-noclean" target instead.
all: all-noclean
	rm -rf $(TOOL_PREFIX)/{man,info} $(TOOLDIR)/diet/man
	rm -rf $(ROOT_PREFIX)/{bin,info,lib/gconv,sbin,share}

all-noclean: dietlibc uclibc glibc gcc default_gcc

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
	$(cmd_tar) cf - toolchain-$(TOOLCHAIN)/{CHANGELOG,HOWTO.txt,Makefile,patches,tools} \
	         toolchain-$(TOOLCHAIN)/tests/{FLXPKG,README.txt,*/.flxpkg} \
	  | $(cmd_gzip) -c9 >flx-toolchain-$(TOOLCHAIN).tgz
	rm -f toolchain-$(TOOLCHAIN)

# easier way to make a bootstrap archive based on git
git-bootstrap-archive:
	git tar-tree HEAD toolchain-$(TOOLCHAIN) | $(cmd_gzip) -c9 >flx-toolchain-$(TOOLCHAIN).tgz

# build the archive containing the minimal binary tools.
tool-archive: remove-unneeded
	$(cmd_tar) -cf - $(TARGETDIR)/tool-$(HOST) \
	  | $(cmd_bzip2) -c9 >flx-toolchain-$(TOOLCHAIN)-tool-$(HOST)_$(TARGET).tbz

# build the archive containing the minimal binary root files.
root-archive: remove-unneeded $(POOLDIR)
	$(cmd_tar) -cf - $(TARGETDIR)/root $(TARGETDIR)/pool \
	  | $(cmd_bzip2) -c9 >flx-toolchain-$(TOOLCHAIN)-root-$(TARGET).tbz

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


##### All symbolic rules should be grouped here for easier troubleshooting ####

binutils:       $(BINUTILS_BDIR)/.installed
gcc-libc:       $(BUILDDIR)/gcc-libc-$(GCCLC)/.installed
kernel-headers: $(KHDR_SDIR)/.completed
glibc:          $(GLIBC_BDIR)/.installed
glibc-headers:  $(GLIBC_HDIR)/.installed
gcc:            $(addprefix gcc-,$(GCCVERSIONS))
default_gcc:    $(addprefix default_gcc-,$(GCCDEFAULT))
dietlibc:       $(DIETLIBC_BDIR)/.installed
uclibc:         $(UCLIBC_BDIR)/.installed

gcc-2.95:       $(BUILDDIR)/gcc-$(GCC_VERSION-2.95)/.installed
gcc-3.3:        $(BUILDDIR)/gcc-$(GCC_VERSION-3.3)/.installed
gcc-3.4:        $(BUILDDIR)/gcc-$(GCC_VERSION-3.4)/.installed
gcc-4.1:        $(BUILDDIR)/gcc-$(GCC_VERSION-4.1)/.installed

default_gcc-2.95: $(BUILDDIR)/gcc-$(GCC_VERSION-2.95)/.default_gcc
default_gcc-3.3:  $(BUILDDIR)/gcc-$(GCC_VERSION-3.3)/.default_gcc
default_gcc-3.4:  $(BUILDDIR)/gcc-$(GCC_VERSION-3.4)/.default_gcc
default_gcc-4.1:  $(BUILDDIR)/gcc-$(GCC_VERSION-4.1)/.default_gcc


################# start of build system ##############

# Note: we link gnm to nm and gstrip to strip because GCC searches them
# first in all of the system directories !
$(BINUTILS_BDIR)/.installed: $(BINUTILS_BDIR)/.compiled
	(cd $(BINUTILS_BDIR) && \
	 $(cmd_make) $(MFLAGS) install INSTALL_PROGRAM="\$${INSTALL} -s" )
	 ln -sf nm $(TOOL_PREFIX)/$(TARGET)/bin/gnm
	 ln -sf strip $(TOOL_PREFIX)/$(TARGET)/bin/gstrip
	touch $@

$(BINUTILS_BDIR)/.compiled: $(BINUTILS_BDIR)/.configured
	cd $(BINUTILS_BDIR) && $(cmd_make) $(MPFLAGS)
	touch $@

$(BINUTILS_BDIR)/.configured: $(BINUTILS_SDIR)/.completed
	mkdir -p $(BINUTILS_BDIR)
	(cd $(BINUTILS_BDIR) && CC=$(HOSTCC) $(BINUTILS_SDIR)/configure \
           --host=$(HOST) --target=$(TARGET) --prefix=$(TOOL_PREFIX) \
	   --with-sysroot=$(SYS_ROOT) \
	   --with-lib-path="$(TOOL_PREFIX)/$(TARGET)-linux/lib:$(ROOTDIR)/lib:$(ROOT_PREFIX)/lib" \
	   --disable-shared --disable-locale --disable-nls \
	)
	touch $@


#### partial GCC needed to build glibc. The correct exact version to use is
#### determined by the GCCLC variable, and the build directory is set to
#### gcc-libc-$(GCCLC).

# GCC-2.95 for GLIBC

$(BUILDDIR)/gcc-libc-$(GCC29)/.installed: $(BUILDDIR)/gcc-libc-$(GCC29)/.compiled $(BINUTILS_BDIR)/.installed
	@# we must first protect possibly existing gcc binaries from removal
	@echo "Saving previous gcc binaries into .gcclc29/"
	mkdir -p $(TOOL_PREFIX)/bin/.gcclc29
	-mv $(TOOL_PREFIX)/bin/$(TARGET)-{gcov,gcc,cpp,unprotoize,protoize} \
	    $(TOOL_PREFIX)/bin/.gcclc29/ >/dev/null 2>&1

	(cd $(BUILDDIR)/gcc-libc-$(GCC29) && \
	 PATH=$(TARGET_PATH) $(cmd_make) install-gcc $(MFLAGS) INSTALL_PROGRAM_ARGS="-s" )

	@# this one is mis-named
	mv -v $(TOOL_PREFIX)/bin/cpp $(TOOL_PREFIX)/bin/$(TARGET)-cpp || true; \
	mv -v $(TOOL_PREFIX)/bin/gcov $(TOOL_PREFIX)/bin/$(TARGET)-gcov || true; \

	@# we must protect the gcc binaries from removal by newer gcc versions
	for i in gcov gcc cpp unprotoize protoize; do \
	    mv -v $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC29_BRANCH) || true; \
	done

	@# we can now restore previous gcc binaries
	-mv $(TOOL_PREFIX)/bin/.gcclc29/$(TARGET)-{gcov,gcc,cpp,unprotoize,protoize} \
	    $(TOOL_PREFIX)/bin/ >/dev/null 2>&1
	rmdir $(TOOL_PREFIX)/bin/.gcclc29 >/dev/null 2>&1
	touch $@

$(BUILDDIR)/gcc-libc-$(GCC29)/.compiled: $(BUILDDIR)/gcc-libc-$(GCC29)/.configured $(BINUTILS_BDIR)/.installed
	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/$(TARGET)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/$(TARGET)/
	cd $(BUILDDIR)/gcc-libc-$(GCC29) && PATH=$(TARGET_PATH) $(cmd_make) all-gcc $(MFLAGS)
	touch $@

# Note: we will install this first-stage compiler in $PREFIX, but since it
# will be a cross-compiler, gcc will implicitly use $PREFIX/$TARGET for the
# includes, libraries and binaries, and we cannot do anything about that,
# so we must install the glibc headers accordingly.
#
# Note: try to build this in a different directory with different options, such
# as --enable-__cxa_atexit, --disable-threads, --with-newlib, --disable-multilib

$(BUILDDIR)/gcc-libc-$(GCC29)/.configured: $(SOURCE)/gcc-$(GCC29)/.completed $(GLIBC_SDIR)/.completed $(GLIBC_HDIR)/.installed $(BINUTILS_BDIR)/.installed
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
	mkdir -p $(BUILDDIR)/gcc-libc-$(GCC29)
	(cd $(BUILDDIR)/gcc-libc-$(GCC29) && PATH=$(TARGET_PATH) \
	 CC=$(HOSTCC) CC_FOR_BUILD=$(HOSTCC) \
	 AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
	 NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
         RANLIB_FOR_TARGET=$(TARGET)-ranlib \
	 $(SOURCE)/gcc-$(GCC29)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) --disable-shared --disable-nls \
	   --disable-__cxa_atexit --disable-haifa \
	   --includedir=$(SYS_ROOT)/usr/include \
	   --enable-languages=c )
	touch $@


# Generic rules to build GCC-3.3/3.4/4.1 for GLIBC

# Generic installation rule for glibc-specific gcc. This rule does not work for gcc <3
$(BUILDDIR)/gcc-libc-%/.installed: $(BUILDDIR)/gcc-libc-%/.compiled $(BINUTILS_BDIR)/.installed
	(cd $(patsubst %/.installed,%,$@) && \
	 PATH=$(TARGET_PATH) $(cmd_make) install-gcc $(MFLAGS) $(GCC_BU_NAMES) INSTALL_PROGRAM_ARGS="-s" )
	touch $@

# Generic build rule for glibc-specific gcc. This rule does not work for gcc <3
$(BUILDDIR)/gcc-libc-%/.compiled: $(BUILDDIR)/gcc-libc-%/.configured $(BINUTILS_BDIR)/.installed
	mkdir -p $(TOOL_PREFIX)/$(TARGET)
	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/$(TARGET)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/$(TARGET)/
	cd $(patsubst %/.compiled,%,$@) && \
	  PATH=$(TARGET_PATH) $(cmd_make) all-gcc $(MPFLAGS) $(GCC_BU_NAMES)
	touch $@

# Generic configuration rule for glibc-specific gcc. This rule does not work for gcc <3
$(BUILDDIR)/gcc-libc-%/.configured: $(SOURCE)/gcc-%/.completed $(GLIBC_SDIR)/.completed $(GLIBC_HDIR)/.installed $(BINUTILS_BDIR)/.installed
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
	mkdir -p $(patsubst %/.configured,%,$@)
	(cd $(patsubst %/.configured,%,$@) && CC="$(HOSTCC)" CC_FOR_BUILD=$(HOSTCC) \
	 AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
         NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
	 RANLIB_FOR_TARGET=$(TARGET)-ranlib \
	 PATH=$(TARGET_PATH) \
	 $(patsubst %/.completed,%,$<)/configure \
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
	   --program-suffix=-$(GCC_BRANCH-$(patsubst $(BUILDDIR)/gcc-libc-%/.configured,%,$@)) \
	   --program-prefix=$(TARGET)- \
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

$(KHDR_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	$(cmd_tar) -C $(SOURCE) -jxf $(DOWNLOAD)/kernel-headers-$(TARGET_ARCH)-$(KHDR).tar.bz2 \
	  || $(cmd_tar) -C $(SOURCE) -jxf $(DOWNLOAD)/kernel-headers-$(KHDR).tar.bz2
	touch $@


#### glibc

$(GLIBC_BDIR)/.installed: $(GLIBC_BDIR)/.compiled $(GLIBC_HDIR)/.installed $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.completed
	(cd $(GLIBC_BDIR) && \
	 $(cmd_make) $(MFLAGS) install slibdir=$(ROOTDIR)/lib \
	    INSTALL_PROGRAM="\$${INSTALL} -s" \
	    INSTALL_SCRIPT="\$${INSTALL}" && \
	 rm -rf $(ROOT_PREFIX)/include/{asm,linux} && \
	 (cd $(KHDR_SDIR)/include/ && $(cmd_tar) -cf - {asm,linux}/.) | (cd $(ROOT_PREFIX)/include/ && $(cmd_tar) xf -) )
	touch $@

$(GLIBC_BDIR)/.compiled: $(BUILDDIR)/gcc-libc-$(GCCLC)/.installed $(GLIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed
	cd $(GLIBC_BDIR) && PATH=$(TARGET_PATH) $(cmd_make) $(MPFLAGS)
	touch $@

$(GLIBC_BDIR)/.configured: $(BUILDDIR)/gcc-libc-$(GCCLC)/.installed $(GLIBC_SDIR)/.completed $(KHDR_SDIR)/.completed $(BINUTILS_BDIR)/.installed
	mkdir -p $(GLIBC_BDIR)
	(cd $(GLIBC_BDIR) && \
	 PATH=$(TARGET_PATH) CC=$(TOOL_PREFIX)/bin/$(TARGET)-gcc-$(GCC_BRANCH-$(GCCLC)) \
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

$(GLIBC_HDIR)/.installed: $(GLIBC_HDIR)/.configured $(GLIBC_SDIR)/.completed $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.completed
	(cd $(GLIBC_HDIR) && \
	 PATH=$(TARGET_PATH) \
	   $(cmd_make) $(MFLAGS) cross-compiling=yes \
	     install_root=$(ROOTDIR) prefix=/usr slibdir=/lib \
	     libdir=/usr/lib libexecdir=/usr/bin install-headers && \
	 cp $(GLIBC_SDIR)/include/features.h $(ROOT_PREFIX)/include/ && \
	 cp $(GLIBC_HDIR)/bits/stdio_lim.h $(ROOT_PREFIX)/include/bits/ && \
	 mkdir -p $(ROOT_PREFIX)/include/gnu && \
	 touch $(ROOT_PREFIX)/include/gnu/stubs.h && \
	 rm -rf $(ROOT_PREFIX)/include/{asm,linux} && \
	 (cd $(KHDR_SDIR)/include/ && $(cmd_tar) -cf - {asm,linux}/.) | (cd $(ROOT_PREFIX)/include/ && $(cmd_tar) xf -) )
	touch $@

$(GLIBC_HDIR)/.configured: $(GLIBC_SDIR)/.completed $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.completed
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
	   PATH=$(TARGET_PATH) $(cmd_make) sysdeps/gnu/errlist.c ; \
	   mkdir -p stdio-common ; \
	   touch stdio-common/errlist-compat.c ; \
	 fi )
	touch $@

$(GLIBC_SDIR)/.extracted:
	mkdir -p $(SOURCE)
	$(cmd_tar) -C $(SOURCE) -jxf $(DOWNLOAD)/glibc-$(GLIBC).tar.bz2
	$(cmd_tar) -C $(GLIBC_SDIR) -jxf $(DOWNLOAD)/glibc-linuxthreads-$(GLIBC).tar.bz2
	touch $@

# We also want to set a default GCC. For this, pick one of "default_gcc-2.95",
# "default_gcc-3.3", "default_gcc-3.4", "default_gcc-4.1". Using "default_gcc"
# alone will result in the compiler designed as the default one to be installed.

# generic rule to set one compiler as the default one. All versionned existing
# files are linked to their canonical name. Note that the canonical name is
# taken out of the .installed file.
$(BUILDDIR)/gcc-%/.default_gcc: $(BUILDDIR)/gcc-%/.installed
	for i in gccbug gcov g++ c++ gcc cpp c++filt unprotoize protoize; do \
	    suffix=$(GCC_BRANCH-$(patsubst $(BUILDDIR)/gcc-%/.default_gcc,%,$@)); \
	    if [ -e $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$$suffix ]; then \
	        ln -snf $(TARGET)-$$i-$$suffix $(TOOL_PREFIX)/bin/$(TARGET)-$$i; \
	    fi; \
	done
	touch $@


#### GCC-2.95

$(BUILDDIR)/gcc-$(GCC29)/.installed: $(BUILDDIR)/gcc-$(GCC29)/.compiled $(BINUTILS_BDIR)/.installed
	@# we must first protect possibly existing gcc binaries from removal
	@echo "Saving previous gcc binaries into .gcc29/"
	mkdir -p $(TOOL_PREFIX)/bin/.gcc29
	-mv $(TOOL_PREFIX)/bin/$(TARGET)-{gcov,g++,c++,gcc,cpp,c++filt,unprotoize,protoize} \
	    $(TOOL_PREFIX)/bin/.gcc29/ >/dev/null 2>&1

	echo "###############  installing 'gcc-cross'  ##################"
	(cd $(BUILDDIR)/gcc-$(GCC29) && \
	 PATH=$(TARGET_PATH) $(cmd_make) $(MFLAGS) install-gcc-cross INSTALL_PROGRAM_ARGS="-s" \
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

	(cd $(BUILDDIR)/gcc-$(GCC29) && \
	 PATH=$(TARGET_PATH) $(cmd_make) $(MFLAGS) install-target INSTALL_PROGRAM_ARGS="-s" \
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
	mv -v $(TOOL_PREFIX)/bin/cpp $(TOOL_PREFIX)/bin/$(TARGET)-cpp || true; \
	mv -v $(TOOL_PREFIX)/bin/gcov $(TOOL_PREFIX)/bin/$(TARGET)-gcov || true; \

	@# we must protect the gcc binaries from removal by newer gcc versions
	for i in gcov g++ c++ gcc cpp c++filt unprotoize protoize; do \
	    mv -v $(TOOL_PREFIX)/bin/$(TARGET)-$$i $(TOOL_PREFIX)/bin/$(TARGET)-$$i-$(GCC29_BRANCH) || true; \
	done

	@# we can now restore previous gcc binaries
	-mv $(TOOL_PREFIX)/bin/.gcc29/$(TARGET)-{gcov,g++,c++,gcc,cpp,c++filt,unprotoize,protoize} \
	    $(TOOL_PREFIX)/bin/ >/dev/null 2>&1
	rmdir $(TOOL_PREFIX)/bin/.gcc29 >/dev/null 2>&1
	touch $@

$(BUILDDIR)/gcc-$(GCC29)/.compiled: $(BUILDDIR)/gcc-$(GCC29)/.configured $(GLIBC_BDIR)/.installed $(BINUTILS_BDIR)/.installed
	@# this is because of bugs in the libstdc++ path configuration
	( rmdir $(BUILDDIR)/gcc-$(GCC29)/$(TARGET) && ln -s . $(BUILDDIR)/gcc-$(GCC29)/$(TARGET) || true ) 2>/dev/null 

	@# first, we will only build gcc
	cd $(BUILDDIR)/gcc-$(GCC29) && PATH=$(TARGET_PATH) $(cmd_make) all-gcc $(MFLAGS) \
	   gcclibdir="$(TOOL_PREFIX)/lib/gcc-lib" \
	    GCC_FLAGS_TO_PASS='$$(BASE_FLAGS_TO_PASS) $$(EXTRA_GCC_FLAGS) \
	        gcclibdir=$(TOOL_PREFIX)/lib/gcc-lib \
	        libsubdir=$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)'

	@# we must reset the 'cross_compile' flag, otherwise the path to crt*.o gets stripped and
	@# components such as libstdc++ cannot be built !
	sed '/^\*cross_compile/,/^$$/s/^1/0/' < $(BUILDDIR)/gcc-$(GCC29)/gcc/specs > $(BUILDDIR)/gcc-$(GCC29)/gcc/specs-
	mv $(BUILDDIR)/gcc-$(GCC29)/gcc/specs- $(BUILDDIR)/gcc-$(GCC29)/gcc/specs

	@# now we can make everything else (libio, libstdc++, ...)
	cd $(BUILDDIR)/gcc-$(GCC29) && PATH=$(TARGET_PATH) $(cmd_make) $(MFLAGS) \
	   gcclibdir="$(TOOL_PREFIX)/lib/gcc-lib" \
	    GCC_FLAGS_TO_PASS='$$(BASE_FLAGS_TO_PASS) $$(EXTRA_GCC_FLAGS) \
	        gcclibdir=$(TOOL_PREFIX)/lib/gcc-lib \
	        libsubdir=$(TOOL_PREFIX)/lib/gcc-lib/\$$(target_alias)/\$$(gcc_version)'
	touch $@

$(BUILDDIR)/gcc-$(GCC29)/.configured: $(SOURCE)/gcc-$(GCC29)/.completed $(GLIBC_BDIR)/.installed $(BINUTILS_BDIR)/.installed
	mkdir -p $(BUILDDIR)/gcc-$(GCC29)

	@# Those directories are important : gcc looks for "limits.h" there to
	@# know if it must chain to it or impose its own.
	[ -e $(TOOL_PREFIX)/$(TARGET)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/$(TARGET)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/$(TARGET)/
	[ -e $(TOOL_PREFIX)/include ] || ln -s $(ROOT_PREFIX)/include $(TOOL_PREFIX)/
	[ -e $(TOOL_PREFIX)/sys-include ] || ln -s $(ROOT_PREFIX)/sys-include $(TOOL_PREFIX)/

	@# WARNING! do not enable target-optspace, it corrupts CXX_FLAGS
	@# in mt-frags which break c++ build. Also, we cannot use program-suffix
	@# because it applies it to binutils too!
	(cd $(BUILDDIR)/gcc-$(GCC29) && CC="$(HOSTCC)" \
	 PATH=$(TARGET_PATH) $(SOURCE)/gcc-$(GCC29)/configure \
           --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	   --prefix=$(TOOL_PREFIX) --disable-locale --disable-nls \
	   --enable-shared --disable-__cxa_atexit --with-gnu-ld \
	   --with-gxx-include-dir=$(SYS_ROOT)/usr/include/c++ \
	   --libdir=$(SYS_ROOT)/usr/lib \
	   --enable-languages=c,c++ --enable-threads )
	touch $@


# Generic rules to build standard GCC-3.3/3.4/4.1

# Generic installation rule for standard gcc. This rule does not work for gcc <3
$(BUILDDIR)/gcc-%/.installed: $(BUILDDIR)/gcc-%/.compiled $(BINUTILS_BDIR)/.installed
	cd $(patsubst %/.installed,%,$@) && \
	  PATH=$(TARGET_PATH) $(cmd_make) install $(MFLAGS) $(GCC_BU_NAMES) INSTALL_PROGRAM_ARGS="-s"

	@# this one is redundant
	-rm -v $(TOOL_PREFIX)/bin/$(TARGET)-gcc-$(patsubst $(BUILDDIR)/gcc-%/.installed,%,$@)
	touch $@

# Generic build rule for standard gcc. This rule does not work for gcc <3
$(BUILDDIR)/gcc-%/.compiled: $(BUILDDIR)/gcc-%/.configured $(GLIBC_BDIR)/.installed $(BINUTILS_BDIR)/.installed
	cd $(patsubst %/.compiled,%,$@) && \
	  PATH=$(TARGET_PATH) $(cmd_make) all $(MPFLAGS) $(GCC_BU_NAMES)
	touch $@

# Generic configuration rule for standard gcc. This rule does not work for gcc <3
$(BUILDDIR)/gcc-%/.configured: $(SOURCE)/gcc-%/.completed $(GLIBC_BDIR)/.installed $(BINUTILS_BDIR)/.installed
	mkdir -p $(patsubst %/.configured,%,$@)
	(cd $(patsubst %/.configured,%,$@) && CC="$(HOSTCC)" \
	 AR_FOR_TARGET=$(TARGET)-ar AS_FOR_TARGET=$(TARGET)-as \
         NM_FOR_TARGET=$(TARGET)-nm LD_FOR_TARGET=$(TARGET)-ld \
	 RANLIB_FOR_TARGET=$(TARGET)-ranlib \
	 PATH=$(TARGET_PATH) \
	 $(patsubst %/.completed,%,$<)/configure \
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
	   --program-suffix=-$(GCC_BRANCH-$(patsubst $(BUILDDIR)/gcc-%/.configured,%,$@)) \
	   --program-prefix=$(TARGET)- \
	   --with-cpu=$(TARGET_CPU))
	touch $@


#### dietlibc
#### Cannot be fully cross-compiled yet, the 'diet' program uses the
#### cross-compiler while it should not.

$(DIETLIBC_BDIR)/.installed: default_gcc $(DIETLIBC_BDIR)/.compiled
	cd $(DIETLIBC_BDIR) && PATH=$(TARGET_PATH) \
	   $(cmd_make) $(MFLAGS) install ARCH=$(TARGET_ARCH) CROSS=$(TARGET)- prefix=$(TOOLDIR)/diet
	touch $@

$(DIETLIBC_BDIR)/.compiled: default_gcc $(DIETLIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.completed
	cd $(DIETLIBC_BDIR) && PATH=$(TARGET_PATH) \
	   $(cmd_make) $(MPFLAGS) ARCH=$(TARGET_ARCH) CROSS=$(TARGET)- prefix=$(TOOLDIR)/diet
	touch $@

$(DIETLIBC_BDIR)/.configured: $(DIETLIBC_SDIR)/.completed
	-rm -f $(DIETLIBC_BDIR) >/dev/null 2>&1
	mkdir -p $(BUILDDIR)
	$(cmd_tar) -C $(SOURCE) -cf - dietlibc-$(DIETLIBC) | $(cmd_tar) -C $(BUILDDIR) -xUf -
	touch $@

#### uclibc
#### it is built with default gcc. The result is good enough.

$(UCLIBC_BDIR)/.installed: default_gcc $(UCLIBC_BDIR)/.compiled
	cd $(UCLIBC_BDIR) && PATH=$(TARGET_PATH) \
	   $(cmd_make) $(MFLAGS) install ARCH=$(TARGET_ARCH) CROSS=$(TARGET)-
	sed -e 's@%%TOOLDIR%%@$(TOOLDIR)@g' $(ADDONS)/uclibc.wrap >$(TOOL_PREFIX)/bin/uclibc
	chmod 755 $(TOOL_PREFIX)/bin/uclibc
	touch $@

$(UCLIBC_BDIR)/.compiled: default_gcc $(UCLIBC_BDIR)/.configured $(BINUTILS_BDIR)/.installed $(KHDR_SDIR)/.completed
	cd $(UCLIBC_BDIR) && PATH=$(TARGET_PATH) $(cmd_make) clean

	cd $(UCLIBC_BDIR) && PATH=$(TARGET_PATH) \
	   $(cmd_make) $(MPFLAGS) ARCH=$(TARGET_ARCH) CROSS=$(TARGET)-
	touch $@

$(UCLIBC_BDIR)/.configured: $(UCLIBC_SDIR)/.completed
	-rm -rf $(UCLIBC_BDIR) >/dev/null 2>&1
	mkdir -p $(BUILDDIR)
	$(cmd_tar) -C $(SOURCE) -cf - uClibc-$(UCLIBC) | $(cmd_tar) -C $(BUILDDIR) -xUf -
	echo 'KERNEL_SOURCE="$(KHDR_SDIR)"' >> $(BUILDDIR)/uClibc-$(UCLIBC)/.config
	echo 'KERNEL_HEADERS="$(KHDR_SDIR)/include"' >> $(BUILDDIR)/uClibc-$(UCLIBC)/.config
	echo 'RUNTIME_PREFIX="$(TOOLDIR)/uclibc/"' >> $(BUILDDIR)/uClibc-$(UCLIBC)/.config
	echo 'DEVEL_PREFIX="$(TOOLDIR)/uclibc/usr/"' >> $(BUILDDIR)/uClibc-$(UCLIBC)/.config
	cd $(BUILDDIR)/uClibc-$(UCLIBC) && $(cmd_make) oldconfig
	touch $@

$(UCLIBC_SDIR)/.completed: $(UCLIBC_SDIR)/.patched
	cp $(CONFIG)/uclibc-$(UCLIBC).$(TARGET_CPU) $(UCLIBC_SDIR)/.config
	touch $@


######### Generic rules applying to sources #########

# Generic source completion rule: after patching, some source require a
# few addons and/or a little bit of tweaking. By defaults, it does nothing.
$(SOURCE)/%/.completed: $(SOURCE)/%/.patched
	touch $@

# Generic source patching rule : apply to source all patches from the patches
# subdirectory with the exact same name and version as the package if it exists
# and otherwise do nothing. Since it relies on the sources already being
# extracted, Make automatically extracts it from the appropriate rule.
$(SOURCE)/%/.patched: $(SOURCE)/%/.extracted
	$(cmd_readall) $(PATCHES)/$(patsubst $(SOURCE)/%/.patched,%,$@) \
	    $(cmd_patch) -p1 -d $(patsubst %/.patched,%,$@)
	touch $@

# Generic source extraction rule : extract download/XXX.tar.bz2 into source/XXX.
$(SOURCE)/%/.extracted:
	mkdir -p $(SOURCE)
	$(cmd_tar) -C $(SOURCE) -jxf $(DOWNLOAD)/$(patsubst $(SOURCE)/%/.extracted,%,$@).tar.bz2
	touch $@

# implicit rule asking make not to remove intermediate files.
.SECONDARY:
