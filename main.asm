    bits 16
    org 0x100
%include "macros.asm"
Up_Key equ 72 
Right_Key equ 77 
Left_Key equ 75 
Down_Key equ 80
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
    call InstallKB 
    call clearScreen
    mov ax, 0x0010
    push ax  
.loop:
    pop ax
    call WaitFrame 
    mov bx,[Vector]
    add ah,bh 
    add al,bl
    push ax
    SetChar Green_Txt,Block_ASC
    mov al,[controlByte]
    
    cmp al, Right_Key
    jnz .leftTest
    mov byte [controlByte],0
    mov word [Vector],0x0001 
    
    jmp .loop
.leftTest:
  cmp al, Left_Key
  jnz .UpTest 
  mov byte [controlByte],0
  mov word [Vector],0x00ff
  jmp .loop
.UpTest:
  cmp al, Up_Key
  jnz .DownTest
  mov byte [controlByte],0
  mov word [Vector],0xff00
  jmp .loop
.DownTest:
  cmp al, Down_Key 
  jnz .exitTest
  mov byte [controlByte],0
  mov word [Vector],0x0100
  jmp .loop
.exitTest:
    mov al,[Quit] 
    cmp al,1
    jnz .loop
    call RestoreKB
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
  .loop:
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

WaitFrame:	
    push ax
    PUSH	DX
		; port 0x03DA contains VGA status
		MOV	DX, 0x03DA
.waitRetrace:	IN	AL, DX	
					; read from status port
		; bit 3 will be on if we're in retrace
		TEST	AL, 0x08			; are we in retrace?
		JNZ	.waitRetrace
		
.endRefresh:	IN	AL, DX
		TEST	AL, 0x08			; are we in refresh?
		JZ	.endRefresh
		POP DX
    pop ax
		RET

%include "c:\libs\kb.asm"
.data:
  QHead: dw 0x000  
  QTail: dw 0x000 
  Vector: dw 0x0100 
  Pos: dw 0x1010
  timer: db 0x00
  SnakeQueue: times 80*25 dw 0x00

