;****************************************************************************
;*
;*	FileAccess.asm
;*
;*	Routine per l'accesso ai file
;*	con supporto della compressione SLZ
;*
;*
;****************************************************************************
;*                         !!! ATTENZIONE !!!
;*
;* Le routine di questo sorgente danno per scontato che in a6 ci sia dosbase.
;*
;****************************************************************************

		opt	p=68020,ALINK,DEBUG,LINE

		include	'system'


ID		EQU	$5644434f	;'VDCO' = Virtual Dreams COmpression


		xdef	OpenCustom
		xdef	UnPack

;****************************************************************************

CALLSYS		MACRO
		jsr	_LVO\1(a6)
		ENDM

;****************************************************************************
;Apre un file testando se è compresso o meno
;
;Parametri passati nei registri:
;
;	d1 = filename
;	d2 = acces mode
;	a4 = pun. destination (nel caso di file compressi)
;	d4 = lun. destination (nel caso di file compressi)
;	d5 = flag unpack (1=scompatta; 0=non scompatta)

OpenCustom
		movem.l	d2-d7/a2-a4,-(sp)

;		lea	dati,a5

		CALLSYS	Open		;I parametri sono già nei registri
		tst.l	d0
		beq	OCerrorout
		move.l	d0,fp(a5)

		move.l	fp(a5),d1
		lea	inputId(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge Id

		tst.w	d5		;Test se deve scompattare
		beq	OpenCustom2

		cmp.l	#ID,inputId(a5)
		beq	OCcompress

		move.w	#0,flagcompress(a5)	;Se il file non è compresso
		move.l	fp(a5),d1
		moveq	#0,d2
		moveq	#-1,d3
		CALLSYS	Seek			; ritorna alla posizione 0

		move.l	fp(a5),d1
		move.l	a4,d2
		move.l	d4,d3
		CALLSYS	Read		;Legge intero file

		bra	OCout



OCcompress
		move.w	#1,flagcompress(a5)	;Se il file è compresso inizializza lettura compressa

		move.l	fp(a5),d1
		lea	outputsize(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge original size

		move.l	fp(a5),d1
		lea	buffersize(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge pack size

		moveq	#0,d0
		move.l	outputsize(a5),d1
		cmp.l	d4,d1		;Test se la destinazione e' sufficientemente grande
		bgt	OCerrorout

		move.l	fp(a5),d1
		move.l	d4,d2
		sub.l	buffersize(a5),d2
		add.l	a4,d2
		subq.l	#1,d2
		move.l	d2,bufferpun(a5)
		move.l	buffersize(a5),d3
		addq.l	#1,d3		;Legge anche byte tipo compressione
		CALLSYS	Read		;Legge packed data


		move.l	bufferpun(a5),a0	;a0=source
		move.l	a4,a1			;a1=dest.
		jsr	UnPack			;Decompressione

OCout		move.l	fp(a5),d0

OCerrorout	movem.l	(sp)+,d2-d7/a2-a4
		rts



;* Carica file compresso e non lo decomprime **************************

OpenCustom2
		cmp.l	#ID,inputId(a5)
		beq	OC2compress

		moveq	#0,d0
		bra	OCerrorout

OC2compress
		move.l	fp(a5),d1
		lea	outputsize(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge original size

		move.l	fp(a5),d1
		lea	buffersize(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge pack size

		moveq	#0,d0
		move.l	buffersize(a5),d1
		cmp.l	d4,d1		;Test se la destinazione e' sufficientemente grande
		bgt	OCerrorout

		move.l	fp(a5),d1
		move.l	a4,d2
		move.l	buffersize(a5),d3
		addq.l	#1,d3		;Legge anche byte tipo compressione
		CALLSYS	Read		;Legge packed data

		bra	OCout


;************************************************************************
;Routines di decompressione SLZ
;
; a0 = pun. to source (compressed data)
; a1 = pun. to destination

UnPack
		movem.l	d2-d3/a2-a3,-(sp)  ; Save Registers

		tst.b	(a0)+		;testa il tipo di compressione
		beq	UnPack0		;normale
		bra	UnPack1		;grafica

;**************************************************

UnPack0

;*****     CS_MASK=(2^(8-CS_LSL))-1
;*****     CS_LSL increases with history size (4->H=4096)

CS_MASK		EQU	15
CS_LSL		EQU	4


 
		move.l	a1,a3
		bra.s	slz_start       ; Skip to entry point
 
slz_literal	move.b	(a0)+,(a1)+     ; Copy 8 byte literal string FAST!
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+

slz_start	move.b	(a0)+,d0        ; Load compression TAG
		beq.s	slz_literal     ; 8-byte literal string?

		moveq	#7,d1           ; Loop thru 8 bits
slz_nxtloop	add.b	d0,d0           ; Set flags for this compression TAG
		bcs.s	slz_comp        ; If bit is set then compress
		move.b	(a0)+,(a1)+     ; Otherwise copy a literal byte
		dbf	d1,slz_nxtloop  ; Check and loop through 8 iterations
		bra.s	slz_start       ; Get next TAG

slz_comp	moveq	#0,d2           ; Clear offset register
		move.b	(a0)+,d2        ; Load compression specifier (cs) into d2
		beq.s	slz_exit        ; If cs is 0, exit (decompression finished)
		moveq	#CS_MASK,d3     ; Copy cs into number reg and mask off bits
		and.w	d2,d3           ;   num = ( cs & CS_MASK ) [+ 2] ; {at least 3}
		lsl.w	#CS_LSL,d2      ; Multiply cs_or by (2^CS_LSL)
		move.b	(a0)+,d2        ;   and replace lsb with rest of cs
		movea.l	a1,a2           ; Now compute the offset from the current
		suba.w	d2,a2           ;   output pointer (d2 auto-extends)

		add.w	d3,d3           ; Compute the unroll offset and begin
		neg.w	d3              ;   unrolled compressed data expansion
		jmp	slz_unroll(pc,d3.w)

slz_exit	sub.l	a3,a1
		move.l	a1,d0
		movem.l	(sp)+,d2-d3/a2-a3  ; Restore Registers
		rts                        ; EXIT routine

;**** For when H=4096 do not include the above (18-35)
		move.b	(a2)+,(a1)+     ; 17
		move.b	(a2)+,(a1)+     ; 16
		move.b	(a2)+,(a1)+     ; 15
		move.b	(a2)+,(a1)+     ; 14
		move.b	(a2)+,(a1)+     ; 13
		move.b	(a2)+,(a1)+     ; 12
		move.b	(a2)+,(a1)+     ; 11
		move.b	(a2)+,(a1)+     ; 10
		move.b	(a2)+,(a1)+     ;  9
		move.b	(a2)+,(a1)+     ;  8
		move.b	(a2)+,(a1)+     ;  7
		move.b	(a2)+,(a1)+     ;  6
		move.b	(a2)+,(a1)+     ;  5
		move.b	(a2)+,(a1)+     ;  4
		move.b	(a2)+,(a1)+     ;  3
slz_unroll	move.b	(a2)+,(a1)+     ;  2
		move.b	(a2)+,(a1)+     ;  1
 
		dbf	d1,slz_nxtloop  ; Check and loop through 8 iterations
		bra.s	slz_start       ; Process Next TAG



;************************************************************************

; a0 = pun. to source (compressed data)
; a1 = pun. to destination

UnPack1

;*****     CS1_MASK=(2^(8-CS_LSL))-1
;*****     CS1_LSL increases with history size (4->H=4096)

CS1_MASK	EQU	31
CS1_LSL		EQU	3


		move.l	a1,a3
		bra.s	slz1_start      ; Skip to entry point
 
slz1_literal	move.b	(a0)+,(a1)+     ; Copy 8 byte literal string FAST!
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
		move.b	(a0)+,(a1)+

slz1_start	move.b	(a0)+,d0        ; Load compression TAG
		beq.s	slz1_literal    ; 8-byte literal string?

		moveq	#7,d1           ; Loop thru 8 bits
slz1_nxtloop	add.b	d0,d0           ; Set flags for this compression TAG
		bcs.s	slz1_comp       ; If bit is set then compress
		move.b	(a0)+,(a1)+     ; Otherwise copy a literal byte
		dbf	d1,slz1_nxtloop ; Check and loop through 8 iterations
		bra.s	slz1_start      ; Get next TAG

slz1_comp	moveq	#0,d2           ; Clear offset register
		move.b	(a0)+,d2        ; Load compression specifier (cs) into d2
		beq.s	slz1_exit       ; If cs is 0, exit (decompression finished)
		moveq	#CS1_MASK,d3    ; Copy cs into number reg and mask off bits
		and.w	d2,d3           ;   num = ( cs & CS_MASK ) [+ 2] ; {at least 3}
		lsl.w	#CS1_LSL,d2     ; Multiply cs_or by (2^CS_LSL)
		move.b	(a0)+,d2        ;   and replace lsb with rest of cs
		movea.l	a1,a2           ; Now compute the offset from the current
		suba.w	d2,a2           ;   output pointer (d2 auto-extends)

		add.w	d3,d3           ; Compute the unroll offset and begin
		neg.w	d3              ;   unrolled compressed data expansion
		jmp	slz1_unroll(pc,d3.w)

slz1_exit	sub.l	a3,a1
		move.l	a1,d0
		movem.l	(sp)+,d2-d3/a2-a3  ; Restore Registers
		rts                        ; EXIT routine

**** For when H=2048
		move.b	(a2)+,(a1)+     ; 33
		move.b	(a2)+,(a1)+     ; 32
		move.b	(a2)+,(a1)+     ; 31
		move.b	(a2)+,(a1)+     ; 30
		move.b	(a2)+,(a1)+     ; 29
		move.b	(a2)+,(a1)+     ; 28
		move.b	(a2)+,(a1)+     ; 27
		move.b	(a2)+,(a1)+     ; 26
		move.b	(a2)+,(a1)+     ; 25
		move.b	(a2)+,(a1)+     ; 24
		move.b	(a2)+,(a1)+     ; 23
		move.b	(a2)+,(a1)+     ; 22
		move.b	(a2)+,(a1)+     ; 21
		move.b	(a2)+,(a1)+     ; 20
		move.b	(a2)+,(a1)+     ; 19
		move.b	(a2)+,(a1)+     ; 18

;**** For when H=4096 do not include the above (18-35)
		move.b	(a2)+,(a1)+     ; 17
		move.b	(a2)+,(a1)+     ; 16
		move.b	(a2)+,(a1)+     ; 15
		move.b	(a2)+,(a1)+     ; 14
		move.b	(a2)+,(a1)+     ; 13
		move.b	(a2)+,(a1)+     ; 12
		move.b	(a2)+,(a1)+     ; 11
		move.b	(a2)+,(a1)+     ; 10
		move.b	(a2)+,(a1)+     ;  9
		move.b	(a2)+,(a1)+     ;  8
		move.b	(a2)+,(a1)+     ;  7
		move.b	(a2)+,(a1)+     ;  6
		move.b	(a2)+,(a1)+     ;  5
		move.b	(a2)+,(a1)+     ;  4
		move.b	(a2)+,(a1)+     ;  3
slz1_unroll	move.b	(a2)+,(a1)+     ;  2
		move.b	(a2)+,(a1)+     ;  1
 
		dbf	d1,slz1_nxtloop ; Check and loop through 8 iterations
		bra.s	slz1_start      ; Process Next TAG

;************************************************************************

	section	__MERGED,BSS

		cnop	0,4
;dati:
outputsize	ds.l	1	;Lun. del file originale
buffersize	ds.l	1	;Lun. dei dati compressi
bufferpun	ds.l	1	;Pun. buffer dati compressi
inputId		ds.l	1	;Per testare l'Id del file
fp		ds.l	1	;Pun. alla struct FileHandle
flagcompress	ds.w	1	;Flag: Se=1 il file è compresso
compressiontype	ds.w	1	;Tipo compressione

		cnop	0,4
