;******************************************************************
;*
;*	Scores.asm
;*
;*		Gestione punteggi, livelli d'energia, etc.
;*
;******************************************************************

	include 'System'
	include 'TMap.i'

;******************************************************************

		xref	gfxbase,intuitionbase
		xref	screen_viewport
		xref	PanelBitplanes
		xref	RedPalette
		xref	Escape,PlayerDeath,PlayAgain
		xref	CurrentGame,CurrentLevel
		xref	PlayerWeapons,PlayerActiWeapon,PlayerBuyWeapon
		xref	GlobalSound0,GlobalSound1,GlobalSound2,GlobalSound3
		xref	GlobalSound4,GlobalSound5,GlobalSound6,GlobalSound7
		xref	GlobalSound8,GlobalSound9,GlobalSound10

		xref	BufferedPlaySoundFX,PlaySoundFX
		xref	ScorePrint
		xref	LoadPalette

;******************************************************************
;* Gestione player colpito.
;* Decrementa livelli di energia e fa diventare rosso lo schermo.
;* Richiede:
;*	d0 = Qt di energia da togliere al player

		xdef	PlayerHit

PlayerHit	movem.l	d0-d3/a0-a1/a6,-(sp)

                IFD     DEVMODE
                tst.b   Invincible(a5)
                bne     PHout

                ENDC

		tst.b	PlayerDeath(a5)		;Test se player morto
		bne	PHout

	;*** Diminuisce Health e Shields del player

		clr.l	d2
		move.w	PlayerShields(a5),d2
		move.w	d0,d1
		swap	d1
		clr.w	d1
		lsr.l	#1,d1
		move.l	d1,d3
		lsr.l	#1,d3
		add.l	d3,d1		;d1=75% dell'energia da togliere al player
		clr.w	d3
		lsl.w	#1,d1		;Mette nel flag X il bit piu' alto della parte decimale
		swap	d1
		addx.w	d3,d1		;Somma il flag X per arrotondare all'intero superiore
		cmp.w	d2,d1		;Ci sono abbastanza scudi ?
		ble.s	PHoksh		; Se si, salta
		move.w	d2,d1		;Altrimenti considera solo la quantita' di scudi disponibili
PHoksh		sub.w	d1,d2
		move.w	d2,PlayerShields(a5)
		sub.w	d1,d0

		clr.l	d2
		move.w	PlayerHealth(a5),d2
		sub.w	d0,d2
		bgt.s	PHnodeath
		st	PlayerDeath(a5)		;Segnala che il player  morto
;		st	Escape(a5)
		clr.w	d2
PHnodeath	move.w	d2,PlayerHealth(a5)

		move.b	#1,PlayerHealthFL(a5)
		move.b	#1,PlayerShieldsFL(a5)

	;*** Numero di 50esimi di permanenza dello schermo rosso

		move.w	#13,RedScreenCont(a5)

	;*** Setta palette rossa

		lea	RedPalette(a5),a0
		jsr	LoadPalette

;		move.l	screen_viewport(a5),a0
;		lea	RedPalette,a1
;		GFXBASE
;		CALLSYS	LoadRGB32

	;*** Suona sample

		move.l	GlobalSound4(a5),a0
		moveq	#0,d1
		jsr	BufferedPlaySoundFX
PHout
		movem.l	(sp)+,d0-d3/a0-a1/a6
		rts

;******************************************************************
;* Gestione incremento livelli d'energia, etc.
;* Richiede:
;*	d4.b = obj_subtype
;*	d2.l = entita' dell'incremento
;* Restituisce in d0 il codice del messaggio da visualizzare
;* nel monitor di sprite.
;* Se d0=-1, l'item non puo' essere collezionato.
;* Usa e modifica i registri: d0,d1,d3,d4


		xdef	CollectItem
