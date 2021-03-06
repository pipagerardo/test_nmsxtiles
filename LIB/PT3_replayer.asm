;-----------------------------------------------------------
;| ------------------------------------------------------- |
;| |                    I N I C I O                      | |
;| ------------------------------------------------------- |
;-----------------------------------------------------------
	MODULE PT3_REPLAYER
	
; --- PT3 REPLAYER WORKING ON ROM ---
; --- Can be assembled with asMSX ---
; --- ROM version: MSX-KUN        ---
; --- asMSX version: SapphiRe     ---
; Based on MSX version of PT3 by Dioniso
;
; This version of the replayer uses a fixed volume and note table, if you need a 
; different note table you can copy it from TABLES.TXT file, distributed with the
; original PT3 distribution. This version also allows the use of PT3 commands.
;
; PLAY and PSG WRITE routines seperated to allow independent calls
;
; ROM LENGTH: 1528 bytes
; RAM LENGTH:  382 bytes

; --- VARIABLES ---

PT3_SETUP:	#	1	;set bit0 to 1, if you want to play without looping
				;bit7 is set each time, when loop point is passed
PT3_MODADDR:	#	2
PT3_CrPsPtr:	#	2
PT3_SAMPTRS:	#	2
PT3_OrnPtrs:	#	2
PT3_PDSP:	#	2
PT3_CSP:	#	2
PT3_PSP:	#	2
PT3_PrNote:	#	1
PT3_PrSlide:	#	2
PT3_AdInPtA:	#	2
PT3_AdInPtB:	#	2
PT3_AdInPtC:	#	2
PT3_LPosPtr:	#	2
PT3_PatsPtr:	#	2
PT3_Delay:	#	1
PT3_AddToEn:	#	1
PT3_Env_Del:	#	1
PT3_ESldAdd:	#	2
PT3_VARS:	#	0
PT3_ChanA:	#	29	; CHNPRM_Size
PT3_ChanB:	#	29	; CHNPRM_Size
PT3_ChanC:	#	29	; CHNPRM_Size
;GlobalVars:
PT3_DelyCnt:	#	1
PT3_CurESld:	#	2
PT3_CurEDel:	#	1
PT3_Ns_Base_AddToNs:
PT3_Ns_Base:	#	1
PT3_AddToNs:	#	1
PT3_AYREGS:	#	0
PT3_VT_:	#	14
PT3_EnvBase:	#	2
PT3_VAR0END:	#	240

; --- CONSTANT VALUES DEFINITION ---

;ChannelsVars
;struc	CHNPRM
;reset group
CHNPRM_PsInOr	= 0	;RESB 1
CHNPRM_PsInSm	= 1	;RESB 1
CHNPRM_CrAmSl	= 2	;RESB 1
CHNPRM_CrNsSl	= 3	;RESB 1
CHNPRM_CrEnSl	= 4	;RESB 1
CHNPRM_TSlCnt	= 5	;RESB 1
CHNPRM_CrTnSl	= 6	;RESW 1
CHNPRM_TnAcc	= 8	;RESW 1
CHNPRM_COnOff	= 10	;RESB 1
;reset group

CHNPRM_OnOffD	= 11	;RESB 1

;IX for PT3_DECOD here [+12]
CHNPRM_OffOnD	= 12	;RESB 1
CHNPRM_OrnPtr	= 13	;RESW 1
CHNPRM_SamPtr	= 15	;RESW 1
CHNPRM_NNtSkp	= 17	;RESB 1
CHNPRM_Note	= 18	;RESB 1
CHNPRM_SlToNt	= 19	;RESB 1
CHNPRM_Env_En	= 20	;RESB 1
CHNPRM_Flags	= 21	;RESB 1
 ;Enabled - 0,SimpleGliss - 2
