;-----------------------------------------------------------
;| ------------------------------------------------------- |
;| |                    I N I C I O                      | |
;| ------------------------------------------------------- |
;-----------------------------------------------------------
; Pletter v0.5c MSX unpacker - XL2S Entertainment 2008
; Copyright (c) 2002-2003 Team Bomba.
;-----------------------------------------------------------
	MODULE DEPLETTER
MACRO GETBIT
	ADD	A, A			; A<<1 -> CF			; T4
	CALL Z,	PLETTER_getbit		; IF( ZF ) CALL PLETTER_getbit	; T17/10 + T27 = T48/41
ENDMACRO
MACRO GETBITEXX
	ADD	A, A			; A<<1 -> CF				; T4
	CALL Z,	PLETTER_getbitexx	; IF( ZF ) CALL PLETTER_getbitexx 	; T17/10 + T35 = T56/49
ENDMACRO
; DEFINE PLETTER_LENGTHINDATA 1
DEFINE USAR_PLETTER 		1
DEFINE USAR_PRETTER_VRAM 	1
;-----------------------------------------------------------

;-----------------------------------------------------------
IFDEF USAR_PLETTER
@DEPLETTER:
; Entrada:	HL = RAM/ROM source
;		DE = RAM desination
; Salida:	
; Registros:	Todos
; Requisitos:	Ninguno
;-----------------------------------------------------------
IFDEF PLETTER_LENGTHINDATA
[2]	INC	HL
ENDIF
; INICIALIZACIÓN
	LD	A, [HL]			; A=[HL]			; T7
	INC	HL			; ++HL				; T11
	EXX				; BC, DE, HL <->  BC', DE', HL'	; T4
	LD	DE, 0			; DE'=0				; T10
	ADD	A, A			; A<<1 -> CF			; T4
	INC	A			; ++A				; T4
	RL	E			; ROTATE LEFT E' -> CF		; T8
	ADD	A, A			; A<<1 -> CF			; T4
	RL	E			; ROTATE LEFT E' -> CF		; T8
	ADD 	A, A			; A<<1 -> CF			; T4
[2]	RL	E			; ROTATE LEFT E' -> CF		; T16
	LD	HL, PLETTER_modes	; HL'=PLETTER_modes		; T10
	ADD	HL, DE			; HL'+=DE'			; T11
	LD	E, [HL]			; E'=[HL']			; T11
	LD	IXL, E			; IXL=E'			; T8
	INC	HL			; ++HL'				; T6
	LD	E, [HL]			; E'=[HL']			; T7
	LD	IXH, E			; IXH'=E'			; T8
	LD	E, 1			; E'=1				; T7
	EXX				; BC', DE', HL' <->  BC, DE, HL	; T4
	LD	IY, PLETTER_loop	; IY=PLETTER_loop		; T14
; MAIN DEPACK LOOP
PLETTER_literal:				
	LDI				; [DE]=[HL]; ++DE; ++HL; --BC;	; T16
PLETTER_loop:
	GETBIT				; T48/41
	JP NC,	PLETTER_literal		; IF( !CF ) GOTO PLETTER_literal
; COMPRESSED DATA 
	EXX				; BC, DE, HL <->  BC', DE', HL'	; T4
	LD	H, D			; H'=D'
	LD	L, E			; L'=E'	
PLETTER_getlen:
	GETBITEXX
	JP NC,	.PLETTER_lenok	; IF( !CF ) GOTO .PLETTER_lenok
.PLETTER_lus:
	GETBITEXX
	ADC	HL, HL			; HL'<<1
	RET	C			; IF( CF ) RETURN
	GETBITEXX
	JP NC,	.PLETTER_lenok		; IF( !CF ) GOTO .PLETTER_lenok
	GETBITEXX
	ADC	HL, HL			; HL'<<1
	RET	C			; IF( CF ) RETURN
	GETBITEXX
	JP C,	.PLETTER_lus		; IF( CF ) GOTO .PLETTER_lus
