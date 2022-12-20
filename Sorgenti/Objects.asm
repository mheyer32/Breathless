;*********************************************************************
;*
;*	Objects.asm
;*
;*	Rendering e animazione oggetti e nemici
;*
;*	- Gestione illuminazione oggetti
;*	- Gestione proiettili player
;*
;*
;*********************************************************************

		include	'TMap.i'
		include	'MulDiv64.i'
		include	'System'

;ChunkyPointer	EQU	0  ; This doesn't work, we can't enforce the place of ChunkyPointer in BSS __MERGED this way

		xref	ChunkyPointer,ChunkyBuffer
;		xref	ChunkyBuffer
		xref	Yoffset
		xref	PlayerX,PlayerY,PlayerZ,PlayerSpeed,PlayerDeath
		xref	LookHeight,LookHeightNum
		xref	PlayerHeading,CPlayerBlockPun
		xref	joyfire,joyfireP
		xref	PlayerWeaponAuto
		xref	VBTimer,Canimcounter
		xref	source_width
		xref	window_width,window_height,pixel_type
		xref	window_width2,window_height2,window_size
		xref	windowXratio,windowYratio
		xref	sintable,costable,arcsintable
		xref	Blocks,Map
		xref	GunObj1,GunObj2,GunObj3,GunObj4,GunObj5
		xref	ExplObj1,ExplObj2,ExplObj3,ExplObj4,ExplObj5
		xref	RaycastObjects,ObjectImages,Objects
		xref	ObjVTable,ObjVTablePun
		xref	LightingTable,GlobalLight
		xref	TriggerBlockListPun
		xref	PlayerHealth,PlayerShields,PlayerEnergy
		xref	PlayerCredits,PlayerScore
		xref	PlayerHealthFL,PlayerShieldsFL,PlayerEnergyFL
		xref	PlayerCreditsFL,PlayerScoreFL
		xref	PlayerWeapons,PlayerActiWeapon
		xref	PlayerWeaponPun
		xref	WeaponOsc,WeaponOscDir
		xref	GlobalSound0,GlobalSound1,GlobalSound2,GlobalSound3
		xref	GlobalSound4,GlobalSound5,GlobalSound6,GlobalSound7
		xref	GlobalSound8,GlobalSound9,GlobalSound10
		xref	ProgramState

		xref	PlayerHit
		xref	PlaySoundFX,BufferedPlaySoundFX
		xref	ObjBufferedPlaySoundFX
		xref	BufferedStopSoundFX
		xref	ScorePrint

;*********************************************************************
;*** Calcola la radice quadrata del numero in d2.l
;*** Il risultato e' in d0.l

; d0=result
; d1=low
; d3=high
; d4=i
; d5=tmp
; d6 = non usato
; d7 = non usato

SQRT		MACRO

		move.l	d2,d1		;low = v
		clr.l	d3		;high = 0
		move.l	d3,d0		;result = 0

		moveq	#15,d4
SQRTloop\@	add.l	d0,d0		;result += result
		lsl.l	#1,d1
		roxl.l	#1,d3
		lsl.l	#1,d1
		roxl.l	#1,d3
		moveq	#1,d5
		add.l	d0,d5
		add.l	d0,d5		;tmp = result + result + 1;
		cmp.l	d5,d3		;if (high >= tmp)
		blt.s	SQRTj1\@
		addq.l	#1,d0		;   result++
		sub.l	d5,d3		;   high -= tmp
SQRTj1\@	dbra	d4,SQRTloop\@

		move.l	d0,d5
		mulu.w	d5,d5
		sub.l	d5,d2
		addq.l	#1,d2		;d2=v-(result*result)+1
		cmp.l	d0,d2		;if (v-(result*result)+1 >= result)
		blt.s	SQRTj2\@
		addq.l	#1,d0		;   result++
SQRTj2\@
		ENDM

;****************************************************************************
;* Macro animazione passi dei nemici
;* Parametri:
;*	 \1 : un registro dati libero
;*	 \2 : il registro indirizzi che punta all'oggetto

WALKANIM	MACRO
		move.w	VBTimer+2(a5),\1
		and.w	#$1c,\1
		lsr.w	#2,\1
		move.w	\1,obj_animcont(\2)
		ENDM

;****************************************************************************
; Animazione oggetti

AnimateObjects


		move.l	Canimcounter(a5),d6
		move.l	d6,d7
		swap	d6
		lsr.l	#2,d6
		add.l	animcarryobj(a5),d6	;Somma riporto precedente
		move.w	d6,animcarryobj+2(a5)	;Scrive nuovo riporto
		swap	d6			;d6=Num. frame
		move.w	d6,animstep(a5)		;Salva per usi successivi


;		tst.w	PlayerWeapon1Auto(a5)	;Test se autofire
;		bne.s	AOokauto1		; Se si, salta
;		move.w	joyfire1(a5),d0
;		add.w	d0,Fire1(a5)		;Somma num. di volte che si  premuto fire
;		bra.s	AOnofire1
;AOokauto1	tst.w	joyfire1P(a5)		;Tasto fire premuto ?
;		beq.s	AOnofire1
;		add.w	d7,Fire1(a5)		;Somma num. di 50esimi
;AOnofire1	clr.w	joyfire1(a5)




		move.l	PlayerWeaponPun(a5),d0
		beq.s	AOfireres
		move.l	d0,a4
		cmp.b	#1,o_param8(a4)		;Lanciafiamme ?
		bne.s	AOnoflame		; Se no, salta
		clr.w	joyfire(a5)
		tst.w	joyfireP(a5)		;Tasto fire premuto ?
		beq.s	AOnofirepress		; Se no, salta
		add.w	d7,Fire(a5)		;Somma num. di 50esimi
		bra.s	AOfireout
AOnofirepress	tst.w	Fire(a5)		;Ci sono ancora proiettili da sparare ?
		bgt.s	AOfireout		; Se si, salta
		move.l	o_sound1(a4),a0
		jsr	BufferedStopSoundFX	;Stop sound
		bra.s	AOfireout
AOnoflame	move.w	joyfire(a5),d0
		add.w	d0,Fire(a5)		;Somma num. di volte che si  premuto fire
AOfireres	clr.w	joyfire(a5)
AOfireout






	;*** Animazione dei fotogrammi per animazioni di tipo 1 (semplice)

		move.l	ObjectImages(a5),a0
		addq.l	#4,a0
AOfloop		move.l	(a0)+,d0
		beq.s	AOfout
		move.l	d0,a1
		tst.b	o_animtype(a1)		;Test animation type
		ble.s	AOfloop
		cmp.b	#4,o_objtype(a1)	;Test object type
		bge.s	AOfloop
		move.l	o_animcont(a1),d1	;a2=contatore frame corrente
		add.w	d6,d1
		cmp.w	o_numframes(a1),d1	;Superato il numero di frame ?
		blt.s	AOfok1			; Se no, salta
		moveq	#0,d1			;Altrimenti resetta il pun. all'inizio della lista
		move.l	o_frameslist(a1),d0
		bra.s	AOfok2
AOfok1		move.l	o_frameslist(a1,d1.l*4),d0	;d0=pun. al prossimo frame
AOfok2		move.l	d0,o_currentframe(a1)	;Scrive pun. al nuovo frame
		move.l	d1,o_animcont(a1)	;Scrive nuovo cont. frame corrente
		bra.s	AOfloop
AOfout



	;***** Gestione pick thing
		move.l	Map(a5),a2		;a2=Pun. mappa
		move.l	ObjPickThings(a5),d0
		beq	AOTout
AOTloop		move.l	d0,a0
		tst.b	obj_subtype(a0)		;Oggetto raccolto ?
		bmi.s	AOTrem			; Se si, salta
		move.l	obj_listnext(a0),d0
		bne.s	AOTloop
		bra	AOTout
AOTrem
		;*** Elimina oggetto dallo schermo
		move.l	obj_listnext(a0),d0
		move.w	obj_mapoffset(a0),d2
		move.l	obj_blocknext(a0),d3	;Se pun. next obj<>0
		bne.s	AOPTremnex		; salta
		move.l	obj_blockprev(a0),d4	;Se pun. previous obj<>0
		bne.s	AOPTremnj1		; salta
		clr.w	2(a2,d2.w*4)		;Azzera nella mappa il numero dell'oggetto alla posizione precedente
		bra.s	AOPTremesc
AOPTremnj1	move.l	d4,a1
		clr.l	obj_blocknext(a1)
		bra.s	AOPTremesc
AOPTremnex	move.l	obj_blockprev(a0),d4	;Se pun. previous obj<>0
		bne.s	AOPTremj1			; salta
		move.l	d3,a1
		clr.l	obj_blockprev(a1)
		move.w	obj_number(a1),2(a2,d2.w*4)
		bra.s	AOPTremesc
AOPTremj1	move.l	d4,a1
		move.l	d3,obj_blocknext(a1)
		move.l	d3,a1
		move.l	d4,obj_blockprev(a1)
AOPTremesc
		move.l	obj_listnext(a0),d3	;Se pun. next obj<>0
		bne.s	AOPT2remnex		; salta
		move.l	obj_listprev(a0),d4	;Se pun. previous obj<>0
		bne.s	AOPT2remnj1		; salta
		clr.l	ObjPickThings(a5)
		bra.s	AOPT2remesc
AOPT2remnj1	move.l	d4,a1
		clr.l	obj_listnext(a1)
		bra.s	AOPT2remesc
AOPT2remnex	move.l	obj_listprev(a0),d4	;Se pun. previous obj<>0
		bne.s	AOPT2remj1		; salta
		move.l	d3,a1
		clr.l	obj_listprev(a1)
		move.l	a1,ObjPickThings(a5)
		bra.s	AOPT2remesc
AOPT2remj1	move.l	d4,a1
		move.l	d3,obj_listnext(a1)
		move.l	d3,a1
		move.l	d4,obj_listprev(a1)
AOPT2remesc
		move.l	ObjFree(a5),obj_listnext(a0)	;Inserisce oggetto nella lista oggetti liberi
		move.l	a0,ObjFree(a5)

		clr.l	obj_listprev(a0)
		clr.l	obj_blockprev(a0)
		clr.l	obj_blocknext(a0)

		tst.l	d0
		bne	AOTloop
AOTout



	;***** Animazione esplosioni

		lea	TriggerBlockListPun+6(a5),a4
		moveq	#0,d7			;d7=flags per gestione illuminazione:
						;	bit 0 : settato se sono attive esplosioni la cui
						;		animazione ha superato la met
						;	bit 1 : settato se sono attive esplosioni la cui
						;		animazione non ha superato la met
		move.l	Map(a5),a2		;a2=Pun. mappa
		move.l	ObjExplosions(a5),d0
		beq	AOEout
AOEloop		move.l	d0,a0
		move.l	obj_image(a0),a3	;a3=pun. image dell'esplosione
		move.w	obj_animcont(a0),d1
		add.w	d6,d1
		move.w	o_numframes(a3),d0
		cmp.w	d0,d1			;Superato il numero di frame ?
		bge.s	AOEstop			; Se si, salta
		move.w	d1,obj_animcont(a0)	;Scrive nuovo cont. frame corrente
		add.w	d1,d1
		cmp.w	d0,d1			;L'animazione ha superato la met ?
		blt.s	AOElan1			; Se no, salta
		bset	#0,d7
		bra.s	AOElan2
AOElan1		bset	#1,d7
AOElan2		move.l	obj_listnext(a0),d0
		bne.s	AOEloop
		bra	AOEout
AOEstop
		bset	#0,d7
		move.l	obj_listnext(a0),d0

		moveq	#0,d5
		tst.l	obj_oldimage(a0)	;Test se l'oggetto esploso pu lasciare resti
		beq.s	AOESnoresti		; Se no, salta
		move.w	o_param2(a3),d5		;Test se lasciare resti a terra
		bne.s	AOESremesc		; Se si, salta
AOESnoresti
		;*** Elimina oggetto dallo schermo
		move.w	obj_mapoffset(a0),d2
		move.l	obj_blocknext(a0),d3	;Se pun. next obj<>0
		bne.s	AOESremnex		; salta
		move.l	obj_blockprev(a0),d4	;Se pun. previous obj<>0
		bne.s	AOESremnj1		; salta
		clr.w	2(a2,d2.w*4)		;Azzera nella mappa il numero dell'oggetto alla posizione precedente
		bra.s	AOESremesc
AOESremnj1	move.l	d4,a1
		clr.l	obj_blocknext(a1)
		bra.s	AOESremesc
AOESremnex	move.l	obj_blockprev(a0),d4	;Se pun. previous obj<>0
		bne.s	AOESremj1			; salta
		move.l	d3,a1
		clr.l	obj_blockprev(a1)
		move.w	obj_number(a1),2(a2,d2.w*4)
		bra.s	AOESremesc
AOESremj1	move.l	d4,a1
		move.l	d3,obj_blocknext(a1)
		move.l	d3,a1
		move.l	d4,obj_blockprev(a1)
AOESremesc
		;*** Elimina oggetto dalla lista delle esplosioni
		move.l	obj_listnext(a0),d3	;Se pun. next obj<>0
		bne.s	AOES2remnex		; salta
		move.l	obj_listprev(a0),d4	;Se pun. previous obj<>0
		bne.s	AOES2remnj1		; salta
		clr.l	ObjExplosions(a5)
		bra.s	AOES2remesc
AOES2remnj1	move.l	d4,a1
		clr.l	obj_listnext(a1)
		bra.s	AOES2remesc
AOES2remnex	move.l	obj_listprev(a0),d4	;Se pun. previous obj<>0
		bne.s	AOES2remj1		; salta
		move.l	d3,a1
		clr.l	obj_listprev(a1)
		move.l	a1,ObjExplosions(a5)
		bra.s	AOES2remesc
AOES2remj1	move.l	d4,a1
		move.l	d3,obj_listnext(a1)
		move.l	d3,a1
		move.l	d4,obj_listprev(a1)
AOES2remesc
		tst.w	d5			;Test se lasciare resti a terra
		bmi.s	AOESrestien
		bgt.s	AOESrestiexp

		move.l	ObjFree(a5),obj_listnext(a0)	;Inserisce oggetto nella lista oggetti liberi
		move.l	a0,ObjFree(a5)

		clr.l	obj_listprev(a0)
		clr.l	obj_blockprev(a0)
		clr.l	obj_blocknext(a0)

		tst.l	d0
		bne	AOEloop				;Salta al loop
		bra.s	AOEout
