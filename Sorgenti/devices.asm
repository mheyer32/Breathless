;***********************************************************
;***
;***	Routine IntuitionOff e IntuitionOn +
;***	Funzioni di supporto alla libreria Exec
;***
;***	Data	23 Dec 93
;***
;***********************************************************


		include	'System'
		include	'TMap.i'


		xref	joyup,joydown,joyleft,joyright
		xref	joyfire,joyfireP
		xref	sideleft,sideright
		xref	speedup,sidemove,lookupdown
		xref	mousepos
		xref	pause
		xref	ScreenActive
		xref	myInputEvent,ResetMousePos
		xref	VBTimer2

;****************************************************************
;
; Programma principale di prova
;
;main		movem.l	d0-d7/a0-a6,-(sp)
;
;		pea	kkk
;		jsr	IntuitionOff
;		addq.w	#4,sp
;		tst.l	d0
;		bne	mainout
;
;waitloop	btst	#6,$bfe001
;		bne	waitloop
;
;		jsr	IntuitionOn
;
;mainout		movem.l	(sp)+,d0-d7/a0-a6
;		rts
;
;kkk		dc.w	0
;
;****************************************************************
;
; int IntuitionOff(UWORD *key, *intuitionbase, *myscreen)
;	   sp+		  12	     16		   20
;
;
; Blocca la gestione dell'input di Intuition inserendo un input handler
;  a priorita' 127.
; Inoltre l'input handler inserito legge l'ultimo tasto premuto
;  e ne inserisce lo scancode nella word puntata da key.
; Se tutto e' andato bene restituisce 0.
;

		xdef	IntuitionOff
IntuitionOff	movem.l	a5/a6,-(sp)

		lea	dati,a5

		move.l	#0,lastkeycode-dati(a5)

		move.l	12(sp),keypressed-dati(a5)
		move.l	16(sp),intuitionbase-dati(a5)
		move.l	20(sp),myscreen-dati(a5)

		jsr	OpenInputDevice
		tst.l	d0		;Test se tutto ok
		beq	IOok
		jsr	CloseAll
		moveq	#1,d0
		bra	IOexit

IOok		jsr	AddInputHandler

		move.w	#1,flagoff-dati(a5)

		moveq	#0,d0
IOexit		movem.l	(sp)+,a5/a6
		rts

;****************************************************************

		xdef	IntuitionOn
IntuitionOn	movem.l	a5/a6,-(sp)

		lea	dati,a5

		tst.w	flagoff-dati(a5)
		beq	NOio

		jsr	RemoveInputHandler
		jsr	CloseAll

		move.w	#0,flagoff-dati(a5)
NOio
		movem.l	(sp)+,a5/a6
		rts

;****************************************************************

OpenInputDevice
		move.l	#127,-(sp)
		move.l	#0,-(sp)
		jsr	CreatePort
		addq.w	#8,sp
		move.l	d0,inputport-dati(a5)
		beq	OIDerrorout

		move.l	inputport-dati(a5),-(sp)
		jsr	CreateStdIO
		addq.w	#4,sp
		move.l	d0,inputreq-dati(a5)
		beq	OIDerrorout

		moveq	#0,d1
		move.l	inputreq-dati(a5),a1
		moveq	#0,d0
		lea	inputdevicename,a0
		move.l	4,a6
		jsr	_LVOOpenDevice(a6)
		tst.l	d0
		bne	OIDerrorout

		moveq	#0,d0
		rts

OIDerrorout	moveq	#1,d0
		rts

;****************************************************************

AddInputHandler
		lea	InputHandler,a0
		lea	InputHandlerCode,a1
		lea	handlername,a2
		move.l	keypressed-dati(a5),a3
		clr.l	kptime-dati(a5)

		move.b	#0,LN_TYPE(a0)
		move.b	#127,LN_PRI(a0)
		move.l	a2,LN_NAME(a0)
		move.l	a3,IS_DATA(a0)
		move.l	a1,IS_CODE(a0)

		move.l	inputreq-dati(a5),a1
		move.w	#IND_ADDHANDLER,IO_COMMAND(a1)
		move.b	#0,IO_FLAGS(a1)
		move.l	a0,IO_DATA(a1)

		move.l	4,a6
		jsr	_LVODoIO(a6)

		rts