CHNPRM_TnSlDl	= 22	;RESB 1
CHNPRM_TSlStp	= 23	;RESW 1
CHNPRM_TnDelt	= 25	;RESW 1
CHNPRM_NtSkCn	= 27	;RESB 1
CHNPRM_Volume	= 28	;RESB 1
CHNPRM_Size	= 29	;RESB 1
;endstruc

;struc	AR
AR_TonA		= 0	;RESW 1
AR_TonB		= 2	;RESW 1
AR_TonC		= 4	;RESW 1
AR_Noise	= 6	;RESB 1
AR_Mixer	= 7	;RESB 1
AR_AmplA	= 8	;RESB 1
AR_AmplB	= 9	;RESB 1
AR_AmplC	= 10	;RESB 1
AR_Env		= 11	;RESW 1
AR_EnvTp	= 13	;RESB 1
;endstruc

;-----------------------------------------------------------
; --- CODE STARTS HERE ---
PT3_CHECKLP:	
	LD	HL, PT3_SETUP
	SET	7, [HL]
	BIT	0, [HL]
	RET	Z
	POP	HL
	LD	HL, PT3_DelyCnt
	INC	[HL]
	LD	HL, PT3_ChanA + CHNPRM_NtSkCn
	INC	[HL]
PT3_MUTE:
	XOR	A
	LD	H, A
	LD	L, A
	LD	[PT3_AYREGS+AR_AmplA], A
	LD	[PT3_AYREGS+AR_AmplB], HL
	JP	ROUT_A0
;-----------------------------------------------------------
PT3_INIT:	;HL - AddressOfModule - 100
	LD	[PT3_MODADDR], HL
	PUSH	HL
	LD 	DE, 100
	ADD	HL, DE
	LD	A, [HL]
	LD	[PT3_Delay], A
	PUSH	HL
	POP	IX
	ADD	HL, DE
	LD	[PT3_CrPsPtr], HL
	LD	E, [IX+102-100]
	ADD	HL, DE
	INC	HL
	LD	[PT3_LPosPtr], HL
	POP	DE
	LD	L, [IX+103-100]
	LD	H, [IX+104-100]
	ADD	HL, DE
	LD	[PT3_PatsPtr], HL
	LD	HL, 169
	ADD	HL, DE
	LD	[PT3_OrnPtrs], HL
	LD	HL, 105
	ADD	HL, DE
	LD	[PT3_SAMPTRS], HL
	LD	HL, PT3_SETUP
	RES	7, [HL]
; --- CREATE PT3 VOLUME TABLE (c) Ivan Roshin, adapted by SapphiRe ---
	LD	HL, $11
	LD	D, H
	LD	E, H
	LD	IX, PT3_VT_+16
	LD	B, 15
.INITV1:
	PUSH	HL
	ADD	HL, DE
	EX	DE, HL
	SBC	HL, HL
	LD	C, B
	LD	B, 16
.INITV2:
	LD	A, L
	RLA
	LD	A, H
	ADC	A, 0
	LD	[IX], A
	INC	IX
	ADD	HL, DE
	DJNZ	.INITV2
	POP	HL
	LD	A, E
	CP	$77
	JR NZ,	.INITV3
	INC	E
.INITV3:
	LD	B, C
	DJNZ	.INITV1
; --- INITIALIZE PT3 VARIABLES ---
	XOR	A
	LD	HL, PT3_VARS
	LD	[HL], A
	LD	DE, PT3_VARS+1
	LD	BC, PT3_VAR0END-PT3_VARS-1
	LDIR
	INC	A
	LD	[PT3_DelyCnt], A
	LD	HL, $F001 			;H - CHNPRM_Volume, L - CHNPRM_NtSkCn
	LD	[PT3_ChanA+CHNPRM_NtSkCn], HL
	LD	[PT3_ChanB+CHNPRM_NtSkCn], HL
	LD	[PT3_ChanC+CHNPRM_NtSkCn], HL
	LD	HL, EMPTYSAMORN
	LD	[PT3_AdInPtA], HL		;ptr to zero
	LD	[PT3_ChanA+CHNPRM_OrnPtr], HL	;ornament 0 is "0,1,0"
	LD	[PT3_ChanB+CHNPRM_OrnPtr], HL	;in all versions from
	LD	[PT3_ChanC+CHNPRM_OrnPtr], HL	;3.xx to 3.6x and VTII
	LD	[PT3_ChanA+CHNPRM_SamPtr], HL	;S1 There is no default
	LD	[PT3_ChanB+CHNPRM_SamPtr], HL	;S2 sample in PT3, so, you
	LD	[PT3_ChanC+CHNPRM_SamPtr], HL	;S3 can comment S1,2,3; see
						;also EMPTYSAMORN comment
	RET
