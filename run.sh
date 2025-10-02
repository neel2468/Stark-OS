#!/bin/bash

# UEFI Bootable Disk Image Creator
# Creates a GPT disk with EFI System Partition and copies BOOTX64.EFI

set -e  # Exit on error

# Configuration
DISK_IMAGE="disk.img"
DISK_SIZE_MB=64
EFI_SOURCE="build/BOOTX64.EFI"
MOUNT_POINT="/mnt/efi"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check if source EFI file exists
if [ ! -f "$EFI_SOURCE" ]; then
    print_error "Source file '$EFI_SOURCE' not found!"
    exit 1
fi

print_info "Starting UEFI disk image creation..."

# Clean up any existing loop devices for this image
if [ -f "$DISK_IMAGE" ]; then
    print_warning "Disk image '$DISK_IMAGE' already exists. Cleaning up..."
    EXISTING_LOOP=$(losetup -j "$DISK_IMAGE" | cut -d: -f1)
    if [ -n "$EXISTING_LOOP" ]; then
        print_info "Detaching existing loop device: $EXISTING_LOOP"
        losetup -d "$EXISTING_LOOP" 2>/dev/null || true
    fi
fi

# Create disk image
print_info "Creating ${DISK_SIZE_MB}MB disk image..."
dd if=/dev/zero of="$DISK_IMAGE" bs=1M count=$DISK_SIZE_MB status=progress

# Create GPT partition table
print_info "Creating GPT partition table..."
parted "$DISK_IMAGE" mklabel gpt

# Create EFI System Partition
print_info "Creating EFI System Partition..."
parted "$DISK_IMAGE" mkpart primary fat32 1MiB 100%
parted "$DISK_IMAGE" set 1 esp on

# Set up loop device with partition scanning
print_info "Setting up loop device..."
losetup -fP "$DISK_IMAGE"

# Find which loop device was assigned
LOOP_DEV=$(losetup -j "$DISK_IMAGE" | cut -d: -f1)
if [ -z "$LOOP_DEV" ]; then
    print_error "Failed to create loop device"
    exit 1
fi
print_info "Using loop device: $LOOP_DEV"

# Verify partition exists
if [ ! -b "${LOOP_DEV}p1" ]; then
    print_error "Partition ${LOOP_DEV}p1 not found"
    losetup -d "$LOOP_DEV"
    exit 1
fi

# Format the partition as FAT32
print_info "Formatting partition as FAT32..."
mkfs.vfat -F 32 "${LOOP_DEV}p1"

# Create mount point if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
    print_info "Creating mount point: $MOUNT_POINT"
    mkdir -p "$MOUNT_POINT"
fi

# Mount the partition
print_info "Mounting partition..."
mount "${LOOP_DEV}p1" "$MOUNT_POINT"

# Create EFI directory structure
print_info "Creating EFI directory structure..."
mkdir -p "$MOUNT_POINT/EFI/BOOT"

# Copy EFI file
print_info "Copying $EFI_SOURCE to /EFI/BOOT/BOOTX64.EFI..."
cp "$EFI_SOURCE" "$MOUNT_POINT/EFI/BOOT/BOOTX64.EFI"

# Verify the file was copied
if [ -f "$MOUNT_POINT/EFI/BOOT/BOOTX64.EFI" ]; then
    print_info "File copied successfully!"
    ls -lh "$MOUNT_POINT/EFI/BOOT/BOOTX64.EFI"
else
    print_error "Failed to copy EFI file"
    umount "$MOUNT_POINT"
    losetup -d "$LOOP_DEV"
    exit 1
fi

# Unmount
print_info "Unmounting partition..."
umount "$MOUNT_POINT"

# Detach loop device
print_info "Detaching loop device..."
losetup -d "$LOOP_DEV"

print_info "Disk image created successfully: $DISK_IMAGE"
echo ""
print_info "To test with QEMU, run:"
echo "  qemu-system-x86_64 -bios /usr/share/OVMF/OVMF_CODE.fd -drive file=$DISK_IMAGE,format=raw -m 512M"
echo ""
