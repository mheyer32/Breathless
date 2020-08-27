;***************************************************************
;*
;*	Gestione movimento player
;*
;* Versione:
;*
;* - Movimento migliorato con gestione dell'inerzia
;*
;* - Controllo collisioni con le pareti migliorato
;*
;* - Migliorato movimento player e aggiunte direzioni oblique
;*
;***************************************************************

	include	'TMap.i'

	xref	sintable,costable
	xref	CPlayerX,CPlayerY,CPlayerZ,PlayerSpeed,CPlayerHeading,PlayerMoved
	xref	CPlayerViewDirX,CPlayerViewDirZ,PlayerYOsc
	xref	CPlayerBlock,CPlayerBlockPun,CPlayerMapPun
	xref	CSkyRotation,PlayerDeath
	xref	Map,Blocks,Edges,Objects
	xref	ObjectsPunList,ObjEnemies
	xref	CurrentBitmap
	xref	BlockEffectListPun
	xref	TriggerBlockListPun,Effects
	xref	keypressed,Escape,ProgramState
	xref	PlayerHealth,PlayerShields,PlayerEnergy
	xref	PlayerCredits,PlayerScore
	xref	PlayerHealthFL,PlayerShieldsFL,PlayerEnergyFL
	xref	PlayerCreditsFL,PlayerScoreFL
	xref	GreenKey,YellowKey,RedKey,BlueKey
	xref	GreenKeyFL,YellowKeyFL,RedKeyFL,BlueKeyFL
	xref	Fire
	xref	GlobalSound0,GlobalSound1,GlobalSound2,GlobalSound3
	xref	GlobalSound4,GlobalSound5,GlobalSound6,GlobalSound7
	xref	GlobalSound8,GlobalSound9,GlobalSound10

	xref	PlaySoundFX,BufferedPlaySoundFX
	xref	ObjBufferedPlaySoundFX
	xref	RemovePickThing
	xref	SprDelayPrintMessage
	xref	CollectItem,PlayerHit

;**********************************************************************
;*** Macro per scorrere la lista dei nemici alla ricerca di quelli
;*** che aspettano di essere attivati dall'effetto contenuto in d0

;ACTIVE_ENEMY	MACRO
;
;		move.l	ObjEnemies(a5),d1
;		beq.s	AEout\@
;AEloop\@	move.l	d1,a0
;		cmp.b	obj_inactive(a0),d2	;Trovato codice effetto ?
;		bne.s	AEnofound\@		; Se no, salta
;		clr.b	obj_inactive(a0)	;Attiva il nemico
;		moveq	#0,d0
;		jsr	ObjBufferedPlaySoundFX
;AEnofound\@	move.l	obj_listnext(a0),d1
;		bne.s	AEloop\@
;AEout\@
;
;		ENDM

;**********************************************************************

		xdef	DoMovement
DoMovement
		tst.w	switchpressed(a5)	;Test se premuta barra spazio
		beq.s	DMnoswpr
		clr.w	switchpressed(a5)
		bsr	SwitchManagement
DMnoswpr
;		clr.w	PlayerMoved(a5)

		bsr	ReadJoy

		tst.w	speedup(a5)
		bne.s	spup
		move.w	PlayerWalkSpeed(a5),d2
		move.w	PlayerRotWalkSpeed(a5),d3
		bra.s	no_spup
spup		move.w	PlayerRunSpeed(a5),d2
		move.w	PlayerRotRunSpeed(a5),d3
no_spup

		clr.w	RotMaxSpeed(a5)
		tst.w	PlayerFalling(a5)	;Se sta cadendo, nessun input  accettato
		bne	nomoving
		clr.w	WalkMaxSpeed(a5)

		tst.b	PlayerDeath(a5)		;Player morto ?
		bne	nomoving		; Se si, salta
		tst.b	ProgramState(a5)	;Gioco congelato ?
		bmi	nomoving		; Se si, salta

		moveq	#0,d4

		tst.b	sideright(a5)		;Test se c' movimento laterale/destra
		bne.s	moveright2		; Se si, salta
		tst.b	sideleft(a5)		;Test se c' movimento laterale/sinistra
		bne.s	moveleft		; Se si, salta

		tst.w	sidemove(a5)		;Test se c' movimento laterale
		beq.s	no_side

moveright	tst.w	joyright(a5)		;Test move right
		beq.s	no_moveright
moveright2	or.b	#1,d4
		bra.s	no_moveleft
no_moveright
		tst.w	joyleft(a5)		;Test move left
		beq.s	no_left
moveleft	or.b	#2,d4
no_moveleft

		tst.w	sidemove(a5)		;Test se premuto tasto movimento laterale
		bne.s	no_left
no_side
		tst.w	joyright(a5)		;Test rotate right
		beq.s	no_right
		move.w	d3,RotMaxSpeed(a5)

no_right	tst.w	joyleft(a5)		;Test rotate left
		beq.s	no_left
		neg.w	d3
		move.w	d3,RotMaxSpeed(a5)


no_left		tst.w	joyup(a5)		;Test up
		beq.s	no_speedup
		or.b	#8,d4

no_speedup	tst.w	joydown(a5)		;Test down
		beq.s	no_slowdown
		or.b	#4,d4
no_slowdown:


		tst.b	d4			;Test se premuto tasti di movimento
		beq.s	nomoving		; Se no, salta
		moveq	#0,d3
		move.b	olddir(a5),d3
		lea	movingdirtable(pc),a0
		move.w	(a0,d4.w*4),MovingDir(a5)
		tst.w	2(a0,d4.w*4)
		bpl.s	noneg
		neg.w	d2
noneg		move.w	d2,WalkMaxSpeed(a5)

		move.b	d4,olddir(a5)

		lea	updspeedtable-11(pc),a0
		mulu.w	#10,d4
		add.w	d3,d4
		tst.b	(a0,d4.w)
		beq.s	nomoving
		bpl.s	nj1
		neg.w	PlayerSpeed(a5)
		bra.s	nomoving
nj1		clr.w	PlayerSpeed(a5)

nomoving



;***** Muoviamo il player:

	;*** Gestione accelerazione per il movimento

		move.w	WalkMaxSpeed(a5),d0
		move.w	PlayerSpeed(a5),d2
		cmp.w	d0,d2			;Test se massima velocit <> velocit attuale
		beq.s	DMspeedok
		bgt.s	DMwalkdec
		add.w	PlayerAccel(a5),d2	;accelera
		cmp.w	d0,d2			;PlayerSpeed<=WalkMaxSpeed ?
		ble.s	DMwalkacc		; Se si, salta
		move.w	d0,d2			;Altrimenti pone PlayerSpeed=WalkMaxSpeed
		bra.s	DMwalkacc
DMwalkdec	sub.w	PlayerAccel(a5),d2	;decelera
		cmp.w	d0,d2			;PlayerSpeed>=WalkMaxSpeed ?
		bge.s	DMwalkacc		; Se si, salta
		move.w	d0,d2			;Altrimenti pone PlayerSpeed=WalkMaxSpeed
DMwalkacc	move.w	d2,PlayerSpeed(a5)
DMspeedok

;		move.w	PlayerSpeed(a5),d2
;		cmp.w	WalkMaxSpeed(a5),d2	;Test se massima velocit <> velocit attuale
;		beq.s	DMspeedok
;		bgt.s	DMwalkdec
;		add.w	PlayerAccel(a5),d2	;accelera
;		bra.s	DMwalkacc
;DMwalkdec	sub.w	PlayerAccel(a5),d2	;decelera
;DMwalkacc	move.w	d2,PlayerSpeed(a5)
;DMspeedok

	;*** Gestione velocit e accelerazione verticale

		moveq	#0,d4			;d4=MaxSpeedY
		move.l	CPlayerY(a5),d0
		cmp.l	NewPlayerY(a5),d0
		beq.s	DMYok
		bgt.s	DMYgodown
		move.l	#$a0000,d4
		bra.s	DMYok
