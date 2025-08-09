org 0x7C00
bits 16

;setup stack
entry:
    mov ax,0
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,7C00h

   ;Step 1: disable interrupts 
   cli
   ;Step 2: Enable A20 gate
   call EnableA20
   ;Step 3 Load GDT
   call LoadGDT
   ;Step 4: switch to protected mode
   mov eax,cr0
   or al,1
   mov cr0,eax

   ;Step 5: Far jump to protected mode
   jmp dword 08h:.pmode


.pmode:
    [bits 32]
    ;step 6: setup segment registers
    mov ax, 0x10
    mov ds,ax
    mov ss,ax

    ;print text on screen
    mov esi, g_Hello_Protected_Mode
    mov edi, ScreenBuffer
    cld

.loop:
    lodsb
    or al,al
    jz .done

    mov [edi],al
    inc edi
    mov [edi], byte 0x2
    inc edi
    jmp .loop



.done:
    ;go back to real mode
    jmp word 18h:.pmode16


.pmode16:
    [bits 16]
    ;disable protected mode bit in cr0
    mov eax,cr0
    and al, ~1
    mov cr0,eax

    ;jump to real mode
    jmp word 00h: .rmode

.rmode:
    ;setup segments
    mov ax,0
    mov ds,ax
    mov es,ax
    mov ss,ax

    ;enable interrupts
    sti
    ;test print from real mode
    mov si, g_Hello_Real_Mode

.rloop:
    lodsb
    or al,al
    jz .rdone
    mov ah, 0eh
    int 10h
    jmp .rloop


.rdone:



.halt:
    jmp .halt
 



EnableA20:
    [bits 16]
    ;disable keyboard
    call A20WaitInput
    mov al,kbdControllerDisableKeyboard
    out kbdControllerCommandPort, al

    ;read control output port
    call A20WaitInput
    mov al, kbdControllerReadCtrlOutputPort
    out kbdControllerCommandPort,al

    call A20WaitOutput
    in al,kbdControllerDataPort
    push eax

    ;write control output port
    call A20WaitInput
    mov al,kbdControllerWriteCtrlOutputPort
    out kbdControllerCommandPort,al

    call A20WaitInput
    mov al, kbdControllerWriteCtrlOutputPort
    out kbdControllerCommandPort,al

    call A20WaitInput
    pop eax
    or al,2
    out kbdControllerDataPort, al

    ;enable keyboard
    call A20WaitInput
    mov al,kbdControllerEnableKeyboard
    out kbdControllerCommandPort,al

    call A20WaitInput
    ret


LoadGDT:
    [bits 16]
    lgdt [g_GDTDesc]
    ret



A20WaitInput:
    [bits 16]
    ;wait until status bit 2(input buffer) is 0 
    in al,kbdControllerCommandPort
    test al,2
    jnz A20WaitInput
    ret 

A20WaitOutput:
    [bits 16]
    ;wait until status bit 1(output buffer) is 1 so it can be read
    in al,kbdControllerCommandPort
    test al,1
    jz A20WaitOutput
    ret





kbdControllerDataPort                   equ 0x60
kbdControllerCommandPort                equ 0x64
kbdControllerDisableKeyboard            equ 0xAD
kbdControllerEnableKeyboard             equ 0xAE
kbdControllerReadCtrlOutputPort         equ 0xD0
kbdControllerWriteCtrlOutputPort        equ 0xD1

ScreenBuffer                            equ 0xB8000


g_GDT:
    ;NULL Descriptor
    dq 0
    ;32-bit code segment
    dw 0FFFFh           ;limit(bit 0-15) = 0xFFFFF for full 32-bit range
    dw 0                ;base(bits 0-15) = 0x0
    db 0                ; base(bits 16-23)
    db 10011010b        ;access(present,ring 0,code segment,executable,direction 0,readable)
    db 11001111b       ;granularity(4k pages, 32-protected mode) + limit(bits 16-19)
    db 0               ; base high 

    ; 32-bit data segment
    dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
    dw 0                        ; base (bits 0-15) = 0x0
    db 0                        ; base (bits 16-23)
    db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
    db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
    db 0                        ; base high

    ; 16-bit code segment
    dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
    dw 0                        ; base (bits 0-15) = 0x0
    db 0                        ; base (bits 16-23)
    db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
    db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
    db 0                        ; base high

    ; 16-bit data segment
    dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
    dw 0                        ; base (bits 0-15) = 0x0
    db 0                        ; base (bits 16-23)
    db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
    db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
    db 0                        ; base high


g_GDTDesc: dw g_GDTDesc - g_GDT - 1     ;limit = size of GDT
           dd g_GDT

g_Hello_Protected_Mode:   db "Hello World from protected mode", 0
g_Hello_Real_Mode:        db "Hello world from real mode",0

times 510-($-$$) db 0
dw 0AA55h