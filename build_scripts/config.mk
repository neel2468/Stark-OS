MAKE_DISK_SIZE = 16777216 #16 MB

export CFLAGS = -std=c99 -g
export ASMFLAGS =
export CC = gcc
export CXX = g++
export LD = gcc
export ASM = nasm
export LINKFLAGS =
export LIBS =

export TARGET = x86_64-elf
export TARGET_CFLAGS = -std=c99 -g #-O2
export TARGET_CC = $(TARGET)-gcc
export TARGET_CXX = $(TARGET)-g++
export TARGET_LD = $(TARGET)-gcc
export TARGET_LINKFLAGS =
export TARGET_LIBS =

export BUILD_DIR = $(abspath build)
export SOURCE_DIR = $(abspath .)

BINUTILS_VERSION = 2.45
BINUTILS_URL = https://sourceware.org/pub/binutils/releases/binutils-$(BINUTILS_VERSION).tar.xz

GCC_VERSION = 15.1.0
GCC_URL = https://mirrors.ibiblio.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz