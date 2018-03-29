;-----------------------------------------------------------
;| ------------------------------------------------------- |
;| |                    I N I C I O                      | |
;| ------------------------------------------------------- |
;-----------------------------------------------------------
	MODULE AYFX_REPLAYER
	
; --- ayFX REPLAYER v1.31 ---
; --- v1.31	Fixed bug on previous version, only PSG channel C worked
; --- v1.3	Fixed volume and Relative volume versions on the same file, conditional compilation
; ---		Support for dynamic or fixed channel allocation
; --- v1.2f/r	ayFX bank support
; --- v1.11f/r	If a frame volume is zero then no AYREGS update
; --- v1.1f/r	Fixed volume for all ayFX streams
; --- v1.1	Explicit priority (as suggested by AR)
; --- v1.0f	Bug fixed (error when using noise)
; --- v1.0	Initial release

; --- DEFINE AYFXRELATIVE AS 0 FOR FIXED VOLUME VERSION ---
; --- DEFINE AYFXRELATIVE AS 1 FOR RELATIVE VOLUME VERSION ---
; DEFINE AYFXRELATIVE 1

ayFX_MODE	#	1	; ayFX mode = 1 to switching channel routine
ayFX_BANK	#	2	; Current ayFX Bank
ayFX_PRIORITY	#	1	; Current ayFX stream priotity
ayFX_POINTER	#	2	; Pointer to the current ayFX stream
ayFX_TONE	#	2	; Current tone of the ayFX stream
ayFX_NOISE	#	1	; Current noise of the ayFX stream
ayFX_VOLUME	#	1	; Current volume of the ayFX stream
ayFX_CHANNEL	#	1	; PSG channel to play the ayFX stream

IFDEF AYFXRELATIVE
ayFX_VT		#	2	; ayFX relative volume table pointer
ENDIF

; --- UNCOMMENT THIS IF YOU DON'T USE THIS REPLAYER WITH PT3 REPLAYER ---
; PT3_AYREGS:	#	14	; Ram copy of PSG registers
; --- UNCOMMENT THIS IF YOU DON'T USE THIS REPLAYER WITH PT3 REPLAYER ---

; ---          ayFX replayer setup          ---
; --- INPUT: HL -> pointer to the ayFX bank ---
ayFX_SETUP:
	LD	[ayFX_BANK], HL		; Current ayFX bank
	XOR	A			; a:=0
	LD	[ayFX_MODE], A		; Initial mode: fixed channel
	INC	A			; Starting channel (=1)
	LD	[ayFX_CHANNEL], A	; Updated
; --- End of an ayFX stream ---
ayFX_END:
	LD	A, 255			; Lowest ayFX priority
	LD	[ayFX_PRIORITY], A	; Priority saved (not playing ayFX stream)
	RET				; Return
; ---     INIT A NEW ayFX STREAM     ---
; --- INPUT: A -> sound to be played ---
; ---        C -> sound priority     ---
ayFX_INIT:
	PUSH	BC			; Store bc in stack
	PUSH	DE			; Store de in stack
	PUSH	HL			; Store hl in stack
; --- Check if the index is in the bank ---
	LD	B, A			; b:=a (new ayFX stream index)
	LD	HL, [ayFX_BANK]		; Current ayFX BANK
	LD	A, [HL]			; Number of samples in the bank
	OR	A			; If zero (means 256 samples)...
	JR Z,	.CHECK_PRI		; ...goto .CHECK_PRI
; The bank has less than 256 samples
	LD	A, B			; a:=b (new ayFX stream index)
	CP	[HL]			; If new index is not in the bank...
	LD	A, 2			; a:=2 (error 2: Sample not in the bank)
	JR NC,	.INIT_END		; ...we can't init it
; --- Check if the new priority is lower than the current one ---
; ---   Remember: 0 = highest priority, 15 = lowest priority  ---
.CHECK_PRI:	
	LD	A, B			; a:=b (new ayFX stream index)
	LD	A, [ayFX_PRIORITY]	; a:=Current ayFX stream priority
	CP	C			; If new ayFX stream priority is lower than current one...
	LD	A, 1			; a:=1 (error 1: A sample with higher priority is being played)
	JR	C, .INIT_END		; ...we don't start the new ayFX stream
; --- Set new priority ---
	LD	A, C			; a:=New priority
	AND	$0F			; We mask the priority
	LD	[ayFX_PRIORITY], A	; new ayFX stream priority saved in RAM
