bits 16
org 7C00h

start:
	mov ax, 07C0h 		; 1K de pile après le loader
	add ax, 96			; (1024 + 512) / 16(octets par segment)
	mov ss, ax
	mov sp, 1024
	
	mov [bootdevice], dl	; On sauvgarde le numero du périférique sur lequel on a boot
	
	mov si, motd
	call print_string

	mov al, dl
	call print_byte

	hlt

; print_string : Ecrit une chaine de caractère à l'écran, à la position du curseur
; DS:SI = debut de chaine
print_string:
	mov ah, 0Eh			; On paramettre la fonction pour l'appelle à int 10h
	mov bh, 00h
	mov bl, 0Fh
	cld 					; On va parcourir la chaine de gauche a droite
print_string.loop:
	lodsb 				; On charge le caractere et on incrémente
	cmp al, 00h 			; Si c'est la fin de la chaine
	je print_string.end 		; On arrete
	int 10h 				; Sinon on affiche
	jmp print_string.loop
print_string.end:
	ret

; print_byte : Ecrit le code hexa à l'écran, à la position du curseur
; AL : octet à afficher
print_byte:
	mov ah, 0Eh			; On paramettre la fonction pour l'appelle à int 10h
	mov bh, 00h
	mov bl, 0Fh
	mov dl, al 			; On sauvgarde AL dans DL
	and al, 0F0h			; On masque les 4 bits de poids faible de AL
	shr al, 4				; On décale AL de 4 bits vers la droite
	call print_byte.b2h		; On converti les 4 bits en leur caractere hexa
	mov al, dl			; On récupère DL
	and al, 0Fh			; On masque les 4 bites de poid fort de AL
	call print_byte.b2h		;  On converti les 4 bits en leur caractere hexa
	ret
print_byte.b2h:
	add al, 48			; On ajoute 48, on a le code ascii du chiffre de 0 à 9
	cmp al, 58			; Si c'est en dessous de 58 (donc c'est bien un chiffre)
	jb print_byte.print		; On imprime le carractere
	add al, 7				; Sinon on ajoute 7 et on a le code ascii de la lettre de A à F
print_byte.print:
	int 10h				; On affiche le caractere
	ret

motd db "Test doit ecrire 5F:", 00h
bootdevice db 0h

times 510-($-$$) db 00h
db 55h
db 0AAh
