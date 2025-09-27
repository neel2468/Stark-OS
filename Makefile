include build_scripts/config.mk

.PHONY: all disk_image kernel bootloader clean always

all: disk_image tools_fat

include build_scripts/toolchain.mk

disk_image: $(BUILD_DIR)/main_disk.raw

$(BUILD_DIR)/main_disk.raw: bootloader kernel
	@sudo ./build_scripts/make_disk_image.sh $@ $(MAKE_DISK_SIZE) $(abspath build)
	@echo "--> Created: " $@

#
# Bootloader (Updated for UEFI)
#
bootloader: $(BUILD_DIR)/bootloader.efi

$(BUILD_DIR)/bootloader.efi: always
	@$(MAKE) -C src/bootloader BUILD_DIR=$(abspath $(BUILD_DIR))

#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	@$(MAKE) -C src/kernel BUILD_DIR=$(abspath $(BUILD_DIR))

#
# Always
#
always:
	@mkdir -p $(BUILD_DIR)

#
# Clean
#
clean:
	@$(MAKE) -C src/bootloader BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	@$(MAKE) -C src/kernel BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	@rm -rf $(BUILD_DIR)/*