DMYgodown	move.l	#-$a0000,d4
DMYok
		move.l	PlayerSpeedY(a5),d2
		cmp.l	d4,d2			;Confronta SpeedY con MaxSpeedY per gestione accelerazione
		beq.s	DMspeedyok
		bgt.s	DMydec
		add.l	#$8000,d2
		bra.s	DMyok
DMydec		sub.l	#$8000,d2
DMyok		move.l	d2,PlayerSpeedY(a5)
DMspeedyok
		cmp.l	NewPlayerY(a5),d0
		beq.s	DMYok2
		bgt.s	DMYj1
		add.l	d2,d0
		cmp.l	NewPlayerY(a5),d0
		ble.s	DMYj2
		clr.l	PlayerSpeedY(a5)
		move.l	NewPlayerY(a5),d0
DMYj2		move.l	d0,CPlayerY(a5)
		bra.s	DMYok2
DMYj1		add.l	d2,d0
		cmp.l	NewPlayerY(a5),d0
		bge.s	DMYj3
		clr.l	PlayerSpeedY(a5)
		move.l	NewPlayerY(a5),d0
DMYj3		move.l	d0,CPlayerY(a5)

DMYok2



	;*** Gestione movimento per alzare/abbassare lo sguardo

		move.l	lookupdown(a5),d0
		lsl.l	#2,d0			;d0=LUDMaxSpeed
		move.l	LUDSpeed(a5),d2
		cmp.l	d0,d2			;Test se massima velocit <> velocit attuale
		beq.s	DMludspeedok
		bgt.s	DMluddec
		addq.l	#1,d2			;accelera
		cmp.l	d0,d2			;LUDSpeed<=LUDMaxSpeed ?
		ble.s	DMludacc		; Se si, salta
		move.l	d0,d2			;Altrimenti pone LUDSpeed=LUDMaxSpeed
		bra.s	DMludacc
DMluddec	subq.l	#1,d2			;decelera
		cmp.l	d0,d2			;LUDSpeed>=LUDMaxSpeed ?
		bge.s	DMludacc		; Se si, salta
		move.l	d0,d2			;Altrimenti pone LUDSpeed=LUDMaxSpeed
DMludacc	move.l	d2,LUDSpeed(a5)
DMludspeedok

		move.l	CLookHeightNum(a5),d0
		tst.l	d2
		bmi.s	DMlowerlook

DMraiselook	add.l	d2,d0
		cmp.w	#72,d0		;old=3
		bgt.s	DMnoralo1
		bra.s	DMracalc

DMnoralo1	moveq	#72,d0
		bra.s	DMracalc
DMnoralo2	moveq	#-72,d0
		bra.s	DMracalc

DMlowerlook	add.l	d2,d0
		cmp.w	#-72,d0		;old=3
		blt.s	DMnoralo2
DMracalc	move.l	d0,CLookHeightNum(a5)
		move.l	LookHeightRatio(a5),d1
		muls.l	d0,d1
		swap	d1
		ext.l	d1
		move.l	d1,CLookHeight(a5)
DMnoralo




	;*** Gestione accelerazione per la rotazione

		move.w	mousepos(a5),d2
		beq.s	DMnomouse
		clr.w	mousepos(a5)
		tst.w	ActiveControl(a5)
		beq.s	DMnomouse
		muls.w	MouseSensitivity(a5),d2
		lsr.l	#2,d2
		add.w	CPlayerHeading(a5),d2
		and.w	#2047,d2
		move.w	d2,CPlayerHeading(a5)
		bra.s	DMokmouse

DMnomouse	move.w	PlayerRotAccel(a5),d1
		move.w	PlayerRotSpeed(a5),d2
		move.w	RotMaxSpeed(a5),d0
		move.w	d0,d3
		beq.s	DMrotdra	;Salta se RotMaxSpeed=0
		eor.w	d2,d3		;Controlla se l'accelerazione di rotazione deve essere maggiore
		bpl.s	DMrotnodra
DMrotdra	addq.w	#1,d1		;Aumenta un po' l'accelerazione, in modo da diminuire l'inerzia
DMrotnodra	cmp.w	d0,d2		;Test se deve sommare o sottrarre l'accelerazione
		beq.s	DMrotok		; Salta se no deve fare nulla
		bgt.s	DMrotdec	; Salta se deve sottrarre
		add.w	d1,d2		;Somma accelerazione
		cmp.w	d0,d2		;PlayerRotSpeed<=RotMaxSpeed ?
		ble.s	DMrotacc	; Se si, salta
		move.w	d0,d2		; Altrimenti pone PlayerRotSpeed=RotMaxSpeed
		bra.s	DMrotacc
DMrotdec	sub.w	d1,d2		;Sottrae accelerazione
		cmp.w	d0,d2		;PlayerRotSpeed>=RotMaxSpeed ?
		bge.s	DMrotacc	; Se si, salta
		move.w	d0,d2		; Altrimenti pone PlayerRotSpeed=RotMaxSpeed
DMrotacc	move.w	d2,PlayerRotSpeed(a5)
DMrotok
		move.w	CPlayerHeading(a5),d2
		add.w	PlayerRotSpeed(a5),d2
		and.w	#2047,d2
		move.w	d2,CPlayerHeading(a5)
DMokmouse

;DMnomouse	move.w	PlayerRotSpeed(a5),d2
;		cmp.w	RotMaxSpeed(a5),d2
;		beq.s	DMrotok
;		bgt.s	DMrotdec
;		add.w	PlayerRotAccel(a5),d2
;		bra.s	DMrotacc
;DMrotdec	sub.w	PlayerRotAccel(a5),d2
;DMrotacc	move.w	d2,PlayerRotSpeed(a5)
;DMrotok
;		move.w	CPlayerHeading(a5),d2
;		add.w	PlayerRotSpeed(a5),d2
;		and.w	#2047,d2
;		move.w	d2,CPlayerHeading(a5)
;DMokmouse





	;*** Test se player morto

		tst.b	PlayerDeath(a5)		;Player morto ?
		beq.s	DMnodeath		; Se no, salta
		tst.w	PostDeathWait(a5)	;Test se inizializzare contatore
		bgt.s	DMnoinipdw
		move.w	#60,PostDeathWait(a5)
DMnoinipdw	clr.w	OscCont(a5)		;Resetta OscCont
		tst.w	PlayerFalling(a5)	;St cadendo ?
		bne.s	DMnodeath		;Se si, salta
		clr.w	PlayerSpeed(a5)
		clr.w	WalkMaxSpeed(a5)
		clr.w	PlayerRotSpeed(a5)
		clr.w	RotMaxSpeed(a5)
		move.w	PlayerEyesHeight(a5),d0
		subq.w	#2,d0			;Decrementa altezza degli occhi
		cmp.w	#12,d0			;Test se caduta player terminata
		bgt.s	DMnodthstop		; Se no, salta
		moveq	#12,d0
		subq.w	#1,PostDeathWait(a5)	;Attesa dopo la morte
		bne.s	DMnodthstop
		st	Escape(a5)		;Segnala uscita dal gioco
DMnodthstop	move.w	d0,PlayerEyesHeight(a5)
DMnodeath

	;*** Direzione dello sguardo del player

		lea	costable,a0
		lea	sintable,a1

		move.l	(a0,d2.w*4),CPlayerViewDirX(a5)
		move.l	(a1,d2.w*4),CPlayerViewDirZ(a5)

	;*** Legge dalla tabella sin/cos la direzione di movimento

		move.w	CPlayerHeading(a5),d2
		add.w	MovingDir(a5),d2
		add.w	AMovingDir(a5),d2	;Somma la direzione aggiuntiva
		and.w	#2047,d2
		move.l	(a0,d2.w*4),d0
		move.l	(a1,d2.w*4),d1
		move.l	d0,MoveDirX(a5)
		move.l	d1,MoveDirZ(a5)

	;*** Gestione direzione di movimento aggiuntiva,
	;*** usata nelle collisioni con gli oggetti

		move.w	AMovingDir(a5),d2	;C'e' la dir. aggiuntiva ?
		beq.s	DMnoaggdir		; Se no, salta
		bmi.s	DMaggminus		;Salta se e' negativa
		sub.w	#64,d2			;Riduce progressivamente la dir. aggiuntiva
		bge.s	DMaggdirj1
		clr.w	d2
		bra.s	DMaggdirj1
