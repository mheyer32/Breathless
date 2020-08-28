;******************************************************************
;*
;*	Main loop e routine di inizializzazione e gestione varie
;*
;* Versione:
;*
;* - Triplo buffer
;* - Eliminata gestione del messaggio dbi_DispMessage, per cui
;*   ora puo' arrivare al 50esimo di secondo
;* - Gestione Picasso II
;* - Gestione mappa migliorata
;* - Eliminato supporto PicassoII
;*
;******************************************************************

	include 'System'
	include 'TMap.i'

	xref	gfxbase,intuitionbase
	xref	LightingTable
	xref	Yoffset
	xref	ScrOutputType
	xref	screen_bitmap1,screen_bitmap2,screen_bitmap3,screen_viewport
	xref	PaletteRGB32,Palette
	xref	source_width
	xref	window_width,window_height
	xref	window_width2,window_height2
	xref	windowXratio,windowYratio,SkyXratio,SkyYratio
	xref	pixel_type,window_size
	xref	CeilingType,FloorType
	xref	PlayerX,PlayerZ,PlayerHeading
	xref	CPlayerX,CPlayerZ,CPlayerHeading
	xref	LookHeight
	xref	LookHeightNum,LookHeightRatio
	xref	CLookHeightNum,CLookHeight
	xref	PlayerBlock,PlayerBlockPun
	xref	CPlayerBlock,CPlayerBlockPun
	xref	InitIRQ,StopIRQ
	xref	AnimatedTextures
	xref	BlockEffectListPun,Effects
	xref	TriggerBlockList,TriggerBlockListPun
	xref	Objects,ObjectNumber
	xref	ObjFree,ObjEnemies,ObjThings
	xref	ObjPickThings,ObjShots,ObjExplosions
	xref	ObjectsPunList
	xref	vtable,otable
	xref	OTablePun,OTableList
	xref	IntuitionView
	xref	TMapScreen
	xref	myDBufInfo,DBufSafePort,DBufDispPort
	xref	uCopTags,myCopList1,myCopList2
	xref	switchpressed
	xref	KeyQueueIndex1,KeyQueueIndex2,KeyQueue
	xref	ChunkyBuffer,c2pBuffer1,c2pBuffer2
	xref	GfxPun,FreeGfxPun,Sprites,NullSprites
	xref	sigbit1,sigbit2
	xref	terminal
	xref	RedScreenCont
	xref	PlayerHealth,PlayerShields,PlayerEnergy
	xref	PlayerCredits,PlayerScore
	xref	PlayerHealthFL,PlayerShieldsFL,PlayerEnergyFL,WeaponsFL
	xref	PlayerCreditsFL,PlayerScoreFL
	xref	automap
	xref	LevelsDirPun,LevelsDirLen
	xref	animcounter,Canimcounter
	xref	ForwardKey,BackwardKey,RotateLeftKey,RotateRightKey
	xref	SideLeftKey,SideRightKey,FireKey,AccelKey
	xref	ForceSideKey,LookUpKey,ResetLookKey,LookDownKey
	xref	SwitchKey
	xref	WindowSize,PixelSize
	xref	WindowSize,PixelSize,SightState
	xref	MusicVolume,FilterState,MusicFade,MusicOnOff
	xref	P61_Master,P61_Play,P61_ofilter
	xref	DiskFlag,PresFirstTime
	xref	Protection
	xref	ActiveControl,MouseSensitivity
	xref	PlayerWalkSpeed,PlayerRunSpeed
	xref	PlayerRotWalkSpeed,PlayerRotRunSpeed
	xref	PlayerAccel,PlayerRotAccel
	xref	LevelCodeASC

	xref	ReadConfig,WriteConfig
	xref	LoadLevelData
	xref	LoadingScreen,EndGameSequence,GameOverSequence
	xref	DoMovement,GetTime
	xref	Render3d,c2p8_init,c2p8_go,c2p8_waitblitter
	xref	Animations
	xref	InitPlayerPos
	xref	PlayerFire
	xref	InitSprPrint
	xref	Terminal,InitTerminal
	xref	SoundFXBufferServer
	xref	InitAudio
	xref	InitScores,InitScores2
	xref	LevelCodeIn,LevelCodeOut,ClearLevelCode
	xref	PanelRefresh
	xref	MapMode,AutoMapping,InitAutomap
	xref	Rnd
	xref	StopAudio
	xref	BufferedPlaySoundFX,PlaySoundFX
	xref	ShowPic,ClearScreen,Presentation
	xref	Waiting
	xref	SprDelayPrintMessage,SprDelayPrint,SprPrint
	xref	P61_Init,P61_End
	xref	PressKeyMessage
	xref	TurnOffMousePointer
	xref	ResetMoveVars
	xref	CopyToActualConfig


;************************************************************

		xdef	TMapMain
TMapMain:
		movem.l	d0-d7/a0-a6,-(sp)

		move.w	#$ffff,ScreenActive(a5)

		bset	#1,$bfe001

		clr.b	PresFirstTime(a5)

		clr.b	ProgramState(a5)
		clr.b	MusicState(a5)

		move.w	#1,SightState(a5)
		move.w	#3,MusicVolume(a5)
		move.w	#1,FilterState(a5)
		move.w	#1,MusicOnOff(a5)
		clr.w	ActiveControl(a5)
		move.w	#5,MouseSensitivity(a5)

		move.w	#4<<4,PlayerWalkSpeed(a5)
		move.w	#6<<4,PlayerRunSpeed(a5)
		move.w	#8,PlayerRotWalkSpeed(a5)
		move.w	#20,PlayerRotRunSpeed(a5)
		move.w	#4,PlayerAccel(a5)
		move.w	#4,PlayerRotAccel(a5)

		jsr	InitSprPrint

		jsr	ClearLevelCode		;Init codice livello

		jsr	InitIRQ


	;***** Init screen sizes

		moveq	#12,d0
		move.l	d0,SelectedSize(a5)	;192x120
		moveq	#3,d0
		move.l	d0,pixel_type(a5)	;2x2
		clr.l	oldpixeltype(a5)


	;***** Legge configurazione

		jsr	ReadConfig

		jsr	CopyToActualConfig	;Copia config. tastiera


	;---------------- Presentation

TMapPres
		st	pause(a5)
		clr.b	ProgramState(a5)
		bsr	InitKeyQueue

		;*** Azzera pun. ai global sounds
		lea	GlobalSound0(a5),a0
		lea	GlobalSound10(a5),a1
		moveq	#0,d0
TMgsreset	move.l	d0,(a0)+
		cmp.l	a1,a0
		ble.s	TMgsreset

		move.w	SightState(a5),savesightstate(a5)
		clr.w	SightState(a5)
		bsr	InitSight		;Spegne mirino
		move.w	savesightstate(a5),SightState(a5)

		clr.b	Escape(a5)
		GFXBASE
		CALLSYS	WaitTOF
		CALLSYS	WaitTOF
		jsr	Presentation
		IFEQ	DEBUG
		tst.b	DiskFlag(a5)		;Se si parte da floppy, non deve essere possibile uscire dal programma
		bne.s	TMcodacc
		ENDC
		tst.b	Escape(a5)		;Test se si deve uscire dal programma
		bne	TMexit
TMcodacc

	;---------------- Init game

		;*** Init sprite terminal position
		move.l	screen_viewport(a5),a0
		move.l	Sprites+(6<<2)(a5),a1	;SimpleSprite pointer
		moveq	#8,d0			;x
		moveq	#0,d1			;y
		CALLSYS	MoveSprite
		move.l	screen_viewport(a5),a0
		move.l	Sprites+(7<<2)(a5),a1	;SimpleSprite pointer
		moveq	#72,d0			;x
		moveq	#0,d1			;y
		CALLSYS	MoveSprite


		move.w	#1,CurrentGame(a5)
		move.w	#1,CurrentLevel(a5)
		clr.b	EndGame(a5)
		clr.b	showmap(a5)
		clr.b	EscKey(a5)
		st	pause(a5)
		st	FirstMatchLevel(a5)

		move.b	#3,Retries(a5)	;Init numero tentativi

		clr.l	TransEffect(a5)

		jsr	InitScores

	;***** Init armi player

		lea	PlayerWeapons(a5),a0
		move.l	#$01000000,(a0)+	;Init armi da 1 a 4
		clr.l	(a0)+			;Init armi da 5 a 8

		clr.w	PlayerActiWeapon(a5)
		clr.w	PlayerWeaponAuto(a5)
		moveq	#$00000006,d0
		move.l	d0,WeaponOsc(a5)
		move.w	#-1,PlayerBuyWeapon(a5)

		jsr	LevelCodeIn		;Interpreta codice livello immesso
		clr.l	PlayerScore(a5)
		clr.b	PlayAgain(a5)		;Deve essere settato se non si parte da zero
		move.b	#3,Retries(a5)		;Init numero tentativi

	;------------------------------------

TMapStart
		move.l	GfxPun(a5),FreeGfxPun(a5)

		move.l	#1,clear_bitmap1(a5)
		move.l	#1,clear_bitmap2(a5)
		move.l	#1,clear_bitmap3(a5)

		move.l	planes_bitmap2(a5),CurrentBitmap(a5)

		move.w	#1,SafeToChange(a5)
		move.w	#1,SafeToWrite(a5)
		move.l	#4,CurrBuffer(a5)

		bsr	KIresetlook

		bsr	TurnOffSprites

		jsr	InitScores2

		bsr	GetLevelNames
		tst.b	EndGame(a5)		;Test se finito gioco
		beq.s	TMnoendgame		; Se no, salta
		jsr	EndGameSequence
		bra	TMapPres
TMnoendgame

;		tst.b	FirstMatchLevel(a5)	;E' il primo livello di questa partita ?
;		bne.s	TMfml			; Se si, salta

;		jsr	LevelCodeOut		;Init codice livello
TMfml
		jsr	LoadLevelData		;Carica dati livello
		bne	TMexit			; Esce se c' errore

		jsr	PressKeyMessage

		bsr	ChangePixelHeight


		clr.w	P61_Play


		jsr	InitTables
		jsr	InitMap
		jsr	InitTextures
		jsr	InitObjects
		jsr	PanelSetup
		jsr	InitWindowSize
		jsr	InitSprPrint
		jsr	InitAudio
		jsr	InitPlayerPos
		jsr	PanelRefresh
		jsr	InitOthers
		jsr	InitSight
		jsr	InitAutomap

		bsr	TurnOnSprites

		move.l	PTModule(a5),d0		;C'e' un modulo da eseguire ?
		beq.s	TMnomod			; Se no, salta
;		move.w	#$e000,$dff09a		;Attiva IRQ lev6
;		move.l	d0,a0
;		lea	$dff000,a6
;		sub.l	a1,a1
;		sub.l	a2,a2
;		jsr	P61_Init
;		GETDBASE
		clr.b	MusicFade(a5)
		st	MusicState(a5)
