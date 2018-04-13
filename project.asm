
;------------------------------------------
; PURPOSE : assembly project FINAL MISSION
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
		p386
;-----------------=constant variables=----------------;
								ESC_KEY             equ 1
								NUMBER_ONE          equ 2
								NUMBER_TWO          equ 3
								NUMBER_THREE        equ 4
								NUMBER_FOUR         equ 5
								LEFT_ARROW          equ 4bh
								UP_ARROW            equ 48h
								RIGHT_ARROW         equ 4dh
								DOWN_ARROW          equ 50h
								ENTER_KEY           equ 1ch

								screen_RAM_text     equ 0B800h
								graphic_mode_offset equ 0A000h

								cursor_width        equ 5
								cursor_height       equ 5
								FreeFallChar_width  equ 8
								FreeFallChar_height equ 12
								cube_width          equ 80
								cube_height         equ 50

								difficultyX1        equ 60
								difficultyY1        equ 26
								difficultyX2        equ 60
								difficultyY2        equ 90
								difficultyX3        equ 60
								difficultyY3        equ 154

                DATASEG
;---------------------=variables=---------------------;
                x1            dw ? ; starting x
                y1            dw ? ; starting y
                x2            dw ? ; ending x (x1 < x2)
                y2            dw ? ; ending y (y2 = y1)
                h_times       db 3
                v_times       db 3
                clear_screen  dw 320*200
                column_number dw ?
                row_number    dw ?
                cancelled     dw 0000000000000000b ; each bit is a cube (1 if cancelled 0 if not)
                letters       db "abcdefghijklmnopqrstuvwsyz"
								rndrange      db ?
								rnd           dw ? ; rnd is word size because of some calculation error caused by si (refer to proc CLICKER_GAME)
				        counter       db ?
								cube          db ?
								bomb          db ?
								temp          db ?
								tempWord      dw ?
;----------------------=difficulty=---------------------;
								difficulty    db 0
								tries         db ?
								clickerCountOffset db ?
								freeFallSpeed dw ?
						    freeFallCounter db ?
;-----------------------=bitmaps-----------------------;
								cursor        db 000,004,004,004,000
															db 004,043,095,043,004
															db 004,095,095,095,004
															db 004,043,095,043,004
															db 000,004,004,004,000

								freeFallChar  db 000,000,000,000,022,000,000,000
															db 000,000,000,000,000,022,000,000
															db 000,000,000,000,000,022,000,000
															db 000,000,000,000,022,000,000,000
															db 000,000,004,004,004,004,040,000
															db 000,000,004,004,004,040,040,000
															db 000,000,004,004,040,040,040,000
															db 000,000,004,040,000,040,040,000
															db 000,000,040,000,040,000,040,000
															db 000,000,040,040,000,040,004,000
															db 000,000,040,040,040,004,004,000
															db 000,000,040,040,040,004,004,000
								bottomX       dw ?
								bottomY       dw ?
								rightX        dw ?
								rightY        dw ?
								leftX         dw ?
								pic_width     dw ?
							  pic_height    dw ?
								bitmapcopy    db 12*8 dup (?)
;---------------=variables for PCX usage=-------------;
								File2         db "defus.pcx"
								File4         db "loses.pcx"
								File5         db "maze1.pcx"
								File6         db "maze2.pcx"
								File7         db "maze3.pcx"
								File8         db "maze4.pcx"
								File9         db "maze5.pcx"
								File11        db "menus.pcx"
								File13        db "start.pcx"
								File14        db "guide.pcx"
								File15        db "nplay.pcx"
								File16        db "mazet.pcx"
								File17        db "bombg.pcx"
								File18        db "bomb1.pcx"
								File19        db "level.pcx"
								File20        db "click.pcx"
;---------------------------------------------- deleted 1,3,10 and 12
								x             dw ? ; the x at the moment
                y             dw ? ; the y at the moment
								FileName      db 10 dup (?)
								FileHandle    dw ?
								FileSize      dw ?
								PCXErrorMSG   db "PCX ERROR$"
								ImageWidth    dw ?
								ImageHeight   dw ?
								StartX        dw ?
								StartY        dw ?
								color         db ?

                CODESEG

Start:
        mov ax, @data
        mov ds, ax
				mov [rndrange], 16
				call rndgen
				mov bx, [rnd]
				mov [bomb], bl