DMaggminus	add.w	#64,d2			;Riduce progressivamente la dir. aggiuntiva
		ble.s	DMaggdirj1
		clr.w	d2
DMaggdirj1	move.w	d2,AMovingDir(a5)
DMnoaggdir

	;*** Posizione precedente del player

		move.l	CPlayerX(a5),d2
		move.l	CPlayerZ(a5),d3

	;*** Calcola nuova posizione player

		move.w	PlayerSpeed(a5),d6
		ext.l	d6
		muls.l	d6,d0
		muls.l	d6,d1
		asr.l	#4,d0		;PlayerSpeed  moltiplicata per 16
		asr.l	#4,d1
		add.l	d2,d0		;d0=Nuova posizione X del player
		add.l	d3,d1		;d1=Nuova posizione Z del player

		move.l	d0,d2
		move.l	d1,d3
		move.l	Map(a5),a0
		and.l	#GRID_AND_L,d3
		lsr.l	#BLOCK_SIZE_B,d2
		add.l	d3,d3
		or.l	d2,d3
		swap	d3
		lea	(a0,d3.w*4),a0	;a0=Pun. nella mappa alla posizione attuale del player

	;*** Ctrl collisione muri

		move.l	Blocks(a5),a4

		move.l	CPlayerBlockPun(a5),a1	;a1=Pun. al blocco su cui si trova il player
		move.w	bl_FloorHeight(a1),d6
		move.w	bl_CeilHeight(a1),d7

		move.l	d0,d2
		move.l	d1,d3
		swap	d2
		swap	d3
		and.w	#BLOCK_SIZE-1,d2
		and.w	#BLOCK_SIZE-1,d3

		moveq	#0,d4
		cmp.w	#PLAYER_WIDTH,d2
		bge.s	DMCCj1
		moveq	#4,d4
		bra.s	DMCCj2
DMCCj1		cmp.w	#BLOCK_SIZE-PLAYER_WIDTH,d2
		blt.s	DMCCj2
		or.w	#1,d4
DMCCj2		cmp.w	#PLAYER_WIDTH,d3
		bge.s	DMCCj3
		or.w	#8,d4
		bra.s	DMCCj4
DMCCj3		cmp.w	#BLOCK_SIZE-PLAYER_WIDTH,d3
		blt.s	DMCCj4
		or.w	#2,d4
DMCCj4
		lea	CollTestTable(pc),a3
		moveq	#0,d5
		move.l	(a3,d4.w*4),a3
		jmp	(a3)		;Salta alla routine di ctrl collisioni con i muri
DMCCret

		and.w	#$f,d5
		lea	SetCoordTable(pc),a3
		move.l	(a3,d5.w*4),a3
		jmp	(a3)		;Salta alla routine che corregge le coordinate in base al ctrl di collisioni
DMSCret


;************************************

	;*** Move player

		move.l	d0,CPlayerX(a5)
		move.l	d1,CPlayerZ(a5)

		move.l	Map(a5),a0
		and.l	#GRID_AND_L,d1
		lsr.l	#BLOCK_SIZE_B,d0
		add.l	d1,d1
		or.l	d0,d1
		swap	d1
		lea	(a0,d1.w*4),a0
		move.l	a0,CPlayerMapPun(a5)
		move.w	(a0),d0
		cmp.w	CPlayerBlock(a5),d0
		beq.s	DMnochangeblock
		st	PlayerMoved(a5)
DMnochangeblock	move.w	d0,CPlayerBlock(a5)
		move.l	Blocks(a5),a0
		lsl.w	#2,d0
		lea	(a0,d0.w*8),a0		;a0=Pun. blocco su cui si trova il Player
		move.l	a0,CPlayerBlockPun(a5)

	;***** Test se il player st cadendo da un'altezza troppo elevata

		move.w	bl_FloorHeight(a1),d2	;Calcola il dislivello del pavimento
		sub.w	bl_FloorHeight(a0),d2
		bmi.s	DMnofall
		cmp.w	#PLAYER_MAX_RISE,d2
		blt.s	DMnofall
		move.w	#24,OscCont(a5)		;Resetta OscCont
		move.w	#1,PlayerFalling(a5)
		move.w	d2,FallingHeight(a5)
		bra	DMout
DMnofall

	;***** Gestione dei blocchi che danneggiano il player

		move.b	bl_Attributes(a0),d1
		and.b	#3,d1			;d1=Block type
		beq.s	DMnohurt		; Salta se zero
		tst.w	PlayerFalling(a5)	;Test se il player sta cadendo
		bne.s	DMnohurt
		subq.w	#1,HurtTimer(a5)	;Decrementa contatore
		bmi.s	DMinithurt
		bgt.s	DMhurtok
		move.w	#50,HurtTimer(a5)
		moveq	#2,d0
		subq.b	#1,d1			;Block type=1 ?
		beq.s	DMhj1
		moveq	#5,d0
		subq.b	#1,d1			;Block type=2 ?
		beq.s	DMhj1
		moveq	#10,d0
DMhj1		jsr	PlayerHit
		bra.s	DMhurtok
DMinithurt
		move.w	#50,HurtTimer(a5)
		bra.s	DMhurtok
DMnohurt
		clr.w	HurtTimer(a5)
DMhurtok


		tst.b	PlayerMoved(a5)
		beq	DMnomove
;		bne.s	DMmv1
;		tst.w	PlayerSpeed(a5)
;		beq.s	DMnomove
DMmv1
		tst.w	PlayerFalling(a5)
		bne	DMnomove

	;***** Controlla se il blocco su cui si trova il player
	;*****  comanda l'esecuzione di un effetto.

		clr.l	d2
		move.b	bl_Effect(a0),d2	;Codice lista effetti <> 0 ?
		beq.s	DMnoeffect		; Se=0, esce
		move.b	bl_Attributes(a0),d1	;Test se l'effetto  comandato da uno switch
		and.b	#$f0,d1
		bne.s	DMnoeffect		;Se si, esce
;		ACTIVE_ENEMY
		lea	BlockEffectListPun,a3
		move.l	(a3,d2.l*4),a3		;a3=Pun. alla lista di effetti da abilitare
DMtrigloop	move.w	(a3)+,d1		;d1=Trigger number
		beq.s	DMnoeffect		;Se Trigger number=0, esce
		move.w	(a3)+,d0		;Codice effetto
		lea	TriggerBlockListPun(a5),a2
		lea	(a2,d1.w*8),a2
		cmp.w	4(a2),d0		;Test se l'effetto di questo trigger number  gi attivo
		bne.s	DMtrigok		; Se no, tutto ok
		addq.l	#6,a3
		bra.s	DMtrigloop		; Se si, passa al prossimo
DMtrigok	lea	Effects(a5),a1		;a1=Pun. alla lista degli effetti attivi
		move.l	(a1)+,d7		;d7=numero effetti attivi
		dbra	d7,DMsearcheffect
		bra.s	DMeffectfound
DMsearcheffect	tst.w	(a1)			;Cerca la prima struttura libera
		beq.s	DMeffectfound		;Esce dal ciclo appena la trova
		lea	ef_SIZE(a1),a1
		dbra	d7,DMsearcheffect
DMeffectfound					;Inizializza struttura effetto
		move.w	d0,(a1)+		;ef_effect
		move.w	d1,(a1)+		;ef_trigger
		move.l	(a2),(a1)+		;ef_blocklist
		move.w	#0,(a1)+		;ef_status
		move.w	(a3)+,(a1)+		;ef_param1
		move.w	(a3)+,(a1)+		;ef_param2
	addq.l	#2,a3		;Salta key
		addq.l	#1,Effects(a5)		;Incrementa il numero di effetti attivi
		move.w	d0,4(a2)		;Segnala che l'effetto di questo trigger number e' gi attivo e non pu essere abilitato
		bra.s	DMtrigloop
