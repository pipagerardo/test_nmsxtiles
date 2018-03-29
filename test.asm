;-----------------------------------------------------------------------
; CONFIGURACION DEL CARTUCHO U BINARIO:
;-----------------------------------------------------------------------
DEFINE TITULO 	"MI JUEGO"	; El nombre de tu fantástico juego
DEFINE COMPRIME 		; Comentar para no usar pletter
; DEFINE BINARIO $8200		; Descomentar para usar Binario
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
IFDEF BINARIO
; Cabecera del binario para RAM
	output	"./DSK/test.bin"
	DB	$FE
	DW	BINARIO
	DW	FIN
	DW	INICIO
	MAP 	FIN			; Direcciones de Memoria
	ORG	BINARIO			; ORG para binarios esta bien...
;-----------------------------------------------------------------------
ELSE
; Cabecera del cartucho ROM 32K
;	output	test.rom		; No es necesario
	DEFPAGE 0			; ROM  16K -> BIOS 16K
	DEFPAGE 1, $4000, $8000		; ROM  32K PÁGINAS 1 Y 2
	MAP	$C000			; RAM 16K
	PAGE	1			; Los cartuchos usar Páginas
	CODE @	$4000			; Los cartuchos usar CODE
	DB	$41, $42	 	; ID ("AB") Cartucho ROM
	DW	INICIO			; Dirección de Inicio
	DW	0, 0, 0, 0, 0, 0	; 12 Bytes para completar
	DB	TITULO			; 12 Bytes nombre de la rom
ENDIF
INICIO_MAPA	#			; MAPA DE MEMORIA

;-----------------------------------------------------------------------
; Librerías:
IFNDEF BINARIO
	INCLUDE "LIB/setpages.asm"	; Páginas ROM
ENDIF
	INCLUDE "LIB/bios.asm"		; BIOS
IFDEF COMPRIME
	INCLUDE "LIB/depletter.asm"	; Descompresor
ENDIF
	INCLUDE "LIB/paleta.asm"	; Cambio de la paleta de color
	INCLUDE "LIB/sonido.asm"

;-----------------------------------------------------------------------
; Funiones:
;-----------------------------------------------------------------------
UN_BANCO:
;-----------------------------------------------------------------------
	LD      B, $9F			; 1 tabla  $2000, $2000, $2000 
	LD      C, 3			; TABLA DE COLOR
	CALL    WRTVDP
	LD      B, $00			; 1 tabla  $0000, $0000, $0000
	LD      C, 4			; TABLA DE PATRONES
	CALL    WRTVDP
	RET
;-----------------------------------------------------------------------
TRES_BANCOS:
;-----------------------------------------------------------------------
	LD      B, $FF			; 3 tablas $2000, $2800, $3000 	
	LD      C, 3			; TABLA DE COLOR
	CALL    WRTVDP
	LD      B, $03			; 3 tablas $0000, $0800, $1000
	LD      C, 4			; TABLA DE PATRONES
	CALL    WRTVDP
	RET
;-----------------------------------------------------------------------
ENGANCHA:
; Engancha una función a ejecutar por cada interrupción de VDP.
; Entrada:	LD	HL, FUNCION
; Requisitos:	Desactivar interrupciones
;-----------------------------------------------------------------------
	LD 	A, $C3			; ASMCODE_JP
	LD	[TIMI], A
	LD	[TIMI+1], HL
	RET
;-----------------------------------------------------------------------
DESENGANCHA:
; Desengancha la función a ejecutar por cada interrupción de VDP. 
; Requisitos:	Desactivar interrupciones
;-----------------------------------------------------------------------
	LD 	A, $C9			; ASMCODE_RET
	LD	[TIMI], A
	LD	[TIMI+1], A
	LD	[TIMI+2], A
	RET

;-----------------------------------------------------------------------
; Empieza el código...
INICIO:

IFNDEF BINARIO
	DI
	CALL	SETPAGES.SETPAGES32K	; Pone las páginas del cartucho
	EI
ENDIF

	LD	A, [BASV2]		; $002d	MSX version number