AOESrestien
		;*** Resti del nemico
		move.l	obj_oldimage(a0),obj_image(a0)	;Ripristina pun. image del nemico
		move.w	#128,obj_animcont(a0)		;Frame nemico a terra
		move.b	#10,obj_type(a0)	;Segnala che si tratta dei resti di un nemico
		move.b	#-3,obj_status(a0)
		bra.s	AOESrestith
AOESrestiexp
		;*** Resti dell'esplosione
		move.w	o_numframes(a3),d1
		subq.w	#1,d1
		move.w	d1,obj_animcont(a0)	;Frame nemico a terra
		move.b	#10,obj_type(a0)	;Segnala che si tratta dei resti di un nemico
AOESrestith
		;*** Inserisce oggetto nella lista dei Things
		move.l	ObjThings(a5),a1
		move.l	a1,obj_listnext(a0)
		beq.s	AOESresnopre
		move.l	a0,obj_listprev(a1)
AOESresnopre	clr.l	obj_listprev(a0)
		move.l	a0,ObjThings(a5)

		;*** Test se i resti rimangono su una porta
		move.l	obj_blockpun(a0),a1	;a1=Pun. blocco
		moveq	#0,d1
		move.b	bl_Trigger(a1),d1	;Il blocco corrente  soggetto ad un trigger ?
		beq.s	AOESnotrig		; Se no, salta
		move.w	(a4,d1.l*8),d3		;Legge comando precedente
		and.w	#$7fff,d3		;Preserva bit alto
		or.w	obj_number(a0),d3	;Inserisce numero oggetto
		move.w	d3,(a4,d1.l*8)		;Segnala alle routine di animazione che i resti sono su un blocco soggetto ad un trigger
AOESnotrig
		tst.l	d0
		bne	AOEloop			;Salta al loop
AOEout

	;*** Gestione illuminazione esplosioni

		move.l	GlobalLight(a5),d0
		cmp.b	#2,d7			;Ci sono esplosioni la cui animazione non ha superato la met ?
		blt.s	AGLdec			; Se no, salta
		moveq	#-6,d0
AGLdec		addq.l	#1,d0
		bgt.s	AGLnodec
		move.l	d0,GlobalLight(a5)
AGLnodec






		move.w	Canimcounter+2(a5),d0	;d0=Num. di 50esimi trascorsi dall'ultima volta
;		lsr.w	#1,d0			;Ottiene il num. di 25esimi

AOMainLoop
		move.w	d0,repeatanim(a5)	;Scrive il contatore
		and.b	#1,d0			;Anima i nemici solo a 25esimi
		beq	MNout

	;***** Movimento dei nemici

		lea	ObjSinCos(pc),a1
		move.l	Map(a5),a2			;a2=Pun. mappa
		move.l	Blocks(a5),a4
		move.l	ObjEnemies(a5),d0
		beq	MNout
MNloop		move.l	d0,a6
		move.l	obj_listnext(a6),d7	;d7=pun. al prossimo nemico


		tst.b	obj_inactive(a6)	;Il nemico  attivo ?
		bne	MNnext2			; Se no, salta


	;*** Calcola nuova posizione x,z

		move.w	obj_speed(a6),d5	;d5=entita' del movimento
		beq	MNnomove		; Se=0, non lo muove

		move.w	obj_heading(a6),d4
		lsr.w	#6,d4
		move.w	(a1,d4.w*4),d0		;d0=cos
		move.w	2(a1,d4.w*4),d1		;d1=sin

		muls.w	d5,d0
		muls.w	d5,d1
		asr.l	#8,d0			;Elimina parte decimale
		asr.l	#8,d1
		add.w	obj_x(a6),d0		;Somma alla posiz. precedente
		add.w	obj_z(a6),d1


	;*** Calcola distanza nemico dal player

		move.w	PlayerX(a5),d2
		sub.w	d0,d2
		move.w	PlayerZ(a5),d3
		sub.w	d1,d3
		muls.w	d2,d2
		muls.w	d3,d3
		add.l	d3,d2			;d2=distanza ^ 2

	;*** Test se muovere nemico:
	;***  muove solo nemici in vista e nemici piu' vicini
	;***  della massima distanza consentita

		tst.b	obj_bmstatus(a6)	;Nemico in vista ?
		bmi.s	MNinview		; Se si, salta
		cmp.l	#MAX_ENEMY_DIST,d2	;Se distanza dal player > Massima distanza,
		bgt	MNnext			; non muove questo nemico (per risparmiare tempo macchina)

MNinview	bclr	#7,obj_bmstatus(a6)	;Azzera flag nemico in vista



	;*** Gestione fire
		cmp.l	obj_attackdist(a6),d2	;Il player  entro la distanza di attacco ?
		bgt.s	MNnoattack		; Se no, salta
		subq.b	#1,obj_attackdelay(a6)	;Decrementa contatore
		bgt.s	MNnoattack		; Se>0, non spara
		tst.b	obj_status(a6)		;Se status<0, non pu sparare
		bmi.s	MNfrj
		move.b	#4,obj_status(a6)
		move.w	#$0104,obj_cont1(a6)
		clr.w	obj_speed(a6)
MNfrj		clr.l	d1
		move.b	obj_attackprob(a6),d1
		bsr	Rnd
		lsl.b	#2,d0
		add.b	d1,d0
		addq.b	#8,d0
		move.b	d0,obj_attackdelay(a6)	;Ripristina il contatore
		bra	MNnext
MNnoattack


	;*** Ctrl collisione col player

		move.w	obj_width(a6),d3	;d3=obj_width
		mulu.w	d3,d3			;!!!OTTIMIZZARE!!! (vedi ToDo.txt)
		add.l	#(PLAYER_WIDTH*PLAYER_WIDTH)<<1,d3
		cmp.l	d3,d2
		ble	MNnewdirP		;Salta se c'e' collisione
MNnopcoll
		tst.b	obj_playercoll(a6)	;Test contatore collisione col player
		ble.s	MNnocollcont		; Se <= 0, salta
		subq.b	#1,obj_playercoll(a6)	;Decrementa contatore
MNnocollcont

		move.w	d0,d2
		move.w	d1,d3
		and.w	#GRID_AND_W,d2
		and.w	#GRID_AND_W,d3
		lsr.w	#BLOCK_SIZE_B,d2
		add.w	d3,d3
		or.w	d3,d2			;d2=offset nella mappa

		move.w	(a2,d2.w*4),d3		;d3=num. nuovo blocco
		bmi	MNnewdir		;Se num.blocco<0, non puo' muoversi
		lsl.w	#2,d3
		lea	(a4,d3.w*8),a3		;a3=Pun. nuovo blocco
		btst	#3,bl_Attributes(a3)	;Testa flag enemy blocker
		bne	MNnewdir		; Se i nemici non possono andare sul blocco, salta
		move.l	a3,saveblpun(a5)	;Salva temporaneamente il pun.
		move.w	bl_FloorHeight(a3),d5	;d5=Pavimento nuovo blocco
		move.w	bl_CeilHeight(a3),d6	;d6=Soffitto nuovo blocco

		move.w	obj_mapoffset(a6),d3
		cmp.w	d3,d2			;Test se l'oggetto ha cambiato blocco
		beq.s	MNnochgbl		; Se no, salta il test di collisione

;		move.b	bl_Trigger(a3),obj_trigblock(a6)	;Il blocco  soggetto ad un trigger ?

		move.w	(a2,d3.w*4),d3		;d3=num. blocco precedente
		lsl.w	#2,d3
		lea	(a4,d3.w*8),a0		;a0=pun. blocco precedente
		move.w	d5,d4
		sub.w	bl_FloorHeight(a0),d4	;Calcola dislivello pavimento
		bmi.s	MNccdisc		;Se dislivello in discesa, salta
		cmp.w	#24,d4
		bgt	MNnewdir		;Se dislivello troppo grande, non va bene
		move.w	d6,d4
		cmp.w	bl_CeilHeight(a0),d6	;Verifica quale soffitto e' piu' basso
		blt.s	MNccj1
		move.w	bl_CeilHeight(a0),d4
MNccj1		sub.w	d5,d4			;Calcola dislivello tra il soffitto piu' basso e pavimento del nuovo blocco
		cmp.w	obj_height(a6),d4	;Test se ci passa 
		blt	MNnewdir
		bra.s	MNnochgbl		;Tutto ok
MNccdisc	neg.w	d4
		cmp.w	#24,d4
		bgt	MNnewdir		;Se dislivello troppo grande, non va bene
		move.w	d6,d4
		sub.w	bl_FloorHeight(a0),d4	;Calcola dislivello tra nuovo soffitto e pavimento attuale
		cmp.w	obj_height(a6),d4	;Test se ci passa 
		blt	MNnewdir

MNnochgbl
		move.l	d2,a3			;Salva in a3 il nuovo offset nella mappa
		and.b	#%10011111,obj_bmstatus(a6)
		clr.l	d4
		move.b	obj_heading(a6),d4
		move.l	(CollTestTable.w,pc,d4.l*4),a0
		jmp	(a0)			;Salta alla routine di ctrl collisioni
MNctrlret
		tst.l	d0			;Se d0=0, allora non si puo' muovere
		beq	MNnewdir		; e salta alla routine per scegliere una nuova direzione

		move.l	a3,d2			;Recupera da a3 il nuovo offset nella mappa
		move.w	obj_mapoffset(a6),d6	;d6=offset precedente nella mappa
		cmp.w	d2,d6			;Se il nuovo offset e' diverso da quello vecchio
		beq.s	MNncbl

		sub.l	a3,a3
		move.w	2(a2,d2.w*4),d3		;Testa se c'e' un altro oggetto nel nuovo blocco
		beq.s	MNnonbobj		; Se non c'e', salta
		lea	ObjectsPunListMinus4(a5),a0
		move.l	(a0,d3.w*4),a0		;a0=Pun. al primo oggetto sul blocco
		move.l	a0,a3
MNctrlobjcoll	cmp.b	#2,obj_type(a0)		;Test tipo oggetto
		ble	MNnewdir		; Se  un nemico o un thing, deve cambiare direzione
MNctrlobjnext	move.l	obj_blocknext(a0),a0	;Prende il prossimo oggetto
		tst.l	a0
		bne.s	MNctrlobjcoll
MNnonbobj
		move.l	obj_blocknext(a6),d3	;Se pun. next obj<>0
		bne.s	MNremnex		; salta
		move.l	obj_blockprev(a6),d4	;Se pun. previous obj<>0
		bne.s	MNremnj1		; salta
		clr.w	2(a2,d6.w*4)		;Azzera nella mappa il numero dell'oggetto alla posizione precedente
		bra.s	MNremesc
MNremnj1	move.l	d4,a0
		clr.l	obj_blocknext(a0)
		bra.s	MNremesc
MNremnex	move.l	obj_blockprev(a6),d4	;Se pun. previous obj<>0
		bne.s	MNremj1			; salta
		move.l	d3,a0
		clr.l	obj_blockprev(a0)
		move.w	obj_number(a0),2(a2,d6.w*4)
		bra.s	MNremesc
MNremj1		move.l	d4,a0
		move.l	d3,obj_blocknext(a0)
		move.l	d3,a0
		move.l	d4,obj_blockprev(a0)
MNremesc
		clr.l	obj_blocknext(a6)
		tst.l	a3
		beq.s	MNnbbj
		move.l	a3,obj_blocknext(a6)
		move.l	a6,obj_blockprev(a3)
MNnbbj
		move.w	obj_number(a6),2(a2,d2.w*4)	;Scrive nella mappa il numero dell'oggetto alla nuova posizione
		move.w	d2,obj_mapoffset(a6)		;Memorizza nuovo offset nella mappa
		move.l	saveblpun(a5),obj_blockpun(a6)	;Scrive il pun. al nuovo blocco
		clr.l	obj_blockprev(a6)
;		clr.l	obj_blocknext(a6)

MNncbl		move.w	d0,obj_x(a6)
		move.w	d1,obj_z(a6)
		move.l	saveblpun(a5),a3
;		move.w	bl_FloorHeight(a3),obj_y(a6)
		clr.b	obj_rotdir(a6)

		bra.s	MNnomove


	;*** Scelta nuova direzione in caso di collisione col player
MNnewdirP
		subq.b	#1,obj_playercoll(a6)	;Decrementa contatore
		bgt.s	MNplcollnoini		; Se>0, salta
		move.b	#10,obj_playercoll(a6)	;Altrimenti inizializza contatore
		clr.l	d0
		move.b	obj_power(a6),d0
		jsr	PlayerHit		; e toglie energia al player
MNplcollnoini	
		btst	#2,obj_subtype(a6)	;In caso di collisione col player, gli rimane addosso ?
		beq.s	MNnewdir		; Se no, salta
		move.b	#6,obj_status(a6)
		move.w	#$0301,obj_cont1(a6)
		clr.w	obj_speed(a6)
		bra.s	MNnomove


	;*** Scelta nuova direzione in caso di collisione
MNnewdir
;		move.b	obj_status(a6),d0	;Se obj_status<0 oppure >1,
;		bmi.s	MNnond			; non cambia direzione
;		cmp.b	#1,d0
;		bgt.s	MNnond
	move.b	obj_status(a6),d0
	cmp.b	#-3,d0		;Se obj_status<-3,
	ble.s	MNnond			; non cambia direzione
;		addq.b	#2,obj_status(a6)	;SOSTITUITA QUESTA RIGA CON LA SUCCESSIVA PER PROVARE A RENDERE I NEMICI MENO COGLIONI
		move.b	#2,obj_status(a6)	; TESTARE COME VA MEGLIO
		move.w	#$0301,obj_cont1(a6)
MNnond		clr.w	obj_speed(a6)

MNnomove
	;*** Scelta nuova direzione e gestione comportamento

		subq.b	#1,obj_cont1(a6)	;Decrementa contatore
		bgt.s	MNnochgdir

		bsr	ChooseEnemyDir

MNnochgdir	move.b	obj_status(a6),d0
		bmi.s	MNnext
		cmp.b	#5,d0
		beq.s	MNnext

		WALKANIM d0,a6		;Animazione frame passi