;****************************************************************

RemoveInputHandler
		lea	InputHandler,a0
		move.l	inputreq-dati(a5),a1

		move.w	#IND_REMHANDLER,IO_COMMAND(a1)
		move.b	#0,IO_FLAGS(a1)
		move.l	a0,IO_DATA(a1)

		move.l	4,a6
		jsr	_LVODoIO(a6)

		rts

;****************************************************************

CloseAll
		move.l	inputreq-dati(a5),d0
		beq	CAj1
		move.l	d0,-(sp)
		jsr	DeleteStdIO
		add.w	#4,sp
CAj1
		move.l	inputport-dati(a5),d0
		beq	CAj2
		move.l	d0,-(sp)
		jsr	DeletePort
		add.w	#4,sp
CAj2

		rts

;****************************************************************

LEFT_AMIGA	EQU	$66

InputHandlerCode
		movem.l	d2/a2-a6,-(sp)
		move.l	a0,a3		;a3=Pun. alla testa della lista di eventi
		sub.l	a4,a4		;a4=Pun. all'evento precedente

		GETDBASE
		lea	dati(pc),a6
		move.l	(a1)+,d2	;d2=Indice alla coda circolare di tasti premuti puntata da a1
					;a1=Pun. alla coda circolare di tasti premuti

		clr.b	ScreenActive(a5)
		move.l	intuitionbase(pc),a2
		move.l	myscreen(pc),d1
		cmp.l	ib_FirstScreen(a2),d1	;Test quale schermo è visualizzato
		bne	IHCout
		st	ScreenActive(a5)

		clr.w	keypassed-dati(a6)

IHCloop		tst.l	a0
		beq	IHCend

		move.b	ie_Class(a0),d0

		cmp.b	#IECLASS_RAWMOUSE,d0
		bne.s	IHCnomouse

		move.w	ie_Qualifier(a0),d0
		btst	#IEQUALIFIERB_RELATIVEMOUSE,d0
		beq.s	IHCnorelmouse
		move.w	ie_X(a0),mousepos(a5)
IHCnorelmouse	btst	#IEQUALIFIERB_RBUTTON,d0
		beq.s	IHCnolbutton
		move.w	SwitchKey(pc),d0
		move.w	d0,(a1,d2.l)		;Memorizza tasto premuto
		bra	IHCmem
IHCnolbutton
		bra	IHCnomem


IHCnomouse	cmp.b	#IECLASS_RAWKEY,d0
		bne	IHCcont

		move.w	ie_Qualifier(a0),d0
		and.w	#IEQUALIFIER_REPEAT,d0	;Tasto autoripetuto ?
		bne	IHCnomem		; Se si, non lo considera

		move.w	ie_Code(a0),d0		;d0=scan code

		cmp.w	#$36,d0			;Premuto N ?
		beq	IHCpressn
		cmp.w	#$37,d0			;Premuto M ?
		bne	IHCnolamiga
IHCpressn	move.w	ie_Qualifier(a0),d1
		and.w	#IEQUALIFIER_LCOMMAND,d1	;Premuto LAmiga ?
		beq.s	IHCnolamiga		; Se no, salta
		st	ResetMousePos(a5)
		bra	IHCkeypass
IHCnolamiga

		move.w	d0,(a1,d2.l)		;Memorizza tasto premuto

		tst.w	pause(a5)		;Se il gioco è in pausa,
		bne	IHCmem			; registra tutti i tasti premuti

	;*** Test se si tratta di tasti di controllo del player

		move.w	FireKey(pc),d1
		or.w	#$80,d1
		cmp.w	d1,d0			;Rilasciato tasto fire ?
		bne.s	IHCnofirerel		; Se no, salta
		subq.w	#1,joyfireP(a5)		;Segnala tasto rilasciato
		bra	IHCnomem
