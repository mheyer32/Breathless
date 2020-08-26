;****************************************************************************
;*
;*	Animations.asm
;*
;*	Gestione delle animazioni di textures e muri
;*
;****************************************************************************


		include 'System'
		include 'TMap.i'



		xref	PlayerBlockPun
		xref	PlayerX,PlayerZ,CPlayerX,CPlayerZ
		xref	pause,Escape,terminal,TransEffect,TEdir
		xref	ObjEnemies
		xref	ProgramState
		xref	GlobalSound0,GlobalSound1,GlobalSound2,GlobalSound3
		xref	GlobalSound4,GlobalSound5,GlobalSound6,GlobalSound7
		xref	GlobalSound8,GlobalSound9,GlobalSound10

		xref	InitTerminal
		xref	PlaySoundFX,BufferedPlaySoundFX
		xref	ObjBufferedPlaySoundFX
		xref	Rnd
		xref	InitPlayerPos2
		xref	StartDoorSoundFX,StopDoorSoundFX
		xref	RemoveRemains

;****************************************************************************

		xdef	Animations
Animations

		move.l	animcounter(a5),d6
		move.l	d6,Canimcounter(a5)
		move.l	#0,animcounter(a5)

	;***** Anima le textures

		add.l	TextAnimCounter(a5),d6	;Somma il resto dell'animazione precedente
		bpl.s	Atxcpl
		move.l	#0,TextAnimCounter(a5)
		bra.s	Atxnotextanim
Atxcpl		divu	#8,d6
		move.l	d6,d1
		clr.w	d1
		swap	d1
		move.l	d1,TextAnimCounter(a5)	;Memorizza il resto
		moveq	#1,d1
		cmp.w	#1,d6		;Numero cicli=1 ?
		beq.s	Atxcok		; se si, salta
		tst.w	d6		;Numero cicli=0 ?
		bne.s	Atxmu		; se no, salta
		clr.l	d1
		tst.l	TextAnimOld(a5)	;Test se anche vecchio numero cicli=0
		bne.s	Atxcok		; se no, salta
		moveq	#1,d1		; se si, il num. cicli attuale non puo' essere 0, ma 1
		moveq	#1,d6
		bra.s	Atxcok
Atxmu		moveq	#-1,d1
		cmp.w	#2,d6		;Numero cicli>2 ?
		ble.s	Atxcd		; se no, salta
		moveq	#2,d6		; se si, allora numero cicli=2
Atxcd		tst.l	TextAnimOld(a5)	;Test se anche vecchio num. cicli=2
		bpl.s	Atxcok		; se no, salta
		moveq	#1,d1		; se si, il num. cicli attuale non puo' essere 2, ma 1
		moveq	#1,d6
Atxcok		move.l	d1,TextAnimOld(a5)	;Memorizza numero cicli attuale
		dbra	d6,Atxloop0
		bra.s	Atxnotextanim

Atxloop0	lea	AnimatedTextures(a5),a0
		move.l	(a0)+,d7	;d7=Num.animated textures
		bra.s	Atxnext
Atxloop1	move.l	(a0)+,a1	;a1=Pun. al campo tx_Brush della texture animata
		lea	4(a1),a2	;a2=Pun. al campo tx_AnimCount della texture animata
		move.l	(a2),d0		;d0=Contatore animazione
		addq.w	#4,d0
		move.l	(a2,d0.w),d1	;d1=Pun. prossimo brush dell'animazione
		bne.s	Atxj1		; Se=0 deve resettare l'animazione
		move.l	4(a2),d1	;d1=Primo brush dell'animazione
		moveq	#4,d0		;d0=Reset contatore animazione
Atxj1		move.l	d0,(a2)		;Memorizza contatore animazione
		move.l	d1,(a1)		;Memorizza pun.brush
Atxnext		dbra	d7,Atxloop1

		dbra	d6,Atxloop0
Atxnotextanim


	;***** Esegue effetti

		lea	Effects(a5),a3
		lea	EffectRoutineTable(pc),a4
		
		move.l	(a3)+,d7		;d7=Number of effect
		dbra	d7,AWloop
		bra.s	AWendeffect

AWloop		move.w	ef_effect(a3),d6	;d6=Effect
		bne.s	AWok			;Is there an effect ?
		lea	ef_SIZE(a3),a3		;If effect=0, skip
		bra.s	AWloop
AWok		lea	TriggerBlockListPun+6(a5),a6
		move.w	ef_trigger(a3),d1
		lea	(a6,d1.w*8),a6		;a6=Pun. alla word di comandi dall'esterno
		move.w	ef_status(a3),d0	;Legge status
		bmi.s	RemoveEffect		; Se status<0, deve rimuovere l'effetto
		move.l	ef_blocklist(a3),a2	;a2=block list pointer
		move.l	(a4,d6.w*4),a0
		jmp	(a0)			;Jump to the effect routine