;--------------------------- put the BOMB in a random cube
start2:
        mov ax,13h
        int 10h
;--------------------------- graphic mode
				mov ax,00h
				int 33h
;--------------------------- initiate mouse
				call MAIN_MENU
;--------------------------- the menu of the game
gameloop:
				call GAMESCREEN
				mov ax, 01
				int 33h
;---------------------------------- draw the cubes and the cancelled cubes
checkmouse:         ; check where the left mouse button is pressed
        mov ax, 5h
        int 33h
        cmp bx, 1b
        jne checkmouse
        shr cx,1
        mov [x],cx
        mov [y],dx
;--------------------------- get the x and y of the mouse press
        mov ax, [x]
        xor dx, dx
        mov cx, 80
        div cx
        mov [column_number], ax
;--------------------------- move to row_number the row of the button press
        mov ax, [y]
        xor dx, dx
        mov cx, 50
        div cx
        mov [row_number], ax
;--------------------------- move to column_number the column of the button press
				mov bx, [column_number]
				shl [row_number], 2 ; [rown_number] * 4
			  add bx, [row_number]
				mov [cube], bl ; in [cube] -> a number (0 - 15) that resembels a cube:
;--------------------------- find the area the mouse pressed in accordingly by y * length + x:
;--------------------------- ==========================
;--------------------------- =    0    1    2    3    =
;--------------------------- =    4    5    6    7    =
;--------------------------- =    8    9    10   11   =
;--------------------------- =    12   13   14   15   =
;--------------------------- ==========================
				mov bx, [cancelled]
			  mov cl, [cube]
				inc cl
				shr bx, cl
				jc checkmouse
;--------------------------- check if the [cube] is cancelled
				mov ax, 02
			  int 33h
;-------------------------- hide cursor
				cmp [tries], 0
				jne NotLastTry
				mov cl, [cube]
				cmp cl, [bomb]
				jne Exit
;-------------------------- check for the last try if the cube is the bomb, if not the player failed
NotLastTry:
				call GAMECHOOSER
				dec [tries]
				jmp gameloop
Exit:
        mov ax, 4C00h
        int 21h

PROC GAMESCREEN

       mov [color], 02
       mov [x],0
       mov [y],0
       mov [clear_screen], 320*200
			 call FILL_SCREEN
			 call DETECTCANCELLEDCUBE
			 mov [x1], 0
			 mov [y1], 50d
			 mov [x2], 320d
			 mov [color], 0
			 mov [h_times], 3
			 mov [v_times], 3
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
			mov ax,01h
			int 33h
;---------------------- show mouse
			ret

ENDP GAMESCREEN

PROC FILL_SCREEN
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

PROC CLICKER_GAME
				mov [StartX], 0
				mov [StartY], 0
				mov cx, 9
				mov si, 0
@@loop1:
				mov ah, [File20 + si]
				mov [FileName + si], ah
				inc si
				loop @@Loop1

				call DrawPCX
;---------------------------- draw the click.pcx
				mov [rndrange], 20
				call rndgen
				mov bl, [clickerCountOffset]
				xor bh,bh
				add [rnd], bx ; get a rndnum between 20 - 40(0 + 20 = 20; 1+ 20 = 21 etc.)
				mov bx, [rnd]
				mov [counter], bl ; reset counter
@@retry:
				mov [rndrange],26
				call rndgen
        mov ah, 02h
        mov dl, (40/2) - 1 ; row
				mov dh, 24/2  + 2  ; column
        xor bx, bx
        int 10h
;------------------------- set cursor position
				cmp [rnd], 17
				je @@retry
        lea si, [letters]
        add si, [rnd]
        mov al, [byte si] ; get a random letter
        mov ah, 09h ; interrupt entry
        xor bh,bh
        mov bl, 15
        mov cx, 1
        int 10h
;------------------------- print the letter
@@loop:
				cmp [counter], 0
				je @@end
				mov ah, 8h
				int 21h
	  		mov cl, [byte rnd]
				add cl, 61h
				cmp al, cl
				jne @@loop
				dec [counter]
				jmp @@loop
;------------------------- check if letter was clicked the required amount of times
@@end:
        ret

ENDP CLICKER_GAME