MNnext
		move.w	obj_mapoffset(a6),d3
		move.w	(a2,d3.w*4),d3		;d3=num. nuovo blocco
		lsl.w	#2,d3
		clr.l	d4
		move.b	bl_Trigger(a4,d3.w*8),d4	;Il blocco  soggetto ad un trigger ?
		beq.s	MNnotrigger			; Se no, salta
		lea	TriggerBlockListPun+6(a5),a0
		lea	(a0,d4.l*8),a0
		bset	#7,(a0)			;Segnala alle routine di animazione che il nemico  su un blocco soggetto ad un trigger
MNnotrigger					; Puo' servire per bloccare una porta che si chiude mentre il nemico vi passa sotto
MNnext2
		move.l	d7,d0
		bne	MNloop
MNout





	;***** Proiettili Player

		bsr	PlayerFire






	;***** Movimento proiettili

		lea	sintable,a1
		move.l	Map(a5),a2			;a2=Pun. mappa
		move.l	Blocks(a5),a4
		move.l	ObjShots(a5),d0
		beq	MSout
MSloop		move.l	d0,a6

		move.w	obj_heading(a6),d4
		move.l	(COSTABLE_OFFSET.w,a1,d4.w*4),d0	;d0=cos
		move.l	(a1,d4.w*4),d1				;d1=sin

		move.w	obj_speed(a6),d5	;d5=entita' del movimento
		cmp.b	obj_maxspeed(a6),d5	;Deve accelerare ?
		bge.s	MSnoaccel		; Se no, salta
		add.b	obj_accel(a6),d5	;Somma accelerazione
		move.w	d5,obj_speed(a6)
MSnoaccel

		add.w	obj_distance(a6),d5
		move.w	d5,obj_distance(a6)

		move.l	obj_image(a6),a3
		cmp.w	o_param4(a3),d5		;Test distanza max
		bgt	MSstop			; Se maggiore, ferma proiettile

		move.w	obj_hheading(a6),d7
		muls.w	d5,d7
		add.l	d7,d7
		swap	d7
		add.w	obj_y0(a6),d7		;d7=nuova posizione y

		ext.l	d5
		muls.l	d5,d0
		muls.l	d5,d1
		swap	d0			;Elimina parte decimale
		swap	d1
		add.w	obj_x0(a6),d0		;Somma alla posiz. iniziale
		add.w	obj_z0(a6),d1

		move.w	d0,d2
		move.w	d1,d3
		and.w	#GRID_AND_W,d2
		and.w	#GRID_AND_W,d3
		lsr.w	#BLOCK_SIZE_B,d2
		add.w	d3,d3
		or.w	d3,d2			;d2=offset nella mappa

			;*** Ctrl collisioni con i muri
		move.l	d2,a3			;Salva in a3 il nuovo offset nella mappa
		move.w	obj_y(a6),d5
		clr.l	d4
		move.b	obj_heading(a6),d4
		move.l	(CollTestTable2.w,pc,d4.l*4),a0
		jmp	(a0)			;Salta alla routine di ctrl collisioni
MSctrlret
		move.l	a3,d2			;Recupera da a3 il nuovo offset nella mappa

		tst.b	obj_subtype(a6)		;Test tipo proiettile
		beq.s	MSctrlobjcoll		;Se del player, salta

			;*** Ctrl collisione con player

		move.w	PlayerX(a5),d3
		sub.w	d0,d3
		move.w	PlayerZ(a5),d4
		sub.w	d1,d4
		muls.w	d3,d3
		muls.w	d4,d4
		add.l	d4,d3			;d3=distanza ^ 2
		move.w	obj_width(a6),d4	;d4=obj_width
		mulu.w	d4,d4			;!!!OTTIMIZZARE!!! (vedi ToDo.txt)
;		add.l	#(PLAYER_WIDTH*PLAYER_WIDTH)<<1,d4
		add.l	#(PLAYER_WIDTH*PLAYER_WIDTH),d4
		cmp.l	d4,d3
		bgt	MSctrlobjout		;Salta se non c'e' collisione
		move.w	PlayerY(a5),d0
		add.w	obj_width(a6),d0
		addq.w	#3,d0
		cmp.w	d7,d0			;Se l'oggetto passa troppo in alto,
		blt	MSctrlobjout		; non c'e' collisione e salta
		clr.l	d0
		move.b	obj_power(a6),d0
		jsr	PlayerHit
		bra	MSstop

			;*** Ctrl collisioni con oggetti
MSctrlobjcoll	clr.l	d4
		move.b	obj_heading(a6),d4
		add.w	d4,d4
		lea	(CollTestOffsetTable.w,pc,d4.w*8),a3
		clr.w	d3
MSctrlobjcoll0	add.w	d2,d3
		move.w	2(a2,d3.w*4),d3
		ble	MSctrlobjnext0
		lea	ObjectsPunListMinus4(a5),a0
		move.l	(a0,d3.w*4),a0 		;a0=Pun. al primo oggetto sul blocco
MSctrlobjcoll1	cmp.b	#2,obj_type(a0)		;Se  un oggetto di tipo >2, non c' collisione
		bgt	MSctrlobjnext1
		move.w	obj_x(a0),d3
		sub.w	obj_x(a6),d3		;d3=obj_x - obj_x
		move.w	obj_z(a0),d4
		sub.w	obj_z(a6),d4		;d4=obj_z - obj_z
		muls.w	d3,d3
		muls.w	d4,d4
		add.l	d4,d3			;d3=distanza ^ 2
		move.w	obj_width(a0),d4	;d4=obj_width
		beq.s	MSctrlobjnext1		;Se width dell'oggetto =0, non c' collisione
		add.w	obj_width(a6),d4
		mulu.w	d4,d4			;!!!OTTIMIZZARE!!! (vedi ToDo.txt)
		cmp.l	d4,d3
		bgt.s	MSctrlobjnext1		;Salta se non c'e' collisione
		cmp.b	#2,obj_type(a0)
		bne.s	MSctrlobjnoen
		cmp.b	#-3,obj_status(a0)	;Se il nemico sta cadendo non deve ucciderlo di nuovo
		beq.s	MSctrlobjnoen
		btst	#1,obj_subtype(a0)	;Il nemico deve fermarsi quando colpito ?
		bne.s	MSctrlobjnostop		; Se no, salta
		move.b	#5,obj_status(a0)
		move.w	#$0201,obj_cont1(a0)
		clr.w	obj_speed(a0)
MSctrlobjnostop	moveq	#0,d3
		move.b	obj_power(a6),d3
		sub.w	d3,obj_strength(a0)	;Decrementa resistenza del nemico
		bgt.s	MSctrlobjnodes
		bsr	DestroyEnemy
		bra	MSstop
MSctrlobjnodes	btst	#3,obj_subtype(a0)	;Test se pu emettere pi suoni in contemporanea
		bne.s	MSplsnd			; Se si, salta
		btst	#7,obj_subtype(a0)	;Sta gi emettendo un suono ?
		bne	MSstop			; Se si, salta
		bset	#7,obj_subtype(a0)	;Setta il bit
MSplsnd		moveq	#1,d0			;Hit sound
		jsr	ObjBufferedPlaySoundFX
MSctrlobjnoen	bra	MSstop
MSctrlobjnext1	move.l	obj_blocknext(a0),a0
		tst.l	a0
		bne	MSctrlobjcoll1
MSctrlobjnext0	move.w	(a3)+,d3
		bne	MSctrlobjcoll0
MSctrlobjout

		move.w	obj_mapoffset(a6),d6	;d6=offset precedente nella mappa
		cmp.w	d2,d6			;Se il nuovo offset e' diverso da quello vecchio
		beq	MSnochgbl

		move.w	(a2,d2.w*4),d3		;d3=num. nuovo blocco
		bmi	MSstop			;Se num.blocco<0, ferma proiettile
		lsl.w	#2,d3
		lea	(a4,d3.w*8),a3		;a3=Pun. nuovo blocco
		move.l	a3,saveblpun(a5)	;Salva temporaneamente il pun.
		move.w	bl_FloorHeight(a3),d3	;d3=Pavimento nuovo blocco
		cmp.w	d3,d5			;Test collisione con pavimento
		blt	MSstop
		move.w	bl_CeilHeight(a3),d3	;d3=Soffitto nuovo blocco
		sub.w	obj_height(a6),d3	;Somma altezza oggetto
		cmp.w	d3,d5			;Test collisione con soffitto
		bge	MSstop

		move.l	obj_blocknext(a6),d3	;Se pun. next obj<>0
		bne.s	MSremnex		; salta
		move.l	obj_blockprev(a6),d4	;Se pun. previous obj<>0
		bne.s	MSremnj1		; salta
		clr.w	2(a2,d6.w*4)		;Azzera nella mappa il numero dell'oggetto alla posizione precedente
		bra.s	MSremesc
MSremnj1	move.l	d4,a0
		clr.l	obj_blocknext(a0)
		bra.s	MSremesc
MSremnex	move.l	obj_blockprev(a6),d4	;Se pun. previous obj<>0
		bne.s	MSremj1			; salta
		move.l	d3,a0
		clr.l	obj_blockprev(a0)
		move.w	obj_number(a0),2(a2,d6.w*4)
		bra.s	MSremesc
MSremj1		move.l	d4,a0
		move.l	d3,obj_blocknext(a0)
		move.l	d3,a0
		move.l	d4,obj_blockprev(a0)
MSremesc
		clr.l	obj_blocknext(a6)
		move.w	2(a2,d2.w*4),d3		;Testa se c'e' un altro oggetto nel nuovo blocco
		beq.s	MSnonbobj		; Se non c'e', salta
		lea	ObjectsPunListMinus4(a5),a0
		move.l	(a0,d3.w*4),a0		;a0=Pun. al primo oggetto sul blocco
		move.l	a0,obj_blocknext(a6)
		move.l	a6,obj_blockprev(a0)
MSnonbobj
		move.w	obj_number(a6),2(a2,d2.w*4)	;Scrive nella mappa il numero dell'oggetto alla nuova posizione
		move.w	d2,obj_mapoffset(a6)		;Memorizza nuovo offset nella mappa
		move.l	saveblpun(a5),obj_blockpun(a6)	;Scrive il pun. al nuovo blocco
		clr.l	obj_blockprev(a6)

MSnochgbl	move.w	d0,obj_x(a6)
		move.w	d1,obj_z(a6)
		move.w	d7,obj_y(a6)

			;*** Animazione frames
		move.l	obj_image(a6),a3
		move.w	obj_animcont(a6),d0
		add.w	animstep(a5),d0
		cmp.w	o_numframes(a3),d0	;Superato il numero di frame ?
		blt.s	MSnolfr			; Se no, salta
		clr.w	d0
MSnolfr		move.w	d0,obj_animcont(a6)	;Scrive nuovo cont. frame corrente


		move.l	obj_listnext(a6),d0
		bne	MSloop

MSout

AOout		move.w	repeatanim(a5),d0
		subq.w	#1,d0
		bgt	AOMainLoop

		rts






	;*** Rimuove il proiettile dal video

MSstop
		move.l	obj_listnext(a6),d3	;Se pun. next obj<>0
		bne.s	MSS2remnex		; salta
		move.l	obj_listprev(a6),d4	;Se pun. previous obj<>0
		bne.s	MSS2remnj1		; salta
		clr.l	ObjShots(a5)
		bra.s	MSS2remesc
MSS2remnj1	move.l	d4,a0
		clr.l	obj_listnext(a0)
		bra.s	MSS2remesc
MSS2remnex	move.l	obj_listprev(a6),d4	;Se pun. previous obj<>0
		bne.s	MSS2remj1		; salta
		move.l	d3,a0
		clr.l	obj_listprev(a0)
		move.l	a0,ObjShots(a5)
		bra.s	MSS2remesc
MSS2remj1	move.l	d4,a0
		move.l	d3,obj_listnext(a0)
		move.l	d3,a0
		move.l	d4,obj_listprev(a0)
MSS2remesc

		move.l	obj_image(a6),a3
		tst.b	o_param9(a3)		;Test se deve esplodere
		bpl.s	MSSexpl			; Se si, salta

		move.w	obj_mapoffset(a6),d6
		move.l	obj_blocknext(a6),d5	;Se pun. next obj<>0
		bne.s	MSSremnex		; salta
		move.l	obj_blockprev(a6),d4	;Se pun. previous obj<>0
		bne.s	MSSremnj1		; salta
		clr.w	2(a2,d6.w*4)		;Azzera nella mappa il numero dell'oggetto alla posizione precedente
		bra.s	MSSremesc
MSSremnj1	move.l	d4,a0
		clr.l	obj_blocknext(a0)
		bra.s	MSSremesc
MSSremnex	move.l	obj_blockprev(a6),d4	;Se pun. previous obj<>0
		bne.s	MSSremj1			; salta
		move.l	d5,a0
		clr.l	obj_blockprev(a0)
		move.w	obj_number(a0),2(a2,d6.w*4)
		bra.s	MSSremesc
MSSremj1	move.l	d4,a0
		move.l	d5,obj_blocknext(a0)
		move.l	d5,a0
		move.l	d4,obj_blockprev(a0)
MSSremesc
		move.l	ObjFree(a5),obj_listnext(a6)	;Inserisce oggetto nella lista oggetti liberi
		move.l	a6,ObjFree(a5)
		clr.l	obj_listprev(a6)
		clr.l	obj_blockprev(a6)
		clr.l	obj_blocknext(a6)
		bra.s	MSSout

MSSexpl
	;*** Inserisce oggetto nella lista delle esplosioni

		move.l	ObjExplosions(a5),a0
		move.l	a0,obj_listnext(a6)
		beq.s	MSSnopre
		move.l	a6,obj_listprev(a0)
MSSnopre	clr.l	obj_listprev(a6)
		move.l	a6,ObjExplosions(a5)

		clr.l	d0
		move.l	d0,obj_oldimage(a6)	;oldimage=0 perch non pu lasciare resti
		move.b	o_param9(a3),d0
		lea	ExplObj1(a5),a3
		move.l	(a3,d0.l*4),a3		;a3=pun. oggetto esplosione
		move.l	a3,obj_image(a6)
		move.b	o_objtype(a3),obj_type(a6)
		clr.w	obj_animcont(a6)
		move.w	o_radius(a3),obj_width(a6)

		move.w	obj_height(a6),d0
		move.w	o_height(a3),d1
		move.w	d1,obj_height(a6)
		sub.w	d1,d0
		asr.w	#1,d0
		add.w	obj_y(a6),d0
		move.w	d0,obj_y(a6)