;-----------------------------------------------------------

;-----------------------------------------------------------
;pattern decoder
PD_OrSm:
	LD	[IX+(CHNPRM_Env_En-12)], 0
	CALL	PT3_SETORN
	LD	A, [BC]
	INC	BC
	RRCA
PD_SAM:
	ADD	A, A
PD_SAM_:
	LD	E, A
	LD	D,0
	LD	HL, [PT3_SAMPTRS]
	ADD	HL, DE
	LD	E, [HL]
	INC	HL
	LD	D, [HL]
	LD	HL, [PT3_MODADDR]
	ADD	HL, DE
	LD	[IX+(CHNPRM_SamPtr-12)], L
	LD	[IX+(CHNPRM_SamPtr+1-12)], H
	JR	PD_LOOP
PD_VOL:
	RLCA
	RLCA
	RLCA
	RLCA
	LD	[IX+(CHNPRM_Volume-12)], A
	JR	PD_LP2
PD_EOff:
	LD	[IX+(CHNPRM_Env_En-12)], A
	LD	[IX+(CHNPRM_PsInOr-12)], A
	JR	PD_LP2
PD_SorE:
	DEC	A
	JR NZ,	.PD_ENV
	LD	A, [BC]
	INC	BC
	LD	[IX+(CHNPRM_NNtSkp-12)], A
	JR	PD_LP2
.PD_ENV:
	CALL	PT3_SETENV
	JR	PD_LP2
PD_ORN:
	CALL	PT3_SETORN
	JR	PD_LOOP
PD_ESAM:	
	LD	[IX+(CHNPRM_Env_En-12)], A
	LD	[IX+(CHNPRM_PsInOr-12)], A
	CALL NZ, PT3_SETENV
	LD	A, [BC]
	INC	BC
	JR	PD_SAM_
PT3_DECOD:
	LD	A, [IX+(CHNPRM_Note-12)]
	LD	[PT3_PrNote],A
	LD	L, [IX+(CHNPRM_CrTnSl-12)]
	LD	H, [IX+(CHNPRM_CrTnSl+1-12)]
	LD	[PT3_PrSlide],HL
PD_LOOP:
	LD	DE, $2010
PD_LP2:
	LD	A,[BC]
	INC	BC
	ADD	A, E
	JR C,	PD_OrSm
	ADD	A, D
	JR Z,	PD_FIN
	JR C,	PD_SAM
	ADD	A, E
	JR Z,	PD_REL
	JR C,	PD_VOL
	ADD	A, E
	JR Z,	PD_EOff
	JR C,	PD_SorE
	ADD	A, 96
	JR C,	PD_NOTE
	ADD	A, E
	JR C,	PD_ORN
	ADD	A, D
	JR C,	PD_NOIS
	ADD	A, E
	JR C,	PD_ESAM
	ADD	A, A
	LD	E, A
; Esto funciona en AsMSX pero n� en sjasm y se cuelga...
;	LD HL,((SPCCOMS+$DF20)%65536)	; Adapted from original Speccy version (saves 6 bytes)
; Correcci�n para que funcione en sjasm y no pete...
	LD	HL, (SPCCOMS+57120)%65536	; Adapted from original Speccy version (saves 6 bytes)
	ADD	HL, DE
	LD	E, [HL]
	INC	HL
	LD	D, [HL]
	PUSH	DE
	JR	PD_LOOP