PROC MAZE_GAME
;-------------------------------------------------------------
; maze_game - a maze game
;-------------------------------------------------------------
; Input:
; n/a
; Output:
; the maze screen, cx <- the amount of cubes to cancel
; Registers
;	 AX(restored) , bl
;------------------------------------------------------------
				mov [StartX], 0
				mov [StartY], 0
				mov cx, 9
				mov si, 0
				@@loop1:
				mov ah, [File16 + si]
				mov [FileName + si], ah
				inc si
				loop @@Loop1

				call DrawPCX

				xor ah, ah
				int 16h
;----------------------------------- print the maze guide
				mov [rndrange], 5
				call rndgen
				mov [startx], 0
				mov [starty], 0
				mov cx, 9
				mov si, 0
				mov [rndrange], 5
				call rndgen
@@again:
				cmp [rnd], 0
				jne @@n1
				mov ah, [file5 + si]
				mov [FileName + si], ah
				inc si
@@n1:
				cmp [rnd], 1
				jne @@n2
				mov ah, [file6 + si]
				mov [FileName + si], ah
				inc si
@@n2:
				cmp [rnd], 2
				jne @@n3
				mov ah, [file7 + si]
				mov [FileName + si], ah
				inc si
@@n3:
				cmp [rnd], 3
				jne @@n4
				mov ah, [file8 + si]
				mov [FileName + si], ah
				inc si
@@n4:
				cmp [rnd], 4
				jne @@n5
				mov ah, [file9 + si]
				mov [FileName + si], ah
				inc si
@@n5:
				loop @@again

				call DrawPCX
;------------------- draw the maze on the screen
			  mov ax, 0004h
				xor cx,cx
				xor dx,dx
				int 33h
				mov ax, 1h
				int 33h
;------------------- show mouse and set position to 0,0
@@checkMouse:
				mov ax, 3h
				int 33h ; get cursor position (dx = row, cx = column)
				shr cx, 1
			  dec cx ; the cursor postion is actually ON the tip of the cursor,
				dec dx ;  so i'll use the top left one above the cursor read
				mov bx, graphic_mode_offset
				mov es, bx ; graphic_mode_offset
				mov si, dx
				shl dx, 8
				shl si, 6
				add si, dx
				add si, cx ; si <- offset es:si <- point
				mov bl, [byte es:si]
				mov [color], bl ; color <- the color of the mouse position
				cmp [color], 4d
				je @@win
				cmp [color], 15d
				je @@fail
				jmp @@checkMouse
;------------------- find the mouse color and check for collision
@@fail:
				mov cx, 0
				mov ax, 2
				int 33h
;--------------------- hide mouse (causes mouse background to go to the cube screen)
				ret
@@win:
				mov cx, 3
				mov ax, 2
				int 33h
;--------------------- hide mouse (causes mouse background to go to the cube screen)
				ret
ENDP MAZE_GAME

PROC FREEFALL_GAME
				mov [color], 0
        mov [x], 0
        mov [y],0
        mov [clear_screen], 320*200
				call FILL_SCREEN
;---------------------------- clear the screen
				mov al, [freeFallCounter]
				push ax
				mov [startx], 320 / 2 - FreeFallChar_width / 2
				mov [starty], 0
				mov [pic_width], FreeFallChar_width
				mov [pic_height], FreeFallChar_height
				xor si,si
				mov cx, FreeFallChar_width * FreeFallChar_height
CopyFreeFallChar:
				mov dl, [freeFallChar + si]
				mov [bitmapcopy + si], dl
				inc si
				loop CopyFreeFallChar
				call bitmap
;------------------------------- draw the bitmap in the starting location
				mov [bottomX], 320 / 2
				mov [bottomY], FreeFallChar_height + 1
				mov [rightX], 320 / 2 + FreeFallChar_width / 2 + 1
				mov [rightY], FreeFallChar_height / 2
				mov [leftX], 320 / 2 - FreeFallChar_width / 2 - 1
				;mov [leftY], FreeFallChar_height / 2 no need leftY = rightY
;------------------------------- set the starting locations for the pixels that are checked for collision
@@newLine:
				mov [y], 200d
				mov [rndrange], 100d
				call rndgen
				add [rnd], 100d
				mov dx, [rnd]
;--------------------------- random (100 - 200) this is the place the hole starts
				mov [rndrange], 50
				call rndgen
				add [rnd],30
;-------------------------- random (30 - 80) this is the width of the hole
@@start:
				mov [color], 15d ; white
				mov [x],0