;		move.w	obj_x(a6),d0
;		sub.w	PlayerX(a5),d0
;		muls.w	d0,d0
;		move.w	obj_z(a6),d1
;		sub.w	PlayerZ(a5),d1
;		muls.w	d1,d1
;		add.l	d0,d1
;		move.l	o_sound1(a3),a0
;		jsr	BufferedPlaySoundFX
	move.l	a6,a0
	moveq	#0,d0
	jsr	ObjBufferedPlaySoundFX

MSSout
		move.l	d3,d0
		bne	MSloop

		bra	AOout


;----------------------------------------------------------------------------
;Input:
;	a0 = pun. oggetto da far esplodere
;	a6 = pun. proiettile

DestroyEnemy

	;*** Calcola punteggio

		clr.l	d4
		move.l	obj_image(a0),a3
		move.w	o_param2(a3),d4		;d4=punteggio nemico
		add.l	d4,PlayerScore(a5)
		move.b	#1,PlayerScoreFL(a5)	;Segnala che  cambiato il punteggio

		move.l	obj_image(a6),a3
		tst.b	o_param9(a3)		;Test se deve esplodere
		bpl.s	DEexpl			; Se si, salta

		move.l	obj_image(a0),a3
		lea	o_frameslist(a3),a3	;a3=Pun. lista pun. ai frame
		move.l	(41<<2)(a3),d3
		cmp.l	(42<<2)(a3),d3		;Ultimo frame fire = primo frame caduta ?
		beq.s	DEexpl			; Se si, non c'e' animazione caduta e salta all'esplosione

	;*** Init animazione caduta

		move.b	#-3,obj_status(a0)	;Segnala che il nemico  stato ucciso e sta cadendo
		move.b	#8,obj_cont1(a0)	;Tempo di ritardo per animazione
		move.w	#42,obj_animcont(a0)	;Primo frame animazione caduta
		move.w	obj_heading(a6),obj_heading(a0)	;Direzione della caduta
		move.w	#5,obj_speed(a0)		;Velocit della caduta
		moveq	#2,d0			;Death sound
		jsr	ObjBufferedPlaySoundFX

		rts


	;*** Elimina oggetto dalla lista dei nemici
DEexpl
		move.l	obj_listnext(a0),d3	;Se pun. next obj<>0
		bne.s	DOSE2remnex		; salta
		move.l	obj_listprev(a0),d4	;Se pun. previous obj<>0
		bne.s	DOSE2remnj1		; salta
		clr.l	ObjEnemies(a5)
		bra.s	DOSE2remesc
DOSE2remnj1	move.l	d4,a3
		clr.l	obj_listnext(a3)
		bra.s	DOSE2remesc
DOSE2remnex	move.l	obj_listprev(a0),d4	;Se pun. previous obj<>0
		bne.s	DOSE2remj1		; salta
		move.l	d3,a3
		clr.l	obj_listprev(a3)
		move.l	a3,ObjEnemies(a5)
		bra.s	DOSE2remesc
DOSE2remj1	move.l	d4,a3
		move.l	d3,obj_listnext(a3)
		move.l	d3,a3
		move.l	d4,obj_listprev(a3)
DOSE2remesc

	;*** Inserisce oggetto nella lista delle esplosioni

		move.l	ObjExplosions(a5),a3
		move.l	a3,obj_listnext(a0)
		beq.s	DOIEnopre
		move.l	a0,obj_listprev(a3)
DOIEnopre	clr.l	obj_listprev(a0)
		move.l	a0,ObjExplosions(a5)

		move.l	obj_image(a0),a3
		move.l	a3,obj_oldimage(a0)
		move.w	o_param4(a3),d4
		lea	ExplObj1(a5),a3
		move.l	(a3,d4.w*4),a3
		move.l	a3,obj_image(a0)
		move.b	o_objtype(a3),obj_type(a0)
		clr.w	obj_animcont(a0)

		move.w	obj_height(a0),d3
		sub.w	o_height(a3),d3
		lsr.w	#1,d3
		add.w	obj_y(a0),d3
		move.w	d3,obj_y(a0)

		moveq	#0,d0
		jsr	ObjBufferedPlaySoundFX

		rts


;----------------------------------------------------------------------------
; Subroutines di controllo collisioni per i nemici

CTRL_OBJ_COLLISION	MACRO

		and.w	#GRID_AND_W,d4
		lsr.w	#BLOCK_SIZE_B,d3
		add.w	d4,d4
		or.w	d4,d3		;d3=offset nella mappa
		cmp.w	d2,d3		;Confronta con l'offset del centro dell'oggetto
		beq.s	CTexit\@	;Se uguale, non fa il test

		move.w	d3,d2
		move.w	(a2,d3.w*4),d3		;d3=num. blocco
		bmi.s	CTnogood\@		;Se num.blocco<0, ferma nemico
		lsl.w	#2,d3
		lea	(a4,d3.w*8),a0		;a0=pun. blocco
		move.w	d5,d4
		sub.w	bl_FloorHeight(a0),d4	;Calcola dislivello pavimento
		bmi.s	CTdisc\@		;Se dislivello in discesa, salta
		cmp.w	#24,d4
		bgt.s	CTnogood\@		;Se dislivello troppo grande, non va bene
		move.w	d6,d4
		cmp.w	bl_CeilHeight(a0),d6	;Verifica quale soffitto e' piu' basso
		blt.s	CTj1\@
		move.w	bl_CeilHeight(a0),d4
CTj1\@		sub.w	d5,d4			;Calcola dislivello tra il soffitto piu' basso e pavimento del nuovo blocco
		cmp.w	obj_height(a6),d4	;Test se ci passa 
		blt.s	CTnogood\@
		bra.s	CTexit\@		;Tutto ok
CTdisc\@	neg.w	d4
		cmp.w	#24,d4
		bgt.s	CTnogood\@		;Se dislivello troppo grande, non va bene
		move.w	d6,d4
		sub.w	bl_FloorHeight(a0),d4	;Calcola dislivello tra nuovo soffitto e pavimento attuale
		cmp.w	obj_height(a6),d4	;Test se ci passa 
		bgt.s	CTexit\@
CTnogood\@	clr.l	d0			;Se c'e' collisione, azzera d0
		IFNE	\1
		bset	#\1,obj_bmstatus(a6)	;Setta bit
		ENDC
		bra	MNctrlret		; ed esce dalla routine di ctrl
CTexit\@
		ENDM


CT0		move.w	obj_width(a6),d3
		move.w	d1,d4
		sub.w	d3,d4		;d4=z-width
		add.w	d0,d3		;d3=x+width
		CTRL_OBJ_COLLISION 0
		move.w	obj_width(a6),d3
		add.w	d0,d3		;d3=x+width
		move.w	d1,d4		;d4=z
		CTRL_OBJ_COLLISION 0
		move.w	obj_width(a6),d3
		move.w	d3,d4
		add.w	d0,d3		;d3=x+width
		add.w	d1,d4		;d4=z+width
		CTRL_OBJ_COLLISION 0
		bra	MNctrlret

CT1		move.w	obj_width(a6),d3
		add.w	d0,d3		;d3=x+width
		move.w	d1,d4		;d4=z
		CTRL_OBJ_COLLISION 5
		move.w	obj_width(a6),d4
		move.w	d0,d3		;d3=x
		add.w	d1,d4		;d4=z+width
		CTRL_OBJ_COLLISION 6
		move.w	obj_width(a6),d3
		move.w	d3,d4
		add.w	d0,d3		;d3=x+width
		add.w	d1,d4		;d4=z+width
		CTRL_OBJ_COLLISION 0
		bra	MNctrlret

CT2		move.w	obj_width(a6),d3
		move.w	d3,d4
		add.w	d0,d3		;d3=x+width
		add.w	d1,d4		;d4=z+width
		CTRL_OBJ_COLLISION 0
		move.w	obj_width(a6),d4
		move.w	d0,d3		;d3=x
		add.w	d1,d4		;d4=z+width
		CTRL_OBJ_COLLISION 0
		move.w	obj_width(a6),d4
		move.w	d0,d3
		sub.w	d4,d3		;d3=x-width
		add.w	d1,d4		;d4=z+width
		CTRL_OBJ_COLLISION 0
		bra	MNctrlret

CT3		move.w	obj_width(a6),d4
		move.w	d0,d3		;d3=x
		add.w	d1,d4		;d4=z+width
		CTRL_OBJ_COLLISION 6
		move.w	d0,d3
		sub.w	obj_width(a6),d3 ;d3=x-width
		move.w	d1,d4		 ;d4=z
		CTRL_OBJ_COLLISION 5
		move.w	obj_width(a6),d4
		move.w	d0,d3
		sub.w	d4,d3		;d3=x-width
		add.w	d1,d4		;d4=z+width
		CTRL_OBJ_COLLISION 0
		bra	MNctrlret

CT4		move.w	obj_width(a6),d4
		move.w	d0,d3
		sub.w	d4,d3		;d3=x-width
		add.w	d1,d4		;d4=z+width
		CTRL_OBJ_COLLISION 0
		move.w	d0,d3
		sub.w	obj_width(a6),d3 ;d3=x-width
		move.w	d1,d4		 ;d4=z
		CTRL_OBJ_COLLISION 0
		move.w	obj_width(a6),d4
		neg.w	d4
		move.w	d4,d3
		add.w	d0,d3		;d3=x-width
		add.w	d1,d4		;d4=z-width
		CTRL_OBJ_COLLISION 0
		bra	MNctrlret

CT5		move.w	d0,d3
		sub.w	obj_width(a6),d3 ;d3=x-width
		move.w	d1,d4		 ;d4=z
		CTRL_OBJ_COLLISION 5
		move.w	d1,d4
		move.w	d0,d3		 ;d3=x
		sub.w	obj_width(a6),d4 ;d4=z-width
		CTRL_OBJ_COLLISION 6
		move.w	obj_width(a6),d4
		neg.w	d4
		move.w	d4,d3
		add.w	d0,d3		;d3=x-width
		add.w	d1,d4		;d4=z-width
		CTRL_OBJ_COLLISION 0
		bra	MNctrlret

CT6		move.w	obj_width(a6),d4
		neg.w	d4
		move.w	d4,d3
		add.w	d0,d3		;d3=x-width
		add.w	d1,d4		;d4=z-width
		CTRL_OBJ_COLLISION 0
		move.w	d1,d4
		move.w	d0,d3		 ;d3=x
		sub.w	obj_width(a6),d4 ;d4=z-width
		CTRL_OBJ_COLLISION 0
		move.w	obj_width(a6),d3
		move.w	d1,d4
		sub.w	d3,d4		;d4=z-width
		add.w	d0,d3		;d3=x+width
		CTRL_OBJ_COLLISION 0
		bra	MNctrlret

CT7		move.w	d1,d4
		move.w	d0,d3		 ;d3=x
		sub.w	obj_width(a6),d4 ;d4=z-width
		CTRL_OBJ_COLLISION 6
		move.w	obj_width(a6),d3
		add.w	d0,d3		;d3=x+width
		move.w	d1,d4		;d4=z
		CTRL_OBJ_COLLISION 5
		move.w	obj_width(a6),d3
		move.w	d1,d4
		sub.w	d3,d4		;d4=z-width
		add.w	d0,d3		;d3=x+width
		CTRL_OBJ_COLLISION 0
		bra	MNctrlret


CollTestTable
		dc.l	CT0,CT1,CT2,CT3,CT4,CT5,CT6,CT7

;----------------------------------------------------------------------------
; Subroutines di controllo collisioni per i proiettili

CTRL_SHOT_COLLISION	MACRO

		and.w	#GRID_AND_W,d4
		lsr.w	#BLOCK_SIZE_B,d3
		add.w	d4,d4
		or.w	d4,d3		;d3=offset nella mappa
		cmp.w	d2,d3		;Confronta con l'offset del centro dell'oggetto
		beq.s	CTSexit\@	;Se uguale, non fa il test

		move.w	d3,d2
		move.w	(a2,d3.w*4),d3		;d3=num. blocco
		bmi	MSstop			;Se num.blocco<0, ferma proiettile
		lsl.w	#2,d3
		lea	(a4,d3.w*8),a0		;a0=pun. blocco

		move.w	bl_FloorHeight(a0),d3	;d3=Pavimento nuovo blocco
		cmp.w	d3,d5			;Test collisione con pavimento
		blt	MSstop
		move.w	bl_CeilHeight(a0),d3	;d3=Soffitto nuovo blocco
		sub.w	obj_height(a6),d3	;Somma altezza oggetto
		cmp.w	d3,d5			;Test collisione con soffitto
		bge	MSstop
CTSexit\@
		ENDM


CTS0		move.w	obj_width(a6),d3
		move.w	d1,d4
		sub.w	d3,d4		;d4=z-width
		add.w	d0,d3		;d3=x+width
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d3
		add.w	d0,d3		;d3=x+width
		move.w	d1,d4		;d4=z
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d3
		move.w	d3,d4
		add.w	d0,d3		;d3=x+width
		add.w	d1,d4		;d4=z+width
		CTRL_SHOT_COLLISION
		bra	MSctrlret

CTS1		move.w	obj_width(a6),d3
		add.w	d0,d3		;d3=x+width
		move.w	d1,d4		;d4=z
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d3
		move.w	d3,d4
		add.w	d0,d3		;d3=x+width
		add.w	d1,d4		;d4=z+width
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d4
		move.w	d0,d3		;d3=x
		add.w	d1,d4		;d4=z+width
		CTRL_SHOT_COLLISION
		bra	MSctrlret

CTS2		move.w	obj_width(a6),d3
		move.w	d3,d4
		add.w	d0,d3		;d3=x+width
		add.w	d1,d4		;d4=z+width
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d4
		move.w	d0,d3		;d3=x
		add.w	d1,d4		;d4=z+width
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d4
		move.w	d0,d3
		sub.w	d4,d3		;d3=x-width
		add.w	d1,d4		;d4=z+width
		CTRL_SHOT_COLLISION
		bra	MSctrlret