;	CP	A, 0			;	0 = MSX 1
	AND	A, A			;	0 = MSX 1
	LD	A, 2			; screen 2 - MSX1
	JR Z, 	MSX1
	LD	A, 4            	; screen 4 - MSX2
MSX1:

	CALL	CHGMOD 		; changes the screen mode. The palette is not initialised.

	LD      A, [RG1SAV]
	OR      00000010b       ; sprites 16x16
	AND     11111110b

	LD      B, A		; B for data the register number
	LD      C, 1		; C for the register number
	CALL    WRTVDP		; writes data in the VDP register

; -----------------------------------------------------
; MOSTRAMOS LA IMAGEN DE PHANTIS
; -----------------------------------------------------

	CALL    DISSCR			; Desactiva la pantalla
	CALL	TRES_BANCOS
	LD	HL, PALETTE
	DI
	CALL	PALETA.CAMBIA
	EI
	
	HALT
	LD	HL, phantis_chr		; HL = RAM/ROM source
	LD	DE, CHRTBL		; DE = VRAM desination
IFDEF COMPRIME
	DI
	CALL	DEPLETTER_VRAM
	EI
ELSE
	LD	HL, phantis_chr
	LD	DE, CHRTBL
	LD	BC, ( 256 * 8 * 3 )
	CALL	LDIRVM
ENDIF

	HALT
	LD	HL, phantis_clr		; HL = RAM/ROM source
	LD	DE, CLRTBL		; DE = VRAM desination
IFDEF COMPRIME
	DI
	CALL	DEPLETTER_VRAM
	EI
ELSE
	LD	BC, ( 256 * 8 * 3 )
	CALL	LDIRVM	    
ENDIF

	HALT
	LD	HL, mapa		; HL = RAM/ROM source
	LD	DE, NAMTBL		; DE = VRAM desination
IFDEF COMPRIME
	DI
	CALL	DEPLETTER_VRAM
	EI
ELSE
	LD	BC, ( 256 * 3 )
	CALL	LDIRVM
ENDIF
	CALL    ENASCR			; Activa la pantalla
	CALL	CHGET

; -----------------------------------------------------
; MOSTRAMOS EL PRIMER NIVEL DE TEMPTATIONS
; -----------------------------------------------------
	
	CALL    DISSCR			; Desactiva la pantalla
	CALL	UN_BANCO
	LD	HL, PALETA.TABLA
	DI
	CALL	PALETA.CAMBIA
	EI

	LD	A, 1
	LD	[BDRCLR], A		; for border colour
	CALL	CHGCLR			; changes the screen colour

	LD	A, 0
	LD	HL, NAMTBL		; Borramos la tabla de nombres
	LD	BC, ( 256 * 3 )
	CALL	FILVRM

	HALT
	LD	HL, tempt_chr		; HL = RAM/ROM source
	LD	DE, CHRTBL		; DE = VRAM desination
IFDEF COMPRIME
	DI
	CALL	DEPLETTER_VRAM
	EI
ELSE
	LD	BC, ( 256 * 8 )
	CALL	LDIRVM
ENDIF

	HALT
	LD	HL, tempt_clr		; HL = RAM/ROM source
	LD	DE, CLRTBL		; DE = VRAM desination
IFDEF COMPRIME
	DI
	CALL	DEPLETTER_VRAM
	EI
ELSE
	LD	BC, ( 256 * 8 )
	CALL	LDIRVM	    
ENDIF

; -----------------------------------------------------
	LD	A, [BASV0]
	LD	[SONIDO.PT3_HERCIOS], A	; 50Hz = $80 <-> 60Hz = $00	(BASV0)
	CALL	SONIDO.INICIA
	
	LD	HL, SONIDO.ACTUALIZA
	CALL	ENGANCHA

	LD	A, 0			; 0 con bucle y 1 sin bucle
	LD	HL, musica		; Módulo PT3
	CALL	SONIDO.REPRODUCE_MUSICA
	HALT
; -----------------------------------------------------
	
	CALL    ENASCR		; Activa la pantalla
		
	LD	B, 7
	LD	IX, mapas
