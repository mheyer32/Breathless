;****************************************************************************
;*
;*	Loaders.asm
;*
;*	Routines per il caricamento da disco dei file dati
;*	(mappe, grafica, sonoro, etc...)
;*
;****************************************************************************

	include 'System'
	include 'TMap.i'

;****************************************************************************

		xref	execbase,dosbase,gfxbase,intuitionbase
		xref	LightingTable
		xref	MapPun,GfxPun,FreeGfxPun,SndPun
		xref	TexturesDirPun,TexturesDirLen
		xref	ObjectsDirPun,ObjectsDirLen
		xref	SoundsDirPun,SoundsDirLen
		xref	GfxDirPun,GfxDirLen
		xref	LevelsDirPun,LevelsDirLen
		xref	c2pBuffer1,c2pBuffer2
		xref	Map,Blocks,Edges,BlockEffectList
		xref	Textures,FirstTexture
		xref	ObjectImages,FirstObjectImage
		xref	Objects,ObjectNumber
		xref	Sounds,FirstSound,SoundsNumber
		xref	CPlayerX,CPlayerZ,CPlayerHeading
		xref	NumGames,CurrentGame,CurrentLevel,NumLevels
		xref	PunGame,PunLevel
		xref	GlobalSound0,GlobalSound1,GlobalSound2,GlobalSound3
		xref	GlobalSound4,GlobalSound5,GlobalSound6,GlobalSound7
		xref	GlobalSound8,GlobalSound9,GlobalSound10
		xref	Palette,LightingTable
		xref	PresModName
		xref	PresPicName1,PresPicName2,PresPicName3
		xref	ActualScr,DiskReqFlag
		xref	WindowSize,PixelSize,SightState
		xref	MusicVolume,FilterState,MusicOnOff
		xref	LevelCodeASC
		xref	pixel_type,SelectedSize
		xref	K_ForwardKey,K_BackwardKey,K_RotateLeftKey,K_RotateRightKey
		xref	K_SideLeftKey,K_SideRightKey,K_FireKey,K_AccelKey
		xref	K_ForceSideKey,K_LookUpKey,K_ResetLookKey,K_LookDownKey
		xref	K_SwitchKey
		xref	M_ForwardKey,M_BackwardKey,M_RotateLeftKey,M_RotateRightKey
		xref	M_SideLeftKey,M_SideRightKey,M_FireKey,M_AccelKey
		xref	M_ForceSideKey,M_LookUpKey,M_ResetLookKey,M_LookDownKey
		xref	M_SwitchKey
		xref	ActiveControl,MouseSensitivity
		xref	PlayerWalkSpeed,PlayerRunSpeed
		xref	PlayerRotWalkSpeed,PlayerRotRunSpeed
		xref	PlayerAccel,PlayerRotAccel

		xref	OpenCustom
		xref	UnPack
		xref	LoadingScreen,DiskRequest,RestoreDR

;****************************************************************************

		xdef	ReadConfig
		xdef	WriteConfig

		xdef	LoadLevelData

		xdef	ReadMainGLD
		xdef	ReadTexturesDir
		xdef	ReadObjectsDir
		xdef	ReadSoundsDir
		xdef	ReadGfxDir

		xdef	LoadPic
		xdef	LoadMod
		xdef	ReadTextures
		xdef	ReadObjects
		xdef	ReadSounds
		xdef	ReadMapGLD
		xdef	CheckDisk
;		xdef	LoadData

;****************************************************************************
; Routine di lettura configurazione gioco
; La lettura/scrittura della configurazione non è permessa sui dischetti
; Restituisce d0=0 se tutto ok

ReadConfig

		lea	configname(pc),a2

		bsr	Stampa		;stampa nome

		DOSBASE
		move.l	a2,d1		;Nome
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		beq	RCout		;Esce senza errori se non c'è il file
		move.l	d0,a4		;Conserva in a4 il pun. al file

		move.l	a4,d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge Id

		cmp.l	#$434f4e31,InputData(a5)	;Test se ID = "CON1"
		beq.s	RCidok
		lea	errmes8,a2
		bsr	Stampa
		bra	ErrorQuit
RCidok

		lea	ConfigVarPointers(pc),a3
RCloop		move.l	(a3)+,d2
		beq.s	RCloopout

		move.l	a4,d1
		moveq	#2,d3
		CALLSYS	Read

		bra.s	RCloop
RCloopout
		move.w	PixelSize(a5),pixel_type+2(a5)
		move.w	WindowSize(a5),d1
		lsl.w	#2,d1
		move.w	d1,SelectedSize+2(a5)

RCclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close

RCout
		clr.l	d0
		rts


;*** Lista di puntatori alle variabili salvate nel file di configurazione.
;*** Le variabili sono tutte word. Per variare la struttura del
;*** file di configurazione basta aggiungere o togliere un puntatore.

ConfigVarPointers
		dc.l	LevelCodeASC,LevelCodeASC+2,LevelCodeASC+4,LevelCodeASC+6
		dc.l	LevelCodeASC+8,LevelCodeASC+10,LevelCodeASC+12,LevelCodeASC+14

		dc.l	WindowSize,PixelSize,SightState
		dc.l	MusicVolume,MusicOnOff,FilterState

		dc.l	K_ForwardKey,K_BackwardKey,K_RotateLeftKey
		dc.l	K_RotateRightKey,K_SideLeftKey,K_SideRightKey
		dc.l	K_FireKey,K_AccelKey,K_ForceSideKey,K_LookUpKey
		dc.l	K_ResetLookKey,K_LookDownKey,K_SwitchKey

		dc.l	M_ForwardKey,M_BackwardKey,M_RotateLeftKey
		dc.l	M_RotateRightKey,M_SideLeftKey,M_SideRightKey
		dc.l	M_FireKey,M_AccelKey,M_ForceSideKey,M_LookUpKey
		dc.l	M_ResetLookKey,M_LookDownKey,M_SwitchKey

		dc.l	ActiveControl,MouseSensitivity

		dc.l	PlayerWalkSpeed,PlayerRunSpeed
		dc.l	PlayerRotWalkSpeed,PlayerRotRunSpeed
		dc.l	PlayerAccel,PlayerRotAccel

		dc.l	0

