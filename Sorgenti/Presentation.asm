;****************************************************************************
;*
;*	Presentation.asm
;*
;*		Gestione Intro, schermate introduttive e di caricamento
;*
;*
;****************************************************************************

		include 'System'
		include 'TMap.i'

		xref	gfxbase,intuitionbase
		xref	screen_rport
		xref	screen_bitmap1,screen_bitmap2,screen_bitmap3
		xref	planes_bitmap1,planes_bitmap2,planes_bitmap3
		xref	screen_viewport
		xref	PaletteRGB32,Palette
		xref	CurrentBitmap,CurrBuffer
		xref	myDBufInfo
		xref	pixel_type,VBTimer2
		xref	GfxPun
		xref	LevelCodeASC,FirstMatchLevel
		xref	WindowSize,PixelSize
		xref	pixel_type,oldpixeltype,SelectedSize
		xref	MusicState
		xref	P61_Master,P61_Play,P61_channels,P61_ofilter
		xref	terminal
		xref	PunGame,PunLevel,Retries
		xref	CurrentGame,CurrentLevel
		xref	ResetMousePos
		xref	myDBufInfo,DBufSafePort,DBufDispPort
		xref	Escape,pause
		xref	c2pBuffer1,c2pBuffer2
		xref	SndPun
		xref	Protection

		xref	ChangePixelHeight,ClearCurrentBitmap
		xref	LoadPalette,ResetPalette
		xref	LoadPic,LoadMod
		xref	ReadKey
		xref	SprPrint
		xref	InitTerminal,Terminal
		xref	P61_Init,P61_End,P61_SetPosition
		xref	TurnOffMousePointer
		xref	InitKeyQueue
		xref	TestChangeScreen
		xref	LevelCodeOut
		xref	TurnOffSprites,TurnOnSprites

;****************************************************************************
;* Routine di presentazione

		xdef	Presentation

Presentation
		move.w	#-1,ActualScr(a5)

	;*** Carica modulo dei titoli
		move.l	PresModName(a5),d4
		move.l	SndPun(a5),a4
		jsr	LoadMod
		beq.s	Plmodok			;Salta se ha caricato il mod
		clr.b	MusicState(a5)
		clr.l	PresModPun(a5)
		bra.s	Plmodnook
Plmodok		move.l	a0,PresModPun(a5)

		move.b	#2,P61_ofilter
		move.w	#4-1,P61_channels
;		move.w	#$e000,$dff09a
;		move.l	PresModPun(a5),a0
		lea	snd_SIZE(a0),a0
		lea	$dff000,a6
		sub.l	a1,a1
		sub.l	a2,a2
		jsr	P61_Init
		GETDBASE
		move.w	#64,P61_Master
		st	MusicState(a5)
		st	P61_Play+1
Plmodnook
		tst.b	PresFirstTime(a5)	;E' la prima volta che viene eseguita la presentazione ?
		bne.s	Pnoft			; Se no, salta

		st	PresFirstTime(a5)

                ifnd SKIPINTRO
		move.l	PresPicName1(a5),d4
		jsr	ShowPic			;Visualizza logo1
		move.l	#250,d2
		bsr	Waiting2

		move.l	PresPicName2(a5),d4
		jsr	ShowPic			;Visualizza logo2
		move.l	#400,d2
		bsr	Waiting2
                endc ; SKIPINTRO

	bra.s	PresTit		;!!! DA RIMUOVERE NEL GIOCO FINALE !!!

		move.l	PresPicName3(a5),d4
		jsr	ShowMainPic		;Visualizza titolo

		bsr	InitKeyQueue
		moveq	#-1,d0
		move.l	d0,terminal(a5)
		st	Protection(a5)
		jsr	InitTerminal
		jsr	Terminal

		bra.s	Pjj
Pnoft

PresTit
		move.l	PresPicName3(a5),d4
		jsr	ShowMainPic		;Visualizza titolo

		bsr	InitKeyQueue
Pjj
		clr.b	ShowCredits(a5)

PresLoop
		jsr	TestChangeScreen
		move.b	$bfe001,d0
		and.b	#$c0,d0
		beq.s	Pout
		jsr	ReadKey
		cmp.w	#$40,d0		;Premuto SPACE ?
		beq.s	Pconfig