CTS3		move.w	obj_width(a6),d4
		move.w	d0,d3		;d3=x
		add.w	d1,d4		;d4=z+width
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d4
		move.w	d0,d3
		sub.w	d4,d3		;d3=x-width
		add.w	d1,d4		;d4=z+width
		CTRL_SHOT_COLLISION
		move.w	d0,d3
		sub.w	obj_width(a6),d3 ;d3=x-width
		move.w	d1,d4		 ;d4=z
		CTRL_SHOT_COLLISION
		bra	MSctrlret

CTS4		move.w	obj_width(a6),d4
		move.w	d0,d3
		sub.w	d4,d3		;d3=x-width
		add.w	d1,d4		;d4=z+width
		CTRL_SHOT_COLLISION
		move.w	d0,d3
		sub.w	obj_width(a6),d3 ;d3=x-width
		move.w	d1,d4		 ;d4=z
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d4
		neg.w	d4
		move.w	d4,d3
		add.w	d0,d3		;d3=x-width
		add.w	d1,d4		;d4=z-width
		CTRL_SHOT_COLLISION
		bra	MSctrlret

CTS5		move.w	d0,d3
		sub.w	obj_width(a6),d3 ;d3=x-width
		move.w	d1,d4		 ;d4=z
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d4
		neg.w	d4
		move.w	d4,d3
		add.w	d0,d3		;d3=x-width
		add.w	d1,d4		;d4=z-width
		CTRL_SHOT_COLLISION
		move.w	d1,d4
		move.w	d0,d3		 ;d3=x
		sub.w	obj_width(a6),d4 ;d4=z-width
		CTRL_SHOT_COLLISION
		bra	MSctrlret

CTS6		move.w	obj_width(a6),d4
		neg.w	d4
		move.w	d4,d3
		add.w	d0,d3		;d3=x-width
		add.w	d1,d4		;d4=z-width
		CTRL_SHOT_COLLISION
		move.w	d1,d4
		move.w	d0,d3		 ;d3=x
		sub.w	obj_width(a6),d4 ;d4=z-width
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d3
		move.w	d1,d4
		sub.w	d3,d4		;d4=z-width
		add.w	d0,d3		;d3=x+width
		CTRL_SHOT_COLLISION
		bra	MSctrlret

CTS7		move.w	d1,d4
		move.w	d0,d3		 ;d3=x
		sub.w	obj_width(a6),d4 ;d4=z-width
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d3
		move.w	d1,d4
		sub.w	d3,d4		;d4=z-width
		add.w	d0,d3		;d3=x+width
		CTRL_SHOT_COLLISION
		move.w	obj_width(a6),d3
		add.w	d0,d3		;d3=x+width
		move.w	d1,d4		;d4=z
		CTRL_SHOT_COLLISION
		bra	MSctrlret


CollTestTable2
		dc.l	CTS0,CTS1,CTS2,CTS3,CTS4,CTS5,CTS6,CTS7

CollTestOffsetTable
		dc.w	1-MAP_SIZE,1,1+MAP_SIZE,0,0,0,0,0
		dc.w	1,1+MAP_SIZE,MAP_SIZE,0,0,0,0,0
		dc.w	1+MAP_SIZE,MAP_SIZE,MAP_SIZE-1,0,0,0,0,0
		dc.w	MAP_SIZE,MAP_SIZE-1,-1,0,0,0,0,0
		dc.w	MAP_SIZE-1,-1,-MAP_SIZE-1,0,0,0,0,0
		dc.w	-1,-MAP_SIZE-1,-MAP_SIZE,0,0,0,0,0
		dc.w	-MAP_SIZE-1,-MAP_SIZE,1-MAP_SIZE,0,0,0,0,0
		dc.w	-MAP_SIZE,1-MAP_SIZE,1,0,0,0,0,0

;****************************************************************************

		xdef	DrawObjects
DrawObjects

		lea	RaycastObjects(a5),a0
		lea	ObjOrderList(pc),a3
		move.l	Blocks(a5),a4
		clr.l	d5			;d5=Pun. alla testa della lista di ordinamento degli oggetti

		move.l	(a0)+,d4		;d4.w=object number
		beq	DOout

DOloop1		move.l	(a0)+,a1		;a1=map pointer
		move.w	d4,(a1)			;Ripristina numero oggetto nella mappa
		lea	ObjectsPunListMinus4(a5),a2
		move.l	(a2,d4.w*4),a2		;a2=Pun. all'oggetto
DOloop1.2	move.l	obj_blockpun(a2),a1

		move.b	obj_type(a2),d0
		cmp.b	#4,d0
		beq.s	DOnomy
		cmp.b	#5,d0
		beq.s	DOnomy
		move.w	bl_FloorHeight(a1),obj_y(a2)
DOnomy
		move.l	a2,-(sp)		;Salva pun. all'oggetto

		move.w	obj_x(a2),d0
		move.w	obj_z(a2),d1
		sub.w	PlayerX(a5),d0
		sub.w	PlayerZ(a5),d1

		move.w	PlayerHeading(a5),d3

		lea	sintable,a1
		move.l	(SINTABLE_LEN.w,a1,d3.w*4),d6	;d6=cos*65536
		asr.l	#2,d6				;d6=cos*16384
		move.l	(a1,d3.w*4),d7			;d7=sin*65536
		asr.l	#2,d7				;d7=sin*16384
		move.l	d0,d3
		move.l	d1,d2
		muls.w	d6,d0		;d0=x*cos
		muls.w	d7,d1		;d1=z*sin
		add.l	d1,d0		;d0=x*cos + z*sin
;		ble.s	DOnextobj
		asr.l	#8,d0
		asr.l	#6,d0

		muls.w	d7,d3		;d3=x*sin
		muls.w	d6,d2		;d2=z*cos
		sub.l	d3,d2		;d2=z*cos - x*sin
		asr.l	#8,d2
		asr.l	#3,d2		;Lascia i 3 bit meno significativi per aumentare la precisione

		move.l	a3,d3		;Conserva a3 per l'ordinamento

		move.l	d0,(a3)+	;Mette la x nella lista
		move.l	d2,(a3)+	;Mette la z nella lista
		move.l	a2,(a3)+	;Mette il pun. all'oggetto nella lista
		clr.l	(a3)+		;Azzera puntatore al prossimo nodo

		move.l	d5,d2		;d5  il puntatore alla testa della lista
		beq.s	DOfirstins
		move.l	d2,a2
DOsort		move.l	d2,a1		;a1=Pun. al nodo
		cmp.l	(a1),d0		;Confronta le x
		bgt.s	DOins
		move.l	a1,a2		;a2=Pun. al nodo precedente
		move.l	12(a1),d2	;Prende pun. al nodo successivo
		bne.s	DOsort		;Se<>0 continua
		bra.s	DOnohins
DOins		move.l	a1,-4(a3)
		cmp.l	a1,a2		;Se Pun.nodo succ. e Pun.nodo prec. sono uguali, allora  un inserimento in testa
		bne.s	DOnohins
DOfirstins	move.l	d3,d5
		bra.s	DOnextobj
DOnohins	move.l	d3,12(a2)


DOnextobj	move.l	(sp)+,a2	;Recupera pun. all'oggetto
		move.l	obj_blocknext(a2),d0	;Legge pun. al prossimo oggetto sul blocco
		beq.s	DOnextobj1.2	;Se=0, non ce ne sono altri
		move.l	d0,a2
		bra	DOloop1.2

DOnextobj1.2	move.l	(a0)+,d4	;d4.w=object number
		bne	DOloop1


	;*****

		moveq	#4,d0
		move.l	pixel_type(a5),d1
		btst	#0,d1			;Test height of the pixel
		beq.s	DOl2j1
		moveq	#3,d0
DOl2j1		btst	#1,d1			;Test width of the pixel
		beq.s	DOl2j2
		addq.w	#1,d0
DOl2j2		move.l	d0,ptmul(a5)

		move.w	PlayerHeading(a5),d3
		add.w	#128,d3
		lsr.w	#8,d3
		and.w	#7,d3
		move.w	d3,plhdandi(a5)

		move.l	ChunkyBuffer(a5),ChunkyPointer(a5)	;Init pun. fake chunky
		move.l	d5,d0		;d0=Pun. alla testa della lista di ordinamento degli oggetti

DOloop2		move.l	d0,a3

		move.l	(a3)+,d0		;d0=x
		move.l	(a3)+,d4		;d4=z
		move.l	(a3)+,a4		;a4=pun. oggetto
		move.l	a3,-(sp)		;Salva a3 sullo stack

		swap	d0
		ble	DOnextobj2
		clr.w	d0
		divu.l	windowYratio(a5),d0
		ble	DOnextobj2

;	muls.w	#9,d4			;Aggiusta la z (ottimizzato dalle istruzioni seguenti)
;	asr.l	#3,d4
		move.l	d4,d5
		lsl.l	#3,d4
		add.l	d5,d4
		asr.l	#3,d4

		move.l	ptmul(a5),d5

		move.l	obj_image(a4),a2
		tst.b	o_animtype(a2)		;Testa tipo animazione
		bmi.s	DOAnimDirezionale
		cmp.b	#4,o_objtype(a2)	;Testa tipo oggetto
		bge.s	DOnoglobalanim
		move.l	o_currentframe(a2),a2	;a2=Pun. al frame corrente
		bra.s	DOAnimok
DOnoglobalanim
		move.w	obj_animcont(a4),d1
		move.l	o_frameslist(a2,d1.w*4),a2	;a2=Pun. frame
		bra.s	DOAnimok
DOAnimDirezionale
		tst.b	obj_status(a4)
		bpl.s	DOadnostop
		move.w	obj_animcont(a4),d1
		bra.s	DOadok
DOadnostop	move.w	obj_heading(a4),d1
		bset	#7,obj_bmstatus(a4)	;Segnala che il nemico e' in vista
		add.w	#128,d1
		lsr.w	#8,d1
		and.w	#7,d1			;d1=((angle+128)/256) & 7

		move.w	plhdandi(a5),d3

		addq.w	#6,d1
		sub.w	d3,d1
		and.w	#7,d1
		lsl.w	#4,d1
		add.w	obj_animcont(a4),d1
DOadok		move.l	o_frameslist(a2,d1.w*4),a2	;a2=Pun. frame
	IFNE	DEBUG
	cmp.l	#$400,a2	;DA ELIMINARE SE NON VIENE MAI PIU' ESEGUITO:
	bgt.s	quququ		;	UTILIZZATO SOLO PER
bellerr2			;	TESTARE UN BUG
	WAITDEBUG $aa,6		;
quququ
	ENDC
DOAnimok
		move.w	4(a2),d3
		asl.w	#3,d3
		ext.l	d3
		sub.l	d3,d4			;somma xoffset
		lsl.l	d5,d4			;d4=z*128
		divs.w	d0,d4			;d4=(z*128)/distance = x_a_video
		add.w	window_width2+2(a5),d4

		move.w	PlayerY(a5),d3
		sub.w	obj_y(a4),d3		;d3=PlayerY - y
		sub.w	6(a2),d3		;somma yoffset
		ext.l	d3
		lsl.l	#7,d3			;d3=y*128
		divs.w	d0,d3			;d3=(y*128)/distance = y_a_video
		add.w	window_height2+2(a5),d3

		clr.l	d7
		move.w	(a2)+,d7		;d7=width
		move.l	d7,d2
		lsl.l	d5,d7
		lsl.l	#3,d7
		divu.w	d0,d7			;d7=(width*128)/distance = width_a_video
		ble	DOnextobj2
		ext.l	d7

		swap	d2
		divu.l	d7,d2			;d2=width_reale / width_a_video

		clr.l	d1
		move.w	(a2)+,d1		;d1=height
		move.l	d1,d5
		lsl.l	#7,d1
		divu.w	d0,d1			;d1=(height*128)/distance = height_a_video
		ble	DOnextobj2
		sub.w	d1,d3			;d3=y_a_video - height_a_video
		add.w	LookHeight+2(a5),d3	;Somma altezza sguardo

		swap	d5
		ext.l	d1
		divu.l	d1,d5			;d5=height_reale / height_a_video
		move.l	d5,d1			;d1=passo y

		swap	d0
		clr.w	d0
		lsr.l	#7,d0
		move.l	d0,savedist(a5)

	;***** Illuminazione

;		add.l	d0,d0
		MULU64	windowYratio(a5),d5,d0,d1,d2,d3	;Aggiusta la distanza in base alle dimensioni della finestra
		move.l	obj_blockpun(a4),a4
		move.b	bl_Illumination(a4),d0
		extb.l	d0
		add.l	d0,d5
		move.l	GlobalLight(a5),d0
		tst.b	bl_Illumination+1(a4)	;Test flag nebbia
		lea	LightingTable(a5),a4	;a3=Pun. alla lighting table
		bpl.s	MFWnofog		;Se non c' nebbia, salta
		lea	8192(a4),a4		;Se c' nebbia, passa alla lighting table per la nebbia
		moveq	#0,d0			;Azzera global light
MFWnofog	add.l	d0,d5			;Somma global light
		bmi.s	MFWlitout
		cmp.w	#31,d5
		ble.s	MFWlitok
		lea	(31<<8)(a4),a4
		bra.s	MFWlitout
MFWlitok	lsl.l	#8,d5
		add.l	d5,a4
MFWlitout

	;***** Traccia oggetto

		tst.w	d4			;Test if xminclip
		bge.s	DOnoxminclip		;Se non clippa, salta
		add.w	d4,d7			;Aggiusta width
		ble	DOnextobj2		;Se width<=0, non traccia oggetto
		neg.w	d4
		ext.l	d4
		mulu.l	d2,d4			;passox * Numero pixel clippati
		swap	d4
		lea	(a2,d4.w*4),a2		;Aggiusta pun. alle colonne
		clr.l	d4
DOnoxminclip
		move.w	d4,d0
		add.w	d7,d0			;d0=x+width=num. colonna pi a destra
		sub.w	window_width+2(a5),d0	;Test if xmaxclip
		ble.s	DOnoxmaxclip		;Se non clippa, salta
		sub.w	d0,d7			;Aggiusta width oggetto
		ble	DOnextobj2		;Se width<=0, non traccia oggetto
