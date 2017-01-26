#
# Makefile
#

all:

.PHONY += help
help:
	@echo "SNAP configuration system"
	@echo
	@echo "  Please ensure that you have installed your Linux kernel"
	@echo "  sources and the tools to build and configure it. We are"
	@echo "  using the same infrastructure to generate the SNAP"
	@echo "  configuration files."
	@echo
	@echo "Possible targets are:"
	@echo "  menuconfig - use menuconfig/ncurses"
	@echo "  gconfig    - use gconfig/GTK+"
	@echo "  xconfig    - use xconfig/QT"
	@echo "  config     - use config/command line version"
	@echo "  prepare    - generate configuration specific header."
	@echo

.PHONY += menuconfig gconfig xconfig config oldconfig prepare
menuconfig gconfig xconfig config oldconfig prepare:
	./snap_config -o $@

install:

uninstall:

clean:
	$(RM) -r build autoconf.h .config *~