AWnext		move.w	(a6),d0			;Nemico su uno dei blocchi ?
		bpl.s	AWnocomres		; Se no, salta
		and.w	#$7fff,d0
		move.w	d0,(a6)			;Azzera il bit che indica nemico su uno dei blocchi del trigger
AWnocomres	lea	ef_SIZE(a3),a3
		dbra	d7,AWloop
AWendeffect
		rts



;***** Routine per fermare un effetto quando questo e' terminato

RemoveEffect
		moveq	#0,d1
		move.w	d1,ef_effect(a3)	;Disabilita effetto corrente
		move.w	d1,ef_status(a3)
		subq.l	#1,Effects(a5)		;Decrementa il numero di effetti da eseguire
		move.w	d1,(a6)			;Azzera word comandi
		cmp.w	#-2,d0
		beq.s	AWnocomres		;Salta se non deve riabilitare l'effetto
		move.w	d1,-2(a6)		;Segnala che il trigger number con l'effetto corrente non e' in esecuzione e puo' essere abilitato
		bra.s	AWnocomres




;*** Tabella di puntatori alle routine per le animazioni dei muri

EffectRoutineTable:

		dc.l	0
		dc.l	CeilUp,		FloorUp
		dc.l	CeilDown,	FloorDown
		dc.l	DoorUp,		Door2
		dc.l	FloorUpDown,	FloorDownUp
		dc.l	LightUp,	LightDown
		dc.l	Terminal,	DoorDown
		dc.l	LinkedLight,	EndLevel
		dc.l	Teleport,	BlinkingLight
		dc.l	ActiveEnemy


;***** Routines di animazione dei muri

; Registri utilizzabili :
;
; d0,d1,d2,d3,d4,d5
; a0,a1
;
; Parametri passati:
;
; d0 = ef_status(a3)
; d6 = Effetto
; a2 = Block list pointer
; a3 = Puntatore alla struttura dell'effetto
; a6 = Puntatore alla word di comandi dall'esterno nella lista TriggerBlockListPun


	;***** Routine per segnalare di fermare un effetto quando questo e' terminato
	;***** Permette di riabilitare l'effetto collegato al trigger number
StopEffect1
		move.w	#-1,ef_status(a3)
		bra	AWnext

	;***** Routine per segnalare di fermare un effetto quando questo e' terminato
	;***** Non permette di riabilitare l'effetto collegato al trigger number
StopEffect2
		move.w	#-2,ef_status(a3)
		bra	AWnext


	;***** Il soffitto si alza di param1
CeilUp		move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	CU64noinit		;Jump if no init needed
		move.w	#1,ef_status(a3)
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
CU64noinit	move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	CU64addok
		move.w	d4,d2
CU64addok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
CU64loop	move.l	(a2)+,a0		;a0=Block pointer
		add.w	d2,bl_CeilHeight(a0)	;Incrementa altezza soffitto del blocco
		dbra	d5,CU64loop
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		bra	StopEffect2


	;***** Il pavimento si alza di param1
FloorUp		move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	FU64noinit		;Jump if no init needed
		move.w	#1,ef_status(a3)
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore num. di pixel mancanti alla fine 
FU64noinit	move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	FU64addok
		move.w	d4,d2
FU64addok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
FU64loop	move.l	(a2)+,a0		;a0=Block pointer
		add.w	d2,bl_FloorHeight(a0)	;Incrementa altezza del pavimento del blocco
		dbra	d5,FU64loop
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		bra	StopEffect2



	;***** Il soffitto si abbassa di param1
CeilDown	move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	CD64noinit		;Jump if no init needed
		move.w	#1,ef_status(a3)
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
CD64noinit	move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	CD64addok
		move.w	d4,d2
CD64addok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
CD64loop	move.l	(a2)+,a0		;a0=Block pointer
		sub.w	d2,bl_CeilHeight(a0)	;Incrementa altezza soffitto del blocco
		dbra	d5,CD64loop
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		bra	StopEffect2


	;***** Il pavimento si abbassa di param1
FloorDown	move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	FD64noinit		;Jump if no init needed
		move.w	#1,ef_status(a3)
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore num. di pixel mancanti alla fine 
FD64noinit	move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	FD64addok
		move.w	d4,d2
FD64addok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
FD64loop	move.l	(a2)+,a0		;a0=Block pointer
		sub.w	d2,bl_FloorHeight(a0)	;Incrementa altezza del pavimento del blocco
		dbra	d5,FD64loop
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		bra	StopEffect2



	;***** Door
	;***** Il soffitto si alza di param1, pausa di param2 50esimi di sec, poi si abbassa di param1
