;********************************************************************
;*
;*	Include per TMap
;*
;********************************************************************

	opt	p=68020,ALINK,DEBUG,LINE,O+
	section .text,code

DEBUG			EQU	0


;*** Definizioni dimensioni schermo

SCREEN_WIDTH		EQU	320
SCREEN_HEIGHT		EQU	240
SCREEN_DEPTH		EQU	8
SCREEN_BITPLANE 	EQU	(SCREEN_WIDTH/8)*SCREEN_HEIGHT

CHUNKY_WIDTH		EQU	320
CHUNKY_HEIGHT		EQU	200

PANEL_HEIGHT		EQU	40

;*** Mappa

MAX_BLOCK_NUM	EQU	500	;Numero massimo di blocchi diversi
MAX_EDGES_NUM	EQU	400	;Numero massimo di edges diversi
MAX_FX_SIZE	EQU	1536	;Massima quantita' di memoria per gli effetti


;*** Textures

MAXTEXTURES		EQU	300	;Numero massimo di textures su file TGLD
MAXLEVELTEXTURES	EQU	60	;Numero massimo di textures per livello


;*** Oggetti

MAXLEVELOBJECTS		EQU	256	;Numero massimo di oggetti per livello
MAXVIEWOBJECTS		EQU	256	;Numero massimo di oggetti visibili per volta
MAXPLAYERSHOTS		EQU	6	;Numero massimo di spari del player presenti sullo schermo

;*** Dimensioni aree di memoria da allocare
	
CHUNKY_SIZE		EQU	CHUNKY_WIDTH*CHUNKY_HEIGHT	;Dim. schermo fake chunky
MAPMEM_SIZE		EQU	65536+1024+(MAX_BLOCK_NUM<<5)+(MAX_EDGES_NUM<<4)+MAX_FX_SIZE		;Dim. area memoria mappa
MAPOBJECTS_SIZE		EQU	MAXLEVELOBJECTS*64	;Dim. area memoria per le strutture degli oggetti in mappa
TEXTURESDIR_SIZE	EQU	MAXTEXTURES*16		;Dim. area memoria directory textures
TEXTURES_SIZE		EQU	MAXLEVELTEXTURES*4096	;Dim. area memoria grafica textures
OBJECTS_SIZE		EQU	300000			;Dim. area memoria grafica oggetti
GFX_SIZE		EQU	TEXTURES_SIZE+OBJECTS_SIZE
MOD_SIZE		EQU	40000			;Dim. massima moduli PT
SOUNDS_SIZE		EQU	92160+MOD_SIZE		;Dim. area memoria chip per sounds e mod


;*** Definizioni per Sprite-monitor

SPRMON_CHARWIDTH	EQU	6	;Larghezza in pixel dei caratteri usati sullo sprite monitor
SPRMON_CHARHEIGHT	EQU	6	;Altezza in pixel dei caratteri usati sullo sprite monitor
SPRMON_NSPRITE		EQU	2	;Numero di sprite da 64 pixel che compongono il monitor
SPRMON_HEIGHT		EQU	22*SPRMON_CHARHEIGHT	;Altezza in pixel dello sprite monitor


;*** Altre definizioni

WINDOW_STANDARD_WIDTH	EQU	160	;La meta' delle dimensioni orizzontali della finestra standard
WINDOW_STANDARD_HEIGHT	EQU	110	;Le dimensioni verticali della finestra standard

WINDOW_MAX_WIDTH	EQU	320
WINDOW_MAX_HEIGHT	EQU	201	;Ho aggiunto una riga per sicurezza

SKY_BRUSH_WIDTH		EQU	256
SKY_STANDARD_WIDTH	EQU	SKY_BRUSH_WIDTH
SKY_STANDARD_HEIGHT	EQU	200

;PIXEL_WIDTH		EQU	3
;PIXEL_HEIGHT		EQU	2
;NUM_BTPL		EQU	7

MAP_SIZE		EQU	128	;Num. blocchi width e height della mappa
MAP_SIZE_B		EQU	7	;Valore di shift per MAP_SIZE
MAP_LENGTH		EQU	(MAP_SIZE*MAP_SIZE*4)	;Dimensioni in byte della mappa (sia quella dei blocchi che quella degli oggetti)