; --- Volume adjust using PT3 volume table ---
IFDEF AYFXRELATIVE
	LD	C, A			; c:=New priority (fixed)
	LD	A, 15			; a:=15
	SUB	C			; a:=15-New priority = relative volume
	JR Z,	.INIT_NOSOUND		; If priority is 15 -> no sound output (volume is zero)
[4]	ADD	A, A			; a:=a*16
	LD	E, A			; e:=a
	LD	D ,0			; de:=a
	LD	HL, PT3_VT_		; hl:=PT3 volume table
	ADD	HL, DE			; hl is a pointer to the relative volume table
	LD	[ayFX_VT], HL		; Save pointer
ENDIF
; --- Calculate the pointer to the new ayFX stream ---
	LD	DE, [ayFX_BANK]		; de:=Current ayFX bank
	INC	DE			; de points to the increments table of the bank
	LD	L, B			; l:=b (new ayFX stream index)
	LD	H, 0			; hl:=b (new ayFX stream index)
	ADD	HL, HL			; hl:=hl*2
	ADD	HL, DE			; hl:=hl+de (hl points to the correct increment)
	LD	E, [HL]			; e:=lower byte of the increment
	INC	HL			; hl points to the higher byte of the correct increment
	LD	D, [HL]			; de:=increment
	ADD	HL, DE			; hl:=hl+de (hl points to the new ayFX stream)
	LD	[ayFX_POINTER], HL	; Pointer saved in RAM
	XOR	A			; a:=0 (no errors)
.INIT_END:
	POP	HL			; Retrieve hl from stack
	POP	DE			; Retrieve de from stack
	POP	BC			; Retrieve bc from stack
	RET				; Return

; --- Init a sample with relative volume zero -> no sound output ---
IFDEF AYFXRELATIVE
.INIT_NOSOUND:
	LD	A, 255			; Lowest ayFX priority
	LD	[ayFX_PRIORITY], A	; Priority saved (not playing ayFX stream)
	JR	.INIT_END		; Jumps to .INIT_END
ENDIF

; --- PLAY A FRAME OF AN ayFX STREAM ---
ayFX_PLAY:
	LD	A, [ayFX_PRIORITY]	; a:=Current ayFX stream priority
	OR	A			; If priority has bit 7 on...
	RET	M			; ...return
; --- Calculate next ayFX channel (if needed) ---
	LD	A, [ayFX_MODE]		; ayFX mode
	AND	1			; If bit0=0 (fixed channel)...
	JR Z,	.TAKECB			; ...skip channel changing
	LD	HL, ayFX_CHANNEL	; Old ayFX playing channel
	DEC	[HL]			; New ayFX playing channel
	JR NZ,	.TAKECB			; If not zero jump to .TAKECB
	LD	[HL], 3			; If zero -> set channel 3
; --- Extract control byte from stream ---
.TAKECB:	
	LD	HL, [ayFX_POINTER]	; Pointer to the current ayFX stream
	LD	C, [HL]			; c:=Control byte
	INC	HL			; Increment pointer
; --- Check if there's new tone on stream ---
	BIT	5, C			; If bit 5 c is off...
	JR Z,	.CHECK_NN		; ...jump to .CHECK_NN (no new tone)
; --- Extract new tone from stream ---
	LD	E, [HL]			; e:=lower byte of new tone
	INC	HL			; Increment pointer
	LD	D, [HL]			; d:=higher byte of new tone
	INC	HL			; Increment pointer
	LD	[ayFX_TONE], DE		; ayFX tone updated
; --- Check if there's new noise on stream ---
.CHECK_NN:	
	BIT	6, C			; if bit 6 c is off...
	JR Z,	.SETPOINTER		; ...jump to .SETPOINTER (no new noise)
; --- Extract new noise from stream ---
	LD	A, [HL]			; a:=New noise
	INC	HL			; Increment pointer
	CP	$20			; If it's an illegal value of noise (used to mark end of stream)...
;	JR Z, 	ayFX_END		; ...jump to ayFX_END
	JP Z,	ayFX_END		; ...jump to ayFX_END
	LD	[ayFX_NOISE], A		; ayFX noise updated
; --- Update ayFX pointer ---
.SETPOINTER:	
	LD	[ayFX_POINTER], HL	; Update ayFX stream pointer
; --- Extract volume ---
	LD	A, C			; a:=Control byte
	AND	$0F			; lower nibble
