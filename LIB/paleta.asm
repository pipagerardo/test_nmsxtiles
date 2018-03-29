; VDP_DATA = $98	; PORT [$88] | [$98] VRAM read/write
; VDP_CMD  = $99	; PORT [$89] | [$99] VDP registers read/write
; VDP_PAL  = $9A 	; Palette registers write

	MODULE PALETA
; -------------------------------------------------------------------
CAMBIA:
; Rutina de cambio de color de la paleta de alta velocidad...
; Entrada:	HL	Tabla con la paleta de color
; Salida:	--
; Registros:	AF, BC, HL
; Requisitos:	Desactivar Interrupciones
;		El color 0 siempre debe ser 0 - transparente
;		La componentes de color son Red, Blue y Green
;		Los valores de las componentes son de 0 a 7, no sobrepasarlo
; -------------------------------------------------------------------
	LD	A, [HL]		; T7	A = COLOR_NUMBER
	CP	0		; T7	
	RET	Z		; T5/11	IF ( A == 0 ) RETURN
	INC	HL		; T11
	OUT	[VDP_CMD], A	; T11	OUT -> COLOR_NUMBER
	LD	A, 16		; T4	A = REGISTRO #16
	OR	128		; T7
	OUT	[VDP_CMD], A	; T11	OUT -> REGISTRO #16
	LD      A, [HL]		; T7	A = RED
	INC     HL		; T11	++HL
;[4]	SLA     A		; T8	A << 4
[4]	RLCA			; T4	A << 4
	LD      B, A		; T4	B = A
	LD      A, [HL]		; T7	A = BLUE
	INC     HL		; T11	++HL
	OR      B		; T4	A |= B
	OUT     [VDP_PAL], A	; T11 	OUT -> RED + BLUE
	NOP			; T4
	LD      A, [HL]		; T7	A = GREEN
	OUT     [VDP_PAL], A	; T11	OUT -> GREEN
	INC     HL		; T11
	JP      CAMBIA		; T10  

; -------------------------------------------------------------------
TABLA:
; --------------------------------------------------------
;    [0~15] Decimal [0~7]      Binary VDP      Hexadecimal
;   DB    NN, R, B, G    ; 0RRR0BBB 00000GGG ; 0xAARRGGBB 
; --------------------------------------------------------
    DB     1, 0, 0, 0    ; 00000000 00000000 ; 0XFF000000
    DB     2, 1, 2, 5    ; 00010010 00000101 ; 0XFF21C842
    DB     3, 2, 3, 6    ; 00100011 00000110 ; 0XFF5EDC78
    DB     4, 2, 7, 2    ; 00100111 00000010 ; 0XFF5455ED
    DB     5, 3, 7, 3    ; 00110111 00000011 ; 0XFF7D76FC
    DB     6, 6, 2, 2    ; 01100010 00000010 ; 0XFFD4524D
    DB     7, 2, 7, 6    ; 00100111 00000110 ; 0XFF42EBF5
    DB     8, 7, 2, 2    ; 01110010 00000010 ; 0XFFFC5554
    DB     9, 7, 3, 3    ; 01110011 00000011 ; 0XFFFF7978
    DB    10, 6, 2, 5    ; 01100010 00000101 ; 0XFFD4C154
    DB    11, 6, 3, 6    ; 01100011 00000110 ; 0XFFE6CE80
    DB    12, 1, 1, 5    ; 00010001 00000101 ; 0XFF21B03B
    DB    13, 5, 5, 2    ; 01010101 00000010 ; 0XFFC95BBA
    DB    14, 6, 6, 6    ; 01100110 00000110 ; 0XFFCCCCCC
    DB    15, 7, 7, 7    ; 01110111 00000111 ; 0XFFFFFFFF
    DB     0, 0, 0, 0    ; 00000000 00000000 ; 0XFF000000
; -------------------------------------------------------------------

	ENDMODULE PALETA

; -------------------------------------------------------------------