;---------------------------- setup
@@Cycle:
				cmp dx, [x]
				jne @@noSkip
				mov cx, [rnd]
@@skip:
				inc [x]
				call checkcollision
				cmp [temp], 1
				je @@end
				loop @@skip
@@noSkip:
				call PutPixel
				call checkcollision
				cmp [temp], 1
				je @@end
			  inc [x]
				cmp [x], 319d
				jne @@cycle
				mov cx, [freeFallSpeed]
@@wait:
				loop @@wait
				mov [color], 0d ; black
				mov [x], 0
@@cycle2:
				call PutPixel
				call checkcollision
				cmp [temp], 1
				je @@end
				inc [x]
				cmp [x],319d
				jne @@cycle2
				call CHECKFORKEYBOARDINPUT
				dec [y]
				jnz @@start
				dec [freeFallCounter]
				jnz @@newLine
				mov cx, 3 ;for cube cancel
@@end:
				pop ax
				mov [freeFallCounter], al

				ret

ENDP FREEFALL_GAME
PROC CHECKCOLLISION

				push ax
				mov di, [bottomY]
				mov ax, [bottomY]
				shl di, 8
				shl ax, 6
				add di, ax
				add di, [bottomX]
				mov bx, graphic_mode_offset
			  mov es, bx
				mov al, [es:di]
				cmp al, 15d
				je @@collisionWithWhite
;-------------------------------- check the bottom pixel
				mov di, [rightY]
				mov ax, [rightY]
				shl di, 8
				shl ax, 6
				add di, ax
				add di, [rightX]
				mov al, [es:di]
				cmp al, 15d
				je @@collisionWithWhite
;-------------------------------- check the right pixel
				mov di, [rightY]
				mov ax, [rightY] ; rightY = leftY so no need for anoter variable
				shl di, 8
				shl ax, 6
				add di, ax
				add di, [leftX]
				mov al, [es:di]
				cmp al, 15d
				je @@collisionWithWhite
;-------------------------------- check the left pixel
				mov [temp], 0
				pop ax
				ret
;-------------------------------- no collision, return normally
@@collisionWithWhite:
				mov [temp], 1
				mov cx, 0 ; for cube cancel
				pop ax
				ret
ENDP CHECKCOLLISION
PROC CHECKFORKEYBOARDINPUT
				mov ax, [x]
				mov bx, [y]
				push ax
				push bx
				in al, 60h
				cmp al, LEFT_ARROW
				jne @@n1
				mov ax, [startX]
				add ax, FreeFallChar_width
				xor bx,bx
				mov cx, FreeFallChar_height
				mov [color], 0 ;black
				;------------------------ calculate the x,y of the point
				call retracebitmap
				dec [startx]
				dec [bottomX]
				dec [leftX]
				dec [rightX]
				call bitmap
@@n1:
				cmp al,RIGHT_ARROW
				jne @@n2
				mov ax, [startX]
				xor bx,bx
				mov cx, FreeFallChar_height
				mov [color], 0 ;black
				;------------------------ calculate the x,y of the point
				call retracebitmap
				inc [startx]
				inc [bottomX]
			  inc [leftX]
				inc [rightX]
				call bitmap
@@n2:
				pop bx
				pop ax
				mov [x], ax
				mov [y], bx
				ret
ENDP CHECKFORKEYBOARDINPUT
PROC RETRACEBITMAP
;-------------------------------------------------------------
; retracebitmap - put a black line to move a bitmap
;-------------------------------------------------------------
; Input:
; ax <- starting x, bx <- starting y, cx <- amount of pixels
; Output:
;
; Registers
;	 ax , bx, cx
;----------------------------------------------------------
@@cycle:
			mov [x],ax
			mov [y], bx
			call PutPixel
			inc [y]
			loop @@cycle
			ret

ENDP RETRACEBITMAP

PROC rndgen
;-------------------------------------------------------------
; rndgen - gets a random number betweeen 0- [rndrange]
;-------------------------------------------------------------
; Input:
; rndrange <- the range of numbers you want to randomize
; Output:
; rnd <- a random number between 0- [rndrange]
; Registers
;	 AX(restored) , bl
;----------------------------------------------------------
				push ax
				in al, 40h    ; get a random number 0-255 into al
				xor ah, ah    ; div uses ax
				mov bl, [rndrange]
				div bl        ; 26 letters
				mov [byte rnd], ah ; ah <- remainder
				pop ax
				ret

