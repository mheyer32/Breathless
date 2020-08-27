;****************************************************************************
;*
;*	Text.asm
;*
;*		Routines per la stampa di numeri e stringhe
;*		a video o sullo sprite-monitor
;*		Stampa su sprite con effetto 3d
;*
;****************************************************************************

		include 'TMap.i'


;**********************************************************************

		xref	Sprites,PanelBitplanes

;**********************************************************************
;* Stampa punteggi
;* Richiede :
;*	d0 = x
;*	d1 = y
;*	d2 = Numero da stampare
;*	d3 = Numero cifre da stampare
;*	d4 = Tipo carattere (0:Digital; 1:Mini)
;*	a0 = Pun. a lista di pun. a bitplane

		xdef	ScorePrint

ScorePrint	movem.l	d0-d7/a0-a6,-(sp)


	;*** Converte il numero

		lea	NumberStr(pc),a1
		lea	(a1,d3.w),a2
		moveq	#10,d5
ScPloopcon	divul.l	d5,d6:d2
		beq.s	ScPconend
		cmp.l	a1,a2		;Se il numero non entra nella stringa
		beq.s	ScPconexit	; esce
		move.b	d6,-(a2)	;Inserisce nella stringa
		bra.s	ScPloopcon
ScPconend	cmp.l	a1,a2		;Se il numero non entra nella stringa
		beq.s	ScPconexit	; esce
		move.b	d6,-(a2)	;Inserisce nella stringa
ScPfill		cmp.l	a1,a2		;Se la stringa non  piena
		beq.s	ScPconexit
		move.b	#0,-(a2)	;Finisce di riempirla
		bra.s	ScPfill
ScPconexit

		tst.w	d4
		beq.s	ScPj1
		lea	CaratteriMini(pc),a6
		bra.s	ScPj2
ScPj1		lea	CaratteriDigital(pc),a6
ScPj2

		mulu.w	#40,d1		;d1=y*40   !!! OTTIMIZZARE
		move.w	d0,d7
		lsr.w	#3,d7		;d7=x>>3
		add.w	d7,d1		;d1=(x>>3) + (y*40)
		not.w	d0
		and.w	#7,d0		;d0=x & 7

		lea	NumberStr(pc),a2
		subq.w	#1,d3
ScPmainloop	addq.w	#1,d0
		clr.w	d2
		move.b	(a2)+,d2
		move.l	8(a6,d2.w*4),a1	;a1=pun.ai dati grafici del carattere
		move.w	4(a6),d4	;d4=mask
		rol.w	d0,d4
		move.l	a0,a4
		move.w	6(a6),d6	;d6=Bitplane usati
		moveq	#7,d7		;d7=num.bitplane
ScPcharloop	lsr.b	#1,d6		;Bitplane usato ?
		bcc.s	ScPnextbitpl	; Se no, salta
		move.l	(a4),a3
		add.w	d1,a3		;a3=pun.al bitplane dello schermo
		swap	d7
		move.w	2(a6),d7	;d7=Num. righe
		subq.w	#1,d7
ScPbitplloop	clr.w	d5
		move.b	(a1)+,d5
		move.w	(a3),d2
		and.w	d4,d2
		lsl.w	d0,d5
		or.w	d5,d2
		move.w	d2,(a3)
		lea	40(a3),a3
		dbra	d7,ScPbitplloop
		swap	d7
ScPnextbitpl	addq.l	#4,a4
		dbra	d7,ScPcharloop

		subq.w	#1,d0
		sub.w	(a6),d0
		bge.s	ScPnom
		and.w	#7,d0
		addq.w	#1,d1
ScPnom
		dbra	d3,ScPmainloop

		movem.l	(sp)+,d0-d7/a0-a6
		rts

;**********************************************************************
;* Stampa una stringa nello sprite screen
;* Richiede :
;*	d0 = x
;*	d1 = y
;*	d3 = color
;*	a0 = pun. alla null-terminated string

		xdef	SprPrint

SprPrint	movem.l	d0-d7/a0-a6,-(sp)

		moveq	#2,d6
		move.w	d3,d5
		bpl.s	SPnomico
		moveq	#-1,d6
SPnomico
SPloop		moveq	#0,d2
		move.b	(a0)+,d2	;Legge prossimo char dalla stringa
		beq.s	SPend		;Esce, se finita stringa
		addq.w	#1,d0
		addq.w	#1,d1
		move.w	d6,d3
		bsr	SprCharPrint		;Stampa char
		subq.w	#1,d0
		subq.w	#1,d1
		move.w	d5,d3
		bsr	SprCharPrint		;Stampa char
		add.w	#SPRMON_CHARWIDTH,d0	;Sposta "cursore"
		cmp.w	#SPRMON_NSPRITE*64,d0	;Test se arrivato a fine screen
		blt.s	SPloop
SPend
		movem.l	(sp)+,d0-d7/a0-a6
		rts

;**********************************************************************
;* Inizializza stampa su sprite-monitor

		xdef	InitSprPrint

InitSprPrint	lea	SprBuffer(a5),a0
		move.l	a0,SprBufPunIn(a5)
		move.l	a0,SprBufPunOut(a5)

		clr.w	Command(a5)

		;***** Calcola pun. ai dati grafici degli sprite usati
		;***** per lo sprite monitor

		lea	Sprites(a5),a1

		move.l	24(a1),a0
		move.l	(a0),a0
		lea	16(a0),a0
		move.l	a0,ScrSprites(a5)	;Pun. sprite 6

		move.l	28(a1),a0
		move.l	(a0),a0
		lea	16(a0),a0
		move.l	a0,ScrSprites+4(a5)	;Pun. sprite 7

		rts