DMnoeffect
DMnomove

		move.l	CPlayerBlockPun(a5),a0
		move.w	bl_FloorHeight(a0),d0
		add.w	PlayerEyesHeight(a5),d0
		move.w	d0,NewPlayerY(a5)

		tst.w	PlayerFalling(a5)
		beq.s	DMnotstf
		cmp.w	CPlayerY(a5),d0
		blt.s	DMnostopfall
		clr.w	PlayerFalling(a5)
		move.w	FallingHeight(a5),d0	;Altezza da cui sta cadendo
		cmp.w	#256,d0			;Maggiore di 256 ?
		ble.s	DMnostopfall		; Se no, salta
		lsr.w	#7,d0			;Altrimenti toglie 4 unita' di energia ogni 128 pixel
		lsl.w	#2,d0
		jsr	PlayerHit
DMnostopfall	moveq	#0,d0
		bra.s	DMnoosc
DMnotstf
		moveq	#0,d0
		move.w	PlayerSpeed(a5),d1
		bne.s	DMokosc
		move.w	d0,OscCont(a5)
		bra.s	DMnoosc
DMokosc		move.w	OscCont(a5),d2		;d2=contatore oscillazione
		lea	OscSpeedTrans(pc),a0
		add.w	(a0,d1.w*2),d2		;Somma a d2, (PlayerSpeed / 1.333333)
		and.w	#$3ff,d2
		move.w	d2,OscCont(a5)
		lsr.w	#4,d2
		lea	OscillationData(pc),a0
		move.b	(a0,d2.w),d0		;In base al contatore, preleva il campione attuale dalla forma d'onda
	tst.w	d1			;Speed>0 ?
	bpl.s	DMstsp			; Se si, salta
	cmp.b	#46,d2
	ble.s	DMstep
	clr.b	stepfl(a5)		;Segnala che pu emettere il suono del passo
	bra.s	DMnostep
DMstsp	cmp.b	#50,d2		;Old=24
	bge.s	DMstep
	clr.b	stepfl(a5)		;Segnala che pu emettere il suono del passo
	bra.s	DMnostep
DMstep	tst.b	stepfl(a5)
	bne.s	DMnostep
	move.l	GlobalSound5(a5),a0
	moveq	#0,d1
	jsr	PlaySoundFX
	st	stepfl(a5)		;Segnala che il suono del passo  stato gi emesso
	move.w	PlayerSpeed(a5),d1
DMnostep
		ext.w	d0
		lea	OscillationAmp+8(pc),a0
		tst.w	d1			;Speed<0 ?
		bpl.s	DMsppl
		neg.w	d1
DMsppl		and.w	#$fff8,d1
		add.w	d1,d1
		add.w	d0,d1
		move.b	(a0,d1.w),d0		;In base a PlayerSpeed, modifica l'ampiezza del campione attuale leggendo dalla tabella
		ext.w	d0
DMnoosc
		move.w	d0,PlayerYOsc(a5)

DMout
		moveq	#0,d0
		move.w	CPlayerHeading(a5),d0
		lsr.l	#1,d0
		lsl.l	#8,d0
		move.l	d0,CSkyRotation(a5)

		clr.w	PlayerMoved(a5)

		rts

;----------------------------------------------------------------------------
; Macro per il controllo di collisioni con blocchi adiacenti
; a0 contiene il pun. nella mappa al blocco su cui si trova il player
; d6 contiene l'altezza del pavimento del blocco su cui si trova il player
; d7 contiene l'altezza del soffitto del blocco su cui si trova il player
; d5  l'output. Ogni bit corrisponde ad una direzione
; \1  l'offset rispetto ad a0 del blocco da testare
; \2  il/i bit di d5 da settare nel caso in cui ci sia una collisione

TESTBLOCK	MACRO

		move.w	\1(a0),d4		;d4=block
		blt.s	TBstop\@		;If the block is a solid wall, don't move player
		lsl.w	#2,d4
		lea	(a4,d4.w*8),a3		;a3=Pun. al blocco
		move.w	bl_FloorHeight(a3),d4	;Calcola il dislivello del pavimento
		sub.w	d6,d4
		bmi.s	TBdisc\@		;Se il dislivello  in discesa, salta
		cmp.w	#PLAYER_MAX_RISE,d4	;Test se il dislivello  troppo grande
		bgt.s	TBstop\@		;Se  troppo grande, non va bene
		move.w	d7,d4
		cmp.w	bl_CeilHeight(a3),d4	;Verifica quale soffitto e' piu' basso
		blt.s	TBj1\@
		move.w	bl_CeilHeight(a3),d4
TBj1\@		sub.w	bl_FloorHeight(a3),d4	;Calcola dislivello tra il soffitto piu' basso e pavimento del nuovo blocco
		cmp.w	#PLAYER_HEIGHT+8,d4	;Test if the player fit
		ble.s	TBstop\@
		bra.s	TBout\@
TBdisc\@
		move.w	bl_CeilHeight(a3),d4	;Calcola distanza soffitto-pavimento nel blocco
		sub.w	d6,d4
		cmp.w	#PLAYER_HEIGHT+8,d4	;Test if the player fit
		bgt.s	TBout\@

TBstop\@	or.w	#\2,d5
TBout\@

		ENDM

;---------------------------------

CTT1
		TESTBLOCK 4,1
		bra	DMCCret

CTT2
		TESTBLOCK (MAP_SIZE<<2),2
		bra	DMCCret

CTT3
		TESTBLOCK 4,1
		TESTBLOCK (MAP_SIZE<<2),2
		tst.w	d5
		bne	DMCCret
		TESTBLOCK ((MAP_SIZE<<2)+4),$8000
		tst.w	d5
		bpl	DMCCret
		cmp.w	d2,d3
		blt.s	CTT3j1
		or.w	#1,d5		;x<=z
		bra	DMCCret
CTT3j1		or.w	#2,d5		;x>z
		bra	DMCCret

CTT4
		TESTBLOCK -4,4
		bra	DMCCret

CTT6
		TESTBLOCK -4,4
		TESTBLOCK (MAP_SIZE<<2),2
		tst.w	d5
		bne	DMCCret
		TESTBLOCK ((MAP_SIZE<<2)-4),$8000
		tst.w	d5
		bpl	DMCCret
		moveq	#63,d4
		sub.w	d3,d4		;d4=63-z
		cmp.w	d2,d4
		bgt.s	CTT6j1
		or.w	#4,d5		;x>=63-z
		bra	DMCCret
CTT6j1		or.w	#2,d5		;63-z>x
		bra	DMCCret

CTT8
		TESTBLOCK -(MAP_SIZE<<2),8
		bra	DMCCret

CTT9
		TESTBLOCK 4,1
		TESTBLOCK -(MAP_SIZE<<2),8
		tst.w	d5
		bne	DMCCret
		TESTBLOCK (-(MAP_SIZE<<2)+4),$8000
		tst.w	d5
		bpl	DMCCret
		moveq	#63,d4
		sub.w	d2,d4		;d4=63-x
		cmp.w	d4,d3
		bgt.s	CTT9j1
		or.w	#1,d5		;63-x>=z
		bra	DMCCret
CTT9j1		or.w	#8,d5		;z>63-x
		bra	DMCCret

CTT12
		TESTBLOCK -4,4
		TESTBLOCK -(MAP_SIZE<<2),8
		tst.w	d5
		bne	DMCCret				;Se i due test precedenti non hanno rilevato collisioni
		TESTBLOCK (-(MAP_SIZE<<2)-4),$8000	; effettua il test sul blocco in direzione obliqua
		tst.w	d5
		bpl	DMCCret
		cmp.w	d2,d3
		bgt.s	CTT12j1
		or.w	#4,d5		;x>=z
		bra	DMCCret
CTT12j1		or.w	#8,d5		;z>x
		bra	DMCCret


    IFEQ 1	;*** !!!PROTEZIONE!!!
Checksum1	dc.l	$87d82	;old=$873c6
    ENDIF	;*** !!!FINE PROTEZIONE!!!