ENDP rndgen

PROC GAMECHOOSER
;-------------------------------------------------------------
; gamechooser - checks if the bomb is in the pressed cube
; true - goes into the bomb defuse game
; false - goes into a random game between the 4 available
;-------------------------------------------------------------
; Input:
; rndrange <- the range of numbers you want to randomize
; bomb     <- the cube that the bomb is in
; cube     <- the cube that the player clicked on
; Output:
; calls the cooresponding game
; Registers:
;	 bl, cx,
;------------------------------------------------------------
				mov bl, [bomb]
				cmp bl, [cube]
				jne @@NotBomb
				call BOMB_GAME ;(doesn't exist right now)
;----------------------- checks if the pressed cube has the bomb
@@NotBomb:
				mov [rndrange], 3
				call rndgen
				cmp [rnd], 0
				jne @@l1
				call CLICKER_GAME
				mov cx, 3
				jmp @@afterGame
@@L1:
			  cmp [rnd], 1
			  jne @@l2
				call MAZE_GAME
			  jmp @@afterGame
@@l2:
		    call  FREEFALL_GAME
@@afterGame:
				mov bl,[cube]
				call CANCELCUBE
				cmp cx, 0
				je @@end

;-----------------------first cancelling the chosen cube(need to cancel [cube])
@@cubeCancel:
				mov [rndrange],16
				call rndgen ; get a number between 0 - 15
				mov bx, [rnd]
				cmp bl, [cube] ; rnd can't be cube, it is already cancelled
				je @@cubecancel
				cmp bl, [bomb] ; cancelling the bomb isn't wanted
				je @@cubeCancel
				call cancelcube
				dec cx
				cmp cx, 0
				jne @@cubeCancel
;------------------------- cancel cx amount of cubes
@@end:
			  ret

ENDP GAMECHOOSER

PROC CANCELCUBE
;-------------------------------------------------------------
; cancelcube - disables the cube in bl
;-------------------------------------------------------------
; Input:
; bl
; Output:
; calls the cooresponding game
; Registers:
;	 bl, cx,
;------------------------------------------------------------
			  push cx
				mov dx, [cancelled]
				mov cl,bl ;bl = [rnd]
				inc cl ; because if the cube chosen is the first one, cl will be 0 and shr dx,cl will do nothing
				shr dx, cl
				jc @@end
;-------------------- check if the cube has already been cancelled
				mov dx, 1
				mov cl, bl ; bl = [rnd]
				shl dx, cl
				add [cancelled], dx
;-------------------- goes by the equation: [cancelled] <- [cancelled] + (shr 1, [rnd])
@@end:
				pop cx
				ret
ENDP CANCELCUBE
PROC DETECTCANCELLEDCUBE
				mov dx, [cancelled]
				shr dx,1
				jc @@cube1
@@n1:
				shr dx,1
				jc @@cube2
@@n2:
				shr dx,1
				jc @@cube3
@@n3:
				shr dx,1
				jc @@cube4
@@n4:
				shr dx,1
				jc @@cube5
@@n5:
				shr dx,1
				jc @@cube6
@@n6:
				shr dx,1
				jc @@cube7
@@n7:
				shr dx,1
				jc @@cube8
@@n8:
				shr dx,1
				jc @@cube9
@@n9:
				shr dx,1
				jc @@cube10
@@n10:
				shr dx,1
				jc @@cube11
@@n11:
				shr dx,1
				jc @@cube12
@@n12:
				shr dx,1
				jc @@cube13
@@n13:
				shr dx,1
				jc @@cube14
@@n14:
				shr dx,1
				jc @@cube15
@@n15:
				shr dx,1
				jc @@cube16
				ret

@@cube1:
				mov [x], 0
				mov [y], 0
				call FILLCUBE
				jmp @@n1
@@cube2:
				mov [x], 80
				mov [y], 0
				call FILLCUBE
				jmp @@n2
@@cube3:
				mov [x], 160
				mov [y], 0
				call FILLCUBE
				jmp @@n3
@@cube4:
				mov [x], 240
				mov [y], 0
				call FILLCUBE
				jmp @@n4
@@cube5:
				mov [x], 0
				mov [y], 50
				call FILLCUBE
				jmp @@n5
@@cube6:
				mov [x], 80
				mov [y], 50
				call FILLCUBE
				jmp @@n6
@@cube7:
				mov [x], 160
				mov [y], 50
				call FILLCUBE
				jmp @@n7
@@cube8:
				mov [x], 240
				mov [y], 50
				call FILLCUBE
				jmp @@n8
@@cube9:
				mov [x], 0
				mov [y], 100
				call FILLCUBE
				jmp @@n9
@@cube10:
				mov [x], 80
				mov [y], 100
				call FILLCUBE
				jmp @@n10
@@cube11:
				mov [x], 160
				mov [y], 100
				call FILLCUBE
				jmp @@n11
@@cube12:
				mov [x], 240
				mov [y], 100
				call FILLCUBE
				jmp @@n12
@@cube13:
				mov [x], 0
				mov [y], 150
				call FILLCUBE
				jmp @@n13
@@cube14:
				mov [x], 80
				mov [y], 150
				call FILLCUBE
				jmp @@n14
@@cube15:
				mov [x], 160
				mov [y], 150
				call FILLCUBE
				jmp @@n15
@@cube16:
				mov [x], 240
				mov [y], 150
				call FILLCUBE
				ret
ENDP DETECTCANCELLEDCUBE
PROC FILLCUBE
				mov bx, [x]
				mov [tempWord], bx
				mov [color], 4
				mov cx, cube_height
@@cycle:
				push cx
				mov cx, cube_width
@@cycle1:
				call PutPixel
				inc [X]
				loop @@cycle1
				pop cx
				inc [y]
				mov bx, [tempWord]
				mov [X], bx
				loop @@cycle
				ret

ENDP FILLCUBE
PROC MAIN_MENU
				mov [StartX], 0
				mov [StartY], 0
				mov cx, 9
				mov si, 0
@@loop1:
				mov ah, [File13 + si]
				mov [FileName + si], ah
				inc si
				loop @@Loop1

				call DrawPCX
				mov ah, 8h
				int 21h
;----------------------the first starting screen
mainloop:
				mov [StartX], 0
				mov [StartY], 0
				mov cx, 9
				mov si, 0
@@loop2:
				mov ah, [File11 + si]
				mov [FileName + si], ah
				inc si
				loop @@Loop2
				mov ax, 13h
				int 10h ; make sure graphic mode is enabled
				call DrawPCX
;---------------------- the main menu screen
				mov ah, 8h
				int 21h
				in al,060h ;--read scan code from keyboard port
	      cmp al, NUMBER_ONE
				je @@game
				cmp al, NUMBER_TWO
				je @@instructions
				cmp al, NUMBER_THREE
				je @@credits
			  cmp al, NUMBER_FOUR
				je @@quit

			  dec al
				jnz mainloop ; the scan code of ESC is 1, so 1-1=0
@@quit:
				mov [StartX], 0
				mov [StartY], 0
				mov cx, 9
				mov si, 0
				@@loop3:
				mov ah, [File15 + si]
				mov [FileName + si], ah
				inc si
				loop @@Loop3

				call DrawPCX
				mov ah, 8h
				int 21h
;----------------------------- draw the thanks for playing pcx
				mov ax, 4C00h
			  int 21h ; terminates the program
@@instructions:
			  call instructions
				jmp mainloop
@@credits:
			  ;call credits
				jmp mainloop
@@game:
				mov [StartX], 0
				mov [StartY], 0
				mov cx, 9
				mov si, 0
				@@loop4:
				mov ah, [File19 + si]
				mov [FileName + si], ah
				inc si
				loop @@Loop4

				call DrawPCX
;----------------------------- draw the difficulty chooser
				mov [startx], difficultyX1
				mov [starty], difficultyY1
				mov [pic_width], cursor_width
				mov [pic_height], cursor_height
				mov cx, cursor_width * cursor_height
				xor si,si
@@CopyCursor:
				mov dl, [cursor + si]
				mov [bitmapcopy + si], dl
				inc si
				loop @@CopyCursor
				call bitmap
;----------------------------- draw the cursor
@@chooseDifficulty:
				xor ah, ah
				int 16h
				cmp ah, DOWN_ARROW
				jne @@n1
				cmp [difficulty], 3
				je @@chooseDifficulty
				inc [difficulty]
			  call deletebitmap
@@n1:
				cmp ah, UP_ARROW
				jne @@n2
				cmp [difficulty], 1
				je @@chooseDifficulty
				dec [difficulty]
				call deletebitmap
@@n2:
				cmp ah, ENTER_KEY
				jne @@n3
				jmp @@gotDifficulty
@@n3:
				push ax
				call MOVEDIFFICULTYBITMAP
				pop ax
				dec al
				jnz @@chooseDifficulty ; the scan code of ESC is 1, so 1-1=0
				jmp mainloop
@@gotDifficulty:
				call setDifficulty
				ret ; the game will start
ENDP MAIN_MENU

PROC MOVEDIFFICULTYBITMAP

				cmp [difficulty],1
				jne @@n1
				mov [StartY], difficultyY1
@@n1:
				cmp [difficulty],2
				jne @@n2
				mov [StartY], difficultyY2
@@n2:
				cmp [difficulty],3
	      jne @@n3
				mov [StartY], difficultyY3
@@n3:
				mov cx, cursor_width * cursor_height
				xor si,si
				@@CopyCursor1:
				mov dl, [cursor + si]
				mov [bitmapcopy + si], dl
				inc si
				loop @@CopyCursor1
				call bitmap
				ret

ENDP MOVEDIFFICULTYBITMAP
PROC DELETEBITMAP

				mov cx, cursor_width * cursor_height
				xor si,si
				@@CopyCursor:
				mov dl, 0
				mov [bitmapcopy + si], dl
				inc si
				loop @@CopyCursor
				call bitmap
				ret

ENDP DELETEBITMAP
PROC setDifficulty

				mov [tries], 6
				mov [clickerCountOffset], 10
				mov [freeFallSpeed],40000d
				mov [freeFallCounter], 3
;---------------------------------- the default (also the easy difficulty)
@@n1:
				cmp [difficulty], 2 ;medium
				jne @@n2
				mov [tries], 5
				mov [clickerCountOffset], 20
				mov [freeFallSpeed], 20000
				mov [freeFallCounter], 4
@@n2:
				cmp [difficulty], 3 ; hard
				jne @@end
				mov [tries], 3
				mov [clickerCountOffset], 40
				mov [freeFallSpeed], 5000
				mov [freeFallCounter], 5
@@end:
				ret

ENDP setDifficulty

PROC INSTRUCTIONS

				mov [StartX], 0
				mov [StartY], 0
				mov cx, 9
				mov si, 0
				@@loop1:
				mov ah, [File14 + si]
				mov [FileName + si], ah
				inc si
				loop @@Loop1

				call DrawPCX
				mov ah, 0ch
			  mov al, 0ah
			  int 21h ;--Clear Keyboard Buffer
				mov ah, 8h
				int 21h
				ret

ENDP INSTRUCTIONS
PROC BOMB_GAME

			mov [StartX], 0
			mov [StartY], 0
			mov cx, 9
			mov si, 0
			@@loop1:
			mov ah, [File17 + si]
			mov [FileName + si], ah
			inc si
			loop @@Loop1

			call DrawPCX
			mov ah, 8h
			int 21h
;-------------------- draw the bomb guide pcx
			mov [StartX], 0
			mov [StartY], 0
			mov cx, 9
			mov si, 0
			@@loop2:
			mov ah, [File18 + si]
			mov [FileName + si], ah
			inc si
			loop @@Loop2

			call DrawPCX
;------------------ draw the bomb game
			mov ah, 8h
			int 21h

			ret

ENDP BOMB_GAME
PROC BITMAP
;-------------------------------------------------------------
; bitmap - draw a bitmap
;-------------------------------------------------------------
; Input:
; startx, starty, bitmap, pic_width, pic_height
; Output:
; a bitmap
; Registers:
;	 ax,bx,si,cl,
;------------------------------------------------------------
			pusha
			mov ax, [StartX]
			mov bx, [StartY]
			mov [x], ax
			mov [y], bx
			mov ax, [pic_width]
			mov bx, [pic_height]
			xor si,si

@@cycle:
			mov cl, [bitmapcopy + si]
			inc si
			mov [color], cl
			pusha
			DRAWPIXEL x, y, color
			popa
			inc [x]
			dec ax
			jnz @@cycle
@@endOfRow:
			inc [y]
			mov ax, [startx]
			mov [x], ax
			mov ax, [pic_width]
			dec bx
			jz @@end
			jmp @@cycle
@@end:
			popa
			ret

ENDP BITMAP
			include "draw.dat"

END start
