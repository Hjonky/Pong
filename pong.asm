[bits 16]
[org 0x7c00]

start:
    ; Set up CPU Environment 
    xor ax, ax      ; Set AX to 0
    mov ds, ax      ; Point Data Segment to 0 
    mov ss, ax      ; Point Stack Segment to 0
    mov sp, 0x7C00  ; Point Stack Pointer safely below our boot sector

    ; Switch to VGA mode 13h (320x200 graphics)
    mov ax, 0x0013
    int 0x10

    ;Point ES to VGA video memory (0xA000)
    mov ax, 0xA000
    mov es, ax

    ; Draw a white pixel at the center (offset 32160)
    mov di, 32160   ; Starting offset (center screen)
    mov al, 15      ; Color 15 (white)

    

game_loop:
    ; Infinite loop to keep the game running

; Following section limits frame rate of the game to 50 fps
    mov ah, 0x86    ; BIOS WAIT
    ; Wait for 4E20 microseconds which is 20,000 in decimal
    mov cx, 0x00
    mov dx, 0x4E20

    ; Trigger wait
    int 0x15

; Erase all
    mov si, 0        
    call DrawAll

; User input
    ; Check if key is pressed
    mov ah, 0x01
    int 0x16
    jz no_key

    ; Read key
    mov ah, 0x00
    int 0x16

    ; Check for 'w' or 's'
    cmp al, 'w'
    je move_up
    cmp al, 's'
    je move_down
    jmp player_2
    
    move_up:
        sub word [paddle_y], 10
        jmp no_key

    move_down:
        add word [paddle_y], 10
        jmp no_key

    player_2:
    cmp ah, 0x48 ; arrow up
    je move_up2
    cmp ah, 0x50 ; arrow down
    je move_down2
    jmp no_key

    move_up2:
        sub word [paddle_y2], 10
        jmp no_key

    move_down2:
        add word [paddle_y2], 10

    no_key:

; Calulate left paddle collisions
    mov ax, [paddle_y]
    cmp ax, 0
    jle cap_top
    cmp ax, 170
    jge cap_bottom
    jmp right_collision

    cap_top:
        mov word [paddle_y], 0
        jmp right_collision
    cap_bottom:
        mov word [paddle_y], 170  

; Calulate right paddle collisions
    right_collision:
    mov ax, [paddle_y2]
    cmp ax, 0
    jle cap_top2
    cmp ax, 170
    jge cap_bottom2
    jmp move_ball

    cap_top2:
        mov word [paddle_y2], 0
        jmp move_ball
    cap_bottom2:
        mov word [paddle_y2], 170 

; Move ball
    move_ball:
    mov ax, [ball_vx]
    add [ball_x], ax
    mov ax, [ball_vy]
    add [ball_y], ax

; Collision check y
    mov ax, [ball_y]
    cmp ax, 0
    jle flip_y

    cmp ax, 196
    jge flip_y
    jmp x_check

    flip_y:
    neg word [ball_vy]

; Collision check x
    x_check:
    mov ax, [ball_x]
    cmp ax, 0
    jle flip_x
    cmp ax, 316
    jge flip_x
    jmp paddle_collison

    flip_x:
    neg word [ball_vx]

; Collision check left paddle paddle
    paddle_collison:
        mov ax, [ball_y]
        add ax, 4
        mov bx, [paddle_y]
        cmp ax, bx
        jl paddle_collison2

        mov ax, [ball_y]
        mov bx, [paddle_y]
        add bx, 30
        cmp ax, bx
        jg paddle_collison2

        mov ax, [ball_x]
        mov bx, [paddle_x]
        add bx, 4
        cmp ax, bx
        jg paddle_collison2

        mov ax, [ball_x]
        add ax, 4
        mov bx, [paddle_x]
        cmp ax, bx
        jl paddle_collison2
        mov word [ball_vx], 2
        jmp draw_all

; Collision check left paddle paddle
    paddle_collison2:
        mov ax, [ball_y]
        add ax, 4
        mov bx, [paddle_y2]
        cmp ax, bx
        jl draw_all

        mov ax, [ball_y]
        mov bx, [paddle_y2]
        add bx, 30
        cmp ax, bx
        jg draw_all

        mov ax, [ball_x]
        mov bx, [paddle_x2]
        add bx, 4
        cmp ax, bx
        jg draw_all

        mov ax, [ball_x]
        add ax, 4
        mov bx, [paddle_x2]
        cmp ax, bx
        jl draw_all
        mov word [ball_vx], -2


; Draw all
    draw_all:
    mov si, 15         
    call DrawAll

    jmp game_loop

; This procedure calculates the offset for each object
; Input: ax - y coords, bx - x coords
; Output: set DI to correct offset
Offset:
    push cx
    mov cx, 320
    mul cx             
    add ax, bx         
    mov di, ax

    pop cx
    ret

; This procedure draws for each object
; Input: si - color, cx - height, ax - y coords, bx - x coords
; Output: *visual*
Draw:
    call Offset
    push ax
    mov ax, si

    row_loop:
        push cx
        mov cx, 4
        rep stosb
        add di, 316
        pop cx
        loop row_loop
    pop ax
    ret

; This procedure every object
; Input: si - color
; Output: *visual*
DrawAll:
    ;left Paddle
    mov ax, [paddle_y]
    mov bx, [paddle_x]
    mov cx, 30
    call Draw
    ;Right paddle
    mov ax, [paddle_y2]
    mov bx, [paddle_x2]
    mov cx, 30
    call Draw
    ;Ball
    mov ax, [ball_y]
    mov bx, [ball_x]
    mov cx, 4
    call Draw
    ret

; Variables to keep track of coords
ball_x dw 160    ; Start at center X
ball_y dw 100    ; Start at center Y

; Variables to keep track of ball speed
ball_vx dw 2
ball_vy dw 2

; Variables to keep track of the paddles coords
paddle_y dw 85     ; Centered vertically
paddle_x dw 10     ; 10 pixels from the left edge
paddle_y2 dw 85    ; Centered vertically
paddle_x2 dw 306     ; 10 pixels from the right edge

; Pad to 512 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55