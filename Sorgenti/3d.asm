;***************************************************************
;*
;*	Gestione del rendering 3d
;*
;* Versione:
;*
;* - Uso del ray-casting con un unico raggio
;*
;* - Mappa composta da blocchi da 128*128
;*
;*
;***************************************************************

		include	'TMap.i'
		include	'MulDiv64.i'
		include	'System'

WINDOW_WIDTH	EQU	112
WINDOW_HEIGHT	EQU	140
PIXEL_TYPE	EQU	0	;0=pixel 1x1; 1=pixel 2x1; 2=pixel 1x2; 3=pixel 2x2


		xref	gfxbase
		xref	CurrentBitmap
		xref	sintable,costable
		xref	Yoffset
		xref	Map,Blocks,Edges
		xref	times
		xref	CLookHeightNum,LookHeightNum
		xref	CLookHeight,LookHeight

		xref	GetTime
		xref	MakeFrame,DrawObjects,CtrlCollPlayerObj

;***************************************************************

		xdef	Render3d
Render3d

		GETDBASE

;		jsr	ClearScreen

		jsr	CtrlCollPlayerObj	;Controllo collisioni con oggetti
		beq.s	moveok			;Salta se non ci sono collisioni

	;*** Ripristina vecchia posizione player
		move.l	PlayerX(a5),CPlayerX(a5)
		move.l	PlayerYcopy(a5),d0
		move.l	d0,CPlayerY(a5)
		add.l	PlayerYOsc(a5),d0	;Somma l'oscillazione verticale
		move.l	d0,PlayerY(a5)
		move.l	PlayerZ(a5),CPlayerZ(a5)
		move.w	CPlayerHeading(a5),PlayerHeading(a5)
		move.l	CPlayerViewDirX(a5),PlayerViewDirX(a5)
		move.l	CPlayerViewDirZ(a5),PlayerViewDirZ(a5)

		move.w	PlayerBlock(a5),CPlayerBlock(a5)
		move.l	PlayerBlockPun(a5),CPlayerBlockPun(a5)
		move.l	PlayerMapPun(a5),CPlayerMapPun(a5)

		bra.s	nomove

	;*** Campiona posizione attuale del player
moveok		move.l	CPlayerX(a5),PlayerX(a5)
		move.l	CPlayerY(a5),d0
		move.l	d0,PlayerYcopy(a5)
		add.l	PlayerYOsc(a5),d0	;Somma l'oscillazione verticale
		move.l	d0,PlayerY(a5)
		move.l	CPlayerZ(a5),PlayerZ(a5)
		move.w	CPlayerHeading(a5),PlayerHeading(a5)
		move.l	CPlayerViewDirX(a5),PlayerViewDirX(a5)
		move.l	CPlayerViewDirZ(a5),PlayerViewDirZ(a5)

		move.w	CPlayerBlock(a5),PlayerBlock(a5)
		move.l	CPlayerBlockPun(a5),PlayerBlockPun(a5)
		move.l	CPlayerMapPun(a5),PlayerMapPun(a5)
nomove

		move.l	CLookHeightNum(a5),LookHeightNum(a5)
		move.l	CLookHeight(a5),LookHeight(a5)

;		move.l	PlayerBlockPun(a5),a0
;		move.w	bl_FloorHeight(a0),d0
;		add.w	d0,PlayerY(a5)

		move.l	CSkyRotation(a5),d0
		lsr.l	#8,d0
		move.w	d0,SkyRotation(a5)

		clr.w	RayCont(a5)		;Azzera contatore raggi

		lea	RaycastObjects(a5),a1	;a1=pun. alla lista di dati relativi ai blocchi (intersecati dai raggi) che contengono oggetti.
		lea	vtable,a4
		lea	RayDirTab(a5),a3

		move.l	#-(WINDOW_STANDARD_WIDTH<<15),d7
Rxloop
	;*** Calcola il raggio passante per la colonna d7 a video
		move.l	PlayerViewDirZ(a5),d0
		move.l	d0,d3
		FIXMUL	d7,d4,d0,d1,d2,d3,d5,d6	;d0=ViewDirZ * X
		move.l	PlayerViewDirX(a5),d1
		move.l	d1,d2
		FIXMUL	d7,d4,d1,d0,d2,d3,d5,d6	;d1=ViewDirX * X
		asl.l	#7,d2			;d2=ViewDirX * D ,  con D=128
		asl.l	#7,d3			;d3=ViewDirZ * D ,  con D=128
		sub.l	d0,d2			;d2=RayDirX
		add.l	d1,d3			;d3=RayDirZ

		FIXMUL	windowYratio(a5),d0,d2,d1,d3,d4,d5,d6
		FIXMUL	windowYratio(a5),d0,d3,d1,d2,d4,d5,d6

		move.l	d2,RayDirX(a5)
		move.l	d3,RayDirZ(a5)

		move.l	d2,(a3)+	;Memorizza RayDirX nella tabella
		move.l	d3,(a3)+	;Memorizza RayDirZ nella tabella

		movem.l	d7/a3-a4,-(sp)
		bsr	RayCasting
		movem.l	(sp)+,d7/a3-a4

		addq.w	#1,RayCont(a5)

		add.l	#vtsize*MAX_BLOCK_VIEW,a4

		add.l	windowXratio(a5),d7
		cmp.l	#WINDOW_STANDARD_WIDTH<<15,d7
		blt	Rxloop

		clr.l	(a1)		;Segnala la fine della lista di blocchi in vista contenenti oggetti

        IFD DEVMODE
	jsr	GetTime
	move.l	d0,times(a5)	;Ray casting time
        ENDC

		jsr	MakeFrame

        IFD DEVMODE
	jsr	GetTime
	move.l	d0,times+4(a5)	;Wall rendering time
        ENDC

		jsr	DrawObjects

        IFD DEVMODE
	jsr	GetTime
	move.l	d0,times+8(a5)	;Object rendering time
        ENDC

		rts






;*********************************************************************
; \1 = vertical edge
; \2 = orizzontal edge
; \3 = sompointerx (2 or -2)

