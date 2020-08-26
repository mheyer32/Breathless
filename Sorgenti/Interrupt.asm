;****************************************************************************
;*
;*	Interrupt.asm
;*
;*		Routines di gestione interrupts
;*
;*
;*
;****************************************************************************


		include 'System'
		include 'TMap.i'

		include	"hardware/intbits.i"	;int bit definitions
		include	"exec/interrupts.i"	;server structure

;****************************************************************************

		xref	_custom
		xref	execbase,gfxbase
		xref	animcounter,VBTimer,VBTimer2
		xref	pause,ProgramState,MusicState
		xref	PlayerDeath
		xref	RedScreenCont
		xref	DoMovement,SprIRQPrint
		xref	AudioIRQ0,AudioIRQ1,AudioIRQ2,AudioIRQ3
		xref	SoundFXServer

;***********************************************************************
;*** Inizializza interrupt

		xdef	InitIRQ
InitIRQ
		EXECBASE
		lea	VBint(pc),a1
		move.l	#VBinterrupt,IS_CODE(a1)
		move.l	a5,IS_DATA(a1)
		clr.b	LN_PRI(a1)
		move.l	#INTB_VERTB,d0
		CALLSYS	AddIntServer

	;*** Interrupt canale audio 0

		lea	AUD0int(pc),a1
		move.l	#AudioIRQ0,IS_CODE(a1)
		move.l	a5,IS_DATA(a1)
		clr.b	LN_PRI(a1)
		move.l	#INTB_AUD0,d0
		CALLSYS	SetIntVector
		move.l	d0,oldaudioirq0(a5)

	;*** Interrupt canale audio 1

		lea	AUD1int(pc),a1
		move.l	#AudioIRQ1,IS_CODE(a1)
		move.l	a5,IS_DATA(a1)
		clr.b	LN_PRI(a1)
		move.l	#INTB_AUD1,d0
		CALLSYS	SetIntVector
		move.l	d0,oldaudioirq1(a5)

	;*** Interrupt canale audio 2

		lea	AUD2int(pc),a1
		move.l	#AudioIRQ2,IS_CODE(a1)
		move.l	a5,IS_DATA(a1)
		clr.b	LN_PRI(a1)
		move.l	#INTB_AUD2,d0
		CALLSYS	SetIntVector
		move.l	d0,oldaudioirq2(a5)

	;*** Interrupt canale audio 3

		lea	AUD3int(pc),a1
		move.l	#AudioIRQ3,IS_CODE(a1)
		move.l	a5,IS_DATA(a1)
		clr.b	LN_PRI(a1)
		move.l	#INTB_AUD3,d0
		CALLSYS	SetIntVector
		move.l	d0,oldaudioirq3(a5)

		rts

;***********************************************************************
;*** Ferma interrupt

		xdef	StopIRQ
StopIRQ
		EXECBASE
		lea	VBint(pc),a1
		move.l	#INTB_VERTB,d0
		CALLSYS	RemIntServer	;Rimuove l'irq server

	;*** Rimuove interrupt canale audio 0

		move.l	oldaudioirq0(a5),a1
		move.l	#INTB_AUD0,d0
		CALLSYS	SetIntVector

	;*** Rimuove interrupt canale audio 1

		move.l	oldaudioirq1(a5),a1
		move.l	#INTB_AUD1,d0
		CALLSYS	SetIntVector

	;*** Rimuove interrupt canale audio 2

		move.l	oldaudioirq2(a5),a1
		move.l	#INTB_AUD2,d0
		CALLSYS	SetIntVector

	;*** Rimuove interrupt canale audio 3

		move.l	oldaudioirq3(a5),a1
		move.l	#INTB_AUD3,d0
		CALLSYS	SetIntVector

		rts


;***********************************************************************
;*** Interrupt VBlank

VBinterrupt	movem.l	d2-d7/a2-a6,-(sp)

		move.l	a1,a5

		tst.b	ProgramState(a5)
		beq.s	VBpresentation

		jsr	SoundFXServer

		tst.b	MusicState(a5)		;Test se la musica è attiva
		beq.s	VBnomusic		; Se no, salta

		xref	P61_Music
		movem.l	d0-d7/a0-a6,-(sp)
		lea	$dff000,a6
		jsr	P61_Music
		movem.l	(sp)+,d0-d7/a0-a6
VBnomusic

		tst.w	pause(a5)		;Se il gioco è in pausa
		bne.s	VBnogame		; Salta

		addq.l	#1,animcounter(a5)
		addq.l	#1,VBTimer(a5)

;		tst.b	ProgramState(a5)	;Gioco congelato ?
;		bmi.s	VBnogame		; Se si, salta

		jsr	DoMovement

		tst.b	PlayerDeath(a5)		;Player morto ?
		bne	VBnorsc		; Se si, salta
		tst.w	RedScreenCont(a5)
		ble.s	VBnorsc
		subq.w	#1,RedScreenCont(a5)
VBnorsc

VBnogame
		jsr	SprIRQPrint
		jsr	SprIRQPrint

VBnogame2
		move.l	VBTimer2(a5),d0
		addq.l	#1,d0
		move.l	d0,VBTimer2(a5)

VBout
		movem.l	(sp)+,d2-d7/a2-a6
		moveq	#0,d0			;Permette il prossimo server
		rts


VBpresentation
		tst.b	MusicState(a5)		;Test se la musica è attiva
		beq.s	VBnomusicp		; Se no, salta

		xref	P61_Music
		movem.l	d0-d7/a0-a6,-(sp)
		lea	$dff000,a6
		jsr	P61_Music
		movem.l	(sp)+,d0-d7/a0-a6
VBnomusicp

		bra.s	VBnogame

;***********************************************************************

		cnop	0,4

VBint		ds.b	IS_SIZE	;VBlank interrupt server structure
AUD0int		ds.b	IS_SIZE	;Audio interrupt server structure
AUD1int		ds.b	IS_SIZE	;Audio interrupt server structure
AUD2int		ds.b	IS_SIZE	;Audio interrupt server structure
AUD3int		ds.b	IS_SIZE	;Audio interrupt server structure

		cnop	0,4

;***********************************************************************

	section	__MERGED,BSS

		cnop	0,4

oldaudioirq0	ds.l	1
oldaudioirq1	ds.l	1
oldaudioirq2	ds.l	1
oldaudioirq3	ds.l	1