CollectItem

		tst.b	d4
		bne.s	CInohealth
		move.w	PlayerHealth(a5),d3
		cmp.w	#MAX_PLAYER_HEALTH,d3
		beq	CInocollect
		add.w	d2,d3
		cmp.w	#MAX_PLAYER_HEALTH,d3
		ble.s	CIhok
		moveq	#MAX_PLAYER_HEALTH,d3
CIhok		move.w	d3,PlayerHealth(a5)
		move.b	#1,PlayerHealthFL(a5)
		moveq	#8,d0
		rts
CInohealth
		subq.b	#1,d4
		bne.s	CInoshields
		move.w	PlayerShields(a5),d3
		cmp.w	#MAX_PLAYER_SHIELDS,d3
		beq	CInocollect
		add.w	d2,d3
		cmp.w	#MAX_PLAYER_SHIELDS,d3
		ble.s	CIsok
		move.w	#MAX_PLAYER_SHIELDS,d3
CIsok		move.w	d3,PlayerShields(a5)
		move.b	#1,PlayerShieldsFL(a5)
		moveq	#9,d0
		rts
CInoshields
		subq.b	#1,d4
		bne.s	CInoenergy
		move.w	PlayerEnergy(a5),d3
		cmp.w	#MAX_PLAYER_ENERGY,d3
		beq	CInocollect
		add.w	d2,d3
		cmp.w	#MAX_PLAYER_ENERGY,d3
		ble.s	CIeok
		move.w	#MAX_PLAYER_ENERGY,d3
CIeok		move.w	d3,PlayerEnergy(a5)
		move.b	#1,PlayerEnergyFL(a5)
		moveq	#10,d0
		rts
CInoenergy
		subq.b	#1,d4
		bne.s	CInocredits
		move.l	PlayerCredits(a5),d3
		cmp.l	#MAX_PLAYER_CREDITS,d3
		beq	CInocollect
		add.l	d2,d3
		cmp.l	#MAX_PLAYER_CREDITS,d3
		ble.s	CIcok
		move.l	#MAX_PLAYER_CREDITS,d3
CIcok		move.l	d3,PlayerCredits(a5)
		move.b	#1,PlayerCreditsFL(a5)
		moveq	#11,d0
		rts
CInocredits
		subq.b	#1,d4
		bne.s	CInogreenkey
		tst.b	GreenKey(a5)
		bne	CInocollect
		move.b	#1,GreenKey(a5)
		move.b	#1,GreenKeyFL(a5)
		moveq	#0,d0
		rts
CInogreenkey
		subq.b	#1,d4
		bne.s	CInoyellowkey
		tst.b	YellowKey(a5)
		bne	CInocollect
		move.b	#1,YellowKey(a5)
		move.b	#1,YellowKeyFL(a5)
		moveq	#1,d0
		rts
CInoyellowkey
		subq.b	#1,d4
		bne.s	CInoredkey
		tst.b	RedKey(a5)
		bne	CInocollect
		move.b	#1,RedKey(a5)
		move.b	#1,RedKeyFL(a5)
		moveq	#2,d0
		rts
CInoredkey
		subq.b	#1,d4
		bne.s	CInobluekey
		tst.b	BlueKey(a5)
		bne	CInocollect
		move.b	#1,BlueKey(a5)
		move.b	#1,BlueKeyFL(a5)
		moveq	#3,d0
		rts
CInobluekey
		moveq	#12,d0		;Messaggio d'errore
CIcont
		rts

CInocollect	moveq	#-1,d0		;Segnala che l'oggetto non puo' essere preso
		rts

;******************************************************************
;* Gestione attivazione e boost delle armi
;* Richiede:
;*	d0.w = Numero arma (0-5)

		xdef	CollectWeapon

CollectWeapon	move.l	a0,-(sp)

		lea	PlayerWeapons(a5),a0
		tst.b	(a0,d0.w)	;L'arma  posseduta ?
		bne.s	CWnocollect	; Se si, salta
		addq.b	#1,(a0,d0.w)
		lea	WeaponsFL(a5),a0
		st	(a0,d0.w)	;Segnala modifica sul pannello dei punteggi

		move.w	d0,PlayerBuyWeapon(a5)

		move.l	(sp)+,a0
		rts




		xdef	BoostWeapon