DoorUp
		move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	DUnoinit		;Jump if no init needed
		jsr	StartDoorSoundFX
		moveq	#1,d0
		move.w	d0,ef_status(a3)
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
DUnoinit	subq.w	#1,d0			;ef_status=1 ?
		beq.s	DUup
		subq.w	#1,d0			;ef_status=2 ?
		beq	DUpause

DUdown		tst.w	(a6)			;Test comando dall'esterno
		bmi	DUenemystop		;Se c'è un nemico sui blocchi soggetti all'effetto, si ferma
		move.l	PlayerBlockPun(a5),a1
		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	DUdownaddok
		move.w	d4,d2
DUdownaddok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
		clr.l	d3
DUloopdown	move.l	(a2)+,a0		;a0=Block pointer
		cmp.l	a0,a1			;Test se il player è su questo blocco
		bne.s	DUnopl
		moveq	#1,d3			;Se si, setta flag
DUnopl		sub.w	d2,bl_CeilHeight(a0)	;decrementa altezza soffitto del blocco
		dbra	d5,DUloopdown
		tst.l	d3			;Se il player è su uno dei blocchi della lista
		bne	DUplayerstop		; salta
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		jsr	StopDoorSoundFX
		move.w	(a6),d0			;Test se deve eliminare resti nemico
		and.w	#$7fff,d0
		beq	StopEffect1		; Se no, salta
		bsr	RemoveRemains		; Altrimenti rimuove oggetto
		clr.w	(a6)
		bra	StopEffect1

DUup		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	DUupaddok
		move.w	d4,d2
DUupaddok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
DUloopup	move.l	(a2)+,a0		;a0=Block pointer
		add.w	d2,bl_CeilHeight(a0)	;Incrementa altezza soffitto del blocco
		dbra	d5,DUloopup
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, passa alla pausa
		jsr	StopDoorSoundFX
		move.w	ef_param2(a3),ef_var1(a3)	;ef_var1=contatore
		beq	StopEffect2		;Se pausa=0, ferma l'effetto e non chiude la porta
		move.w	#2,ef_status(a3)
		bra	AWnext

DUpause		move.l	PlayerBlockPun(a5),a1
		move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
DUpploop	cmp.l	(a2)+,a1		;Test se il player è su questo blocco
		beq	AWnext			;Se si, esce
		dbra	d5,DUpploop
		tst.w	(a6)			;Test comando dall'esterno
		bmi	AWnext			;Se c'è un nemico sui blocchi soggetti all'effetto, si ferma
		sub.w	d2,ef_var1(a3)		;Decrementa contatore pausa
		bgt	AWnext
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
		move.w	#3,ef_status(a3)
		jsr	StartDoorSoundFX
		bra	AWnext
DUplayerstop		; Ripristina altezza soffito dei blocchi della lista
		move.l	ef_blocklist(a3),a2	;a2=block list pointer
		move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
DUloopnodown	move.l	(a2)+,a0		;a0=Block pointer
		add.w	d2,bl_CeilHeight(a0)	;ripristina altezza soffitto del blocco
		dbra	d5,DUloopnodown
DUenemystop	move.w	#1,ef_status(a3)	;Deve riportare su il soffitto
		move.w	ef_param1(a3),d0
		sub.w	ef_var1(a3),d0
		move.w	d0,ef_var1(a3)		;ef_var1=contatore
		bra	AWnext



	;***** Il pavimento si alza di param1, pausa di param2 50esimi di sec, poi si abbassa di param1
FloorUpDown
		move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	FUDnoinit		;Jump if no init needed
		jsr	StartDoorSoundFX
		moveq	#1,d0
		move.w	d0,ef_status(a3)
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
FUDnoinit	subq.w	#1,d0			;ef_status=1 ?
		beq.s	FUDup
		subq.w	#1,d0			;ef_status=2 ?
		beq.s	FUDpause

FUDdown		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	FUDdownaddok
		move.w	d4,d2
FUDdownaddok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
FUDloopdown	move.l	(a2)+,a0		;a0=Block pointer
		sub.w	d2,bl_FloorHeight(a0)	;decrementa altezza pavimento del blocco
		dbra	d5,FUDloopdown
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		jsr	StopDoorSoundFX
		bra	StopEffect1

FUDup		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	FUDupaddok
		move.w	d4,d2
FUDupaddok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
FUDloopup	move.l	(a2)+,a0		;a0=Block pointer
		add.w	d2,bl_FloorHeight(a0)	;Incrementa altezza pavimento del blocco
		dbra	d5,FUDloopup
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, passa alla pausa
		jsr	StopDoorSoundFX
		move.w	ef_param2(a3),ef_var1(a3)	;ef_var1=contatore
		beq	StopEffect2		;Se pausa=0, ferma l'effetto
		move.w	#2,ef_status(a3)
		bra	AWnext