;		beq.s	Pout
		cmp.w	#$44,d0		;Premuto RETURN ?
		beq.s	Pconfig
;		beq.s	Pout
		cmp.w	#$45,d0		;Premuto ESC ?
		beq.s	Pconfig

		GFXBASE
		CALLSYS	WaitTOF

		bra.s	PresLoop

Pout
		clr.b	MusicState(a5)

		tst.l	PresModPun(a5)
		beq.s	Pnomod
		lea	$dff000,a6
		jsr	P61_End
		GETDBASE
Pnomod
		moveq	#0,d2
		jsr	ClearScreen
		rts


;***** Gestione terminale di configurazione

Pconfig
		clr.b	StartGame(a5)

		move.l	pixel_type(a5),d0
		move.w	d0,PixelSize(a5)
		move.l	d0,oldpixeltype(a5)
		move.w	SelectedSize+2(a5),d0
		lsr.w	#2,d0
		move.w	d0,WindowSize(a5)
		moveq	#-1,d0
		move.l	d0,terminal(a5)
		jsr	InitTerminal
		jsr	Terminal
		st	pause(a5)
		move.w	PixelSize(a5),pixel_type+2(a5)
		move.w	WindowSize(a5),d0
		lsl.w	#2,d0
		ext.l	d0
		move.l	d0,SelectedSize(a5)

		tst.b	ShowCredits(a5)		;Deve visualizzare credits ?
		beq.s	PLnocred
		move.l	PresPicName4(a5),d4
		jsr	ShowPic			;Visualizza credits
		move.l	#3000,d2
		bsr	Waiting
		bra	PresTit
PLnocred

		tst.b	StartGame(a5)		;Test se si vuole giocare
		bne	Pout

		tst.b	Escape(a5)		;Test se si vuole uscire
		bne	Pout
		bra	PresLoop

;****************************************************************************
;* Manda a video schermo di caricamento
;* Richiede:
;*	d4 = nome pic da mostrare a video


		xdef	LoadingScreen

LoadingScreen

		move.w	#-1,ActualScr(a5)

		move.l	d4,-(sp)

	;*** Carica modulo dei titoli
		move.l	#"MUSL",d4
		move.l	c2pBuffer2(a5),a4
		lea	30720(a4),a4
		jsr	LoadMod
		beq.s	LSlmodok		;Salta se ha caricato il mod
		clr.b	MusicState(a5)
		clr.l	PresModPun(a5)
		bra.s	LSlmodnook
LSlmodok	move.l	a0,PresModPun(a5)

		move.b	#2,P61_ofilter
		move.w	#4-1,P61_channels
		lea	snd_SIZE(a0),a0
		lea	$dff000,a6
		sub.l	a1,a1
		sub.l	a2,a2
		jsr	P61_Init
		GETDBASE
		move.w	#64,P61_Master
		st	MusicState(a5)
		st	P61_Play+1
LSlmodnook

		move.l	(sp)+,d4

		;*** Cancella schermi

		lea	planes_bitmap1(a5),a2
		moveq	#2,d5
LSclearloop0	move.l	(a2)+,a1
		moveq	#7,d6		;d6=contatore bitplanes
LSclearloop1	move.l	(a1)+,a0
		move.w	#499,d7