;**********************************************************************
;* Inserisce un messaggio nel buffer per essere stampato,
;* un carattere al 25esimo, sullo sprite screen.
;* Richiede :
;*	d0 = Codice messaggio (vedi lista in fondo al file)

		xdef	SprDelayPrintMessage

SprDelayPrintMessage
		movem.l	a0-a1,-(sp)

		lea	Messages(pc),a0
		move.l	(a0,d0.w*4),a0		;a0=Pun. al messaggio

		move.l	SprBufPunIn(a5),a1
		move.w	#0,(a1)+
		move.w	#8,(a1)+
		move.l	a0,(a1)+
		move.w	#0,(a1)+
		lea	EndSprBuffer(a5),a0
		cmp.l	a0,a1
		blt.s	SDPMj1
		lea	SprBuffer(a5),a1
SDPMj1
		clr.l	(a1)+
;		lea	MessWait(pc),a0		;Comandi Wait e Clear row
;		move.l	a0,(a1)+
		move.l	#MessWait,(a1)+		;Comandi Wait e Clear row
		move.w	#0,(a1)+
		cmp.l	a0,a1
		blt.s	SDPMj2
		lea	SprBuffer(a5),a1
SDPMj2
		move.l	a1,SprBufPunIn(a5)

		movem.l	(sp)+,a0-a1
		rts


;**********************************************************************
;* Inserisce una stringa nel buffer per essere stampata,
;* un carattere al 25esimo, sullo sprite screen.
;* Esegue anche comandi (vedere SprIRQPrint)
;* Richiede :
;*	d0 = x
;*	d1 = y
;*	d2 = color
;*	a0 = pun. alla null-terminated string

		xdef	SprDelayPrint

SprDelayPrint	movem.l	a0-a1,-(sp)

		move.l	SprBufPunIn(a5),a1
		move.w	d0,(a1)+
		move.w	d1,(a1)+
		move.l	a0,(a1)+
		move.w	d2,(a1)+
		lea	EndSprBuffer(a5),a0
		cmp.l	a0,a1
		blt.s	SDPj1
		lea	SprBuffer(a5),a1
SDPj1		move.l	a1,SprBufPunIn(a5)

		movem.l	(sp)+,a0-a1
		rts

;**********************************************************************
;* Stampa nello sprite screen, un carattere al 25esimo.
;* Viene richiamata da IRQ e legge i dati relativi alle stringhe
;* da stampare in un buffer.
;* Per inserire le stringhe nel buffer usare SprDelayPrint
;* Esegue anche comandi.
;* Un comando e' rappresentato da un codice minore di 0.
;* I comandi disponibili sono:
;*	-1 : Clear Screen (parametro=prima riga da cancellare)
;*	-2 : Wait (param.=Numero di 25esimi (o 50esimi?) da attendere)
;*	-3 : Clear Row (param.=riga da cancellare)
;*	-4 : Cambia colore (param.=codice colore (0,1,2))

		xdef	SprIRQPrint

SprIRQPrint
		move.l	SprBufPunOut(a5),a1	;a1=Pun. stringa da stampare
		cmp.l	SprBufPunIn(a5),a1
		beq	SIPout

		move.b	Command(a5),d2	;C'e' un comando in esecuzione ?
		beq.s	SIPnocomm	;Se no, salta
		addq.b	#1,d2		;-1 : Clear screen ?
		beq.s	SIPcls
		addq.b	#1,d2		;-2 : Wait ?
		beq.s	SIPwait
		bra	SIPendcommand	;Nessun comando

SIPwait		subq.b	#1,CommandParam(a5)	;Decrementa contatore
		bne	SIPout
		bra	SIPendcommand		;Se arrivato a zero, termina

SIPcls		moveq	#0,d1
		move.b	CommandParam(a5),d1
		bsr	SprClearRow		;Pulisce riga
		add.w	#SPRMON_CHARHEIGHT,d1
		move.b	d1,CommandParam(a5)
		cmp.w	#SPRMON_HEIGHT,d1
		blt	SIPout
		bra	SIPendcommand		;Se finito, disabilita comando


SIPnocomm
		move.w	(a1)+,d0	;d0=x
		move.w	(a1)+,d1	;d1=y
		move.l	(a1)+,a0	;a0=pun. stringa
		move.w	(a1)+,d5	;d5=color
SIPnextchar
		moveq	#0,d2
		move.b	(a0)+,d2		;Legge prossimo char dalla stringa
		beq.s	SIPend			;Salta, se finita stringa
		bmi.s	SIPcomm			;Salta, se e' un comando
		cmp.b	#32,d2			;E' uno spazio ?
		beq.s	SIPspace		; se si, salta
		cmp.b	#95,d2			;E' un'underscore ?
		beq.s	SIPspace2		; se si, salta
		addq.w	#1,d0
		addq.w	#1,d1
		moveq	#2,d3
		bsr	SprCharPrint		;Stampa char
		subq.w	#1,d0
		subq.w	#1,d1
		move.w	d5,d3
		bsr	SprCharPrint		;Stampa char

		add.w	#SPRMON_CHARWIDTH,d0	;Sposta "cursore"
		cmp.w	#SPRMON_NSPRITE*64,d0	;Test se arrivato a fine screen
		blt.s	SIPcont
		bra.s	SIPend