IHCnofirerel


		clr.l	d1
		tst.b	d0
		bmi.s	IHCrilasciato
		moveq	#1,d1
IHCrilasciato
		and.w	#$7f,d0

		cmp.w	ForwardKey(pc),d0	;Premuto tasto freccia su ?
		bne.s	IHCnoup
		move.b	d1,joyup+1(a5)
		bra	IHCnomem
IHCnoup		cmp.w	BackwardKey(pc),d0	;Premuto tasto freccia giu ?
		bne.s	IHCnodown
		move.b	d1,joydown+1(a5)
		bra.s	IHCnomem
IHCnodown	cmp.w	RotateLeftKey(pc),d0	;Premuto tasto freccia sinistra ?
		bne.s	IHCnoleft
		move.b	d1,joyleft+1(a5)
		bra.s	IHCnomem
IHCnoleft	cmp.w	RotateRightKey(pc),d0	;Premuto tasto freccia destra ?
		bne.s	IHCnoright
		move.b	d1,joyright+1(a5)
		bra.s	IHCnomem
IHCnoright	cmp.w	SideLeftKey(pc),d0	;Premuto tasto sinistra ?
		bne.s	IHCnosideleft
		move.b	d1,sideleft(a5)
;		move.b	d1,joyleft+1(a5)
		bra.s	IHCnomem
IHCnosideleft	cmp.w	SideRightKey(pc),d0	;Premuto tasto destra ?
		bne.s	IHCnosideright
		move.b	d1,sideright(a5)
;		move.b	d1,joyright+1(a5)
		bra.s	IHCnomem
IHCnosideright	cmp.w	AccelKey(pc),d0		;Premuto tasto ctrl ?
		bne.s	IHCnoctrl
		move.b	d1,speedup(a5)
		bra.s	IHCnomem
IHCnoctrl	cmp.w	FireKey(pc),d0		;Premuto tasto alt ?
		bne.s	IHCnoalt
		addq.w	#1,joyfireP(a5)
		addq.w	#1,joyfire(a5)
		bra.s	IHCnomem
IHCnoalt	cmp.w	ForceSideKey(pc),d0	;Premuto tasto shift ?
		bne.s	IHCnoshift
		move.b	d1,sidemove(a5)
		bra.s	IHCnomem
IHCnoshift	cmp.w	LookUpKey(pc),d0	;Premuto tasto sguardo in alto ?
		bne.s	IHCnoraiselook
		move.l	d1,lookupdown(a5)
		bra.s	IHCnomem
IHCnoraiselook	cmp.w	LookDownKey(pc),d0	;Premuto tasto sguardo in basso ?
		bne.s	IHCnolowlook
		move.l	d1,lookupdown(a5)
		neg.l	lookupdown(a5)
		bra.s	IHCnomem
IHCnolowlook	




	;*** Se non si tratta di un tasto di controllo del player,
	;*** sposta l'indice della coda (il codice del tasto è
	;*** già stato inserito nella coda).
IHCmem
		addq.l	#2,d2			;Sposta l'indice alla coda
		and.w	#$7f,d2			;Assicura la circolarità dell'indice
IHCnomem
		cmp.l	a3,a0			;L'elemento attuale è il primo della lista ?
		bne.s	IHCnohead		; se no, salta
		move.l	ie_NextEvent(a0),a3	;Elimina il primo elemento dalla lista
		bra.s	IHCcont
IHCnohead	move.l	ie_NextEvent(a0),ie_NextEvent(a4)	;Elimina l'elemento attuale dalla lista

IHCcont		move.l	a0,a4			;a4=Pun. all'evento precedente
		move.l	ie_NextEvent(a0),a0
		bra	IHCloop

		;*** Saltare qui se si vuole lasciare il tasto nella coda di input
IHCkeypass	st	keypassed-dati(a6)	;Segnala che il tasto rimane nella coda di input
		bra.s	IHCcont