BLOCK_SIZE		EQU	64
BLOCK_SIZE_B		EQU	6	;Valore di shift per block size
MAX_BLOCK_VIEW		EQU	32	;Num. massimo di blocchi diversi che e' possibile vedere su un singolo raggio

GRID_SIZE		EQU	128	;Num. blocchi width e height della mappa
GRID_SIZE_B		EQU	7	;Valore di shift per grid size
GRID_AND_W		EQU	(GRID_SIZE*BLOCK_SIZE)-BLOCK_SIZE	;Valore per fare l'and con la parte intera di una coordinata sulla mappa
GRID_AND_L		EQU	((GRID_SIZE*BLOCK_SIZE)-BLOCK_SIZE)<<16	;Valore per fare l'and con una coordinata sulla mappa (formato 16.16)

BRUSH_DIM		EQU	64	;Numero pixel per lato del brush

MAX_ENEMY_DIST_BLK	EQU	20		;Distanza massima in blocchi dal player oltre la quale i nemici non vengono mossi
MAX_ENEMY_DIST_PIX	EQU	MAX_ENEMY_DIST_BLK*BLOCK_SIZE	;Come MAX_ENEMY_DIST_BLK, ma espresso in pixel
MAX_ENEMY_DIST		EQU	MAX_ENEMY_DIST_PIX*MAX_ENEMY_DIST_PIX	;MAX_ENEMY_DIST_PIX, elevato al quadrato

MAX_EFFECT		EQU	42	;Numero massimo di effetti attivi in uno stesso istante

SINTABLE_LEN		EQU	2048	;Numero di valori nella tabella dei seni.
SINTABLE_AND		EQU	((SINTABLE_LEN<<2)-1)
COSTABLE_OFFSET		EQU	SINTABLE_LEN	;Offset rispetto a sintable per la costable

;****************************************************************************
;
;	Game definitions
;
;****************************************************************************

PLAYER_WIDTH		EQU	16
PLAYER_HEIGHT		EQU	56
PLAYER_EYES_HEIGHT	EQU	54
PLAYER_MAX_RISE		EQU	24	;Entit massima del dislivello in salita che il player pu superare
PLAYER_WALK_SPEED	EQU	3	;Velocit camminata del player(old=3)
PLAYER_RUN_SPEED	EQU	5	;Velocit corsa del player (old=5)
PLAYER_ACCEL		EQU	4	;Accelerazione del player per camminata/corsa (old=4)
PLAYER_ROT_SPEED	EQU	8	;Velocit di rotazione del player mentre  fermo
PLAYER_ROT_WALK_SPEED	EQU	12	;Velocit di rotazione del player mentre cammina (old=8)
PLAYER_ROT_RUN_SPEED	EQU	20	;Velocit di rotazione del player mentre corre (old=20)
PLAYER_ROT_ACCEL	EQU	1	;Accelerazione per la rotazione del player (old=4)

SKY_ROT_WALK_SPEED	EQU	((SKY_STANDARD_WIDTH<<16)/((SINTABLE_LEN<<8)/PLAYER_ROT_WALK_SPEED))	;Velocit di rotazione del cielo, moltiplicata per 256
SKY_ROT_RUN_SPEED	EQU	((SKY_STANDARD_WIDTH<<16)/((SINTABLE_LEN<<8)/PLAYER_ROT_RUN_SPEED))	;Velocit di rotazione del cielo, moltiplicata per 256

LOOKHEIGHT_STEP		EQU	1	;Passo della variazione di altezza dello sguardo del player (old=24)

PLAYER_HEALTH		EQU	100	;Stato di salute iniziale
PLAYER_SHIELDS		EQU	100	;Scudi iniziali
PLAYER_ENERGY		EQU	1000	;Energia iniziale
PLAYER_CREDITS		EQU	0	;Crediti iniziali

MAX_PLAYER_HEALTH	EQU	100	;Massima qt di health
MAX_PLAYER_SHIELDS	EQU	100	;Massima qt di shields
MAX_PLAYER_ENERGY	EQU	9999	;Massima qt di energy
MAX_PLAYER_CREDITS	EQU	99999	;Massima qt di credits