RayCastX	MACRO

		move.l	d4,a4		;Copia d4 in a4

		move.l	d5,d1
		FIXMUL	d2,d3,d1,d0,d4,d5,d6,d7
		add.l	PlayerZ(a5),d1	;d1=Z+=(contdistx * RayDirZ)

		FIXMUL	d2,d3,d4,d0,d1,d5,d6,d7
		move.l	d4,d3		;d3=DZ=(somdistx * RayDirZ)

		move.l	d7,d0
		FIXMUL	RayDirX(a5),d4,d0,d1,d2,d3,d5,d6
		add.l	PlayerX(a5),d0	;d0=X+=(contdistz * RayDirX)

		move.l	d6,d2
		FIXMUL	RayDirX(a5),d4,d2,d0,d1,d3,d5,d6
                ;d2=DX=(somdistz * RayDirX)

		;*** Compilazione condizionale per far si che
		;*** i brush di Edge2 e Edge3 non abbiano lo stesso
		;*** orientamento dei brush di Edge4 e Edge1 rispettivamente.
		IFEQ	\1-bl_Edge3
		not.l	d1
		neg.l	d3
		ENDC
		IFEQ	\2-bl_Edge2
		not.l	d0
		neg.l	d2
		and.l	#(((BLOCK_SIZE-1)<<16)+$ffff),d0
		ENDC

		and.l	#(((BLOCK_SIZE-1)<<16)+$ffff),d1

		move.l	Blocks(a5),a6	;a6=Blocks pun.

		clr.l	d4
		move.w	2(a0),d4		;Test if there's an object in the first block
		beq.s	RCXnofrstobj\@
		move.l	d4,(a1)+		;Save object number
		move.l	a0,(a1)			;Save map pointer
		addq.l	#2,(a1)+
		clr.w	2(a0)
RCXnofrstobj\@
		move.w	PlayerBlock(a5),a5	;a5=usato per scartare i blocchi uguali
		clr.l	d4
		cmp.l	d7,d5		;compare contdistx and contdistz
		bgt.s	RCXinloopz\@
		bra.s	RCXinloopx\@

		cnop	0,8
RCXloop\@
		cmp.l	a5,d4		;Test se blocco uguale a quello precedente
		beq.s	RCXnx\@
		move.l	d4,a5
		move.l	d5,(a3)+		;Save distance=contdistx
		lsl.l	#5,d4
		add.l	a6,d4
		move.l	d4,(a3)+		;Save block pointer
		move.l	d1,(a3)+		;Save Z for brush column offset calculation
		move.l	(\1.w,d4.l),(a3)+	;Save Pointer to the Edge
		clr.l	d4
RCXnx\@		move.w	2(a0),d4		;Test if there's an object here
		beq.s	RCXnxobj\@
		move.l	d4,(a1)+		;Save object number
		move.l	a0,(a1)			;Save map pointer
		addq.l	#2,(a1)+
		clr.w	2(a0)
RCXnxobj\@	add.l	d3,d1			;Z+=DZ
		add.l	a4,d5			;contdistx+=somdistx

		cmp.l	d7,d5		;compare contdistx and contdistz
		ble.s	RCXinloopx\@

RCXinloopz\@	add.l	a2,a0			;pointer+=sompointerz
		move.w	(a0),d4			;d4=block
		bmi.s	RCXstopwall1\@

		cmp.l	a5,d4		;Test se blocco uguale a quello precedente
		beq.s	RCXnz\@
		move.l	d4,a5
		move.l	d7,(a3)+		;Save distance=contdistz
		lsl.l	#5,d4
		add.l	a6,d4
		move.l	d4,(a3)+		;Save block pointer
		move.l	d0,(a3)+		;Save X for brush column offset calculation
		move.l	(\2.w,d4.l),(a3)+	;Save Pointer to the Edge
		clr.l	d4
RCXnz\@		move.w	2(a0),d4		;Test if there's an object here
		beq.s	RCXnzobj\@
		move.l	d4,(a1)+		;Save object number
		move.l	a0,(a1)			;Save map pointer
		addq.l	#2,(a1)+
		clr.w	2(a0)
RCXnzobj\@	add.l	d2,d0			;X+=DX
		add.l	d6,d7			;contdistz+=somdistz
RCXinloopx\@
		IFEQ	\3-2
		addq.l	#4,a0			;pointer+=sompointerx
		ELSEIF
		subq.l	#4,a0			;pointer+=sompointerx
		ENDC
		move.w	(a0),d4			;d4=block
		bpl.s	RCXloop\@

RCXstopwall2\@
		move.l	d5,(a3)+		;Save distance=contdistx
		neg.w	d4
		lsl.l	#5,d4
		add.l	a6,d4
		move.l	d4,(a3)+		;Save block pointer
		move.l	d1,(a3)+		;Save Z for brush column offset calculation
		move.l	(\1.w,d4.l),(a3)+	;Save Pointer to the right Edge
		move.w	#-1,(a3)+
		GETDBASE
		move.w	RayCont(a5),d0
		and.b	#3,d0
		bne.s	RCXOout\@
		moveq	#10,d1			;init contatore
		addq.l	#2,a0
		clr.l	d4
		bra.s	RCXOnxobj\@

RCXstopwall1\@
		move.l	d7,(a3)+		;Save distance=contdistz
		neg.w	d4
		lsl.l	#5,d4
		add.l	a6,d4
		move.l	d4,(a3)+		;Save block pointer
		move.l	d0,(a3)+		;Save X for brush column offset calculation
		move.l	(\2.w,d4.l),(a3)+	;Save Pointer to the right Edge
		move.w	#-1,(a3)+
		GETDBASE
		move.w	RayCont(a5),d0
		and.b	#3,d0
		bne.s	RCXOout\@
		moveq	#10,d1			;init contatore
		addq.l	#2,a0
		clr.l	d4
		bra.s	RCXOnzobj\@

		cnop	0,8
			;***** Ciclo di raycasting per i soli oggetti

RCXOloop\@	move.w	(a0),d4			;Test if there's an object here
		beq.s	RCXOnxobj\@
		bmi.s	RCXOout\@
		move.l	d4,(a1)+		;Save object number
		move.l	a0,(a1)+		;Save map pointer
		clr.w	(a0)