LSclearloop2	clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		dbra	d7,LSclearloop2
		dbra	d6,LSclearloop1
		dbra	d5,LSclearloop0

		move.l	pixel_type(a5),savepixeltype(a5)
		move.l	#1,pixel_type(a5)
		bsr	ChangePixelHeight
		move.l	savepixeltype(a5),pixel_type(a5)



		jsr	ShowPic

		GFXBASE

		lea	screen_rport(a5),a1
		move.l	a1,a4
		move.l	#254,d0
		CALLSYS	SetAPen

	;*** Stampa nome game e nome livello

		move.l	PunGame(a5),a0
		addq.w	#2,a0
		move.l	a0,a2
		moveq	#20,d0
		bsr	CheckLen
		move.l	d0,d3

		move.l	PunLevel(a5),a0
		addq.w	#4,a0
		move.l	a0,a3
		moveq	#20,d0
		bsr	CheckLen
		move.l	d0,d4

		add.w	d3,d0
		addq.w	#1,d0
		lsl.w	#3,d0		;d0=dim. in pixel della stringa
		sub.w	#320,d0
		neg.w	d0
		lsr.w	#1,d0

		move.l	a4,a1
		moveq	#7,d1
		CALLSYS	Move

		move.l	a4,a1
		move.l	a2,a0
		move.l	d3,d0
		CALLSYS	Text

		move.l	a4,a1
		lea	blanktext(pc),a0
		moveq	#1,d0
		CALLSYS	Text

		move.l	a4,a1
		move.l	a3,a0
		move.l	d4,d0
		CALLSYS	Text


	;*** Stampa numero di tentativi a disposizione

		move.b	Retries(a5),d0
		add.b	#48,d0
		lea	retriesnum(pc),a0
		move.b	d0,(a0)

		move.l	a4,a1
		moveq	#100,d0
		move.l	#17,d1
		CALLSYS	Move

		move.l	a4,a1
		lea	retriestext(pc),a0
		move.l	#15,d0
		CALLSYS	Text


	;*** Stampa codice di accesso

;		cmp.w	#1,CurrentGame(a5)	;Se  il primo game
;		beq.s	LSnolevcode		; non stampa il codice
;		cmp.w	#1,CurrentLevel(a5)	;Se non  il primo livello
;		bne.s	LSnolevcode		; non stampa il codice

		cmp.w	#1,CurrentGame(a5)	;Se  il primo livello del primo game
		bne.s	LSnofg			; non stampa il codice
		cmp.w	#1,CurrentLevel(a5)
		beq.s	LSnolevcode
LSnofg
		jsr	LevelCodeOut		;Calcola codice livello

		move.l	a4,a1
		moveq	#116,d0
		move.l	#220,d1
		CALLSYS	Move

		move.l	a4,a1
		lea	levcodetext(pc),a0
		moveq	#11,d0
		CALLSYS	Text

		move.l	a4,a1
		moveq	#96,d0
		move.l	#230,d1
		CALLSYS	Move

		move.l	a4,a1
		lea	LevelCodeASC(a5),a0
		moveq	#16,d0
		CALLSYS	Text
LSnolevcode



    IFEQ 1	;*** !!!PROTEZIONE!!!
	;*** Se  il secondo livello del secondo, terzo o quarto mondo,
	;*** segnala che bisogna controllare se  stata rimossa la protezione

		move.w	CurrentGame(a5),d0
		cmp.w	#2,d0			;E' il game 2, 3 o 4 ?
		blt.s	LSnogame2		; Se no, salta
		cmp.w	#2,CurrentLevel(a5)	;E' il secondo livello ?
		bne.s	LSnogame2		; se no, salta
		subq.b	#1,d0
		move.b	d0,Protection2(a5)	;Segnala tipo controllo da effettuare (1,2,3)
LSnogame2
    ENDIF	;*** !!!FINE PROTEZIONE!!!




;	;*** Stampa nome rivista a cui  stato mandato il gioco
;		move.l	a4,a1
;		moveq	#56,d0
;		move.l	#34,d1
;		CALLSYS	Move
;
;		moveq	#25,d7
;		lea	anticopy(pc),a3
;LScloop		move.l	a4,a1
;		move.l	a3,a0
;		moveq	#1,d0
;		CALLSYS	Text
;		addq.l	#2,a3
;		dbra	d7,LScloop

		rts





levcodetext	dc.b	'ACCESS CODE'
presskey	dc.b	'PRESS ANY KEY TO START'
retriestext	dc.b	'RETRIES LEFT  '
retriesnum	dc.b	' '		;Qui il codice scrive il numero da stampare
insdisktext	dc.b	'PLEASE INSERT DISK '
blanktext	dc.b	' ',0

		cnop	0,4


;****************************************************************************
;* Stampa sulla schermata di caricamento la scritta
;* "PRESS A KEY TO START" e attende pressione tasto.
;* In uscita ferma la musica e pulisce lo schermo.

		xdef	PressKeyMessage