SIPcomm
		move.b	d2,d3
		addq.b	#1,d3		;-1 : Clear screen ?
		beq.s	SIPinitcls
		addq.b	#1,d3		;-2 : Wait ?
		beq.s	SIPinitwait
		addq.b	#1,d3		;-3 : Clear row ?
		beq.s	SIPclr
		addq.b	#1,d3		;-4 : Change color ?
		beq.s	SIPcolor
		bra.s	SIPcont		;Nessun comando

SIPinitwait	move.b	d2,Command(a5)		;Memorizza il codice del comando
		move.b	(a0)+,CommandParam(a5)
		bra.s	SIPcont

SIPinitcls	move.b	d2,Command(a5)		;Memorizza il codice del comando
		move.b	(a0)+,CommandParam(a5)
		bra.s	SIPcont

SIPclr		move.b	(a0)+,d1
		bsr	SprClearRow		;Pulisce riga
		bra.s	SIPcont

SIPcolor	clr.w	d5
		move.b	(a0)+,d5
		move.w	d5,-2(a1)
		bra.s	SIPnextchar

SIPspace2	add.w	#SPRMON_CHARWIDTH-4,d0
SIPspace
		add.w	#4,d0			;Sposta "cursore" per lo spazio
		cmp.w	#SPRMON_NSPRITE*64,d0	;Test se arrivato a fine screen
		bge.s	SIPend
SIPcont
		move.l	SprBufPunOut(a5),a1
		move.w	d0,(a1)+
		move.w	d1,(a1)+
		move.l	a0,(a1)+
		bra.s	SIPout
SIPend
		lea	EndSprBuffer(a5),a0
		cmp.l	a0,a1
		blt.s	SIPj1
		lea	SprBuffer(a5),a1
SIPj1		move.l	a1,SprBufPunOut(a5)
SIPout
		rts


SIPendcommand
		clr.w	Command(a5)	;Azzera comando e parametro
		rts

;**********************************************************************
;* Restituisce il flag Z=1 se il buffer di stampa e' vuoto

		xdef	CheckEmptySprBuffer

CheckEmptySprBuffer

		move.l	SprBufPunOut(a5),d0	;a1=Pun. stringa da stampare
		sub.l	SprBufPunIn(a5),d0
		rts

;**********************************************************************
;* Pulisce la riga dello sprite screen indicata da d1

SprClearRow	movem.l	d0-d2/a0-a1,-(sp)

		cmp.w	#SPRMON_HEIGHT-SPRMON_CHARHEIGHT,d1
		bgt.s	SCRout

		lea	ScrSprites(a5),a1
		lsl.w	#4,d1		;d1=y*16

		moveq	#0,d0

		moveq	#SPRMON_NSPRITE-1,d3
SCRloop0	move.l	(a1)+,a0
		add.w	d1,a0		;a0=Pun. allo sprite

		move.w	#SPRMON_CHARHEIGHT-1,d2
SCRloop1	move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d2,SCRloop1
		dbra	d3,SCRloop0
SCRout
		movem.l	(sp)+,d0-d2/a0-a1
		rts

;**********************************************************************

SCPBYTED	MACRO
		clr.w	d5
		move.b	(a2)+,d5
		ror.w	d0,d5
		not.w	d5
		and.b	d5,\1(a3)
		and.b	d5,\1+8(a3)
		move.w	d5,(a1)+
		ENDM

SCPBYTE0	MACRO
		clr.w	d5
		move.b	(a2)+,d5
		ror.w	d0,d5
		or.b	d5,\1(a3)
		move.w	d5,(a1)+
		not.b	d5
		and.b	d5,\1+8(a3)
		ENDM

SCPBYTE1	MACRO
		clr.w	d5
		move.b	(a2)+,d5
		ror.w	d0,d5
		or.b	d5,\1+8(a3)
		move.w	d5,(a1)+
		not.b	d5
		and.b	d5,\1(a3)
		ENDM

SCPBYTE2	MACRO
		clr.w	d5
		move.b	(a2)+,d5
		ror.w	d0,d5
		or.b	d5,\1(a3)
		or.b	d5,\1+8(a3)
		move.w	d5,(a1)+
		ENDM


SCPBYTEVD	MACRO
		move.b	\2(a1),d5
		and.b	d5,\1(a3)
		and.b	d5,\1+8(a3)
		ENDM

SCPBYTEV0	MACRO
		move.b	\2(a1),d5
		or.b	d5,\1(a3)
		not.b	d5
		and.b	d5,\1+8(a3)
		ENDM

SCPBYTEV1	MACRO
		move.b	\2(a1),d5
		or.b	d5,\1+8(a3)
		not.b	d5
		and.b	d5,\1(a3)
		ENDM

SCPBYTEV2	MACRO
		move.b	\2(a1),d5
		or.b	d5,\1(a3)
		or.b	d5,\1+8(a3)
		ENDM

;**********************************************************************
;* Stampa un carattere nello sprite screen
;* Richiede :
;*	d0 = x
;*	d1 = y
;*	d2 = codice ASCII del carattere da stampare
;*	d3 = colore (-1=delete/0/1/2)


		xdef	SprCharPrint

