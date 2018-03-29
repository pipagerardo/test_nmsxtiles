;-----------------------------------------------------------------------
;                       INICIO SONIDO
;-----------------------------------------------------------------------
; SONIDO.INICIA		; Inicia el sistema de sonido
; SONIDO.QUITA		; Quita el sistema de sonido
; SONIDO.LIMPIA		; Borra el buffer de sonido y actualiza PSG 
; SONIDO.ACTUALIZA	; Enganchar en la función de interrupción
; SONIDO.REPRODUCE_MUSICA	; Reproduce musica PT3
; SONIDO.PARA_MUSICA		; Para la música
; SONIDO.REPRODUCE_SONIDO	; Reproduce sonido AFB
; SONIDO.PARA_SONIDO		; Para el sonido
;-----------------------------------------------------------------------

	MODULE SONIDO
DEFINE USAR_SONIDO 1
IFDEF USAR_SONIDO
	INCLUDE	"ayFX_replayer.asm"
ENDIF
	INCLUDE	"PT3_replayer.asm"

; AÑADIDO PARA SOPORTE 50 Y 60 HZ
PT3_HERCIOS	#	1	; 50Hz = $80 <-> 60Hz = $00	(BASV0)
PT3_60_50	#	1
PT3_AYREGS_BAK	#	14

;-----------------------------------------------------------------------
INICIA:
; Entrada:	PT3_HERCIOS	La frecuencia 50HZ | 60HZ
; Salida:	--
; Registros:	AF, HL
; Requisitos:	--
;-----------------------------------------------------------------------
	XOR	A			; A = 0;
	LD 	[PT3_60_50], A
	LD 	A, [PT3_HERCIOS]	; ASOPORTE 50 Y 60 HZ
	AND 	$80
	JP NZ, .SEGUIMOS
	LD	A, 6
	LD	[PT3_60_50], A		; FIN SOPORTE 50 Y 60 Hz
.SEGUIMOS:
	CALL	QUITA
	RET
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
QUITA:
	CALL	PARA_MUSICA
IFDEF USAR_SONIDO
	CALL	PARA_SONIDO
ENDIF
	CALL	LIMPIA
	HALT
	RET
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
LIMPIA:
; Borra los buffer de sonido y actualiza los registros  PSG 
; para que no se escuche pitidos
; Requisitos:	--
;-----------------------------------------------------------------------
	LD	HL, 0
	LD	[PT3_REPLAYER.PT3_AYREGS+0], HL
	LD	[PT3_REPLAYER.PT3_AYREGS+2], HL
	LD	[PT3_REPLAYER.PT3_AYREGS+4], HL
	LD	[PT3_REPLAYER.PT3_AYREGS+6], HL
	LD	[PT3_REPLAYER.PT3_AYREGS+8], HL
	LD	[PT3_REPLAYER.PT3_AYREGS+10], HL
	LD	[PT3_REPLAYER.PT3_AYREGS+12], HL
	LD	HL, PT3_REPLAYER.PT3_AYREGS
	LD	DE, PT3_AYREGS_BAK
	LD	BC, 14
	LDIR
	DI
	CALL	PT3_REPLAYER.PT3_ROUT
	EI
	RET
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
ACTUALIZA:
; Requisitos:	Debe ejecutarse durante una interrupción.
;-----------------------------------------------------------------------
	CALL	PT3_REPLAYER.PT3_ROUT	; Write values on PSG registers
;	CALL	PT3_REPLAYER.PT3_PLAY	; Calculates PSG values for next frame
	CALL	PT3_PLAYMUSIC	; Mejora PT3_PLAY dando soporte a 60Hz
IFDEF USAR_SONIDO
	CALL	AYFX_REPLAYER.ayFX_PLAY	; Fx
ENDIF
	RET
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
REPRODUCE_MUSICA:
; Entradas:	A	0 con bucle y 1 sin bucle
;		HL	Módulo PT3
; Salida:	--
; Registros:	AF
; Requisitos:	--
;-----------------------------------------------------------------------
	LD	[PT3_REPLAYER.PT3_SETUP], A
	CALL	PT3_REPLAYER.PT3_INIT	; Inits PT3 player
	RET
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
PARA_MUSICA:
; Entradas:	--
; Salida:	--
; Registros:	AF, HL
; Requisitos:	--
;-----------------------------------------------------------------------
	LD	A, 1		 	; A=0 con bucle; A=1 sin bucle
	LD	[PT3_REPLAYER.PT3_SETUP], A
	LD	HL, PT3_REPLAYER.EMPTYSAMORN
	CALL	PT3_REPLAYER.PT3_INIT
	RET
;-----------------------------------------------------------------------

IFDEF USAR_SONIDO
;-----------------------------------------------------------------------
REPRODUCE_SONIDO:
;-----------------------------------------------------------------------
; Entrada:	HL	Modulo AFB
;		C	Prioridad [0~15]
; Salida:	--
; Registros:	AF
;-----------------------------------------------------------------------
	CALL	AYFX_REPLAYER.ayFX_SETUP	;  HL -> pointer to the ayFX bank 
	XOR	A
	CALL	AYFX_REPLAYER.ayFX_INIT
	RET
;-----------------------------------------------------------------------
PARA_SONIDO:
;-----------------------------------------------------------------------
	LD	A, 255			; Lowest ayFX priority
	LD	[AYFX_REPLAYER.ayFX_PRIORITY], A	; Priority saved (not playing ayFX stream)
	RET
;-----------------------------------------------------------------------
ENDIF

;-----------------------------------------------------------------------
PT3_PLAYMUSIC:
; AÑADIDO PARA SOPORTE 50 Y 60 HZ
;-----------------------------------------------------------------------
	LD	A, [PT3_HERCIOS]
	AND	128
	JP NZ,	PT3_REPLAYER.PT3_PLAY
	LD 	A, [PT3_60_50]
	DEC 	A
	LD 	[PT3_60_50], A
	JP Z,	.RESTORECOPY
	CALL 	PT3_REPLAYER.PT3_PLAY
	LD 	HL, PT3_REPLAYER.PT3_AYREGS
	LD 	DE, PT3_AYREGS_BAK
	LD 	BC, 14
	LDIR
	RET
.RESTORECOPY:
	LD 	A, 6
	LD	[PT3_60_50], A
	LD	HL, PT3_AYREGS_BAK
	LD	DE, PT3_REPLAYER.PT3_AYREGS
	LD	BC, 14
	LDIR
	RET
;-----------------------------------------------------------------------

	ENDMODULE SONIDO
;-----------------------------------------------------------------------
;                            FIN SONIDO
;-----------------------------------------------------------------------

