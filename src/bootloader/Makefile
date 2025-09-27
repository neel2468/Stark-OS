# Minimal UEFI Bootloader Makefile

# Toolchain
TARGET_CC = x86_64-elf-gcc
TARGET_LD = x86_64-elf-ld
TARGET_OBJCOPY = x86_64-elf-objcopy

# GNU-EFI Paths (installed to cross-compiler toolchain)
TOOLCHAIN_PREFIX = x86_64-elf
TOOLCHAIN_ROOT = $(shell dirname $(shell which $(TOOLCHAIN_PREFIX)-gcc))/../..
GNUEFI_INC = $(TOOLCHAIN_ROOT)/include/efi
GNUEFI_LIB = $(TOOLCHAIN_ROOT)/lib
GNUEFI_CRT = $(TOOLCHAIN_ROOT)/lib/crt0-efi-x86_64.o
GNUEFI_LDS = $(TOOLCHAIN_ROOT)/lib/elf_x86_64_efi.lds

# Compiler Flags
TARGET_CFLAGS = -I$(GNUEFI_INC) -I$(GNUEFI_INC)/x86_64 -I$(GNUEFI_INC)/protocol
TARGET_CFLAGS += -fno-stack-protector -fpic -fshort-wchar -mno-red-zone
TARGET_CFLAGS += -DGNU_EFI_USE_MS_ABI -maccumulate-outgoing-args
TARGET_CFLAGS += -ffreestanding -nostdlib

# Linker Flags
TARGET_LINKFLAGS = -T $(GNUEFI_LDS) -shared -Bsymbolic -L$(GNUEFI_LIB) -nostdlib

# Libraries
TARGET_LIBS = -lefi -lgnuefi

# Sources
SOURCES_C = $(wildcard *.c)
OBJECTS_C = $(patsubst %.c, $(BUILD_DIR)/%.obj, $(SOURCES_C))

.PHONY: all clean

all: $(BUILD_DIR)/bootloader.efi

$(BUILD_DIR)/bootloader.efi: $(BUILD_DIR)/bootloader.so
	@$(TARGET_OBJCOPY) -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 $< $@
	@echo "--> Created: $@"

$(BUILD_DIR)/bootloader.so: $(OBJECTS_C)
	@$(TARGET_LD) $(TARGET_LINKFLAGS) $(GNUEFI_CRT) -o $@ $^ $(TARGET_LIBS)
	@echo "--> Linked: $@"

$(BUILD_DIR)/%.obj: %.c
	@mkdir -p $(@D)
	@$(TARGET_CC) $(TARGET_CFLAGS) -c -o $@ $<
	@echo "--> Compiled: $<"

clean:
	@rm -rf $(BUILD_DIR)/bootloader.efi $(BUILD_DIR)/bootloader.so $(BUILD_DIR)/*.obj