RCXOnxobj\@	add.l	a4,d5			;contdistx+=somdistx

		cmp.l	d7,d5			;compare contdistx and contdistz
		ble.s	RCXOinloopx\@

RCXOinloopz\@	add.l	a2,a0			;pointer+=sompointerz
		move.w	(a0),d4			;Test if there's an object here
		beq.s	RCXOnzobj\@
		bmi.s	RCXOout\@		;Esce se incontrati limiti mappa oggetti
		move.l	d4,(a1)+		;Save object number
		move.l	a0,(a1)+		;Save map pointer
		clr.w	(a0)
RCXOnzobj\@	add.l	d6,d7			;contdistz+=somdistz

RCXOinloopx\@
		IFEQ	\3-2
		addq.l	#4,a0			;pointer+=sompointerx
		ELSEIF
		subq.l	#4,a0			;pointer+=sompointerx
		ENDC
		dbra	d1,RCXOloop\@		;Decrementa contatore
RCXOout\@

		ENDM

;*********************************************************************
; \1 = orizzontal edge
; \2 = vertical edge
; \3 = sompointerx (2 or -2)

RayCastZ	MACRO
		clr.l	d6
		DIVS64	d2,d3,d6,d0,d1,d4	;d6=somdistz=(SZ / RaydirZ) = distanza, lungo il raggio, tra un blocco e il successivo

		move.l	d1,d7
		sub.l	PlayerZ(a5),d7
		move.l	d7,d3
		swap	d3
		ext.l	d3
		swap	d7
		clr.w	d7
		DIVS64	d2,d3,d7,d0,d1,d4	;d7=contdistx=((Z-PlayerZ) / RayDirZ)


		move.l	d4,a4		;Copia d4 in a4

		move.l	d5,d1
		FIXMUL	d2,d3,d1,d0,d4,d5,d6,d7
		add.l	PlayerZ(a5),d1	;d1=Z+=(contdistx * RayDirZ)

		FIXMUL	d2,d3,d4,d0,d1,d5,d6,d7
		move.l	d4,d3		;d3=DZ=(somdistx * RayDirZ)

		move.l	d7,d0
		FIXMUL	RayDirX(a5),d4,d0,d1,d2,d3,d5,d6
		add.l	PlayerX(a5),d0	;d0=X+=(contdistz * RayDirX)

		move.l	d6,d2
		FIXMUL	RayDirX(a5),d4,d2,d0,d1,d3,d5,d6
		;d2=DX=(somdistz * RayDirX)

		;*** Compilazione condizionale per far si che
		;*** i brush di Edge2 e Edge3 non abbiano lo stesso
		;*** orientamento dei brush di Edge4 e Edge1 rispettivamente.
		IFEQ	\1-bl_Edge2
		not.l	d0
		neg.l	d2
		ENDC
		IFEQ	\2-bl_Edge3
		not.l	d1
		neg.l	d3
		and.l	#(((BLOCK_SIZE-1)<<16)+$ffff),d1
		ENDC

		and.l	#(((BLOCK_SIZE-1)<<16)+$ffff),d0

		move.l	Blocks(a5),a6	;a6=Blocks pun.

		clr.l	d4
		move.w	2(a0),d4		;Test if there's an object in the first block
		beq.s	RCZnofrstobj\@
		move.l	d4,(a1)+		;Save object number
		move.l	a0,(a1)			;Save map pointer
		addq.l	#2,(a1)+
		clr.w	2(a0)
RCZnofrstobj\@
		move.w	PlayerBlock(a5),a5	;a5=usato per scartare i blocchi uguali
		clr.l	d4
		cmp.l	d5,d7		;compare contdistx and contdistz
		bgt.s	RCZinloopx\@
		bra.s	RCZinloopz\@

		cnop	0,8
RCZloop\@
		cmp.l	a5,d4		;Test se blocco uguale a quello precedente
		beq.s	RCZnz\@
		move.l	d4,a5
		move.l	d7,(a3)+		;Save distance=contdistz
		lsl.l	#5,d4
		add.l	a6,d4
		move.l	d4,(a3)+		;Save block pointer
		move.l	d0,(a3)+		;Save X for brush column offset calculation
		move.l	(\1.w,d4.l),(a3)+	;Save Pointer to the Edge
		clr.l	d4
RCZnz\@		move.w	2(a0),d4		;Test if there's an object here
		beq.s	RCZnzobj\@
		move.l	d4,(a1)+		;Save object number
		move.l	a0,(a1)			;Save map pointer
		addq.l	#2,(a1)+
		clr.w	2(a0)
RCZnzobj\@	add.l	d2,d0			;X+=DX
		add.l	d6,d7			;contdistz+=somdistz

		cmp.l	d5,d7			;compare contdistx and contdistz
		ble.s	RCZinloopz\@

RCZinloopx\@
		IFEQ	\3-2
		addq.l	#4,a0			;pointer+=sompointerx
		ELSEIF
		subq.l	#4,a0			;pointer+=sompointerx
		ENDC
		move.w	(a0),d4			;d4=block
		bmi.s	RCZstopwall1\@

		cmp.l	a5,d4		;Test se blocco uguale a quello precedente
		beq.s	RCZnx\@
		move.l	d4,a5
		move.l	d5,(a3)+		;Save distance=contdistx
		lsl.l	#5,d4
		add.l	a6,d4
		move.l	d4,(a3)+		;Save block pointer
		move.l	d1,(a3)+		;Save Z for brush column offset calculation
		move.l	(\2.w,d4.l),(a3)+	;Save Pointer to the Edge
		clr.l	d4
RCZnx\@		move.w	2(a0),d4		;Test if there's an object here
		beq.s	RCZnxobj\@
		move.l	d4,(a1)+		;Save object number
		move.l	a0,(a1)			;Save map pointer
		addq.l	#2,(a1)+
		clr.w	2(a0)
RCZnxobj\@	add.l	d3,d1			;Z+=DZ
		add.l	a4,d5			;contdistx+=somdistx
RCZinloopz\@
		add.l	a2,a0			;pointer+=sompointerz
		move.w	(a0),d4			;d4=block
		bpl.s	RCZloop\@