FUDpause	sub.w	d2,ef_var1(a3)		;Decrementa contatore pausa
		bgt	AWnext
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
		move.w	#3,ef_status(a3)
		jsr	StartDoorSoundFX
		bra	AWnext


	;***** Il pavimento si abbassa di param1, pausa di param2 50esimi di sec, poi si alza di param1
FloorDownUp
		move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	FDUnoinit		;Jump if no init needed
		jsr	StartDoorSoundFX
		moveq	#1,d0
		move.w	d0,ef_status(a3)
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
FDUnoinit	subq.w	#1,d0			;ef_status=1 ?
		beq.s	FDUdown
		subq.w	#1,d0			;ef_status=2 ?
		beq.s	FDUpause

FDUup		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	FDUupaddok
		move.w	d4,d2
FDUupaddok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
FDUloopup	move.l	(a2)+,a0		;a0=Block pointer
		add.w	d2,bl_FloorHeight(a0)	;incrementa altezza pavimento del blocco
		dbra	d5,FDUloopup
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		jsr	StopDoorSoundFX
		bra	StopEffect1

FDUdown		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	FDUdownaddok
		move.w	d4,d2
FDUdownaddok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
FDUloopdown	move.l	(a2)+,a0		;a0=Block pointer
		sub.w	d2,bl_FloorHeight(a0)	;Dencrementa altezza pavimento del blocco
		dbra	d5,FDUloopdown
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, passa alla pausa
		jsr	StopDoorSoundFX
		move.w	ef_param2(a3),ef_var1(a3)	;ef_var1=contatore
		beq	StopEffect2		;Se pausa=0, ferma l'effetto
		move.w	#2,ef_status(a3)
		bra	AWnext

FDUpause	sub.w	d2,ef_var1(a3)		;Decrementa contatore pausa
		bgt	AWnext
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
		move.w	#3,ef_status(a3)
		jsr	StartDoorSoundFX
		bra	AWnext


	;***** Aumenta la luminosità di una quantità pari al parametro 1
	;*****  nel numero di 50esimi specificati dal parametro 2
	;***** I due parametri hanno valori da 0 a +127
LightUp
		move.l	Canimcounter(a5),d2	;d2=num. di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	LUnoinit		;Jump if no init needed
		move.w	#1,ef_status(a3)
		clr.l	d0
		move.w	ef_param1(a3),d0
		lsl.w	#8,d0
		move.w	d0,ef_var1(a3)		;ef_var1=contatore durata effetto
		divu.w	ef_param2(a3),d0	;Calcola la velocità di variazione della luce, dividendo parametro1<<8 e parametro2
		move.w	d0,ef_param2(a3)	;ef_param2=velocità variazione luminosità. E' relativa al 50esimo di secondo. Formato 8.8
		move.w	#0,ef_var2(a3)		;ef_var2=parte decimale del contatore di variazione della luce
LUnoinit	mulu.w	ef_param2(a3),d2	;d2=Variazione della luce
		cmp.l	#$7fff,d2		;Troppo grande ?
		ble.s	LUok1
		move.w	#$7fff,d2
LUok1		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare la variazione della luce
		ble.s	LUaddok			; se no, salta
		move.w	d4,d2
LUaddok		move.w	d2,d3			;Conserva in d3 per aggiornare contatore durata effetto
		sub.b	d2,ef_var2(a3)		;Sottrae parte decimale
		bcc.s	LUnoovfl		; se non c'è riporto, salta
		add.w	#$100,d2		; se c'è riporto, lo somma alla parte intera di d2
LUnoovfl	lsr.w	#8,d2
		move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
LUloop		move.l	(a2)+,a0		;a0=Block pointer
		sub.b	d2,bl_Illumination(a0)	;Aumenta luminosità del blocco
		bcc.s	LUok2			;Se c'è overflow deve aggiustare il valore di luminosità
		move.b	#0,bl_Illumination(a0)
LUok2		dbra	d5,LUloop
		sub.w	d3,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		bra	StopEffect2


	;***** Diminuisce la luminosità di una quantità pari al parametro 1
	;*****  nel numero di 50esimi specificati dal parametro 2
	;***** I due parametri hanno valori da 0 a +127
LightDown
		move.l	Canimcounter(a5),d2	;d2=num. di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	LDnoinit		;Jump if no init needed
		move.w	#1,ef_status(a3)
		clr.l	d0
		move.w	ef_param1(a3),d0
		lsl.w	#8,d0
		move.w	d0,ef_var1(a3)		;ef_var1=contatore durata effetto
		divu.w	ef_param2(a3),d0	;Calcola la velocità di variazione della luce, dividendo parametro1<<8 e parametro2
		move.w	d0,ef_param2(a3)	;ef_param2=velocità variazione luminosità. E' relativa al 50esimo di secondo. Formato 8.8
		move.w	#0,ef_var2(a3)		;ef_var2=parte decimale del contatore di variazione della luce