SprCharPrint	movem.l	d0-d7/a0-a6,-(sp)

		lea	ScrSprites(a5),a4
		lea	CaratteriSprMon(pc),a6

		lsl.w	#4,d1		;d1=y*16
		move.w	d0,d7
		lsr.w	#3,d7
		move.w	d7,d6
		lsr.w	#3,d7		;d7=Num. dello sprite di partenza
		and.w	#7,d6		;d6=Colonna(byte) iniziale nello sprite di partenza
		and.w	#7,d0		;d0=Colonna(pixel) iniziale nello sprite di partenza

		cmp.w	#SPRMON_NSPRITE,d7
		bge	SCPend
		move.l	(a4,d7.w*4),a3
		add.w	d6,a3
		add.w	d1,a3		;a3=Pun. allo sprite

		cmp.b	#32,d2
		blt	SCPend		;Se<32, esce
		cmp.b	#106,d2
		bgt	SCPend		;Se>96, esce
		sub.b	#32,d2
		mulu.w	#5,d2		
		lea	(a6,d2.w),a2	;a2=Pun. dati grafici carattere

		lea	charbuffer(pc),a1

		tst.w	d3
		bmi.s	SCPdelete
		bne	SCPcolor1
		SCPBYTE0 0
		SCPBYTE0 16
		SCPBYTE0 32
		SCPBYTE0 48
		SCPBYTE0 64
		bra	SCPj1
SCPdelete
		SCPBYTED 0
		SCPBYTED 16
		SCPBYTED 32
		SCPBYTED 48
		SCPBYTED 64
		bra	SCPj1
SCPcolor1
		cmp.w	#1,d3
		bne.s	SCPcolor2
		SCPBYTE1 0
		SCPBYTE1 16
		SCPBYTE1 32
		SCPBYTE1 48
		SCPBYTE1 64
		bra.s	SCPj1
SCPcolor2
		SCPBYTE2 0
		SCPBYTE2 16
		SCPBYTE2 32
		SCPBYTE2 48
		SCPBYTE2 64
SCPj1
		cmp.w	#8-SPRMON_CHARWIDTH,d0	;Test se c'e' overflow nel prossimo byte
		ble	SCPend

		addq.w	#1,a3
		addq.w	#1,d6
		cmp.w	#8,d6
		blt.s	SCPcont
		addq.w	#1,d7		;Passa al prossimo sprite
		cmp.w	#SPRMON_NSPRITE,d7	;Se finiti sprite, esce
		bge	SCPend

		move.l	(a4,d7.w*4),a3
		add.w	d1,a3		;a3=Pun. allo sprite
SCPcont
		lea	charbuffer(pc),a1

		tst.w	d3
		bmi.s	SCPdeleteb
		bne	SCPcolor1b
		SCPBYTEV0  0,0
		SCPBYTEV0 16,2
		SCPBYTEV0 32,4
		SCPBYTEV0 48,6
		SCPBYTEV0 64,8
		bra	SCPj1b
SCPdeleteb
		SCPBYTEVD  0,0
		SCPBYTEVD 16,2
		SCPBYTEVD 32,4
		SCPBYTEVD 48,6
		SCPBYTEVD 64,8
		bra	SCPj1b
SCPcolor1b
		cmp.w	#1,d3
		bne.s	SCPcolor2b
		SCPBYTEV1  0,0
		SCPBYTEV1 16,2
		SCPBYTEV1 32,4
		SCPBYTEV1 48,6
		SCPBYTEV1 64,8
		bra.s	SCPj1b
SCPcolor2b
		SCPBYTEV2  0,0
		SCPBYTEV2 16,2
		SCPBYTEV2 32,4
		SCPBYTEV2 48,6
		SCPBYTEV2 64,8
SCPj1b

SCPend
		movem.l	(sp)+,d0-d7/a0-a6
		rts

charbuffer	ds.w	12

;* Stampa numeri a video in esadecimale ******************************
;* Richiede :
;*	d0 = x (in byte)
;*	d1 = y (in pixel)
;*	d2 = numero da stampare
;*	a0 = Pun. bitplane
;*

		xdef	PrintHex

PrintHex	movem.l	d0-d7/a0-a6,-(sp)

		mulu	#40,d1
		adda.l	d1,a0
		ext.l	d0
		adda.l	d0,a0		;a0=puntatore a video

		lea	caratteri,a1
		move.w	d2,d1
		lsr.w	#8,d1
		lsr.w	#4,d1
		lsl.w	#3,d1
		move.b	(a1,d1.w),(a0)
		move.b	1(a1,d1.w),40(a0)
		move.b	2(a1,d1.w),80(a0)
		move.b	3(a1,d1.w),120(a0)
		move.b	4(a1,d1.w),160(a0)
		move.b	5(a1,d1.w),200(a0)
		move.b	6(a1,d1.w),240(a0)

		move.w	d2,d1
		lsr.w	#8,d1
		andi.w	#15,d1
		lsl.w	#3,d1
		move.b	(a1,d1.w),1(a0)
		move.b	1(a1,d1.w),41(a0)
		move.b	2(a1,d1.w),81(a0)
		move.b	3(a1,d1.w),121(a0)
		move.b	4(a1,d1.w),161(a0)
		move.b	5(a1,d1.w),201(a0)
		move.b	6(a1,d1.w),241(a0)

		move.w	d2,d1
		lsr.w	#4,d1
		andi.w	#15,d1
		lsl.w	#3,d1
		move.b	(a1,d1.w),2(a0)
		move.b	1(a1,d1.w),42(a0)
		move.b	2(a1,d1.w),82(a0)
		move.b	3(a1,d1.w),122(a0)
		move.b	4(a1,d1.w),162(a0)
		move.b	5(a1,d1.w),202(a0)
		move.b	6(a1,d1.w),242(a0)

		move.w	d2,d1
		andi.w	#15,d1
		lsl.w	#3,d1
		move.b	(a1,d1.w),3(a0)
		move.b	1(a1,d1.w),43(a0)
		move.b	2(a1,d1.w),83(a0)
		move.b	3(a1,d1.w),123(a0)
		move.b	4(a1,d1.w),163(a0)
		move.b	5(a1,d1.w),203(a0)
		move.b	6(a1,d1.w),243(a0)

		movem.l	(sp)+,d0-d7/a0-a6
		rts

