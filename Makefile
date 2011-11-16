.DELETE_ON_ERROR:

PWD:=$(shell pwd)/
INSTALLDIR:=/home/$(USER)/install/arm-none-eabi-toolchain

BINUTILS_VERSION:=binutils-2.20.1
BINUTILS_ARCHIVE:=$(BINUTILS_VERSION).tar.bz2
BINUTILS_BUILD:=generated/$(BINUTILS_VERSION)

GDB_VERSION:=gdb-7.1
GDB_ARCHIVE:=$(GDB_VERSION).tar.bz2
GDB_BUILD:=generated/$(GDB_VERSION)

GCC_VERSION:=gcc-4.4.4
GCC_ARCHIVE:=$(GCC_VERSION).tar.bz2
GCC_EXTRACT:=generated/$(GCC_VERSION)
GCC_BUILD:=generated/arm-none-eabi-gcc-build

NEWLIB_VERSION:=newlib-1.18.0
NEWLIB_ARCHIVE:=$(NEWLIB_VERSION).tar.gz
NEWLIB_EXTRACT:=generated/$(NEWLIB_VERSION)
NEWLIB_BUILD:=gnerated/arm-none-eabi-newlib-build

PARALLEL=-j 8
TARGET=arm-none-eabi

state_aptitude:=$(shell [ -f /usr/bin/aptitude ] && echo "found")

ifeq ("$(state_aptitude)", "found")

state_libgmp3_dev:=$(shell aptitude show libgmp3-dev | grep State | sed -e "s/^State: //")
state_libmpfr_dev:=$(shell aptitude show libmpfr-dev | grep State | sed -e "s/^State: //")
state_libncurses5_dev:=$(shell aptitude show libncurses5-dev | grep State | sed -e "s/^State: //")

ifeq ("$(state_libgmp3_dev)", "not installed")
$(error Make sure libgmp3-dev is installed)
endif

ifeq ("$(state_libmpfr_dev)", "not installed")
$(error Make sure libmpfr-dev is installed)
endif

ifeq ("$(state_libncurses5_dev)", "not installed")
$(error Make sure libncurses5-dev is installed)
endif

endif

arm-none-eabi-toolchain: $(BINUTILS_BUILD)/.touch $(GCC_BUILD)/.touch $(GDB_BUILD)/.touch

default: arm-none-eabi-toolchain

BINUTILS_FLAGS=--target=$(TARGET) \
	       --prefix=$(INSTALLDIR)

$(BINUTILS_BUILD)/.touch: $(BINUTILS_ARCHIVE) $(BINUTILS_PATCH)
	mkdir -p generated
	tar -C generated -xjf $(BINUTILS_ARCHIVE)
	cd $(BINUTILS_BUILD) && ./configure $(BINUTILS_FLAGS)
	cd $(BINUTILS_BUILD) && $(MAKE) $(PARALLEL)
	cd $(BINUTILS_BUILD) && $(MAKE) install
	touch $@

$(GDB_BUILD)/.touch: $(GDB_ARCHIVE) $(BINUTILS_BUILD)/.touch
	mkdir -p generated
	tar -C generated -xjf $(GDB_ARCHIVE)
	cd $(GDB_BUILD) && ./configure CFLAGS=-U_FORTIFY_SOURCE --target=$(TARGET) --prefix=$(INSTALLDIR)
	cd $(GDB_BUILD) && $(MAKE) $(PARALLEL)
	cd $(GDB_BUILD) && $(MAKE) install
	touch $@

GCC_FLAGS:=--target=$(TARGET) \
	--prefix=$(INSTALLDIR) \
	--enable-languages="c,c++" \
	--with-newlib

$(GCC_BUILD)/.touch: $(GCC_ARCHIVE) $(NEWLIB_ARCHIVE) $(BINUTILS_BUILD)/.touch
	mkdir -p generated
	tar -C generated -xjf $(GCC_ARCHIVE)
	tar -C generated -xzf $(NEWLIB_ARCHIVE)
	ln -s -f $(PWD)/$(NEWLIB_EXTRACT)/newlib $(GCC_EXTRACT)/newlib
	mkdir -p $(GCC_BUILD)
	cd $(GCC_BUILD) && PATH=$$PATH:$(INSTALLDIR)/bin ../$(GCC_VERSION)/configure $(GCC_FLAGS)
	cd $(GCC_BUILD) && $(MAKE) $(PARALLEL)
	cd $(GCC_BUILD) && $(MAKE) install
	touch $@

clean:
	rm -rf generated
