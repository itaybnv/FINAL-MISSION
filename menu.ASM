
;------------------------------------------
; PURPOSE : The Main Function 
; SYSTEM  : Turbo Assembler Ideal Mode  
; AUTHOR  : Itay Benvenisti    
;------------------------------------------

		IDEAL
		
		MODEL small

		STACK 256

                ESC_KEY         equ 1
                NUMBER_ONE      equ 2
                NUMBER_TWO      equ 3
                NUMBER_THREE    equ 4
                NUMBER_FOUR     equ 5
                screen_RAM_text equ 0B800h
                DATASEG

        options db 0dh,0ah,0dh,0ah,0dh,0ah,0dh,0ah,0dh,0ah,0dh,0ah,0dh,0ah
                db "1. PLAY ",0dh,0ah
                db "",0dh,0ah
                db "",0dh,0ah
                db "2. INSTRUCTIONS",0dh,0ah

                db "",0dh,0ah
                db "",0dh,0ah
                db "3. CREDITS",0dh,0ah
                db "",0dh,0ah
                db "",0dh,0ah
                db "4. QUIT GAME$"

        game_text         db "this is the game screen$"
        instructions_text db "this is the instructions screen$"
        credits_text      db "this is the credits screen$"
        
		CODESEG
Start:
        mov ax, @data
        mov ds, ax

        mov ax, 3h
        int 10h        ; text mode
        mov dx, offset options
        mov ah,09h
        int 21h        ; print options


;---------------- MAIN LOOP
mainloop:
        mov ah, 0ch
        mov al, 07h
        int 21h ;--Clear Keyboard Buffer

        in al,060h ;--read scan code from keyboard port
        push ax
;--------------- CHECK FOR KEYPRESS
        
        cmp al, NUMBER_ONE
        je startgame

        cmp al, NUMBER_TWO
        je instructions

        cmp al, NUMBER_THREE
        je credits

        cmp al, NUMBER_FOUR
        je quit
        
        pop ax
        dec al
        jnz mainloop
        jmp quit

startgame:

        call ClearScreen
        mov ah, 02h
        mov dx, 0h
        mov bh, 0h
        int 10h    ;--Reset cursor position

        mov dx, offset game_text
        mov ah,09h
        int 21h        ; print game
        jmp WaitForEsc

instructions:

        call ClearScreen
        mov ah, 02h
        mov dx, 0h
        mov bh, 0h
        int 10h    ;--Reset cursor position

        mov dx, offset instructions_text
        mov ah,09h
        int 21h        ; print instructions
        jmp WaitForEsc


credits:

        call ClearScreen
        mov ah, 02h
        mov dx, 0h
        mov bh, 0h
        int 10h    ;--Reset cursor position

        mov dx, offset credits_text
        mov ah,09h
        int 21h        ; print credits
WaitForEsc:

        mov ah, 0ch
        mov al, 07h
        int 21h ;--Clear Keyboard Buffer

        in al,060h ;--read scan code from keyboard port
        push ax

        cmp al, ESC_KEY
        je start
        jmp WaitForEsc

quit:

        call ClearScreen



Exit:
        mov ax, 4C00h
        int 21h

PROC ClearScreen

        mov ax, screen_RAM_text
        mov es,ax
        xor di,di
        mov cx,80*24
        mov al,255d ; ASCII
        mov ah,15d ;color
        rep stosw ; clear screen by moving ax to es:di and inc by 1 
        ret     

ENDP ClearScreen





END start