LDnoinit	mulu.w	ef_param2(a3),d2	;d2=Variazione della luce
		cmp.l	#$7fff,d2		;Troppo grande ?
		ble.s	LDok1
		move.w	#$7fff,d2
LDok1		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare la variazione della luce
		ble.s	LDaddok			; se no, salta
		move.w	d4,d2
LDaddok		move.w	d2,d3			;Conserva in d3 per aggiornare contatore durata effetto
		sub.b	d2,ef_var2(a3)		;Sottrae parte decimale
		bcc.s	LDnoovfl		; se non c'è riporto, salta
		add.w	#$100,d2		; se c'è riporto, lo somma alla parte intera di d2
LDnoovfl	lsr.w	#8,d2
		move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
LDloop		move.l	(a2)+,a0		;a0=Block pointer
		add.b	d2,bl_Illumination(a0)	;Diminuisce luminosità del blocco
		bcc.s	LDok2			;Se c'è overflow deve aggiustare il valore di luminosità
		move.b	#0,bl_Illumination(a0)
LDok2		dbra	d5,LDloop
		sub.w	d3,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		bra	StopEffect2



	;***** Door "a due ante"
	;***** Il soffitto si alza di param1, pausa di param2 50esimi di sec, poi si abbassa di param1
	;***** Il pavimento si abbassa di param1, pausa di param2 50esimi di sec, poi si alza di param1
Door2
	 	move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	D2noinit		;Jump if no init needed
		jsr	StartDoorSoundFX
		moveq	#1,d0
		move.w	d0,ef_status(a3)
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
D2noinit	subq.w	#1,d0			;ef_status=1 ?
		beq.s	D2up
		subq.w	#1,d0			;ef_status=2 ?
		beq	D2pause

D2down		tst.w	(a6)			;Test comando dall'esterno
		bmi	D2enemystop		;Se c'è un nemico sui blocchi soggetti all'effetto, si ferma
		move.l	PlayerBlockPun(a5),a1
		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	D2downaddok
		move.w	d4,d2
D2downaddok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
		clr.l	d3
D2loopdown	move.l	(a2)+,a0		;a0=Block pointer
		cmp.l	a0,a1			;Test se il player è su questo blocco
		bne.s	D2nopl
		moveq	#1,d3			;Se si, setta il flag
D2nopl		sub.w	d2,bl_CeilHeight(a0)	;decrementa altezza soffitto del blocco
		add.w	d2,bl_FloorHeight(a0)	;incrementa altezza pavimento del blocco
		dbra	d5,D2loopdown
		tst.l	d3			;Se il player è su uno dei blocchi della lista
		bne	D2playerstop		; salta
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		jsr	StopDoorSoundFX
		move.w	(a6),d0			;Test se deve eliminare resti nemico
		and.w	#$7fff,d0
		beq	StopEffect1		; Se no, salta
		bsr	RemoveRemains		; Altrimenti rimuove oggetto
		clr.w	(a6)
		bra	StopEffect1

D2up		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	D2upaddok
		move.w	d4,d2
D2upaddok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
D2loopup	move.l	(a2)+,a0		;a0=Block pointer
		add.w	d2,bl_CeilHeight(a0)	;Incrementa altezza soffitto del blocco
		sub.w	d2,bl_FloorHeight(a0)	;Decrementa altezza pavimento del blocco
		dbra	d5,D2loopup
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, passa alla pausa
		jsr	StopDoorSoundFX
		move.w	ef_param2(a3),ef_var1(a3)	;ef_var1=contatore
		beq	StopEffect2		;Se pausa=0, ferma l'effetto e non chiude la porta
		move.w	#2,ef_status(a3)
		bra	AWnext

D2pause		move.l	PlayerBlockPun(a5),a1
		move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
D2pploop	cmp.l	(a2)+,a1		;Test se il player è su questo blocco
		beq	AWnext			;Se si, esce
		dbra	d5,D2pploop
		tst.w	(a6)			;Test comando dall'esterno
		bmi	AWnext			;Se c'è un nemico sui blocchi soggetti all'effetto, si ferma
		sub.w	d2,ef_var1(a3)		;Decrementa contatore pausa
		bgt	AWnext
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
		move.w	#3,ef_status(a3)
		jsr	StartDoorSoundFX
		bra	AWnext
D2playerstop		; Ripristina altezza soffito dei blocchi della lista
		move.l	ef_blocklist(a3),a2	;a2=block list pointer
		move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
D2loopnodown	move.l	(a2)+,a0		;a0=Block pointer
		add.w	d2,bl_CeilHeight(a0)	;ripristina altezza soffitto del blocco
		sub.w	d2,bl_FloorHeight(a0)	;ripristina altezza pavimento del blocco
		dbra	d5,D2loopnodown
