.386
ASSUME CS:code, DS:data, SS:stack

stack SEGMENT STACK
  DW 64 dup (0)
stack ends

data SEGMENT para PUBLIC
  string DB "FirstName LastName", 13, 10, "$"
  pixel_size dw 10
  direction dw 0
  head dw 0
  cherry dw 0
  score dw 0
  snake DW 10 DUP(?)
  seed DW 121  ; Inicjalizujemy seed wartoœci¹ pocz¹tkow¹ 1234
  wektor8 dd ?
  klawisz db 0
data ends

code SEGMENT USE16 PARA PUBLIC 'CODE'

gra PROC
	push ax
	push bx
	push dx
	push es
	mov ax, 0A000H ; adres pamiêci ekranu
	mov es, ax


		; Check the scan code in AH
		mov al, klawisz      ; Move scan code to AL for comparison
		cmp al, 48h     ; Up arrow
		je handle_up
		cmp al, 50h     ; Down arrow
		je handle_down
		cmp al, 4Bh     ; Left arrow
		je handle_left
		cmp al, 4Dh     ; Right arrow
		je handle_right


		jmp rysowaniePlanszy   ; Go back to main loop

	handle_up:
		xor bx,bx
		mov bl,1
		cmp direction,2
		je rysowaniePlanszy
		mov direction,bx
		jmp rysowaniePlanszy ; Example action

	handle_down:
		; Action for down arrow
		xor bx,bx
		mov bl,2
		cmp direction,1
		je rysowaniePlanszy
		mov direction,bx
		jmp rysowaniePlanszy  ; Example action

	handle_left:
		; Action for left arrow
		xor bx,bx
		mov bl,3
		cmp direction,4
		je rysowaniePlanszy
		mov direction,bx
		jmp rysowaniePlanszy  ; Example action

	handle_right:
		; Action for right arrow
		xor bx,bx
		mov bl,4
		cmp direction,3
		je rysowaniePlanszy
		mov direction,bx
		jmp rysowaniePlanszy  ; Example action

	rysowaniePlanszy:
		


		; move da snake

		mov cx,score
		cmp cx,0
		jng scoreIs0
		mov ax,2
		mul cx
		mov di,ax
	moveSnake:
		sub di,2
		mov bx,[snake+di]
		mov [snake+di+2],bx
		loop moveSnake
	scoreIs0:


		
		mov bx,head
		mov [snake],bx

		cmp direction, 1
		jne NieGora
		cmp bh,0
		jne NieZeroLewo
		call reset
		NieZeroLewo:
		sub bh,1
		jmp HeadUpdated
	NieGora:
		cmp direction, 2
		jne NieDol
		
		cmp bh,40
		jne wysokoscDobra
		call reset
		wysokoscDobra:
		add bh,1
		jmp HeadUpdated
	NieDol:
		cmp direction, 3
		jne NieLewo
		cmp bl,0
		jne NieZeroGora
		call reset
		NieZeroGora:
		sub bl,1
		jmp HeadUpdated
	NieLewo:
		cmp bl,64
		jne SzerokoscDobra
		call reset
		SzerokoscDobra:
		add bl,1


	HeadUpdated:
		mov head,bx

		call clear_screen



		
		mov cx,score
		inc cx
		cmp cx,0
		je dalej
		mov ax,2
		mul cx
		mov di,ax
		sub di,2
	checkSnake:
		mov bx,[snake+di]
		cmp bx,head
		jne notColllision
		call reset
		notColllision:
		sub di, 2
		loop checkSnake


	dalej:
		mov cx,score
		cmp cx,0
		je score0
		mov ax,2
		mul cx
		mov di,ax
		sub di,2
	drawSnake:
		mov bx,[snake+di]
		call translate_xy  ; Translate to video memory address
		mov al, 30         
		call draw
		sub di,2
		loop drawSnake

	score0:


		mov bx,head
		call translate_xy  ; Translate to video memory address
		mov al, 10         
		call draw

		mov bx,head
		cmp bx,cherry
		jne rysowanieCherry 
		add score,1
		; new position of cherry
		call get_random ; get random position
		mov cherry,bx
		jmp koniecFunkcji

	rysowanieCherry:
		mov bx,cherry
		call translate_xy  ; Translate to video memory address
		mov al, 4         
		call draw

	koniecFunkcji:
	pop es
	pop dx
	pop bx
	pop ax

	jmp dword PTR wektor8
gra ENDP



clear_screen PROC
	; Za³adowanie segmentu pamiêci wideo (0xA000) do ES
	mov ax, 0A000H
	mov es, ax

	; Wyczyszczenie ca³ego ekranu
	xor di, di       ; Ustaw DI (adres w pamiêci wideo) na 0
	mov cx, 64000   ; Liczba bajtów w pamiêci wideo (320 x 200)- i suppose
	xor al, al       ; Kolor czarny (0)
	;mov al, 0Fh       ;kolor bialy
	rep stosb        ; Wype³nij pamiêæ od [ES:DI] zerami
	ret