PressKeyMessage
		GFXBASE

		lea	screen_rport(a5),a1
		move.l	a1,a4
		move.w	#RP_JAM1,d0
		CALLSYS	SetDrMd

		move.l	a4,a1
		move.l	#0,d0
		CALLSYS	SetAPen

		move.l	a4,a1
		moveq	#73,d0
		move.l	#117,d1
		CALLSYS	Move

		move.l	a4,a1
		lea	presskey(pc),a0
		moveq	#22,d0
		CALLSYS	Text

		move.l	a4,a1
		move.l	#255,d0
		CALLSYS	SetAPen

		move.l	a4,a1
		moveq	#72,d0
		move.l	#116,d1
		CALLSYS	Move

		move.l	a4,a1
		lea	presskey(pc),a0
		moveq	#22,d0
		CALLSYS	Text

		move.l	#25000,d2
		jsr	Waiting			;Attende

		moveq	#0,d2
		jsr	ClearScreen

		clr.b	MusicState(a5)

		tst.l	PresModPun(a5)
		beq.s	PKMnomod
		lea	$dff000,a6
		jsr	P61_End
		GETDBASE
PKMnomod

		rts

;****************************************************************************
;* Calcola la lunghezza della stringa puntata da a0, senza gli spazi finali.
;* Richiede:
;*	a0 = Pun. stringa
;*	d0 = Lun. massima stringa
;*
;* Risultato in d0

CheckLen	move.l	a0,-(sp)

		lea	(a0,d0.w),a0
CLloop		cmp.b	#32,-(a0)
		bne.s	CLout
		subq.w	#1,d0
		bgt.s	CLloop
CLout
		move.l	(sp)+,a0
		rts

;****************************************************************************
;* Sequenza di fine gioco

		xdef	EndGameSequence
EndGameSequence

		bsr	TurnOffSprites

		move.w	#-1,ActualScr(a5)

	;*** Carica modulo dei titoli
		move.l	PresModName(a5),d4
		move.l	SndPun(a5),a4
		jsr	LoadMod
		beq.s	EGSlmodok		;Salta se ha caricato il mod
		clr.b	MusicState(a5)
		clr.l	PresModPun(a5)
		bra.s	EGSlmodnook
EGSlmodok	move.l	a0,PresModPun(a5)

		move.b	#2,P61_ofilter
		move.w	#4-1,P61_channels
		lea	snd_SIZE(a0),a0
		lea	$dff000,a6
		sub.l	a1,a1
		sub.l	a2,a2
		jsr	P61_Init
		moveq	#34,d0
		jsr	P61_SetPosition
		GETDBASE
		move.w	#64,P61_Master
		st	MusicState(a5)
		st	P61_Play+1
EGSlmodnook

		move.l	EndGamePicName(a5),d4
		jsr	ShowPic
		move.l	#5000,d2
		bsr	Waiting

		bsr	TurnOnSprites

		tst.l	PresModPun(a5)
		beq.s	EGSnomod
		lea	$dff000,a6
		jsr	P61_End
		GETDBASE
EGSnomod
		rts

;****************************************************************************
;* Sequenza di game over

		xdef	GameOverSequence
GameOverSequence

		bsr	TurnOffSprites

		move.w	#-1,ActualScr(a5)

	;*** Carica modulo di caricamento
		move.l	#"MUSL",d4
		move.l	SndPun(a5),a4
		jsr	LoadMod
		beq.s	GOSlmodok		;Salta se ha caricato il mod
		clr.b	MusicState(a5)
		clr.l	PresModPun(a5)
		bra.s	GOSlmodnook
GOSlmodok	move.l	a0,PresModPun(a5)

		move.b	#2,P61_ofilter
		move.w	#4-1,P61_channels
		lea	snd_SIZE(a0),a0
		lea	$dff000,a6
		sub.l	a1,a1
		sub.l	a2,a2
		jsr	P61_Init
		moveq	#3,d0
		jsr	P61_SetPosition
		GETDBASE
		move.w	#64,P61_Master
		st	MusicState(a5)
		st	P61_Play+1
GOSlmodnook

		move.l	GameOverPicName(a5),d4
		jsr	ShowPic
		move.l	#1000,d2
		bsr	Waiting

		bsr	TurnOnSprites

		tst.l	PresModPun(a5)
		beq.s	GOSnomod
		lea	$dff000,a6
		jsr	P61_End
		GETDBASE
