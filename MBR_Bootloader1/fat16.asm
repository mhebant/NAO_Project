BITS 16
ORG 7C00h

	jmp Start
	nop ; The FAT16 Boot Sector Structure must be on offset 03h

; FAT16 Boot Sector Structure
	oemID db "        " ; 8 bytes
	bytesPerSector DW 512
	sectorsPerCluster DB 0FFh
	reservedSectors DW 0FFFFh
	fatCopies DB 0FFh
	rootEntries DW 512
	smallTotalSectors DW 0		; Use only for device < 32Mb
	mediaDescriptor DB 0F8h
	sectorsPerFAT DW 0FFh
	sectorsPerTrack DW 0FFFFh
	heads DW 0FFFFh
	hiddenSectors DD 0
	totalSectors DD 0FFFFFFFFh
	driveNumber DB 0FFh
	DB 0FFh ; Reserved
	extendedBootSignature DB 0FFh
	volumeID DD 0FFFFFFFFh
	volumeLabel DB "           " ; 11 bytes
	fileSystemID DB "FAT16   " ; 8 bytes
	
Start:
	mov ax, 0780h				; (7C00h - 1024) / 16 (On place la plie de 1K avent l'adresse 7C00h)
	mov ss, ax
	mov sp, 1024
	
	mov BYTE [driveNumber], dl		; On sauvgarde le numero du périférique sur lequel on a boot
	mov ah, 08h						; Et on recupere la geometrie du disque
	add dh, 1
	mov DWORD [sectorsPerTrack], 0
	mov BYTE [heads], dh
	and cl, 03fh
	mov BYTE [sectorsPerTrack], cl
	
	xor ax, ax					; Calculate Root Dir Table first sector
	mov al, BYTE [fatCopies]
	mul WORD [sectorsPerFAT]
	add ax, WORD [reservedSectors]

	call Sector2Disk

	mov ah, 02h					; Function: Read sectors
	mov al, 32					; Number of sectors to read
	xor bx, bx			
	mov es, bx					; Set ES to segment 0
	mov bx, 500h					; Set BX to 0500h
	int 13h						; Load the Root Dir Table at 0x0500 (0000:0500)
	jc .Fail

	mov bp, 0500h				; On commence par comparer la première entrée
	cld							; On va parcourir les string du début vers la fin (DF = 0)
.NextEntry:
	mov si, fileName				; DS:SI = fileName
	mov di, bp 					; On place DI au début de l'entrée en cour
	mov cx, 8					; Initialisation du compteur
.NextCharacter:
	jcxz .EntryFound
	dec cx						; On décrémente le compteur
	cmpsb
	je  .NextCharacter
	add bp, 32					; On passe à l'entré suivante
	cmp bp, 4500h				; Si l'entré suivante est au dessu de l'adresse 4500h
	jae .Fail						; Alors on à lu les 512 premières entrés (les seules qu'on est chargé), donc on abandone
	jmp .NextEntry

.EntryFound:
	mov bx, bp
	mov dx, WORD [bx + 1Ch]
	mov WORD [fileSize], dx
	mov dx, WORD [bx + 1Ch + 2]
	mov WORD [fileSize +2], dx
mov al, [fileSize]
call Print_byte
	mov si, bx
	call Print_string
	jmp $
	
.Fail:	
	mov si, failMsg
	call Print_string
	jmp $

; Sector2Disk : Calcule absoluteSector, absoluteHead et absoluteTrack pour un secteur logique donné et prépare les registre pour un appel à int 13h
; 	absolute sector = (logical sector / sectors per track) + 1
; 	absolute head   = (logical sector / sectors per track) MOD number of heads
; 	absolute track  = logical sector / (sectors per track * number of heads)
; AX = Secteur logique
Sector2Disk:
	xor dx, dx					; Clear dx before div
	div WORD [sectorsPerTrack]
	inc dl						; Adjust for sector 0
	mov cl, dl					; Sector (=CL pour int 13h)
	xor dx, dx					; Clear dx before div
	div WORD [heads]
	mov dh, dl					; Head (=DH pour int 13h)
	mov ch, al					; Track (=CH pour int 13h)
	mov dl, BYTE [driveNumber]		; Drive (=DL pour int 13h)
	ret

; Print_string : Ecrit une chaine de caractère à l'écran, à la position du curseur
; DS:SI = debut de chaine
Print_string:
	push ax
	push bx
	mov ah, 0Eh			; On paramettre la fonction pour l'appelle à int 10h
	mov bh, 00h
	mov bl, 0Fh
	cld 					; On va parcourir la chaine de gauche a droite
.Print_string.loop:
	lodsb 				; On charge le caractere et on incrémente
	cmp al, 00h 			; Si c'est la fin de la chaine
	je .Print_string.end 		; On arrete
	int 10h 				; Sinon on affiche
	jmp .Print_string.loop
.Print_string.end:
	pop bx
	pop ax
	ret

; Print_byte : Ecrit le code hexa à l'écran, à la position du curseur
; AL : octet à afficher
Print_byte:
	push ax
	push bx
	push dx
	mov ah, 0Eh			; On paramettre la fonction pour l'appelle à int 10h
	mov bh, 00h
	mov bl, 0Fh
	mov dl, al 			; On sauvgarde AL dans DL
	and al, 0F0h			; On masque les 4 bits de poids faible de AL
	shr al, 4				; On décale AL de 4 bits vers la droite
	call Print_byte.b2h		; On converti les 4 bits en leur caractere hexa
	mov al, dl			; On récupère DL
	and al, 0Fh			; On masque les 4 bites de poid fort de AL
	call Print_byte.b2h		;  On converti les 4 bits en leur caractere hexa
	pop dx
	pop bx
	pop ax
	ret
Print_byte.b2h:
	add al, 48			; On ajoute 48, on a le code ascii du chiffre de 0 à 9
	cmp al, 58			; Si c'est en dessous de 58 (donc c'est bien un chiffre)
	jb .Print_byte.print		; On imprime le carractere
	add al, 7				; Sinon on ajoute 7 et on a le code ascii de la lettre de A à F
.Print_byte.print:
	int 10h				; On affiche le caractere
	ret

fileName DB "TEST    TXT"
fileSize DD 0
successMsg DB "RDT loaded !", 00h
failMsg DB "ERROR !!", 00h


TIMES 510-($-$$) DB 00h
DB 55h
DB 0AAh