PD_NOIS:
	LD	[PT3_Ns_Base], A
	JR	PD_LP2
PD_REL:
	RES	0, [IX+(CHNPRM_Flags-12)]
	JR	PD_RES
PD_NOTE:
	LD	[IX+(CHNPRM_Note-12)],A
	SET	0, [IX+(CHNPRM_Flags-12)]
	XOR	A
PD_RES:	
	LD	[PT3_PDSP],SP
	LD	SP,IX
	LD	H,A
	LD	L,A
	PUSH	HL
	PUSH	HL
	PUSH	HL
	PUSH	HL
	PUSH	HL
	PUSH	HL
	LD	SP, [PT3_PDSP]
PD_FIN:	
	LD	A, [IX+(CHNPRM_NNtSkp-12)]
	LD	[IX+(CHNPRM_NtSkCn-12)], A
	RET
C_PORTM:
	RES	2, [IX+(CHNPRM_Flags-12)]
	LD	A, [BC]
	INC	BC
;SKIP PRECALCULATED TONE DELTA [BECAUSE CANNOT BE RIGHT AFTER PT3 COMPILATION]
	INC	BC
	INC	BC
	LD	[IX+(CHNPRM_TnSlDl-12)], A
	LD	[IX+(CHNPRM_TSlCnt-12)], A
	LD	DE, PT3_NT_
	LD	A,[IX+(CHNPRM_Note-12)]
	LD	[IX+(CHNPRM_SlToNt-12)], A
	ADD	A, A
	LD	L, A
	LD	H, 0
	ADD	HL, DE
	LD	A, [HL]
	INC	HL
	LD	H, [HL]
	LD	L, A
	PUSH	HL
	LD	A, [PT3_PrNote]
	LD	[IX+(CHNPRM_Note-12)], A
	ADD	A, A
	LD	L, A
	LD	H, 0
	ADD	HL, DE
	LD	E, [HL]
	INC	HL
	LD	D, [HL]
	POP	HL
	SBC	HL, DE
	LD	[IX+(CHNPRM_TnDelt-12)], L
	LD	[IX+(CHNPRM_TnDelt+1-12)], H
	LD	DE, [PT3_PrSlide]
	LD	[IX+(CHNPRM_CrTnSl-12)], E
	LD	[IX+(CHNPRM_CrTnSl+1-12)], D
	LD	A, [BC] 			;SIGNED TONE STEP
	INC	BC
	EX	AF, AF'
	LD	A, [BC]
	INC	BC
	AND	A
	JR Z,	.NOSIG
	EX	DE, HL
.NOSIG:
	SBC	HL, DE
	JP P,	SET_STP
	CPL
	EX	AF, AF'
	NEG
	EX	AF, AF'
SET_STP:
	LD	[IX+(CHNPRM_TSlStp+1-12)], A
	EX	AF, AF'
	LD	[IX+(CHNPRM_TSlStp-12)], A
	LD	[IX+(CHNPRM_COnOff-12)], 0
	RET
C_GLISS:
	SET 	2, [IX+(CHNPRM_Flags-12)]
	LD	A, [BC]
	INC	BC
	LD	[IX+(CHNPRM_TnSlDl-12)], A
	LD	[IX+(CHNPRM_TSlCnt-12)], A
	LD	A, [BC]
	INC	BC
	EX	AF, AF'
	LD	A, [BC]
	INC	BC
	JR	SET_STP
C_SMPOS:
	LD	A, [BC]
	INC	BC
	LD	[IX+(CHNPRM_PsInSm-12)], A
	RET
C_ORPOS:
	LD	A, [BC]
	INC	BC
	LD	[IX+(CHNPRM_PsInOr-12)], A
	RET