RCZstopwall2\@
		move.l	d7,(a3)+		;Save distance=contdistz
		neg.w	d4
		lsl.l	#5,d4
		add.l	a6,d4
		move.l	d4,(a3)+		;Save block pointer
		move.l	d0,(a3)+		;Save X for brush column offset calculation
		move.l	(\1.w,d4.l),(a3)+	;Save Pointer to the right Edge
		move.w	#-1,(a3)+
		GETDBASE
		move.w	RayCont(a5),d0
		and.b	#3,d0
		bne.s	RCZOout\@
		moveq	#10,d1			;init contatore
		addq.l	#2,a0
		clr.l	d4
		bra.s	RCZOnzobj\@

RCZstopwall1\@
		move.l	d5,(a3)+		;Save distance=contdistx
		neg.w	d4
		lsl.l	#5,d4
		add.l	a6,d4
		move.l	d4,(a3)+		;Save block pointer
		move.l	d1,(a3)+		;Save Z for brush column offset calculation
		move.l	(\2.w,d4.l),(a3)+	;Save Pointer to the right Edge
		move.w	#-1,(a3)+
		GETDBASE
		move.w	RayCont(a5),d0
		and.b	#3,d0
		bne.s	RCZOout\@
		moveq	#10,d1			;init contatore
		addq.l	#2,a0
		clr.l	d4
		bra.s	RCZOnxobj\@

		cnop	0,8
			;***** Ciclo di raycasting per i soli oggetti

RCZOloop\@	move.w	(a0),d4			;Test if there's an object here
		beq.s	RCZOnzobj\@
		bmi.s	RCZOout\@
		move.l	d4,(a1)+		;Save object number
		move.l	a0,(a1)+		;Save map pointer
		clr.w	(a0)
RCZOnzobj\@	add.l	d6,d7			;contdistz+=somdistz

		cmp.l	d5,d7			;compare contdistx and contdistz
		ble.s	RCZOinloopz\@

RCZOinloopx\@
		IFEQ	\3-2
		addq.l	#4,a0			;pointer+=sompointerx
		ELSEIF
		subq.l	#4,a0			;pointer+=sompointerx
		ENDC
		move.w	(a0),d4			;Test if there's an object here
		beq.s	RCZOnxobj\@
		bmi.s	RCZOout\@		;Esce se incontrati limiti mappa oggetti
		move.l	d4,(a1)+		;Save object number
		move.l	a0,(a1)+		;Save map pointer
		clr.w	(a0)
RCZOnxobj\@	add.l	a4,d5			;contdistx+=somdistx

RCZOinloopz\@	add.l	a2,a0			;pointer+=sompointerz
		dbra	d1,RCZOloop\@		;Decrementa contatore
RCZOout\@

		ENDM

;*********************************************************************
; Cast a ray in the map

RayCasting
		move.l	PlayerX(a5),d0	;d0=X	 (PlayerX)
		and.l	#GRID_AND_L,d0
		move.l	PlayerZ(a5),d1	;d1=Z	 (PlayerZ)
		and.l	#GRID_AND_L,d1

;		move.l	Map(a5),a0		;a0=Map pun.
;		move.l	d0,d5
;		lsr.l	#(BLOCK_SIZE_B+1),d5
;		or.l	d1,d5
;		add.l	d5,d5
;		swap	d5
;		lea	(a0,d5.w*4),a0	;a0=Pointer to map
		move.l	PlayerMapPun(a5),a0	;a0=Pointer to map

		move.l	a4,a3		;a3=Pun. vtable

		tst.l	d2
		bpl.s	RCd2pl
		neg.l	d2
RCd2pl		tst.l	d3
		bpl.s	RCd3pl
		neg.l	d3
RCd3pl
		cmp.l	d2,d3		;jump if ABS(RayDirZ)>ABS(RayDirX)
		bgt	RCZdominant

;***** Ciclo per raggi con RayDirX>=RayDirZ

				;*** Tentativo di aggiustare errori di precisione e di overflow
		cmp.l	#$10000,d3
		bge.s	RCXj1
		lsl.l	#8,d3
		lsl.l	#7,d3
		cmp.l	d2,d3
		bge.s	RCXj1
		move.l	#128,RayDirZ(a5)
RCXj1

		move.l	RayDirX(a5),d2
		bmi	RCXrdxmin		;RayDirX<0 ?
		move.l	#BLOCK_SIZE,d3		;d3=SX
		add.l	#BLOCK_SIZE<<16,d0	;d0=X+=SX

		clr.l	d4
		DIVS64	d2,d3,d4,d0,d1,d5	;d4=somdistx=(SX / RaydirX) = distanza, lungo il raggio, tra un blocco e il successivo

		move.l	d0,d5
		sub.l	PlayerX(a5),d5
		move.l	d5,d3
		swap	d3
		ext.l	d3
		swap	d5
		clr.w	d5
		DIVS64	d2,d3,d5,d0,d1,d4	;d5=contdistx=((X-PlayerX) / RayDirX)

		move.l	RayDirZ(a5),d2
		bmi	RCXrdzmin		;RayDirZ<0 ?
		bne.s	RCXrdzn1		;RayDirZ=0 ?
		clr.l	d6			;d6=somdistz
		clr.l	d7			;d7=contdistz
		bra	RCXrdzmok1
RCXrdzn1

;***** Ciclo per raggi con RayDirX>=RayDirZ e RayDirX>0 e RayDirZ>0

		move.l	#BLOCK_SIZE,d3		;d3=SZ
		add.l	#BLOCK_SIZE<<16,d1	;d1=Z+=SZ
		move.w	#GRID_SIZE<<2,a2	;a2=sompointerz

		clr.l	d6
		DIVS64	d2,d3,d6,d0,d1,d4	;d6=somdistz=(SZ / RaydirZ) = distanza, lungo il raggio, tra un blocco e il successivo

		move.l	d1,d7
		sub.l	PlayerZ(a5),d7
		move.l	d7,d3
		swap	d3
		ext.l	d3
		swap	d7
		clr.w	d7
		DIVS64	d2,d3,d7,d0,d1,d4	;d7=contdistx=((Z-PlayerZ) / RayDirZ)
