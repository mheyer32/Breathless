;****************************************************************************
;*
;*	Map.asm
;*
;*		Gestione dell'automapping e visualizzazione
;*		della mappa
;*
;*
;****************************************************************************

		include 'System'
		include 'TMap.i'

;****************************************************************************

		xref	gfxbase,intuitionbase,vilintuisupbase
		xref	PlayerX,PlayerY,PlayerZ,PlayerHeading
		xref	PlayerViewDirX,PlayerViewDirZ
		xref	PlayerMapPun
		xref	Map,Blocks,automap
		xref	screen_bitmap1,screen_bitmap2,screen_bitmap3,screen_viewport
		xref	CurrentBitmap,CurrBuffer
		xref	showmap
		xref	myDBufInfo
		xref	pixel_type,VBTimer2
		xref	Palette
		xref	GlobalSound0,GlobalSound1,GlobalSound2,GlobalSound3
		xref	GlobalSound4,GlobalSound5,GlobalSound6,GlobalSound7
		xref	GlobalSound8,GlobalSound9,GlobalSound10

		xref	TurnOnSprites,TurnOffSprites
		xref	ChangePixelHeight,ClearCurrentBitmap
		xref	KeyboardInput
		xref	LoadPalette
		xref	PlaySoundFX

;****************************************************************************
;*** Gestione automapping
;*** Traccia 3 raggi affiancati nella mappa, finche' non incontra
;*** un solid wall, oppure una porta.
;*** Per ogni blocco toccato dal raggio, mette a 1 il bit corrispondente
;*** nell'array per l'automapping.

		xdef	AutoMapping
AutoMapping
		move.l	Map(a5),a0
		lea	automap,a1
		move.l	Blocks(a5),a2

		move.l	PlayerMapPun(a5),d0
		sub.l	a0,d0
		lsr.l	#2,d0			;d0=offset in mappa

		move.l	d0,a6
		moveq	#-1,d2
		bsr	TraceRay

		move.l	a6,d0
		moveq	#0,d2
		bsr	TraceRay

		move.l	a6,d0
		moveq	#1,d2
		bsr	TraceRay

		rts

;*** Traccia un raggio.
;*** d2.l contiene lo scostamento in blocchi dalla posizione di
;*** partenza.

TraceRay
		moveq	#1,d4
		move.l	PlayerViewDirX(a5),d6
		asr.l	#8,d6			;d6=ax
		bge.s	TPnoabsx
		neg.w	d6
		neg.w	d4			;d4=sx
TPnoabsx
		move.w	#128,d5
		move.l	PlayerViewDirZ(a5),d7
		asr.l	#8,d7			;d7=ay
		bge.s	TPnoabsy
		neg.w	d7
		neg.w	d5			;d5=sy
TPnoabsy
		clr.l	d1

		cmp.w	d6,d7
		bgt.w	TPydominant		;if(ax > ay)

;***** X dominant part

TPxdominant
		lsl.l	#7,d2
		add.l	d2,d0		;Sposta punto di partenza

		move.w	d6,d3
		lsr.w	#1,d3		;D = ax>>1	/* 'D' is digital error */
		bra.s	TPxpixel

		cnop	0,8

TPxloop		sub.w	d7,d3		;D -= ay
		bgt.s	TPxnoe		;if(D < 0)
		add.w	d6,d3		;    D += ax
		add.w	d5,d0		;    offset += sy
TPxnoe		add.w	d4,d0		;offset += sx

TPxpixel	move.w	d0,d2
		lsr.w	#3,d2
		bset	d0,(a1,d2.w)

		move.w	(a0,d0.w*4),d2	;Legge codice blocco
		ble.s	TPout
		cmp.w	d1,d2		;Cambiato blocco ?
		beq.s	TPxloop		; Se no, salta
		move.w	d2,d1
		lsl.w	#2,d2
		lea	(a2,d2.w*8),a3	;a3=Pun. blocco
		move.w	(a3)+,d2
		cmp.w	(a3)+,d2	;Confronta altezza soffitto e pavimento
		bne.s	TPxloop		;Se diverse, salta
TPout		rts



;***** Y dominant part

TPydominant
		add.l	d2,d0		;Sposta punto di partenza

		move.w	d7,d3
		lsr.w	#1,d3		;D = ay>>1	/* 'D' is digital error */
		bra.s	TPyreadpixel

		cnop	0,8

TPyloop		sub.w	d6,d3		;D -= ax
		bgt.s	TPynoe		;if(D < 0)
		add.w	d7,d3		;    D += ay
		add.w	d4,d0		;    offset += sx