BoostWeapon	move.l	a0,-(sp)

		lea	PlayerWeapons(a5),a0
		cmp.b	#1,(a0,d0.w)	;L'arma  posseduta ed  a potenza 1?
		bne.s	CWnocollect	; Se no, salta
		addq.b	#1,(a0,d0.w)
		lea	WeaponsFL(a5),a0
		st	(a0,d0.w)	;Segnala modifica sul pannello dei punteggi

		move.l	(sp)+,a0
		rts


CWnocollect	moveq	#-1,d0		;Segnala che l'arma non puo' essere attivata
		move.l	(sp)+,a0
		rts

;******************************************************************
;* Inizializza punteggi, livelli d'energia, etc.

		xdef	InitScores,InitScores2
InitScores
		moveq	#0,d0

		move.w	#PLAYER_HEALTH,PlayerHealth(a5)
		move.w	#PLAYER_SHIELDS,PlayerShields(a5)
		move.w	#PLAYER_ENERGY,PlayerEnergy(a5)
		move.l	#PLAYER_CREDITS,PlayerCredits(a5)
		move.l	d0,PlayerScore(a5)
		rts

;*** Inizializza ad ogni livello

InitScores2
		tst.b	PlayAgain(a5)		;Test se ripristinare lo stato di un livello gi giocato
		beq.s	ISnoplayagain		; Se no, salta

		move.w	SPlayerHealth(a5),PlayerHealth(a5)
		move.w	SPlayerShields(a5),PlayerShields(a5)
		move.w	SPlayerEnergy(a5),PlayerEnergy(a5)
		move.l	SPlayerCredits(a5),PlayerCredits(a5)
		move.l	SPlayerScore(a5),PlayerScore(a5)
		move.l	SGreenKey(a5),GreenKey(a5)	;Stato delle 4 chiavi
		move.l	SPlayerWeapons(a5),PlayerWeapons(a5)
		move.l	SPlayerWeapons+4(a5),PlayerWeapons+4(a5)
		move.w	SPlayerActiWeapon(a5),PlayerActiWeapon(a5)
ISnoplayagain
		move.w	PlayerHealth(a5),SPlayerHealth(a5)
		move.w	PlayerShields(a5),SPlayerShields(a5)
		move.w	PlayerEnergy(a5),SPlayerEnergy(a5)
		move.l	PlayerCredits(a5),SPlayerCredits(a5)
		move.l	PlayerScore(a5),SPlayerScore(a5)
		move.l	GreenKey(a5),SGreenKey(a5)	;Stato delle 4 chiavi
		move.l	PlayerWeapons(a5),SPlayerWeapons(a5)
		move.l	PlayerWeapons+4(a5),SPlayerWeapons+4(a5)
		move.w	PlayerActiWeapon(a5),SPlayerActiWeapon(a5)

		clr.w	RedScreenCont(a5)
		clr.l	GreenKey(a5)

		moveq	#-1,d1
		lea	PlayerHealthFL(a5),a0
		move.l	d1,(a0)+
		move.l	d1,(a0)+
		move.l	d1,(a0)+
		move.l	d1,(a0)+
		move.b	d1,(a0)+

;		bsr	PanelRefresh

		rts

;******************************************************************
;* Controlla quali parametri sono cambiati e li rinfresca
;* nel pannello dei punteggi

		xdef	PanelRefresh
PanelRefresh	movem.l	d0-d4/d7/a0-a3,-(sp)

		clr.l	d2

		tst.b	PlayerScoreFL(a5)
		beq.s	PRnoscore
		moveq	#46,d0
		moveq	#20,d1
		move.l	PlayerScore(a5),d2
		moveq	#7,d3
		moveq	#1,d4
		lea	PanelBitplanes(a5),a0
		jsr	ScorePrint		;Stampa Score
		clr.l	d2