;****************************************************************************



;... Offset sistema

COPINIT		EQU	38		;CopInit della struttura GfxBase

CIAAPRA		EQU	$BFE001		;Registro dati periferico A
CIAATALO	EQU	$BFE401		;Registro basso del timer A
CIAATAHI	EQU	$BFE501		;Registro alto del timer A
CIAASDR		EQU	$BFEC01		;Registro dati seriale
CIAAICR		EQU	$BFED01		;Registro di controllo delle CIA IRQ
CIAACRA		EQU	$BFEE01		;Registro di controllo A


;... Definizione macro

EXT_SYS		MACRO
		XREF	_LVO\1
		ENDM

CALLSYS		MACRO
		jsr	_LVO\1(a6)
		ENDM

EXECBASE	MACRO
		move.l	4,a6
		ENDM

GFXBASE		MACRO
		move.l	gfxbase(a5),a6
		ENDM

DOSBASE		MACRO
		move.l	dosbase(a5),a6
		ENDM

INTUITIONBASE	MACRO
		move.l	intuitionbase(a5),a6
		ENDM

GETDBASE	MACRO
		xref	_LinkerDB
		lea	_LinkerDB,a5
		ENDM

VIDEOCARDLIBBASE MACRO
		move.l	vilintuisupbase(a5),a6
		 ENDM


; Apre la libreria di nome lname e ne mette il pun. in lvar(a5)
; Se ci sono problemi, esce
OPENLIB		MACRO	lname,lvar
		lea	\1,a1			; library name
		moveq	#0,d0			; library version
		move.l	execbase(a5),a6		; get from local copy, not location 4!
		CALLSYS	OpenLibrary		; open the library
		move.l	d0,\2(a5)		; save it and test for zero
		beq	ErrorQuit		; not found?
		ENDM


; Prova ad aprire la libreria di nome lname e ne mette il pun. in lvar(a5)
; In d0 c'e' il pun. alla libreria e gli status code sono settati in base
; al contenuto di d0.
TRYOPENLIB	MACRO	lname,version,lvar
		lea	\1,a1			; library name
		moveq	#\2,d0			; library version
		move.l	execbase(a5),a6		; get from local copy, not location 4!
		CALLSYS	OpenLibrary		; open the library
		move.l	d0,\3(a5)		; save it
		ENDM


; Chiude la libreria puntata dal contenuto di lbase(a5)
; trashes a0/a1/d0/d1
CLOSELIB	MACRO	lbase
		move.l	\1(a5),d0		; fetch library pointer and test for 0
		beq.s	already_closed\@
		move.l	d0,a1
		move.l	execbase(a5),a6		; need execbase for closelib
		CALLSYS	CloseLibrary		; close it
		clr.l	\1(a5)			; clear ptr for safety
already_closed\@:
		ENDM

; Alloca len byte di memoria di tipo type e ne scrive il puntatore in var(a5)
ALLOCMEMORY	MACRO	len,type,var
		move.l	\1,d0
		move.l	#\2,d1
		CALLSYS	AllocMem
		move.l	d0,\3(a5)
		beq	ErrorQuit
		ENDM

; Dealloca len byte di memoria allocati a partire da pun
FREEMEMORY	MACRO	pun,len
		move.l	\1(a5),d0
		beq.s	already_free\@
		move.l	d0,a1
		move.l	\2,d0
		CALLSYS	FreeMem
		clr.l	\1(a5)
already_free\@:
		ENDM


;Fa lampeggiare lo schermo del colore specificato
; e attende la pressione del tasto specificato (6=mouse ; 7=joystick)
WAITDEBUG	MACRO	color, button
wwww\@		move.w	#0,$dff180
		move.w	#\1,$dff180
		btst	#\2,$bfe001
		bne	wwww\@
		ENDM


;Stampa a video un numero in esadecimale di lunghezza word
;Notare che:
; x = valore della coordinata x (0..39)
; y = offset rispetto a scorey(a5) della coordinata y
; number e pun.screen sono modi di indirizzamento
PRINTHEX	MACRO	x,y,number
		movem.l	d0-d2/a0,-(sp)
		move.w	\1,d0
		move.w	scorey(a5),d1
		add.w	\2,d1
		move.w	\3,d2