C_VIBRT:
	LD	A, [BC]
	INC	BC
	LD	[IX+(CHNPRM_OnOffD-12)], A
	LD	[IX+(CHNPRM_COnOff-12)], A
	LD	A, [BC]
	INC	BC
	LD	[IX+(CHNPRM_OffOnD-12)], A
	XOR	A
	LD	[IX+(CHNPRM_TSlCnt-12)], A
	LD	[IX+(CHNPRM_CrTnSl-12)], A
	LD	[IX+(CHNPRM_CrTnSl+1-12)], A
	RET
C_ENGLS:
	LD	A, [BC]
	INC	BC
	LD	[PT3_Env_Del], A
	LD	[PT3_CurEDel], A
	LD	A, [BC]
	INC	BC
	LD	L,A
	LD	A, [BC]
	INC	BC
	LD	H, A
	LD	[PT3_ESldAdd], HL
	RET
C_DELAY:
	LD	A, [BC]
	INC	BC
	LD	[PT3_Delay], A
	RET
;-----------------------------------------------------------
PT3_SETENV:
	LD	[IX+(CHNPRM_Env_En-12)], E
	LD	[PT3_AYREGS+AR_EnvTp], A
	LD	A, [BC]
	INC	BC
	LD	H, A
	LD	A, [BC]
	INC	BC
	LD	L, A
	LD	[PT3_EnvBase], HL
	XOR	A
	LD	[IX+(CHNPRM_PsInOr-12)], A
	LD	[PT3_CurEDel], A
	LD	H, A
	LD	L, A
	LD	[PT3_CurESld], HL
C_NOP:
	RET
PT3_SETORN:
	ADD	A, A
	LD	E, A
	LD	D, 0
	LD	[IX+(CHNPRM_PsInOr-12)], D
	LD	HL, [PT3_OrnPtrs]
	ADD	HL, DE
	LD	E, [HL]
	INC	HL
	LD	D, [HL]
	LD	HL, [PT3_MODADDR]
	ADD	HL, DE
	LD	[IX+(CHNPRM_OrnPtr-12)], L
	LD	[IX+(CHNPRM_OrnPtr+1-12)], H
	RET
	
; ALL 16 ADDRESSES TO PROTECT FROM BROKEN PT3 MODULES
SPCCOMS:
	DW C_NOP,   C_GLISS, C_PORTM, C_SMPOS
	DW C_ORPOS, C_VIBRT, C_NOP,   C_NOP
	DW C_ENGLS, C_DELAY, C_NOP,   C_NOP
	DW C_NOP,   C_NOP,   C_NOP,   C_NOP
	
PT3_CHREGS:
	XOR	A
	LD	[PT3_AYREGS+AR_AmplC], A
	BIT	0, [IX+CHNPRM_Flags]
	PUSH	HL
	JP Z,	.CH_EXIT
	LD	[PT3_CSP], SP
	LD	L, [IX+CHNPRM_OrnPtr]
	LD	H, [IX+CHNPRM_OrnPtr+1]
	LD	SP, HL
	POP	DE
	LD	H, A
	LD	A, [IX+CHNPRM_PsInOr]
	LD	L, A
	ADD	HL, SP
	INC	A
	CP	D
	JR C,	.CH_ORPS
	LD	A, E
.CH_ORPS:
	LD	[IX+CHNPRM_PsInOr], A
	LD	A, [IX+CHNPRM_Note]
	ADD	A, [HL]
	JP P,	.CH_NTP
	XOR	A
.CH_NTP:
	CP	96
	JR C,	.CH_NOK
	LD	A, 95
.CH_NOK:
	ADD	A, A
	EX	AF, AF'
	LD	L, [IX+CHNPRM_SamPtr]
	LD	H, [IX+CHNPRM_SamPtr+1]
	LD	SP, HL
	POP	DE
	LD	H, 0
	LD	A, [IX+CHNPRM_PsInSm]
	LD	B, A
	ADD	A, A
	ADD	A, A
	LD	L, A
	ADD	HL, SP
	LD	SP, HL
	LD	A, B
	INC	A
	CP	D
	JR C,	.CH_SMPS
	LD	A, E