CollTestTable	dc.l	DMCCret
		dc.l	CTT1
		dc.l	CTT2
		dc.l	CTT3
		dc.l	CTT4
		dc.l	0
		dc.l	CTT6
		dc.l	0
		dc.l	CTT8
		dc.l	CTT9
		dc.l	0
		dc.l	0
		dc.l	CTT12


;****************************************************************************
; Routines per settare a valori corretti la posizione del player
; in base al controllo di collisione con i muri.
; In pratica, ad esempio, se le nuove coordinate del player (d0,d1)
; sono troppo vicine ad un muro, vengono settate al valore piu' opportuno.

SCT1		and.l	#GRID_AND_L,d0
		add.l	#(BLOCK_SIZE-PLAYER_WIDTH)<<16,d0
		bra	DMSCret

SCT2		and.l	#GRID_AND_L,d1
		add.l	#(BLOCK_SIZE-PLAYER_WIDTH)<<16,d1
		bra	DMSCret

SCT3		and.l	#GRID_AND_L,d0
		and.l	#GRID_AND_L,d1
		add.l	#(BLOCK_SIZE-PLAYER_WIDTH)<<16,d0
		add.l	#(BLOCK_SIZE-PLAYER_WIDTH)<<16,d1
		bra	DMSCret

SCT4		and.l	#GRID_AND_L,d0
		add.l	#(PLAYER_WIDTH)<<16,d0
		bra	DMSCret

SCT6		and.l	#GRID_AND_L,d0
		and.l	#GRID_AND_L,d1
		add.l	#(PLAYER_WIDTH)<<16,d0
		add.l	#(BLOCK_SIZE-PLAYER_WIDTH)<<16,d1
		bra	DMSCret

SCT8		and.l	#GRID_AND_L,d1
		add.l	#(PLAYER_WIDTH)<<16,d1
		bra	DMSCret

SCT9		and.l	#GRID_AND_L,d0
		and.l	#GRID_AND_L,d1
		add.l	#(BLOCK_SIZE-PLAYER_WIDTH)<<16,d0
		add.l	#(PLAYER_WIDTH)<<16,d1
		bra	DMSCret

SCT12		and.l	#GRID_AND_L,d0
		and.l	#GRID_AND_L,d1
		add.l	#(PLAYER_WIDTH)<<16,d0
		add.l	#(PLAYER_WIDTH)<<16,d1
		bra	DMSCret

SetCoordTable	dc.l	DMSCret
		dc.l	SCT1
		dc.l	SCT2
		dc.l	SCT3
		dc.l	SCT4
		dc.l	0
		dc.l	SCT6
		dc.l	0
		dc.l	SCT8
		dc.l	SCT9
		dc.l	0
		dc.l	0
		dc.l	SCT12

;****************************************************************************
;* Controllo collisioni del player con gli oggetti
;* Mette a zero il flag Z se ci sono state collisioni

		xdef	CtrlCollPlayerObj
CtrlCollPlayerObj

		clr.w	d5
;		clr.w	AMovingDir(a5)

	;***** Ctrl collisione oggetti

		move.l	CPlayerX(a5),d6
		move.l	CPlayerZ(a5),d7

		move.l	d6,d2
		move.l	d7,d3
		move.l	Map(a5),a0
		and.l	#GRID_AND_L,d3
		lsr.l	#BLOCK_SIZE_B,d2
		add.l	d3,d3
		or.l	d2,d3
		swap	d3
		lea	(a0,d3.w*4),a1	;a1=Pun. nella mappa alla posizione attuale del player

		swap	d6
		swap	d7

		move.w	2(a1),d2			;Test blocco corrente
		ble.s	DMCOno0				; Se non ci sono obj, salta
		bsr	CtrlCollObj
DMCOno0		move.w	6(a1),d2			;Test destra
		ble.s	DMCOno1				; Se non ci sono obj, salta
		bsr	CtrlCollObj
DMCOno1		move.w	((MAP_SIZE<<2)+6)(a1),d2	;Test basso-destra
		ble.s	DMCOno2				; Se non ci sono obj, salta
		bsr	CtrlCollObj
DMCOno2		move.w	((MAP_SIZE<<2)+2)(a1),d2	;Test basso
		ble.s	DMCOno3				; Se non ci sono obj, salta
		bsr	CtrlCollObj
DMCOno3		move.w	((MAP_SIZE<<2)-2)(a1),d2	;Test basso-sinistra
		ble.s	DMCOno4				; Se non ci sono obj, salta
		bsr	CtrlCollObj
DMCOno4		move.w	-2(a1),d2			;Test sinistra
		ble.s	DMCOno5				; Se non ci sono obj, salta
		bsr	CtrlCollObj
DMCOno5		move.w	(-(MAP_SIZE<<2)-2)(a1),d2	;Test alto-sinistra
		ble.s	DMCOno6				; Se non ci sono obj, salta
		bsr	CtrlCollObj
DMCOno6		move.w	(-(MAP_SIZE<<2)+2)(a1),d2	;Test alto
		ble.s	DMCOno7				; Se non ci sono obj, salta
		bsr	CtrlCollObj
DMCOno7		move.w	(-(MAP_SIZE<<2)+6)(a1),d2	;Test alto-destra
		ble.s	DMCOno8				; Se non ci sono obj, salta
		bsr	CtrlCollObj
DMCOno8	
;		tst.w	AMovingDir(a5)
		tst.w	d5

		rts


;* Controllo collisioni con oggetti di un blocco
;* d2 contiene il codice del primo oggetto della lista degli oggetti sul blocco

CtrlCollObj
		lea	ObjectsPunList-4(a5),a2
		move.l	(a2,d2.w*4),a2		;a2=Pun. al primo oggetto sul blocco
CCOloop		move.w	obj_type(a2),d4
;		bmi.s	CCOnext			;Se si tratta dei resti di un nemico, salta
		cmp.w	#$0400,d4		;Si tratta di un colpo, di un'esplosione, di un nemico morto ?
		bge.s	CCOnext			; Se si, salta
		move.w	obj_x(a2),d2
		sub.w	d6,d2			;d2=obj_x - playerx
		move.w	obj_z(a2),d3
		sub.w	d7,d3			;d3=obj_z - playerz
		move.w	d2,d0			;Salva in d0
		move.w	d3,d1			;Salva in d1
		muls.w	d2,d2
		muls.w	d3,d3
		add.l	d3,d2			;d2=distanza ^ 2
		move.w	obj_width(a2),d3	;d3=obj_width
		beq.s	CCOnext			;Salta se obj_width=0
		mulu.w	d3,d3			;!!!OTTIMIZZARE!!! (vedi ToDo.txt)
		add.l	#(PLAYER_WIDTH*PLAYER_WIDTH)<<1,d3
		cmp.l	d3,d2
		blt.s	CCOcoll			;Salta se c'e' collisione
CCOnext		move.l	obj_blocknext(a2),a2
		tst.l	a2
		bne.s	CCOloop
		rts
CCOcoll
;		cmp.w	#$0401,d4		;Si tratta di un colpo nemico ?
;		beq.s	CCOnext			; Se si, salta
;		cmp.w	#$0500,d4		;Si tratta di un'esplosione ?
;		bge.s	CCOnext			; Se si, salta
		cmp.w	#$0300,d4		;Si tratta di un pick thing ?
		blt.s	CCOnopickth		; Se no, salta
		tst.b	d4			;E' stato gi raccolto ?
		bmi.s	CCOnext			; Se si, salta
		clr.l	d2
		move.w	obj_value(a2),d2
		jsr	CollectItem
		tst.w	d0			;Tutto ok ?
		bmi.s	CCOnext			; Se no, salta
		move.b	#-1,obj_subtype(a2)	;Segnala che l'oggetto  stato raccolto
		jsr	SprDelayPrintMessage
		move.l	obj_image(a2),a0
		move.l	o_sound1(a0),a0
		moveq	#0,d1
		jsr	PlaySoundFX
		bra.s	CCOnext
