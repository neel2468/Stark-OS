#include <efi.h>
#include <efidef.h>

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    EFI_INPUT_KEY Key;
    UINTN Index;
    SystemTable->ConOut->OutputString(SystemTable->ConOut, L"Hello from UEFI!\r\n");
    SystemTable->ConOut->OutputString(SystemTable->ConOut, L"Press any key to exit...\r\n");
    
    SystemTable->ConIn->Reset(SystemTable->ConIn, FALSE);
    
    while (SystemTable->ConIn->ReadKeyStroke(SystemTable->ConIn, &Key) != EFI_SUCCESS);
    
    return EFI_SUCCESS;
}