.CH_SMPS:
	LD	[IX+CHNPRM_PsInSm], A
	POP	BC
	POP	HL
	LD	E, [IX+CHNPRM_TnAcc]
	LD	D, [IX+CHNPRM_TnAcc+1]
	ADD	HL, DE
	BIT	6, B
	JR	Z, .CH_NOAC
	LD	[IX+CHNPRM_TnAcc], L
	LD	[IX+CHNPRM_TnAcc+1], H
.CH_NOAC:
	EX	DE, HL
	EX	AF, AF'
	LD	L, A
	LD	H, 0
	LD	SP, PT3_NT_
	ADD	HL, SP
	LD	SP, HL
	POP	HL
	ADD	HL, DE
	LD	E, [IX+CHNPRM_CrTnSl]
	LD	D, [IX+CHNPRM_CrTnSl+1]
	ADD	HL, DE
	LD	SP, [PT3_CSP]
	EX	[SP], HL
	XOR	A
	OR	[IX+CHNPRM_TSlCnt]
	JR Z,	.CH_AMP
	DEC	[IX+CHNPRM_TSlCnt]
	JR NZ,	.CH_AMP
	LD	A, [IX+CHNPRM_TnSlDl]
	LD	[IX+CHNPRM_TSlCnt], A
	LD	L, [IX+CHNPRM_TSlStp]
	LD	H, [IX+CHNPRM_TSlStp+1]
	LD	A, H
	ADD	HL, DE
	LD	[IX+CHNPRM_CrTnSl], L
	LD	[IX+CHNPRM_CrTnSl+1], H
	BIT	2, [IX+CHNPRM_Flags]
	JR NZ,	.CH_AMP
	LD	E, [IX+CHNPRM_TnDelt]
	LD	D, [IX+CHNPRM_TnDelt+1]
	AND	A
	JR Z,	.CH_STPP
	EX	DE, HL
.CH_STPP:
	SBC	HL, DE
	JP M,	.CH_AMP
	LD	A, [IX+CHNPRM_SlToNt]
	LD	[IX+CHNPRM_Note], A
	XOR	A
	LD	[IX+CHNPRM_TSlCnt], A
	LD	[IX+CHNPRM_CrTnSl], A
	LD	[IX+CHNPRM_CrTnSl+1], A
.CH_AMP:
	LD	A, [IX+CHNPRM_CrAmSl]
	BIT	7, C
	JR Z,	.CH_NOAM
	BIT	6, C
	JR Z,	.CH_AMIN
	CP	15
	JR Z,	.CH_NOAM
	INC	A
	JR	.CH_SVAM
.CH_AMIN:
	CP	-15
	JR Z,	.CH_NOAM
	DEC	A
.CH_SVAM:
	LD	[IX+CHNPRM_CrAmSl], A
.CH_NOAM:
	LD	L, A
	LD	A, B
	AND	15
	ADD	A, L
	JP P,	.CH_APOS
	XOR	A
.CH_APOS:
	CP	16
	JR C,	.CH_VOL
	LD	A, 15
.CH_VOL:
	OR	[IX+CHNPRM_Volume]
	LD	L, A
	LD	H, 0
	LD	DE, PT3_VT_
	ADD	HL, DE
	LD	A, [HL]
.CH_ENV:
	BIT	0, C
	JR NZ,	.CH_NOEN
	OR	[IX+CHNPRM_Env_En]
.CH_NOEN:
	LD	[PT3_AYREGS+AR_AmplC], A
	BIT	7, B
	LD	A, C
	JR Z,	.NO_ENSL
	RLA
	RLA
	SRA	A
	SRA	A
	SRA	A
	ADD	A,[IX+CHNPRM_CrEnSl]	;SEE COMMENT BELOW
	BIT	5, B
	JR Z,	.NO_ENAC
	LD	[IX+CHNPRM_CrEnSl], A