TPynoe		add.w	d5,d0		;offset += sy

TPyreadpixel	move.w	d0,d2
		lsr.w	#3,d2
		bset	d0,(a1,d2.w)

		move.w	(a0,d0.w*4),d2	;Legge codice blocco
		ble.s	TPout
		cmp.w	d1,d2		;Cambiato blocco ?
		beq.s	TPyloop		; Se no, salta
		move.w	d2,d1
		lsl.w	#2,d2
		lea	(a2,d2.w*8),a3	;a3=Pun. blocco
		move.w	(a3)+,d2
		cmp.w	(a3)+,d2	;Confronta altezza soffitto e pavimento
		bne.s	TPyloop		;Se diverse, salta
		rts

;****************************************************************************
;*** Mostra a video la mappa

		xdef	MapMode
MapMode

		move.l	GlobalSound2(a5),a0
		moveq	#0,d1
		jsr	PlaySoundFX

		bsr	TurnOffSprites

	;*** Cancella schermo

		move.l	CurrentBitmap(a5),a3
		moveq	#0,d0
		move.l	d0,d1
		move.l	d0,d2
		move.l	d0,d3
		moveq	#7,d6		;d6=contatore bitplanes
MMclearloop0	move.l	(a3)+,a0
		move.w	#499,d7
MMclearloop1	move.l	d0,(a0)+
		move.l	d1,(a0)+
		move.l	d2,(a0)+
		move.l	d3,(a0)+
		dbra	d7,MMclearloop1
		dbra	d6,MMclearloop0

		lea	Palette(a5),a0
		bsr	LoadPalette


	;*** Mostra schermo mappa

		GFXBASE
		CALLSYS	WaitTOF
		CALLSYS	WaitTOF

		move.l	screen_viewport(a5),a0
		move.l	CurrBuffer(a5),d0
		subq.w	#4,d0
		bge.s	MMnm
		moveq	#8,d0
MMnm		lea	screen_bitmap1(a5),a1
		move.l	(a1,d0.l),a1
		move.l	myDBufInfo(a5),a2
		GFXBASE
		CALLSYS	ChangeVPBitMap

		move.l	pixel_type(a5),storepixeltype(a5)
		move.l	#1,pixel_type(a5)
		bsr	ChangePixelHeight


	;*** Analizza e migliora lo stato dell'automapping
;
;		lea	automap,a0
;		move.l	Map(a5),a1
;		move.l	Blocks(a5),a3
;		moveq	#127,d7		;d7=cont. righe
;MNfixloop0	moveq	#15,d6		;d6=cont. colonne
;MNfixloop1	moveq	#7,d5		;d5=cont. bit
;		move.b	(a0)+,d4
;MNfixloop2	lsl.b	#1,d4
;		
;
;		dbra	d5,MSfixloop2
;		dbra	d6,MSfixloop1
;		dbra	d7,MSfixloop0



		lea	automap,a0
		moveq	#127,d7		;d6=y
MNfixloopy	moveq	#127,d6		;d6=x
MNfixloopx	move.w	d6,d0
		move.w	d7,d1
		bsr	CheckBlock
		bne.s	MNfixnextx
		moveq	#0,d5		;d5=contatore
		move.w	d6,d0		;Check (x-1,y)
		move.w	d7,d1
		subq.w	#1,d0
		bsr	CheckBlock
		add.w	d0,d5
		move.w	d6,d0		;Check (x+1,y)
		move.w	d7,d1
		addq.w	#1,d0
		bsr	CheckBlock
		add.w	d0,d5
		cmp.w	#2,d5
		beq.s	MNfixset
		moveq	#0,d5
		move.w	d6,d0		;Check (x,y-1)
		move.w	d7,d1
		subq.w	#1,d1
		bsr	CheckBlock
		add.w	d0,d5
		move.w	d6,d0		;Check (x,y+1)
		move.w	d7,d1
		addq.w	#1,d1
		bsr	CheckBlock
		add.w	d0,d5
		cmp.w	#2,d5
		bne.s	MNfixnextx
MNfixset	move.w	d6,d0
		move.w	d7,d1
		bsr	SetBlock
