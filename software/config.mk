#
# Copyright 2016, 2017 International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Check if SNAP_ROOT is set. Having SNAP_ROOT set allows simplifications
# in the Makeefiles all over the place. We tried with relative path setups
# but that is cumbersome if we like to use this from different levels
# in the directory tree.
#

ifndef SNAP_ROOT
$(error Please set SNAP_ROOT to the repository root directory.)
endif
ifeq ("$(wildcard $(SNAP_ROOT)/ActionTypes.md)","")
$(error Please make sure that SNAP_ROOT=$$SNAP_ROOT is set up correctly.)
endif

# Verbosity level:
#   V=0 means completely silent
#   V=1 means brief output
#   V=2 means full output
#
V		?= 1

ifeq ($(V),0)
Q		:= @
MAKEFLAGS	+= --silent
MAKE		+= -s
endif

ifeq ($(V),1)
MAKEFLAGS	+= --silent
MAKE		+= -s
endif

CC		= $(CROSS)gcc
AS		= $(CROSS)as
LD		= $(CROSS)ld
AR		= $(CROSS)ar
RANLIB		= $(CROSS)ranlib
OBJCOPY		= $(CROSS)objcopy
OBJDUMP		= $(CROSS)objdump
STRIP		= $(CROSS)strip
NM		= $(CROSS)nm
HELP2MAN	= help2man

ifeq ($(V),0)
Q		:= @
MAKEFLAGS	+= --silent
MAKE		+= -s
endif

ifeq ($(V),1)
MAKEFLAGS	+= --silent
MAKE		+= -s
CC		= printf "\t[CC]\t%s\n" `basename "$@"`; $(CROSS)gcc
AS		= printf "\t[AS]\t%s\n" `basename "$@"`; $(CROSS)as
AR		= printf "\t[AR]\t%s\n" `basename "$@"`; $(CROSS)ar
LD		= printf "\t[LD]\t%s\n" `basename "$@"`; $(CROSS)ld
OBJCOPY		= printf "\t[OBJCOPY]\t%s\n" `basename "$@"`; $(CROSS)objcopy
else
CLEAN		= echo -n
endif

#
# If we can use git to get a version, we use that. If not, we have
# no repository and set a static version number.
#
# NOTE Keep the VERSION for the non git case in sync with the git
#      tag used to build this code!
#
HAS_GIT = $(shell git describe > /dev/null 2>&1 && echo y || echo n)

# Set a default Version
VERSION=0.0.9-no-git

ifeq (${HAS_GIT},y)
	GIT_BRANCH=$(shell git describe --always --tags)
	VERSION:=$(GIT_BRANCH)
endif

CFLAGS ?= -W -Wall -Werror -Wwrite-strings -Wextra -O2 -g \
	-Wmissing-prototypes # -Wstrict-prototypes -Warray-bounds

CFLAGS += -DGIT_VERSION=\"$(VERSION)\" \
	-I. -I../include -D_GNU_SOURCE=1

# Optimizations
CFLAGS += -funroll-all-loops

# General settings: Include and library search path
CFLAGS += -I$(SNAP_ROOT)/software/include 
LDFLAGS += -L$(SNAP_ROOT)/software/lib

# Force 32-bit build
#   This is needed to generate the code for special environments. We have
#   some 64-bit machines where we need to support binaries compiled for
#   32-bit.
#
#   FORCE_32BIT=0  Use machine default
#   FORCE_32BIT=1  Enforce 32-bit build
#
PLATFORM ?= $(shell uname -i)
ifeq ($(PLATFORM),x86_64)
BUILD_SIMCODE=1

ifndef PSLSE_ROOT
# Environment variable PSLSE_ROOT defined by hardware setup scripts.
# Use default path if PSLSE_ROOT is not defined.
PSLSE_ROOT=$(abspath ../../../pslse)
endif

FORCE_32BIT ?= 0

ifeq ($(FORCE_32BIT),1)
CFLAGS += -m32
LDFLAGS += -m32
XLDFLAGS = -melf_i386
ARFLAGS =
else
CFLAGS += -m64
LDFLAGS += -m64
XLDFLAGS = -melf_x86_64
ARFLAGS =
endif
else
ARFLAGS =
endif

#
# If we build for simulation we need to take the PSLSE version
# of libcxl. This is true for linage as well as when we setup
# the LD_LIBRARY_PATH on program execution.
#
ifdef BUILD_SIMCODE
CFLAGS += -D_SIM_ -I$(PSLSE_ROOT)/libcxl -I$(PSLSE_ROOT)/common
LDFLAGS += -L$(PSLSE_ROOT)/libcxl
endif

DESTDIR ?= /usr
LIB_INSTALL_PATH ?= $(DESTDIR)/lib64
INCLUDE_INSTALL_PATH ?= $(DESTDIR)/include
MAN_INSTALL_PATH ?= $(DESTDIR)/share/man/man1