CCOnopickth	moveq	#1,d5			;Segnala che c'e' stata collisione
		move.l	MoveDirX(a5),d2
		lsl.l	#8,d2
		swap	d2
		move.l	MoveDirZ(a5),d3
		lsl.l	#8,d3
		swap	d3
		muls.w	d2,d1
		muls.w	d3,d0
		sub.l	d0,d1			;d1=prodotto vettoriale
		bpl.s	CCOgoleft
		move.w	#512,AMovingDir(a5)
		bra.s	CCOnext
CCOgoleft	move.w	#-512,AMovingDir(a5)
		bra.s	CCOnext


;****************************************************************************

ReadJoy:
; joystick - get current state of switches in variables
; uses d0,d1
		move.w	$dff00c,d0
		btst	#1,d0
		sne	joyright(a5)
		btst	#9,d0
		sne	joyleft(a5)
		move	d0,d1
		add	d0,d0
		eor	d1,d0
		btst	#1,d0
		sne	joydown(a5)
		btst	#9,d0
		sne	joyup(a5)
		move.b	$bfe001,d0	;Test fire button
		and.b	#%11000000,d0
		cmp.b	#%11000000,d0
		beq.s	RJnofire	; Salta se non premuto
		tst.w	joyfireP(a5)	;Test se fire precedentemente premuto
		bne.s	RJout
		addq.w	#1,joyfire(a5)
		move.b	#1,joyfireP(a5)
		rts
RJnofire
		clr.b	joyfireP(a5)

RJout
		rts

;****************************************************************************
; Inizializzazione della posizione del player
; Da richiamare all'inizio di ogni livello

		xdef	InitPlayerPos
		xdef	InitPlayerPos2
InitPlayerPos
		clr.w	PlayerRotSpeed(a5)
		clr.l	LUDSpeed(a5)

		move.w	#$3795,CPlayerX+2(a5)
		move.w	#$3795,CPlayerZ+2(a5)

		bsr	ResetMoveVars
		clr.w	HurtTimer(a5)
		st	PlayerMoved(a5)

		move.w	#PLAYER_EYES_HEIGHT,PlayerEyesHeight(a5)
		move.w	#-1,PostDeathWait(a5)


		IFEQ	DEBUG

    IFEQ 1	;*** !!!PROTEZIONE!!!
	;*** Controlla se la routine tra DSprotection e DSProtectionEnd
	;***  integra.
		xref	Protection2,DSprotection,DSprotectionEnd
		sub.l	a3,a3
		move.l	#$864,d1
		lea	Protection2-$287(a5),a0
		cmp.b	#1,$287(a0)		;Test se deve fare test
		blt.s	PPPno
		lea	DSprotection-$864,a0
		lea	DSprotectionEnd-$864,a1
PPPchecksumloop	add.w	(a0,d1.l),a3		;Loop di calcolo checksum
		addq.l	#2,a0
		cmp.l	a1,a0
		blt.s	PPPchecksumloop
		lea	CollTestTable(pc),a0
		cmp.l	-4(a0),a3		;Controlla checksum
;PROT.REMOVED	beq.s	PPPno			; Se valido, salta
;PROT.REMOVED	move.w	#-20000,PlayerEyesHeight(a5)
PPPno

    ENDIF	;*** !!!FINE PROTEZIONE!!!

		ENDC


InitPlayerPos2
		move.l	Map(a5),a0
		move.l	CPlayerX(a5),d0
		move.l	CPlayerZ(a5),d1
		and.l	#GRID_AND_L,d1
		lsr.l	#BLOCK_SIZE_B,d0
		add.l	d1,d1
		or.l	d0,d1
		swap	d1
		lea	(a0,d1.w*4),a0
		move.l	a0,CPlayerMapPun(a5)
		move.w	(a0),d0			;d0=codice blocco
		move.w	d0,CPlayerBlock(a5)

		move.l	Blocks(a5),a0
		lsl.w	#2,d0
		lea	(a0,d0.w*8),a0		;a0=Pun. blocco su cui si trova il Player
		move.w	bl_FloorHeight(a0),d0
		add.w	PlayerEyesHeight(a5),d0
		move.w	d0,NewPlayerY(a5)
		move.w	d0,CPlayerY(a5)

		clr.w	PlayerFalling(a5)
		clr.w	FallingHeight(a5)
		clr.l	PlayerSpeedY(a5)

		clr.w	joyfire(a5)
		clr.w	joyfireP(a5)
		clr.w	Fire(a5)

		rts


;****************************************************************************
;* Resetta variabili relative ai comandi di movimento

		xdef	ResetMoveVars
ResetMoveVars
		clr.w	joyup(a5)
		clr.w	joydown(a5)
		clr.w	joyleft(a5)
		clr.w	joyright(a5)
		clr.w	joyfire(a5)
		clr.w	joyfireP(a5)
		clr.w	sidemove(a5)
		clr.w	speedup(a5)
		clr.w	switchpressed(a5)
		clr.l	lookupdown(a5)

		clr.w	joyfire(a5)
		clr.w	joyfireP(a5)
		clr.w	Fire(a5)
		rts

;****************************************************************************
;*** Gestione pressione barra spaziatrice per azionare switch e porte

SwitchManagement

		move.l	CPlayerMapPun(a5),a0
		move.w	CPlayerHeading(a5),d0

	;*** Serie di test per verificare verso quale blocco
	;***  rivolto il player.
					;*** Test left
		cmp.w	#(1024-224),d0
		blt.s	SMj1
		cmp.w	#(1024+224),d0
		bgt.s	SMj2
		subq.w	#4,a0
		moveq	#16,d1
		moveq	#bl_Edge1,d2
		bra.s	SMtest
SMj1					;*** Test down
		cmp.w	#(512-224),d0
		blt.s	SMj4
		cmp.w	#(512+224),d0
		bgt	SMout
		add.w	#(MAP_SIZE<<2),a0
		move.w	#128,d1
		moveq	#bl_Edge4,d2
		bra.s	SMtest
SMj3					;*** Test right
		cmp.w	#(2048-224),d0
		blt	SMout
		addq.w	#4,a0
		moveq	#64,d1
		moveq	#bl_Edge3,d2
		bra.s	SMtest
SMj4		cmp.w	#(0+224),d0
		bgt	SMout
		addq.w	#4,a0
		moveq	#64,d1
		moveq	#bl_Edge3,d2
		bra.s	SMtest
SMj2					;*** Test up
		cmp.w	#(1536-224),d0
		blt	SMout
		cmp.w	#(1536+224),d0
		bgt.s	SMj3
		sub.w	#(MAP_SIZE<<2),a0
		moveq	#32,d1
		moveq	#bl_Edge2,d2


SMtest
		move.w	(a0),d0
		bgt.s	SMbpos
		neg.w	d0
SMbpos		move.l	Blocks(a5),a0
		lsl.w	#2,d0
		lea	(a0,d0.w*8),a0		;a0=Pun. blocco
		and.b	bl_Attributes(a0),d1	;Test se  attivo lo switch
		beq	SMout			;Se no, salta

	;*** Gestione cambiamento texture dello switch
		move.l	(a0,d2.l),a2		;a2=Pun. all'edge
		move.l	ed_NormTexture(a2),d0	;d0=Pun. normal texture
		beq.s	SMnoct1			; Salta se non c' normal texture
		move.l	d0,a1
		cmp.w	#1,tx_Animation(a1)	;  Texture animata ?
		bgt.s	SMnoct1			;   se si, salta
		move.l	tx_AnimCount(a1),d0	;  C'e' un link con un'altra texture?
		beq.s	SMnoct1			;   se no, salta
		move.l	d0,ed_NormTexture(a2)	;  Altrimenti, cambia texture
SMnoct1		move.l	ed_UpTexture(a2),a1	;a1=Pun. upper texture
		cmp.w	#1,tx_Animation(a1)	;  Texture animata ?
		bgt.s	SMnoct2			;   se si, salta
		move.l	tx_AnimCount(a1),d0	;  C'e' un link con un'altra texture?
		beq.s	SMnoct2			;   se no, salta
		move.l	d0,ed_UpTexture(a2)	;  Altrimenti, cambia texture