RCXrdzmok1
		RayCastX bl_Edge3,bl_Edge4,2	;Call macro

		rts


;***** Ciclo per raggi con RayDirX>=RayDirZ e RayDirX>0 e RayDirZ<0

RCXrdzmin	move.l	#-(BLOCK_SIZE),d3	;d3=SZ
		move.w	#-(GRID_SIZE<<2),a2	;a2=sompointerz

		clr.l	d6
		DIVS64	d2,d3,d6,d0,d1,d4	;d6=somdistz=(SZ / RaydirZ) = distanza, lungo il raggio, tra un blocco e il successivo

		move.l	d1,d7
		sub.l	PlayerZ(a5),d7
		move.l	d7,d3
		swap	d3
		ext.l	d3
		swap	d7
		clr.w	d7
		DIVS64	d2,d3,d7,d0,d1,d4	;d7=contdistx=((Z-PlayerZ) / RayDirZ)

		RayCastX bl_Edge3,bl_Edge2,2	;Call macro

		rts




;***** Ciclo per raggi con RayDirX>=RayDirZ e RayDirX<0

RCXrdxmin	move.l	#-(BLOCK_SIZE),d3	;d3=SX

		clr.l	d4
		DIVS64	d2,d3,d4,d0,d1,d5	;d4=somdistx=(SX / RaydirX) = distanza, lungo il raggio, tra un blocco e il successivo

		move.l	d0,d5
		sub.l	PlayerX(a5),d5
		move.l	d5,d3
		swap	d3
		ext.l	d3
		swap	d5
		clr.w	d5
		DIVS64	d2,d3,d5,d0,d1,d4	;d5=contdistx=((X-PlayerX) / RayDirX)

		move.l	RayDirZ(a5),d2
		bmi	RCXrdzmin2		;RayDirZ<0 ?
		bne.s	RCXrdzn2		;RayDirZ=0 ?
		clr.l	d6			;d6=somdistz
		clr.l	d7			;d7=contdistz
		bra	RCXrdzmok2
RCXrdzn2

;***** Ciclo per raggi con RayDirX>=RayDirZ e RayDirX<0 e RayDirZ>0

		move.l	#BLOCK_SIZE,d3		;d3=SZ
		add.l	#BLOCK_SIZE<<16,d1	;d1=Z+=SZ
		move.w	#GRID_SIZE<<2,a2	;a2=sompointerz

		clr.l	d6
		DIVS64	d2,d3,d6,d0,d1,d4	;d6=somdistz=(SZ / RaydirZ) = distanza, lungo il raggio, tra un blocco e il successivo

		move.l	d1,d7
		sub.l	PlayerZ(a5),d7
		move.l	d7,d3
		swap	d3
		ext.l	d3
		swap	d7
		clr.w	d7
		DIVS64	d2,d3,d7,d0,d1,d4	;d7=contdistx=((Z-PlayerZ) / RayDirZ)
RCXrdzmok2
		RayCastX bl_Edge1,bl_Edge4,-2	;Call macro

		rts


;***** Ciclo per raggi con RayDirX>=RayDirZ e RayDirX<0 e RayDirZ<0

RCXrdzmin2	move.l	#-(BLOCK_SIZE),d3	;d3=SZ
		move.w	#-(GRID_SIZE<<2),a2	;a2=sompointerz

		clr.l	d6
		DIVS64	d2,d3,d6,d0,d1,d4	;d6=somdistz=(SZ / RaydirZ) = distanza, lungo il raggio, tra un blocco e il successivo

		move.l	d1,d7
		sub.l	PlayerZ(a5),d7
		move.l	d7,d3
		swap	d3
		ext.l	d3
		swap	d7
		clr.w	d7
		DIVS64	d2,d3,d7,d0,d1,d4	;d7=contdistx=((Z-PlayerZ) / RayDirZ)

		RayCastX bl_Edge1,bl_Edge2,-2	;Call macro

		rts


;-----------------------------------------------------




;***** Ciclo per raggi con RayDirZ>RayDirX

RCZdominant
				;*** Tentativo di aggiustare errori di precisione e di overflow
		cmp.l	#$10000,d2
		bge.s	RCZj1
		lsl.l	#8,d2
		lsl.l	#7,d2
		cmp.l	d3,d2
		bge.s	RCZj1
		move.l	#128,RayDirX(a5)
RCZj1

		move.l	RayDirX(a5),d2
		bmi	RCZrdxmin		;RayDirX<0 ?
		bne.s	RCZrdxn1		;RayDirX=0 ?
		clr.l	d4			;d4=somdistx
		clr.l	d5			;d5=contdistx
		bra	RCZrdxmok1
RCZrdxn1	move.l	#BLOCK_SIZE,d3		;d3=SX
		add.l	#BLOCK_SIZE<<16,d0	;d0=X+=SX

		clr.l	d4
		DIVS64	d2,d3,d4,d0,d1,d5	;d4=somdistx=(SX / RaydirX) = distanza, lungo il raggio, tra un blocco e il successivo

		move.l	d0,d5
		sub.l	PlayerX(a5),d5
		move.l	d5,d3
		swap	d3
		ext.l	d3
		swap	d5
		clr.w	d5
		DIVS64	d2,d3,d5,d0,d1,d4	;d5=contdistx=((X-PlayerX) / RayDirX)
RCZrdxmok1
		move.l	RayDirZ(a5),d2
		bmi	RCZrdzmin1		;RayDirZ<0 ?

;***** Ciclo per raggi con RayDirZ>RayDirX e RayDirX>0 e RayDirZ>0

		move.l	#BLOCK_SIZE,d3		;d3=SZ
		add.l	#BLOCK_SIZE<<16,d1	;d1=Z+=SZ
		move.w	#GRID_SIZE<<2,a2	;a2=sompointerz

		RayCastZ bl_Edge4,bl_Edge3,2	;Call macro

		rts


;***** Ciclo per raggi con RayDirZ>RayDirX e RayDirX>0 e RayDirZ<0

RCZrdzmin1	move.l	#-(BLOCK_SIZE),d3	;d3=SZ
		move.w	#-(GRID_SIZE<<2),a2	;a2=sompointerz

		RayCastZ bl_Edge2,bl_Edge3,2	;Call macro

		rts