TMnomod
		clr.w	pause(a5)
		move.b	#1,ProgramState(a5)
		clr.b	FirstMatchLevel(a5)
		clr.b	EndLevelFade(a5)

		GFXBASE
		CALLSYS	WaitTOF
		CALLSYS	WaitTOF

		EXECBASE
		CALLSYS	CacheClearU

;-----------------------------------------------------------------

;		jsr	GetTime
;		move.l	d0,time0(a5)

		bsr	InitKeyQueue

		clr.b	PlayerDeath(a5)
		clr.b	Escape(a5)
		clr.l	animcounter(a5)

				;*** Effetto fade iniziale
;		move.b	#-1,ProgramState(a5)
		move.l	#$1f000100,TransEffect(a5)
		moveq	#0,d1
		move.l	GlobalSound3(a5),a0
		clr.l	CurrBuffer(a5)
		jsr	BufferedPlaySoundFX
		move.l	#4,CurrBuffer(a5)

TMainloop
		tst.w	RedScreenCont(a5)
		bmi.s	TMnoresetpalette
		beq.s	TMresetpalette
		tst.w	pause(a5)		;Test se  in pausa
		beq.s	TMnoresetpalette
TMresetpalette	lea	Palette(a5),a0
		bsr	LoadPalette
;		move.l	screen_viewport(a5),a0
;		lea	Palette,a1
;		GFXBASE
;		CALLSYS	LoadRGB32
		move.w	#-1,RedScreenCont(a5)
TMnoresetpalette

		tst.w	pause(a5)		;Test se  in pausa
		beq.s	TMnopause
		jsr	ResetMoveVars
		tst.b	showmap(a5)		;Test se deve mostrare mappa
		bne.s	TMsmap
		tst.l	terminal(a5)		;Test se deve mostrare terminale
		bmi.s	TMconfig		;Salta se terminale configurazione
		bne.s	TMterm
		bsr	PauseMode
		bra.s	TMnopause
TMconfig	move.w	pixel_type+2(a5),PixelSize(a5)
		move.w	SelectedSize+2(a5),d1
		lsr.w	#2,d1
		move.w	d1,WindowSize(a5)
		jsr	InitTerminal
		jsr	Terminal
		move.w	PixelSize(a5),d0
		move.w	WindowSize(a5),d1
		lsl.w	#2,d1
		ext.l	d1
		sub.l	SelectedSize(a5),d1
		bne.s	TMmodwin
		cmp.w	pixel_type+2(a5),d0
		beq.s	TMnopause
TMmodwin	move.w	d0,pixel_type+2(a5)
		bsr	KIchangewinsize		;Se cambiata configurazione window, inizializza view
		bra.s	TMnopause
TMterm		jsr	Terminal
		move.w	PlayerBuyWeapon(a5),d0
		bmi.s	TMnopause
		move.w	#-1,PlayerBuyWeapon(a5)
		bsr	ChangeWeapon
		bra.s	TMnopause
TMsmap		jsr	MapMode
TMnopause

		move.b	ScreenActive(a5),d0
		cmp.b	OldScreenActive(a5),d0	;Test se cambiato schermo Intuition
		beq.s	TMnochangescreen	; Se no, salta
		move.b	d0,OldScreenActive(a5)
		tst.b	d0
		beq.s	TMsproff
		bsr	TurnOnSprites
		bra.s	TMnochangescreen
TMsproff	bsr	TurnOffSprites
		tst.b	ProgramState(a5)	;Se ProgramState=-1
		bmi.s	TMnochangescreen	; Salta
		st	gopause(a5)		;Segnala che deve andare in pausa
TMnochangescreen

		jsr	SoundFXBufferServer
;		jsr	PlayerFire
		jsr	Render3d
		jsr	Animations
		jsr	PanelRefresh
		jsr	AutoMapping

		move.l	animcounter(a5),d0
		cmp.l	storecount(a5),d0	;Test se  passato almeno un 50esimo
		bgt.s	TM50ok			; Se si, salta
		GFXBASE
		CALLSYS	WaitTOF
TM50ok		move.l	d0,storecount(a5)


		tst.w	SafeToWrite(a5)
		bne.s	TMgowrite
		EXECBASE
STWloop		move.l	DBufSafePort(a5),a0
		CALLSYS	GetMsg
		tst.l	d0
		bne.s	TMgowrite
		moveq	#1,d0
		move.l	DBufSafePort(a5),a0
		move.b	MP_SIGBIT(a0),d1
		lsl.l	d1,d0
		CALLSYS	Wait
		bra.s	STWloop
TMgowrite
		move.w	#1,SafeToWrite(a5)

		tst.w	TransEffect(a5)
		beq.s	TMnotranseffect
		bsr	Fade
TMnotranseffect

		tst.l	CurrentClear(a5)
		beq.s	TMnoclear
		bsr	ClearCurrentBitmap
TMnoclear	move.l	CurrentBitmap(a5),a0
		jsr	c2p8_go

		bsr	KeyboardInput
		tst.b	gopause(a5)		;Deve andare in pausa forzata da un cambio di schermo ?
		beq.s	TMnforcepause
		bsr	KIpause
TMnforcepause
		move.l	CurrBuffer(a5),d0
		lea	planes_bitmap1(a5),a0
		move.l	(a0,d0.l),CurrentBitmap(a5)
		move.l	16(a0,d0.l),CurrentClear(a5)
		move.l	#0,16(a0,d0.l)

		addq.w	#4,d0
		cmp.w	#8,d0
		ble.s	TMnor
		clr.l	d0
TMnor		move.l	d0,CurrBuffer(a5)

		move.l	screen_viewport(a5),a0
;		move.l	CurrBuffer(a5),d0
		lea	screen_bitmap1(a5),a1
		move.l	(a1,d0.l),a1
		move.l	myDBufInfo(a5),a2
		GFXBASE
		CALLSYS	ChangeVPBitMap

		move.l	changeres(a5),d0
		beq.s	TMnochgres
		cmp.w	CurrBuffer+2(a5),d0
		bne.s	TMnochgres
		clr.l	changeres(a5)
		bsr	ChangePixelHeight
TMnochgres
		move.w	#0,SafeToWrite(a5)

		IFNE	0

		PRINTHEX #2,#10,PlayerX(a5)
		PRINTHEX #2,#20,PlayerZ(a5)
		PRINTHEX #2,#30,PlayerHeading(a5)

		PRINTHEX #26,#0,times(a5)	;Raycasting time
		PRINTHEX #30,#0,times+2(a5)
		PRINTHEX #26,#10,times+4(a5)	;Wall rendering time
		PRINTHEX #30,#10,times+6(a5)
		PRINTHEX #26,#20,times+8(a5)	;Object rendering time
		PRINTHEX #30,#20,times+10(a5)

		jsr	GetTime
		add.l	times(a5),d0
		add.l	times+4(a5),d0
		add.l	times+8(a5),d0
		beq.s	TMnoframerate
		move.l	#1000000,d1
		divu.l	d0,d1
		move.w	d1,framerate(a5)
		PRINTHEX #10,#0,framerate(a5)
TMnoframerate
		ENDC

		tst.b	EndLevelFade(a5)	;E' attivo il fade di fine livello ?
		bne.s	TMendfade		; Se si, salta

		tst.b	Escape(a5)		;Deve uscire dal ciclo principale ?
		beq	TMainloop		; Se no, salta

			;*** Init fade di fine livello
		lea	Palette(a5),a0
		bsr	LoadPalette
		moveq	#0,d1
		move.l	GlobalSound3(a5),a0
		clr.l	CurrBuffer(a5)
		jsr	BufferedPlaySoundFX
		move.b	#-1,ProgramState(a5)
		move.l	#$04000002,TransEffect(a5)
		st	EndLevelFade(a5)
		st	MusicFade(a5)
		move.b	#13,EndLevelCont(a5)	;Init contatore finale
		bra	TMainloop

TMendfade
		cmp.w	#8192-256,TransEffect(a5)
		blt	TMainloop
		subq.b	#1,EndLevelCont(a5)	;Decrementa contatore finale
		bgt	TMainloop		; Se>0, salta
		tst.b	MusicFade(a5)		;Fade terminato ?
		bne	TMainloop		; Se no, salta


;		jsr	StopIRQ

;-----------------------------------------------------------------

		GFXBASE
		moveq	#13,d7
TMendwait	CALLSYS	WaitTOF
		dbra	d7,TMendwait

		tst.w	SafeToWrite(a5)
		bne.s	TMwriteoff
		EXECBASE
STWloopoff	move.l	DBufSafePort(a5),a0
		CALLSYS	GetMsg
		tst.l	d0
		bne.s	TMwriteoff
		moveq	#1,d0
		move.l	DBufSafePort(a5),a0
		move.b	MP_SIGBIT(a0),d1
		lsl.l	d1,d0
		CALLSYS	Wait
		bra.s	STWloopoff
TMwriteoff

		clr.b	MusicState(a5)

		tst.l	PTModule(a5)		;E' in esecuzione un modulo ?
		beq.s	TMnomod2
		lea	$dff000,a6
		jsr	P61_End
		GETDBASE
TMnomod2
		jsr	c2p8_waitblitter

		jsr	StopAudio

		bsr	ResetPalette

		clr.b	PlayAgain(a5)

		tst.b	EscKey(a5)
		bne	TMapPres	;Abilitare questa riga nel gioco definitivo per tornare alla presentazione
;		bne.s	TMexit		; e remmare questa riga

		tst.b	PlayerDeath(a5)
		beq.s	TMnodth
		subq.b	#1,Retries(a5)		;Decrementa num. tentativi
		bgt.s	TMretr			; Se>0, riprova
		jsr	GameOverSequence
		bra	TMapPres
TMretr		st	PlayAgain(a5)
		bra	TMapStart
TMnodth

		addq.w	#1,CurrentLevel(a5)	;Prossimo level

		st	pause(a5)
		bra	TMapStart

TMexit
	;*** Scrive nuovo codice di livello

		move.l	LevelCodeASC(a5),-(sp)
		move.l	LevelCodeASC+4(a5),-(sp)
		move.l	LevelCodeASC+8(a5),-(sp)
		move.l	LevelCodeASC+12(a5),-(sp)
		jsr	ReadConfig
		move.l	(sp)+,LevelCodeASC+12(a5)
		move.l	(sp)+,LevelCodeASC+8(a5)
		move.l	(sp)+,LevelCodeASC+4(a5)
		move.l	(sp)+,LevelCodeASC(a5)
		jsr	WriteConfig


		jsr	StopIRQ
		movem.l	(sp)+,d0-d7/a0-a6
		rts