DOnoxmaxclip
		lea	ObjVTable,a3
		lea	(a3,d4.w*4),a3		;a3=Pun. al pun. alla coda della vtable relativa alla prima colonna a sinistra dell'oggetto

		move.l	ChunkyPointer(a5),a6
		add.w	d4,a6			;a6=Pun. a video
		move.l	d3,-(sp)		;Salva sullo stack y iniziale

		move.l	source_width(a5),d5	;valore di somma per destinazione
		move.l	d7,-(sp)
		clr.l	d4
		swap	d2
DOdrawloopx	move.l	4(a2,d4.w*4),a0		;a0=Pun. colonna immagine

		move.l	(a3)+,a1		;a1=Pun. alla coda della vtable per la colonna corrente
		move.l	savedist(a5),d0

	IFNE	DEBUG
	tst.l	a1		;DA ELIMINARE SE NON VIENE MAI PIU' ESEGUITO:
	bne.s	qpqpqp		;	UTILIZZATO SOLO PER
	xdef	bellerr		;	TESTARE UN BUG
bellerr				;
	WAITDEBUG $a0,6		;
	ENDC
qpqpqp				;

		cmp.l	(a1)+,d0
		bgt	DOendcolumn
		lea	-(vtsize+4)(a1),a1
DOdistsearch	cmp.l	(a1)+,d0		;Ciclo per cercare yminclip e ymaxclip
		bgt.s	DOdistfound
		lea	-(vtsize+4)(a1),a1
		bra.s	DOdistsearch
DOdistfound
		move.l	vtsize(a1),d3		;d3.l=yminclip; d3.h=ymaxclip

;qpqp	move.l	#((100<<16)+1),d3	;d3.l=yminclip; d3.h=ymaxclip

DOdrawloopt	clr.l	d7
		move.b	(a0)+,d7		;d7=riga iniziale del trattino verticale
		bmi	DOendcolumn		;Se riga iniziale<0, allora  finita la colonna
		swap	d7
		divu.l	d1,d7
		add.w	6(sp),d7

		clr.l	d6
		move.b	(a0)+,d6		;d6=Numero pixel del trattino
		move.l	d6,d0
		neg.w	d0
		swap	d0
		add.l	d6,a0			;Posiziona a0 all'inizio del trattino successivo
		swap	d6
		divu.l	d1,d6

		cmp.w	d3,d7		;Test se yminclip
		bgt.s	DOnoyminclip	;Salta se non c' clipping
		move.w	d3,d5
		sub.w	d7,d5
		addq.w	#1,d5
		sub.w	d5,d6		;Corregge Num.pixel
		ble.s	DOdrawloopt
		ext.l	d5
		mulu.l	d1,d5
		add.l	d5,d0		;Corregge Start acc.
		move.w	d3,d7
		addq.w	#1,d7
DOnoyminclip
		move.l	Yoffset.w(a5,d7.w*4),a1
		add.l	a6,a1			;a1=Pun. a video

		swap	d3
		add.w	d6,d7
		sub.w	d3,d7		;Test se ymaxclip
		ble.s	DOnoymaxclip
		sub.w	d7,d6		;Corregge Num.pixel
		ble.s	DOdrawloopt
DOnoymaxclip
		swap	d3

		move.l	source_width(a5),d5	;valore di somma per destinazione

		clr.l	d7

		ror.l	#1,d6
		add.w	d1,d0
		swap	d0
		swap	d1
		dbra	d6,DOdrawloopy
		bra.s	DOdrawstop
		cnop	0,8
DOdrawloopy	move.b	(a0,d0.w),d7
		move.b	(a4,d7.w),(a1)
		addx.l	d1,d0
		adda.l	d5,a1
		move.b	(a0,d0.w),d7
		move.b	(a4,d7.w),(a1)
		addx.l	d1,d0
		adda.l	d5,a1
DOdrawin	dbra	d6,DOdrawloopy
DOdrawstop	swap	d1
		tst.l	d6
		bpl	DOdrawloopt
		move.b	(a0,d0.w),d7
		move.b	(a4,d7.w),(a1)
		bra	DOdrawloopt
DOendcolumn
		clr.l	d7
		addq.l	#1,a6
		add.l	d2,d4
		addx.w	d7,d4
		subq.l	#1,(sp)
		bgt	DOdrawloopx

		addq.l	#8,sp

DOnextobj2
		move.l	(sp)+,a3	;Recupera a3 dallo stack
		move.l	(a3)+,d0	;Prende pun. al prossimo nodo
		bne	DOloop2		;Se<>0, continua ciclo

DOout

		tst.b	ProgramState(a5)	;Gioco congelato?
		bmi.s	DOexit			; Se si, salta
		bsr	AnimateObjects
DOexit
		rts


;****************************************************************************
;*** Routine di gestione delle armi del player

		xdef	PlayerFire

PlayerFire
		tst.b	PlayerDeath(a5)	;Se player morto, non spara
		bne	PFnofire

		move.w	Fire(a5),d7	;Legge quante volte  stato premuto il fire
		beq	PFnofire	;Salta, se non  stato premuto
		move.l	PlayerWeaponPun(a5),d0
		beq.s	PFnofire	;Se pun. arma usata=0, esce
		move.l	d0,a4		;a4=pun. arma
		subq.w	#1,Fire(a5)
		tst.b	o_param8(a4)	;E' un lanciafiamme ?
		bne	PFflame		; Se si, salta
		move.w	PlayerActiWeapon(a5),d0
		lea	PlayerWeapons(a5),a0
		cmp.b	#2,(a0,d0.w)	;L'arma  boost-ata ?
		bne.s	PFfnoboost	; Se no, salta
		moveq	#-8,d6
		moveq	#0,d7
		move.l	d7,a6
		bsr	PlayerShot
		bne.s	PFnofire
		moveq	#8,d6
		moveq	#1,d7
		move.l	d7,a6
		bsr	PlayerShot
		bra.s	PFnofire
PFfnoboost	moveq	#0,d6
		moveq	#0,d7
		move.l	d6,a6
		bsr	PlayerShot
PFnofire
		rts


	;***** Gestione lanciafiamme

PFflame		move.w	WeaponOsc(a5),d6
		add.w	WeaponOscDir(a5),d6
		bmi.s	PFflm1
		cmp.w	#40,d6
		blt.s	PFflok
		neg.w	WeaponOscDir(a5)
		bra.s	PFflok
PFflm1		cmp.w	#-40,d6
		bgt.s	PFflok
		neg.w	WeaponOscDir(a5)
PFflok		move.w	d6,WeaponOsc(a5)
		moveq	#0,d7
		move.l	d7,a6
		bsr	PlayerShot
		bne.s	PFflstop		;Se non ha sparato. salta
		rts
PFflstop	move.l	o_sound1(a4),a0
		jsr	BufferedStopSoundFX	;Stop sound
		rts



;***** Spara un proiettile del player
;***** Richiede:
;*****		d6.w : Offset direzione (-an, 0, an)
;*****		d7.w : Se<>0, non suona
;***** 		a4   : Pun. arma usata
;*****		a6   : Se<>0, non sottrae energia al player
;***** Non modifica d6, d7, a4
;***** Restituisce flag Z a 0, se non spara

PlayerShot
		move.l	ObjFree(a5),d0
		beq	PFesci		;Esce se non ci sono oggetti liberi
		move.l	d0,a0		;a0=pun. nuovo proiettile

		tst.l	a6			;Test se deve sottrarre energia
		bne.s	PFnoergloss
		move.w	PlayerEnergy(a5),d1
		sub.w	o_param3(a4),d1		;Decrementa energia player
		bmi	PFesci2			;Se<0, non spara
		move.w	d1,PlayerEnergy(a5)
		move.b	#1,PlayerEnergyFL(a5)	;Segnala che  cambiata l'energia
PFnoergloss
		move.l	obj_listnext(a0),ObjFree(a5)	;Aggiorna lista oggetti liberi

		move.l	ObjShots(a5),a1
		move.l	a1,obj_listnext(a0)	;Aggiorna lista proiettili
		beq.s	PFnopre
		move.l	a0,obj_listprev(a1)
PFnopre		clr.l	obj_listprev(a0)
		move.l	a0,ObjShots(a5)

		move.w	PlayerHeading(a5),d4
		add.w	d6,d4
		and.w	#2047,d4
		move.w	d4,obj_heading(a0)

		lea	sintable,a1
		move.l	(COSTABLE_OFFSET.w,a1,d4.w*4),d0	;d0=cos
		move.l	(a1,d4.w*4),d1				;d1=sin
		move.l	d0,d2
		move.l	d1,d3
		moveq	#16,d5
		muls.l	d5,d0
		muls.l	d5,d1
		swap	d0			;Elimina parte decimale
		swap	d1
		add.w	PlayerX(a5),d0		;Somma alla posiz. precedente
		add.w	PlayerZ(a5),d1

		asr.l	#2,d2
		asr.l	#2,d3
		move.w	d2,obj_dirx(a0)
		move.w	d3,obj_dirz(a0)

		move.w	d0,obj_x(a0)
		move.w	d1,obj_z(a0)

		move.w	PlayerX(a5),obj_x0(a0)
		move.w	PlayerZ(a5),obj_z0(a0)
		move.w	d5,obj_distance(a0)

		move.l	Map(a5),a1
		and.l	#GRID_AND_W,d0
		and.l	#GRID_AND_W,d1
		lsr.w	#BLOCK_SIZE_B,d0
		add.w	d1,d1
		or.w	d1,d0			;d0=offset nella mappa
		move.w	d0,obj_mapoffset(a0)

		lea	2(a1,d0.w*4),a3		;a3=pun. nella mappa degli oggetti
		move.w	(a3),d1			;Test se c' gi un oggetto sul blocco
		beq.s	PFnoblkobj		; Se no, salta
		lea	ObjectsPunListMinus4(a5),a2
		move.l	(a2,d1.w*4),a2		;a2=Pun. al primo oggetto sul blocco
		clr.l	obj_blockprev(a0)
		move.l	a2,obj_blocknext(a0)
		move.l	a0,obj_blockprev(a2)
PFnoblkobj	move.w	obj_number(a0),(a3)	;Scrive nella mappa il numero dell'oggetto

		clr.l	d1
		move.w	(a1,d0.w*4),d1		;d1=Num. blocco su cui si trova l'oggetto
		lsl.l	#5,d1
		move.l	Blocks(a5),a2
		lea	(a2,d1.l),a3		;a3=Pun. al blocco
		move.l	a3,obj_blockpun(a0)

		move.l	CPlayerBlockPun(a5),a3
		clr.w	d0
		move.b	o_param12(a4),d0	;Y offset
		add.w	bl_FloorHeight(a3),d0
		move.w	d0,obj_y(a0)
		move.w	d0,obj_y0(a0)

		clr.w	obj_animcont(a0)

		move.l	a4,obj_image(a0)
		move.w	o_radius(a4),obj_width(a0)
		move.w	o_height(a4),obj_height(a0)
		move.b	o_objtype(a4),obj_type(a0)
		move.b	o_param1+1(a4),obj_power(a0)
		move.w	PlayerSpeed(a5),d0
		bpl.s	PFnomipsp
		moveq	#0,d0
PFnomipsp	lsr.w	#1,d0
		add.w	o_param2(a4),d0
		move.w	d0,obj_speed(a0)
		move.b	o_param5(a4),obj_accel(a0)
		move.b	o_param6(a4),obj_maxspeed(a0)

		move.l	LookHeightNum(a5),d0
;		muls.w	#6500,d0		;if step=24
;		muls.w	#1625,d0		;if step=6
		lsl.w	#8,d0			;if step=1
		move.w	d0,obj_hheading(a0)

		clr.b	obj_subtype(a0)		;Segnala che  un proiettile del player

		tst.w	d7
		bne.s	PFnosound
		move.l	o_sound1(a4),a0
		moveq	#0,d1
		jsr	BufferedPlaySoundFX
PFnosound
		clr.l	d0
		rts

PFesci2		move.l	GlobalSound6(a5),a0	;Suono arma scarica
		moveq	#0,d1
		jsr	BufferedPlaySoundFX

PFesci		moveq	#1,d0
		rts

;****************************************************************************
;*** Routine di gestione delle armi dei nemici
;*** Spara un proiettile per l'oggetto nemico puntato da a6

EnemiesFire	movem.l	d0-d7/a0-a4,-(sp)

		move.b	obj_gun(a6),d0
		beq	EFesci

		move.l	ObjFree(a5),d0
		beq	EFesci		;Esce se non ci sono oggetti liberi
		move.l	d0,a0		;a0=pun. nuovo proiettile

		move.w	PlayerX(a5),d0
		sub.w	obj_x(a6),d0		;d0=x
		move.w	PlayerZ(a5),d2
		sub.w	obj_z(a6),d2		;d2=z
		move.w	d0,d6			;d6.h=x
		swap	d6
		move.w	d2,d6			;d6.l=z
		move.w	d2,d7			;d7=z
		muls.w	d0,d0
		muls.w	d2,d2
		add.l	d0,d2			;d2=x^2 + z^2
		beq	EFesci
		SQRT				;Calcola radice quadrata
		move.l	d0,d4			;Salva la distanza in d4 per usarla dopo
		swap	d7
		clr.w	d7
		divs.l	d0,d7			;d7=sin = z / Sqr(x^2 + z^2)
		bpl.s	EFposz
		neg.l	d7
EFposz		move.l	d7,d0			;d0=sin
		lsl.l	#8,d7
		add.l	d7,d7
		swap	d7
		lea	arcsintable(pc),a3
		move.w	(a3,d7.w*2),d2		;Legge dalla tabella arcsin

	;*** Cerca nella tabella del sin un valore
	;*** piu' preciso di quello letto nella tabella
	;*** dell'arcsin
		lea	sintable(pc),a3
		lea	(a3,d2.w*4),a3
		move.l	(a3),d1			;Legge valore del sin nell'angolo letto dalla tabella arcsin
		sub.l	d0,d1			;Il segno della differenza ci dice se cercare a destra o a sinistra
		bpl.s	EFsrcleft
		addq.l	#4,a3
