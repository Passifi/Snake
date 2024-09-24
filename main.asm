    bits 16
    org 0x100
%include "macros.asm"
FrameCounter equ 65535 
Up_Key equ 72 
Right_Key equ 77 
Left_Key equ 75 
Down_Key equ 80
Col equ 80
Row equ 25
Block_ASC equ 219
Green_Txt equ 0x0a
Max_Queue equ 80*20
%macro SetChar 2  
  push ax
  push bx 
  push ds 
    mov bx, VGA_TEXT_BUFFER 
    mov ds,bx 
    call convertPosition
    mov bx,ax
    mov ah, %2  
    mov byte al, %1 
    mov [bx],ax
  pop ds 
  pop bx
  pop ax 

%endm     

start:
    call InstallKB 
    call clearScreen
    mov byte [timer],0
    call spawnNewFruit
    mov ax, 0x0010
    mov cx,ax 
    call Enqueue 
    SetChar [Color], Block_ASC
    mov ax,cx 
    inc ax 
    mov cx,ax 
    call Enqueue 
    SetChar [Color], Block_ASC
    mov ax,cx 
    inc ax 
    mov cx,ax 
    call Enqueue 
    SetChar [Color], Block_ASC
    mov ax,cx
    push ax
.loop:
    pop ax
.waitLoop: 
    add word [timer],1
    cmp word [timer],FrameCounter 
    jnz .waitLoop
    mov word [timer],0
    mov bx,[Vector]
    add ah,bh 
    add al,bl
    call collisionDetection
    cmp dx,0xff 
    jz .endGame
      push ax
    push dx 
      mov cx, ax 
    
      call WaitFrame 
      call Enqueue 
      SetChar [Color],Block_ASC
    pop dx 
    cmp dx, 0x10
    mov dx,0 
    jz .continueOver
    call Dequeue
    mov ax,cx 
    SetChar 0x00,0x00
.continueOver:
    mov al,[controlByte]
.rightTest: 
    cmp al, Right_Key
    jnz .leftTest
    mov byte [controlByte],0
    cmp word [Vector],0x00ff
    jz .loop 
    mov word [Vector],0x0001 
    jmp .loop
.leftTest:
  cmp al, Left_Key
  jnz .UpTest 
  mov byte [controlByte],0
  cmp word [Vector],0x0001
  jz .loop  
  mov word [Vector],0x00ff
  jmp .loop
.UpTest:
  cmp al, Up_Key
  jnz .DownTest
  mov byte [controlByte],0 
  cmp word [Vector],0x0100 
  jz .loop 
  mov word [Vector],0xff00
  jmp .loop
.DownTest:
  cmp al, Down_Key 
  jnz .exitTest
  mov byte [controlByte],0
  cmp word [Vector],0xff00
  jz .loop 
  mov word [Vector],0x0100
  jmp .loop
.exitTest:
    mov al,[Quit] 
    cmp al,1
    jnz .loop
.endGame:
    call RestoreKB
    cls 
    mov word ax, [Score]
    push ax  
    call toChar 
    Exit

collisionDetection:
  push ax
  push bx 
  push ds
  push cx
  push es 
  mov bx,ds 
  mov es,bx 
  cmp ah, 0 
  jl .setDead 
  cmp al, 0 ; al x ah y    
  jl .setDead
  cmp al,79 
  jge .setDead
  cmp ah,24 
  jge .setDead
  jmp .collisionTest 
.setDead: 
  mov dx, 0xff 
  jmp .endOfFunc
.collisionTest:
  call convertPosition
  mov cx, VGA_TEXT_BUFFER 
  mov ds, cx 
  mov bx, ax
  mov word ax, [bx]
  cmp al, Block_ASC
  jnz .fruitTest 
  mov dx, 0xff
  jmp .endOfFunc
.fruitTest:
  cmp al, 'o' 
  jnz .endOfFunc
  mov ax,es 
  mov ds,ax 
  add word [Score],0x00A0 
  call spawnNewFruit 
  mov dx, 0x10
.endOfFunc:
  pop es 
  pop cx
  pop ds 
  pop bx
  pop ax
  ret

spawnNewFruit:
  push ax 
  push bx 
  push cx 
  push dx 
  call generateCoordinates
  call convertPosition 
  SetChar Green_Txt, 'o' 
  pop dx 
  pop cx 
  pop bx 
  pop ax 
  ret

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

generateCoordinates:
    push bx 
    push cx
    push dx 
    Dos_Int DOS_GET_TIME 
    mov cx,dx 
    mov dl, ch 
    xor ax,ax 
    mov al,dl 
    mov bx,80 
    div bl 
    mov dl,ah 
    mov cl,dl 
    xor ax,ax 
    mov al,dh
    mov bx, 20  
    div bl  
    mov dl,ah 
    mov ch,dl 
    mov ax,cx
    pop dx 
    pop cx 
    pop bx
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

Enqueue: ; I need callee for this but right now we jsut say dx contains the value 
  push ax 
  push bx 
  mov bx, SnakeQueue 
  mov word ax, [QHead] 
  cmp ax, Max_Queue
  jnz .continue
  mov ax,0 
.continue:
  shl ax,1 
  add bx, ax 
  mov [bx],cx 
  add word [QHead],1 
  pop bx 
  pop ax
  ret 
Dequeue: 
  push ax 
  push bx 
  mov bx, SnakeQueue 
  mov word ax, [QTail]
  cmp ax,[QHead]
  jz .retArea
  shl ax,1 
  add bx, ax 
  mov cx,[bx]
  add word [QTail],1 
.retArea:
  pop bx 
  pop ax 
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
%include "tochar.asm" 
  ;Variables 
.data:
  Color: db 0x03
  Score: dw 0x0000
  QHead: dw 0x000  
  QTail: dw 0x000 
  Vector: dw 0x0100 
  Pos: dw 0x1010
  timer: dw 0x00
  SnakeQueue: times 80*25 dw 0x00