;***** Ciclo per raggi con RayDirZ>RayDirX e RayDirX<0

RCZrdxmin	move.l	#-(BLOCK_SIZE),d3	;d3=SX

		clr.l	d4
		DIVS64	d2,d3,d4,d0,d1,d5	;d4=somdistx=(SX / RaydirX) = distanza, lungo il raggio, tra un blocco e il successivo

		move.l	d0,d5
		sub.l	PlayerX(a5),d5
		move.l	d5,d3
		swap	d3
		ext.l	d3
		swap	d5
		clr.w	d5
		DIVS64	d2,d3,d5,d0,d1,d4	;d5=contdistx=((X-PlayerX) / RayDirX)

		move.l	RayDirZ(a5),d2
		bmi	RCZrdzmin2		;RayDirZ<0 ?

;***** Ciclo per raggi con RayDirZ>RayDirX e RayDirX<0 e RayDirZ>0

		move.l	#BLOCK_SIZE,d3		;d3=SZ
		add.l	#BLOCK_SIZE<<16,d1	;d1=Z+=SZ
		move.w	#GRID_SIZE<<2,a2	;a2=sompointerz

		RayCastZ bl_Edge4,bl_Edge1,-2	;Call macro

		rts


;***** Ciclo per raggi con RayDirZ>RayDirX e RayDirX<0 e RayDirZ<0

RCZrdzmin2	move.l	#-(BLOCK_SIZE),d3	;d3=SZ
		move.w	#-(GRID_SIZE<<2),a2	;a2=sompointerz

		RayCastZ bl_Edge2,bl_Edge1,-2	;Call macro

		rts


                IFEQ __CPU-68060
                IFND USEFPU

        ; divs.l    d2,d1:d0
        ; Thanks to Thomas Richter
        ;https://eab.abime.net/showthread.php?t=104901
        ;; signed 64/32 divide, 68060 function
SDiv64:
    movem.l    d2-d7/a2-a5,-(sp)

    sub.l    a2,a2        ;sign flag divisor
    sub.l    a3,a3        ;sign flag dividend
    move.l    d0,a4
    move.l    d1,a5        ;save original contents

    move.l    d2,d7        ;save divisor
    bpl.s    1$        ;make positive
    addq.w    #1,a2        ;set flag
    neg.l    d7
1$:

    move.l    d0,d6
    move.l    d1,d5        ;save dividend
    bpl.s    2$
    addq.w    #1,a3        ;set flag
    neg.l    d6
    negx.l    d5        ;invert
2$:
    tst.l    d5        ;is the high non-zero? If so, full divide
    bne.s    3$

    tst.l    d6        ;is low zero?
    beq.s    10$        ;yes, we are done

    ;; here low <> 0
    cmp.l    d6,d7        ;is the divisor <= lo (dividend)
    bls.s    5$        ;yes, use a 32-bit divide

    exg.l    d5,d6        ;q = 0, r = dividend
    bra.s    6$        ;can't divide, done
5$:    
    divul.l    d7,d5:d6                    ;# it's only a 32/32 bit div!
    bra.b    6$
3$:    ;; full 64 bit case here. do we have an overflow?
    cmp.l    d5,d7
    bls.s    7$        ;yes
    ;; here full 64/32 divide
    bsr    AlgorithmD    ;perform classical algorithm D from Knuth
    ;; remainder in d6, quotient in d5
6$:    ;done here, check whether there is a sign switch
    cmp.w    #0,a3
    beq.s    8$
    neg.l    d5        ;remainder has the same sign as dividend
8$:
    cmp.w    a2,a3        ;same signs of divisor and dividend?
    beq.s    9$

    cmp.l    #$80000000,d6    ;representable as 32-bit negative number?
    bhi.s    7$        ;overflow
    neg.l    d6        ;make a 2s complement for quotient
    bra.s    10$
9$:                ;here positive
    tst.l    d6        ;will fit into 32 bits?
    bmi.s    7$        ;overflow if not
10$:                ;here done
    move.l    d5,d1        ;remainder -> d1
    move.l    d6,d0        ;quotient -> d0
    andi.b    #$fc,ccr    ;clear V and C
    bra.s    11$
7$:
    move.l    a4,d0        ;restore original register content
    move.l    a5,d1
    ori.b    #$2,ccr        ;set overflow bit
11$:
    movem.l    (sp)+,d2-d7/a2-a5
    rts

    ;; division algorithm. This is either a
    ;; full algorithmD from Knuth "The Art of Programming", Vol.2
    ;; or using a 32:16 division in case the divisor fits
    ;; into 16 bits.
    ;; This algorithm divides d5:d6 by d7
AlgorithmD:    
    swap    d7
    tst.w    d7
    bne.s    1$
    ;; ok, we only need to divide by 16 bits, so
    ;; things are somewhat simpler
    swap    d7        ; restore divisor
    ;; note that we already know that the division
    ;; does not overflow (checked upwards)
    moveq    #0,d1

    swap    d5        ; same as r*b if previous step rqd
    swap    d6        ; get u3 to lsw position
    move.w    d6,d5        ; rb + u3

    divu.w    d7,d5

    move.w    d5,d1        ; first quotient word
    swap    d6        ; get u4
    move.w    d6,d5        ; rb + u4

    divu.w    d7,d5

    swap    d1
    move.w    d5,d1        ; 2nd quotient 'digit'
    clr.w    d5        
    swap    d5        ;now remainder
    move.l    d1,d6        ; and quotient
    rts    
1$:
    swap d7            ; restore divisor
    ;; classical algorithm D.
    ;; In this algorithm, the divisor is treated as a 2 digit (word) number
    ;; which is divided into a 3 digit (word) dividend to get one quotient
    ;; digit (word). After subtraction, the dividend is shifted and the
    ;; process repeated. Before beginning, the divisor and quotient are
    ;; 'normalized' so that the process of estimating the quotient digit
    ;; will yield verifiably correct results..
    moveq    #0,d4                        ;all the flags in d4