;******************************************************************

caratteri	dc.b	254,130,130,130,130,130,254,0	;0
		dc.b	 16, 16, 16, 16, 16, 16, 16,0	;1
		dc.b	254,  2,  2,254,128,128,254,0	;2
		dc.b	254,  2,  2, 62,  2,  2,254,0	;3
		dc.b	128,128,128,128,136,254,  8,0	;4
		dc.b	254,128,128,254,  2,  2,254,0	;5
		dc.b	254,128,128,254,130,130,254,0	;6
		dc.b	254,  2,  2,  2,  2,  2,  2,0	;7
		dc.b	254,130,130,254,130,130,254,0	;8
		dc.b	254,130,130,254,  2,  2,254,0	;9
		dc.b	254,130,130,254,130,130,130,0	;a
		dc.b	254,130,130,252,130,130,254,0	;b
		dc.b	254,128,128,128,128,128,254,0	;c
		dc.b	248,132,130,130,130,132,248,0	;d
		dc.b	254,128,128,248,128,128,254,0	;e
		dc.b	254,128,128,248,128,128,128,0	;f



;*********************************************************************
;* Stampa numeri in esadecimale in uno schermo chunky pixel **********
;* Richiede :
;*	d0 = x (in pixel)
;*	d1 = y (in pixel)
;*	d2 = numero da stampare
;*	a0 = Pun. schermo chunky pixel
;*

;		xdef	PrintHexChunky
;
;PrintHexChunky	movem.l	d0-d7/a0-a6,-(sp)
;
;		mulu	#320,d1
;		adda.l	d1,a0
;		ext.l	d0
;		adda.l	d0,a0		;a0=puntatore a video
;
;		lea	caratteri2,a1
;		move.w	d2,d1
;		lsr.w	#8,d1
;		lsr.w	#4,d1
;		lsl.w	#6,d1
;		lea	(a1,d1.w),a2
;		move.l	(a2)+,(a0)
;		move.l	(a2)+,4(a0)
;		move.l	(a2)+,320(a0)
;		move.l	(a2)+,324(a0)
;		move.l	(a2)+,640(a0)
;		move.l	(a2)+,644(a0)
;		move.l	(a2)+,960(a0)
;		move.l	(a2)+,964(a0)
;		move.l	(a2)+,1280(a0)
;		move.l	(a2)+,1284(a0)
;		move.l	(a2)+,1600(a0)
;		move.l	(a2)+,1604(a0)
;		move.l	(a2)+,1920(a0)
;		move.l	(a2)+,1924(a0)
;		move.l	(a2)+,2240(a0)
;		move.l	(a2)+,2244(a0)
;		addq.l	#8,a0
;
;		move.w	d2,d1
;		lsr.w	#8,d1
;		andi.w	#15,d1
;		lsl.w	#6,d1
;		lea	(a1,d1.w),a2
;		move.l	(a2)+,(a0)
;		move.l	(a2)+,4(a0)
;		move.l	(a2)+,320(a0)
;		move.l	(a2)+,324(a0)
;		move.l	(a2)+,640(a0)
;		move.l	(a2)+,644(a0)
;		move.l	(a2)+,960(a0)
;		move.l	(a2)+,964(a0)
;		move.l	(a2)+,1280(a0)
;		move.l	(a2)+,1284(a0)
;		move.l	(a2)+,1600(a0)
;		move.l	(a2)+,1604(a0)
;		move.l	(a2)+,1920(a0)
;		move.l	(a2)+,1924(a0)
;		move.l	(a2)+,2240(a0)
;		move.l	(a2)+,2244(a0)
;		addq.l	#8,a0
;
;		move.w	d2,d1
;		lsr.w	#4,d1
;		andi.w	#15,d1
;		lsl.w	#6,d1
;		lea	(a1,d1.w),a2
;		move.l	(a2)+,(a0)
;		move.l	(a2)+,4(a0)
;		move.l	(a2)+,320(a0)
;		move.l	(a2)+,324(a0)
;		move.l	(a2)+,640(a0)
;		move.l	(a2)+,644(a0)
;		move.l	(a2)+,960(a0)
;		move.l	(a2)+,964(a0)
;		move.l	(a2)+,1280(a0)
;		move.l	(a2)+,1284(a0)
;		move.l	(a2)+,1600(a0)
;		move.l	(a2)+,1604(a0)
;		move.l	(a2)+,1920(a0)
;		move.l	(a2)+,1924(a0)
;		move.l	(a2)+,2240(a0)
;		move.l	(a2)+,2244(a0)
;		addq.l	#8,a0
;
;		move.w	d2,d1
;		andi.w	#15,d1
;		lsl.w	#6,d1
;		lea	(a1,d1.w),a2
;		move.l	(a2)+,(a0)
;		move.l	(a2)+,4(a0)
;		move.l	(a2)+,320(a0)
;		move.l	(a2)+,324(a0)
;		move.l	(a2)+,640(a0)
;		move.l	(a2)+,644(a0)
;		move.l	(a2)+,960(a0)
;		move.l	(a2)+,964(a0)
;		move.l	(a2)+,1280(a0)
;		move.l	(a2)+,1284(a0)
;		move.l	(a2)+,1600(a0)
;		move.l	(a2)+,1604(a0)
;		move.l	(a2)+,1920(a0)
;		move.l	(a2)+,1924(a0)
;		move.l	(a2)+,2240(a0)
;		move.l	(a2)+,2244(a0)
;
;		movem.l	(sp)+,d0-d7/a0-a6
;		rts
;
;;******************************************************************
;
;caratteri2	dc.b	4,4,4,4,4,4,4,0		;0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	0,0,0,4,0,0,0,0		;1
;		dc.b	0,0,0,4,0,0,0,0
;		dc.b	0,0,0,4,0,0,0,0
;		dc.b	0,0,0,4,0,0,0,0
;		dc.b	0,0,0,4,0,0,0,0
;		dc.b	0,0,0,4,0,0,0,0
;		dc.b	0,0,0,4,0,0,0,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;2
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;3
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,0,0,0,0,0,0,0		;4
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,4,0,0,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,4,0,0,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;5
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;6
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;7
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;8
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;9
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;A
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,0,0		;B
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,0,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,4,4,4,4,4,0,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;C
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,0,0,0		;D
;		dc.b	4,0,0,0,0,4,0,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,0,4,0
;		dc.b	4,0,0,0,0,4,0,0
;		dc.b	4,4,4,4,4,0,0,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;E
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,4,4,4,4,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,4,4,4,4,4,4,0
;		dc.b	0,0,0,0,0,0,0,0
;
;		dc.b	4,4,4,4,4,4,4,0		;F
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,4,4,4,4,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	4,0,0,0,0,0,0,0
;		dc.b	0,0,0,0,0,0,0,0