;****************************************************************************
; Routine di scrittura configurazione gioco
; La lettura/scrittura della configurazione non è permessa sui dischetti

WriteConfig
		lea	configname(pc),a2

		bsr	Stampa		;stampa nome

		DOSBASE
		move.l	a2,d1		;Nome
		move.l	#MODE_NEWFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		beq	WCout		;Esce senza errori se non può creare il file
		move.l	d0,a4		;Conserva in a4 il pun. al file

		move.l	a4,d1
		lea	configid(pc),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Write		;Scrive ID = "CON1"


		lea	ConfigVarPointers(pc),a3
WCloop		move.l	(a3)+,d2
		beq.s	WCloopout

		move.l	a4,d1
		moveq	#2,d3
		CALLSYS	Write

		bra.s	WCloop
WCloopout

WCclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close

WCout
		clr.l	d0
		rts


;****************************************************************************
; Caricatore livello
; Ritorna il flag Z settato se tutto ok

LoadLevelData

		move.w	#-1,ActualScr(a5)

		bsr	ReadMapGLD
		bne.s	LLDerror

		move.l	loadpicname(a5),d4
		jsr	LoadingScreen

		bsr	ReadSounds
		bne.s	LLDerror
		bsr	ReadTextures
		bne.s	LLDerror
		bsr	ReadObjects
		bne.s	LLDerror

		clr.l	d0
		rts
LLDerror
		moveq	#1,d0
		rts

;****************************************************************************
; Legge il file Main GLD
;
; Restituisce d0=0 se tutto ok

ReadMainGLD
		DOSBASE

		clr.b	TextDirFlag(a5)
		clr.b	ObjDirFlag(a5)
		clr.b	DiskReqFlag(a5)

		tst.b	DiskFlag(a5)		;Test se caricamento da floppy
		bne.s	RMGdisk			; Se si, salta
		lea	nomeMGLD(pc),a2
		bra.s	RMGhd
RMGdisk		lea	disknomeMGLD(pc),a2
RMGhd
		bsr	Stampa		;stampa nome

		move.l	a2,d1		;Nome
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		bne	RMGopenok
		lea	errmes1,a2
		bsr	Stampa
		bra	ErrorQuit
;		bra	RMGout
RMGopenok	move.l	d0,a4		;Conserva in a4 il pun. al file

		move.l	a4,d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge Id

		cmp.l	#$4d474c44,InputData(a5)	;Test se ID = "MGLD"
		beq.s	RMGidok
		lea	errmes4,a2
		bsr	Stampa
		bra	ErrorQuit
