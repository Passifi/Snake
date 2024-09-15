SCREEN_WIDTH equ 320 
SETCOLORREGISTER_CMD equ 0x1010
SetColorRegisterBlock equ 0x1012 
VGA_SCREEN_MEMORY equ 0xA000
VGA_TEXT_BUFFER equ 0xB800
VGA_STATUS_PORT equ 0x03DA
VGA_RETRACE equ 0x08
VGA_IRQ equ 0x10 
VGA_TEXT_MODE equ 0x03 
MODE_13 equ 0x0013
DOS_WAIT_FOR_KEY_CMD equ 0x07
DOS_STD_OUT_CHR equ 0x02 ;use DL for character value 
DOS_EXIT_CMD equ 0x4c
DOS_MEM_ALLOC_CMD equ 0x48 ; bx number of paragraphs (16bytes) ax has the segment address
DOS_FREE_MEM_CMD equ 0x49 
DOS_GET_INT_VEC equ 0x00
DOS_SET_INT_VEC equ 0x25 ; AL carries the int number and DS:DX should contain the interrupt handler 

DOS_IRQ equ 0x21 
DOS_READ_FILE equ 0x3f  ; BX files handle, cx number of byte to read ;ds:dx address buffer
DOS_OPEN_FILE equ 0x3d00 ; al access control ah irq request, ds:dx pointer to filename
OPEN_ACCESS_READWRITE equ 0x02 ; 

KB_PORT equ 0x60
KB_ACK equ 0x20
%macro Exit 0 
    mov ah, DOS_EXIT_CMD
    int DOS_IRQ
%endm 

%macro Free 0 
    mov es, ax 
    mov ah, DOS_FREE_MEM_CMD
    int DOS_IRQ
%endm 

%macro cls 0
    mov ah, DOS_STD_OUT_CHR 
    mov dl, 27 
    int DOS_IRQ
    mov dl,'[' 
    int DOS_IRQ
    mov dl,'2' 
    int DOS_IRQ 
    mov dl,'J' 
    int DOS_IRQ
%endm 