D2enemystop	move.w	#1,ef_status(a3)	;Deve riportare su il soffitto
		move.w	ef_param1(a3),d0
		sub.w	ef_var1(a3),d0
		move.w	d0,ef_var1(a3)		;ef_var1=contatore
		bra	AWnext


	;***** Attiva il terminale
Terminal
		move.w	ef_param1(a3),terminal+2(a5)
		move.w	#1,pause(a5)
		jsr	InitTerminal
		bra	StopEffect1


	;***** Door down
	;***** Il pavimento si abbassa di param1, pausa di param2 50esimi di sec, poi si alza di param1
DoorDown
		move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	DDnoinit		;Jump if no init needed
		jsr	StartDoorSoundFX
		moveq	#1,d0
		move.w	d0,ef_status(a3)
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
DDnoinit	subq.w	#1,d0			;ef_status=1 ?
		beq.s	DDdown
		subq.w	#1,d0			;ef_status=2 ?
		beq	DDpause

DDup		tst.w	(a6)			;Test comando dall'esterno
		bmi	DDenemystop		;Se c'è un nemico sui blocchi soggetti all'effetto, si ferma
		move.l	PlayerBlockPun(a5),a1
		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	DDupaddok
		move.w	d4,d2
DDupaddok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
		clr.l	d3
DDloopup	move.l	(a2)+,a0		;a0=Block pointer
		cmp.l	a0,a1			;Test se il player è su questo blocco
		bne.s	DDnopl
		moveq	#1,d3			;Se si, setta flag
DDnopl		add.w	d2,bl_FloorHeight(a0)	;Incrementa altezza pavimento del blocco
		dbra	d5,DDloopup
		tst.l	d3			;Se il player è su uno dei blocchi della lista
		bne	DDplayerstop		; salta
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, disabilita animazione
		jsr	StopDoorSoundFX
		move.w	(a6),d0			;Test se deve eliminare resti nemico
		and.w	#$7fff,d0
		beq	StopEffect1		; Se no, salta
		bsr	RemoveRemains		; Altrimenti rimuove oggetto
		clr.w	(a6)
		bra	StopEffect1

DDdown		move.w	ef_var1(a3),d4
		cmp.w	d4,d2			;Test se aggiustare num.pixel movimento
		ble.s	DDdownaddok
		move.w	d4,d2
DDdownaddok	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
DDloopdown	move.l	(a2)+,a0		;a0=Block pointer
		sub.w	d2,bl_FloorHeight(a0)	;Decrementa altezza pavimento del blocco
		dbra	d5,DDloopdown
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext			;Se contatore<=0, passa alla pausa
		jsr	StopDoorSoundFX
		move.w	ef_param2(a3),ef_var1(a3)	;ef_var1=contatore
		beq	StopEffect2		;Se pausa=0, ferma l'effetto e non chiude la porta
		move.w	#2,ef_status(a3)
		bra	AWnext

DDpause		move.l	PlayerBlockPun(a5),a1
		move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
DDpploop	cmp.l	(a2)+,a1		;Test se il player è su questo blocco
		beq	AWnext			;Se si, esce
		dbra	d5,DDpploop
		tst.w	(a6)			;Test comando dall'esterno
		bmi	AWnext			;Se c'è un nemico sui blocchi soggetti all'effetto, si ferma
		sub.w	d2,ef_var1(a3)		;Decrementa contatore pausa
		bgt	AWnext
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
		move.w	#3,ef_status(a3)
		jsr	StartDoorSoundFX
		bra	AWnext
DDplayerstop		; Ripristina altezza pavimento dei blocchi della lista
		move.l	ef_blocklist(a3),a2	;a2=block list pointer
		move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
DDloopnodown	move.l	(a2)+,a0		;a0=Block pointer
		sub.w	d2,bl_FloorHeight(a0)	;ripristina altezza pavimento del blocco
		dbra	d5,DDloopnodown
DDenemystop	move.w	#1,ef_status(a3)	;Deve riportare giu' il pavimento
		move.w	ef_param1(a3),d0
		sub.w	ef_var1(a3),d0
		move.w	d0,ef_var1(a3)		;ef_var1=contatore
		bra	AWnext



	;***** Modifica la luminosità in base al valore di ef_var1
	;***** di un effetto linkato (in genere effetti di tipo Door).
	;***** Param1 e' la massima variazione di luminosità da far
	;***** corrispondere alla massima variazione di altezza
	;***** dell'effetto linkato.
	;***** Param2 e' il trigger number dell'effetto linkato, che
	;***** deve appartenere alla stessa lista.
	;***** Questo effetto deve essere applicato solo a blocchi
	;***** con la stessa luminosità iniziale.

LinkedLight
		tst.w	d0			;Test status
		bne.s	LLnoinit		;Jump if no init needed
		move.w	ef_param2(a3),d0	;d0=trigger number da cercare
		lea	Effects(a5),a0
		move.l	(a0)+,d5		;d5=Number of effect
		dbra	d5,LLloopsearch
		bra	AWnext
