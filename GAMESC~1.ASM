;------------------------------------------
; PURPOSE : draw the main game screen 
; SYSTEM  : Turbo Assembler Ideal Mode  
; AUTHOR  : Itay Benvenisti    
;------------------------------------------

		IDEAL
		
		MODEL small

MACRO HORIZONTAL_LINE x1,y1,x2,y2,color
                local L1
                mov cx,[x2]
                sub cx,[x1] ; get the length of the line
                mov ax,[x1]
                mov [x],ax
                mov ax,[y1]
                mov [y],ax
L1:
                push cx
                DRAWPIXEL x,y,color
                inc [x]
                pop cx
                loop L1

ENDM HORIZONTAL_LINE

MACRO VERTICAL_LINE x1,y1,x2,y2,color
                local L1
                mov cx,[y2]
                sub cx,[y1]
                mov ax,[x1]
                mov [x],ax
                mov ax,[y1]
                mov [y],ax
L1:
                push cx
                DRAWPIXEL x,y,color
                inc [y]
                pop cx
                loop l1

ENDM VERTICAL_LINE

MACRO DRAWPIXEL x,y,color
                mov bh,0
                mov cx, [x]
                mov dx, [y]
                mov al, [color]
                mov ah,0ch
                int 10h
ENDM DRAWPIXEL


		STACK 256
                pic_width equ 3
                pic_height equ 3
                DATASEG

                color db ?
                x1    dw ? ; starting x
                y1    dw ? ; starting y
                x2    dw ? ; ending x (x1 < x2)
                y2    dw ? ; ending y (y2 = y1)
                x     dw ? ; the x at the moment
                y     dw ? ; the y at the moment
                h_times db 3
                v_times db 3
                clear_screen dw 320*200
		CODESEG
Start:
        mov ax, @data
        mov ds, ax
        mov ax,13h
        int 10h  ;-- graphic mode

        call FILL_SCREEN 
        mov [x1], 0
        mov [y1], 50d
        mov [x2], 320d
        mov [color], 0

Lh2:
        HORIZONTAL_LINE x1,y1,x2,y1, color
        add [y1], 50d
        dec [h_times]
        cmp [h_times], 0
        jne Lh2

        mov [x1], 80d
        mov [y1],0d
        mov [y2],200d
        

lv2:
        VERTICAL_LINE x1,y1,x1,y2,color
        add [x1], 80d
        dec [v_times]
        cmp [v_times], 0
        jne Lv2



        ;---------- initiate mouse
        mov ax,00h
        int 33h
        ;---------- show mouse
        mov ax,01h
        int 33h

checkmouse:

        mov ax,05h
        int 33h
        shr cx,1
        mov x,cx
        mov y,dx








        mov ax,0h
        int 16h  ; wait for a keyboard input
        mov ax,03h
        int 10h ; stop the nc msg from coming up when a button is pressed
        
 

        
        
Exit:
        mov ax, 4C00h
        int 21h

PROC FILL_SCREEN

        mov [x],0
        mov [y],0
        mov [color], 2
        mov [clear_screen], 320*200
clear:
        
        DRAWPIXEL x,y,color
        
        inc [x]
        cmp [x], 320
        jne x_not_320
        mov [x], 0
        inc [y]
x_not_320:

        dec [clear_screen]
        cmp [clear_screen], 0
        jne clear
        ret

ENDP FILL_SCREEN

END start