;******************************************************************

PauseMode
		moveq	#0,d0
		moveq	#8,d1
		moveq	#0,d2
		lea	MessPause(pc),a0
		jsr	SprDelayPrint

PMloop		move.b	ScreenActive(a5),d0
		cmp.b	OldScreenActive(a5),d0	;Test se cambiato schermo Intuition
		beq.s	PMnochangescreen	; Se no, salta
		move.b	d0,OldScreenActive(a5)
		tst.b	d0
		beq.s	PMsproff
		bsr	TurnOnSprites
		bra.s	PMnochangescreen
PMsproff	bsr	TurnOffSprites
PMnochangescreen
		GFXBASE
		CALLSYS	WaitTOF
		bsr	KeyboardInput
		tst.w	pause(a5)
		bne.s	PMloop

		moveq	#19,d0
		jsr	SprDelayPrintMessage
PMret		rts

MessPause	dc.b	'PAUSE ON',0

		cnop	0,4

;******************************************************************
; Gestione input da tastiera

		xdef	KeyboardInput

KeyboardInput
		tst.b	ProgramState(a5)
		bmi.s	PMret

		lea	KeyQueueIndex1(a5),a0
		move.l	(a0)+,d1		;d1=KeyQueueIndex1
		cmp.l	(a0)+,d1		;Confronta con KeyQueueIndex2
		beq	KIout			;Se sono uguali, allora la coda  vuota
		move.w	(a0,d1.l),d0		;d0=scancode tasto
		addq.l	#2,d1			;Sposta l'indice
		and.w	#$7f,d1			;Assicura la circolarit dell'indice
		move.l	d1,KeyQueueIndex1(a5)	;Memorizza l'indice

		tst.w	showmap(a5)
		bne	KImp
		tst.w	pause(a5)
		bne	KIwp

;		cmp.w	#($40),d0		;Premuto tasto ' ' ?
		cmp.w	SwitchKey,d0		;Premuto tasto switch ?
		bne.s	KInospace
		move.w	#1,switchpressed(a5)
		rts
KInospace	cmp.w	#($01),d0		;Premuto tasti da 1 a 6 ?
		blt.s	KInow1
		cmp.w	#($06),d0
		bgt.s	KInow1
		subq.w	#$1,d0
		bra	KIchangeweapon
KInow1		cmp.w	#($50),d0		;Premuto tasti da F1 a F6 ?
		blt.s	KInow2
		cmp.w	#($55),d0
		bgt.s	KInow2
		sub.w	#$50,d0
		bra	KIchangeweapon
KInow2		cmp.w	#($4a+$80),d0		;Premuto tasto '-' ?
		bne.s	KIno1
		moveq	#-4,d1
		bra	KIchangewinsize
KIno1		cmp.w	#($5e+$80),d0		;Premuto tasto '+' ?
		bne.s	KIno2
		moveq	#4,d1
		bra	KIchangewinsize
KIno2		cmp.w	#($5a+$80),d0		;Premuto tasto '[' Tast.Num.?
		beq	KIpixelsize11
		cmp.w	#($5b+$80),d0		;Premuto tasto ']' Tast.Num.?
		beq	KIpixelsize21
		cmp.w	#($5c+$80),d0		;Premuto tasto '/' Tast.Num.?
		beq	KIpixelsize12
		cmp.w	#($5d+$80),d0		;Premuto tasto '*' Tast.Num.?
		beq	KIpixelsize22
;		cmp.w	LookUpKey,d0		;Premuto tasto sguardo in alto ?
;		beq	KIraiselook
		cmp.w	ResetLookKey,d0		;Premuto tasto reset sguardo ?
		beq	KIresetlook
;		cmp.w	LookDownKey,d0		;Premuto tasto sguardo in basso ?
;		beq	KIlowerlook
;		cmp.w	#($3e+$80),d0		;Premuto tasto '8' Tast.Num.?
;		beq	KIceilonoff
;		cmp.w	#($3f+$80),d0		;Premuto tasto '9' Tast.Num.?
;		beq	KIflooronoff
		cmp.w	#($45+$80),d0		;Premuto tasto Esc ?
		beq	KIescape
		cmp.w	#($58+$80),d0		;Premuto tasto F9 ?
		beq	KIcheat
		cmp.w	#($08),d0		;Premuto tasto '8' ?
		beq	KIjumplevel
		cmp.w	#($09),d0		;Premuto tasto '9' ?
		beq	KIjumpgame

	;* Questi test devono essere gli ultimi e devono rimanere in quest'ordine
KImp		cmp.w	#($42+$80),d0		;Premuto tasto TAB ?
		beq	KIshowmap
KIwp		cmp.w	#($19+$80),d0		;Premuto tasto 'p' ?
		beq	KIpause
		rts



	;***** Cambia armi

KIchangeweapon
		lea	PlayerWeapons(a5),a1
		tst.b	(a1,d0.w)			;Test se l'arma  posseduta
		beq.s	KIcwout				; Se no, salta
		cmp.w	PlayerActiWeapon(a5),d0		;Arma gi attiva ?
		beq.s	KIcwout				; Se si, salta
		move.l	GlobalSound2(a5),a0
		moveq	#0,d1
		jsr	PlaySoundFX
ChangeWeapon
		lea	PlayerWeapons(a5),a1
		tst.b	(a1,d0.w)			;Test se l'arma  posseduta
		beq.s	KIcwout				; Se no, salta
		move.w	PlayerActiWeapon(a5),d2		;d2=precedente arma attiva
		move.w	d0,PlayerActiWeapon(a5)		;Attiva l'arma
		lea	WeaponsFL(a5),a1
		st	(a1,d0.w)			;Segnala di aggiornare il pannello dei punteggi
		st	(a1,d2.w)

		lea	GunObj1(a5),a1
		move.l	(a1,d0.w*4),a1			;a1=pun. all'oggetto shot
		move.l	a1,PlayerWeaponPun(a5)		;Pun. all'oggetto
		move.b	o_param10(a1),PlayerWeaponAuto+1(a5)	;Stato autofire

		add.w	#13,d0
		jsr	SprDelayPrintMessage

KIcwout		rts


	;***** Cambia dimensioni pixel

KIpixelsize11	move.l	pixel_type(a5),oldpixeltype(a5)
		clr.l	pixel_type(a5)
		clr.l	d1
		bra	KIchangewinsize

KIpixelsize21	move.l	pixel_type(a5),oldpixeltype(a5)
		move.l	#1,pixel_type(a5)
		clr.l	d1
		bra	KIchangewinsize

KIpixelsize12	move.l	pixel_type(a5),oldpixeltype(a5)
		move.l	#2,pixel_type(a5)
		clr.l	d1
		bra	KIchangewinsize

KIpixelsize22	move.l	pixel_type(a5),oldpixeltype(a5)
		move.l	#3,pixel_type(a5)
		clr.l	d1
		bra.s	KIchangewinsize

	;***** Alza/abbassa lo sguardo

KIresetlook	clr.l	CLookHeight(a5)
		clr.l	CLookHeightNum(a5)
		rts


	;***** Abilita/disabilita soffitto/pavimento texture mapped

KIceilonoff	eor.w	#1,CeilingType(a5)
		rts

KIflooronoff	eor.w	#1,FloorType(a5)
		rts

	;***** Setta flag uscita dal gioco

KIescape	move.l	GlobalSound2(a5),a0
		moveq	#0,d1
		jsr	PlaySoundFX
		move.w	#1,pause(a5)
		moveq	#-1,d0
		move.l	d0,terminal(a5)
		rts

	;***** Abilita/disabilita pausa

KIpause		eor.w	#1,pause(a5)
		clr.b	gopause(a5)
		rts

	;***** Mostra la mappa

KIshowmap	eor.b	#1,showmap(a5)
		eor.w	#1,pause(a5)
		rts


;***** Inizializza le dimensioni della finestra
;***** Richiama anche InitView

InitWindowSize
		clr.l	d1


	;***** Cambia dimensioni della finestra
KIchangewinsize
		add.l	SelectedSize(a5),d1
		lea	ViewSizeTable(pc,d1.l),a0
		clr.l	d2
		clr.l	d3
		move.w	(a0)+,d2		;d2=width
		beq	KIout			;Se width=0, allora siamo fuori dalla ViewSizeTable
		move.w	(a0)+,d3		;d3=height

		move.l	d1,SelectedSize(a5)

		move.l	d2,realwindow_width(a5)
		move.l	d3,realwindow_height(a5)

		move.l	pixel_type(a5),d0
		beq.s	KIpixel11		;Salta se pixel 1x1
		lsr.w	#1,d0			;Width dei pixel=2 ?
		bcc.s	KInox			; se no, salta
		lsr.l	#1,d2			; se si, divide width per due
KInox		lsr.w	#1,d0			;Height dei pixel=2 ?
		bcc.s	KIpixel11		; se no, salta
		lsr.l	#1,d3			; se si, divide height per due
KIpixel11	move.l	d2,window_width(a5)
		move.l	d3,window_height(a5)
		move.l	d2,d4
		mulu	d3,d4			;d4=width*height
		move.l	d4,window_size(a5)
		lsr.l	#1,d2
		lsr.l	#1,d3
		move.l	d2,window_width2(a5)
		move.l	d3,window_height2(a5)
		bsr	InitView
		bsr	ComputeVars
KIout
		rts


    IFEQ 1	;*** !!!PROTEZIONE!!!
Checksum2	dc.l	$6e399
    ENDIF	;*** !!!FINE PROTEZIONE!!!


		dc.l	0
ViewSizeTable	;	dc.w	32,20
		;	dc.w	64,40
		dc.w	96,60
		dc.w	128,80
		dc.w	160,100
		dc.w	192,120
		dc.w	224,140
		dc.w	256,160
		dc.w	288,180
		dc.w	320,200
		dc.l	0

;******************************************************************
;***** Cheat mode

KIcheat
		move.w	#PLAYER_HEALTH,PlayerHealth(a5)
		move.w	#PLAYER_SHIELDS,PlayerShields(a5)
		move.w	#PLAYER_ENERGY,PlayerEnergy(a5)
		move.l	#90000,PlayerCredits(a5)
		move.b	#1,PlayerHealthFL(a5)
		move.b	#1,PlayerShieldsFL(a5)
		move.b	#1,PlayerEnergyFL(a5)
		move.b	#1,PlayerCreditsFL(a5)

		rts

KIjumplevel
		st	Escape(a5)
		rts

KIjumpgame
		st	Escape(a5)
		addq.w	#1,CurrentGame(a5)
		clr.w	CurrentLevel(a5)
		rts


;******************************************************************
; Calcola alcune variabili, in base alle dimensioni della finestra
; ed alla risoluzione dei pixel

