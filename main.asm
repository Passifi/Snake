    bits 16
    org 0x100
%include "..\macros.asm"
Col equ 80
Row equ 25
Block_ASC equ 219
Green_Txt equ 0x0a00 
%macro SetChar 2  
  push ax
    push ds 
    mov bx, VGA_TEXT_BUFFER 
    mov ds,bx 
    call convertPosition
    mov bx,ax 
    mov ax, %1|%2 
    mov [bx],ax
    pop ds 
  pop ax 

%endm     

start:
    lea ax, timer 
    mov bx,ax 
    mov ah, 0x2c 
    int DOS_IRQ    
    mov [bx],dh 
    call clearScreen
    mov ax, 0x1010
    
.loop 
    push ax 
.timeLoop 
      mov ah, 0x2c 
      int DOS_IRQ
      mov ah,[timer]  
      push dx 
      sub dh,ah 
      cmp dh, 1  
      pop dx
      jl .timeLoop
    lea bx, timer 
    mov [bx],dh 
    pop ax 
    push ax 
    SetChar Green_Txt,Block_ASC
    pop ax 
    inc ah 
    cmp ah,24 
    jnz .loop 
    Exit

convertPosition: ; ax contains x in al and y in ah  
    push cx 
    mov cl, ah
    shl al,1 
    cmp cl,0 
    jz .endOfFunc 
    xor ah,ah
.loop: 
    add ax,160 
    dec cl 
    jnz .loop 
.endOfFunc:
    pop cx
    ret 
     
DrawLineH: ; ax contains starting position, cx should contain length  
.loop:
    SetChar Green_Txt, Block_ASC
    inc al 
    dec cx
    jnz .loop 
    ret 

DrawLineV: ; ax start (ah:y, al:x), cx: length  
  .loop 
  SetChar Green_Txt, Block_ASC
  inc ah 
  dec cx 
  jnz .loop 
  ret 


drawDiagonal:
    mov cx, 20 
    mov ah,0
    mov al,0 
.loop:
    push ax 
    call convertPosition
    mov bx,ax
    mov ax, 0x0A00|Block_ASC
    mov [bx],ax 
    pop ax 
    add ax, 0x0101 
    dec cx 
    jnz .loop
    ret

clearScreen:
  push ds 
    push bx 
      mov bx, VGA_TEXT_BUFFER 
      mov ds,bx 
    pop bx
    push cx
      push ax 
        mov ax, VGA_TEXT_BUFFER
        mov es, ax 
        mov cx, 80*25 
        mov ax, 0 
        mov di, ax 
        mov ax, 0x0 
        rep stosw
      pop ax
    pop cx 
  pop ds 
  ret 
 
.data:
  QHead: dw 0x000  
  QTail: dw 0x000 
  SnakeQueue: dw 0x000
  Vector: db -1,0 
  Pos: dw 0x1010
  timer: db 0x00 