EFsrcright	move.l	(a3)+,d1
		sub.l	d0,d1
		bpl.s	EFsrcout
		addq.l	#1,d2
		bra.s	EFsrcright
EFsrcleft	move.l	-(a3),d1
		sub.l	d0,d1
		bmi.s	EFsrcout
		addq.l	#1,d2
		bra.s	EFsrcleft
EFsrcout
	;*** A questo punto d2 contiene il valore dell'angolo
	;*** tra 0 e 512 (0 e 90 gradi). Ora, in base al segno di x e z
	;*** calcola il valore effettivo dell'angolo, cioe'
	;*** tra 0 e 2048 (0 e 360 gradi).
		tst.w	d6
		bpl.s	EFasinp1
		swap	d6
		tst.w	d6
		bpl.s	EFasinm1p2
		add.w	#1024,d2
		bra.s	EFasinp1p2
EFasinm1p2	sub.w	#2048,d2
		neg.w	d2
		bra.s	EFasinp1p2
EFasinp1	swap	d6
		tst.w	d6
		bpl.s	EFasinp1p2
		sub.w	#1024,d2
		neg.w	d2
EFasinp1p2	and.w	#2047,d2

	;*** Calcola posizione iniziale del proiettile

		lea	sintable(pc),a3
		move.w	d2,obj_heading(a0)
		move.l	(COSTABLE_OFFSET.w,a3,d2.w*4),d0	;d0=cos
		move.l	(a3,d2.w*4),d1				;d1=sin

		moveq	#16,d5
		muls.l	d5,d0
		muls.l	d5,d1
		swap	d0			;Elimina parte decimale
		swap	d1
		add.w	obj_x(a6),d0		;Somma alla posiz. precedente
		add.w	obj_z(a6),d1

		move.w	d0,obj_x(a0)
		move.w	d1,obj_z(a0)

		move.w	obj_x(a6),obj_x0(a0)
		move.w	obj_z(a6),obj_z0(a0)
		move.w	d5,obj_distance(a0)

		and.l	#GRID_AND_W,d0
		and.l	#GRID_AND_W,d1
		lsr.w	#BLOCK_SIZE_B,d0
		add.w	d1,d1
		or.w	d1,d0			;d0=offset nella mappa
		move.w	d0,obj_mapoffset(a0)

		move.l	obj_image(a6),a3
		clr.w	d5
		move.b	o_param12(a3),d5	;y offset
		move.l	obj_blockpun(a6),a3
		add.w	bl_FloorHeight(a3),d5
		move.w	d5,obj_y(a0)		;d5=y iniziale
		move.w	d5,obj_y0(a0)

	;*** Controlla collisioni con muri.
	;*** Se c'e' collisione non spara

		move.w	(a2,d0.w*4),d1		;d1=Num. blocco su cui si trova l'oggetto
		bmi	EFesci			;Se num.blocco<0, ferma proiettile
		lsl.l	#2,d1
		lea	(a4,d1.w*8),a3		;a3=Pun. al blocco
		move.l	a3,obj_blockpun(a0)

		move.w	bl_FloorHeight(a3),d1	;d1=Pavimento nuovo blocco
		cmp.w	d1,d5			;Test collisione con pavimento
		blt	EFesci
		move.w	bl_CeilHeight(a3),d1	;d3=Soffitto nuovo blocco
		sub.w	obj_height(a0),d1	;Somma altezza oggetto
		cmp.w	d1,d5			;Test collisione con soffitto
		bge	EFesci

	;*** Sottrae oggetto alla lista oggetti liberi
	;*** e lo aggiunge alla lista dei proiettili

		move.l	obj_listnext(a0),ObjFree(a5)	;Aggiorna lista oggetti liberi

		move.l	ObjShots(a5),a1
		move.l	a1,obj_listnext(a0)	;Aggiorna lista proiettili
		beq.s	EFnopre
		move.l	a0,obj_listprev(a1)
EFnopre		clr.l	obj_listprev(a0)
		move.l	a0,ObjShots(a5)


	;*** Aggiunge oggetto alla lista del blocco

		lea	2(a2,d0.w*4),a3		;a3=pun. nella mappa degli oggetti
		move.w	(a3),d1			;Test se c' gi un oggetto sul blocco
		beq.s	EFnoblkobj		; Se no, salta
		lea	ObjectsPunListMinus4(a5),a1
		move.l	(a1,d1.w*4),a1		;a1=Pun. al primo oggetto sul blocco
		clr.l	obj_blockprev(a0)
		move.l	a1,obj_blocknext(a0)
		move.l	a0,obj_blockprev(a1)
EFnoblkobj	move.w	obj_number(a0),(a3)	;Scrive nella mappa il numero dell'oggetto

		clr.w	obj_animcont(a0)

		clr.w	d0
		move.b	obj_gun(a6),d0
		lea	GunObj1(a5),a3
		move.l	(a3,d0.w*4),a3
		move.l	a3,obj_image(a0)
		move.w	o_radius(a3),obj_width(a0)
		move.w	o_height(a3),obj_height(a0)
		move.b	o_objtype(a3),obj_type(a0)
		move.b	o_param1+1(a3),obj_power(a0)
		move.w	obj_speed(a6),d0
		lsr.w	#1,d0
		add.w	o_param2(a3),d0
		move.w	d0,obj_speed(a0)
		move.b	o_param5(a3),obj_accel(a0)
		move.b	o_param6(a3),obj_maxspeed(a0)

		move.w	PlayerY(a5),d0
		sub.w	obj_y(a6),d0
		sub.w	#PLAYER_EYES_HEIGHT,d0
		move.w	d0,d1
		swap	d0
		clr.w	d0
		asr.l	#1,d0
		divs.w	d4,d0
		bvc.s	EFnoovf
		move.w	#32767,d0
		tst.w	d1
		bpl.s	EFnoovf
		neg.w	d0
EFnoovf		move.w	d0,obj_hheading(a0)

;		clr.w	obj_hheading(a0)

		move.b	#1,obj_subtype(a0)	;Segnala che  un proiettile nemico

		moveq	#0,d0
		jsr	ObjBufferedPlaySoundFX

EFesci
EFout
		movem.l	(sp)+,d0-d7/a0-a4
		rts

;****************************************************************************
;Decide la direzione dell'oggetto nemico puntato da a6
; e ne gestisce le varie animazioni (caduta, esplosione, fire, etc.)
;Non modificare d7, a1, a2, a4, a5, a6

ChooseEnemyDir
		lea	CEDpunlist(pc),a0
		move.b	obj_status(a6),d2
		ext.w	d2
		move.l	(a0,d2.w*4),a0
		jmp	(a0)


	;*** Status=-3 : Animazione caduta
CEDcaduta
		cmp.w	#44,obj_animcont(a6)	;Ultimo frame caduta ?
		beq.s	CEDcadutaend		; Se si, fine animazione
		move.l	obj_image(a6),a3
		move.w	obj_animcont(a6),d3
		lea	o_frameslist(a3,d3.w*4),a3
		move.l	(a3)+,d3
		cmp.l	(a3),d3			;Frame attuale = nuovo frame ?
		beq.s	CEDcadutaend		; Se si, fine animazione
		move.b	#8,obj_cont1(a6)
		addq.w	#1,obj_animcont(a6)
		rts
CEDcadutaend	move.w	#129,obj_animcont(a6)	;Frame nemico a terra
		move.b	#10,obj_type(a6)	;Segnala che si tratta dei resti di un nemico
			;*** Elimina oggetto dalla lista dei nemici
		move.l	obj_listnext(a6),d3	;Se pun. next obj<>0
		bne.s	CEDCELremnex		; salta
		move.l	obj_listprev(a6),d4	;Se pun. previous obj<>0
		bne.s	CEDCELremnj1		; salta
		clr.l	ObjEnemies(a5)
		bra.s	CEDCELremesc
CEDCELremnj1	move.l	d4,a3
		clr.l	obj_listnext(a3)
		bra.s	CEDCELremesc
CEDCELremnex	move.l	obj_listprev(a6),d4	;Se pun. previous obj<>0
		bne.s	CEDCELremj1		; salta
		move.l	d3,a3
		clr.l	obj_listprev(a3)
		move.l	a3,ObjEnemies(a5)
		bra.s	CEDCELremesc
CEDCELremj1	move.l	d4,a3
		move.l	d3,obj_listnext(a3)
		move.l	d3,a3
		move.l	d4,obj_listprev(a3)
CEDCELremesc
			;*** Inserisce oggetto nella lista dei Things
		move.l	ObjThings(a5),a3
		move.l	a3,obj_listnext(a6)
		beq.s	CEDCITnopre
		move.l	a6,obj_listprev(a3)
CEDCITnopre	clr.l	obj_listprev(a6)
		move.l	a6,ObjThings(a5)

		;*** Test se i resti rimangono su una porta
		move.l	obj_blockpun(a6),a3	;a3=Pun. blocco
		moveq	#0,d3
		move.b	bl_Trigger(a3),d3	;Il blocco corrente  soggetto ad un trigger ?
		beq.s	CEDCELnotrig		; Se no, salta
		lea	TriggerBlockListPun+6(a5),a3
		move.w	(a3,d3.l*8),d4		;Legge comando precedente
		and.w	#$7fff,d4		;Preserva bit alto
		or.w	obj_number(a6),d4	;Inserisce numero oggetto
		move.w	d4,(a3,d3.l*8)		;Segnala alle routine di animazione che i resti sono su un blocco soggetto ad un trigger
CEDCELnotrig
		rts



	;*** Status=-1 : Animazione fire
CEDfire
		bsr	EnemiesFire
		move.b	obj_enemyspeed(a6),obj_speed+1(a6)
		moveq	#2,d1
		bsr	Rnd
		move.b	d0,obj_status(a6)
		beq.s	CEDfirej1
		move.w	#$0202,obj_cont1(a6)
		bra	CEDwalkanim
CEDfirej1	move.w	#$0204,obj_cont1(a6)
		bra	CEDwalkanim



	;*** Status=0 : Player seek
CEDseek
		move.b	obj_enemyspeed(a6),obj_speed+1(a6)
		move.b	#15,obj_cont1(a6)
		subq.b	#1,obj_cont2(a6)	;Decrementa contatore
		bgt.s	CEDseekok
		move.b	#2,obj_cont2(a6)
		move.b	#1,obj_status(a6)
		bra.s	CEDrandomok
CEDseekok
		move.w	obj_heading(a6),d4
		move.w	PlayerX(a5),d0
		move.w	PlayerZ(a5),d1
		sub.w	obj_x(a6),d0
		sub.w	obj_z(a6),d1
		move.w	d4,d2
		lsr.w	#8,d2
		move.l	(EPangleTable.w,pc,d2.w*4),a0
		jmp	(a0)			;Salta alla routine di calcolo
CEDseekret
		beq.s	CEDseekout
		blt.s	CEDseekleft
		add.w	#256,d4
		and.w	#2047,d4
		move.w	d4,obj_heading(a6)
		bra.s	CEDseekout
CEDseekleft	sub.w	#256,d4
		and.w	#2047,d4
		move.w	d4,obj_heading(a6)
CEDseekout	rts



	;*** Status=1 : Move random
CEDrandom
		move.b	obj_enemyspeed(a6),obj_speed+1(a6)
		move.b	#15,obj_cont1(a6)
		subq.b	#1,obj_cont2(a6)	;Decrementa contatore
		bgt.s	CEDrandomok
		move.b	#5,obj_cont2(a6)
		move.b	#0,obj_status(a6)
		bra.s	CEDseekok
CEDrandomok
		move.w	obj_heading(a6),d4
		move.w	#32767,d1
		bsr	Rnd
		cmp.w	#24576,d0
		ble.s	CEDrandomout
		cmp.w	#28672,d0
		bgt.s	MNrandomj2
		sub.w	#256,d4
		and.w	#2047,d4
		move.w	d4,obj_heading(a6)
		bra.s	CEDrandomout
MNrandomj2	add.w	#256,d4
		and.w	#2047,d4
		move.w	d4,obj_heading(a6)
CEDrandomout	rts




	;*** Status=2 : Sceglie nuova direzione in caso di collisione
	;***		avvenuta mentre status=0
CEDnewdir1
		move.w	obj_heading(a6),d4
		move.b	obj_rotdir(a6),d0
		bne.s	MNndobbl
		clr.l	d0
		btst	#5,obj_bmstatus(a6)
		bne.s	CEDndst5
		move.w	PlayerX(a5),d0
		sub.w	obj_x(a6),d0
CEDndst5	clr.l	d1
		btst	#6,obj_bmstatus(a6)
		bne.s	CEDndst6
		move.w	PlayerZ(a5),d1
		sub.w	obj_z(a6),d1
CEDndst6	lea	NewDirTable(pc),a0
		move.w	d4,d2
		lsr.w	#8,d2
		move.l	(a0,d2.w*4),a0
		jmp	(a0)
MNndret		bmi.s	MNndmin
		moveq	#1,d0
		bra.s	MNndgr
MNndmin		moveq	#-1,d0
MNndgr		move.b	d0,obj_rotdir(a6)
MNndobbl	lsl.w	#8,d0
		add.w	d4,d0
		and.w	#2047,d0
		move.w	d0,obj_heading(a6)
		move.w	#$2f05,obj_cont1(a6)
		clr.b	obj_status(a6)
		move.b	obj_enemyspeed(a6),obj_speed+1(a6)
		rts



	;*** Status=3 : Sceglie nuova direzione in caso di collisione
	;***		avvenuta mentre status=1
CEDnewdir2
		move.b	obj_rotdir(a6),d2
		bne.s	MNndobbl2
		moveq	#1,d2
		moveq	#2,d1
		bsr	Rnd
		tst.w	d0
		beq.s	MNgr
		moveq	#-1,d2
MNgr		move.b	d2,obj_rotdir(a6)
MNndobbl2	move.w	obj_heading(a6),d4
		lsl.w	#8,d2
		add.w	d2,d4
		and.w	#2047,d4
		move.w	d4,obj_heading(a6)
		move.w	#$0f03,obj_cont1(a6)
		move.b	#1,obj_status(a6)
		move.b	obj_enemyspeed(a6),obj_speed+1(a6)
		rts



	;*** Status=4 : Prepare to fire