; --- Fix the volume using PT3 Volume Table ---
IFDEF AYFXRELATIVE
	LD	HL, [ayFX_VT]		; hl:=Pointer to relative volume table
	LD	E, A			; e:=a (ayFX volume)
	LD	D, 0			; d:=0
	ADD	HL, DE			; hl:=hl+de (hl points to the relative volume of this frame
	LD	A, [HL]			; a:=ayFX relative volume
	OR	A			; If relative volume is zero...
ENDIF
	LD	[ayFX_VOLUME], A	; ayFX volume updated
	RET	Z			; ...return (don't copy ayFX values in to AYREGS)
; -------------------------------------
; --- COPY ayFX VALUES IN TO AYREGS ---
; -------------------------------------
; --- Set noise channel ---
	BIT	7, C			; If noise is off...
	JR NZ,	.SETMASKS		; ...jump to .SETMASKS
	LD	A, [ayFX_NOISE]		; ayFX noise value
	LD	[PT3_REPLAYER.PT3_AYREGS+6], A	; copied in to AYREGS (noise channel)
; --- Set mixer masks ---
.SETMASKS:
	LD	A, C			; a:=Control byte
	AND	$90			; Only bits 7 and 4 (noise and tone mask for psg reg 7)
	CP	$90			; If no noise and no tone...
	RET	Z			; ...return (don't copy ayFX values in to AYREGS)
; --- Copy ayFX values in to ARYREGS ---
[2]	RRCA				; Rotate a to the right (2 TIMES) (OR mask)
	LD	D, $DB			; d:=Mask for psg mixer (AND mask)
; --- Dump to correct channel ---
	LD	HL, ayFX_CHANNEL	; Next ayFX playing channel
	LD	B, [HL]			; Channel counter
; --- Check if playing channel was 1 ---
.CHK1:
	DJNZ	.CHK2			; Decrement and jump if channel was not 1
; --- Play ayFX stream on channel C ---
.PLAY_C:	
	CALL	.SETMIXER		; Set PSG mixer value (returning a=ayFX volume and hl=ayFX tone)
	LD	[PT3_REPLAYER.PT3_AYREGS+10], A	; Volume copied in to AYREGS (channel C volume)
	BIT	2, C			; If tone is off...
	RET	NZ			; ...return
	LD	[PT3_REPLAYER.PT3_AYREGS+4], HL	; copied in to AYREGS (channel C tone)
	RET				; Return
; --- Check if playing channel was 2 ---
.CHK2:
	RRC	D			; Rotate right AND mask
	RRCA				; Rotate right OR mask
	DJNZ	.CHK3			; Decrement and jump if channel was not 2
.PLAY_B:	; --- Play ayFX stream on channel B ---
	CALL	.SETMIXER		; Set PSG mixer value (returning a=ayFX volume and hl=ayFX tone)
	LD	[PT3_REPLAYER.PT3_AYREGS+9], A	; Volume copied in to AYREGS (channel B volume)
	BIT	1, C			; If tone is off...
	RET	NZ			; ...return
	LD	[PT3_REPLAYER.PT3_AYREGS+2], HL	; copied in to AYREGS (channel B tone)
	RET				; Return
; --- Check if playing channel was 3 ---
.CHK3:
	RRC	D			; Rotate right AND mask
	RRCA				; Rotate right OR mask
; --- Play ayFX stream on channel A ---
.PLAY_A:
	CALL	.SETMIXER		; Set PSG mixer value (returning a=ayFX volume and hl=ayFX tone)
	LD	[PT3_REPLAYER.PT3_AYREGS+8], A	; Volume copied in to AYREGS (channel A volume)
	BIT	0, C			; If tone is off...
	RET	NZ			; ...return
	LD	[PT3_REPLAYER.PT3_AYREGS+0], HL	; copied in to AYREGS (channel A tone)
	RET				; Return
; --- Set PSG mixer value ---
.SETMIXER:	
	LD	C, A			; c:=OR mask
	LD	A, [PT3_REPLAYER.PT3_AYREGS+7]	; a:=PSG mixer value
	AND	D			; AND mask
	OR	C			; OR mask
	LD	[PT3_REPLAYER.PT3_AYREGS+7], A	; PSG mixer value updated
	LD	A, [ayFX_VOLUME]	; a:=ayFX volume value
	LD	HL, [ayFX_TONE]		; ayFX tone value
	RET				; Return
	
IFDEF AYFXRELATIVE
; --- UNCOMMENT THIS IF YOU DON'T USE THIS REPLAYER WITH PT3 REPLAYER ---
; PT3_VT_:	.INCBIN	"VT.BIN"
; --- UNCOMMENT THIS IF YOU DON'T USE THIS REPLAYER WITH PT3 REPLAYER ---
ENDIF

	ENDMODULE AYFX_REPLAYER
;-----------------------------------------------------------
;| ------------------------------------------------------- |
;| |                      F I N                          | |
;| ------------------------------------------------------- |
;-----------------------------------------------------------
