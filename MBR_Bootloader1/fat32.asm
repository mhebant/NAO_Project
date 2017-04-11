BITS 16
ORG 7C00h

	jmp Start
	nop ; The FAT32 Boot Sector Structure must be on offset 03h

; FAT32 Boot Sector Structure (See http://www.maverick-os.dk/FileSystemFormats/FAT32_FileSystem.html for all FAT file system stuff)
	oemID DB "        "
	bytesPerSector DW 512
	sectorsPerCluster DB 00h
	reservedSectors DW 00h
	fatCopies DB 2
	DD 00 ; Not used in FAT32
	mediaDescriptor DB 0F8h
	DW 00 ; Not used in FAT32
	sectorsPerTrack DW 00h
	sectorsPerHead DW 00h
	hiddenSectors DD 00h
	totalSectors DD 0
	sectorsPerFAT DD 00h
	flags DW 00h
	fat32DriveVersion DW 00h
	rootDirectoryCluster DD 2
	fileSystemInfoSector DW 1
	backupBootSector DW 6
	
	TIMES 12 DB 00
	
	driveNumber DB 80h
	currentHead DB 00h
	signature DB 29h
	volumeID DD 00h
	volumeLabel DB "           "
	systemID DB "FAT32   "

Start:
	
	mov ax, 780h		; (7C00h - 1024) / 16 (Placing the stack of 1Kb before the address 7C00h)
	mov ss, ax
	mov sp, 1024
	
	mov [bootdevice], dl	; Save the id of the device we want to boot on
	
	mov ah, 02h
	mov al, 1				; Number of sectors to read
	mov
	
	
	mov si, motd
	call Print_string

; Sector2disk : Calcule absoluteSector, absoluteHead et absoluteTrack pour un secteur logique donné
; 	absolute sector = (logical sector / sectors per track) + 1
; 	absolute head   = (logical sector / sectors per track) MOD number of heads
; 	absolute track  = logical sector / (sectors per track * number of heads)
; AX = Secteur logique
Sector2disk:
	xor dx, dx						; prepare dx:ax for operation
	div WORD [SectorsPerTrack]		; calculate
	inc dl							; adjust for sector 0
	mov BYTE [absoluteSector], dl
	xor dx, dx						; prepare dx:ax for operation
	div WORD [SectorsPerHead]		; calculate
	mov BYTE [absoluteHead], dl
	mov BYTE [absoluteTrack], al
	ret

; print_string : Ecrit une chaine de caractère à l'écran, à la position du curseur
; DS:SI = debut de chaine
Print_string:
	mov ah, 0Eh			; On paramettre la fonction pour l'appelle à int 10h
	mov bh, 00h
	mov bl, 0Fh
	cld 					; On va parcourir la chaine de gauche a droite
Print_string.loop:
	lodsb 				; On charge le caractere et on incrémente
	cmp al, 00h 			; Si c'est la fin de la chaine
	je Print_string.end 		; On arrete
	int 10h 				; Sinon on affiche
	jmp Print_string.loop
Print_string.end:
	ret

bootdevice DB 0h
absoluteSector DB 0h
absoluteHead DB 0h
absoluteTrack DB 0h
motd DB "CouCou !!", 00h


TIMES 510-($-$$) DB 00h
DB 55h
DB 0AAh
