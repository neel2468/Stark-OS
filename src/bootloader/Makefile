TARGET_CC      := x86_64-w64-mingw32-gcc
TARGET_LD      := x86_64-w64-mingw32-ld
TARGET_OBJCOPY := x86_64-w64-mingw32-objcopy

TOOLCHAIN_PREFIX = x86_64-elf
TOOLCHAIN_ROOT = $(shell dirname $(shell which $(TOOLCHAIN_PREFIX)-gcc))/../..


GNUEFI_INC = $(TOOLCHAIN_ROOT)/include/efi

TARGET_CFLAGS := -ffreestanding -fno-stack-protector \
                 -fshort-wchar -mno-red-zone \
                 -DGNU_EFI_USE_MS_ABI -maccumulate-outgoing-args -nostdlib \
                 -I$(GNUEFI_INC) -I$(GNUEFI_INC)/x86_64 -I$(GNUEFI_INC)/protocol


TARGET_LDFLAGS := -nostdlib -Wl,--subsystem,10 -Wl,-entry:efi_main

# Sources
SOURCES_C = $(wildcard *.c)
OBJECTS_C = $(patsubst %.c,$(BUILD_DIR)/%.o,$(SOURCES_C))

.PHONY: all clean

all: $(BUILD_DIR)/bootloader.efi

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(TARGET_CC) $(TARGET_CFLAGS) -c $< -o $@

# Build final EFI binary
$(BUILD_DIR)/bootloader.efi: $(OBJECTS_C)
	@mkdir -p $(dir $@)
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) $^ -o $@

clean:
	rm -rf $(BUILD_DIR)