.PLETTER_lenok:
	INC	HL			; ++HL'
	EXX				; BC', DE', HL' <->  BC, DE, HL		; T4
	LD	C, [HL]			; C=[HL]
	INC	HL			; ++HL
	LD	B, 0			; B=0
	BIT	7, C			; ZF = !(BIT 7 DE C)
	JP Z,	PLETTER_offsok		; IF( ZF ) GOTO PLETTER_offsok
	JP	[IX]			; GOTO [IX]				; T8
PLETTER_mode6:
	GETBIT				;					; T48/41
	RL	B			; ROTATE LEFT B -> CF			; T8
PLETTER_mode5:
	GETBIT				;					; T48/41
	RL	B			; ROTATE LEFT B -> CF			; T8
PLETTER_mode4:
	GETBIT				;					; T48/41
	RL	B			; ROTATE LEFT B -> CF			; T8
PLETTER_mode3:
	GETBIT				;					; T48/41
	RL	B			; ROTATE LEFT B -> CF			; T8
PLETTER_mode2:
	GETBIT				;					; T48/41
	RL	B			; ROTATE LEFT B -> CF			; T8
	GETBIT
	JP NC,	PLETTER_offsok		; IF(!CF) GOTO PLETTER_offsok		; T10
	OR	A			; A|=A -> FC=0				; T4
	INC	B			; ++B					; T4
	RES	7, C			; BIT 7 DE C = 0			; T8