ComputeVars

		move.l	#WINDOW_STANDARD_WIDTH<<16,d0
		divu.l	window_width(a5),d0
		move.l	d0,windowXratio(a5)

		move.l	window_height(a5),d0
		swap	d0
		clr.w	d0
		divu.l	#WINDOW_STANDARD_HEIGHT,d0
		move.l	d0,windowYratio(a5)

		mulu.l	#(LOOKHEIGHT_STEP<<16),d1:d0
		move.w	d1,d0
		swap	d0
		move.l	d0,LookHeightRatio(a5)
		move.l	CLookHeightNum(a5),d1
		muls.l	d0,d1
		swap	d1
		ext.l	d1
		move.l	d1,CLookHeight(a5)

		move.l	#SKY_STANDARD_WIDTH<<12,d0
		divu.l	window_width(a5),d0
		move.w	d0,SkyXratio(a5)

		move.l	#SKY_STANDARD_HEIGHT<<16,d0
		divu.l	window_height(a5),d0
		move.l	d0,SkyYratio(a5)

		rts

;******************************************************************
; Inizializza mappa

InitMap
		move.l	Textures(a5),a2

		IFEQ	DEBUG

    IFEQ 1	;*** !!!PROTEZIONE!!!
	;*** Controlla se la routine tra SecurityCode1 e SecurityCode1End
	;***  integra.
		xref	Protection2,SecurityCode1,SecurityCode1End
		sub.l	a4,a4
		lea	Protection2-$153(a5),a0
		cmp.b	#2,$153(a0)		;Test se deve fare test
		blt.s	TPPno
		lea	SecurityCode1-$658,a1
		lea	SecurityCode1End-$658,a0
TPPchecksumloop	add.w	$658(a1),a4		;Loop di calcolo checksum
		addq.l	#2,a1
		cmp.l	a0,a1
		blt.s	TPPchecksumloop
		lea	ViewSizeTable(pc),a3
		cmp.l	-8(a3),a4		;Controlla checksum
;PROT.REMOVED	beq.s	TPPno			; Se valido, salta
;PROT.REMOVED	move.l	Textures-8(a5),a2
TPPno

    ENDIF	;*** !!!FINE PROTEZIONE!!!

		ENDC
		move.l	Blocks(a5),a0
		move.l	Edges(a5),a1
;		move.l	Textures(a5),a2

	;*** Init blocks
;		move.l	-8(a0),d4	;d4=flag se calcolare pun. alle texture di pavimento e soffitto
		move.l	-4(a0),d7	;d7=num. blocchi
		subq.w	#1,d7
		clr.l	d6
IMloop1
		move.w	d6,bl_BlockNumber(a0)	;Block number
		move.l	bl_Edge1(a0),d0
		mulu	#ed_SIZE,d0
		add.l	a1,d0
		move.l	d0,bl_Edge1(a0)		;Edge1 pun.
		move.l	bl_Edge2(a0),d0
		mulu	#ed_SIZE,d0
		add.l	a1,d0
		move.l	d0,bl_Edge2(a0)		;Edge2 pun.
		move.l	bl_Edge3(a0),d0
		mulu	#ed_SIZE,d0
		add.l	a1,d0
		move.l	d0,bl_Edge3(a0)		;Edge3 pun.
		move.l	bl_Edge4(a0),d0
		mulu	#ed_SIZE,d0
		add.l	a1,d0
		move.l	d0,bl_Edge4(a0)		;Edge4 pun.
		add.w	#bl_SIZE,a0
		addq.w	#1,d6
		dbra	d7,IMloop1


	;*** Init edges
		move.l	-4(a1),d7	;d7=num. edges
		subq.w	#1,d7
IMloop2		move.l	ed_NormTexture(a1),d0
		move.l	(a2,d0.w*4),ed_NormTexture(a1)	;Normal texture pun.
		move.l	ed_UpTexture(a1),d0
		bne.s	IMutnz				;Se la upper texture non  zero, salta
		addq.w	#1,d0				;Altrimenti prende la texture uno
IMutnz		move.l	(a2,d0.w*4),ed_UpTexture(a1)	;Upper texture pun.
		move.l	ed_LowTexture(a1),d0
		bne.s	IMltnz				;Se la lower texture non  zero, salta
		addq.w	#1,d0				;Altrimenti prende la texture uno
IMltnz		move.l	(a2,d0.w*4),ed_LowTexture(a1)	;Lower texture pun.
		add.w	#ed_SIZE,a1
		dbra	d7,IMloop2

		rts

;******************************************************************
; Inizializza textures

InitTextures
		move.l	Textures(a5),a0
		addq.w	#4,a0		;Salta primo puntatore inutilizzato
		lea	AnimatedTextures+4(a5),a1

		moveq	#0,d2
ITxloop		move.l	(a0)+,d0		;Legge pun. texture
		beq.s	ITxout			;Se=0 abbiamo finito
		move.l	d0,a2
		add.l	d0,tx_Brush(a2)		;Calcola pun. al primo frame
		cmp.w	#1,tx_Animation(a2)	;Test se texture animata
		ble.s	ITxloop			;Se non animata continua il ciclo
		addq.w	#4,a2			;Sposta il pun. alla texture sul puntatore ai brush
		move.l	a2,(a1)+		;Memorizza pun. alla texture animata
		addq.w	#1,d2			;Incrementa num. texture animate
		addq.w	#8,a2			;Sposta a2 sulla lista di puntatori ai brush
ITxloop2	tst.l	(a2)			;Test se finita lista frames
		beq.s	ITxloop			;Se finita lista frames, salta alla prossima texture
		add.l	d0,(a2)+		;Calcola pun. frame
		bra.s	ITxloop2
ITxout
		lea	AnimatedTextures(a5),a1
		move.l	d2,(a1)			;Memorizza all'inizio della tabella il num. di textures animate presenti


	;*** Inizializza switch textures

		move.l	Textures(a5),a0
		addq.w	#4,a0		;Salta primo puntatore inutilizzato

ITswloop	move.l	(a0)+,d0		;Legge pun. texture
		beq.s	ITswout			;Se=0 abbiamo finito
		move.l	d0,a1
		cmp.w	#1,tx_Animation(a1)	;Texture animata ?
		bgt.s	ITswloop		; se si, salta
		move.l	tx_AnimCount(a1),d1	;C'e' un link con un'altra texture?
		beq.s	ITswloop		; se no, salta
		add.l	d0,d1			;Calcola pun. alla testata della seconda texture dello switch
		move.l	d1,tx_AnimCount(a1)
		move.l	d1,a1
		add.l	d1,tx_Brush(a1)		;Calcola pun. al frame della seconda texture dello switch
		bra.s	ITswloop
ITswout

		rts

;******************************************************************
; Inizializza oggetti

InitObjects

	;***** Inizializza la lista di pun. ai frame e
	;***** la lista di pun. alle varie colonne di ogni frame.
	;***** Inoltre inizializza i pun. alle immagini
	;***** degli oggetti delle armi.

		move.l	ObjectImages(a5),a0
		addq.l	#4,a0
IObjloop0	move.l	(a0)+,d0	;Legge pun. prossimo oggetto
		beq.s	IObjout0	;Se=0, fine
		move.l	d0,a3

		move.b	o_objtype(a3),d1
		cmp.b	#4,d1		;L'oggetto  un proiettile ?
		bne.s	IObjnoshot	; Se no, salta
		move.b	o_param7(a3),d1
		ext.w	d1
		lea	GunObj1(a5),a4
		move.l	a3,(a4,d1.w*4)	; Se si, inizializza il pun. all'arma
		bra.s	IObjok1
IObjnoshot	cmp.b	#5,d1		;L'oggetto  una esplosione?
		bne.s	IObjnoexpl	; Se no, salta
		move.w	o_param1(a3),d1
		lea	ExplObj1(a5),a4
		move.l	a3,(a4,d1.w*4)	; Se si, inizializza il pun. all'esplosione
IObjnoexpl
IObjok1		add.l	d0,o_currentframe(a3)
		clr.l	d1
		lea	o_frameslist(a3),a2	;a2=pun. alla lista di pun. ai frame per l'oggetto corrente
IObjloop1	move.l	(a2),d0		;Legge offset prossimo frame
		beq.s	IObjloop0	;Se=0, oggetto finito
		add.l	a3,d0
		move.l	d0,(a2)+
		cmp.l	d1,d0
		beq.s	IObjloop1
		move.l	d0,d1
		move.l	d0,a1		;a1=pun. frame
		move.w	(a1)+,d7	;d7=object width
		addq.l	#6,a1		;a1=pun. lista offset colonne immagine
		subq.w	#1,d7
IObjloopc	add.l	d0,(a1)+	;Somma all'offset il puntatore
		dbra	d7,IObjloopc
		bra.s	IObjloop1
IObjout0


	;***** Inizializza pun. ai sound

		move.l	ObjectImages(a5),a0
		addq.l	#4,a0
IObjloopsnd0	move.l	(a0)+,d0	;Legge pun. prossimo oggetto
		beq.s	IObjoutsnd	;Se=0, fine
		move.l	d0,a1

		lea	o_sound1(a1),a1	;a1=Pun. ai nomi dei sound nell'oggetto
		moveq	#2,d7		;Deve elaborare o_sound1, o_sound2 e o_sound3
IObjloopsnd1	move.l	(a1),d0		;d0=nome sound oggetto
		beq.s	IObjnosnd	;Se nome sound=0, salta
		move.l	Sounds(a5),a2	;a2=pun. alla lista dei sound. Per ogni sound ci sono 2 long: la prima con il nome, la seconda con il puntatore
IObjloopsnd2	move.l	(a2),d1		;d1=nome
		beq.s	IObjsndj1	;Se terminata lista sound, esce
		addq.l	#4,a2
		cmp.l	d1,d0		;Confronta i due nomi
		beq.s	IObjsndj1	; Se uguali, salta
		addq.l	#4,a2		; Altrimenti passa al prossimo sound della lista
		bra.s	IObjloopsnd2
IObjsndj1	move.l	(a2),d0		;Legge pun. al sound, oppure 0 se non c' sound
IObjnosnd	move.l	d0,(a1)+	;Scrive il pun. al sound
		dbra	d7,IObjloopsnd1

		bra.s	IObjloopsnd0
IObjoutsnd


	;***** Inizializza tutte le strutture oggetti e
	;***** i pun. per la lista oggetti liberi

		lea	ObjectsPunList(a5),a3	;a3=Pun. alla lista di pun. agli oggetti
		move.l	Objects(a5),a0		;a0=Pun. oggetto attuale
		sub.l	a1,a1			;a1=Pun. oggetto precedente
		lea	obj_SIZE(a0),a2		;a2=Pun. oggetto successivo
		moveq	#1,d6
		move.w	#MAXLEVELOBJECTS-1,d7
		bra.s	IObjinloopi