IHCend	;	move.w	#0,(a1)		;Nessun tasto premuto
IHCout
		move.l	d2,-4(a1)	;Memorizza la nuova posizione dell'indice nella coda

		tst.b	ResetMousePos(a5)	;Test se deve inserire un evento di posizionamento del mouse
		beq.s	IHCnomousepos		; Se no, salta
		move.l	myInputEvent(a5),a0
		move.l	a3,(a0)+		;ie_NextEvent
		move.b	#IECLASS_RAWMOUSE,(a0)+	;ie_Class
		clr.b	(a0)+			;ie_SubClass
		move.w	#IECODE_NOBUTTON,(a0)+	;ie_Code
		clr.w	(a0)+			;ie_Qualifier
		move.w	#319,(a0)+		;ie_X
		move.w	#239,(a0)+		;ie_Y
		move.l	myInputEvent(a5),a3
		clr.b	ResetMousePos(a5)
		bra.s	IHCnokp
IHCnomousepos
		;*** Per evitare che gli screen blanker creino
		;*** casini, immette ogni tanto un tasto shift
		;*** nella coda di input
		tst.w	keypassed-dati(a6)	;Test se è rimasto almeno un tasto nella coda
		bne.s	IHCnokp			; Se si, salta
		move.l	VBTimer2(a5),d0
		cmp.l	kptime-dati(a6),d0	;Sono passati 200/50esimi ?
		blt.s	IHCnokp			; Se no, salta
		add.l	#200,d0
		move.l	d0,kptime-dati(a6)	;Reinit contatore
		move.l	myInputEvent(a5),a0
		move.l	a3,(a0)+		;ie_NextEvent
		move.b	#IECLASS_RAWKEY,(a0)+	;ie_Class
		clr.b	(a0)+			;ie_SubClass
		move.w	#$60,(a0)+		;ie_Code	(Shift)
		clr.w	(a0)+			;ie_Qualifier
		clr.l	(a0)+			;ie_Addr
		move.l	myInputEvent(a5),a3
IHCnokp
		move.l	a3,d0
		movem.l	(sp)+,d2/a2-a6
		rts


;****************************************************************

		cnop	0,8

dati:

intuitionbase	dc.l	0
myscreen	dc.l	0

inputport	dc.l	0
inputreq	dc.l	0
keypressed	dc.l	0	;Pun. all'indice alla coda circolare dei tasti premuti
flagoff		dc.w	0	;Se<>0 allora IntuitionOff è stata già chiamata con successo

		cnop	0,8

InputHandler	ds.b	IS_SIZE

lastkeycode	dc.w	0
keypassed	dc.w	0	;Se=TRUE, è rimasto almeno un tasto nella coda di input
kptime		dc.l	0

inputdevicename	dc.b	"input.device",0
handlername	dc.b	"MyInputHandler",0

		cnop	0,8

	;Tabella di conversione da scancode a ascii.
	;Basta accedere alla tabella usando lo scancode come indice.

;keytable	dc.b	00,49,50,51,52,53,54,55,56,57,48,45,43,00,00,48	;$00
;		dc.b	81,87,69,82,84,89,85,73,79,80,91,93,00,49,50,51	;$10
;		dc.b	65,83,68,70,71,72,74,75,76,00,00,00,00,52,53,54 ;$20
;		dc.b	00,90,88,67,86,66,78,77,44,46,95,00,46,55,56,57 ;$30
;		dc.b	32,08,00,00,13,00,00,00,00,00,45,00,00,00,00,00 ;$40
;		dc.b	00,00,00,00,00,00,00,00,00,00,40,41,00,00,43,00	;$50
;		dc.b	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00	;$60

		xdef	ForwardKey,BackwardKey,RotateLeftKey,RotateRightKey
		xdef	SideLeftKey,SideRightKey,FireKey,AccelKey
		xdef	ForceSideKey,LookUpKey,ResetLookKey,LookDownKey
		xdef	SwitchKey

		xdef	K_ForwardKey,K_BackwardKey,K_RotateLeftKey,K_RotateRightKey
		xdef	K_SideLeftKey,K_SideRightKey,K_FireKey,K_AccelKey
		xdef	K_ForceSideKey,K_LookUpKey,K_ResetLookKey,K_LookDownKey
		xdef	K_SwitchKey

		xdef	M_ForwardKey,M_BackwardKey,M_RotateLeftKey,M_RotateRightKey
		xdef	M_SideLeftKey,M_SideRightKey,M_FireKey,M_AccelKey
		xdef	M_ForceSideKey,M_LookUpKey,M_ResetLookKey,M_LookDownKey
		xdef	M_SwitchKey

		xdef	ActiveKeyConfig,KeyboardKeyConfig,MouseKeyConfig