.NO_ENAC:
	LD	HL, PT3_AddToEn
	ADD	A, [HL]		;BUG IN PT3 - NEED WORD HERE. ;FIX IT IN NEXT VERSION?
	LD	[HL],A
	JR	.CH_MIX
.NO_ENSL:
	RRA
	ADD	A, [IX+CHNPRM_CrNsSl]
	LD	[PT3_AddToNs], A
	BIT	5, B
	JR Z,	.CH_MIX
	LD	[IX+CHNPRM_CrNsSl], A
.CH_MIX:
	LD	A, B
	RRA
	AND	$48
.CH_EXIT:
	LD	HL, PT3_AYREGS+AR_Mixer
	OR	[HL]
	RRCA
	LD	[HL], A
	POP	HL
	XOR	A
	OR	[IX+CHNPRM_COnOff]
	RET	Z
	DEC	[IX+CHNPRM_COnOff]
	RET	NZ
	XOR	[IX+CHNPRM_Flags]
	LD	[IX+CHNPRM_Flags], A
	RRA
	LD	A, [IX+CHNPRM_OnOffD]
	JR	C, .CH_ONDL
	LD	A, [IX+CHNPRM_OffOnD]
.CH_ONDL:
	LD	[IX+CHNPRM_COnOff], A
	RET
PT3_PLAY:
	XOR	A
	LD	[PT3_AddToEn], A
	LD	[PT3_AYREGS+AR_Mixer], A
	DEC	A
	LD	[PT3_AYREGS+AR_EnvTp], A
	LD	HL, PT3_DelyCnt
	DEC	[HL]
	JP	NZ, .PL2
	LD	HL, PT3_ChanA + CHNPRM_NtSkCn
	DEC	[HL]
	JR NZ,	.PL1B
	LD	BC, [PT3_AdInPtA]
	LD	A, [BC]
	AND	A
	JR NZ,	.PL1A
	LD	D, A
	LD	[PT3_Ns_Base], A
	LD	HL, [PT3_CrPsPtr]
	INC	HL
	LD	A, [HL]
	INC	A
	JR NZ,	.PLNLP
	CALL	PT3_CHECKLP
	LD	HL, [PT3_LPosPtr]
	LD	A, [HL]
	INC	A
.PLNLP:
	LD	[PT3_CrPsPtr], HL
	DEC	A
	ADD	A, A
	LD	E, A
	RL	D
	LD	HL, [PT3_PatsPtr]
	ADD	HL, DE
	LD	DE, [PT3_MODADDR]
	LD	[PT3_PSP], SP
	LD	SP, HL
	POP	HL
	ADD	HL, DE
	LD	B, H
	LD	C, L
	POP	HL
	ADD	HL, DE
	LD	[PT3_AdInPtB], HL
	POP	HL
	ADD	HL, DE
	LD	[PT3_AdInPtC], HL
	LD	SP,[PT3_PSP]
.PL1A:	
	LD	IX, PT3_ChanA + 12
	CALL	PT3_DECOD
	LD	[PT3_AdInPtA], BC
.PL1B:
	LD	HL, PT3_ChanB + CHNPRM_NtSkCn
	DEC	[HL]
	JR NZ,	.PL1C
	LD	IX, PT3_ChanB + 12
	LD	BC, [PT3_AdInPtB]
	CALL	PT3_DECOD
	LD	[PT3_AdInPtB], BC
.PL1C:
	LD	HL, PT3_ChanC + CHNPRM_NtSkCn
	DEC	[HL]
	JR NZ,	.PL1D
	LD	IX, PT3_ChanC + 12
	LD	BC, [PT3_AdInPtC]
	CALL	PT3_DECOD
	LD	[PT3_AdInPtC],BC
.PL1D:
	LD	A, [PT3_Delay]
	LD	[PT3_DelyCnt], A