MNfixnextx	dbra	d6,MNfixloopx
		dbra	d7,MNfixloopy





	;*** Traccia mappa (80x50 blocchi)

		move.l	Map(a5),a6
		move.l	Blocks(a5),a3

			;*** Calcola offset in mappa iniziale
		clr.l	d0
		moveq	#39,d1		;d1=playerx in mappa a video
		move.w	PlayerX(a5),d0
		lsr.w	#BLOCK_SIZE_B,d0
		sub.w	#39,d0
		bpl.s	MMprexpl
		add.w	d0,d1
		clr.l	d0
		bra.s	MMprexok
MMprexpl	cmp.w	#48,d0
		ble.s	MMprexok
		sub.w	#48,d0
		add.w	d0,d1
		moveq	#48,d0
MMprexok
		clr.l	d4
		moveq	#24,d2		;d2=playery in mappa a video
		move.w	PlayerZ(a5),d4
		lsr.w	#BLOCK_SIZE_B,d4
		sub.w	#24,d4
		bpl.s	MMprezpl
		add.w	d4,d2
		clr.l	d4
		bra.s	MMprezok
MMprezpl	cmp.w	#78,d4
		ble.s	MMprezok
		sub.w	#78,d4
		add.w	d4,d2
		moveq	#78,d4
MMprezok
		lsl.l	#7,d4
		add.l	d0,d4		;d4=offset in mappa

		move.w	d1,playermapx
		move.w	d2,playermapy

MAPCOLORL1	EQU	2		;Colore linee invalicabili
MAPCOLORL2	EQU	16		;Colore linee valicabili
MAPCOLORL3	EQU	195		;Colore linee con differenza di altezza nel soffitto

		moveq	#0,d7		;d7=flag (0=primo nibble; 1=secondo nibble)

		moveq	#49,d6		;d6=Contatore righe
		clr.l	d5		;d5=offset nello schermo
MMdrawloopy	swap	d6
		move.w	#39,d6		;d6=Contatore colonne
		clr.w	mapulcolor(a5)
MMdrawloopx	move.w	mapulcolor(a5),mapulcolorold(a5)
		clr.w	mapllcolor(a5)
		clr.w	mapulcolor(a5)
		clr.l	d1		;d1=colore blocco
	lea	automap,a0
	move.w	d4,d0
	lsr.w	#3,d0
	btst	d4,(a0,d0.w)
	beq	MMdpout
		move.w	(a6,d4.w*4),d0	;Legge codice prossimo blocco
		ble.s	MMnodb1
		move.w	#243,d1
		bsr	DrawBlock
MMnodb1		move.w	d0,d2
		lsl.w	#5,d2
		lea	(a3,d2.w),a1		;a1=pun. blocco
		cmp.w	#128,d4
		bge.s	MMnofirstrow1
		clr.w	d2
		bra.s	MMfirstrow1
MMnofirstrow1	move.w	(-(MAP_SIZE<<2).w,a6,d4.w*4),d2
MMfirstrow1	move.w	#MAPCOLORL1,d1
		cmp.w	d2,d0
		beq.s	MMnodupl1
		tst.w	d0
		bgt.s	MMnonega1
		tst.w	d2
		ble.s	MMnodupl1
		bra.s	MMdupl1
MMnonega1	tst.w	d2
		ble.s	MMdupl1
		lsl.w	#5,d2
		lea	(a3,d2.w),a2		;a2=pun. blocco
		move.w	#MAPCOLORL2,d1
		move.w	(a2)+,d2
		sub.w	bl_FloorHeight(a1),d2
		beq.s	MMunodiffh1
		bpl.s	MMudiffhpl1
		neg.w	d2
MMudiffhpl1	cmp.w	#PLAYER_MAX_RISE,d2
		ble.s	MMdupl1
		move.w	#MAPCOLORL1,d1
		bra.s	MMdupl1
MMunodiffh1	move.w	#MAPCOLORL3,d1
		move.w	(a2)+,d2
		cmp.w	bl_CeilHeight(a1),d2
		bne.s	MMdupl1
		move.w	#MAPCOLORL2,d1
		move.w	(a2)+,d2
		cmp.w	bl_FloorTexture(a1),d2
		bne.s	MMdupl1
		move.w	(a2)+,d2
		move.w	#MAPCOLORL3,d1
		cmp.w	bl_CeilTexture(a1),d2
		beq.s	MMnodupl1
MMdupl1		bsr	DrawUpLine
MMnodupl1	move.w	d4,d1
		and.w	#$7f,d1
		bne.s	MMnofirstcol1
		clr.w	d2
		bra.s	MMfirstcol1