ddnchk:
    ;; normalize/upshift the divisor to use full 32 bits, adjust dividend with it.
    ;; the number of shifts goes into d4
    ;; note that d7 is at least 0x00010000
    tst.l    d7
    bmi.b    ddnormalized
ddnchk2:
    addq.l    #$1,d4                        ;count in d4
    lsl.l    #$1,d6                        ;# shift u4,u3 with overflow to u2
    roxl.l    #$1,d5                        ;# shift u1,u2 
    lsl.l    #$1,d7                        ;# shift the divisor
    bpl.b    ddnchk2

    swap    d4                        ;keep lo-word free

ddnormalized:
    ;; Now calculate an estimate of the quotient words (msw first, then lsw).
    ;; The comments use subscripts for the first quotient digit determination.
    move.l    d7,d3                        ;# divisor
    move.l    d5,d2                        ;# dividend mslw
    swap    d3
    swap    d2
    move.w    #$ffff,d1                    ;# use max trial quotient word
    cmp.w    d3,d2                        ;# V1 = U1 ?
    beq.b    ddadj0

    move.l    d5,d1
    divu.w    d3,d1                        ;# use quotient of mslw/msw
ddadj0:

    ;; now test the trial quotient and adjust. This step plus the
    ;; normalization assures (according to Knuth) that the trial
    ;; quotient will be at worst 2 too large.
    ;; NOTE: We do not perform step D3 here. This is not required, as
    ;; D4 is sufficient for adjusting a quotient that has been guessed
    ;; "too large". At most, it can be off by two (easy to prove).

    move.l    d7,d2        ;V1V2->d2

    ;; at this stage, d1 is scaled by 1<<16. Evaluate the 32x32 product d1'0xd7->d2(hi),d3(lo)
    ;; d0,d2,d3,d6 are scratches

    move.l    d7,d0        ;V1V2->d0
    swap     d2        ;get hi of d7 = V1
    mulu.w    d1,d0        ;V2*q: scaled by 2^16, must be split in higher/lower pair
    mulu.w    d1,d2        ;V1*q: the upper 32 bit = V1*q, must be scaled by 2^32
    move.l    d0,d3        ;get lo
    clr.w    d0        ;clear lo
    swap    d3        ;part of it
    swap    d0        ;swap: scale by 2^16: This must be added to hi
    clr.w    d3        ;shift up by 16
    add.l    d0,d2        ;add to hi

    sub.l    d3,d6        
    subx.l    d2,d5        ; subtract double precision
    bcc.s    dd2nd        ; no carry, do next quotient digit

    ;; need to add back divisor longword to current ms 3 digits of dividend
    ;; - according to Knuth, this is done only 2 out of 65536 times for random
    ;; divisor, dividend selection.
    ;;
    ;; thor: computations show that this loop is run at most twice.
    ;; this is better than knuth in this specific case because we
    ;; avoid the multiplications in D3 and this step here (D4) is 
    ;; only addition.

    move.l    d7,d3
    move.l    d7,d2        ; add V1V20 back to U1U2U3U4
    swap    d3
    clr.w    d2
    clr.w    d3
    swap    d2        ; d3 now ls word of divisor
ddaddup:
    subq.l    #$1,d1        ; q is one too large
    add.l    d3,d6        ; aligned with 3rd word of dividend
    addx.l    d2,d5
    bcc    ddaddup        ; until we're positive again
dd2nd:
    tst.l    d4
    bmi.s    ddremain

;# first quotient digit now correct. store digit and shift the
;# (subtracted) dividend 
    move.w    d1,d4        ;keep hi-quotient
    swap    d5
    swap    d6
    move.w    d6,d5
    clr.w    d6        ;shift remainder up by 16 bits
    bset    #31,d4        ;second digit
    bra.s    ddnormalized
ddremain:
;# add 2nd word to quotient, get the remainder.
    swap    d1
    move.w    d4,d1        ;get result of previous division
    swap    d1        ;restore order
    swap    d4        ;restore normalization counter

;# shift down one word/digit to renormalize remainder.
    move.w    d5,d6
    swap    d6
    swap    d5
    clr.l    d7
    move.b    d4,d7
    beq.s    ddrn
    ;; shift d5:d6 to the right by d7 bits, d5 is high
    move.l    d5,d0
    lsr.l    d7,d6        ; shift low out
    ror.l    d7,d0        ; move low bits of high to high
    lsr.l    d7,d5        ; shift high down
    eor.l    d5,d0        ; high bits are in d0
    or.l    d0,d6        ; into d6
ddrn:
    move.l    d6,d5        ; remainder
    move.l    d1,d6
    rts
                ENDC    ; !USEFPU
                ENDC    ; 68060


;*********************************************************************

		section	TABLES,BSS

		xdef	vtable

		ds.b	vtsize					;Non rimuovere.
vtable		ds.b	WINDOW_MAX_WIDTH*vtsize*MAX_BLOCK_VIEW	;Vedi in TMap.i per la descrizione


		xdef	automap

automap		ds.b	(MAP_SIZE*MAP_SIZE)>>3	;Mappa per l'automapping:
						; ogni bit a 1 rappresenta
						; un blocco da visualizzare

;*********************************************************************


		section	__MERGED,BSS

	xdef	RayDirTab

RayDirTab	ds.l	WINDOW_MAX_WIDTH*2	;Tabella di tutti i raggi di ogni colonna

	xdef	RaycastObjects

RaycastObjects	ds.l	2*MAXVIEWOBJECTS	;Lista di dati (2 long) relativi ai blocchi della mappa che contengono oggetti e che sono intersecati dai raggi (ovvero che sono in vista).


	xdef	source_width
	xdef	window_width,window_height
	xdef	window_width2,window_height2,window_size
	xdef	pixel_type
	xdef	windowXratio,windowYratio,SkyXratio,SkyYratio

		cnop	0,4

source_width	ds.l	1	;WINDOW_WIDTH		;Dim. in byte dell'area di memoria contenente la window. Usato come offset tra una riga e l'altra.
window_width	ds.l	1	;WINDOW_WIDTH
window_height	ds.l	1	;WINDOW_HEIGHT
window_width2	ds.l	1	;WINDOW_WIDTH>>1
window_height2	ds.l	1	;WINDOW_HEIGHT>>1
window_size	ds.l	1	;WINDOW_WIDTH*WINDOW_HEIGHT	;Numero pixel
pixel_type	ds.l	1	;PIXEL_TYPE