;*** Configurazione tastiera attiva

ActiveKeyConfig:

ForwardKey	dc.w	$4c
BackwardKey	dc.w	$4d
RotateLeftKey	dc.w	$4f
RotateRightKey	dc.w	$4e
SideLeftKey	dc.w	$31
SideRightKey	dc.w	$32
FireKey		dc.w	$64
AccelKey	dc.w	$63
ForceSideKey	dc.w	$60
LookUpKey	dc.w	$3d
ResetLookKey	dc.w	$2d
LookDownKey	dc.w	$1d
SwitchKey	dc.w	$40
		dc.w	$8180	;End

;*** Configurazione tastiera per controllo da tastiera

KeyboardKeyConfig:

K_ForwardKey	dc.w	$4c
K_BackwardKey	dc.w	$4d
K_RotateLeftKey	dc.w	$4f
K_RotateRightKey dc.w	$4e
K_SideLeftKey	dc.w	$31
K_SideRightKey	dc.w	$32
K_FireKey	dc.w	$64
K_AccelKey	dc.w	$63
K_ForceSideKey	dc.w	$60
K_LookUpKey	dc.w	$3d
K_ResetLookKey	dc.w	$2d
K_LookDownKey	dc.w	$1d
K_SwitchKey	dc.w	$40
		dc.w	$8180	;End

;*** Configurazione tastiera per controllo da mouse

MouseKeyConfig:

M_ForwardKey	dc.w	$4c
M_BackwardKey	dc.w	$4d
M_RotateLeftKey	dc.w	$2c
M_RotateRightKey dc.w	$2c
M_SideLeftKey	dc.w	$4f
M_SideRightKey	dc.w	$4e
M_FireKey	dc.w	$64
M_AccelKey	dc.w	$61
M_ForceSideKey	dc.w	$2c
M_LookUpKey	dc.w	$3d
M_ResetLookKey	dc.w	$2d
M_LookDownKey	dc.w	$1d
M_SwitchKey	dc.w	$40
		dc.w	$8180	;End

		cnop	0,4

;***********************************************************
;***
;***	Funzioni di supporto alla libreria Exec
;***
;***	Autore	Alberto Longo
;***
;***	Data	23 Dec 93
;***
;***
;***********************************************************
;
; struct MsgPort *CreatePort(char *msgPortName, long msgPortPriority)
;			sp+		20		24
; Variabili:
;
;  d3 = long		sig
;  a3 = struct MsgPort	*mp
;

	xdef	CreatePort
CreatePort
		movem.l	d2/d3/a3/a6,-(sp)

		moveq	#-1,d0
		move.l	4,a6
		jsr	_LVOAllocSignal(a6)
		move.l	d0,d3
		cmp.l	#-1,d3
		beq	CPreturn0

		move.l	#MP_SIZE,d0
		move.l	#MEMF_PUBLIC|MEMF_CLEAR,d1
		move.l	4,a6
		jsr	_LVOAllocMem(a6)
		tst.l	d0
		bne	CPallok
		move.l	d3,d0
		move.l	4,a6
		jsr	_LVOFreeSignal(a6)
		bra	CPreturn0
CPallok
		move.l	d0,a3
		move.l	20(sp),LN_NAME(a3)
		move.b	24(sp),LN_PRI(a3)
		move.b	#NT_MSGPORT,LN_TYPE(a3)
		move.b	#0,MP_FLAGS(a3)
		move.b	d3,MP_SIGBIT(a3)
		sub.l	a1,a1
		move.l	4,a6
		jsr	_LVOFindTask(a6)
		move.l	d0,MP_SIGTASK(a3)

		tst.l	20(sp)
		beq	CPnoname
		move.l	a3,a1
		move.l	4,a6
		jsr	_LVOAddPort(a6)
		bra	CPreturnok