MMnofirstcol1	move.w	-4(a6,d4.w*4),d2
MMfirstcol1	move.w	#MAPCOLORL1,d1
		cmp.w	d2,d0
		beq.s	MMnodll1
		tst.w	d0
		bgt.s	MMnonegb1
		tst.w	d2
		ble.s	MMnodll1
		bra.s	MMdll1
MMnonegb1	tst.w	d2
		ble.s	MMdll1
		lsl.w	#5,d2
		lea	(a3,d2.w),a2		;a2=pun. blocco
		move.w	#MAPCOLORL2,d1
		move.w	(a2)+,d2
		sub.w	bl_FloorHeight(a1),d2
		beq.s	MMlnodiffh1
		bpl.s	MMldiffhpl1
		neg.w	d2
MMldiffhpl1	cmp.w	#PLAYER_MAX_RISE,d2
		ble.s	MMdll1
		move.w	#MAPCOLORL1,d1
		bra.s	MMdll1
MMlnodiffh1	move.w	#MAPCOLORL3,d1
		move.w	(a2)+,d2
		cmp.w	bl_CeilHeight(a1),d2
		bne.s	MMdll1
		move.w	#MAPCOLORL2,d1
		move.w	(a2)+,d2
		cmp.w	bl_FloorTexture(a1),d2
		bne.s	MMdll1
		move.w	#MAPCOLORL3,d1
		move.w	(a2)+,d2
		cmp.w	bl_CeilTexture(a1),d2
		beq.s	MMnodll1
MMdll1		bsr	DrawLeftLine
MMnodll1
		move.w	mapllcolor(a5),d0
		beq.s	MMdpj1
		move.w	mapulcolor(a5),d2
		beq.s	MMdpout
		cmp.w	d0,d2
		beq.s	MMdpout
		cmp.w	#MAPCOLORL1,d2
		bne.s	MMdpout
		move.w	#MAPCOLORL1,d1
		bsr	DrawPoint
		bra.s	MMdpout
MMdpj1		move.w	mapulcolor(a5),d2
		bne.s	MMdpout
		move.w	mapulcolorold(a5),d1
		beq.s	MMdpout
		bsr	DrawPoint
MMdpout
		addq.w	#1,d4		;Muove offset in mappa
		eor.w	#1,d7
		bne	MMdrawloopx
		addq.l	#1,d5
		dbra	d6,MMdrawloopx
		add.l	#120,d5
		add.w	#48,d4		;Muove offset in mappa
		swap	d6
		dbra	d6,MMdrawloopy


	;*** Attende pressione tasto Tab

MMtomm		bsr	KeyboardInput

		GFXBASE
		CALLSYS	WaitTOF

	;***** Traccia posizione player

		move.w	#41,d1		;colore
		move.l	VBTimer2(a5),d0
		and.w	#8,d0
		beq.s	MMccol
		move.w	#243,d1		;colore
MMccol
		clr.l	d2
		move.w	playermapy(pc),d5	;y
		move.w	playermapx(pc),d2	;x
		mulu.w	#160,d5
		lsr.w	#1,d2
		bcc.s	MMdrawplj1
		add.l	d2,d5
		moveq	#0,d0
		bsr	DrawPlayerPos
		bra.s	MMdrawplout
MMdrawplj1	add.l	d2,d5
		moveq	#4,d0
		bsr	DrawPlayerPos
MMdrawplout

		tst.b	showmap(a5)
		bne.s	MMtomm

		bsr	ClearCurrentBitmap
		move.l	storepixeltype(a5),pixel_type(a5)
		bsr	ChangePixelHeight

		bsr	TurnOnSprites

		rts

;---------------------

DrawBlock	tst.w	d7
		bne.s	DrawBlock2
DrawBlock1	moveq	#-16,d2
		bra.s	Draw
DrawBlock2	moveq	#15,d2
		bra.s	Draw

DrawLeftLine	move.w	d1,mapllcolor(a5)
		tst.w	d7
		bne.s	DrawLeftLine2
DrawLeftLine1	moveq	#-128,d2
		bra.s	Draw
DrawLeftLine2	moveq	#8,d2
		bra.s	Draw

Draw		move.l	CurrentBitmap(a5),a4
		moveq	#7,d3
DB1loop		move.l	(a4)+,a0
		lea	(a0,d5.w),a0
		lsr.b	#1,d1
		bcc.s	DB1clr
		or.b	d2,(a0)
		or.b	d2,40(a0)
		or.b	d2,80(a0)
		or.b	d2,120(a0)
		bra.s	DB1n