IObjloopi	move.l	a0,obj_listnext(a1)
IObjinloopi	move.l	a1,obj_listprev(a0)
		move.w	d6,obj_number(a0)	;Numero codice in mappa dell'oggetto
		move.l	a0,(a3)+		;Scrive pun. all'oggetto
		move.l	a0,a1
		move.l	a2,a0
		lea	obj_SIZE(a2),a2
		addq.w	#1,d6
		dbra	d7,IObjloopi
		clr.l	obj_listnext(a1)	;Azzera l'ultimo pun.


	;***** Inizializza le strutture degli oggetti presenti in mappa
	;*****  e la mappa degli oggetti

		move.l	Objects(a5),a0
;		lea	obj_SIZE(a0),a0		;Salta il primo perch inutilizzato
		move.l	Map(a5),a4
		lea	2(a4),a1
		move.l	ObjectImages(a5),a2
		move.l	Blocks(a5),a6
		move.l	ObjectNumber(a5),d7
		bra	IObjnexts

IObjloops	move.l	obj_image(a0),d0
		move.l	(a2,d0.l*4),a3
		move.l	a3,obj_image(a0)
		move.w	o_radius(a3),obj_width(a0)
		move.b	o_objtype(a3),obj_type(a0)
		move.w	o_height(a3),obj_height(a0)
		clr.w	obj_cont1(a0)
		clr.b	obj_rotdir(a0)
		clr.b	obj_playercoll(a0)
		clr.b	obj_status(a0)

		cmp.b	#2,obj_type(a0)		;E' un nemico ?
		bne.s	IObjnotp2
		move.w	#$0f04,obj_cont1(a0)
		move.w	o_param1(a3),d0
		mulu.w	d0,d0
		move.l	d0,obj_attackdist(a0)
		move.b	o_param5(a3),obj_gun(a0)
		move.w	o_param3(a3),obj_strength(a0)
		move.b	o_param7(a3),obj_power(a0)
		clr.w	d0
		move.b	o_param8(a3),d0
		move.b	d0,obj_enemyspeed(a0)
		move.w	d0,obj_speed(a0)
		move.b	o_param9(a3),obj_attackprob(a0)
		move.b	o_param10(a3),obj_subtype(a0)
		clr.b	obj_bmstatus(a0)
;		clr.b	obj_trigblock(a0)
		moveq	#64,d1
		jsr	Rnd
		move.b	d0,obj_attackdelay(a0)
IObjnotp2
		cmp.b	#3,obj_type(a0)		;E' un pick thing ?
		bne.s	IObjnotp3
		move.b	o_param1+1(a3),obj_subtype(a0)
		move.w	o_param2(a3),obj_value(a0)
IObjnotp3
		move.w	obj_x(a0),d0
		move.w	obj_z(a0),d1
		and.l	#GRID_AND_W,d0
		and.l	#GRID_AND_W,d1
		lsr.w	#BLOCK_SIZE_B,d0
		add.w	d1,d1
		or.w	d1,d0		;d0=offset nella mappa
		lea	(a1,d0.w*4),a3
		move.w	obj_number(a0),(a3)	;Scrive nella mappa il numero dell'oggetto
		move.w	d0,obj_mapoffset(a0)
		clr.l	d1
		move.w	(a4,d0.w*4),d1	;d1=Num. blocco su cui si trova l'oggetto
		lsl.l	#5,d1
		lea	(a6,d1.l),a3	;a3=Pun. al blocco
		move.l	a3,obj_blockpun(a0)
		move.w	bl_FloorHeight(a3),obj_y(a0)

		clr.l	obj_blockprev(a0)
		clr.l	obj_blocknext(a0)

		lea	obj_SIZE(a0),a0
IObjnexts	dbra	d7,IObjloops


		clr.l	ObjShots(a5)		;Init. pun. alla lista di oggetti per i proiettili
		clr.l	ObjExplosions(a5)	;Init. pun. alla lista di oggetti per le esplosioni

	;***** Inizializza lista oggetti nemici

		clr.l	ObjEnemies(a5)
		move.l	Objects(a5),a0		;a0=Pun. oggetto attuale
		sub.l	a1,a1			;a1=Pun. oggetto precedente
		lea	obj_SIZE(a0),a2		;a2=Pun. oggetto successivo
		move.l	ObjectNumber(a5),d7
		bra.s	IObjnexten
IObjloopen	move.l	obj_image(a0),a3
		tst.b	o_animtype(a3)		;Test se animazione di tipo -1 (direzionale)
		bge.s	IObjnoen		;Se no, salta
		tst.l	a1			;Pun. obj precedente=0 ?
		bne.s	IObjpreen
		move.l	a0,ObjEnemies(a5)	;Se si, inizializza pun. alla testa della lista
		bra.s	IObjnopreen
IObjpreen	move.l	a0,obj_listnext(a1)
IObjnopreen	move.l	a1,obj_listprev(a0)
		move.l	a0,a1
IObjnoen	move.l	a2,a0
		lea	obj_SIZE(a2),a2
IObjnexten	dbra	d7,IObjloopen

		tst.l	a1			;C'e' almeno un oggetto in lista ?
		beq.s	IObjnessunen		;Se no, salta
		clr.l	obj_listnext(a1)	;Azzera l'ultimo pun.
IObjnessunen

	;***** Inizializza lista oggetti Thing

		clr.l	ObjThings(a5)
		move.l	Objects(a5),a0		;a0=Pun. oggetto attuale
		sub.l	a1,a1			;a1=Pun. oggetto precedente
		lea	obj_SIZE(a0),a2		;a2=Pun. oggetto successivo
		move.l	ObjectNumber(a5),d7
		bra.s	IObjnextth
IObjloopth	tst.b	obj_type(a0)		;Test se oggetto di tipo thing
		bne.s	IObjnoth		;Se no, salta
		tst.l	a1			;Pun. obj precedente=0 ?
		bne.s	IObjpreth
		move.l	a0,ObjThings(a5)	;Se si, inizializza pun. alla testa della lista
		bra.s	IObjnopreth
IObjpreth	move.l	a0,obj_listnext(a1)
IObjnopreth	move.l	a1,obj_listprev(a0)
		move.l	a0,a1
IObjnoth	move.l	a2,a0
		lea	obj_SIZE(a2),a2
IObjnextth	dbra	d7,IObjloopth

		tst.l	a1			;C'e' almeno un oggetto in lista ?
		beq.s	IObjnessunth		;Se no, salta
		clr.l	obj_listnext(a1)	;Azzera l'ultimo pun.
IObjnessunth

	;***** Inizializza lista oggetti Pick Thing

		clr.l	ObjPickThings(a5)
		move.l	Objects(a5),a0		;a0=Pun. oggetto attuale
		sub.l	a1,a1			;a1=Pun. oggetto precedente
		lea	obj_SIZE(a0),a2		;a2=Pun. oggetto successivo
		move.l	ObjectNumber(a5),d7
		bra.s	IObjnextpkth
IObjlooppkth	cmp.b	#3,obj_type(a0)		;Test se oggetto di tipo pick thing
		bne.s	IObjnopkth		;Se no, salta
		tst.l	a1			;Pun. obj precedente=0 ?
		bne.s	IObjprepkth
		move.l	a0,ObjPickThings(a5)	;Se si, inizializza pun. alla testa della lista
		bra.s	IObjnoprepkth
IObjprepkth	move.l	a0,obj_listnext(a1)
IObjnoprepkth	move.l	a1,obj_listprev(a0)
		move.l	a0,a1
IObjnopkth	move.l	a2,a0
		lea	obj_SIZE(a2),a2
IObjnextpkth	dbra	d7,IObjlooppkth

		tst.l	a1			;C'e' almeno un oggetto in lista ?
		beq.s	IObjnessunpkth		;Se no, salta
		clr.l	obj_listnext(a1)	;Azzera l'ultimo pun.
IObjnessunpkth

		move.l	a0,ObjFree(a5)		;Init. pun. alla lista di oggetti liberi


	;***** Traccia sui bordi della mappa oggetti,
	;*****  delle word di valore -1 usate dal raycasting
	;*****  per riconoscere i confini della mappa.

		move.l	Map(a5),a0
		lea	2(a0),a0
		move.l	a0,a1
		add.l	#(((MAP_SIZE-1)*(MAP_SIZE))<<2),a1
		lea	(a0),a2
		lea	((MAP_SIZE-1)<<2)(a0),a3
		move.w	#MAP_SIZE-1,d7
		move.l	#MAP_SIZE<<2,d1
		moveq	#-1,d0
IOMloop		move.w	d0,(a0)
		move.w	d0,(a1)
		move.w	d0,(a2)
		move.w	d0,(a3)
		addq.l	#4,a0
		addq.l	#4,a1
		add.l	d1,a2
		add.l	d1,a3
		dbra	d7,IOMloop

		rts

;******************************************************************

InitTables

		lea	vtable,a0
		clr.l	-vtsize(a0)


	;***** Tabella animazioni muri ed effetti vari

				;***** Azzera effetti attivi

		lea	Effects(a5),a1
		move.w	#((MAX_EFFECT*ef_SIZE)>>2)-1,d7
ITWloopcleare	clr.l	(a1)+
		dbra	d7,ITWloopcleare


				;***** Azzera tutti i puntatori

		lea	TriggerBlockListPun(a5),a1
		move.w	#255,d7
ITWloopcleart	clr.l	(a1)+
		clr.l	(a1)+
		dbra	d7,ITWloopcleart

				;***** Controlla quali trigger number
				;*****  sono usati dalla mappa
		move.l	Blocks(a5),a0
		lea	TriggerBlockListPun(a5),a1

		move.w	-2(a0),d7	;d7=Numero blocchi
		subq.w	#1,d7
		clr.l	d0
ITWloop1	move.b	bl_Trigger(a0),d0	;d0=Trigger
		beq.s	ITWnextblock1a
		move.l	#1,(a1,d0.l*8)		;Segna il trigger number in d0 come usato
ITWnextblock1a	move.b	bl_Trigger2(a0),d0	;d0=Trigger2
		beq.s	ITWnextblock1b
		move.l	#1,(a1,d0.l*8)		;Segna il trigger number in d0 come usato
ITWnextblock1b	lea	bl_SIZE(a0),a0
		dbra	d7,ITWloop1


				;***** Forma le liste di blocchi
				;*****  associate ad ogni trigger number

		lea	TriggerBlockListPun+8(a5),a1
		lea	TriggerBlockList,a2

		moveq	#1,d7