PRnoscore

		tst.b	PlayerHealthFL(a5)
		beq.s	PRnohealth
		moveq	#123,d0
		moveq	#18,d1
		move.w	PlayerHealth(a5),d2
		moveq	#3,d3
		moveq	#0,d4
		lea	PanelBitplanes(a5),a0
		jsr	ScorePrint		;Stampa Health
PRnohealth
		tst.b	PlayerShieldsFL(a5)
		beq.s	PRnoshields
		move.w	#151,d0
		moveq	#18,d1
		move.w	PlayerShields(a5),d2
		moveq	#3,d3
		moveq	#0,d4
		lea	PanelBitplanes(a5),a0
		jsr	ScorePrint		;Stampa Shields
PRnoshields
		tst.b	PlayerEnergyFL(a5)
		beq.s	PRnoenergy
		move.w	#177,d0
		moveq	#18,d1
		move.w	PlayerEnergy(a5),d2
		moveq	#4,d3
		moveq	#0,d4
		lea	PanelBitplanes(a5),a0
		jsr	ScorePrint		;Stampa Energy
PRnoenergy
		tst.b	PlayerCreditsFL(a5)
		beq.s	PRnocredits
		move.w	#250,d0
		moveq	#20,d1
		move.l	PlayerCredits(a5),d2
		moveq	#5,d3
		moveq	#1,d4
		lea	PanelBitplanes(a5),a0
		jsr	ScorePrint		;Stampa Credits
PRnocredits
		tst.b	GreenKeyFL(a5)
		beq.s	PRnogreenkey
		move.w	#1+(8*40),d0		;offset
		moveq	#21,d1			;colore
		tst.b	GreenKey(a5)
		beq.s	PRngk
		moveq	#61,d1			;colore
PRngk		lea	KeyLightData(pc),a2	;gfx data
		bsr	TurnLight
PRnogreenkey
		tst.b	YellowKeyFL(a5)
		beq.s	PRnoyellowkey
		move.w	#3+(8*40),d0		;offset
		moveq	#21,d1			;colore
		tst.b	YellowKey(a5)
		beq.s	PRnyk
		move.w	#195,d1			;colore
PRnyk		lea	KeyLightData(pc),a2	;gfx data
		bsr	TurnLight
PRnoyellowkey
		tst.b	RedKeyFL(a5)
		beq.s	PRnoredkey
		move.w	#1+(23*40),d0		;offset
		moveq	#21,d1			;colore
		tst.b	RedKey(a5)
		beq.s	PRnrk
		moveq	#62,d1			;colore
PRnrk		lea	KeyLightData(pc),a2	;gfx data
		bsr	TurnLight
PRnoredkey
		tst.b	BlueKeyFL(a5)
		beq.s	PRnobluekey
		move.w	#3+(23*40),d0		;offset
		moveq	#21,d1			;colore
		tst.b	BlueKey(a5)
		beq.s	PRnbk
		moveq	#44,d1			;colore
PRnbk		lea	KeyLightData(pc),a2	;gfx data
		bsr	TurnLight
PRnobluekey
		lea	WeaponsFL(a5),a3
		moveq	#0,d7
PRweaponloop	tst.b	(a3)+
		beq.s	PRnoweapon
		moveq	#0,d1			;colore arma non posseduta
		lea	PlayerWeapons(a5),a0
		tst.b	(a0,d7.w)		;Test se arma posseduta
		beq.s	PRyw
		move.w	#195,d1			;colore arma posseduta
		cmp.b	PlayerActiWeapon+1(a5),d7
		bne.s	PRyw
		moveq	#62,d1			;colore arma attiva
PRyw		lea	WeaponLightData(pc),a2
		lea	(a2,d7.w*8),a2		;a2=gfx data
		move.w	(a2)+,d0		;offset
		bsr	TurnLight