GOSnomod
		rts

;****************************************************************************
;* Visualizza schermo per richiedere l'inserimento di un disco
;* Richiede:
;*	a2 = Pun. alla stringa contenente il nome del disco

		xdef	DiskRequest

DiskRequest	movem.l	d0-d7/a0-a6,-(sp)

;		moveq	#1,d2
;		jsr	ClearScreen2

;		moveq	#1,d2			;Mostra secondo schermo
		moveq	#0,d2			;Mostra primo schermo
		bsr	ChangeScreen

		GFXBASE

		tst.b	DiskReqFlag(a5)		;C'e' una richiesta di disco attiva ?
		bne.s	DRnosave		; Se si, salta

		move.l	a2,a4

		;*** Salva fondo
		move.l	screen_bitmap1(a5),a0	;SrcBitMap
		move.l	screen_bitmap2(a5),a1	;DstBitMap
		sub.l	a2,a2			;TempA
		moveq	#0,d0			;SrcX
		moveq	#88,d1			;SrcY
		moveq	#0,d2			;DstX
		moveq	#0,d3			;DstY
		move.w	#320,d4			;SizeX
		moveq	#40,d5			;SizeY
		move.w	#$c0,d6			;Minterm
		move.w	#$ff,d7			;Mask
		CALLSYS	BltBitMap

		move.l	a4,a2
DRnosave

		move.l	screen_viewport(a5),a0
		move.l	#255,d0
		move.l	#$ff000000,d1
		clr.l	d2
		clr.l	d3
		CALLSYS	SetRGB32

		lea	screen_rport(a5),a1
		move.l	a1,a4
		move.l	#255,d0
		CALLSYS	SetAPen

		move.l	a4,a1
		moveq	#88,d0
		move.l	#115,d1
		CALLSYS	Move

		move.l	a4,a1
		lea	insdisktext(pc),a0
		moveq	#18,d0
		CALLSYS	Text

		move.l	a4,a1
		moveq	#116,d0
		move.l	#125,d1
		CALLSYS	Move

		move.l	a4,a1
		move.l	a2,a0
		moveq	#11,d0
		CALLSYS	Text

		CALLSYS	WaitTOF
		CALLSYS	WaitTOF

		st	DiskReqFlag(a5)

		movem.l	(sp)+,d0-d7/a0-a6
		rts



;* Ripristina sfondo sotto la scritta "Please insert disk"

		xdef	RestoreDR

RestoreDR	movem.l	d0-d7/a0-a6,-(sp)

		tst.b	DiskReqFlag(a5)		;C'e' una richiesta di disco attiva ?
		beq.s	RDRout			; Se no, salta

		GFXBASE
		move.l	screen_bitmap2(a5),a0	;SrcBitMap
		move.l	screen_bitmap1(a5),a1	;DstBitMap
		sub.l	a2,a2			;TempA
		moveq	#0,d0			;SrcX
		moveq	#0,d1			;SrcY
		moveq	#0,d2			;DstX
		moveq	#88,d3			;DstY
		move.w	#320,d4			;SizeX
		moveq	#40,d5			;SizeY
		move.w	#$c0,d6			;Minterm
		move.w	#$ff,d7			;Mask
		CALLSYS	BltBitMap

		clr.b	DiskReqFlag(a5)
RDRout
		movem.l	(sp)+,d0-d7/a0-a6
		rts

;****************************************************************************
;* Carica e mostra un'immagine dal file gfx gld
;*
;* Richiede:
;*	d4 : Nome pic.
;*

		xdef	ShowPic

ShowPic		movem.l	d0-d7/a0-a5,-(sp)

		jsr	LoadPic
		bne	SPout			;Esce se c' errore
		move.l	a0,PicPun(a5)		;Salva pun. pic

		moveq	#0,d2
		jsr	ClearScreen
SPin2
		bsr	c2p

		moveq	#0,d2			;Mostra primo schermo
		bsr	ChangeScreen

		move.l	PicPun(a5),a0
		lea	12(a0),a0
		bsr	LoadPalette

SPout
		movem.l	(sp)+,d0-d7/a0-a5
		rts



;*** Carica e mostra la schermata dei titoli.
;*** Differisce dalla ShowPic per la chiamata alla PutVersionLogo.

