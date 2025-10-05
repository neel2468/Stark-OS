#include <efi.h>
#include <efidef.h>
#include "boot_info.h"

static EFI_SYSTEM_TABLE *gST;
static EFI_BOOT_SERVICES *gBS;



static UINT32 ConvertMemoryType(UINT32 efi_type);
static EFI_STATUS EFIAPI GetSystemMemoryMap(BootInfo boot_info);
static EFI_STATUS EFIAPI ConfigureAndReturnGraphicsBuffer(BootInfo boot_info);
static EFI_STATUS EFIAPI FindACPITable(BootInfo boot_info);



EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
   
    
    gST = SystemTable;
    gBS = SystemTable->BootServices;
    
    BootInfo boot_info = {0};
    EFI_STATUS status;
    
    gST->ConOut->ClearScreen(gST->ConOut);
    gST->ConOut->OutputString(gST->ConOut,L"=== Stark OS Bootloader ===\r\n\r\n");
    
    // ==== STEP 1: Get Memory Map ====
    gST->ConOut->OutputString(gST->ConOut,L"[1] Getting memory map...\r\n");
    status = GetSystemMemoryMap(boot_info);
    
    // ==== STEP 2: Setup Graphics ====
    gST->ConOut->OutputString(gST->ConOut,L"[2] Setting up graphics...\r\n");
    status = ConfigureAndReturnGraphicsBuffer(boot_info);
    
    // ==== STEP 3: Find ACPI ====
    gST->ConOut->OutputString(gST->ConOut,L"[3] Finding ACPI tables...\r\n");
    status = FindACPITable(boot_info);
    
    gST->ConOut->OutputString(gST->ConOut,L"\r\nAll steps completed successfully!\r\n");
    gST->ConOut->OutputString(gST->ConOut,L"System halted.\r\n");
    
    while(1) __asm__("hlt");

    if(status != EFI_SUCCESS){
        gST->ConOut->OutputString(gST->ConOut,L"\r\nError occurred. Press any key to exit.\r\n");
        EFI_INPUT_KEY key;
        while (gST->ConIn->ReadKeyStroke(gST->ConIn, &key) != EFI_SUCCESS);
    }
    return status;
}

static EFI_STATUS EFIAPI GetSystemMemoryMap(BootInfo boot_info) {
    UINTN memory_map_size = 0;
    EFI_MEMORY_DESCRIPTOR *memory_map = NULL;
    UINTN map_key, descriptor_size;
    UINT32 descriptor_version;
    EFI_STATUS status;
    
    status = gBS->GetMemoryMap(&memory_map_size, memory_map, &map_key,
                                &descriptor_size, &descriptor_version);
    
    memory_map_size += 2 * descriptor_size;
    status = gBS->AllocatePool(EfiLoaderData, memory_map_size, (void**)&memory_map);
    if(EFI_ERROR(status)) {
        gST->ConOut->OutputString(gST->ConOut,L"Failed to allocate memory map buffer\r\n");
        return status;
    }
    
    status = gBS->GetMemoryMap(&memory_map_size, memory_map, &map_key,
                                &descriptor_size, &descriptor_version);
    if(EFI_ERROR(status)) {
        gST->ConOut->OutputString(gST->ConOut,L"Failed to get memory map\r\n");
        return status;
    }
    
    UINTN entry_count = memory_map_size / descriptor_size;
    status = gBS->AllocatePool(EfiLoaderData, entry_count * sizeof(MemoryDescriptor),
                                (void**)&boot_info.memory_map);
    if(EFI_ERROR(status)) {
        gST->ConOut->OutputString(gST->ConOut,L"Failed to allocate boot_info memory_map\r\n");
        return status;
    }
    
    EFI_MEMORY_DESCRIPTOR *entry = memory_map;
    for(UINTN i = 0; i < entry_count; i++) {
        boot_info.memory_map[i].base = entry->PhysicalStart;
        boot_info.memory_map[i].length = entry->NumberOfPages * 4096;
        boot_info.memory_map[i].type = ConvertMemoryType(entry->Type);
        entry = (EFI_MEMORY_DESCRIPTOR*)((UINT8*)entry + descriptor_size);
    }
    
    boot_info.memory_map_size = memory_map_size;
    boot_info.memory_map_entry_count = entry_count;
    gST->ConOut->OutputString(gST->ConOut,L"Memory map obtained successfully\r\n");
    return EFI_SUCCESS;
}