ITWloop2	move.l	(a1)+,d0	;Test if trigger number is used
		beq.s	ITWnexttrig	;jump if no used
		move.l	Blocks(a5),a0
		move.l	a2,-4(a1)	;Save block list pointer
		move.l	a2,a3		;Reserve a longword to the number of blocks in the list
		addq.l	#4,a2
		clr.l	d5		;d5=Block list counter
		move.w	-2(a0),d6	;d6=Number of blocks in the map
		subq.w	#1,d6
ITWloop3	cmp.b	bl_Trigger(a0),d7
		beq.s	ITWblockok
		cmp.b	bl_Trigger2(a0),d7
		bne.s	ITWnextblock2
ITWblockok	move.l	a0,(a2)+	;Insert block pointer into the list
		addq.l	#1,d5		;Increments block list counter
ITWnextblock2	lea	bl_SIZE(a0),a0
		dbra	d6,ITWloop3
		subq.l	#1,d5
		move.l	d5,(a3)		;Write number of blocks-1 in the list of the trigger number d0
ITWnexttrig	addq.l	#4,a1
		addq.w	#1,d7
		cmp.w	#255,d7
		ble.s	ITWloop2



		move.l	BlockEffectList(a5),a0
		lea	BlockEffectListPun(a5),a1

		clr.l	(a1)+

ITWloop4	tst.l	(a0)		;Test se primo effetto lista  < 0
		bmi.s	ITWendeffectlist	;Se si, fine liste effetti ed esce
		move.l	a0,(a1)+	;Scrive puntatore al primo effetto della lista nell'array di puntatori
		tst.l	(a0)		;Test se primo effetto lista  = 0
		beq.s	ITWemptylist	; Se si, la lista  vuota e va alla prossima lista
ITWloop5	lea	10(a0),a0
		tst.l	(a0)		;Testa successivi effetti della lista
		bne.s	ITWloop5	; e continua a farlo finche' non ne trova uno = 0
ITWemptylist	addq.l	#4,a0		;Si sposta sul primo effetto della prossima lista di effetti
		bra.s	ITWloop4	; e continua
ITWendeffectlist



	;***** Tabelle per tracciamento pavimenti e soffitti

		lea	OTablePun,a0
		lea	OTableList,a1
		move.l	#(6<<5),d0
		moveq	#-2,d1
		move.w	#(WINDOW_MAX_HEIGHT-1),d7
ITloop2		move.l	a1,(a0)+
		move.w	d1,(a1)
		add.l	d0,a1
		dbra	d7,ITloop2



		rts

;******************************************************************
;*** Inizializza variabili

InitOthers

	;***** Calcola blocco e pun. blocco su cui parte il player

		moveq	#0,d0
		move.w	CPlayerZ(a5),d0
		and.w	#GRID_AND_W,d0
		move.w	CPlayerX(a5),d1
		lsr.w	#BLOCK_SIZE_B,d1
		add.w	d0,d0
		or.w	d1,d0
		move.l	Map(a5),a0
		move.w	(a0,d0.w*4),d0
		move.w	d0,PlayerBlock(a5)
		move.w	d0,CPlayerBlock(a5)
		move.l	Blocks(a5),a0
		lsl.w	#2,d0
		lea	(a0,d0.w*8),a0	;a0=Pun. blocco su cui si trova il Player
		move.l	a0,PlayerBlockPun(a5)
		move.l	a0,CPlayerBlockPun(a5)


	;***** Init variabili varie

		clr.l	LookHeight(a5)

	;***** Init armi

		lea	GunObj1(a5),a1
		sub.l	a2,a2
		moveq	#0,d1
		move.w	PlayerActiWeapon(a5),d0
		bmi.s	IOweapj1
		move.l	(a1,d0.w*4),a2			;a2=pun. all'oggetto shot
		move.b	o_param10(a2),d1		;d1=Stato autofire
IOweapj1	move.l	a2,PlayerWeaponPun(a5)
		move.b	d1,PlayerWeaponAuto(a5)

		rts

;**********************************************************************
; Inizializza tutto cio' che ha a che vedere con la finestra a video

InitView

		move.l	#1,clear_bitmap1(a5)
		move.l	#1,clear_bitmap2(a5)
		move.l	#1,clear_bitmap3(a5)



; Init chunky to planar conversion

		move.l	ChunkyBuffer(a5),a0	;a0=pun. to chunky
		move.l	pixel_type(a5),a1	;a1=conversion mode
		move.l	sigbit1(a5),d2
		moveq	#1,d0
		lsl.l	d2,d0			;d0=1 << sigbit1
		move.l	sigbit2(a5),d2
		moveq	#1,d1
		lsl.l	d2,d1			;d1=1 << sigbit2
		move.l	window_width(a5),d2	;d2=width
		move.l	window_height(a5),d3	;d3=height
		move.l	#0,d4			;d4=byte offset
		move.l	c2pBuffer1(a5),d5	;d5=pun. to buffer1
		move.l	c2pBuffer2(a5),d6	;d6=pun. to buffer2
		move.l	#SCREEN_WIDTH,d7	;d7=screen width
		move.l	gfxbase(a5),a3		;a3=GfxBase
		jsr	c2p8_init

		move.l	window_width(a5),source_width(a5)

		move.w	#200,scorey(a5)
		move.l	pixel_type(a5),d0
;		btst	#1,d0			;Test height of the pixel
;		beq.s	IVnodoubleh
;		move.w	#100,scorey(a5)
;IVnodoubleh
		move.l	oldpixeltype(a5),d1
		eor.l	d0,d1
		btst	#1,d1			;Test se cambiata dimensione verticale pixel
		beq.s	IVcont			; se no, salta
		move.l	d0,oldpixeltype(a5)

		btst	#1,d0			;Test nuova dimensione verticale pixel
		bne.s	IVnodoub		; se 1x2 o 2x2, salta
		moveq	#-1,d0
		move.w	CurrBuffer+2(a5),d0
		move.l	d0,changeres(a5)	;Segnala in quale frame cambiare risoluzione
		bra.s	IVcont
IVnodoub
		bsr	ChangePixelHeight


IVcont
	;***** Tabella offset righe fake chunky pixel screen

		lea	Yoffset(a5),a0
		move.l	source_width(a5),d1
		move.w	window_height+2(a5),d7
		clr.l	d0
		subq.w	#1,d7
IVloopoffset	move.l	d0,(a0)+
		add.l	d1,d0
		dbra	d7,IVloopoffset

IVout
		rts

;**********************************************************************
; Cambia dimensioni verticali dei pixel

		xdef	ChangePixelHeight

ChangePixelHeight

		EXECBASE
		CALLSYS	Forbid

;		move.l	myCopList2(a5),a0
		move.l	screen_viewport(a5),a3
		move.l	pixel_type(a5),d0	;Test height of the pixel
		btst	#1,d0
		beq.s	CPHnodoubleh

		move.l	myCopList2(a5),vp_UCopIns(a3)
		bra.s	CPHdoubleh
CPHnodoubleh
		move.l	myCopList1(a5),vp_UCopIns(a3)
CPHdoubleh

		CALLSYS	Permit

		GFXBASE

		INTUITIONBASE
		CALLSYS	RethinkDisplay

;		move.l	IntuitionView(a5),a0
;		move.l	screen_viewport(a5),a1
;		CALLSYS	MakeVPort
;		move.l	IntuitionView(a5),a1
;		CALLSYS	MrgCop
;		move.l	IntuitionView(a5),a1
;		CALLSYS	LoadView

		GFXBASE
;		CALLSYS	WaitTOF

		GFXBASE
		jsr	TurnOffMousePointer

CPHout
		rts

;**********************************************************************
;
		xdef	ClearCurrentBitmap

ClearCurrentBitmap

		lea	background(pc),a1
		move.l	CurrentBitmap(a5),a3
		moveq	#7,d6		;d6=contatore bitplanes
CBclearloop0	move.l	(a3)+,a0
		lea	5120(a0),a2
		move.w	#71,d7
CBclearloop1	move.l	(a1)+,d0
		move.l	(a1)+,d1
		move.l	(a1)+,d2
		move.l	(a1)+,d3
		move.l	d0,(a0)+
		move.l	d1,(a0)+
		move.l	d2,(a0)+
		move.l	d3,(a0)+
		move.l	d0,(a0)+
		move.l	d1,(a0)+
		move.l	d2,(a0)+
		move.l	d3,(a0)+
		move.l	d0,(a0)+
		move.l	d1,(a0)+
		move.l	d0,(a2)+
		move.l	d1,(a2)+
		move.l	d2,(a2)+
		move.l	d3,(a2)+
		move.l	d0,(a2)+
		move.l	d1,(a2)+
		move.l	d2,(a2)+
		move.l	d3,(a2)+
		move.l	d0,(a2)+
		move.l	d1,(a2)+
		dbra	d7,CBclearloop1
		move.w	#55,d7
CBclearloop2	move.l	(a1)+,d0
		move.l	(a1)+,d1
		move.l	(a1)+,d2
		move.l	(a1)+,d3
		move.l	d0,(a0)+
		move.l	d1,(a0)+
		move.l	d2,(a0)+
		move.l	d3,(a0)+
		move.l	d0,(a0)+
		move.l	d1,(a0)+
		move.l	d2,(a0)+
		move.l	d3,(a0)+
		move.l	d0,(a0)+
		move.l	d1,(a0)+
		dbra	d7,CBclearloop2
		dbra	d6,CBclearloop0

		rts
;------------
;		move.l	CurrentBitmap(a5),a1
;
;		clr.l	d0
;
;		moveq	#7,d7
;CCBloop0	move.l	(a1)+,a0	;Bitplane pointer
;		move.w	#499,d6
;CCBloop1	move.l	d0,(a0)+
;		move.l	d0,(a0)+
;		move.l	d0,(a0)+
;		move.l	d0,(a0)+
;		dbra	d6,CCBloop1
;		dbra	d7,CCBloop0
;
;		rts
;


;**********************************************************************
;* Effetto per teletrasporto

Fade
		move.l	ChunkyBuffer(a5),a0		;a0=pun. fake chunky
		move.w	TransEffect(a5),d0
		lea	LightingTable(a5),a1		;a1=Pun. alla lighting table
		btst	#0,TEtype(a5)			;Test tipo fade
		beq.s	Fnofog				;Se tipo black, salta
		lea	8192(a1),a1
Fnofog		lea	(a1,d0.w),a1

		move.l	Canimcounter(a5),d1		;Numero di 50esimi passati dall'ultima volta
		cmp.l	#32,d1				;Test se maggiore del dovuto
		ble.s	Facok
		moveq	#32,d1
Facok		lsl.l	#8,d1				;Moltiplica per 256

		tst.b	TEdir(a5)			;Test direzione fade
		beq.s	Fup

Fdown		sub.w	d1,d0				;Fade down
		bgt.s	Fok				;Se>0, tutto ok
		bra.s	Fend				; Altrimenti finisce