ShowMainPic	movem.l	d0-d7/a0-a5,-(sp)

		jsr	LoadPic
		bne	SPout			;Esce se c' errore
		move.l	a0,PicPun(a5)		;Salva pun. pic

		moveq	#0,d2
		jsr	ClearScreen

		bsr	PutVersionLogo

		bra.s	SPin2

;****************************************************************************


c2p
		move.l	PicPun(a5),d0

		move.l	planes_bitmap1(a5),a0
		move.l	(a0)+,a1
		move.l	(a0)+,a2
		move.l	(a0)+,a3
		move.l	(a0)+,a4
		move.l	(a0)+,a5
		move.l	(a0)+,a6

		move.l	(a0)+,d5
		sub.l	a6,d5
		move.l	(a0)+,d6
		sub.l	a6,d6

		move.l	d0,a0

		move.w	6(a0),d1
		mulu.w	#40,d1
		moveq	#0,d2
		move.w	4(a0),d2
		lsr.l	#3,d2
		add.l	d1,d2		;d2=(y1*(320>>3))+(x1>>3)=offset iniziale

		add.l	d2,a1
		add.l	d2,a2
		add.l	d2,a3
		add.l	d2,a4
		add.l	d2,a5
		add.l	d2,a6

		move.l	#320,d0
		move.w	8(a0),d7	;d7=width
		sub.w	d7,d0		;d0=320-width
		lsr.w	#3,d0		;d0=(320-width)>>3
		move.l	d0,rowoffset
		lsr.w	#3,d7		;d7=width>>3
		subq.w	#1,d7
		swap	d7		;d7.h=(width>>3)-1
		move.w	10(a0),d7
		subq.w	#1,d7		;d7.l=height-1

		lea	780(a0),a0
c2ploopy
		swap	d7
		move.w	d7,d4
		swap	d7
c2ploopx
		move.l	(a0)+,d0
		move.l	(a0)+,d1

		move.l	d0,d2
		and.l	#$f0f0f0f0,d2
		eor.l	d2,d0
		move.l	d1,d3
		and.l	#$f0f0f0f0,d3
		eor.l	d3,d1
		lsr.l	#4,d3
		or.l	d3,d2
		lsl.l	#4,d0
		or.l	d0,d1

		move.l	d2,d0
		and.l	#$3333cccc,d0
		eor.l	d0,d2
		lsr.w	#2,d0
		swap	d0
		lsl.w	#2,d0
		or.l	d0,d2

		move.l	d1,d3
		and.l	#$3333cccc,d3
		eor.l	d3,d1
		lsr.w	#2,d3
		swap	d3
		lsl.w	#2,d3
		or.l	d1,d3

		move.l	d2,d0
		and.l	#$55aa55aa,d0
		eor.l	d0,d2
		lsr.b	#1,d0
		ror.w	#8,d0
		add.b	d0,d0
		swap	d0
		lsr.b	#1,d0
		ror.w	#8,d0
		add.b	d0,d0
		swap	d0
		or.l	d2,d0

		move.l	d3,d1
		and.l	#$55aa55aa,d1
		eor.l	d1,d3
		lsr.b	#1,d1
		ror.w	#8,d1
		add.b	d1,d1
		swap	d1
		lsr.b	#1,d1
		ror.w	#8,d1
		add.b	d1,d1
		swap	d1
		or.l	d3,d1

		move.b	d1,(a1)+
		lsr.l	#8,d1
		move.b	d1,(a2)+
		lsr.l	#8,d1
		move.b	d1,(a3)+
		lsr.l	#8,d1
		move.b	d1,(a4)+

		move.b	d0,(a5)+
		lsr.l	#8,d0
		move.b	d0,(a6)+
		lsr.l	#8,d0
		move.b	d0,-1(a6,d5.l)
		lsr.l	#8,d0
		move.b	d0,-1(a6,d6.l)

		dbra	d4,c2ploopx

		move.l	rowoffset(pc),d0
		add.l	d0,a1
		add.l	d0,a2
		add.l	d0,a3
		add.l	d0,a4
		add.l	d0,a5
		add.l	d0,a6

		dbra	d7,c2ploopy

		GETDBASE

		rts