LLloopsearch	tst.w	ef_effect(a0)		;C'e' un effetto ?
		bne.s	LLsok			; Se si, salta
LLlsnext	lea	ef_SIZE(a0),a0
		dbra	d5,LLloopsearch		; Se no, continua loop
		bra	AWnext			;Esce
LLsok		cmp.w	ef_trigger(a0),d0	;Trovato trigger number ?
		bne.s	LLlsnext		; Se no, salta
		tst.w	ef_status(a0)		;Effetto inizializzato ?
		beq	AWnext			; Se no, esce
		move.l	a0,ef_var3(a3)		;Scrive in ef_var3 e ef_var4 il pun. all'effetto linkato
		tst.w	ef_param1(a0)		;Test per evitare divisioni per zero
		beq	StopEffect2
		move.l	4(a2),a0		;a0=Block pointer
		move.b	bl_Illumination(a0),ef_var2(a3)	;Salva luminosità iniziale
		move.w	#1,ef_status(a3)
LLnoinit	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
		move.l	ef_var3(a3),a0		;a0=Pun. effetto linkato
		move.w	ef_status(a0),d0	;d0=status effetto linkato
		bmi.s	LLend			;Se terminato effetto linkato, termina anche questo
		subq.w	#1,d0			;ef_status=1
		beq.s	LLup
		subq.w	#1,d0			;ef_status=2
		beq	AWnext

LLdown		move.w	ef_var1(a0),d1
		mulu.w	ef_param1(a3),d1
		divu.w	ef_param1(a0),d1	;d1=entità della variazione di luminosità
		move.b	ef_var2(a3),d0
		sub.b	d1,d0			;d0=nuovo valore luminosità
		bra.s	LLloop

LLup		move.w	ef_param1(a0),d1
		sub.w	ef_var1(a0),d1
		mulu.w	ef_param1(a3),d1
		divu.w	ef_param1(a0),d1	;d1=entità della variazione di luminosità
		move.b	ef_var2(a3),d0
		sub.b	d1,d0			;d0=nuovo valore luminosità

LLloop		move.l	(a2)+,a0		;a0=Block pointer
		move.b	d0,bl_Illumination(a0)	;Modifica luminosità del blocco
		dbra	d5,LLloop
		bra	AWnext

LLend		addq.w	#1,d0			;Se l'effetto linkato è stato bloccato in maniera definitiva,
		bne	StopEffect2		; blocca in maniera definitiva anche questo e non ripristina luminosità iniziale
		move.b	ef_var2(a3),d0		;d0=Luminosità iniziale
LLloopend	move.l	(a2)+,a0		;a0=Block pointer
		move.b	d0,bl_Illumination(a0)	;Modifica luminosità del blocco
		dbra	d5,LLloopend
		bra	StopEffect1


	;***** Fine livello
EndLevel
		st	Escape(a5)
		bra	StopEffect2


	;***** Teletrasporto
Teleport
		tst.w	d0			;Test status
		bne.s	Tnoinit			;Jump if no init needed
		moveq	#0,d1
		move.l	GlobalSound3(a5),a0
		jsr	BufferedPlaySoundFX
		move.b	#-1,ProgramState(a5)
		move.l	#$04000001,TransEffect(a5)
		move.w	#32,ef_var1(a3)		;Init contatore
		move.w	#1,ef_status(a3)
Tnoinit		move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext
		move.w	ef_param1(a3),d1	;x in mappa
		lsl.w	#6,d1
		add.w	#BLOCK_SIZE>>1,d1
		move.w	d1,CPlayerX(a5)
		move.w	ef_param2(a3),d1	;z in mappa
		lsl.w	#6,d1
		add.w	#BLOCK_SIZE>>1,d1
		move.w	d1,CPlayerZ(a5)
		jsr	InitPlayerPos2
		bra	StopEffect1


	;***** Ogni ef_param2 50esimi, le luci si portano per un istante
	;***** al valore specificato da ef_param1, poi tornano al
	;***** valore originario.
	;***** Se ef_param2=0, il numero di 50esimi è random, e varia
	;***** tra 0 e 3 sec.
	;***** Questo effetto deve essere applicato solo a blocchi
	;***** con la stessa luminosità iniziale.
BlinkingLight
		tst.w	d0			;Test status
		bne.s	BLLnoinit		;Jump if no init needed
		move.w	#50,ef_var1(a3)		;Init contatore
		move.l	4(a2),a0		;a0=Block pointer
		move.b	bl_Illumination(a0),ef_var2(a3)	;Salva luminosità iniziale
		moveq	#1,d0
		move.w	d0,ef_status(a3)