Fup		add.w	d1,d0				;Fade up
		cmp.w	#8192,d0
		blt.s	Fok				;Se<8192, tutto ok
		move.w	#8192-256,d0			; Altrimenti inizializza fade down
		btst	#1,TEtype(a5)			;Se una sola direzione,
		bne.s	Fok				; Salta
		st	TEdir(a5)

Fok		move.w	d0,TransEffect(a5)

		move.l	window_size(a5),d7
		lsr.l	#2,d7
		subq.w	#1,d7
		moveq	#0,d0
		bra.s	Floop1

		cnop	0,8

Floop1		move.b	(a0),d0
		move.b	(a1,d0.w),(a0)+
		move.b	(a0),d0
		move.b	(a1,d0.w),(a0)+
		move.b	(a0),d0
		move.b	(a1,d0.w),(a0)+
		move.b	(a0),d0
		move.b	(a1,d0.w),(a0)+
		dbra	d7,Floop1

		rts

Fend		clr.w	TransEffect(a5)
		clr.b	TEdir(a5)
		tst.b	EndLevelFade(a5)
		bne.s	Fret
		move.b	#1,ProgramState(a5)
Fret		rts

;**********************************************************************
; Inizializzazione del pannello inferiore

PanelSetup
		lea	panelpic(pc),a1
		move.l	planes_bitmap1(a5),a2
		moveq	#7,d6		;d6=contatore bitplanes
PScopyloop0	move.l	(a2)+,a0
		lea	8000(a0),a0
		move.w	#((320*40)>>6)-1,d7
PScopyloop1	move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		dbra	d7,PScopyloop1
		dbra	d6,PScopyloop0

;		lea	panelpic(pc),a1
;		move.l	planes_bitmap2(a5),a2
;		moveq	#7,d6		;d6=contatore bitplanes
;PScopyloop2	move.l	(a2)+,a0
;		lea	8000(a0),a0
;		move.w	#((320*40)>>6)-1,d7
;PScopyloop3	move.l	(a1)+,(a0)+
;		move.l	(a1)+,(a0)+
;		dbra	d7,PScopyloop3
;		dbra	d6,PScopyloop2

;		lea	panelpic(pc),a1
;		move.l	planes_bitmap3(a5),a2
;		moveq	#7,d6		;d6=contatore bitplanes
;PScopyloop4	move.l	(a2)+,a0
;		lea	8000(a0),a0
;		move.w	#((320*40)>>6)-1,d7
;PScopyloop5	move.l	(a1)+,(a0)+
;		move.l	(a1)+,(a0)+
;		dbra	d7,PScopyloop5
;		dbra	d6,PScopyloop4

		rts

;**********************************************************************
;* Inizializza mirino

		xdef	InitSight

InitSight	movem.l	d0-d7/a0-a6,-(sp)

		lea	Sprites+(4<<2)(a5),a2

		lea	mirino01(pc),a1

		moveq	#1,d6
ISloop1		move.l	(a2)+,a0
		move.l	(a0),a0
		lea	16(a0),a0	;a0=Pun. dati grafici sprite 4
		moveq	#((64*11*2)>>5)-1,d7
		tst.w	SightState(a5)
		beq.s	ISclear
ISloop2		move.l	(a1)+,(a0)+	;Copia sprite
		dbra	d7,ISloop2
		bra.s	ISnext
ISclear		clr.l	(a0)+		;Del sprite
		dbra	d7,ISclear
ISnext		dbra	d6,ISloop1

		movem.l	(sp)+,d0-d7/a0-a6
		rts

;**********************************************************************
;* Spegne mirino
;
;		xdef	TurnOffSight
;
;TurnOffSight
;		lea	Sprites+(4<<2)(a5),a2
;
;		moveq	#1,d6
;TOFFSloop1	move.l	(a2)+,a0
;		move.l	(a0),a0
;		lea	16(a0),a0	;a0=Pun. dati grafici sprite 4
;		moveq	#((64*11*2)>>5)-1,d7
;TOFFSloop2	clr.l	(a0)+
;		dbra	d7,TOFFSloop2
;		dbra	d6,TOFFSloop1
;
;		rts

;**********************************************************************
;* Sostituisce tutti gli sprite attivi con lo sprite nullo

		xdef	TurnOffSprites
TurnOffSprites
		movem.l	d0-d7/a0-a6,-(sp)
		GFXBASE
		jsr	TurnOffMousePointer
		lea	Sprites+4(a5),a4
		moveq	#6,d7
TOFspritesloop	move.l	(a4)+,d0
		beq.s	TOFspritenext
		move.l	d0,a1
		move.l	screen_viewport(a5),a0
		move.l	28(a4),a2		;a2=Pun. al null-sprite
		lea	nulltaglist(pc),a3
		CALLSYS	ChangeExtSpriteA
TOFspritenext	dbra	d7,TOFspritesloop
TOFspriteout
		movem.l	(sp)+,d0-d7/a0-a6
		rts


;* Da chiamare solo dopo aver chiamato TurnOffSprites.
;* Ripristina gli sprite originari

		xdef	TurnOnSprites
TurnOnSprites
		movem.l	d0-d7/a0-a6,-(sp)
		GFXBASE
		jsr	TurnOffMousePointer
		lea	Sprites+4(a5),a4
		moveq	#6,d7
TONspritesloop	move.l	(a4)+,d0
		beq.s	TONspritenext
		move.l	d0,a2
		move.l	screen_viewport(a5),a0
		move.l	28(a4),a1		;a1=Pun. al null-sprite
		lea	nulltaglist(pc),a3
		CALLSYS	ChangeExtSpriteA
TONspritenext	dbra	d7,TONspritesloop
TONspriteout
		movem.l	(sp)+,d0-d7/a0-a6
		rts


nulltaglist	dc.l	TAG_END,0


;****************************************************************************
;* Se cambiato schermo accende/spegne gli sprite

		xdef	TestChangeScreen
TestChangeScreen
		move.b	ScreenActive(a5),d0
		cmp.b	OldScreenActive(a5),d0	;Test se cambiato schermo Intuition
		beq.s	Tnochangescreen		; Se no, salta
		move.b	d0,OldScreenActive(a5)
		tst.b	d0
		beq.s	Tsproff
		bsr	TurnOnSprites
		bra.s	Tnochangescreen
Tsproff		bsr	TurnOffSprites
Tnochangescreen
		rts

;****************************************************************************
;*** Manda a video la palette puntata da a0.
;*** Tale palette  nel formato RGB 8bit, e viene trasformata
;*** nel formato adatto a LoadRGB32.

		xdef	LoadPalette

LoadPalette	move.l	a2,-(sp)

		lea	PaletteRGB32+4,a1
		move.w	#255,d0
LPloop		move.b	(a0)+,(a1)
		move.b	(a0)+,4(a1)
		move.b	(a0)+,8(a1)
		lea	12(a1),a1
		dbra	d0,LPloop

		move.l	screen_viewport(a5),a0
		lea	PaletteRGB32,a1
		GFXBASE
		CALLSYS	LoadRGB32

		move.l	(sp)+,a2
		rts

;****************************************************************************
;* Azzera la palette e la manda a video

		xdef	ResetPalette

ResetPalette
		lea	PaletteRGB32+4,a0
		move.w	#(256*3)-1,d0
RPloopP		clr.l	(a0)+
		dbra	d0,RPloopP

		move.l	screen_viewport(a5),a0
		lea	PaletteRGB32,a1
		GFXBASE
		CALLSYS	LoadRGB32
		
		rts

;****************************************************************************
;* Subroutine per calcolare i pun. nella dir. dei livelli
;* al game e al level corrente.
;* Se il level corrente non  definito nel game corrente,
;* passa al primo level del prossimo game.
;* Se il game corrente non  definito, segnala che il gioco  finito.
;* Quindi questa routine  utile anche per passare al prossimo
;* livello del game corretto.

GetLevelNames
		move.l	LevelsDirPun(a5),a0

		move.w	CurrentGame(a5),d7
		cmp.w	NumGames(a5),d7		;Confronta con il num. totale di game
		bgt	GLNendgame		; Se >, allora  finito il gioco

		subq.w	#1,d7
		bra.s	GLNnext1
GLNloop1	move.w	(a0)+,d0	;Legge num. livelli game
		mulu.w	#24,d0
		lea	20(a0,d0.l),a0	;Salta al prossimo game
GLNnext1	dbra	d7,GLNloop1

		move.l	a0,PunGame(a5)	;Pun. al game corrente nella dir

		move.w	CurrentLevel(a5),d0
		cmp.w	(a0)+,d0		;Confronta con il num. di livelli del game
		ble.s	GLNoklev		; Se <=, ok
		move.w	CurrentGame(a5),d1	;Altrimenti,
		addq.w	#1,CurrentGame(a5)	;Passa al prossimo game
		move.w	#1,CurrentLevel(a5)	;Seleziona livello 1 del nuovo game
		bra.s	GetLevelNames		;Ripete tutto
GLNoklev	subq.w	#1,d0
		mulu.w	#24,d0
		lea	20(a0,d0.l),a0	;Salta al level corrente

		move.l	a0,PunLevel(a5)	;Pun. nella dir. al level corrente

		rts

GLNendgame
		st	EndGame(a5)		;Segnala che  finito il gioco
		rts

;***********************************************************************
;* Restituisce in d0 il primo tasto premuto presente nella coda di input.
;* Restituisce -1 se non c'e' nessun tasto

		xdef	ReadKey

ReadKey		movem.l	d1/a0,-(sp)

		lea	KeyQueueIndex1(a5),a0
		move.l	(a0)+,d1		;d1=KeyQueueIndex1
		cmp.l	(a0)+,d1		;Confronta con KeyQueueIndex2
		beq	RKnokey			;Se sono uguali, allora la coda  vuota
		move.w	(a0,d1.l),d0		;d0=scancode tasto
		addq.l	#2,d1			;Sposta l'indice
		and.w	#$7f,d1			;Assicura la circolarit dell'indice
		move.l	d1,KeyQueueIndex1(a5)	;Memorizza l'indice
		bra.s	RKout

RKnokey		moveq	#-1,d0
RKout		movem.l	(sp)+,d1/a0
		rts


;**********************************************************************
;* Inizializza coda tasti premuti

		xdef	InitKeyQueue
InitKeyQueue
		clr.l	KeyQueueIndex1(a5)
		clr.l	KeyQueueIndex2(a5)

		rts

;**********************************************************************

panelpic	incbin	"Graphic/Panel04.raw"
background	incbin	"Graphic/Background01.raw"
mirino01	incbin	"Graphic/Mirino01.raw"


;**********************************************************************

	
	section	__MERGED,BSS


		cnop	0,4


		xdef	ProgramState,MusicState,ScreenActive,OldScreenActive