;		move.l	CurrentBitmap(a5),a0
		move.l	planes_bitmap1(a5),a0
		move.l	(a0),a0
		xref	PrintHex
		jsr	PrintHex
		movem.l	(sp)+,d0-d2/a0
		ENDM

;Stampa in chunky pixel un numero in esadecimale di lunghezza word
;Notare che:
; x = valore della coordinata x (0..319)
; y = offset rispetto a scorey(a5) della coordinata y
; number e pun.screen sono modi di indirizzamento
;PRINTHEXCHUNKY	MACRO	x,y,number
;		movem.l	d0-d2/a0,-(sp)
;		move.w	\1,d0
;		move.w	scorey(a5),d1
;		add.w	\2,d1
;		move.w	\3,d2
;		move.l	CurrentChunkyBuffer(a5),a0
;		xref	PrintHexChunky
;		jsr	PrintHexChunky
;		movem.l	(sp)+,d0-d2/a0
;		ENDM


CWAIT	macro	ucl,vpos,hpos
;		\1  \2   \3
; trashes d0-d1/a0-a1
;	xref	_LVOCWait,_LVOCBump
	move.l	\1,a1
	move.l	a1,-(a7)
	move.l	\2,d0
	move.l	\3,d1
	jsr	_LVOCWait(a6)
	move.l	(a7)+,a1
	jsr	_LVOCBump(a6)
	endm	

CMOVE	macro	ucl,reg,value
;		\1  \2   \3
; trashes d0-d1/a0-a1
;	xref	_LVOCMove,_LVOCBump
	move.l	\1,a1
	move.l	a1,-(a7)
	move.l	\2,d0
	move.l	\3,d1
	jsr	_LVOCMove(a6)
	move.l	(a7)+,a1
	jsr	_LVOCBump(a6)
	endm	

CEND	macro	ucl
;		\1
	CWAIT	\1,#10000,#255
	endm


;****************************************************************************
;
;	vtable  una tabella contenente WINDOW_WIDTH strutture di
;	6 byte ciascuna. Ogni struttura rappresenta una colonna
;	a video ed  cosi' formata:

vtsize		EQU	16	;Numero di byte della struttura

vtdistance	EQU	0	;L	Distance
vtblock		EQU	4	;L	Block pointer
vtbitmap	EQU	8	;L	Brush column offset
vtedge		EQU	12	;L	Edge pointer

;****************************************************************************
;
;	Offsets per strutture texture contenute in Graphics.asm
;

tx_Width	EQU	-4	;W	Num. colonne della texture
tx_Animation	EQU	-2	;W	Se>1 la texture e' animata
tx_Height	EQU	0	;W	Num. righe della texture
tx_HeightShift	EQU	2	;W	Usato per le moltiplicazioni con tx_Height. (1<<tx_HeightShift) = tx_Height
tx_Brush	EQU	4	;L	Pun. al brush corrente
tx_AnimCount	EQU	8	;L	Contatore per l'animazione. E' un offset rispetto a tx_AnimCount, quindi assume valori: 4,8,12,16, ...
				;	Se la texture non  animata, puo' contenere il pun. ad un'altra texture che puo' essere utilizzata
				;	per effetti particolari. Ad es. per cambiare texture quando viene attivato uno switch.
tx_FirstBrush	EQU	12	;L	Lista di puntatori ai brush dell'animazione. Deve terminare con uno zero.


;****************************************************************************

	IFEQ	1

bl_Effect : Viene attivata una lista di effetti quando il player passa
	     su un blocco con bl_Effect<>0.
	    Ogni effetto della lista  formato dai seguenti dati:

		dc.w	Trigger,Effect,Param1,Param2

	    Effect  il codice dell'effetto specifico (vedi lista sotto)
	    da eseguire con parametri Param1 e Param2. Tutti i blocchi
	    con lo stesso Trigger number saranno soggetti a questo effetto.
	    Ogni lista di effetti  terminata da una long a zero:

		dc.w	Trigger,Effect,Param1,Param2
		....	............................
		dc.w	Trigger,Effect,Param1,Param2
		dc.l	0


    *** Lista effetti:

	Significato della colonna Action:
	
	W : Il player deve camminare sul blocco (Walk) per attivare l'effetto
	S : Bisogna premere la barra spaziatrice per attivare l'effetto
	1 : L'effetto funziona solo una volta
	R : L'effetto funziona ripetutamente