DB1clr		not.b	d2
		and.b	d2,(a0)
		and.b	d2,40(a0)
		and.b	d2,80(a0)
		and.b	d2,120(a0)
		not.b	d2
DB1n		dbra	d3,DB1loop

		rts

DrawUpLine	move.w	d1,mapulcolor(a5)
		tst.w	d7
		bne.s	DrawUpLine2
DrawUpLine1	moveq	#-16,d2
		bra.s	DrawUL
DrawUpLine2	moveq	#15,d2
		bra.s	DrawUL

DrawUL		move.l	CurrentBitmap(a5),a4
		moveq	#7,d3
DULloop		move.l	(a4)+,a0
		lea	(a0,d5.w),a0
		lsr.b	#1,d1
		bcc.s	DULclr
		or.b	d2,(a0)
		bra.s	DULn
DULclr		not.b	d2
		and.b	d2,(a0)
		not.b	d2
DULn		dbra	d3,DULloop

		rts


DrawPoint	tst.w	d7
		bne.s	DrawPoint2
DrawPoint1	moveq	#-128,d2
		bra.s	DrawP
DrawPoint2	moveq	#8,d2
		bra.s	DrawP

DrawP		move.l	CurrentBitmap(a5),a4
		moveq	#7,d3
DP1loop		move.l	(a4)+,a0
		lea	(a0,d5.w),a0
		lsr.b	#1,d1
		bcc.s	DP1clr
		or.b	d2,(a0)
		bra.s	DP1n
DP1clr		not.b	d2
		and.b	d2,(a0)
		not.b	d2
DP1n		dbra	d3,DP1loop

		rts



DrawPlayerPos	move.w	PlayerHeading(a5),d2
		add.w	#128,d2
		and.w	#2047,d2
		lsr.w	#8,d2
		lea	PlayerMapPics(pc,d2.w*4),a0
		move.b	(a0)+,d2
		move.b	(a0)+,d3
		move.b	(a0)+,d4
		lsl.b	d0,d2
		lsl.b	d0,d3
		lsl.b	d0,d4
		move.l	CurrentBitmap(a5),a4
		moveq	#7,d6
DPPloop		move.l	(a4)+,a0
		lea	(a0,d5.w),a0
		lsr.b	#1,d1
		bcc.s	DPPclr
		or.b	d2,40(a0)
		or.b	d3,80(a0)
		or.b	d4,120(a0)
		bra.s	DPPn
DPPclr		not.b	d2
		not.b	d3
		not.b	d4
		and.b	d2,40(a0)
		and.b	d3,80(a0)
		and.b	d4,120(a0)
		not.b	d2
		not.b	d3
		not.b	d4
DPPn		dbra	d6,DPPloop

		rts

playermapx	dc.w	0
playermapy	dc.w	0

PlayerMapPics	dc.b	%100,%111,%100,0
		dc.b	%110,%110,%001,0
		dc.b	%111,%010,%010,0
		dc.b	%011,%011,%100,0
		dc.b	%001,%111,%001,0
		dc.b	%100,%011,%011,0
		dc.b	%010,%010,%111,0
		dc.b	%001,%110,%110,0

;----------------------------------------------------

CheckBlock
		cmp.w	#127,d0
		bge.s	CBnoset
		cmp.w	#127,d1
		bge.s	CBnoset
		move.w	d0,d2
		blt.s	CBnoset
		asl.w	#4,d1
		blt.s	CBnoset
		lsr.w	#3,d0
		add.w	d0,d1
		and.w	#7,d2
		btst	d2,(a0,d1.w)
		beq.s	CBnoset
		moveq	#1,d0
		rts
CBnoset		moveq	#0,d0
		rts


SetBlock
		move.w	d0,d2
		lsl.w	#4,d1
		lsr.w	#3,d0
		add.w	d0,d1
		and.w	#7,d2
		bset	d2,(a0,d1.w)
		rts


;****************************************************************************
;* Azzera map automapping

		xdef	InitAutomap

InitAutomap
		lea	automap,a0
		move.w	#((MAP_SIZE*MAP_SIZE)>>5)-1,d7
IAloop		clr.l	(a0)+
		dbra	d7,IAloop

		rts

;****************************************************************************

	section	__MERGED,BSS

		cnop	0,4

storepixeltype	ds.l	1

mapllcolor	ds.w	1	;Usato nel tracciamento mappa
mapulcolor	ds.w	1	;Usato nel tracciamento mappa
mapulcolorold	ds.w	1	;Usato nel tracciamento mappa

		ds.w	1	;Non usato

		cnop	0,4