;		bra	RMGclose
RMGidok

		move.l	a4,d1
		moveq	#36,d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sui nomi delle pic e del mod

		move.l	a4,d1
		lea	PresModName(a5),a0
		move.l	a0,d2
		move.l	#7*4,d3
		CALLSYS	Read			;Legge nomi pic di presentazione e del mod


		move.l	a4,d1
		moveq	#64,d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sul prefisso

		move.l	a4,d1
		lea	fileprefix(a5),a0
		move.l	a0,d2
		move.l	#20,d3
		CALLSYS	Read			;Legge prefisso nomi file,
						; nome Gfx GLD,
						; nome Texture GLD,
						; nome Object GLD,
						; nome Sound GLD

		move.l	a4,d1
		lea	LevelsDirLen(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read			;Legge lunghezza dir. dei livelli

		move.l	a4,d1
		lea	NumGames(a5),a0
		move.l	a0,d2
		move.l	#2,d3
		CALLSYS	Read			;Legge num. games

		EXECBASE
		ALLOCMEMORY LevelsDirLen(a5),MEMF_CLEAR,LevelsDirPun
		DOSBASE

		move.l	a4,d1
		move.l	LevelsDirPun(a5),d2
		move.l	LevelsDirLen(a5),d3
		CALLSYS	Read			;Legge dir. dei livelli
		

RMGclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
RMGout
		clr.l	d0
		rts


;****************************************************************************
; Legge dal file Textures GLD, la directory delle textures
;
; Restituisce d0=0 se tutto ok

ReadTexturesDir
		clr.b	DiskReqFlag(a5)

		move.l	nomeTGLD(a5),d0
		bsr	MakeFileName
		lea	filename(a5),a2
		bsr	Stampa		;stampa nome
RTDagain
		DOSBASE
		move.l	#filename,d1
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		bne	RTDopenok
		jsr	DiskRequest
		bra.s	RTDagain
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	ErrorQuit
RTDopenok
		jsr	RestoreDR	;Ripristina sfondo

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge Id

		cmp.l	#$54474c44,InputData(a5)	;Test se ID = "TGLD"
		beq.s	RTDidok
		lea	errmes4,a2
		bsr	Stampa
		bra	ErrorQuit
;		bra	RTDclose
RTDidok

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge offset directory

		move.l	file(a5),d1
		move.l	InputData(a5),d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sulla directory

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read			;Legge numero textures

		move.l	InputData(a5),d2
		lsl.l	#4,d2			;Calcola lunghezza in byte della directory delle texture
		move.l	d2,TexturesDirLen(a5)

		EXECBASE
		ALLOCMEMORY TexturesDirLen(a5),MEMF_CLEAR,TexturesDirPun
		DOSBASE

		move.l	InputData(a5),d3
		move.l	d3,numtextures(a5)
		cmp.l	#MAXTEXTURES,d3		;Test se ci sono troppo textures nel file
		ble.s	RTDntok
		lea	errmes5,a2
		bsr	Stampa
		bra	ErrorQuit
;		bra	RTDout
RTDntok
		move.l	file(a5),d1
		move.l	TexturesDirPun(a5),d2
		move.l	TexturesDirLen(a5),d3
		CALLSYS	Read			;Legge directory textures

		st	TextDirFlag(a5)

RTDclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
RTDout
		clr.l	d0
		rts

;****************************************************************************
; Legge dal file Objects GLD, la directory degli oggetti
;
; Restituisce d0=0 se tutto ok

ReadObjectsDir
		clr.b	DiskReqFlag(a5)

		move.l	nomeOGLD(a5),d0
		bsr	MakeFileName
		lea	filename(a5),a2
		bsr	Stampa		;stampa nome
RODagain
		DOSBASE
		move.l	#filename,d1
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		bne	RODopenok
		jsr	DiskRequest
		bra.s	RODagain
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	ErrorQuit
RODopenok
		jsr	RestoreDR	;Ripristina sfondo

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge Id

		cmp.l	#$4f474c44,InputData(a5)	;Test se ID = "OGLD"
		beq.s	RODidok
		lea	errmes4,a2
		bsr	Stampa
		bra	ErrorQuit
;		bra	RODclose
RODidok

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge offset directory

		move.l	file(a5),d1
		move.l	InputData(a5),d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sulla directory

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read			;Legge numero oggetti

		move.l	InputData(a5),d2
		move.l	d2,numobjects(a5)
		mulu.w	#12,d2			;Calcola lunghezza in byte della directory degli oggetti
		move.l	d2,ObjectsDirLen(a5)

		EXECBASE
		ALLOCMEMORY ObjectsDirLen(a5),MEMF_CLEAR,ObjectsDirPun
		DOSBASE

		move.l	file(a5),d1
		move.l	ObjectsDirPun(a5),d2
		move.l	ObjectsDirLen(a5),d3
		CALLSYS	Read			;Legge directory oggetti

		st	ObjDirFlag(a5)

RODclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
RODout
		clr.l	d0
		rts


;****************************************************************************
; Legge dal file Sounds GLD, la directory dei sounds
;
; Restituisce d0=0 se tutto ok

ReadSoundsDir
		clr.b	DiskReqFlag(a5)

		move.l	nomeSGLD(a5),d0
		bsr	MakeFileName
		lea	filename(a5),a2
		bsr	Stampa		;stampa nome
RSDagain
		DOSBASE
		move.l	#filename,d1
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		bne	RSDopenok
		jsr	DiskRequest
		bra.s	RSDagain
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	ErrorQuit
RSDopenok
		jsr	RestoreDR	;Ripristina sfondo

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge Id

		cmp.l	#$53474c44,InputData(a5)	;Test se ID = "SGLD"
		beq.s	RSDidok
		lea	errmes6,a2
		bsr	Stampa
		bra	ErrorQuit
;		bra	RSDclose
RSDidok

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge offset directory

		move.l	file(a5),d1
		move.l	InputData(a5),d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sulla directory

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read			;Legge numero sounds

		move.l	InputData(a5),d2
		move.l	d2,numsounds(a5)
		mulu.w	#12,d2			;Calcola lunghezza in byte della directory dei sounds
		move.l	d2,SoundsDirLen(a5)

		EXECBASE
		ALLOCMEMORY SoundsDirLen(a5),MEMF_CLEAR,SoundsDirPun
		DOSBASE

		move.l	file(a5),d1
		move.l	SoundsDirPun(a5),d2
		move.l	SoundsDirLen(a5),d3
		CALLSYS	Read			;Legge directory sounds


RSDclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
RSDout
		clr.l	d0
		rts


;****************************************************************************
; Legge dal file Sounds GLD, la directory dei sounds
;
; Restituisce d0=0 se tutto ok

ReadGfxDir
		clr.b	DiskReqFlag(a5)

		move.l	nomeGGLD(a5),d0
		bsr	MakeFileName
		lea	filename(a5),a2
		bsr	Stampa		;stampa nome
RGDagain
		DOSBASE
		move.l	#filename,d1
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		bne	RGDopenok
		jsr	DiskRequest
		bra.s	RGDagain
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	ErrorQuit
RGDopenok
		jsr	RestoreDR	;Ripristina sfondo

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge Id

		cmp.l	#$47474c44,InputData(a5)	;Test se ID = "GGLD"
		beq.s	RGDidok
		lea	errmes7,a2
		bsr	Stampa
		bra	ErrorQuit
RGDidok

		move.l	file(a5),d1
		lea	InputData+8(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read		;Legge offset directory

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#2,d3
		CALLSYS	Read		;Legge num.palettes

		move.l	file(a5),d1
		lea	Palette(a5),a0
		move.l	a0,d2
		move.w	InputData(a5),d3
		mulu.w	#(256*3),d3
		CALLSYS	Read		;Legge palettes



		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#2,d3
		CALLSYS	Read		;Legge num. lighting tables

		move.l	file(a5),d1
		lea	LightingTable(a5),a0
		move.l	a0,d2
		move.w	InputData(a5),d3
		mulu.w	#8192,d3
		CALLSYS	Read		;Legge lighting tables


		move.l	file(a5),d1
		move.l	InputData+8(a5),d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sulla directory

		move.l	file(a5),d1
		lea	InputData(a5),a0
		move.l	a0,d2
		move.l	#4,d3
		CALLSYS	Read			;Legge numero pics

		clr.l	GfxDirPun(a5)
		move.l	InputData(a5),d2
		move.l	d2,numpics(a5)
		mulu.w	#12,d2			;Calcola lunghezza in byte della directory delle pic
		move.l	d2,GfxDirLen(a5)
		beq.s	RGDclose

		EXECBASE
		ALLOCMEMORY GfxDirLen(a5),MEMF_CLEAR,GfxDirPun
		DOSBASE

		move.l	file(a5),d1
		move.l	GfxDirPun(a5),d2
		move.l	GfxDirLen(a5),d3
		CALLSYS	Read			;Legge directory gfx


RGDclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
RGDout
		clr.l	d0
		rts


;****************************************************************************
;*** In caso di errore nell'allocazione della memoria,
;*** o nella lettura di un file salta qui

ErrorQuit
		DOSBASE
		move.l	file(a5),d1
		beq.s	EQj1
		CALLSYS	Close
EQj1
		moveq	#1,d0
		rts


;****************************************************************************
;* Legge una pic dal file gfx gld nell'area di memoria puntata da GfxPun
;*
;* Richiede:
;*	d4 : Nome pic
;*
;* Restituisce in a0 il pun. alla pic caricata

LoadPic
		clr.b	DiskReqFlag(a5)

		move.l	nomeGGLD(a5),d0
		bsr	MakeFileName
		lea	filename(a5),a2
		bsr	Stampa		;stampa nome
LPagain
		DOSBASE
		move.l	#filename,d1
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		bne	LPopenok
		jsr	DiskRequest
		bra.s	LPagain
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	ErrorQuit
LPopenok
		jsr	RestoreDR	;Ripristina sfondo

		move.l	GfxDirPun(a5),a0	;a0=Pun. alla directory gfx
		move.l	numpics(a5),d6		;d6=Num. pic nella directory
		subq.w	#1,d6
LPfloop		cmp.l	(a0),d4			;Confronta nome
		beq.s	LPfound			;Se trovato, esce dal loop
		lea	12(a0),a0
		dbra	d6,LPfloop
		bra	ErrorQuit		;Se non trovato, errore

LPfound		move.l	4(a0),d4		;d4=offset
		move.l	8(a0),d5		;d5=length

		move.l	file(a5),d1
		move.l	d4,d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sulla pic

		move.l	file(a5),d1
		move.l	GfxPun(a5),d2
		move.l	d5,d3			;Length
		CALLSYS	Read			;Legge la pic

		move.l	d2,a0
		cmp.l	#$5644434f,12(a0)	;Test if 'VDCO' (Virtual Dreams COmpression)
		bne.s	LPclose			; Salta se non compresso
		move.l	a0,a1
		add.l	#81920,a1		;a1=destinazione
		move.l	a1,d2			;Salva pun. pic
		lea	12(a1),a1		;Lascia spazio per i dati della pic
		lea	24(a0),a0		;a0=sorgente
		jsr	UnPack

		;*** Copia dati pic dalla sorgente alla destinazione
		move.l	GfxPun(a5),a0
		move.l	d2,a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+

LPclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
LPout
		move.l	d2,a0			;a0=pun. pic
		clr.l	d0
		rts

;****************************************************************************
;* Legge un mod dal sounds gld
;*
;* Richiede:
;*	d4 : Nome mod
;*	a4 : Pun. destinazione
;*
;* Restituisce in a0 il pun. al mod caricato

LoadMod
		clr.b	DiskReqFlag(a5)

		move.l	nomeSGLD(a5),d0
		bsr	MakeFileName
		lea	filename(a5),a2
		bsr	Stampa		;stampa nome
LMagain
		DOSBASE
		move.l	#filename,d1
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		bne	LMopenok
		jsr	DiskRequest
		bra.s	LMagain
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	ErrorQuit
LMopenok
		jsr	RestoreDR	;Ripristina sfondo

		move.l	SoundsDirPun(a5),a0	;a0=Pun. alla directory sounds
		move.l	numsounds(a5),d6	;d6=Num. sounds nella directory
		subq.w	#1,d6
LMfloop		cmp.l	(a0),d4			;Confronta nome
		beq.s	LMfound			;Se trovato, esce dal loop
		lea	12(a0),a0
		dbra	d6,LMfloop
		bra	ErrorQuit		;Se non trovato, errore

LMfound		move.l	4(a0),d4		;d4=offset
		move.l	8(a0),d5		;d5=length

		move.l	file(a5),d1
		move.l	d4,d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sul mod

		move.l	file(a5),d1
;		move.l	SndPun(a5),d2
		move.l	a4,d2
		move.l	d5,d3			;Length
		CALLSYS	Read			;Legge il mod

LMclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
LMout
		move.l	d2,a0			;a0=pun. mod
		clr.l	d0
		rts

;****************************************************************************
; Legge textures dal file Textures GLD basandosi sulla lista di
; textures della mappa.
; Da per scontato che il file sia corretto.

ReadTextures
		tst.b	TextDirFlag(a5)	;Test se la dir è stata caricata
		bne.s	RDdirok		; Se si, salta
		bsr	ReadTexturesDir
RDdirok
		clr.b	DiskReqFlag(a5)

		move.l	nomeTGLD(a5),d0
		bsr	MakeFileName
		lea	filename(a5),a2
		bsr	Stampa		;stampa nome
RTagain
		DOSBASE
		move.l	#filename,d1	;Nome
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		bne	RTopenok
		jsr	DiskRequest
		bra.s	RTagain
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	ErrorQuit
RTopenok
		jsr	RestoreDR	;Ripristina sfondo

			;***** Calcola alcuni pun.
		move.l	FreeGfxPun(a5),d5
		move.l	d5,Textures(a5)
		move.l	numleveltext(a5),d3
		addq.l	#2,d3
		lsl.l	#2,d3
		add.l	d3,d5
		move.l	d5,FirstTexture(a5)


		move.l	textlistpun(a5),a3	;a3=Pun. ai nomi delle textures
		move.l	Textures(a5),a4		;a4=Pun. alla lista di pun. alle textures
		move.l	FirstTexture(a5),a2	;a2=Pun. alle textures
		move.l	numleveltext(a5),d7
		subq.w	#1,d7

		addq.l	#4,a4			;Salta primo puntatore, perchè la texture num. 0 è inutilizzata

	;*** Loop di lettura textures
RTrloop
		move.l	(a3)+,d0		;d0=Primi 4 char del nome
		move.l	(a3)+,d1		;d1=Ultimi 4 char del nome
		move.l	TexturesDirPun(a5),a0	;a0=Pun. alla directory textures
		move.l	numtextures(a5),d6	;d6=Num. textures nella directory
		subq.w	#1,d6
RTfloop		cmp.l	(a0),d0			;Confronta prima 4 char
		bne.s	RTnoeq
		cmp.l	4(a0),d1		;Confronta ultimi 4 char
		beq.s	RTfound			;Se trovato, esce dal loop
RTnoeq		lea	16(a0),a0
		dbra	d6,RTfloop
		bra	ErrorQuit		;Se non trovato, errore

RTfound		move.l	8(a0),d4		;d4=offset
		move.l	12(a0),d5		;d5=length

		move.l	file(a5),d1
		move.l	d4,d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sulla texture

		move.l	file(a5),d1
		move.l	a2,d2
		move.l	d5,d3			;Length
		CALLSYS	Read			;Legge texture

		move.l	a2,(a4)			;Scrive pun. alla texture appena letta
		addq.l	#4,(a4)+		;Il pun. alla texture deve puntare 2 word più avanti
		add.l	d5,a2

		dbra	d7,RTrloop

		move.l	a2,FreeGfxPun(a5)	;Aggiorna pun. alla memoria libera
		clr.l	(a4)			;Azzera ultimo pun.
		move.l	Textures(a5),a4
		clr.l	(a4)			;Azzera primo pun.

RTclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
RTout
		clr.l	d0
		rts

;****************************************************************************
; Legge oggetti dal file Objects GLD basandosi sulla lista di
; oggetti presenti nella mappa.
; Da per scontato che il file sia corretto.

ReadObjects
		tst.b	ObjDirFlag(a5)	;Test se la dir è stata caricata
		bne.s	ROdirok		; Se si, salta
		bsr	ReadObjectsDir
ROdirok
		clr.b	DiskReqFlag(a5)

		move.l	nomeOGLD(a5),d0
		bsr	MakeFileName
		lea	filename(a5),a2
		bsr	Stampa		;stampa nome
ROagain
		DOSBASE
		move.l	#filename,d1	;Nome
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		bne	ROopenok
		jsr	DiskRequest
		bra.s	ROagain
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	ErrorQuit
ROopenok
		jsr	RestoreDR	;Ripristina sfondo

			;***** Calcola alcuni pun.
		move.l	FreeGfxPun(a5),d5
		move.l	d5,ObjectImages(a5)
		move.l	numlevelobj(a5),d3
		addq.l	#2,d3
		lsl.l	#2,d3
		add.l	d3,d5
		move.l	d5,FirstObjectImage(a5)


		move.l	objlistpun(a5),a3	;a3=Pun. ai nomi degli oggetti
		move.l	ObjectImages(a5),a4	;a4=Pun. alla lista di pun. agli oggetti
		move.l	FirstObjectImage(a5),a2	;a2=Pun. agli oggetti
		move.l	numlevelobj(a5),d7
		addq.l	#4,a4			;Salta primo puntatore, perchè l'oggetto num. 0 è inutilizzato
		bra.s	ROnext

	;*** Loop di lettura oggetti
ROrloop
		move.l	(a3)+,d0		;d0=nome oggetto
		move.l	ObjectsDirPun(a5),a0	;a0=Pun. alla directory oggetti
		move.l	numobjects(a5),d6	;d6=Num. oggetti nella directory
		subq.w	#1,d6
ROfloop		cmp.l	(a0),d0			;Confronta nome
		beq.s	ROfound			;Se trovato, esce dal loop
ROnoeq		lea	12(a0),a0
		dbra	d6,ROfloop
		bra	ErrorQuit		;Se non trovato, errore

ROfound		move.l	4(a0),d4		;d4=offset
		move.l	8(a0),d5		;d5=length

		move.l	file(a5),d1
		move.l	d4,d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sull'oggetto

		move.l	file(a5),d1
		move.l	a2,d2
		move.l	d5,d3			;Length
		CALLSYS	Read			;Legge oggetto

		move.l	a2,(a4)+		;Scrive pun. all'oggetto appena letto
		addq.l	#4,d5
		and.l	#$fffffffc,d5		;Allinea a long
		add.l	d5,a2

ROnext		dbra	d7,ROrloop

		move.l	a2,FreeGfxPun(a5)	;Aggiorna pun. alla memoria libera
		clr.l	(a4)			;Azzera ultimo pun.
		move.l	ObjectImages(a5),a4
		clr.l	(a4)			;Azzera primo pun.

ROclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
ROout
		clr.l	d0
		rts

;****************************************************************************
; Legge oggetti dal file Sounds GLD basandosi sulla lista di
; sounds presenti nella mappa.
; Da per scontato che il file sia corretto.

ReadSounds
		clr.b	DiskReqFlag(a5)

		move.l	nomeSGLD(a5),d0
		bsr	MakeFileName
		lea	filename(a5),a2
		bsr	Stampa		;stampa nome
RSagain
		DOSBASE
		move.l	#filename,d1	;Nome
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		move.l	d0,file(a5)
		bne	RSopenok
		jsr	DiskRequest
		bra.s	RSagain
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	ErrorQuit
RSopenok
		jsr	RestoreDR	;Ripristina sfondo

			;***** Calcola alcuni pun.
		move.l	SndPun(a5),d5
		move.l	d5,Sounds(a5)
		move.l	d5,a4			;a4=Pun. alla lista di pun. agli oggetti
		move.l	SoundsNumber(a5),d3
		move.l	d3,d7
		lsl.l	#3,d3
		addq.l	#4,d3
		add.l	d3,d5
		move.l	d5,FirstSound(a5)
		move.l	d5,a2			;a2=Pun. ai sounds
		move.l	sndlistpun(a5),a3	;a3=Pun. ai nomi dei sounds del livello
		bra.s	RSnext

	;*** Loop di lettura sounds
RSrloop
		move.l	(a3)+,d0		;d0=nome sound
		move.l	SoundsDirPun(a5),a0	;a0=Pun. alla directory sounds
		move.l	numsounds(a5),d6	;d6=Num. sounds nella directory
		subq.w	#1,d6
RSfloop		cmp.l	(a0),d0			;Confronta nome
		beq.s	RSfound			;Se trovato, esce dal loop
RSnoeq		lea	12(a0),a0
		dbra	d6,RSfloop
		bra	ErrorQuit		;Se non trovato, errore
		
RSfound		move.l	d0,(a4)+		;Scrive nome sound

		move.l	4(a0),d4		;d4=offset
		move.l	8(a0),d5		;d5=length

		move.l	file(a5),d1
		move.l	d4,d2
		move.l	#OFFSET_BEGINNING,d3
		CALLSYS	Seek			;Si sposta sul sound

		move.l	file(a5),d1
		move.l	a2,d2
		move.l	d5,d3			;Length
		CALLSYS	Read			;Legge sound

		cmp.b	#1,snd_type(a2)		;E' un global sound ?
		bne.s	RSnoglobal		; Se no, salta
		lea	GlobalSound0(a5),a0
		clr.l	d0
		move.b	snd_code(a2),d0
		move.l	a2,(a0,d0.l*4)		;Scrive pun. al sound nella lista dei global sounds
RSnoglobal
		move.l	a2,(a4)+		;Scrive pun. al sound appena letto
		addq.l	#4,d5
		and.l	#$fffffffc,d5		;Allinea a long
		add.l	d5,a2

RSnext		dbra	d7,RSrloop

		clr.l	(a4)			;Azzera ultimo pun.

RSclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
RSout
		clr.l	d0
		rts

;****************************************************************************
; Carica tutti i dati del livello corrente dal Map GLD
; e inizializza alcuni puntatori

ReadMapGLD
		clr.b	DiskReqFlag(a5)

		move.l	PunLevel(a5),a0
		move.l	(a0),d0		;d0=Nome level
		bsr	MakeFileName
		lea	filename(a5),a2
		bsr	Stampa		;stampa nome
LLDagain
		DOSBASE
		move.l	#filename,d1	;Nome
		move.l	#MODE_OLDFILE,d2
		move.l	GfxPun(a5),a4	;Dest.
		move.l	#GFX_SIZE,d4	;Lun. dest.
		moveq	#1,d5		;UnPack
		jsr	OpenCustom
		move.l	d0,file(a5)
		bne	LLDopenok
		jsr	DiskRequest
		bra.s	LLDagain
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	ErrorQuit
LLDopenok
		jsr	RestoreDR	;Ripristina sfondo


		move.l	GfxPun(a5),a3	;a3=Pun. buffer


		cmp.l	#$4c474c44,(a3)+	;Test se ID = "LGLD"
		beq.s	LLDidok
		lea	errmes3,a2
		bsr	Stampa
		bra	ErrorQuit
;		bra	LLDclose
LLDidok

		addq.l	#6,a3			;Non usati
		addq.l	#1,a3			;Compression flag

		move.l	(a3)+,d0			;d0=Length
		sub.l	#((MAP_SIZE*MAP_SIZE)<<1),d0	;Sottrae lung. mappa
		move.l	MapPun(a5),a1			;a1=dest.
		bsr	CopyMemory			;Legge Blocks, Edges, Effects


	;*** Init puntatori Blocks, Edges, Map

		move.l	MapPun(a5),a0
		move.l	(a0)+,d0		;d0=Num.blocchi
		move.l	a0,Blocks(a5)
		lsl.l	#bl_SIZE_B,d0
		add.l	d0,a0			;a0=Pun. Edges
		move.l	(a0)+,d0		;d0=Num. Edges
		move.l	a0,Edges(a5)
		lsl.l	#ed_SIZE_B,d0
		add.l	d0,a0			;a0=Pun. BlockEffectList
		move.l	a0,BlockEffectList(a5)

	;*** Cerca fine lista effetti

LLDloopel1	tst.l	(a0)
		bmi.s	LLDelout		;Se<0, fine elenco liste effetti ed esce
		beq.s	LLDemptylist		;Se=0, la lista è vuota e va alla prossima lista
LLDloopel2	lea	10(a0),a0		;Si sposta sul prossimo effetto della lista attuale
		tst.l	(a0)			;Se non e' uguale a zero
		bne.s	LLDloopel2		; continua
LLDemptylist	addq.l	#4,a0			;Si sposta sul primo effetto della prossima lista di effetti
		bra.s	LLDloopel1		; e continua
LLDelout	addq.l	#4,a0			;Salta il -1

	;*** Mette a -1 le 128 long precedenti la mappa

		moveq	#127,d7
		moveq	#-1,d0
LLDloopmu1	move.l	d0,(a0)+
		dbra	d7,LLDloopmu1

		move.l	a0,Map(a5)


	;*** Legge la mappa

		move.l	#((MAP_SIZE*MAP_SIZE)<<1),d0	;d0=length
		move.l	a0,a1				;a1=dest.
		bsr	CopyMemory			;Legge mappa


	;*** Trasforma mappa da 128x128 in mappa da 128x128 mixata con la mappa oggetti

		move.l	Map(a5),a0
		move.l	a0,a1
		add.l	#65536,a0	;a0=pun. alla fine della mappa 128x128 mixata
		add.l	#32768,a1	;a1=pun. alla fine della mappa 128x128 non mixata
		move.w	#(128*128),d7	;d7=contatore
LLDlooptr1	clr.w	-(a0)		;Scrive word mappa oggetti
		move.w	-(a1),-(a0)	;Copia word mappa muri
		dbra	d7,LLDlooptr1

	;*** Scorre la mappa blocchi e per ogni blocco=0,
	;*** mette a -1 le word della mappa oggetti
	;*** Per velocizzare un pochetto il raycasting degli oggetti

		move.l	Map(a5),a0	;a0=Pun. mappa blocchi
		lea	2(a0),a1	;a1=Pun. mappa oggetti
		move.w	#(128*128)-1,d7	;d7=contatore
LLDloopneg	tst.w	(a0)		;Cod. blocco=0 ?
		bne.s	LLDlnj		; Se no, salta
		move.w	#-1,(a1)	;Mette -1 nella mappa oggetti, alla posizione corrispondente
LLDlnj		addq.l	#4,a0
		addq.l	#4,a1
		dbra	d7,LLDloopneg


	;*** Mette a -1 le 128 long subito dopo la mappa

		move.l	Map(a5),a0
		add.l	#((MAP_SIZE*MAP_SIZE)<<2),a0
		moveq	#127,d7
		moveq	#-1,d0
LLDloopmu2	move.l	d0,(a0)+
		dbra	d7,LLDloopmu2


	;*** Legge textures utilizzate

		move.l	(a3)+,d0		;d0=Num.textures
		move.l	d0,numleveltext(a5)
		lsl.l	#3,d0			;d0=length
		move.l	c2pBuffer1(a5),a1	;a1=dest.
		move.l	a1,textlistpun(a5)	;pun. alla lista di nomi textures utilizzate
		move.l	a1,d4
		add.l	d0,d4
		move.l	d4,objlistpun(a5)	;pun. alla lista di nomi objects utilizzati
		bsr	CopyMemory		;Legge nomi textures


	;*** Legge oggetti utilizzati

		move.l	(a3)+,d0		;d0=Num.oggetti
		beq.s	LLDnoobj
		move.l	d0,numlevelobj(a5)
		lsl.l	#2,d0			;d0=length
		move.l	objlistpun(a5),a1	;a1=dest.
		move.l	a1,d4
		add.l	d0,d4
		move.l	d4,sndlistpun(a5)	;pun. alla lista di nomi sounds utilizzati
		bsr	CopyMemory		;Legge nomi textures
LLDnoobj

	;*** Legge oggetti presenti in mappa

		move.l	(a3)+,d0		;d0=Num.oggetti
		beq.s	LLDnomapobj
		move.l	d0,ObjectNumber(a5)
		mulu.w	#10,d0			;d0=length
		move.l	c2pBuffer2(a5),a1	;a1=dest.
		bsr	CopyMemory		;Legge oggetti in mappa


	;*** Costruisce la lista delle strutture degli oggetti in mappa

		move.l	c2pBuffer2(a5),a0
		move.l	Objects(a5),a1
		move.l	ObjectNumber(a5),d7
		bra.s	LLDobjnext
LLDloopobj	clr.l	d0
		move.w	(a0)+,d0	;Codice oggetto
		bne.s	LLDobjnopl	;Se non è il player, salta
		subq.l	#1,ObjectNumber(a5)	;Sottrae un oggetto dalla lista
		move.w	(a0)+,CPlayerX(a5)
		move.w	(a0)+,CPlayerZ(a5)
		move.w	(a0)+,CPlayerHeading(a5)
		addq.l	#2,a0			;Salta flags
		bra.s	LLDobjnext
LLDobjnopl	move.l	a1,a2
		REPT	16		;Clear struttura
		clr.l	(a2)+
		ENDR
		move.l	d0,obj_image(a1)
		move.w	(a0)+,obj_x(a1)
		move.w	(a0)+,obj_z(a1)
		move.w	(a0)+,obj_heading(a1)
		addq.l	#1,a0			;Salta flags
		move.b	(a0)+,obj_inactive(a1)
		lea	obj_SIZE(a1),a1
LLDobjnext	dbra	d7,LLDloopobj

LLDnomapobj


	;*** Legge sounds presenti in mappa

		move.l	(a3)+,d0		;d0=Num.suoni
		beq.s	LLDnosounds
		move.l	d0,SoundsNumber(a5)
		lsl.l	#2,d0			;d0=length
		move.l	sndlistpun(a5),a1	;a1=dest.
		bsr	CopyMemory		;Legge oggetti in mappa
LLDnosounds

	;*** Legge nome pic di caricmento

		move.l	(a3)+,loadpicname(a5)

LLDclose
		DOSBASE
		move.l	file(a5),d1
		CALLSYS	Close
LLDout
		clr.l	d0
		rts


;****************************************************************************
;* Copia memoria
;* Richiede:
;*	a1=dest.
;*	a3=source
;*	d0=len. in byte
;*
;* All'uscita, a1 e a3 puntano ai prossimi byte da copiare

CopyMemory

CMloop		move.b	(a3)+,(a1)+
		subq.l	#1,d0
		bne.s	CMloop

		rts

;****************************************************************************
;* Carica dati (mod PT, sample, etc)
;*
;* Richiede:
;*	d1 : Pun. nome file
;*	d4 : Len. dest.
;*	d5 : Unpack flag
;*	a4 : Pun. dest

;LoadData	movem.l	d0-d7/a0-a5,-(sp)
;
;		move.l	d1,a2
;		bsr	Stampa		;stampa nome
;
;LDstart
;		move.l	#MODE_OLDFILE,d2
;		jsr	OpenCustom
;		tst.l	d0
;		bne	LDopenok
;		lea	errmes1,a2
;		bsr	Stampa
;		bra	LDout
;LDopenok	move.l	d0,file(a5)
;
;		move.l	file(a5),d1
;		CALLSYS	Close
;
;LDout		movem.l	(sp)+,d0-d7/a0-a5	
;		rts

;****************************************************************************
;* Cerca il file S:BREATHLESS_WTOM, se lo trova vuol dire che
;* il caricamento avviene da dischetti

CheckDisk
		clr.b	DiskFlag(a5)

		DOSBASE
		move.l	#nomeWTOM,d1		;Nome
		move.l	#MODE_OLDFILE,d2
		CALLSYS	Open
		tst.l	d0
		beq	CDout			;Salta se file non trovato

		move.l	d0,d1
		CALLSYS	Close

		st	DiskFlag(a5)		;Segnala che il caricamento avviene da dischetti

CDout
		rts

;****************************************************************************
;*** Costruisce il nome file in base al parametro
;***
;***  d0 = Nome del file .GLD da leggere

MakeFileName	movem.l	d0-d7/a0-a5,-(sp)

		lea	filename(a5),a0

		tst.b	DiskFlag(a5)		;Test se caricamento da floppy
		bne.s	MFNdisk			; Se si, salta
		lea	filepath(pc),a1
		bra.s	MFNhd
MFNdisk		cmp.w	#'01',d0		;File TGLD ?
		bne.s	MFNnotgld		; Se no, salta
		lea	disk2path(pc),a1
		bra.s	MFNhd
MFNnotgld	cmp.w	#'03',d0		;File OGLD ?
		bne.s	MFNnoogld		; Se no, salta
		lea	disk3path(pc),a1
		bra.s	MFNhd
MFNnoogld	lea	disk1path(pc),a1

MFNhd

			;*** Copia la path
MFNloop1	move.b	(a1)+,d1
		beq.s	MFNoutloop1
		move.b	d1,(a0)+
		bra.s	MFNloop1
MFNoutloop1
		move.l	fileprefix(a5),(a0)+	;Copia il prefisso del nome file

		move.l	d0,(a0)+		;Copia il nome del file
		
		move.l	#'.gld',(a0)+		;Copia l'estensione del nome file

		clr.b	(a0)+			;Termina la stringa con zero

		movem.l	(sp)+,d0-d7/a0-a5	
		rts

;****************************************************************************
;Stampa il numero long indirizzato da a2

StampaNum	movem.l	d0-d7/a0-a5,-(sp)

		CALLSYS	Output
		move.l	d0,d6		;salva handle

		lea	caratteri,a3
		lea	bbb,a4
		moveq	#3,d7
SNloop
		move.b	(a2),d0
		lsr.b	#4,d0
		ext.w	d0
		move.b	(a3,d0.w),(a4)
		move.l	d6,d1		;d1=handle output video
		move.l	a4,d2		;d2=indirizzo buffer
		moveq	#1,d3		;d3=lun
		CALLSYS	Write

		move.b	(a2)+,d0
		and.b	#15,d0
		ext.w	d0
		move.b	(a3,d0.w),(a4)
		move.l	d6,d1		;d1=handle output video
		move.l	a4,d2		;d2=indirizzo buffer
		moveq	#1,d3		;d3=lun
		CALLSYS	Write

		dbra	d7,SNloop

		move.b	#' ',(a4)
		move.l	d6,d1		;d1=handle output video
		move.l	a4,d2		;d2=indirizzo buffer
		moveq	#1,d3		;d3=lun
		CALLSYS	Write

SNout		movem.l	(sp)+,d0-d7/a0-a5	
		rts

bbb		dc.b	0
caratteri	dc.b	'0123456789abcdef'
		cnop	0,2

;------------------------------------------------------------------------
;Stampa una null terminated string
;
;I	a2=indirizzo null terminated string

Stampa
		IFNE	DEBUG

		movem.l	d0-d7/a0-a5,-(sp)

		DOSBASE

		CALLSYS	Output
		move.l	d0,d6		;salva handle

		move.l	a2,a0
		moveq	#-1,d3		;Conta numero caratteri
Sloop		addq.l	#1,d3
		tst.b	(a0)+
		bne	Sloop

		tst.w	d3
		beq	Sout

		move.l	d6,d1		;d1=handle output video
		move.l	a2,d2		;d2=indirizzo buffer
		CALLSYS	Write

		move.l	d6,d1		;d1=handle output video
		lea	linefeed,a0
		move.l	a0,d2		;d2=indirizzo buffer
		moveq	#1,d3
		CALLSYS	Write		;line feed

Sout		movem.l	(sp)+,d0-d7/a0-a5	

		ENDC

		rts

;************************************************************************

configname	dc.b	'BREATHLESS:Config',0	;Nome file di configurazione
configid	dc.b	'CON1',0

filepath	dc.b	'BREATHLESS:',0		;Path dei file
disk1path	dc.b	'BREATHLESS1:',0	;Path dei file per disk 1
disk2path	dc.b	'BREATHLESS2:',0	;Path dei file per disk 2
disk3path	dc.b	'BREATHLESS3:',0	;Path dei file per disk 3

nomeMGLD	dc.b	'BREATHLESS:Breathless.gld',0
disknomeMGLD	dc.b	'BREATHLESS1:Breathless.gld',0

nomeWTOM	dc.b	'S:BREATHLESS_WTOM',0	;Se è presente questo file, il caricamento avviene da dischetti

errmes1		dc.b	'Error opening file.',0
errmes2		dc.b	'Read error.',0
errmes3		dc.b	'No LGLD file.',0
errmes4		dc.b	'No TGLD file.',0
errmes5		dc.b	'Too much textures in TGLD file.',0
errmes6		dc.b	'No SGLD file.',0
errmes7		dc.b	'No GGLD file.',0
errmes8		dc.b	'No CONF file.',0

linefeed	dc.b	10
		cnop	0,4

;****************************************************************************

	section	__MERGED,BSS

		cnop	0,4

		xdef	DiskFlag

DiskFlag	ds.b	1	;Se=TRUE, il caricamento avviene da floppy

TextDirFlag	ds.b	1	;Se=TRUE, la dir delle texture è stata già caricata
ObjDirFlag	ds.b	1	;Se=TRUE, la dir degli oggetti è stata già caricata

		ds.b	1	;Usato per allineare

fileprefix	ds.b	4	;Prefisso per i nomi dei file .gld
nomeGGLD	ds.b	4	;Nome Gfx GLD
nomeTGLD	ds.b	4	;Nome Texture GLD
nomeOGLD	ds.b	4	;Nome Object GLD
nomeSGLD	ds.b	4	;Nome Sound GLD

filename	ds.b	256	;Stringa usata per comporre i nomi file

		cnop	0,4

file		ds.l	1	;File handler
InputData	ds.b	32
length		ds.l	1
numtextures	ds.l	1	;Num. textures nel file TGLD
numleveltext	ds.l	1	;Num. textures del livello
textlistpun	ds.l	1	;Pun. alla lista di nomi di textures usate nel livello
numobjects	ds.l	1	;Num. objects nel file OGLD
numlevelobj	ds.l	1	;Num. objects del livello
objlistpun	ds.l	1	;Pun. alla lista di nomi di oggetti usati nel livello
numsounds	ds.l	1	;Num. sounds nel file SGLD
sndlistpun	ds.l	1	;Pun. alla lista di nomi di sound usati nel livello
numpics		ds.l	1	;Num. pics nel file GGLD
loadpicname	ds.l	1	;Nome della pic di caricamento del livello

		cnop	0,4