.PL2:	
	LD	IX, PT3_ChanA
	LD	HL, [PT3_AYREGS+AR_TonA]
	CALL	PT3_CHREGS
	LD	[PT3_AYREGS+AR_TonA], HL
	LD	A, [PT3_AYREGS+AR_AmplC]
	LD	[PT3_AYREGS+AR_AmplA], A
	LD	IX, PT3_ChanB
	LD	HL, [PT3_AYREGS+AR_TonB]
	CALL	PT3_CHREGS
	LD	[PT3_AYREGS+AR_TonB], HL
	LD	A, [PT3_AYREGS+AR_AmplC]
	LD	[PT3_AYREGS+AR_AmplB],A
	LD	IX, PT3_ChanC
	LD	HL, [PT3_AYREGS+AR_TonC]
	CALL	PT3_CHREGS
	LD	[PT3_AYREGS+AR_TonC], HL
	LD	HL, [PT3_Ns_Base_AddToNs]
	LD	A, H
	ADD	A, L
	LD	[PT3_AYREGS+AR_Noise], A
	LD	A, [PT3_AddToEn]
	LD	E, A
	ADD	A, A
	SBC	A, A
	LD	D, A
	LD	HL, [PT3_EnvBase]
	ADD	HL, DE
	LD	DE, [PT3_CurESld]
	ADD	HL, DE
	LD	[PT3_AYREGS+AR_Env], HL
	XOR	A
	LD	HL, PT3_CurEDel
	OR	[HL]
	RET	Z
	DEC	[HL]
	RET	NZ
	LD	A, [PT3_Env_Del]
	LD	[HL], A
	LD	HL, [PT3_ESldAdd]
	ADD	HL, DE
	LD	[PT3_CurESld], HL
	RET
;-----------------------------------------------------------

;-----------------------------------------------------------
PT3_ROUT:
	XOR A
; --- FIXES BITS 6 AND 7 OF MIXER ---
ROUT_A0:	
	LD	HL, PT3_AYREGS + AR_Mixer
	SET	7, [HL]
	RES	6, [HL]
	LD	C, $A0
	LD	HL, PT3_AYREGS
.LOUT:	
	OUT	[C], A
	INC 	C
	OUTI 
	DEC	C
	INC	A
	CP 	13
	JR NZ,	.LOUT
	OUT	[C], A
	LD	A, [HL]
	AND	A
	RET	M
	INC	C
	OUT	[C], A
	RET
;-----------------------------------------------------------

EMPTYSAMORN:
	DB 0, 1, 0, $90		; delete $90 if you don't need default sample

; Note table 2 [if you use another in Vortex Tracker II copy it and paste it from TABLES.TXT]
PT3_NT_	
	DW $0D10, $0C55, $0BA4, $0AFC, $0A5F, $09CA, $093D, $08B8, $083B, $07C5, $0755, $06EC
	DW $0688, $062A, $05D2, $057E, $052F, $04E5, $049E, $045C, $041D, $03E2, $03AB, $0376
	DW $0344, $0315, $02E9, $02BF, $0298, $0272, $024F, $022E, $020F, $01F1, $01D5, $01BB
	DW $01A2, $018B, $0174, $0160, $014C, $0139, $0128, $0117, $0107, $00F9, $00EB, $00DD
	DW $00D1, $00C5, $00BA, $00B0, $00A6, $009D, $0094, $008C, $0084, $007C, $0075, $006F
	DW $0069, $0063, $005D, $0058, $0053, $004E, $004A, $0046, $0042, $003E, $003B, $0037
	DW $0034, $0031, $002F, $002C, $0029, $0027, $0025, $0023, $0021, $001F, $001D, $001C
	DW $001A, $0019, $0017, $0016, $0015, $0014, $0012, $0011, $0010, $000F, $000E, $000D

	ENDMODULE PT3_REPLAYER
;-----------------------------------------------------------
;| ------------------------------------------------------- |
;| |                      F I N                          | |
;| ------------------------------------------------------- |
;-----------------------------------------------------------