SMnoct2		move.l	ed_LowTexture(a2),a1	;a1=Pun. lower texture
		cmp.w	#1,tx_Animation(a1)	;  Texture animata ?
		bgt.s	SMnoct3			;   se si, salta
		move.l	tx_AnimCount(a1),d0	;  C'e' un link con un'altra texture?
		beq.s	SMnoct3			;   se no, salta
		move.l	d0,ed_LowTexture(a2)	;  Altrimenti, cambia texture
SMnoct3
		clr.l	d2
		move.b	bl_Effect(a0),d2	;Codice lista effetti <> 0 ?
		beq	SMnoeffect		; Se=0, esce
;		ACTIVE_ENEMY
		lea	BlockEffectListPun,a3
		move.l	(a3,d2.l*4),a3		;a3=Pun. alla lista di effetti da abilitare
SMtrigloop	move.w	(a3)+,d1		;d1=Trigger number
		beq.s	SMnoeffect		;Se Trigger number=0, esce
		move.w	(a3)+,d0		;Codice effetto
		lea	TriggerBlockListPun(a5),a2
		lea	(a2,d1.w*8),a2
		cmp.w	4(a2),d0		;Test se l'effetto di questo trigger number  gi attivo
		bne.s	SMtrigok		; Se no, tutto ok
		addq.l	#6,a3
		bra.s	SMtrigloop		; Se si, passa al prossimo
SMtrigok	lea	Effects(a5),a1		;a1=Pun. alla lista degli effetti attivi
		move.l	(a1)+,d7		;d7=numero effetti attivi
		dbra	d7,SMsearcheffect
		bra.s	SMeffectfound
SMsearcheffect	tst.w	(a1)			;Cerca la prima struttura libera
		beq.s	SMeffectfound		;Esce dal ciclo appena la trova
		lea	ef_SIZE(a1),a1
		dbra	d7,SMsearcheffect
SMeffectfound					;Inizializza struttura effetto
		move.w	d0,(a1)+		;ef_effect
		move.w	d1,(a1)+		;ef_trigger
		move.l	(a2),(a1)+		;ef_blocklist
		move.w	#0,(a1)+		;ef_status
		move.w	(a3)+,(a1)+		;ef_param1
		move.w	(a3)+,(a1)+		;ef_param2
		clr.w	d1
		move.b	(a3)+,d1		;d1=key
		beq.s	SMnokeyneeded		;Se=0, non  necessaria alcuna chiave
		lea	GreenKey(a5),a4
		tst.b	-1(a4,d1.w)		;Test se la chiave  posseduta
		bne.s	SMusekey		;Se si, salta
		clr.w	-14(a1)			;Disabilita effetto
		addq.w	#3,d1
		move.w	d1,d0
		jsr	SprDelayPrintMessage
		bra.s	SMout
SMusekey	lea	GreenKeyFL(a5),a4
		st.b	-1(a4,d1.w)		;Segnala che la chiave  stata usata
SMnokeyneeded	addq.l	#1,a3			;Salta byte non usato
		addq.l	#1,Effects(a5)		;Incrementa il numero di effetti attivi
		move.w	d0,4(a2)		;Segnala che l'effetto di questo trigger number e' gi attivo e non pu essere abilitato

		move.l	GlobalSound2(a5),a0
		moveq	#0,d1
		jsr	PlaySoundFX

		bra.s	SMtrigloop
SMnoeffect

			;***** Controlla se qualche chiave  stata usata,
			;***** nel qual caso la elimina.
		lea	GreenKeyFL(a5),a0
		lea	GreenKey(a5),a1
		moveq	#3,d1
SMtstkloop	tst.b	(a0)+		;Chiave usata ?
		beq.s	SMtstnok	; Se no, salta
		clr.b	(a1)		;Altrimenti la elimina
SMtstnok	addq.l	#1,a1
		dbra	d1,SMtstkloop


SMout
		rts

;****************************************************************************
;*** Tabelle usate dalla routine di simulazione della camminata
;*** (oscillazione verticale)

	;Tabella per la divisione di PlayerSpeed per 1.3333333
		dc.w	-48,-48
		dc.w	-47,-47,-47,-47,-47,-47,-47,-47,-46,-46,-46,-46,-46,-46,-46,-46
		dc.w	-45,-45,-45,-45,-45,-45,-45,-44,-44,-44,-44,-44,-44,-43,-43,-43
		dc.w	-43,-43,-42,-42,-42,-42,-42,-41,-41,-41,-41,-41,-40,-40,-40,-40
		dc.w	-39,-39,-39,-39,-38,-38,-38,-38,-37,-37,-37,-37,-36,-36,-36,-36
		dc.w	-36,-35,-34,-33,-33,-32,-31,-30,-30,-29,-28,-27,-27,-26,-25,-24
		dc.w	-24,-23,-22,-21,-21,-20,-19,-18,-18,-17,-16,-15,-15,-14,-13,-12
		dc.w	-12,-11,-10,-09,-09,-08,-07,-06,-06,-05,-04,-03,-03,-02,-01,-00
OscSpeedTrans	dc.w	00,00,01,02,03,03,04,05,06,06,07,08,09,09,10,11
		dc.w	12,12,13,14,15,15,16,17,18,18,19,20,21,21,22,23
		dc.w	24,24,25,26,27,27,28,29,30,30,31,32,33,33,34,35
		dc.w	36,36,36,36,37,37,37,37,38,38,38,38,39,39,39,39
		dc.w	40,40,40,40,41,41,41,41,41,42,42,42,42,42,43,43
		dc.w	43,43,43,44,44,44,44,44,44,45,45,45,45,45,45,45
		dc.w	46,46,46,46,46,46,46,46,47,47,47,47,47,47,47,47
		dc.w	48,48

;		dc.w	-60
;		dc.w	-60,-59,-58,-57,-57,-56,-55,-54,-54,-53,-52,-51,-51,-50,-49,-48
;		dc.w	-48,-47,-46,-45,-45,-44,-43,-42,-42,-41,-40,-39,-39,-38,-37,-36
;		dc.w	-36,-35,-34,-33,-33,-32,-31,-30,-30,-29,-28,-27,-27,-26,-25,-24
;		dc.w	-24,-23,-22,-21,-21,-20,-19,-18,-18,-17,-16,-15,-15,-14,-13,-12
;		dc.w	-12,-11,-10,-09,-09,-08,-07,-06,-06,-05,-04,-03,-03,-02,-01,-00
;OscSpeedTrans	dc.w	00,00,01,02,03,03,04,05,06,06,07,08,09,09,10,11
;		dc.w	12,12,13,14,15,15,16,17,18,18,19,20,21,21,22,23
;		dc.w	24,24,25,26,27,27,28,29,30,30,31,32,33,33,34,35
;		dc.w	36,36,37,38,39,39,40,41,42,42,43,44,45,45,46,47
;		dc.w	48,48,49,50,51,51,52,53,54,54,55,56,57,57,58,59
;		dc.w	60,60

	;Tabella della forma d'onda della camminata.
	;La forma d'onda e' indicata alla massima ampiezza e minima frequenza
OscillationData
		dc.b	0,0,1,1,2,2,3,3,4,4,5,5,6,6,6,7
		dc.b	7,7,7,6,6,6,5,5,4,4,3,3,2,2,1,1
		dc.b	00,00,-1,-1,-2,-2,-3,-3,-4,-4,-5,-5,-6,-6,-6,-7
		dc.b	-7,-7,-7,-6,-6,-6,-5,-5,-4,-4,-3,-3,-2,-2,-1,-1

	;Tabella per la variazione di ampiezza dell'oscillazione in
	;dipendenza di PlayerSpeed.