CEDprepfire
		subq.b	#1,obj_cont2(a6)	;Decrementa contatore
		ble.s	CEDgofire
		move.w	obj_heading(a6),d4	;d4=obj_heading serve alla routine CEDseekret
		move.w	PlayerX(a5),d0
		move.w	PlayerZ(a5),d1
		sub.w	obj_x(a6),d0
		sub.w	obj_z(a6),d1
		move.w	d4,d3
		lsr.w	#8,d3
		move.l	(ProdScalTable.w,pc,d3.w*4),a0
		jmp	(a0)			;Salta alla routine di calcolo
CEDprscret
		bmi.s	CEDpsmin
		move.b	#1,obj_cont2(a6)
CEDpsmin	move.b	#3,obj_cont1(a6)
		move.l	(EPangleTable.w,pc,d3.w*4),a0
		jmp	(a0)			;Salta alla routine di calcolo

CEDgofire	btst	#0,obj_subtype(a6)	;Il nemico deve fermarsi quando spara ?
		bne.s	CEDprfnostop		; Se no, salta
		move.w	#40,obj_animcont(a6)
		move.w	#$0a01,obj_cont1(a6)
		move.b	#-1,obj_status(a6)
		clr.w	obj_speed(a6)
		rts

CEDprfnostop	move.w	#$0101,obj_cont1(a6)
		move.b	#-1,obj_status(a6)
		rts




	;*** Status=5 : Animazione colpito
CEDcolpito
		moveq	#2,d1
		bsr	Rnd
		move.b	d0,obj_status(a6)
		beq.s	CEDcolpitoj1
		move.w	#$0102,obj_cont1(a6)
		bra	CEDwalkanim
CEDcolpitoj1	move.w	#$0104,obj_cont1(a6)
		bra	CEDwalkanim




	;*** Status=6 : Sta addosso al player
CEDnearplayer
		bsr	CEDseekok
		move.w	#$0f05,obj_cont1(a6)
		clr.b	obj_status(a6)
		move.b	obj_enemyspeed(a6),obj_speed+1(a6)
		rts


;-----

;***** Routine animazione frame nemici

CEDwalkanim
		WALKANIM d0,a6
		rts		

;----------------------------------------------------------------

		dc.l	CEDcaduta	;Status=-3 : cade perch ucciso
		dc.l	0		;Status=-2 : nessuna azione
		dc.l	CEDfire		;Status=-1 : spara
CEDpunlist	dc.l	CEDseek		;Status=0  : cerca il player
		dc.l	CEDrandom	;Status=1  : si muove in maniera random
		dc.l	CEDnewdir1	;Status=2  : dopo una collisione sceglie nuova direzione cercando il player
		dc.l	CEDnewdir2	;Status=3  : dopo una collisione sceglie nuova direzione in maniera random
		dc.l	CEDprepfire	;Status=4  : si prepara a sparare
		dc.l	CEDcolpito	;Status=5  : colpito dal player
		dc.l	CEDnearplayer	;Status=6  : dopo una collisione col player sceglie nuova direzione cercando di stargli addosso


;***** Serie di routine per il calcolo del seek (nemico che cerca il player)

EPT0		move.w	d1,d2
		bra	CEDseekret

EPT1		move.w	d1,d2
		sub.w	d0,d2
		bra	CEDseekret

EPT2		move.w	d0,d2
		neg.w	d2
		bra	CEDseekret

EPT3		move.w	d1,d2
		add.w	d0,d2
		neg.w	d2
		bra	CEDseekret

EPT4		move.w	d1,d2
		neg.w	d2
		bra	CEDseekret

EPT5		move.w	d0,d2
		sub.w	d1,d2
		bra	CEDseekret

EPT6		move.w	d0,d2
		bra	CEDseekret

EPT7		move.w	d1,d2
		add.w	d0,d2
		bra	CEDseekret


EPangleTable	dc.l	EPT0,EPT1,EPT2,EPT3,EPT4,EPT5,EPT6,EPT7

;****************************************************************************
;*** Serie di routine per il calcolo della nuova direzione del
;*** nemico, se questo ha urtato un ostacolo
;*** Richiede:
;***	d0 = PlayerX - obj_x
;***	d1 = PlayerZ - obj_z

NDT0		move.w	d1,d2
		bra	MNndret

NDT1		move.w	d1,d2
		sub.w	d0,d2
		bra	MNndret

NDT2		move.w	d0,d2
		neg.w	d2
		bra	MNndret

NDT3		move.w	d1,d2
		add.w	d0,d2
		neg.w	d2
		bra	MNndret

NDT4		move.w	d1,d2
		neg.w	d2
		bra	MNndret

NDT5		move.w	d0,d2
		sub.w	d1,d2
		bra	MNndret

NDT6		move.w	d0,d2
		bra	MNndret

NDT7		move.w	d1,d2
		add.w	d0,d2
		bra	MNndret



NewDirTable	dc.l	NDT0,NDT1,NDT2,NDT3,NDT4,NDT5,NDT6,NDT7

;****************************************************************************
;* Serie di routine per il calcolo del prodotto scalare tra
;* il vettore direzione del nemico e il vettore differenza tra
;* la posizione del player e quella del nemico.
;* Utilizzata per controllare se il nemico  ruotato verso il player.
;* Richiede:
;*	d0 = PlayerX - obj_x
;*	d1 = PlayerZ - obj_z


PST0		move.w	d0,d2		;d2=x
		bra	CEDprscret

PST1		move.w	d0,d2
		add.w	d1,d2		;d2=x+z
		bra	CEDprscret

PST2		move.w	d1,d2		;d2=z
		bra	CEDprscret

PST3		move.w	d1,d2
		sub.w	d0,d2		;d2=-x+z
		bra	CEDprscret

PST4		move.w	d0,d2
		neg.w	d2		;d2=-x
		bra	CEDprscret

PST5		move.w	d0,d2
		add.w	d1,d2
		neg.w	d2		;d2=-x-z
		bra	CEDprscret

PST6		move.w	d1,d2
		neg.w	d2		;d2=-z
		bra	CEDprscret

PST7		move.w	d0,d2
		sub.w	d1,d2		;d2=x-z
		bra	CEDprscret


ProdScalTable	dc.l	PST0,PST1,PST2,PST3,PST4,PST5,PST6,PST7

;****************************************************************************
;* Rimuove i resti del nemico di codice d0 dalla mappa

		xdef	RemoveRemains

RemoveRemains	movem.l	d2-d4/a0-a2,-(sp)

		lea	ObjectsPunListMinus4(a5),a0
		move.l	(a0,d0.w*4),a0		;a0=Pun. all'oggetto

		;*** Elimina oggetto dallo schermo
		move.l	Map(a5),a2		;a2=Pun. mappa
		move.w	obj_mapoffset(a0),d2
		move.l	obj_blocknext(a0),d3	;Se pun. next obj<>0
		bne.s	RRremnex		; salta
		move.l	obj_blockprev(a0),d4	;Se pun. previous obj<>0
		bne.s	RRremnj1		; salta
		clr.w	2(a2,d2.w*4)		;Azzera nella mappa il numero dell'oggetto alla posizione precedente
		bra.s	RRremesc
RRremnj1	move.l	d4,a1
		clr.l	obj_blocknext(a1)
		bra.s	RRremesc
RRremnex	move.l	obj_blockprev(a0),d4	;Se pun. previous obj<>0
		bne.s	RRremj1			; salta
		move.l	d3,a1
		clr.l	obj_blockprev(a1)
		move.w	obj_number(a1),2(a2,d2.w*4)
		bra.s	RRremesc
RRremj1		move.l	d4,a1
		move.l	d3,obj_blocknext(a1)
		move.l	d3,a1
		move.l	d4,obj_blockprev(a1)
RRremesc
		;*** Elimina oggetto dalla lista Things
		move.l	obj_listnext(a0),d3	;Se pun. next obj<>0
		bne.s	RR2remnex		; salta
		move.l	obj_listprev(a0),d4	;Se pun. previous obj<>0
		bne.s	RR2remnj1		; salta
		clr.l	ObjThings(a5)
		bra.s	RR2remesc
RR2remnj1	move.l	d4,a1
		clr.l	obj_listnext(a1)
		bra.s	RR2remesc
RR2remnex	move.l	obj_listprev(a0),d4	;Se pun. previous obj<>0
		bne.s	RR2remj1		; salta
		move.l	d3,a1
		clr.l	obj_listprev(a1)
		move.l	a1,ObjThings(a5)
		bra.s	RR2remesc
RR2remj1	move.l	d4,a1
		move.l	d3,obj_listnext(a1)
		move.l	d3,a1
		move.l	d4,obj_listprev(a1)
RR2remesc
		move.l	ObjFree(a5),obj_listnext(a0)	;Inserisce oggetto nella lista oggetti liberi
		move.l	a0,ObjFree(a5)

		clr.l	obj_listprev(a0)
		clr.l	obj_blockprev(a0)
		clr.l	obj_blocknext(a0)

		movem.l	(sp)+,d2-d4/a0-a2
		rts

;****************************************************************************
;Numeri casuali tra 0 e d1=rndrange
;
;I	d1=rnd range
;O	d0=rnd number

		xdef	Rnd
Rnd
		move.l	rndseed(a5),d0	;Get seed
		add.l   d0,d0
		bhi.s   ROver
		eori.l  #$1d872b41,d0
ROver
		move.l	d0,rndseed(a5)	;Save new seed
		andi.l	#$ffff,d0	;Coerce into word
		divu	d1,d0		;Divide by range
		swap	d0		; and get remainder (modulus)

		rts


;****************************************************************************

;	Formato file oggetti :
;
;		0	W	Width
;		2	W	Height
;		4	W	X offset
;		6	W	Y offset
;		8	L*N	Offset pointers to the data for each column. N=number of column (width).
;				The Offset is relative to the field Width.
;
;	A questo punto, ogni colonna  suddivisa in trattini di pixel non
;	trasparenti. Per ogni trattino si ha:
;
;		0	B	Row to begin drawing (if < 0, the column is finished)
;		1	B	Number of pixel - 1
;		2	B*N	List of N pixel, where N is Number of pixel
;
;	Se la riga a cui iniziare  < 0 la colonna  terminata.

;****************************************************************************

ObjOrderList	ds.l	4*MAXVIEWOBJECTS	;Lista di ordinamento oggetti (max 40 oggetti)

	;*** Mini tabella di cos e sin per gli oggetti
;ObjSinCos	dc.w	256,0
;		dc.w	181,181
;		dc.w	0,256
;		dc.w	-181,181
;		dc.w	-256,0
;		dc.w	-181,-181
;		dc.w	0,-256
;		dc.w	181,-181

ObjSinCos	dc.w	256,0
		dc.w	251,50
		dc.w	236,98
		dc.w	213,142
		dc.w	181,181
		dc.w	142,213
		dc.w	98,236
		dc.w	50,251
		dc.w	0,256
		dc.w	-50,251
		dc.w	-98,236
		dc.w	-142,213
		dc.w	-181,181
		dc.w	-213,142
		dc.w	-236,98
		dc.w	-251,50
		dc.w	-256,0
		dc.w	-251,-50
		dc.w	-236,-98
		dc.w	-213,-142
		dc.w	-181,-181
		dc.w	-142,-213
		dc.w	-98,-236
		dc.w	-50,-251
		dc.w	0,-256
		dc.w	50,-251
		dc.w	98,-236
		dc.w	142,-213
		dc.w	181,-181
		dc.w	213,-142
		dc.w	236,-98
		dc.w	251,-50


;****************************************************************************

		section	__MERGED,BSS

		xdef	ObjectNumber

		cnop	0,4

ObjectNumber	ds.l	1	;Numero oggetti nella mappa

savedist	ds.l	1	;Per memorizzare temporaneamente la distanza dell'oggetto da tracciare
saveblpun	ds.l	1	;Per memorizzare temporaneamente il pun. al blocco
repeatanim	ds.w	1	;Contatore numero ripetizioni

animstep	ds.w	1	;Num. di fotogrammi da saltare nelle animazioni
animcarryobj	ds.l	1	;Riporto per animazione oggetti

ptmul		ds.l	1	;Usato dalla routine DrawObjects

plhdandi	ds.w	1	;usato nel calcolo del frame da visualizzare per i nemici

		xdef	Fire

Fire		ds.w	1



		cnop	0,4

		xdef	rndseed

rndseed		ds.l	1	;$4c277839

		xdef	ObjFree,ObjEnemies,ObjThings
		xdef	ObjPickThings,ObjShots,ObjExplosions

ObjFree		ds.l	1	;Pun. lista oggetti liberi
ObjEnemies	ds.l	1	;Pun. lista nemici
ObjThings	ds.l	1	;Pun. lista cose
ObjPickThings	ds.l	1	;Pun. lista cose da raccogliere
ObjShots	ds.l	1	;Pun. lista proiettili armi
ObjExplosions	ds.l	1	;Pun. lista esplosioni


		xdef	ObjectsPunList
		xdef	ObjectsPunListMinus4
ObjectsPunListMinus4 ds.l 1
ObjectsPunList	ds.l	MAXLEVELOBJECTS	;Lista di pun. ai singoli oggetti

;****************************************************************************

	IFEQ	1

long long_sqrt(long v) {
    int		i;
    unsigned	long result,tmp;
    unsigned	long low,high;

if (v <= 1L) return((unsigned)v);

low = v;
high = 0L;
result = 0;

for (i = 0; i < 16; i++) {
    result += result;
    high = (high << 2) | ((low >>30) & 0x3);
    low <<= 2;

    tmp = result + result + 1;
    if (high >= tmp)
	{
	result++;
	high -= tmp;
	}
}

if (v - (result * result) >= (result - 1))
    result++;

return(result);
}

    ENDIF
;****************************************************************
;*** Routine in pseudo codice per eliminare un oggetto
;*** dalla lista di oggetti di un blocco

;	if obj_next=0
;		if obj_prev=0
;			map[pos]=0
;		else
;			(obj_prev).obj_next=0
;		.
;	else
;		if obj_prev=0
;			(obj_next).obj_prev=0
;			map[pos]=(obj_next).number
;		else
;			(obj_prev).obj_next=obj_next
;			(obj_next).obj_prev=obj_prev
;		.
;	.

	ENDC
