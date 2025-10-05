#ifndef BOOT_INFO_H
#define BOOT_INFO_H

#include <efi.h>
#include <efidef.h>

// Memory map entry that kernel will understand
typedef struct {
    UINT64 base;
    UINT64 length;
    UINT32 type;  // 1=usable, 2=reserved, 3=ACPI reclaimable, etc.
} MemoryDescriptor;

// Boot information structure to pass to kernel
typedef struct {
    // Memory information
    MemoryDescriptor *memory_map;
    UINT64 memory_map_size;
    UINT64 memory_map_entry_count;
    
    // Framebuffer information
    UINT64 framebuffer_addr;
    UINT32 framebuffer_width;
    UINT32 framebuffer_height;
    UINT32 framebuffer_pitch;
    UINT32 framebuffer_bpp;
    UINT32 pixel_format; // 0=PixelRedGreenBlueReserved, 1=PixelBlueGreenRedReserved
    
    // ACPI information
    UINT64 rsdp_addr;
    
    // Kernel information
    UINT64 kernel_physical_base;
    UINT64 kernel_virtual_base;
    UINT64 kernel_size;
} BootInfo;

#endif