PRnoweapon	addq.w	#1,d7
		cmp.w	#6,d7
		blt.s	PRweaponloop

		lea	PlayerHealthFL(a5),a0
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.b	(a0)+

		movem.l	(sp)+,d0-d4/d7/a0-a3
		rts

;******************************************************************
;* Cambia il colore del segnalatore di chiave raccolta
;* (si tratta di un rettangolo di 8*6 pixel).
;* Richiede:
;*	d0 = offset nel pannello
;*	d1 = colore
;*	a2 = pun. ai 6 byte da tracciare

BTPLSET		MACRO
		move.b	(a2)+,d2
		or.b	d2,\1(a0)
		ENDM

BTPLCLR		MACRO
		move.b	(a2)+,d2
		not.b	d2
		and.b	d2,\1(a0)
		ENDM

TurnLight
		lea	PanelBitplanes(a5),a1
		moveq	#-1,d2
		moveq	#7,d3
		move.l	a2,d4
TOKLloop	move.l	d4,a2
		move.l	(a1)+,a0
		lea	(a0,d0.w),a0
		lsr.b	#1,d1
		bcc.s	TOKLclr
		BTPLSET	0
		BTPLSET	40
		BTPLSET	80
		BTPLSET	120
		BTPLSET	160
		BTPLSET	200
		dbra	d3,TOKLloop
		rts
TOKLclr		BTPLCLR	0
		BTPLCLR	40
		BTPLCLR	80
		BTPLCLR	120
		BTPLCLR	160
		BTPLCLR	200
		dbra	d3,TOKLloop

		rts



;*** Dati grafici delle luci delle chiavi sul pannello dei punteggi

KeyLightData	dc.b	255,255,255,255,255,255

;*** Dati grafici dei numeri delle armi sul pannello dei punteggi.
;*** Per ogni numero, 6 byte di dati grafici sono preceduti
;*** dall'offset sul pannello dei punteggi.

WeaponLightData	dc.w	36+(7*40)		;1
		dc.b	16,16,16,16,16,0
		dc.w	38+(7*40)		;2
		dc.b	60,4,60,32,60,0
		dc.w	36+(19*40)		;3
		dc.b	60,4,28,4,60,0
		dc.w	38+(19*40)		;4
		dc.b	36,36,60,4,4,0
		dc.w	36+(31*40)		;5
		dc.b	60,32,60,4,60,0
		dc.w	38+(31*40)		;6
		dc.b	60,32,60,36,60,0

;******************************************************************
;* Inizializza il codice di accesso al primo livello del primo mondo

		xdef	ClearLevelCode
ClearLevelCode

		lea	LevelCodeASC(a5),a0
		move.l	#'181C',(a0)+
		move.l	#'EIGG',(a0)+
		move.l	#'LJRJ',(a0)+
		move.l	#'SE2T',(a0)

		rts

;******************************************************************
;* Routine per calcolare il codice di livello

		xdef	LevelCodeOut

LevelCodeOut
		lea	LevelCode(a5),a1
		move.l	a1,a3

		move.b	PlayerHealth+1(a5),(a1)+
		move.b	PlayerShields+1(a5),(a1)+
		move.w	PlayerEnergy(a5),(a1)+
		move.b	PlayerCredits+1(a5),d6		;d6=byte alto credits
		move.b	d6,(a1)+
		move.w	PlayerCredits+2(a5),(a1)+

		move.w	PlayerActiWeapon(a5),d1
		and.w	#7,d1
		ror.w	#3,d1

		moveq	#0,d2
		lea	PlayerWeapons(a5),a0
		moveq	#5,d7
LCOloop2	move.b	(a0)+,d0
		roxr.b	#1,d0
		roxr.w	#1,d2
		roxr.b	#1,d0
		roxr.w	#1,d2
		dbra	d7,LCOloop2

		lsr.w	#4,d2
		or.w	d2,d1
		move.w	d1,(a1)+

		move.w	CurrentGame(a5),d0
		lsl.w	#4,d0
		or.w	CurrentLevel(a5),d0
		move.b	d0,(a1)+

		move.l	a3,a0
		moveq	#0,d0
		moveq	#9,d7