rowoffset	dc.l	0	;Offset di riga

;****************************************************************************
;* Pulisce lo schermo indicato in d0
;*
;* Richiede:
;*	d2 : Cod. schermo (0,1,2)

ClearScreen2	movem.l	d0-d7/a0-a5,-(sp)
		bra.s	CS2

		xdef	ClearScreen

ClearScreen	movem.l	d0-d7/a0-a5,-(sp)

		jsr	ResetPalette
CS2
		move.w	#499,d5
		tst.w	d2
		bne.s	CSnos0
		move.w	#599,d5
CSnos0
		GFXBASE
		CALLSYS	WaitTOF

		lea	planes_bitmap1(a5),a2
		move.l	(a2,d2.w*4),a1
		moveq	#0,d0
		moveq	#7,d6		;d6=contatore bitplanes
CSclearloop1	move.l	(a1)+,a0
		move.w	d5,d7
CSclearloop2	move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d7,CSclearloop2
		dbra	d6,CSclearloop1

		movem.l	(sp)+,d0-d7/a0-a5
		rts

;****************************************************************************
;* Mostra a video lo schermo indicato in d0
;*
;* Richiede:
;*	d2 : Cod. schermo (0,1,2)

ChangeScreen	movem.l	d0-d7/a0-a5,-(sp)

		cmp.w	ActualScr(a5),d2	;Test se lo schermo  gi mostrato
		beq.s	CSout			; Se si, salta
		move.w	d2,ActualScr(a5)

		st	ResetMousePos(a5)	;Segnala di riposizionare il mouse

		GFXBASE
		CALLSYS	WaitTOF
		CALLSYS	WaitTOF

		move.l	screen_viewport(a5),a0
		move.l	screen_bitmap1(a5),a1
		lea	(a1,d2.w*4),a1
		move.l	myDBufInfo(a5),a2
		CALLSYS	ChangeVPBitMap

		EXECBASE
CSloopw		move.l	DBufSafePort(a5),a0
		CALLSYS	GetMsg
		tst.l	d0
		bne.s	CSgo
		moveq	#1,d0
		move.l	DBufSafePort(a5),a0
		move.b	MP_SIGBIT(a0),d1
		lsl.l	d1,d0
		CALLSYS	Wait
		bra.s	CSloopw
CSgo
		GFXBASE
		CALLSYS	WaitTOF
		CALLSYS	WaitTOF

		EXECBASE
		CALLSYS	Forbid
		move.l	screen_viewport(a5),a0
		clr.l	vp_UCopIns(a0)
		CALLSYS	Permit

		INTUITIONBASE
		CALLSYS	RethinkDisplay

		GFXBASE
		jsr	TurnOffMousePointer
CSout
		movem.l	(sp)+,d0-d7/a0-a5
		rts

;****************************************************************************
;* Routine che attende d0 50esimi, oppure la pressione del LMB
;*
;* Richiede:
;*	d2.l = Numero 50esimi da attendere
;*
;* Restituisce flag Z=1 se  stato premuto LMB

		xdef	Waiting

Waiting
		add.l	VBTimer2(a5),d2
		bsr	InitKeyQueue
Wloop		jsr	TestChangeScreen
		btst	#6,$bfe001
		beq.s	WLMB
		jsr	ReadKey
		tst.b	d0
		bpl.s	WLMB
		cmp.l	VBTimer2(a5),d2
		bgt.s	Wloop

		moveq	#1,d0
		rts

WLMB		moveq	#0,d0
		rts

;****************************************************************************
;* Routine che attende d0 50esimi
;*
;* Richiede:
;*	d2.l = Numero 50esimi da attendere

		xdef	Waiting2
Waiting2
		add.l	VBTimer2(a5),d2
W2loop		GFXBASE
		CALLSYS	WaitTOF
		jsr	TestChangeScreen
		cmp.l	VBTimer2(a5),d2
		bgt.s	W2loop

		rts

;****************************************************************************
;*** Scrive a video il logo della versione del motore