Cod.  Action   Effect

 00            Nothing
 01    W 1     Soffitto su di 64
 02    W 1     Soffitto su di 128
 03    W 1     Pavimento su di 64
 04    W 1     Pavimento su di 128
 05    W R     Soffitto su di 64, pausa di 5sec, soffitto giu' di 64
 06    W R     Soffitto su di 128, pausa di 5sec, soffitto giu' di 128




bl_Attributes :

 bit #		Condition if set (=1)

 bit 0		--+--- Type (2bit): 0=Normal; 1=-2Health; 2=-5Health; 3=-10Health;
 bit 1		--+
 bit 2		No used
 bit 3		Enemies cannot enter this block
 bit 4		Edge 1 switch  (Player can press space bar in front of this edge to trigger an effect)
 bit 5		Edge 2 switch
 bit 6		Edge 3 switch
 bit 7		Edge 4 switch


	ENDC

;****************************************************************************
;
;	Offsets per struttura Block
;

bl_FloorHeight	EQU	 0	;W
bl_CeilHeight	EQU	 2	;W
bl_FloorTexture	EQU	 4	;W
bl_CeilTexture	EQU	 6	;W
bl_BlockNumber	EQU	 8	;W
bl_Illumination	EQU	10	;W	Il byte alto  l'illuminazione. Se il bit 7 del byte basso  settato,  attiva la nebbia
bl_Edge1	EQU	12	;L
bl_Edge2	EQU	16	;L
bl_Edge3	EQU	20	;L
bl_Edge4	EQU	24	;L
bl_Effect	EQU	28	;B	Se<>0 e se il player entra in questo blocco viene eseguita una lista di effetti. Ogni effetto ha un trigger number.
bl_Trigger2	EQU	29	;B	Se<>0 questo blocco  soggetto all'effetto con lo stesso trigger number.
;bl_Type		EQU	29	;B	Cosa succede al player o al blocco stesso se il player vi entra. Anche usato per effetti luminosi.
bl_Attributes	EQU	30	;B	Bitmapped attributes
bl_Trigger	EQU	31	;B	Se<>0 questo blocco  soggetto all'effetto con lo stesso trigger number.
bl_SIZE		EQU	32
bl_SIZE_B	EQU	 5

;		   Edge4
;		+---------+
;		|         |
;	  Edge3	|         | Edge1
;		|         |
;		|         |
;		+---------+
;		   Edge2

;****************************************************************************
;
;	Offsets per struttura Edge
;

;
;  ed_Attribute:
;	bit 0 :	If set, upper texture is unpegged
;	bit 1 : If set, lower texture is unpegged
;

ed_NormTexture	EQU	 0	;L
ed_UpTexture	EQU	 4	;L
ed_LowTexture	EQU	 8	;L
ed_Attribute	EQU	12	;W
ed_NoUsed	EQU	14	;W
ed_SIZE		EQU	16
ed_SIZE_B	EQU	 4

;****************************************************************************
;
;	Offsets per la struttura Effects definita in Animations.asm
;
;

ef_effect	EQU	0	;W	Effect type
ef_trigger	EQU	2	;W	Trigger number
ef_blocklist	EQU	4	;L	Block list pointer: puntatore alla lista di blocchi con lo stesso trigger number.
ef_status	EQU	8	;W	Stato dell'animazione. Se=0 bisogna inizializzarla
ef_param1	EQU	10	;W	Parametro effetto
ef_param2	EQU	12	;W	Parametro effetto
ef_var1		EQU	14	;W	Variabile usata dalle varie routine
ef_var2		EQU	16	;W	Variabile usata dalle varie routine
ef_var3		EQU	18	;W	Variabile usata dalle varie routine
ef_var4		EQU	20	;W	Variabile usata dalle varie routine
ef_SIZE		EQU	24


;****************************************************************************
;
;	Offsets per strutture ObjVTable
;