LCOloop3	add.b	(a0)+,d0	;Calcola checksum
		dbra	d7,LCOloop3
		lsl.b	#1,d0
		or.b	d0,d6		;Or tra checksum e bit alto credits
		move.b	d6,4(a3)	;Scrive checksum + bit alto credits

	;*** Critta codice

		move.l	#%01100101101001001011010100101101,d0
		move.l	a3,a0
		eor.l	d0,(a0)+
		eor.l	d0,(a0)+
		eor.w	d0,(a0)


	;*** Converte il codice di livello nel formato ASCII

		lea	LevelCodeASC(A5),a1
		moveq	#0,d0
LCTAloop	bfextu	(a3){d0:5},d1
		add.b	#49,d1
		cmp.b	#58,d1		;Test se deve essere codificato come un numero
		blt.s	LCTAnum		; Se si, salta
		addq.b	#7,d1
LCTAnum		move.b	d1,(a1)+
		addq.w	#5,d0
		cmp.w	#80,d0
		blt.s	LCTAloop

		clr.b	(a1)		;Scrive zero di terminazione

		rts


;******************************************************************
;* Routine per trasformare il codice di livello in valori
;* utilizzabili dal gioco

		xdef	LevelCodeIn

LevelCodeIn
		bsr	CheckAccessCode
		beq.s	LCIcok			; Se codice corretto, salta
		bsr	ClearLevelCode
		bsr	CheckAccessCode
LCIcok
	;*** Interpreta il codice di livello

		lea	LevelCode(A5),a1

		moveq	#0,d0
		move.b	(a1)+,d0
		move.w	d0,PlayerHealth(a5)
		move.b	(a1)+,d0
		move.w	d0,PlayerShields(a5)
		move.w	(a1)+,d0
		move.w	d0,PlayerEnergy(a5)
		moveq	#0,d0
		move.b	(a1)+,d0
		move.w	d0,PlayerCredits(a5)
		move.w	(a1)+,PlayerCredits+2(a5)

		move.w	(a1)+,d0
		move.w	d0,d1
		moveq	#13,d2
		lsr.w	d2,d1
		move.w	d1,PlayerActiWeapon(a5)
		lsl.w	#4,d0

		lea	PlayerWeapons+6(a5),a0
		moveq	#5,d7
LCIloop2	moveq	#0,d1
		roxl.w	#1,d0
		roxl.b	#1,d1
		roxl.w	#1,d0
		roxl.b	#1,d1
		move.b	d1,-(a0)
		dbra	d7,LCIloop2

		moveq	#0,d0
		move.b	(a1)+,d0
		move.w	d0,d1
		lsr.b	#4,d0
		and.b	#$f,d1
		move.w	d0,CurrentGame(a5)
		move.w	d1,CurrentLevel(a5)

		rts

;******************************************************************
;* Controlla checksum del codice d'accesso.
;* Inoltre elimina checksum dal codice d'accesso.
;* Restituisce flag Z=1 se tutto ok

		xdef	CheckAccessCode

CheckAccessCode
		lea	LevelCode(A5),a1

	;*** Converte il codice dal formato ASCII

		lea	LevelCodeASC(a5),a0
		moveq	#0,d0
ATLCloop	move.b	(a0)+,d1
		sub.b	#49,d1
		cmp.b	#65-49,d1
		blt.s	ATLCnum
		subq.b	#7,d1