static EFI_STATUS EFIAPI ConfigureAndReturnGraphicsBuffer(BootInfo boot_info) {
    EFI_GUID gop_guid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
    EFI_GRAPHICS_OUTPUT_PROTOCOL *gop;
    EFI_STATUS status;
    
    status = gBS->LocateProtocol(&gop_guid, NULL, (void**)&gop);
    if(EFI_ERROR(status)) {
        gST->ConOut->OutputString(gST->ConOut,L"Failed to locate GOP\r\n");
        return status;
    }
    
    EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *info = gop->Mode->Info;
    boot_info.framebuffer_addr = gop->Mode->FrameBufferBase;
    boot_info.framebuffer_width = info->HorizontalResolution;
    boot_info.framebuffer_height = info->VerticalResolution;
    boot_info.framebuffer_pitch = info->PixelsPerScanLine * 4;
    boot_info.framebuffer_bpp = 32;
    
    if(info->PixelFormat == PixelRedGreenBlueReserved8BitPerColor) {
        boot_info.pixel_format = 0;
    } else if (info->PixelFormat == PixelBlueGreenRedReserved8BitPerColor) {
        boot_info.pixel_format = 1;
    } else {
        boot_info.pixel_format = 1;
    }
    
    gST->ConOut->OutputString(gST->ConOut,L"Graphics mode configured\r\n");
    return EFI_SUCCESS;
}

static EFI_STATUS EFIAPI FindACPITable(BootInfo boot_info) {
    EFI_GUID acpi_guid = ACPI_20_TABLE_GUID;
    EFI_GUID acpi1_guid = ACPI_TABLE_GUID;
    BOOLEAN found = FALSE;
    
    for(UINTN i = 0; i < gST->NumberOfTableEntries; i++) {
        EFI_GUID *vendor_guid = &gST->ConfigurationTable[i].VendorGuid;
        if(vendor_guid->Data1 == acpi_guid.Data1 &&
            vendor_guid->Data2 == acpi_guid.Data2 &&
            vendor_guid->Data3 == acpi_guid.Data3) {
            boot_info.rsdp_addr = (UINT64)gST->ConfigurationTable[i].VendorTable;
            gST->ConOut->OutputString(gST->ConOut,L"ACPI 2.0+ RSDP found\r\n");
            found = TRUE;
            break;
        }
    }
    
    if(!found) {
        for(UINTN j = 0; j < gST->NumberOfTableEntries; j++) {
            EFI_GUID *vendor_guid = &gST->ConfigurationTable[j].VendorGuid;
            if(vendor_guid->Data1 == acpi1_guid.Data1 &&
                vendor_guid->Data2 == acpi1_guid.Data2 &&
                vendor_guid->Data3 == acpi1_guid.Data3) {
                boot_info.rsdp_addr = (UINT64)gST->ConfigurationTable[j].VendorTable;
                gST->ConOut->OutputString(gST->ConOut,L"ACPI 1.0 RSDP found\r\n");
                found = TRUE;
                break;
            }
        }
    }
    
    if(!found) {
        gST->ConOut->OutputString(gST->ConOut,L"Warning: ACPI RSDP not found\r\n");
        boot_info.rsdp_addr = 0;
    }
    return EFI_SUCCESS;
}


static UINT32 ConvertMemoryType(UINT32 efi_type) {
    switch (efi_type) {
    case EfiConventionalMemory: return 1;
    case EfiACPIReclaimMemory: return 3;
    case EfiBootServicesCode:
    case EfiBootServicesData: return 1;
    default: return 2;
    }
}