windowXratio	ds.l	1
windowYratio	ds.l	1

SkyXratio	ds.l	1
SkyYratio	ds.l	1

;-----------------------------------------------------------------------

		xdef	PlayerX,PlayerY,PlayerZ
		xdef	PlayerHeading,PlayerSpeed,PlayerMoved
		xdef	PlayerViewDirX,PlayerViewDirZ
		xdef	PlayerBlock,PlayerBlockPun,PlayerMapPun
		xdef	PlayerYOsc
		xdef	SkyRotation

PlayerX		ds.l	1		;Posizione player X (16.16)
PlayerY		ds.l	1		;Posizione player Y (16.16) correntemente non usata
PlayerZ		ds.l	1		;Posizione player Z (16.16)
PlayerHeading	ds.w	1
PlayerSpeed	ds.w	1
PlayerMoved	ds.w	1
PlayerBlock	ds.w	1	;Num. blocco su cui si trova il Player
PlayerBlockPun	ds.l	1	;Pun. al blocco su cui si trova il Player
PlayerMapPun	ds.l	1	;Pun. nella mappa al blocco su cui si trova il Player
PlayerYOsc	ds.l	1	;Oscillazione verticale del player
SkyRotation	ds.l	1

PlayerViewDirX	ds.l	1	;Direzione X dello sguardo (16.16)
PlayerViewDirZ	ds.l	1	;Direzione Z dello sguardo (16.16)

RayDirX		ds.l	1	;Direzione X del raggio (16.16)
RayDirZ		ds.l	1	;Direzione Z del raggio (16.16)

RayCont		ds.w	1	;Contatore raggi
		ds.w	1	;noused


		xdef	CPlayerX,CPlayerY,CPlayerZ
		xdef	CPlayerViewDirX,CPlayerViewDirZ
		xdef	CPlayerHeading
		xdef	CPlayerBlock,CPlayerBlockPun,CPlayerMapPun
		xdef	CSkyRotation

	;*** Copie usate dalla routine di movimento
CPlayerX	ds.l	1
CPlayerY	ds.l	1
CPlayerZ	ds.l	1
CPlayerViewDirX	ds.l	1
CPlayerViewDirZ	ds.l	1
CPlayerHeading	ds.w	1
CPlayerBlock	ds.w	1
CPlayerBlockPun	ds.l	1
CPlayerMapPun	ds.l	1
PlayerYcopy	ds.l	1		;Copia di playery senza oscillazione
CSkyRotation	ds.l	1

		cnop	0,4

		end


	IFEQ	1

	if abs(raydirx)>=abs(raydirz)

		x=playerx and $fc00000			;x=d0
		z=playerz and $fc00000			;z=d1

		if raydirx>0 then
			sx=64				;sx=d3
			x+=sx
			sompointerx=2
		else
			sx=-64				;sx=d3
		;	x-=1
			sompointerx=-2
		endif

		somdistx=sx/raydirx			;somdistx=d4
		contdistx=(x-playerx)/raydirx		;contdistx=d5

		if raydirz>0 then
			sz=64				;sz=d3
			z+=sz
			sompointerz=GRID_SIZE*2
		else
			sz=-64				;sz=d3
		;	z-=1
			sompointerz=-GRID_SIZE*2
		endif

		if raydirz<>0 then
			somdistz=sz/raydirz		;somdistz=d6
			contdistz=(z-playerz)/raydirz	;contdistz=d7
		else
			contdistz=0
			somdistz=0
		endif

		dx=somdistz*raydirx
		dz=somdistx*raydirz
		x+=contdistz*raydirx
		z+=contdistx*raydirz

		pointer=calcola_pointer(x,z)

		if contdistx>contdistz then goto Xinloopz
				       else goto Xinloopx
Xloop
		z+=dz
		if z<0 or z>=BLOCK_SIZE then
			z=z and BLOCK_SIZE-1
Xinloopz		pointer+=sompointerz		
			block=peek(pointer)
			ProcessBlock(block,x)
			x+=dx
			contdistz+=somdistz
			if block<0 goto Xoutloop
		endif

Xinloopx	pointer+=sompointerx
		block=peek(pointer)
		ProcessBlock(block,z)
		contdistx+=somdistx
		if block>=0 goto Xloop
Xoutloop


	else	;*** Y dominant

		x=playerx and $fc00000			;x=d0
		z=playerz and $fc00000			;z=d1

		if raydirx>0 then
			sx=64				;sx=d3
			x+=sx
			sompointerx=2
		else
			sx=-64				;sx=d3
		;	x-=1
			sompointerx=-2
		endif

		if raydirz<>0 then
			somdistx=sx/raydirx		;somdistx=d4
			contdistx=(x-playerx)/raydirx	;contdistx=d5
		else
			somdistx=0
			contdistx=0
		endif

		if raydirz>0 then
			sz=64				;sz=d3
			z+=sz
			sompointerz=GRID_SIZE*2
		else
			sz=-64				;sz=d3
		;	z-=1
			sompointerz=-GRID_SIZE*2
		endif

		somdistz=sz/raydirz		;somdistz=d6
		contdistz=(z-playerz)/raydirz	;contdistz=d7

		dx=somdistz*raydirx
		dz=somdistx*raydirz
		x+=contdistz*raydirx
		z+=contdistx*raydirz

		pointer=calcola_pointer(x,z)

		if contdistz>contdistx then goto Zinloopx
				       else goto Zinloopz
Zloop
		x+=dx
		if x<0 or x>=BLOCK_SIZE then
			x=x and BLOCK_SIZE-1
Zinloopx		pointer+=sompointerx		
			block=peek(pointer)
			ProcessBlock(block,z)
			z+=dz
			contdistx+=somdistx
			if block<0 goto Zoutloop
		endif

Zinloopz	pointer+=sompointerz
		block=peek(pointer)
		ProcessBlock(block,x)
		contdistz+=somdistz
		if block>=0 goto Zloop
Zoutloop
	endif

	ENDC