ATLCnum		bfins	d1,(a1){d0:5}
		addq.w	#5,d0
		cmp.w	#80,d0
		blt.s	ATLCloop

	;*** Decritta codice

		move.l	#%01100101101001001011010100101101,d0
		move.l	a1,a0
		eor.l	d0,(a0)+
		eor.l	d0,(a0)+
		eor.w	d0,(a0)


		move.b	4(a1),d1	;d6=checksum + bit alto credits
		move.b	d1,d0
		and.b	#1,d0
		move.b	d0,4(a1)	;Elimina checksum dal codice
		eor.b	d0,d1		;d6=checksum

		moveq	#0,d0
		moveq	#9,d2
CACloop1	add.b	(a1)+,d0	;Calcola checksum
		dbra	d2,CACloop1
		lsl.b	#1,d0
		cmp.b	d0,d1
		bne.s	CACnogood

		moveq	#0,d0
		rts

CACnogood
		moveq	#1,d0
		rts

;******************************************************************

	section	__MERGED,BSS

		cnop	0,4

		xdef	LevelCode,LevelCodeASC

LevelCode	ds.b	10	;Codice livello:
				;    num.bit   descrizione
				;	8	Health
				;	8	Shields
				;	16	Energy
				;	24	Credits
				;	3	Active weapon (0-5)
				;	1	Unused=0
				;	2*6	Weapons (665544332211)
				;	4	Game
				;	4	Level

LevelCodeASC	ds.b	18	;Codice livello in formato ASCII


		cnop	0,4

		xdef	PlayerHealth,PlayerShields,PlayerEnergy
		xdef	PlayerCredits,PlayerScore
		xdef	RedScreenCont

RedScreenCont	ds.w	1	;Contatore per permanenza schermo rosso

PlayerHealth	ds.w	1	;Stato di salute del player
PlayerShields	ds.w	1	;Scudi del player
PlayerEnergy	ds.w	1	;Energia del player
PlayerCredits	ds.l	1	;Crediti del player
PlayerScore	ds.l	1	;Punteggio

                IFD     DEVMODE
                xdef    Invincible
Invincible      ds.b    1
                ENDC

		xdef	GreenKey,YellowKey,RedKey,BlueKey

GreenKey	ds.b	1	;Se=1, il player possiede la chiave
YellowKey	ds.b	1	;Se=1, il player possiede la chiave
RedKey		ds.b	1	;Se=1, il player possiede la chiave
BlueKey		ds.b	1	;Se=1, il player possiede la chiave

		xdef	PlayerHealthFL,PlayerShieldsFL,PlayerEnergyFL
		xdef	PlayerCreditsFL,PlayerScoreFL
		xdef	GreenKeyFL,YellowKeyFL,RedKeyFL,BlueKeyFL
		xdef	WeaponsFL

;* Flag che indicano se sono modificati i vari punteggi

PlayerHealthFL	ds.b	1
PlayerShieldsFL	ds.b	1
PlayerEnergyFL	ds.b	1
PlayerCreditsFL	ds.b	1
PlayerScoreFL	ds.b	1
GreenKeyFL	ds.b	1
YellowKeyFL	ds.b	1
RedKeyFL	ds.b	1
BlueKeyFL	ds.b	1
WeaponsFL	ds.b	8

		ds.b	1	;Usato per allineare

		cnop	0,2

	;*** Valori salvati ad inizio livello

SPlayerHealth	ds.w	1	;Stato di salute del player
SPlayerShields	ds.w	1	;Scudi del player
SPlayerEnergy	ds.w	1	;Energia del player
SPlayerCredits	ds.l	1	;Crediti del player
SPlayerScore	ds.l	1	;Punteggio

SGreenKey	ds.b	1	;Se=1, il player possiede la chiave
SYellowKey	ds.b	1	;Se=1, il player possiede la chiave
SRedKey		ds.b	1	;Se=1, il player possiede la chiave
SBlueKey	ds.b	1	;Se=1, il player possiede la chiave

SPlayerWeapons	ds.b	8	;Un byte per ogni arma del player:
SPlayerActiWeapon ds.w	1	;Arma attiva del player	(Se=-1, nessuna arma)

		ds.w	1	;Usato per allineare

		cnop	0,4