CPnoname	pea	MP_MSGLIST(a3)
		jsr	NewList
		addq.w	#4,sp

CPreturnok	move.l	a3,d0
		bra	CPexit
CPreturn0
		moveq	#0,d0
CPexit		movem.l	(sp)+,d2/d3/a3/a6
		rts

;***********************************************************
;
; void DeletePort(struct MsgPort *myMsgPort)
;	  sp+			     12	
;

	xdef	DeletePort
DeletePort	movem.l	a3/a6,-(sp)

		move.l	12(sp),a3
		tst.l	LN_NAME(a3)
		beq	DPnoname
		move.l	a3,a1
		move.l	4,a6
		jsr	_LVORemPort(a6)
DPnoname
		move.b	#-1,LN_TYPE(a3)
		move.b	#-1,MP_MSGLIST+LH_HEAD(a3)
		moveq	#0,d0
		move.b	MP_SIGBIT(a3),d0
		move.l	4,a6
		jsr	_LVOFreeSignal(a6)
		move.l	12(sp),a1
		move.l	#MP_SIZE,d0
		move.l	4,a6
		jsr	_LVOFreeMem(a6)

		movem.l	(sp)+,a3/a6
		rts

;***********************************************************
;
; struct IORequest *CreateExtIO(struct MsgPort *IOReplyPort, ULONG size)
;			sp+			   12		    16
; variabili:
;
;  a3 = struct IORequest *iop
;

	xdef	CreateExtIO
CreateExtIO	movem.l	a3/a6,-(sp)

		tst.l	12(sp)
		beq	CEIOreturn0

		move.l	16(sp),d0
		move.l	#MEMF_PUBLIC|MEMF_CLEAR,d1
		move.l	4,a6
		jsr	_LVOAllocMem(a6)
		tst.l	d0
		beq	CEIOreturn0
		move.l	d0,a3

		move.b	#NT_MESSAGE,IO+MN+LN_TYPE(a3)
		move.w	18(sp),IO+MN_LENGTH(a3)
		move.l	12(sp),IO+MN_REPLYPORT(a3)

		move.l	a3,d0
		bra	CEIOexit

CEIOreturn0	moveq	#0,d0
CEIOexit	movem.l	(sp)+,a3/a6
		rts

;***********************************************************
;
; void DeleteExtIO(struct IORequest *myIOExtReq)
;	   sp+				8

	xdef	DeleteExtIO
DeleteExtIO	movem.l	a6,-(sp)

		tst.l	8(sp)
		beq	DEIOexit

		move.l	8(sp),a0

		move.b	#-1,IO+MN+LN_TYPE(a0)
		move.l	#-1,IO_DEVICE(a0)
		move.l	#-1,IO_UNIT(a0)

		move.l	8(sp),a1
		moveq	#0,d0
		move.w	IO+MN_LENGTH(a0),d0
		move.l	4,a6
		jsr	_LVOFreeMem(a6)

DEIOexit	movem.l	(sp)+,a6
		rts

;***********************************************************
;
; struct IOStdReq *CreateStdIO(struct MsgPort *IOReplyPort)
;			sp+			   4

	xdef	CreateStdIO
CreateStdIO
		move.l	sp,a0
		move.l	#IOSTD_SIZE,-(sp)
		move.l	4(a0),-(sp)
		jsr	CreateExtIO
		add.w	#8,sp

		rts

;***********************************************************
;
; void DeleteStdIO(struct IOStdReq *myIOStdReq)
;	   sp+				4

	xdef	DeleteStdIO
DeleteStdIO
		move.l	sp,a0
		move.l	4(a0),-(sp)
		jsr	DeleteExtIO
		add.w	#4,sp

		rts

;***********************************************************

NewList
	move.l	4(sp),a0
	move.l	a0,(a0)
	addq.l	#4,(a0)
	clr.l	4(a0)
	move.l	a0,8(a0)
	rts

;***********************************************************