.BUCLE:
	LD	L, [IX+0]
	LD	H, [IX+1]	; HL = RAM/ROM source
[2]	INC	IX
	PUSH	IX
	PUSH	BC
	LD	DE, NAMTBL	; DE = VRAM desination
IFDEF COMPRIME
	DI
	CALL	DEPLETTER_VRAM
	EI
ELSE
	LD	BC, ( 256 * 3 )
	CALL	LDIRVM
ENDIF
	CALL	CHGET
	
	LD	C, 0
	LD	HL, sonido
	CALL	SONIDO.REPRODUCE_SONIDO

	POP	BC
	POP	IX
	DJNZ 	.BUCLE
; -----------------------------------------------------

	CALL	DESENGANCHA
	CALL	SONIDO.QUITA
	RET
	
;-----------------------------------------------------------------------
; Datos:
musica:		INCBIN "SND/1stVTII.pt3"
sonido:		INCBIN "FXS/noname.afb"

IFDEF COMPRIME
phantis_chr:	INCBIN "DAT/phantis.chr.plet5"
phantis_clr:	INCBIN "DAT/phantis.clr.plet5"
mapa:		INCBIN "DAT/phantis.nam.plet5"
tempt_chr:	INCBIN "DAT/tempt.chr.plet5"
tempt_clr:	INCBIN "DAT/tempt.clr.plet5"
mapa0:		INCBIN "DAT/tempt_0_0.plet5"
mapa1:		INCBIN "DAT/tempt_1_0.plet5"
mapa2:		INCBIN "DAT/tempt_2_0.plet5"
mapa3:		INCBIN "DAT/tempt_3_0.plet5"
mapa4:		INCBIN "DAT/tempt_4_0.plet5"
mapa5:		INCBIN "DAT/tempt_5_0.plet5"
mapa6:		INCBIN "DAT/tempt_6_0.plet5"
ELSE
phantis_chr:	INCBIN "DAT/phantis.chr"
phantis_clr:	INCBIN "DAT/phantis.clr"
mapa:		INCBIN "DAT/phantis.nam"
tempt_chr:	INCBIN "DAT/tempt.chr"
tempt_clr:	INCBIN "DAT/tempt.clr"
mapa0:		INCBIN "DAT/tempt_0_0.bin"
mapa1:		INCBIN "DAT/tempt_1_0.bin"
mapa2:		INCBIN "DAT/tempt_2_0.bin"
mapa3:		INCBIN "DAT/tempt_3_0.bin"
mapa4:		INCBIN "DAT/tempt_4_0.bin"
mapa5:		INCBIN "DAT/tempt_5_0.bin"
mapa6:		INCBIN "DAT/tempt_6_0.bin"
ENDIF

mapas:
	DW	mapa0
	DW	mapa1
	DW	mapa2
	DW	mapa3
	DW	mapa4
	DW	mapa5
	DW	mapa6

	INCLUDE "DAT/phantis.pal.asm"


;-----------------------------------------------------------------------
FIN:
FINAL_MAPA	#

IFDEF BINARIO
	PRINTSTRDEC "RAM ocupada = ", ( FIN - BINARIO ) + ( FINAL_MAPA - INICIO_MAPA ), 5
	PRINTSTRDEC "RAM libre   = ", ( $F380 - BINARIO ) - ( FIN - BINARIO ) + ( FINAL_MAPA - INICIO_MAPA ), 5
ELSE
	PRINTSTRDEC "ROM ocupada = ", FIN - $4000, 5
	PRINTSTRDEC "ROM libre   = ", $8000 - ( FIN - $4000 ), 5
	PRINTSTRDEC "RAM ocupada = ", FINAL_MAPA - INICIO_MAPA, 5
	PRINTSTRDEC "RAM libre   = ", ( $F380 - $C000 ) - ( FINAL_MAPA - INICIO_MAPA ), 5
ENDIF

;-----------------------------------------------------------------------
	ENDMAP	; Fin del mapa de memoria
	END	; Fin de código
;-----------------------------------------------------------------------