ovt_distance	EQU	0	;L	Distanza
ovt_object	EQU	4	;L	Pun. all'oggetto
ovt_minclip	EQU	8	;W
ovt_maxclip	EQU	10	;W
ovt_SIZE	EQU	12


;****************************************************************************
;
;	Offsets per strutture oggetti contenute in Graphics.asm
;

o_numframes	EQU	0	;W	Num. frame
o_radius	EQU	2	;W	Raggio in pixel per ctrl collisioni
o_height	EQU	4	;W	Altezza in pixel per ctrl collisioni
o_animtype	EQU	6	;B	Tipo animazione (0:nessuna; 1:semplice; -1:direzionale)
o_objtype	EQU	7	;B	Tipo oggetto (0:oggetto semplice; 1:player; 2:nemico; 3:oggetto da raccogliere; 4:colpo d'arma)
o_param1	EQU	8	;W	Parametro1 (cambia significato in base al valore di o_objtype)
o_param2	EQU	10	;W	Parametro2 (cambia significato in base al valore di o_objtype)
o_param3	EQU	12	;W	Parametro3 (cambia significato in base al valore di o_objtype)
o_param4	EQU	14	;W	Parametro4 (cambia significato in base al valore di o_objtype)
o_param5	EQU	16	;B	Parametro5 (cambia significato in base al valore di o_objtype)
o_param6	EQU	17	;B	Parametro6 (cambia significato in base al valore di o_objtype)
o_param7	EQU	18	;B	Parametro7 (cambia significato in base al valore di o_objtype)
o_param8	EQU	19	;B	Parametro8 (cambia significato in base al valore di o_objtype)
o_param9	EQU	20	;B	Parametro9 (cambia significato in base al valore di o_objtype)
o_param10	EQU	21	;B	Parametro10(cambia significato in base al valore di o_objtype)
o_param11	EQU	22	;B	Parametro11(cambia significato in base al valore di o_objtype)
o_param12	EQU	23	;B	Parametro12(cambia significato in base al valore di o_objtype)
o_sound1	EQU	24	;L	Pun. al sound 1 (cambia significato in base al valore di o_objtype)
o_sound2	EQU	28	;L	Pun. al sound 2 (cambia significato in base al valore di o_objtype)
o_sound3	EQU	32	;L	Pun. al sound 3 (cambia significato in base al valore di o_objtype)
o_currentframe	EQU	36	;L	Pun. al frame corrente
o_animcont	EQU	40	;L	Contatore frame per animazione
o_frameslist	EQU	44	;L	Zero terminated list di pun. ai frame

;****************************************************************************
;
;	Offsets per struttura Obj
;
; N.B.
;	La prima parte della struttura e' fissa ed uguale per tutti i
;	tipi di oggetto.
;	Seguono poi le definizioni specifiche per ogni tipo.
;
;
;

obj_number	EQU	0	;W	Numero oggetto (da 1 in poi)
obj_x		EQU	2	;W
obj_z		EQU	4	;W
obj_y		EQU	6	;W
obj_width	EQU	8	;W	Dimensioni oggetto (raggio)
obj_height	EQU	10	;W	Altezza
obj_image	EQU	12	;L	Pun. immagine
obj_animcont	EQU	16	;W	Contatore per animazione frames
obj_mapoffset	EQU	18	;W	Offset>>2 nella mappa oggetti, al blocco su cui si trova l'oggetto
obj_blockpun	EQU	20	;L	Pun. al blocco su cui si trova l'oggetto
obj_blockprev	EQU	24	;L	Pun. all'oggetto precedente sul blocco attuale (0, se non ce ne sono altri)
obj_blocknext	EQU	28	;L	Pun. al prossimo oggetto sul blocco attuale (0, se non ce ne sono altri)
obj_listprev	EQU	32	;L	Pun. all'oggetto precedente nella lista (0, se non ce ne sono altri)
obj_listnext	EQU	36	;L	Pun. al prossimo oggetto nella lista (0, se non ce ne sono altri)
obj_type	EQU	40	;B	Tipo oggetto (NON SEPARARE DAL CAMPO SUCCESSIVO)
obj_subtype	EQU	41	;B	Sotto-tipo oggetto:
				;	  oggetto   :
				;	  player    :
				;	  nemico    : tipo comportamento (inoltre il bit 7 indica se il nemico sta gi emettendo un suono)
				;	  pick obj  : 0=Health; 1=Shields; 2=Energy; 3=Credits
				;	  proiettili: 0=Player;  1=Nemico
				;	  esplosioni:
obj_status	EQU	42	;B	Stato oggetto. Questo valore dipende dal tipo di oggetto.
obj_power	EQU	43	;B	Power
obj_speed	EQU	44	;W	Velocita'
obj_heading	EQU	46	;W	Angolo di osservazione: 0:Est  512:Nord  1024:Ovest  1536:Sud

;--- Type=2 : Enemies

obj_attackdist	EQU	48	;L	Massima distanza (al quadrato), oltre la quale il nemico non attacca
obj_rotdir	EQU	52	;B	Dir. di rotazione nel caso in cui sta scegliendo una nuova direzione di movimento. Puo' valere -1, 0, oppure 1.
obj_playercoll	EQU	53	;B	Contatore per collisione con il player
obj_strength	EQU	54	;W	Resistenza nemici
obj_attackdelay	EQU	56	;B	Contatore di ritardo per fire
obj_bmstatus	EQU	57	;B	Bitmapped:
				;		bit 5 : Se on, non si pu muovere in orizzontale
				;		bit 6 : Se on, non si pu muovere in verticale
				;		bit 7 : Se on, il nemico  nel campo visivo del player
obj_cont1	EQU	58	;B	Contatore per movimento NON SEPARARE DA obj_cont2
obj_cont2	EQU	59	;B	Contatore per movimento
obj_gun		EQU	60	;B	Arma da usare:
				;		  0 = Nessuna
				;		  1 = Colpisce col corpo (pugni, morsi, etc.)
				;		  2 = Arma con proiettili invisibili
				;		=>10= Oggetto Shot, con codice =>10
obj_attackprob	EQU	61	;B	Probabilit di attacco. DEVE essere > 0
obj_enemyspeed	EQU	62	;B	Velocit massima del nemico
obj_inactive	EQU	63	;B	Se=0, il nemico  attivo.
				;	Se<>0, contiene il numero del trigger che lo attiva.


;--- Type=3 : Pick things

obj_value	EQU	48	;W	Valore di energia da sommare


;--- Type=4 : Shots

obj_x0		EQU	48	;W	x iniziale per i proiettili
obj_z0		EQU	50	;W	z iniziale per i proiettili
obj_distance	EQU	52	;W	distanza dalla posizione iniziale per i proiettili
obj_dirx	EQU	54	;W	Direzione x (nel formato 2.14)
obj_dirz	EQU	56	;W	Direzione z (nel formato 2.14)
obj_accel	EQU	58	;B	Accelerazione per i proiettili
obj_maxspeed	EQU	59	;B	Massima velocita' per i proiettili
obj_hheading	EQU	60	;W	Angolo verticale per i proiettili
obj_y0		EQU	62	;W	y iniziale per i proiettili


;--- Type=5 : Explosion

obj_oldimage	EQU	48	;L	Pun. vecchia immagine, se  l'esplosione di un nemico


obj_SIZE	EQU	64
;;;obj_SIZE_B	EQU	6

;****************************************************************************
;* Offsets per struttura dati sound

		RSRESET
snd_pointer	rs.l	1	;Puntatore al sample
snd_length	rs.w	1	;Lunghezza in word
snd_period	rs.w	1	;Periodo
snd_volume	rs.w	1	;Volume (0-64)
snd_loop	rs.w	1	;Loop: offset rispetto a snd_pointer (0:no loop)
snd_priority	rs.b	1	;Priorita' (0-7)
snd_mask	rs.b	1	;Maschera canali audio utilizzabili:
				;  bit 0 : canale 0
				;  bit 1 : canale 1
				;  bit 2 : canale 2
				;  bit 3 : canale 3
snd_type	rs.b	1	;Type: 0=Protracker MOD; 1=Global sound; 2=Object sound
snd_code	rs.b	1	;Se snd_type=1 :
				;		0 = Door start & loop
				;		1 = Door stop
				;		2 = Switch
				;		3 = Teletransporter
				;		4 = Player scream
snd_SIZE	rs.w	1