ProgramState	ds.b	1	;Stato programma:
				;	-1: Gioco congelato (viene effettuato solo il rendering, ma non il movimento di nemici e player)
				;	    Usato durante i fade di inizio e fine gioco e durante il teletrasporto
				;	0 : Presentazione
				;	1 : Gioco

MusicState	ds.b	1	;Stato musica: (FALSE=non attiva; TRUE=attiva)

ScreenActive	ds.b	1	;Se<>0, lo schermo di gioco  quello attivo
OldScreenActive	ds.b	1	;ScreenActive al frame precedente

		xdef	FirstMatchLevel

FirstMatchLevel	ds.b	1	;Se<>0, si sta inizializzando il primo livello della partita

		ds.b	1	;Usato per allineare

EndLevelFade	ds.b	1	;Se<>0,  in esecuzione il fade di fine livello (perch finito livello o perch morto)
EndLevelCont	ds.b	1	;Contatore ritardo fine livello


		cnop	0,4

		xdef	NumGames,CurrentGame,CurrentLevel,NumLevels
		xdef	PunGame,PunLevel,Retries

NumGames	ds.w	1	;Numero di games
CurrentGame	ds.w	1	;Game corrente
CurrentLevel	ds.w	1	;Livello corrente
NumLevels	ds.w	1	;Numero di livelli del game corrente

PunGame		ds.l	1	;Pun. nella dir. al game corrente
PunLevel	ds.l	1	;Pun. nella dir. al level corrente

Retries		ds.b	1	;Numero di tentativi ancora a disposizione

		ds.b	1	;Usato per allineare


savesightstate	ds.w	1

		cnop	0,4

		xdef	pause,Escape,EscKey,PlayerDeath,showmap,PlayAgain
		xdef	TransEffect,TEdir

pause		ds.w	1	;Se<>0, il gioco va in pausa
showmap		ds.b	1	;Se<>0, mostra la mappa
Escape		ds.b	1	;Se<>0, bisogna uscire dal ciclo principale
EscKey		ds.b	1	;Se<>0, l'utente ha premuto Esc per uscire dal gioco
PlayerDeath	ds.b	1	;Se<>0, il player  morto
EndGame		ds.b	1	;Se<>0,  finito il gioco
PlayAgain	ds.b	1	;Se<>0, riparte da un livello gi giocato (anche per gestione codici livello)
gopause		ds.b	1	;Se<>0, l'utente ha cambiato schermo e il gioco deve andare in pausa

		ds.b	3	;Usato per allineare

	;*** !!! ATTENZIONE !!! NON SEPARARE I SEGUENTI 3 CAMPI
TransEffect	ds.w	1	;Se<>0,  il contatore dell'effetto teletrasporto
TEdir		ds.b	1	;Direzione effetto: FALSE=sale; TRUE=scende
TEtype		ds.b	1	;Tipo effetto:
				;	bit 0 : FALSE=black fade
				;		TRUE=fog fade
				;	bit 1 : FALSE=doppia direzione (sale/scende)
				;		TRUE=singola direzione



		cnop	0,4

framerate	ds.w	1	; Numero frame al secondo

	xdef	times
times		ds.l	4	; Microsecondi impiegati dalle varie sezioni di codice. Usato per testing


scorey		ds.w	1	; Coordinata y della sezione di schermo relativa ai punteggi

storecount	ds.l	1	; animcounter precedente

		cnop	0,4

	xdef	CurrentBitmap
	xdef	planes_bitmap1,planes_bitmap2,planes_bitmap3

planes_bitmap1	ds.l	1	;Pun. all'array di pun. ai piani di bit della bitmap1, oppure Pun. al primo chunky buffer su scheda video
planes_bitmap2	ds.l	1	;Pun. all'array di pun. ai piani di bit della bitmap2, oppure Pun. al secondo chunky buffer su scheda video
planes_bitmap3	ds.l	1	;Pun. all'array di pun. ai piani di bit della bitmap3, oppure Pun. al terzo chunky buffer su scheda video
CurrentBitmap	ds.l	1
clear_bitmap1	ds.l	1
clear_bitmap2	ds.l	1
clear_bitmap3	ds.l	1
CurrentClear	ds.l	1

changeres	ds.l	1	;Nel caso di passaggio da pixel alti 2 a pixel alti 1,
				; segnala in questa variabile a quale frame cambiare risoluzione

	xdef	CurrBuffer

SafeToChange	ds.w	1
SafeToWrite	ds.w	1
CurrBuffer	ds.l	1

		cnop	0,4

ChunkyStartOffset	ds.l	1	;Offset al primo byte della finestra su uno schermo chunky pixel reale.
CurrentChunkyBuffer	ds.l	1	;Pun. al buffer corrente in chunky pixel

realwindow_width	ds.l	1	;Width reale della finestra. Ad es. se window_width=160 e i pixel sono larghi 2, realwindow_width=320
realwindow_height	ds.l	1	;Height reale della finestra.

		cnop	0,4

		xdef	CurrentBuffer,SelectedSize,oldpixeltype

CurrentBuffer	ds.l	1	;Pun. al buffer corrente

SelectedSize	ds.l	1	;Offset nella tabella ViewSizeTable per la dimensione correntemente selezionata della finestra

oldpixeltype	ds.l	1

;---------------

	xdef	Blocks,Edges,BlockEffectList,Map
	xdef	Textures,FirstTexture
	xdef	ObjectImages,FirstObjectImage
	xdef	Sounds,FirstSound

Blocks		ds.l	1	;Pun. alle definizioni dei blocchi
Edges		ds.l	1	;Pun. alle definizioni delle facce dei blocchi
BlockEffectList	ds.l	1	;Pun. alle liste di effetti
Map		ds.l	1	;Pun. alla mappa
Textures	ds.l	1	;Pun. alla lista di pun. alle textures
FirstTexture	ds.l	1	;Pun. alla prima texture della lista
ObjectImages	ds.l	1	;Pun. alla lista di pun. agli oggetti
FirstObjectImage ds.l	1	;Pun. al primo oggetto della lista
Sounds		ds.l	1	;Pun. alla lista di pun. a sounds e mods
FirstSound	ds.l	1	;Pun. al primo sound della lista

		xdef	PTModule

PTModule	ds.l	1	;Pun. al modulo musicale


		xdef	PlayerWeapons,PlayerActiWeapon
		xdef	PlayerWeaponAuto
		xdef	PlayerWeaponPun,PlayerBuyWeapon
		xdef	WeaponOsc,WeaponOscDir

PlayerWeapons	ds.b	8	;Un byte per ogni arma del player:
				;se=0, l'arma non  posseduta
				;se=1, l'arma  ad efficienza 1
				;se=2, l'arma  ad efficienza 2
				;se=3, l'arma  ad efficienza 3

PlayerActiWeapon ds.w	1	;Arma attiva del player	(Se=-1, nessuna arma)

PlayerWeaponAuto ds.w	1	;TRUE, se l'arma ha l'autofire

PlayerWeaponPun  ds.l	1	;Pun. all'immagine dell'oggetto dell'arma attiva

PlayerBuyWeapon	ds.w	1	;Se<>-1, ultima arma acquistata da terminale

		ds.w	1	;Usato per allineare


	;*** !!! ATTENZIONE !!! NON SPOSTARE I SEGUENTI CAMPI
WeaponOsc	ds.w	1	;Oscillazione lanciafiamme
WeaponOscDir	ds.w	1	;Direzione oscillazione lanciafiamme


	xdef	GunObj1,GunObj2,GunObj3,GunObj4,GunObj5

GunObj1		ds.l	1	;Pun. immagini degli oggetti per l'arma 1
GunObj2		ds.l	1	;Pun. immagini degli oggetti per l'arma 2
GunObj3		ds.l	1	;Pun. immagini degli oggetti per l'arma 3
GunObj4		ds.l	1	;Pun. immagini degli oggetti per l'arma 4
GunObj5		ds.l	1	;Pun. immagini degli oggetti per l'arma 5
GunObj6		ds.l	1	;Pun. immagini degli oggetti per l'arma 6
GunObj7		ds.l	1	;Pun. immagini degli oggetti per l'arma 7
GunObj8		ds.l	1	;Pun. immagini degli oggetti per l'arma 8
GunObj9		ds.l	1	;Pun. immagini degli oggetti per l'arma 9
GunObj10	ds.l	1	;Pun. immagini degli oggetti per l'arma 10
GunObj11	ds.l	1	;Pun. immagini degli oggetti per l'arma 11
GunObj12	ds.l	1	;Pun. immagini degli oggetti per l'arma 12
GunObj13	ds.l	1	;Pun. immagini degli oggetti per l'arma 13
GunObj14	ds.l	1	;Pun. immagini degli oggetti per l'arma 14
GunObj15	ds.l	1	;Pun. immagini degli oggetti per l'arma 15
GunObj16	ds.l	1	;Pun. immagini degli oggetti per l'arma 16
GunObj17	ds.l	1	;Pun. immagini degli oggetti per l'arma 17
GunObj18	ds.l	1	;Pun. immagini degli oggetti per l'arma 18

	xdef	ExplObj1,ExplObj2,ExplObj3,ExplObj4,ExplObj5

ExplObj1	ds.l	1	;Pun. immagini esplosione tipo 1
ExplObj2	ds.l	1	;Pun. immagini esplosione tipo 2
ExplObj3	ds.l	1	;Pun. immagini esplosione tipo 3
ExplObj4	ds.l	1	;Pun. immagini esplosione tipo 4
ExplObj5	ds.l	1	;Pun. immagini esplosione tipo 5


	xdef	GlobalSound0,GlobalSound1,GlobalSound2,GlobalSound3
	xdef	GlobalSound4,GlobalSound5,GlobalSound6,GlobalSound7
	xdef	GlobalSound8,GlobalSound9,GlobalSound10

GlobalSound0	ds.l	1	;Pun. al global sound 0
GlobalSound1	ds.l	1	;Pun. al global sound 1
GlobalSound2	ds.l	1	;Pun. al global sound 2
GlobalSound3	ds.l	1	;Pun. al global sound 3
GlobalSound4	ds.l	1	;Pun. al global sound 4
GlobalSound5	ds.l	1	;Pun. al global sound 5
GlobalSound6	ds.l	1	;Pun. al global sound 6
GlobalSound7	ds.l	1	;Pun. al global sound 7
GlobalSound8	ds.l	1	;Pun. al global sound 8
GlobalSound9	ds.l	1	;Pun. al global sound 9
GlobalSound10	ds.l	1	;Pun. al global sound 10

		cnop	0,4

; define our own _custom symbol to not have to link against amiga.lib
		org 0xDFF000
		xdef _custom
_custom		ds.l	1

	end
