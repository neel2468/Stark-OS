#!/bin/bash
set -e

OUTPUT_IMAGE="$1"
DISK_SIZE="$2"
BUILD_DIR="$3"

echo "=== Creating UEFI Bootable Disk Image ==="
echo "Output: $OUTPUT_IMAGE"
echo "Size: ${DISK_SIZE}MB"
echo "Build dir: $BUILD_DIR"

# Remove old image
rm -f "$OUTPUT_IMAGE"

# Create empty disk image
dd if=/dev/zero of="$OUTPUT_IMAGE" bs=1M count="$DISK_SIZE" status=progress

# Create GPT partition table with ESP
echo "Creating GPT partition table..."
parted "$OUTPUT_IMAGE" -s mklabel gpt
parted "$OUTPUT_IMAGE" -s mkpart primary fat32 2048s 100%
parted "$OUTPUT_IMAGE" -s set 1 esp on

# Setup loop device
echo "Setting up loop device..."
LOOP_DEVICE=$(sudo losetup --partscan --find --show "$OUTPUT_IMAGE")
echo "Loop device: $LOOP_DEVICE"

# Wait for partition to appear
sleep 1

# Format ESP as FAT32
echo "Formatting ESP partition..."
sudo mkfs.fat -F 32 "${LOOP_DEVICE}p1"

# Mount ESP
MOUNT_POINT=$(mktemp -d)
sudo mount "${LOOP_DEVICE}p1" "$MOUNT_POINT"

# Create EFI directory structure
echo "Creating EFI directory structure..."
sudo mkdir -p "$MOUNT_POINT/EFI/BOOT"

# Copy bootloader
if [ -f "$BUILD_DIR/bootloader.efi" ]; then
    sudo cp "$BUILD_DIR/bootloader.efi" "$MOUNT_POINT/EFI/BOOT/BOOTX64.EFI"
    echo "✓ Copied: bootloader.efi -> BOOTX64.EFI"
else
    echo "ERROR: $BUILD_DIR/bootloader.efi not found!"
    sudo umount "$MOUNT_POINT"
    sudo losetup -d "$LOOP_DEVICE"
    rmdir "$MOUNT_POINT"
    exit 1
fi

# Copy kernel if exists
if [ -f "$BUILD_DIR/kernel.bin" ]; then
    sudo cp "$BUILD_DIR/kernel.bin" "$MOUNT_POINT/kernel.bin"
    echo "✓ Copied: kernel.bin"
fi

# List contents
echo ""
echo "=== Disk Image Contents ==="
sudo find "$MOUNT_POINT" -type f -exec ls -lh {} \;
echo ""

# Verify bootloader
echo "=== Bootloader Verification ==="
sudo file "$MOUNT_POINT/EFI/BOOT/BOOTX64.EFI"

# Cleanup
echo ""
echo "Cleaning up..."
sudo umount "$MOUNT_POINT"
sudo losetup -d "$LOOP_DEVICE"
rmdir "$MOUNT_POINT"

echo "✓ Disk image created successfully: $OUTPUT_IMAGE"