PutVersionLogo	movem.l	a0-a2/d0-d2,-(sp)

		lea	VersionLogo(pc),a0
		clr.l	d0
		move.w	(a0)+,d0		;d0=x
		move.w	(a0)+,d1		;d1=y
		mulu.w	#320,d1
		add.l	d1,d0
		move.l	PicPun(a5),a1
		lea	780(a1),a1
		add.l	d0,a1

		move.w	(a0)+,d2		;d0=width-1
		move.w	(a0)+,d1		;d1=height-1
PVLloopy	move.w	d2,d0
		move.l	a1,a2
PVLloopx	move.b	(a0)+,(a2)+		;scrive pixel
		dbra	d0,PVLloopx
		lea	320(a1),a1		;Salta al prossimo rigo
		dbra	d1,PVLloopy

		movem.l	(sp)+,a0-a2/d0-d2
		rts

VersionLogo
		dc.w	303,47,8,4		;x,y,w-1,h-1
		;Immagine del logo in formato chunky pixel
		dc.b	000,255,000,000,000,000,000,255,000
		dc.b	255,255,000,000,000,000,255,255,000
		dc.b	000,255,000,000,000,000,000,255,000
		dc.b	000,255,000,000,000,000,000,255,000
		dc.b	255,255,255,000,255,000,255,255,255

;****************************************************************************

;		dc.b	'Registered to Amiga Format'
;anticopy	dc.b	'R1e4g3i1s7t5e3r2e4d2 1t6o7 6A5m4i3g2a1 5F6o7r8m6a5t4'

;		dc.b	'Registered to CU Amiga'
;anticopy	dc.b	'R1e4g3i6s2t3e4r5e9d8 6t5o4 2C3U1 5A7m8i9g5a4'

;		dc.b	'Registered to Amiga Computing'
;anticopy	dc.b	'R1e6g5i4s3t2e6r4e5d2 3t1o6 5A4m3i2g1a6 4C7o2m5p4u3t2i1n5g6'

;		dc.b	'Registered to Amiga Magazin'
;anticopy	dc.b	'R2e1g5i4s3t2e8r7e6d5 4t3o1 3A4m7i6g5a4 3M5a4g2a1z2i6n7'


		cnop	0,8

;****************************************************************************

		section	__MERGED,BSS


		cnop	0,4

		xdef	ActualScr,DiskReqFlag,PresFirstTime
		xdef	ShowCredits,StartGame

ActualScr	ds.w	1	;Numero (0,1,2) del buffer mostrato

DiskReqFlag	ds.b	1	;Se=TRUE,  attiva una richiesta di cambio disco

PresFirstTime	ds.b	1	;Se=FALSE,  la prima volta che esegue la presentazione

savepixeltype	ds.l	1

PicPun		ds.l	1	;Pun. immagine caricata

ShowCredits	ds.b	1	;Se=TRUE, deve visualizzare pagina credits

StartGame	ds.b	1	;Se=TRUE,  stata selezionata la voce "Start Game"


    IFEQ 1	;*** !!!PROTEZIONE!!!
		xdef	Protection2

Protection2	ds.b	1	;Se>0,  il tipo di controllo di protezione da effettuare
				;   1 : Controlla checksum tra DSprotection e DSProtectionEnd
				;   2 : Controlla checksum tra SecurityCode1 e SecurityCode1End
				;   3 : Come la 2
    ENDIF	;*** !!!FINE PROTEZIONE!!!


		ds.b	1	;Usato per allineare


		xdef	PresModName
		xdef	PresPicName1,PresPicName2,PresPicName3
		xdef	PresPicPun1,PresPicPun2,PresPicPun3

;*** !!! ATTENZIONE !!! Non separare le seguenti long

PresModName	ds.l	1	;Nome musica di presentazione
PresPicName1	ds.l	1	;Nomi immagini presentazione
PresPicName2	ds.l	1
PresPicName3	ds.l	1
PresPicName4	ds.l	1
GameOverPicName	ds.l	1	;Pic Game over
EndGamePicName	ds.l	1	;Pic End game

PresModPun	ds.l	1	;Pun. musica di presentazione
PresPicPun1	ds.l	1	;Pun. immagini presentazione
PresPicPun2	ds.l	1
PresPicPun3	ds.l	1
PresPicPun4	ds.l	1
PresPicPun5	ds.l	1
PresPicPun6	ds.l	1

		cnop	0,4