BLLnoinit	move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		sub.w	d2,ef_var1(a3)		;Decrementa contatore
		bgt	AWnext
		move.w	ef_param1(a3),d1	;d1=lights (se status=1)
		moveq	#2,d2			;d2=new status (se status=1)
		moveq	#10,d3			;d3=new ef_var1 (se status=1)
		subq.w	#1,d0			;Status=1 ?
		beq.s	BLLmodifylights
		move.w	ef_param2(a3),d3	;d3=new ef_var1 (se status=2)
		bne.s	BLLnornd		; Se=0, calcola valore rnd
		move.w	#3*50,d1
		jsr	Rnd
		move.w	d0,d3			;d3=new ef_var1 (se status=2)
BLLnornd	move.b	ef_var2(a3),d1		;d1=lights (se status=2)
		moveq	#1,d2			;d2=new status (se status=2)
BLLmodifylights	move.l	(a2)+,d5		;d5=Numero blocchi nella lista - 1
BLLloop		move.l	(a2)+,a0		;a0=Block pointer
		move.b	d1,bl_Illumination(a0)	;Modifica luminosità del blocco
		dbra	d5,BLLloop
		move.w	d2,ef_status(a3)
		move.w	d3,ef_var1(a3)
		bra	AWnext


	;***** Attiva nemici in base al trigger number
	;***** dell'effetto corrente
ActiveEnemy
		move.l	Canimcounter(a5),d2	;d2=num.pixel movimento, pari al numero di 50esimi passati dall'ultima volta
		tst.w	d0			;Test status
		bne.s	AEnoinit		;Jump if no init needed
		move.w	#1,ef_status(a3)
		move.w	ef_param1(a3),ef_var1(a3)	;ef_var1=contatore
AEnoinit	sub.w	d2,ef_var1(a3)		;Decrementa contatore pausa
		bgt	AWnext
		move.w	ef_trigger(a3),d2
		move.l	ObjEnemies(a5),d1
		beq.s	AEout
AEloop		move.l	d1,a0
		cmp.b	obj_inactive(a0),d2	;Trovato trigger ?
		bne.s	AEnofound		; Se no, salta
		clr.b	obj_inactive(a0)	;Attiva il nemico
		moveq	#0,d0
		jsr	ObjBufferedPlaySoundFX
AEnofound	move.l	obj_listnext(a0),d1
		bne.s	AEloop
AEout		bra	StopEffect2

;****************************************************************************

		section	TABLES,BSS

		xdef	TriggerBlockList

TriggerBlockList:
		ds.l	256*16	;Buffer per contenere la lista di blocchi per ogni trigger number.
				;Lo spazio in questa lista viene allocato dinamicamente.
				;Per ogni trigger number viene allocato un numero di long pari al
				;numero di blocchi soggetti all'effetto, piu' uno:
				;
				;	Trigger 1 :	Num. blocchi
				;			Pun. blocco 1
				;			 .      ..  .
				;			Pun. blocco n
				;
				;	Trigger 2 :	Num. blocchi
				;			Pun. blocco 1
				;			 .      ..  .
				;			Pun. blocco n

;****************************************************************************

	section	__MERGED,BSS


		xdef	VBTimer,VBTimer2,animcounter,Canimcounter

VBTimer		ds.l	1	;Contatore globale in 50esimi
VBTimer2	ds.l	1	;Contatore globale in 50esimi non viene fermato durante le pause
animcounter	ds.l	1	;Contatore in 50esimi per tempo di rendering dell'ultimo frame
Canimcounter	ds.l	1	;Copia interna di animcounter

TextAnimCounter	ds.l	1
TextAnimOld	ds.l	1	;Vecchio num. cicli (-1=2 cicli; 0=0 cicli; 1=1 ciclo)


		xdef	AnimatedTextures

AnimatedTextures:
		ds.l	1	;Number of animated textures
		ds.l	64	;List of pointers to the animated textures



		xdef	BlockEffectListPun
BlockEffectListPun:
		ds.l	256	;Array di puntatori alle liste di effetti


		xdef	TriggerBlockListPun
TriggerBlockListPun:
		ds.l	256*2	;Array di strutture relative ai trigger number
				;La struttura e' cosi' composta:
				; 0  L  Puntatore alla lista di blocchi soggetti all'effetto
				; 4  W  Flag. Se<>0 l'effetto e' gia' attivo
				; 6  W  Questa word viene usata per comandi dall'esterno (attualmente usato solo per le porte)
				;	I 15 bit bassi sono il codice dell'oggetto rimasto nella porta
				;	(in genere i resti di un nemico). Se tali bit sono a zero, non ci sono resti nella porta.
				;	Il bit piu' alto, se settato, indica che c'e' un nemico sui blocchi della porta.


		xdef	Effects
Effects:
		ds.l	1		;Number of current animations
		ds.b	MAX_EFFECT*ef_SIZE	;Vedi TMap.i per la definizione della struttura dati