;**********************************************************************
;* N.B.:
;*	Il carattere ' ' (32) da una spaziatura di 4 pixel
;*	Il carattere '_' (95) da una spaziatura di 6 pixel

CaratteriSprMon

	dc.b	$00,$00,$00,$00,$00		;(32)
	dc.b	$40,$40,$40,$00,$40		;!
	dc.b	$A0,$A0,$00,$00,$00		;"
	ds.b	5				;(35)
	ds.b	5				;(36)
	ds.b	5				;(37)
	ds.b	5				;(38)
	dc.b	$20,$20,$00,$00,$00		;' (39)
	ds.b	5				;(40)
	ds.b	5				;(41)
	dc.b	$00,$50,$20,$50,$00		;*
	dc.b	$00,$40,$E0,$40,$00		;+
	dc.b	$00,$00,$00,$20,$40		;, (44)
	dc.b	$00,$00,$E0,$00,$00		;-
	dc.b	$00,$00,$00,$00,$20		;.
	dc.b	$08,$10,$20,$40,$80		;/
	dc.b	$70,$C8,$A8,$98,$70		;0
	dc.b	$20,$60,$20,$20,$70		;1
	dc.b	$F0,$08,$70,$80,$F8		;2
	dc.b	$F0,$08,$78,$08,$F0		;3
	dc.b	$90,$90,$F8,$10,$10		;4
	dc.b	$F8,$80,$78,$08,$F0		;5
	dc.b	$70,$80,$F8,$88,$70		;6
	dc.b	$F8,$08,$10,$20,$20		;7
	dc.b	$70,$88,$70,$88,$70		;8
	dc.b	$70,$88,$F8,$08,$70		;9
	dc.b	$00,$20,$00,$20,$00		;: (58)
	dc.b	$00,$20,$00,$20,$40		;; (59)
	dc.b	$10,$20,$40,$20,$10		;<
	dc.b	$00,$E0,$00,$E0,$00		;=
	ds.b	5				;(62)
	dc.b	$30,$48,$10,$00,$10		;?
	ds.b	5				;(64)
	dc.b	$70,$88,$F8,$88,$88		;A
	dc.b	$F0,$88,$F0,$88,$F0		;B
	dc.b	$78,$80,$80,$80,$78		;C
	dc.b	$F0,$88,$88,$88,$F0		;D
	dc.b	$F8,$80,$F0,$80,$F8		;E
	dc.b	$F8,$80,$F0,$80,$80		;F
	dc.b	$70,$80,$B8,$88,$70		;G
	dc.b	$88,$88,$F8,$88,$88		;H
	dc.b	$70,$20,$20,$20,$70		;I
	dc.b	$08,$08,$08,$88,$70		;J
	dc.b	$88,$90,$E0,$90,$88		;K
	dc.b	$40,$40,$40,$40,$70		;L
	dc.b	$88,$D8,$A8,$88,$88		;M
	dc.b	$88,$C8,$A8,$98,$88		;N
	dc.b	$70,$88,$88,$88,$70		;O
	dc.b	$F0,$88,$F0,$80,$80		;P
	dc.b	$70,$88,$88,$90,$68		;Q
	dc.b	$F0,$88,$F0,$88,$88		;R
	dc.b	$78,$80,$70,$08,$F0		;S
	dc.b	$F8,$20,$20,$20,$20		;T
	dc.b	$88,$88,$88,$88,$70		;U
	dc.b	$88,$88,$88,$50,$20		;V
	dc.b	$88,$88,$A8,$D8,$88		;W
	dc.b	$88,$88,$70,$88,$88		;X
	dc.b	$88,$88,$50,$20,$20		;Y
	dc.b	$F8,$08,$70,$80,$F8		;Z
	dc.b	$60,$40,$40,$40,$60		;[ (91)
	dc.b	$80,$40,$20,$10,$08		;\
	dc.b	$30,$10,$10,$10,$30		;]
	ds.b	5				;(94)
	ds.b	5				;(95)
	dc.b	$40,$20,$00,$00,$00		;` (96)

	dc.b	$f8,$a8,$20,$20,$f8		;97
	dc.b	$20,$78,$20,$f0,$20		;98
	dc.b	$20,$20,$38,$20,$e0		;99
	dc.b	$20,$20,$f8,$a8,$a8		;100
	dc.b	$a8,$a8,$f8,$20,$20		;101
	dc.b	$20,$a8,$88,$a8,$20		;102
	dc.b	$70,$a8,$a8,$20,$20		;103
	dc.b	$a8,$28,$f8,$a0,$a8		;104
	dc.b	$60,$a0,$b8,$a0,$60		;105
	dc.b	$30,$e8,$28,$e8,$30		;106

	cnop	0,4

;**********************************************************************

CaratteriDigital
	dc.w	6	;Numero colonne
	dc.w	9	;Numero righe
	dc.w	$ff03	;Mask
	dc.w	%11101	;Bitplane usati: ogni bit a uno corrisponde ad un bitplane usato

	dc.l	CD0,CD1,CD2,CD3,CD4,CD5,CD6,CD7,CD8,CD9	;Puntatori ai bitplane

CD0	dc.b	$70,$88,$88,$88,$70,$88,$88,$88,$70	;0
	dc.b	$00,$00,$00,$00,$70,$00,$00,$00,$00
	dc.b	$FC,$FC,$FC,$FC,$8C,$FC,$FC,$FC,$FC
	dc.b	$8C,$74,$74,$74,$FC,$74,$74,$74,$8C
CD1	dc.b	$70,$88,$88,$88,$70,$88,$88,$88,$70	;1
	dc.b	$70,$80,$80,$80,$70,$80,$80,$80,$70
	dc.b	$8C,$7C,$7C,$7C,$8C,$7C,$7C,$7C,$8C
	dc.b	$FC,$F4,$F4,$F4,$FC,$F4,$F4,$F4,$FC
CD2	dc.b	$70,$88,$88,$88,$70,$88,$88,$88,$70	;2
	dc.b	$00,$80,$80,$80,$00,$08,$08,$08,$00
	dc.b	$FC,$7C,$7C,$7C,$FC,$F4,$F4,$F4,$FC
	dc.b	$8C,$F4,$F4,$F4,$8C,$7C,$7C,$7C,$8C
CD3	dc.b	$70,$88,$88,$88,$70,$88,$88,$88,$70	;3
	dc.b	$00,$80,$80,$80,$00,$80,$80,$80,$00
	dc.b	$FC,$7C,$7C,$7C,$FC,$7C,$7C,$7C,$FC
	dc.b	$8C,$F4,$F4,$F4,$8C,$F4,$F4,$F4,$8C
CD4	dc.b	$70,$88,$88,$88,$70,$88,$88,$88,$70	;4
	dc.b	$70,$00,$00,$00,$00,$80,$80,$80,$70
	dc.b	$8C,$FC,$FC,$FC,$FC,$7C,$7C,$7C,$8C
	dc.b	$FC,$74,$74,$74,$8C,$F4,$F4,$F4,$FC
CD5	dc.b	$70,$88,$88,$88,$70,$88,$88,$88,$70	;5
	dc.b	$00,$08,$08,$08,$00,$80,$80,$80,$00
	dc.b	$FC,$F4,$F4,$F4,$FC,$7C,$7C,$7C,$FC
	dc.b	$8C,$7C,$7C,$7C,$8C,$F4,$F4,$F4,$8C
CD6	dc.b	$70,$88,$88,$88,$70,$88,$88,$88,$70	;6
	dc.b	$00,$08,$08,$08,$00,$00,$00,$00,$00
	dc.b	$FC,$F4,$F4,$F4,$FC,$FC,$FC,$FC,$FC
	dc.b	$8C,$7C,$7C,$7C,$8C,$74,$74,$74,$8C
CD7	dc.b	$70,$88,$88,$88,$70,$88,$88,$88,$70	;7
	dc.b	$00,$80,$80,$80,$70,$80,$80,$80,$70
	dc.b	$FC,$7C,$7C,$7C,$8C,$7C,$7C,$7C,$8C
	dc.b	$8C,$F4,$F4,$F4,$FC,$F4,$F4,$F4,$FC
CD8	dc.b	$70,$88,$88,$88,$70,$88,$88,$88,$70	;8
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
	dc.b	$8C,$74,$74,$74,$8C,$74,$74,$74,$8C
CD9	dc.b	$70,$88,$88,$88,$70,$88,$88,$88,$70	;9
	dc.b	$00,$00,$00,$00,$00,$80,$80,$80,$00
	dc.b	$FC,$FC,$FC,$FC,$FC,$7C,$7C,$7C,$FC
	dc.b	$8C,$74,$74,$74,$8C,$F4,$F4,$F4,$8C

	cnop	0,4

;**********************************************************************

CaratteriMini
	dc.w	4	;Numero colonne
	dc.w	5	;Numero righe
	dc.w	$ff0f	;Mask
	dc.w	%10001	;Bitplane usati: ogni bit a uno corrisponde ad un bitplane usato

	dc.l	CM0,CM1,CM2,CM3,CM4,CM5,CM6,CM7,CM8,CM9	;Puntatori ai bitplane

CM0	dc.b	$E0,$A0,$A0,$A0,$E0	;0
	dc.b	$10,$50,$50,$50,$10
CM1	dc.b	$20,$20,$20,$20,$20	;1
	dc.b	$D0,$D0,$D0,$D0,$D0
CM2	dc.b	$E0,$20,$E0,$80,$E0	;2
	dc.b	$10,$D0,$10,$70,$10
CM3	dc.b	$E0,$20,$60,$20,$E0	;3
	dc.b	$10,$D0,$90,$D0,$10
CM4	dc.b	$80,$80,$A0,$E0,$20	;4
	dc.b	$70,$70,$50,$10,$D0
CM5	dc.b	$E0,$80,$E0,$20,$E0	;5
	dc.b	$10,$70,$10,$D0,$10
CM6	dc.b	$80,$80,$E0,$A0,$E0	;6
	dc.b	$70,$70,$10,$50,$10
CM7	dc.b	$E0,$20,$20,$20,$20	;7
	dc.b	$10,$D0,$D0,$D0,$D0
CM8	dc.b	$E0,$A0,$E0,$A0,$E0	;8
	dc.b	$10,$50,$10,$50,$10
CM9	dc.b	$E0,$A0,$E0,$20,$20	;9
	dc.b	$10,$50,$10,$D0,$D0

;**********************************************************************

Messages	dc.l	Mess0,Mess1,Mess2,Mess3
		dc.l	Mess4,Mess5,Mess6,Mess7
		dc.l	Mess8,Mess9,Mess10,Mess11
		dc.l	Mess12,Mess13,Mess14,Mess15
		dc.l	Mess16,Mess17,Mess18
		dc.l	Mess19

Mess0	dc.b	'COLLECTED GREEN KEY',0
Mess1	dc.b	'COLLECTED YELLOW KEY',0
Mess2	dc.b	'COLLECTED RED KEY',0
Mess3	dc.b	'COLLECTED BLUE KEY',0
Mess4	dc.b	'NEED GREEN KEY',0
Mess5	dc.b	'NEED YELLOW KEY',0
Mess6	dc.b	'NEED RED KEY',0
Mess7	dc.b	'NEED BLUE KEY',0
Mess8	dc.b	'COLLECTED HEALTH ITEM',0
Mess9	dc.b	'COLLECTED SHIELDS ITEM',0
Mess10	dc.b	'COLLECTED ENERGY ITEM',0
Mess11	dc.b	'COLLECTED CREDITS ITEM',0
Mess12	dc.b	'WARNING!!! ITEM ERROR',0	;Se viene visualizzato questo messaggio, vuol dire che un pick item e' di tipo sbagliato
Mess13	dc.b	'SIMPLE SHOT',0
Mess14	dc.b	'FIREBALLS',0
Mess15	dc.b	'PLASMA GUN',0
Mess16	dc.b	'FLAME-THROWER',0
Mess17	dc.b	'MAGNETIC GUN',0
Mess18	dc.b	'DEATH MACHINE',0
Mess19	dc.b	-3,8,'PAUSE OFF',0

MessWait	dc.b	-2,60, -3,8, 0

NumberStr	dc.b	'           ',0

		cnop	0,4

;**********************************************************************

	section	__MERGED,BSS

		cnop	0,4

		xdef	ScrSprites

ScrSprites	ds.l	SPRMON_NSPRITE	;Puntatori agli sprite per lo sprite screen

SprBufPunIn	ds.l	1		;Pun. di ingresso al buffer
SprBufPunOut	ds.l	1		;Pun. di uscita al buffer

SprBuffer	ds.b	32*10		;Buffer per la routine di stampa delayed
					;I dati di ogni stringa da stampare sono:
					;  0  W  x
					;  2  W  y
					;  4  L  string pun.
					;  8  W  color (0/1/2)
					;	 Se color<0, allora e' un comando speciale e il pun. alla stringa puo' essere NULL:
					;	 	-1 : clear screen (x e y devono essere = 0)
					;		-2 : ....
EndSprBuffer:		;Fine del buffer

;*** ATTENZIONE! I due byte che seguono devono rimanere insieme
Command		ds.b	1		;Se<0, SprIRQPrint sta eseguendo un comando
CommandParam	ds.b	1		;Parametro del comando

		ds.w	1	;Usato per allineare

		cnop	0,4