clear_screen ENDP


draw PROC
	    ; Parametry wejœciowe:
    ; BX - lewy gorny rog 
    ; AL - kolor piksela (0-255)
	push bx
    push cx        ; Zachowanie rejestru cx
    push dx        ; Zachowanie rejestru dx
	push di

	mov dx, 0A000H    ; Segment for video memory
    mov es, dx
    ; Set ES to video memory segment
	mov cx, 5  ; Use only the lower byte of pixel_size
    mov dx, cx                   ; Copy pixel_size to DX for lines
	mov di,cx
	;bx-punkt pocz¹tkowy rysowania

	draw_line:
		mov cx, dx      ; Ka¿da linia ma 16 piksele
		draw_pixel:
			mov es:[bx], al ; Ustaw piksel na podany kolor
			inc bx                 ; PrzejdŸ do nastêpnego piksela
		loop draw_pixel         ; Kontynuuj, jeœli nie wszystkie piksele s¹ narysowane
		add bx, 320            ; PrzejdŸ do nastêpnej linii (320 - 16)
		sub bx,dx
		dec di 
	jnz draw_line          ; Kontynuuj, jeœli nie wszystkie linie s¹ narysowane

	pop di
    pop dx        ; Przywrócenie rejestru DX
    pop cx        ; Przywrócenie rejestru CX
	pop bx
    ret           ; Powrót z funkcji
draw ENDP
	

translate_xy PROC

	; Parametry wejœciowe:
    ; BX - 16-bitowy rejestr, gdzie:
    ;      - BH: wspó³rzêdna Y (wysokoœæ)
    ;      - BL: wspó³rzêdna X (szerokoœæ)
    ; Wyjœcie:
    ; BX - Przet³umaczony adres pamiêci wideo
    push ax           ; Zachowaj AX
    push cx           ; Zachowaj CX

    mov al, bh        ; AX = Y-coordinate
	mov bh,0
    mov cx, 320       ; CX = screen width (320 bytes per line)
    mul cx            ; AX = Y * 320
    add ax, bx        ; AX = Y * 320 + X
	mov cx,5
	mul cx
	mov bx,ax

    pop cx            ; Przywróæ CX
    pop ax            ; Przywróæ AX

	ret
translate_xy ENDP

get_random PROC

	mov ah, 0
			int 1ah ; cx = hi dx = low
			mov dx,seed

			mov ax, dx
			and ax, 0fffh
			mul dx
			mov dx, ax
			mov ax, dx
			mov cx, 40
			xor dx, dx
			div cx ; dx = rest of division
			mov bh, dl

			mov ah,0
			int 1ah ; cx = hi dx = low
			mov ax, dx
			and ax, 0fffh
			mul dx
			mov dx, ax
			mov ax, dx
			mov cx, 64 
			xor dx, dx
			div cx ; dx = rest of division
			mov bl, dl
	ret
get_random ENDP


reset PROC
	mov score,0
	mov bl,10
	mov bh,10
	mov head,bx
	call get_random ; get random position
	mov cherry,bx

	ret
reset ENDP

start:
	mov ax, data
	mov ds, ax

	mov ah, 0 ; funkcja nr 0 ustawia tryb sterownika
	mov al, 13H ; nr trybu
	int 10H ; wywo³anie funkcji systemu BIOS
	
	; nadpisanie wektora przerwan dla odswiezania obrazu
	xor bx, bx ; bx = 0
	mov es, bx ; zerowanie rejestru ES
	mov eax, es:[32] ; odczytanie wektora nr 8
	mov wektor8, eax; zapamiêtanie wektora nr 8
	; adres petli gry 'snake_update' w postaci segment:offset
	mov ax, SEG gra
	mov bx, OFFSET gra
	cli ; zablokowanie przerwañ
	; zapisanie adresu petli gry 'snake_update' do wektora nr 8
	mov es:[32], bx
	mov es:[32+2], ax
	sti ; odblokowanie przerwañ

	
	mov bh,10
	mov bl,5
	mov cherry,bx

	call clear_screen

	mov score,0
	
	
	czekaj:
		xor ah, ah ; ah = 00h
		int 16h
		mov klawisz, ah
		cmp ah, 45 ; scancode 45 = x
		jne czekaj
	
	;ustawienie trybu tekstowego
	mov ah, 0
	mov al, 3H
	int 10H
	
	; odtworzenie oryginalnej zawartoœci wektora nr 8
	mov eax, wektor8
	mov es:[32], eax
	
	; zakoñczenie wykonywania programu
	mov ax, 4C00H
	int 21H
	
code ENDS
END start