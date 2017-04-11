BITS 16
ORG 7C00h

	jmp Start
	nop ; The FAT16 Boot Sector Structure must be on offset 03h

; FAT16 Boot Sector Structure
	oemID db "rockytoo" ; 8 bytes
	bytesPerSector DW 512
	sectorsPerCluster DB 128
	reservedSectors DW 1
	fatCopies DB 2
	rootEntries DW 512
	smallTotalSectors DW 0		; Use only for device < 32Mb
	mediaDescriptor DB 0F8h
	sectorsPerFAT DW 0FFFFh
	sectorsPerTrack DW 0FFFFh
	heads DW 0FFFFh
	hiddenSectors DD 0
	totalSectors DD 0
	driveNumber DB 0FFh
	DB 0FFh ; Reserved
	extendedBootSignature DB 29h
	volumeID DD 42
	volumeLabel DB "frank'stein" ; 11 bytes
	fileSystemID DB "FAT16   " ; 8 bytes
	
Start:
	mov si, motd
	
Print_string:
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
    jmp $

motd DB "Frankenstein is alive but brainless, sorry ^^", 00h


TIMES 510-($-$$) DB 00h
DB 55h
DB 0AAh
