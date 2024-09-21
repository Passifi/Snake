    %include "macros.asm"

    BITS 16
toChar:

    calleeSetup 1 
    push ax
    push bx 
    push cx 
    push dx 
    getPar ax, 1 

    mov bx,10 
    mov cx, 0 
    mov dx,0 
.divLoop:
    inc cx 
    PUSH AX 

    POP AX
    div bx ; al has the result and ah has the remainder 
    push dx
    xor dx,dx    
    cmp ax,0 
    jnz .divLoop

.writeLoop:
    pop ax
    add al, 48 
    mov dl,al 
    mov ah, DOS_STD_OUT_CHR
    int DOS_IRQ
    dec cx 
    jnz .writeLoop

    mov ah, DOS_WAIT_FOR_KEY_CMD
    int DOS_IRQ 
    mov ah,DOS_EXIT_CMD
    int DOS_IRQ

    pop dx 
    pop cx 
    pop bx 
    pop ax
    calleeDone  
    ret 