PLETTER_offsok:
	INC	BC			; ++BC					; T6
	PUSH	HL			; PUSH( HL )				; T11
	EXX				; BC, DE, HL <->  BC', DE', HL'		; T4
	PUSH	HL			; PUSH( HL' )				; T11
	EXX				; BC', DE', HL' <->  BC, DE, HL		; T4
	LD	L, E			; L=E					; T4
	LD	H, D			; H=D					; T4
	SBC	HL, BC			; HL-=BC				; T15
	POP	BC			; POP( BC )				; T10
	LDIR				; WHILE( BC ) { [DE]=[HL]; ++DE; ++HL; --BC; }	; T21/16
	POP	HL			; POP( HL )				; T10
	JP	[IY]			; GOTO [IY]				; T8
PLETTER_getbit:				;					; TOTAL = T27
	LD	A, [HL]			; A=[HL]				; T7
	INC	HL			; ++HL					; T6
	RLA				; ROTATE LEFT A				; T4
	RET				; RETURN				; T10
PLETTER_getbitexx:			;					; TOTAL = T35
	EXX				; BC, DE, HL <->  BC', DE', HL'		; T4
	LD	A, [HL]			; A=[HL']				; T7
	INC	HL			; ++HL'					; T6
	EXX				; BC', DE', HL' <->  BC, DE, HL		; T4
	RLA				; ROTATE LEFT A				; T4
	RET				; RETURN				; T10
;-----------------------------------------------------------
PLETTER_modes:
	DW	PLETTER_offsok
	DW	PLETTER_mode2
	DW	PLETTER_mode3
	DW	PLETTER_mode4
	DW	PLETTER_mode5
	DW	PLETTER_mode6
ENDIF
;-----------------------------------------------------------

;-----------------------------------------------------------
IFDEF USAR_PRETTER_VRAM
@DEPLETTER_VRAM:
; Versión modificada para volcar directamente a VRAM.
; Entrada:	HL = RAM/ROM source
;		DE = VRAM desination
; Salida:
; Registros:	Todos
; Requisitos:	Desactivar interrupciones
;-----------------------------------------------------------
IFDEF PLETTER_LENGTHINDATA
[2]	INC	HL
ENDIF
	LD	A, E			; T4
	OUT	[VDP_CMD], A		; T11
	LD	A, D			; T4
	AND	$3F			; T7
	OR	$40			; T7	
	OUT	[VDP_CMD], A		; T11	T29
	LD	A, [HL]			; INICIALIZACIÓN
	INC	HL
	EXX				; BC, DE, HL <->  BC', DE', HL'	; T4
	LD	DE, 0
	ADD	A, A
	INC	A
	RL	E
	ADD	A, A
	RL	E
	ADD 	A, A
[2]	RL	E
	LD	HL, PLETTER_VRAM_modes
	ADD	HL, DE
	LD	E, [HL]
	LD	IXL, E
	INC	HL
	LD	E, [HL]
	LD	IXH, E
	LD	E, 1
	EXX				; BC', DE', HL' <->  BC, DE, HL	; T4
	LD	IY, PLETTER_VRAM_loop
PLETTER_VRAM_literal:			; MAIN DEPACK LOOP
	LD	C, VDP_DATA		; C=VDP_DATA			; T7
	OUTI				; PORT[C]=[HL]; ++HL; --B	; T16
	INC	DE			; ++DE				; T6
PLETTER_VRAM_loop:
	GETBIT
	JP NC,	PLETTER_VRAM_literal	; Velocidad...
; COMPRESSED DATA
	EXX				; BC, DE, HL <->  BC', DE', HL'	; T4
	LD	H, D
	LD	L, E
PLETTER_VRAM_getlen:
	GETBITEXX
	JP NC,	.PLETTER_VRAM_lenok	; Velocidad...
.PLETTER_VRAM_lus:
	GETBITEXX
	ADC	HL, HL
	RET	C
	GETBITEXX
	JP NC,	.PLETTER_VRAM_lenok	; Velocidad...
	GETBITEXX
	ADC	HL, HL
	RET	C
	GETBITEXX
	JP C,	.PLETTER_VRAM_lus
.PLETTER_VRAM_lenok:
	INC	HL
	EXX				; BC', DE', HL' <->  BC, DE, HL	; T4
	LD	C, [HL]
	INC	HL
	LD	B, 0
	BIT	7, C
	JP	Z, PLETTER_VRAM_offsok
	JP	[IX]
PLETTER_VRAM_mode6:
	GETBIT
	RL	B
PLETTER_VRAM_mode5:
	GETBIT
	RL	B
PLETTER_VRAM_mode4:
	GETBIT
	RL	B
PLETTER_VRAM_mode3:
	GETBIT
	RL	B
PLETTER_VRAM_mode2:
	GETBIT
	RL	B
	GETBIT
	JP NC,	PLETTER_VRAM_offsok	; Velocidad...
	OR	A
	INC	B
	RES	7, C
PLETTER_VRAM_offsok:
	INC	BC
	PUSH	HL
	EXX				; BC, DE, HL <->  BC', DE', HL'	; T4
	PUSH	HL			; PUSH( HL' )
	EXX				; BC', DE', HL' <->  BC, DE, HL	; T4
	LD	L, E
	LD	H, D
	SBC	HL, BC
	POP	BC
	PUSH	AF
.PLETTER_LOOP:
	LD	A, L			; T4
	OUT	[VDP_CMD], A		; T11
[2]	NOP				; T4	[2]
	LD	A, H			; T4
	OUT	[VDP_CMD], A		; T11
[3]	NOP				; T4	[3]
	IN	A, [VDP_DATA]		; T11
	EX	AF, AF'			; T4
	LD	A, E			; T4
	NOP				; T4
	OUT	[VDP_CMD], A		; T11
	LD	A, D			; T4
	AND	$3F			; T7
	OR	$40			; T7
	OUT	[VDP_CMD], A		; T11	
[2]	NOP				; T4	[2]
	EX	AF, AF'			; T4
	OUT	[VDP_DATA], A		; T11
	INC	DE			; T6
	CPI				; T16
	JP PE,	.PLETTER_LOOP		; T10
	POP	AF
	POP	HL
	JP	[IY]
;-----------------------------------------------------------
PLETTER_VRAM_modes:
	DW	PLETTER_VRAM_offsok
	DW	PLETTER_VRAM_mode2
	DW	PLETTER_VRAM_mode3
	DW	PLETTER_VRAM_mode4
	DW	PLETTER_VRAM_mode5
	DW	PLETTER_VRAM_mode6
ENDIF
;-----------------------------------------------------------
	
	ENDMODULE DEPLETTER
;-----------------------------------------------------------
;| ------------------------------------------------------- |
;| |                      F I N                          | |
;| ------------------------------------------------------- |
;-----------------------------------------------------------