OscillationAmp
		dc.b	-1,-1,-1,-1,00,00,00,00,0,0,0,0,0,1,1,1
		dc.b	-2,-2,-2,-1,-1,00,00,00,0,0,0,0,1,1,2,2
		dc.b	-2,-2,-2,-1,-1,00,00,00,0,0,0,0,1,1,2,2
		dc.b	-3,-3,-2,-2,-2,-1,-1,00,0,0,1,1,2,2,2,3
		dc.b	-3,-3,-2,-2,-2,-1,-1,00,0,0,1,1,2,2,2,3
		dc.b	-4,-4,-3,-3,-2,-1,-1,00,0,0,1,1,2,3,3,4
		dc.b	-4,-4,-3,-3,-2,-1,-1,00,0,0,1,1,2,3,3,4
		dc.b	-5,-5,-4,-3,-3,-2,-1,-1,0,1,1,2,3,3,4,5
		dc.b	-5,-5,-4,-3,-3,-2,-1,-1,0,1,1,2,3,3,4,5
		dc.b	-6,-5,-4,-4,-3,-2,-2,-1,0,1,2,2,3,4,4,5
		dc.b	-6,-5,-4,-4,-3,-2,-2,-1,0,1,2,2,3,4,4,5
		dc.b	-7,-6,-5,-4,-4,-3,-2,-1,0,1,2,3,4,4,5,6
		dc.b	-7,-6,-5,-4,-4,-3,-2,-1,0,1,2,3,4,4,5,6
		dc.b	-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7
		dc.b	-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7
		dc.b	-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7

;		dc.b	-1,-1,-1,-1,00,00,00,00,0,0,0,0,0,1,1,1
;		dc.b	-2,-2,-2,-1,-1,00,00,00,0,0,0,0,1,1,2,2
;		dc.b	-3,-3,-2,-2,-2,-1,-1,00,0,0,1,1,2,2,2,3
;		dc.b	-4,-4,-3,-3,-2,-1,-1,00,0,0,1,1,2,3,3,4
;		dc.b	-5,-5,-4,-3,-3,-2,-1,-1,0,1,1,2,3,3,4,5
;		dc.b	-6,-5,-4,-4,-3,-2,-2,-1,0,1,2,2,3,4,4,5
;		dc.b	-7,-6,-5,-4,-4,-3,-2,-1,0,1,2,3,4,4,5,6
;		dc.b	-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7
;		dc.b	-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7
;		dc.b	-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7
;		dc.b	-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7
;		dc.b	-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7
;		dc.b	-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7

;****************************************************************************

; Tabella per le direzioni di movimento in base ai tasti premuti
; Si accede alla tabella tramite un codice in cui ogni bit corrisponde
; ad un tasto di direzione:
;	bit 0 : destra
;	bit 1 : sinistra
;	bit 2 : basso
;	bit 3 : alto
;
; La prima word corrisponde all'angolo da sommare alla direzione dello
; sguardo per ottenere la direzione di movimento.
; La seconda word indica il segno della velocit massima.

movingdirtable:
		dc.w	0,0
		dc.w	512,1		;1=destra
		dc.w	512,-1		;2=sinistra
		dc.w	0,0
		dc.w	0,-1		;4=basso
		dc.w	-256,-1		;5=basso-destra
		dc.w	256,-1		;6=basso-sinistra
		dc.w	0,0
		dc.w	0,1		;8=alto
		dc.w	256,1		;9=alto-destra
		dc.w	-256,1		;10=alto-sinistra
		dc.w	0,0,0,0,0
		dc.w	0,0,0,0,0

; Tabella per la modifica di PlayerSpeed in base alla direzione
; attuale e a quella precedente.
; Si accede alla matrice indirizzando le righe tramite la nuova
; direzione e le colonne tramite quella vecchia.
; Se il byte letto  positivo, bisogna azzerare PlayerSpeed;
; Se il byte letto  negativo, bisogna negare PlayerSpeed;
; Altrimenti non bisogna fare nulla.

updspeedtable:	;old	 1, 2, 3, 4, 5, 6, 7, 8, 9,10
		dc.b	00,00,00,01,-1,01,00,01,00,01	;1
		dc.b	00,00,00,01,01,00,00,01,01,-1	;2
		dc.b	00,00,00,00,00,00,00,00,00,00	;3
		dc.b	01,01,00,00,00,00,00,00,01,01	;4
		dc.b	-1,01,00,00,00,00,00,01,00,00	;5
		dc.b	01,00,00,00,00,00,00,01,00,00	;6
		dc.b	00,00,00,00,00,00,00,00,00,00	;7
		dc.b	01,01,00,00,01,01,00,00,00,00	;8
		dc.b	00,01,00,01,00,00,00,00,00,00	;9
		dc.b	01,-1,00,01,00,00,00,00,00,00	;10


;****************************************************************************

	section	__MERGED,BSS

		cnop	0,4

	xdef	ActiveControl,MouseSensitivity

ActiveControl	ds.w	1	;Tipo controllo attivo: 0=Keyboard; 1=Mouse

MouseSensitivity ds.w	1	;Sensibilita' mouse (0...8): .25, .5, .75, 1, 1.25, 1.5, 1.75, 2
				;Nel formato virgola fissa 14.2

		xdef	PlayerWalkSpeed,PlayerRunSpeed
		xdef	PlayerRotWalkSpeed,PlayerRotRunSpeed
		xdef	PlayerAccel,PlayerRotAccel

PlayerWalkSpeed		ds.w	1	;Velocit di camminata del player
PlayerRunSpeed		ds.w	1	;Velocit di corsa del player
PlayerRotWalkSpeed	ds.w	1	;Velocit di rotazione del player mentre cammina
PlayerRotRunSpeed	ds.w	1	;Velocit di rotazione del player mentre corre
PlayerAccel		ds.w	1	;Accelerazione camminata/corsa player
PlayerRotAccel		ds.w	1	;Accelerazione rotazione player


	xdef	mousepos

mousepos	ds.w	1	;Posizione mouse

		ds.w	1	;Usato per allineare


	xdef	joyup,joydown,joyleft,joyright
	xdef	joyfire,joyfireP
	xdef	sidemove,speedup,switchpressed
	xdef	sideleft,sideright
	xdef	lookupdown

joyup		ds.w	1
joydown		ds.w	1
joyleft		ds.w	1
joyright	ds.w	1
joyfire		ds.w	1	;Contatore numero pressioni tasto

joyfireP	ds.w	1	;TRUE se il tasto  premuto

sidemove	ds.w	1
speedup		ds.w	1
switchpressed	ds.w	1
sideleft	ds.b	1
sideright	ds.b	1

lookupdown	ds.l	1	;Se=1, sguardo in alto; se=-1, sguardo in basso

		cnop	0,4

MovingDir	ds.w	1	;Direzione del movimento
AMovingDir	ds.w	1	;Direzione del movimento aggiunta

sidedir		ds.w	1	;Direzione movimento obliqua
		ds.w	1	;Usato per allineare

MoveDirX	ds.l	1
MoveDirZ	ds.l	1

WalkMaxSpeed	ds.w	1
RotMaxSpeed	ds.w	1
PlayerRotSpeed	ds.w	1
olddir		ds.b	1	;Vecchia direzione:
				;	FALSE = avanti/dietro
				;	TRUE  = destra/sinistra

stepfl		ds.b	1

FallingHeight	ds.w	1	;Altezza da cui sta cadendo il player
PlayerFalling	ds.w	1	;Se<>0, il player st cadendo
OscCont		ds.w	1

PlayerEyesHeight ds.w	1	;Altezza degli occhi del player relativa a PlayerY

PostDeathWait	ds.w	1	;Contatore di ritardo per attesa dopo la morte del player

NewPlayerY	ds.l	1	;Y verso cui si dirige il player
PlayerSpeedY	ds.l	1

HurtTimer	ds.w	1	;Contatore al 50esimo


		xdef	LookHeightNum,LookHeightRatio
		xdef	CLookHeightNum
		xdef	CLookHeight

LookHeightNum	ds.l	1
LookHeightRatio	ds.l	1
CLookHeightNum	ds.l	1
CLookHeight	ds.l	1

LUDSpeed	ds.l	1

		cnop	0,4

