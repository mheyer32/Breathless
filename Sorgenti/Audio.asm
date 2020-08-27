;****************************************************************************
;*
;*	Audio.asm
;*
;*		Routines di gestione dell'audio
;*
;*
;*
;****************************************************************************

		include 'System'
		include 'TMap.i'

;****************************************************************************

		xref	_custom
		xref	CurrBuffer
		xref	PlayerX,PlayerZ
		xref	Sounds,ObjectsPunList
		xref	PTModule
		xref	GlobalSound0,GlobalSound1,GlobalSound2,GlobalSound3
		xref	GlobalSound4,GlobalSound5,GlobalSound6,GlobalSound7
		xref	GlobalSound8,GlobalSound9,GlobalSound10
		xref	MusicVolume,FilterState,MusicState,MusicOnOff
		xref	P61_channels,P61_Master,P61_Play,P61_ofilter

		xref	nullbytes
		xref	pause

		xref	Rnd
		xref	P61_Init,P61_End

;****************************************************************************
;* Gestione effetti sonori
;* Viene richiamata ad ogni 50esimo dal VBlank e per suonare un sample
;* ha bisogno di tre passi (scanditi da AUDx_status):
;*	-1 : Resetta il canale
;*	 1 : Inserisce i dati del sample nei registri HW
;*	 0 : Abilita l'interrupt audio


		xdef	SoundFXServer
SoundFXServer
		lea	_custom,a6

		tst.b	MusicFade(a5)		;Test se effettuare fade-out musica
		beq.s	SFXSnofade		; Se no, salta
;		eori.b	#1,ritfade(a5)
;		beq.s	SFXSnofade
		move.w	P61_Master,d0		;Volume musica
		subq.w	#1,d0
		move.w	d0,P61_Master		;Setta volume musica
		bgt.s	SFXSnofade
		clr.b	MusicFade(a5)		;Ferma fade
SFXSnofade
		move.l	AUD0_sample(a5),d0
		beq.s	SFXSchannel1
		tst.b	AUD0_status(a5)
		bpl.s	SFXS0j1
		move.w	#DMAF_AUD0,dmacon(a6)	;Ferma DMA
		move.w	#INTF_AUD0,intena(a6)	;Ferma IRQ
		move.w	#0,aud0+ac_vol(a6)
		move.b	#1,AUD0_status(a5)
		bra	SFXSchannel1
SFXS0j1		beq.s	SFXS0j2
		move.l	d0,a0
		move.w	#0,aud0+ac_vol(a6)
		move.l	(a0)+,aud0+ac_ptr(a6)	;Pun. sample
		move.l	(a0)+,aud0+ac_len(a6)	;Length + Period
;		move.w	(a0)+,aud0+ac_vol(a6)	;Volume
	move.w	AUD0_volume(a5),aud0+ac_vol(a6)	;Volume
		clr.b	AUD0_status(a5)
		move.w	#DMAF_SETCLR+DMAF_AUD0,dmacon(a6)
		bra	SFXSchannel1
SFXS0j2		move.w	#INTF_SETCLR+INTF_AUD0,intena(a6)
		clr.l	AUD0_sample(a5)


SFXSchannel1	move.l	AUD1_sample(a5),d0
		beq.s	SFXSchannel2
		tst.b	AUD1_status(a5)
		bpl.s	SFXS1j1
		move.w	#DMAF_AUD1,dmacon(a6)	;Ferma DMA
		move.w	#INTF_AUD1,intena(a6)	;Ferma IRQ
		move.w	#0,aud1+ac_vol(a6)
		move.b	#1,AUD1_status(a5)
		bra	SFXSchannel2
SFXS1j1		beq.s	SFXS1j2
		move.l	d0,a0
		move.w	#0,aud1+ac_vol(a6)
		move.l	(a0)+,aud1+ac_ptr(a6)	;Pun. sample
		move.l	(a0)+,aud1+ac_len(a6)	;Length + Period
;		move.w	(a0)+,aud1+ac_vol(a6)	;Volume
	move.w	AUD1_volume(a5),aud1+ac_vol(a6)	;Volume
		clr.b	AUD1_status(a5)
		move.w	#DMAF_SETCLR+DMAF_AUD1,dmacon(a6)
		bra	SFXSchannel2
SFXS1j2		move.w	#INTF_SETCLR+INTF_AUD1,intena(a6)
		clr.l	AUD1_sample(a5)


SFXSchannel2	move.l	AUD2_sample(a5),d0
		beq.s	SFXSchannel3
		tst.b	AUD2_status(a5)
		bpl.s	SFXS2j1
		move.w	#DMAF_AUD2,dmacon(a6)	;Ferma DMA
		move.w	#INTF_AUD2,intena(a6)	;Ferma IRQ
		move.w	#0,aud2+ac_vol(a6)
		move.b	#1,AUD2_status(a5)
	move.w	#2-1,P61_channels
		bra	SFXSchannel3
SFXS2j1		beq.s	SFXS2j2
		move.l	d0,a0
		move.w	#0,aud2+ac_vol(a6)
		move.l	(a0)+,aud2+ac_ptr(a6)	;Pun. sample
		move.l	(a0)+,aud2+ac_len(a6)	;Length + Period
;		move.w	(a0)+,aud2+ac_vol(a6)	;Volume
	move.w	AUD2_volume(a5),aud2+ac_vol(a6)	;Volume
		clr.b	AUD2_status(a5)
		move.w	#DMAF_SETCLR+DMAF_AUD2,dmacon(a6)
		bra.s	SFXSchannel3
SFXS2j2		move.w	#INTF_SETCLR+INTF_AUD2,intena(a6)
		clr.l	AUD2_sample(a5)


SFXSchannel3	move.l	AUD3_sample(a5),d0
		beq.s	SFXSout
		tst.b	AUD3_status(a5)
		bpl.s	SFXS3j1
		move.w	#DMAF_AUD3,dmacon(a6)	;Ferma DMA
		move.w	#INTF_AUD3,intena(a6)	;Ferma IRQ
		move.w	#0,aud3+ac_vol(a6)
		move.b	#1,AUD3_status(a5)
		bra.s	SFXSout
SFXS3j1		beq.s	SFXS3j2
		move.l	d0,a0
		move.w	#0,aud3+ac_vol(a6)
		move.l	(a0)+,aud3+ac_ptr(a6)	;Pun. sample
		move.l	(a0)+,aud3+ac_len(a6)	;Length + Period
;		move.w	(a0)+,aud3+ac_vol(a6)	;Volume
	move.w	AUD3_volume(a5),aud3+ac_vol(a6)	;Volume
		clr.b	AUD3_status(a5)
		move.w	#DMAF_SETCLR+DMAF_AUD3,dmacon(a6)
		bra.s	SFXSout
SFXS3j2		move.w	#INTF_SETCLR+INTF_AUD3,intena(a6)
		clr.l	AUD3_sample(a5)


SFXSout
		rts

;****************************************************************************
;* Subroutines per suonare i sample di porte e ascensori
;* Usano: d0,d1,a0

		xdef	StartDoorSoundFX
StartDoorSoundFX
		move.w	ef_trigger(a3),d0
		moveq	#0,d1
		move.l	GlobalSound0(a5),a0
		movem.l	d0/a1-a2,-(sp)
		bra.s	BPSFXin2



		xdef	StopDoorSoundFX
StopDoorSoundFX
		move.w	ef_trigger(a3),d0
		moveq	#0,d1
		move.l	GlobalSound1(a5),a0
		movem.l	d0/a1-a2,-(sp)
		bra.s	BPSFXin2


;****************************************************************************
;* Subroutine per richiedere al SoundFXServer di suonare un sample.
;* Inserisce la richiesta di suonare un sample in una coda FIFO
;* per sincronizzare gli effetti sonori con il rendering a video.
;* Il tempo di rendering e il triplo buffer introducono dei tempi
;* di ritardo tra l'input di un comando da parte dell'utente e
;* l'effettiva visualizzazione dell'effetto del comando.
;* Tramite la gestione del buffer audio gli effetti sonori non sono
;* piu' sincronizzati con l'input del comando, ma con l'effettiva
;* visualizzazione.
;* Nel caso non sia richiesta sincronizzazione con il video,
;* e' possibile richiamare direttamente PlaySoundFX.
;* Richiede:
;*	a0 : Pun. al sound
;*	d1 : Distanza al quadrato della fonte sonora
;*
;* L'ingresso BPSFXin2 alla routine  impiegato per la gestione
;* dei suoni composti. Infatti  gestito il parametro code
;* passato tramite d0 (normalmente d0 viene azzerato).
;* Viene poi gestito il tipo di suono (sound type):
;*	-1 : Ferma suono
;*	 0 : Global sound o altro
;*	 1 : Suono emesso da oggetti
;* Se sound type = -1, Code non ha significato
;* Se sound type = 0, Code pu essere il trigger number di un effetto.
;* Se sound type = 1, Code pu essere il codice di un oggetto

		xdef	BufferedPlaySoundFX

BufferedPlaySoundFX
;		tst.b	BPSFXsemaphore(a5)	;La routine  occupata ?
;		bne.s	BPSFXexit		; Se si, salta
		movem.l	d0/a1-a2,-(sp)
		moveq	#0,d0
BPSFXin2
;		st	BPSFXsemaphore(a5)	;Segnala che la routine  occupata

		tst.l	a0		;Se pun. al sound=0,
		beq	BPSFXout	; esce

		move.l	ABufPunIn(a5),a2
		move.b	CurrBuffer+3(a5),(a2)+
		move.b	#1,(a2)+	;Sound type
		move.w	d0,(a2)+	;Code
		move.l	a0,(a2)+	;Pun. sound
		move.l	d1,(a2)+	;Distance
		lea	EndAudioBuffer(a5),a1
		cmp.l	a1,a2
		blt.s	BPSFXj1
		lea	AudioBuffer(a5),a2
BPSFXj1		move.l	a2,ABufPunIn(a5)
BPSFXout
;		clr.b	BPSFXsemaphore(a5)	;Segnala che la routine non  occupata

		movem.l	(sp)+,d0/a1-a2
BPSFXexit	rts


;****************************************************************************
;* Variante della BufferedPlaySoundFX, utilizzabile per emmettere
;* i suoni degli oggetti tenendo conto della distanza dal player
;* Richiede:
;*	a0   = Pun. all'object
;*	d0.l = numero del sound (0,1,2)
;*
;* a0 non viene modificato


		xdef	ObjBufferedPlaySoundFX

ObjBufferedPlaySoundFX
;		tst.b	BPSFXsemaphore(a5)	;La routine  occupata ?
;		bne.s	OBPSFXexit		; Se si, salta
		movem.l	a1-a2/d1,-(sp)

		move.l	obj_image(a0),a1
		move.l	o_sound1(a1,d0.l*4),a1
		tst.l	a1			;Se pun. sound=0,
		beq.s	OBPSFXout		; esce

;		st	BPSFXsemaphore(a5)	;Segnala che la routine  occupata

		move.w	obj_x(a0),d0
		sub.w	PlayerX(a5),d0
		muls.w	d0,d0
		move.w	obj_z(a0),d1
		sub.w	PlayerZ(a5),d1
		muls.w	d1,d1
		add.l	d0,d1			;d1=distanza oggetto dal player

		move.l	ABufPunIn(a5),a2
		move.b	CurrBuffer+3(a5),(a2)+
		clr.b	(a2)+			;Sound type
		moveq	#0,d0
		cmp.b	#2,obj_type(a0)		;L'oggetto  un nemico ?
		bne.s	OBPSFXj0		; Se no, salta
		move.w	obj_number(a0),d0
OBPSFXj0	move.w	d0,(a2)+		;Code
		move.l	a1,(a2)+		;Pun. sound
		move.l	d1,(a2)+		;Distance
		lea	EndAudioBuffer(a5),a1
		cmp.l	a1,a2
		blt.s	OBPSFXj1
		lea	AudioBuffer(a5),a2
OBPSFXj1	move.l	a2,ABufPunIn(a5)
OBPSFXout
;		clr.b	BPSFXsemaphore(a5)	;Segnala che la routine non  occupata

		movem.l	(sp)+,a1-a2/d1
OBPSFXexit	rts



;****************************************************************************
;* Routine bufferizzata per fermare un sound.
;* Richiede:
;*	a0 = Pun. al sound (I sound rnd non sono ancora gestiti)

		xdef	BufferedStopSoundFX

BufferedStopSoundFX
		movem.l	a1-a2,-(sp)

		tst.l	a0		;Se pun. al sound=0,
		beq	BSSFXout	; esce

		move.l	ABufPunIn(a5),a2
		move.b	CurrBuffer+3(a5),(a2)+
		move.b	#-1,(a2)+	;Sound type
		clr.w	(a2)+		;Code
		move.l	a0,(a2)+	;Pun. sound
		clr.l	(a2)+		;Distance
		lea	EndAudioBuffer(a5),a1
		cmp.l	a1,a2
		blt.s	BSSFXj1
		lea	AudioBuffer(a5),a2
BSSFXj1		move.l	a2,ABufPunIn(a5)
BSSFXout
		movem.l	(sp)+,a1-a2
		rts

;****************************************************************************

		xdef	SoundFXBufferServer

SoundFXBufferServer

		move.l	ABufPunOut(a5),a2
		cmp.l	ABufPunIn(a5),a2	;Ci sono effetti in coda ?
		beq	SFXBSout		; Se no, esce

		lea	EndAudioBuffer(a5),a3
		move.l	CurrBuffer(a5),d7

SFXBSloop	cmp.b	(a2),d7			;Deve essere suonato ora ?
		bne	SFXBSend		; Se no, esce
		move.b	#-1,(a2)+
		move.b	(a2)+,d5		;d5=Type
		bmi.s	SFXBSstopsound
		move.w	(a2)+,d0		;d0=Code
		move.l	(a2)+,a0		;a0=Pun. sound

		tst.b	snd_type(a0)		;Test se suono rnd
		bpl.s	SFXBSnornd		; Se no, salta
		move.l	d0,d3
		moveq	#0,d1
		move.b	snd_code(a0),d1		;d1=Num. di sound tra cui scegliere
		beq	SFXBSout
		jsr	Rnd
		move.l	(a0,d0.w*4),a0		;a0=pun. sound
		move.l	d3,d0
SFXBSnornd
		move.l	(a2)+,d1		;d1=Distance

		move.b	snd_mask(a0),d2

		moveq	#0,d4
		move.w	d0,d4			;Test code
		beq.s	SFXBSalloc		; Se=0, salta

		tst.b	d5			;E' un object sound ?
		bne.s	SFXBSnoobj		; Se no, salta
		lea	ObjectsPunListMinus4(a5),a1
		move.l	(a1,d0.w*4),d4		;d4=Pun. all'oggetto
SFXBSnoobj

			;*** Cerca canale con lo stesso code.
			;*** Se non lo trova, alloca normalmente il suono.

		cmp.l	AUD0_code(a5),d4
		bne.s	SFXBSj1
		moveq	#1,d2
		bra.s	SFXBSj4
SFXBSj1		cmp.l	AUD1_code(a5),d4
		bne.s	SFXBSj2
		moveq	#2,d2
		bra.s	SFXBSj4
SFXBSj2		cmp.l	AUD2_code(a5),d4
		bne.s	SFXBSj3
		moveq	#4,d2
		bra.s	SFXBSj4
SFXBSj3		cmp.l	AUD3_code(a5),d4
		bne.s	SFXBSj4
		moveq	#8,d2
SFXBSj4

SFXBSalloc	bsr	AllocSoundFX

SFXBScont	cmp.l	a3,a2
		blt.s	SFXBSnoe
		lea	AudioBuffer(a5),a2
SFXBSnoe
		bra	SFXBSloop
SFXBSend
		move.l	a2,ABufPunOut(a5)

SFXBSout
		rts


		;*** Gestione stop sound
SFXBSstopsound
		move.w	(a2)+,d0		;d0=Code
		move.l	(a2)+,a0		;a0=Pun. sound
		move.l	(a2)+,d1		;d1=Distance

		bsr	StopSoundFX

		bra.s	SFXBScont

;****************************************************************************
;* Subroutine per richiedere al SoundFXServer di suonare un sample.
;*
;* Richiede:
;*	a0 : Pun. al sound
;*	d1 : Distanza al quadrato della fonte sonora


		xdef	PlaySoundFX

PlaySoundFX	movem.l	a0-a1/d0-d5,-(sp)

		tst.l	a0			;Test se pun. sound=0
		beq.s	PSFXout			; Se si, esce

		tst.b	snd_type(a0)		;Test se suono rnd
		bpl.s	PSFXnornd		; Se no, salta
		move.l	d1,d3			;Salva d1
		moveq	#0,d1
		move.b	snd_code(a0),d1		;d1=Num. di sound tra cui scegliere
		beq	PSFXout
		jsr	Rnd
		move.l	(a0,d0.w*4),a0		;a0=pun. sound
		move.l	d3,d1			;Recupera d1
PSFXnornd
		moveq	#0,d4
		moveq	#1,d5
		move.b	snd_mask(a0),d2

		bsr	AllocSoundFX
PSFXout
		movem.l	(sp)+,a0-a1/d0-d5
		rts


;****************************************************************************
;* Subroutine per richiedere al SoundFXServer di suonare un sample.
;* L'assegnazione di un canale audio avviene in base alla priorita'.
;* La priorit di un suono diminuisce in base alla distanza,
;* viene cio sottratto un certo valore dalla priorit iniziale
;* in base al valore del volume (che viene calcolato a partire
;* dalla distanza). Questi valori sono:
;*	volume 64 : 0
;*	volume 32 : 1
;*	volume 16 : 2
;*	volume  8 : 3
;*	volume  4 : 4
;*	volume  2 : 5
;*	volume  1 : 6
;*	volume  0 : 7
;* Il volume calcolato in base alla distanza  relativo al valore
;* massimo di 64. Il volume a cui il sample viene suonato viene poi
;* calcolato in relazione al volume indicato nella struttura sound stessa.
;*
;* Richiede :
;*	a0 = Pun. al sound (Non deve essere=0 e non deve essere un sound rnd)
;*	d1 = Distanza al quadrato dalla fonte sonora
;*	d2 = channel mask
;*	d4 = code
;*	d5 = type (0=object; 1=altro)
;*

AllocSoundFX

		tst.b	snd_mask(a0)		;Test flag alone
		bpl.s	ASFXnochk		; Se FALSE, salta
						; altrimLGLD la se il sound puntato da a0 gi in play
		cmp.l	AUD0_sound(a5),a0
		beq	ASFXout
		cmp.l	AUD1_sound(a5),a0
		beq	ASFXout
		cmp.l	AUD2_sound(a5),a0
		beq	ASFXout
		cmp.l	AUD3_sound(a5),a0
		beq	ASFXout
ASFXnochk

		cmp.l	#32768,d1
		bgt.s	ASFXcalvol
		moveq	#64,d1
		bra.s	ASFXnocalvol
ASFXcalvol	lsr.l	#8,d1
		lsr.l	#7,d1
		cmp.w	#64,d1
		bge	ASFXout
ASFXcalvol2	sub.w	#64,d1
		neg.w	d1
ASFXnocalvol

		move.b	snd_priority(a0),d3
		lea	ChgPriTable(pc),a1
		sub.b	(a1,d1.w),d3		;Modifica priorit in base alla distanza

		mulu.w	snd_volume(a0),d1
		lsr.w	#6,d1			;d1=volume reale
		beq	ASFXout

		move.b	FreeChannels(a5),d0
		and.b	d2,d0
		beq.s	ASFXnofree		;Se=0, non ci sono canali liberi

		lsr.b	#1,d0
		bcs.s	ASFXgoch0
		lsr.b	#1,d0
		bcs.s	ASFXgoch1
		lsr.b	#1,d0
		bcs.s	ASFXgoch2
		lsr.b	#1,d0
		bcs	ASFXgoch3
ASFXnofree

		lsr.b	#1,d2			;Si pu usare il canale 0 ?
		bcc.s	ASFXchannel1		; Se no, salta
		cmp.b	AUD0_priority(a5),d3	;Confronta priorita'
		blt.s	ASFXchannel1		; Se piu' bassa, salta
ASFXgoch0	lea	AUD0_sound(a5),a1
		moveq	#0,d0
		bra.s	ASFXgo
ASFXchannel1
		lsr.b	#1,d2			;Si pu usare il canale 1 ?
		bcc.s	ASFXchannel2		; Se no, salta
		cmp.b	AUD1_priority(a5),d3	;Confronta priorita'
		blt.s	ASFXchannel2		; Se piu' bassa, salta
ASFXgoch1	lea	AUD1_sound(a5),a1
		moveq	#1,d0
		bra.s	ASFXgo
ASFXchannel2
		lsr.b	#1,d2			;Si pu usare il canale 2 ?
		bcc.s	ASFXchannel3		; Se no, salta
		cmp.b	AUD2_priority(a5),d3	;Confronta priorita'
		blt.s	ASFXchannel3		; Se piu' bassa, salta
ASFXgoch2	lea	AUD2_sound(a5),a1
		moveq	#2,d0
		bra.s	ASFXgo
ASFXchannel3
		lsr.b	#1,d2			;Si pu usare il canale 3 ?
		bcc.s	ASFXout			; Se no, salta
		cmp.b	AUD3_priority(a5),d3	;Confronta priorita'
		blt.s	ASFXout			; Se piu' bassa, salta
ASFXgoch3	lea	AUD3_sound(a5),a1
		moveq	#3,d0


ASFXgo
		move.b	d5,AUD0_type-AUD0_sound(a1)
		move.l	d4,AUD0_code-AUD0_sound(a1)
		move.l	a0,(a1)+		;Scrive pun. alla struttura sound
		move.l	a0,(a1)+		;Scrive pun. alla struttura sound
		move.b	#-1,(a1)+		;Init status
		move.b	d3,(a1)+		;Scrive priorita'
		bclr	d0,FreeChannels(a5)	;Segnala canale occupato
		move.w	d1,(a1)+		;Scrive volume

		move.w	snd_loop(a0),d0		;Il sample ha un loop ?
		bne.s	ASFXloop		; Se si, salta
		move.l	nullbytes(a5),(a1)+	;Scrive pun. loop
		move.w	#1,(a1)+		;Scrive lun. loop
		clr.b	(a1)+			;Scrive flag loop
		bra.s	ASFXnoloop
ASFXloop	move.l	snd_pointer(a0),d2
		ext.l	d0
		add.l	d0,d2			;d2=Pun. loop
		move.l	d2,(a1)+		;Scrive pun. loop
		lsr.w	#1,d0
		sub.w	snd_length(a0),d0
		neg.w	d0			;d0=Lunghezza loop
		move.w	d0,(a1)+		;Scrive lun. loop
		move.b	#1,(a1)+		;Scrive flag loop
ASFXnoloop

ASFXout
		rts



ChgPriTable	dc.b	7
		dc.b	6,5,4,4,3,3,3,3,2,2,2,2,2,2,2,2
		dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

		cnop	0,2


;****************************************************************************
;* Routine per fermare l'esecuzione di un suono.
;* Cerca nei canali indicati dal channel mask il sound con pun.
;* uguale a quello in a0 e lo ferma
;* Richiede:
;*	a0 = Pun. al sound (Non deve essere=0 e non deve essere un sound rnd)
;*	d0 = channel mask

		xdef	StopSoundFX

StopSoundFX
		and.b	FreeChannels(a5),d0
		cmp.b	#%1111,d0
		beq	SSout			;Salta se tutti i canali sono liberi

		lea	$dff000,a6

		lsr.b	#1,d0			;Canale 0 occupato ?
		bcs.s	SSchannel1		; Se no, salta
		cmp.l	AUD0_sound(a5),a0
		bne.s	SSchannel1
		move.w	#DMAF_AUD0,dmacon(a6)	;Ferma DMA
		move.w	#INTF_AUD0,intena(a6)	;Ferma IRQ
		move.w	#INTF_AUD0,intreq(a6)	;Clear IRQ bit
		clr.b	AUD0_priority(a5)
		clr.l	AUD0_sound(a5)
		clr.l	AUD0_sample(a5)
		bset	#0,FreeChannels(a5)
		rts
SSchannel1
		lsr.b	#1,d0			;Canale 1 occupato ?
		bcs.s	SSchannel2		; Se no, salta
		cmp.l	AUD1_sound(a5),a0
		bne.s	SSchannel2
		move.w	#DMAF_AUD1,dmacon(a6)	;Ferma DMA
		move.w	#INTF_AUD1,intena(a6)	;Ferma IRQ
		move.w	#INTF_AUD1,intreq(a6)	;Clear IRQ bit
		clr.b	AUD1_priority(a5)
		clr.l	AUD1_sound(a5)
		clr.l	AUD1_sample(a5)
		bset	#1,FreeChannels(a5)
		rts
SSchannel2
		lsr.b	#1,d0			;Canale 2 occupato ?
		bcs.s	SSchannel3		; Se no, salta
		cmp.l	AUD2_sound(a5),a0
		bne.s	SSchannel3
		move.w	#DMAF_AUD2,dmacon(a6)	;Ferma DMA
		move.w	#INTF_AUD2,intena(a6)	;Ferma IRQ
		move.w	#INTF_AUD2,intreq(a6)	;Clear IRQ bit
		clr.b	AUD2_priority(a5)
		clr.l	AUD2_sound(a5)
		clr.l	AUD2_sample(a5)
		bset	#2,FreeChannels(a5)
		rts
SSchannel3
		lsr.b	#1,d0			;Canale 3 occupato ?
		bcs.s	SSout			; Se no, salta
		cmp.l	AUD3_sound(a5),a0
		bne.s	SSout
		move.w	#DMAF_AUD3,dmacon(a6)	;Ferma DMA
		move.w	#INTF_AUD3,intena(a6)	;Ferma IRQ
		move.w	#INTF_AUD3,intreq(a6)	;Clear IRQ bit
		clr.b	AUD3_priority(a5)
		clr.l	AUD3_sound(a5)
		clr.l	AUD3_sample(a5)
		bset	#3,FreeChannels(a5)
SSout
		rts

;****************************************************************************
;* Inizializzazione delle routine sonore

		xdef	InitAudio

InitAudio
		lea	AudioBuffer(a5),a0
		move.l	a0,ABufPunIn(a5)
		move.l	a0,ABufPunOut(a5)

	;*** Init Audio buffer
		lea	EndAudioBuffer(a5),a1
		moveq	#-1,d0
IAloop0		move.l	d0,(a0)+
		cmp.l	a1,a0
		blt.s	IAloop0

		move.b	#%1111,FreeChannels(a5)

	;*** Azzera dati canali audio
		lea	AUD0_sample(a5),a0
		moveq	#23,d1
IAloop1		clr.l	(a0)+
		dbra	d1,IAloop1


		clr.l	PTModule(a5)

	;*** Init sound samples

		move.l	Sounds(a5),a0
IAloop2		move.l	(a0)+,d0		;Legge nome sound
		beq.s	IAout2			;Se=0, fine lista sound
		move.l	(a0)+,a1		;a1=pun. al sound
		tst.b	snd_type(a1)		;Sound di tipo rnd ?
		bmi.s	IArndinit		; Se si, salta
		move.l	snd_pointer(a1),d1	;d1=nome sound link
		bne.s	IAsearch		; Se<>0, salta
		lea	snd_SIZE(a1),a2		;Altrimenti calcola pun. al sample
IAwr		move.l	a2,snd_pointer(a1)	;Scrive pun. al sample
		tst.b	snd_type(a1)		;E' un modulo PT ?
		bne.s	IAloop2			; Se no, salta
		move.l	a2,PTModule(a5)		;Scrive pun. al pezzo musicale
		bra.s	IAloop2
IAsearch	move.l	Sounds(a5),a3
IAloop3		move.l	(a3)+,d0		;Legge nome sound
		beq.s	IAloop2			;Se=0, fine lista sound: non ha trovato il sound link
		cmp.l	d0,d1			;Confronta nomi sound
		beq.s	IAfound			; Se uguali, salta
		addq.l	#4,a3			;Passa al prossimo sound
		bra.s	IAloop3
IAfound		move.l	(a3),a2			;Legge pun. sound link
		lea	snd_SIZE(a2),a2		;a2=pun. sample
		bra.s	IAwr			;Salta a scriverlo
IArndinit
		moveq	#2,d7
IAloop4		move.l	Sounds(a5),a3
		move.l	(a1),d1			;d1=nome sound da cercare
		beq.s	IAfound2		;Salta se=0
IAloop5		move.l	(a3)+,d0		;Legge nome sound
		beq.s	IAfound2		;Se=0, fine lista sound: non ha trovato il sound
		cmp.l	d0,d1			;Confronta nomi sound
		beq.s	IAfound2		; Se uguali, salta
		addq.l	#4,a3			;Passa al prossimo sound
		bra.s	IAloop5
IAfound2	move.l	(a3),(a1)+		;Legge pun. sound
		dbra	d7,IAloop4
		bra.s	IAloop2			;Ritorna al loop principale
IAout2

;		rts

;***********************************************************************
;* Accende/spegne musica, setta volume musica e
;* setta filtro in base ad alcuni flag

		xdef	InitAudio2

InitAudio2	movem.l	d0-d7/a0-a6,-(sp)

		moveq	#2,d0
		bset	#1,$bfe001
		tst.w	FilterState(a5)
		beq.s	IMfilteroff
		moveq	#0,d0
		bclr	#1,$bfe001
IMfilteroff	move.b	d0,P61_ofilter

		move.w	#3-1,P61_channels

		move.l	PTModule(a5),d0		;Test se c'e' musica
		beq.s	IMnomod			; Se no, salta
		tst.w	MusicOnOff(a5)		;Test stato musica
		beq.s	IMmodoff		; Se=0, spegne musica
		move.w	MusicVolume(a5),d1	;d1=Volume musica
		addq.w	#1,d1
		lsl.w	#4,d1
		move.w	d1,P61_Master		;Setta volume musica
		st	MusicState(a5)
		move.b	#7,AUD0_priority(a5)
		move.b	#7,AUD1_priority(a5)
		move.b	#2,AUD2_priority(a5)
		move.b	#%1000,FreeChannels(a5)
		move.w	#$e000,$dff09a		;Attiva IRQ lev6
		tst.w	P61_Play		;Test se deve inizializzare la musica
		bne.s	IMnomodinit		; Se no, salta
		move.l	d0,a0
		lea	$dff000,a6
		sub.l	a1,a1
		sub.l	a2,a2
		jsr	P61_Init
		GETDBASE
		st	P61_Play+1
IMnomodinit	bra.s	IMout
IMmodoff	tst.w	P61_Play		;Test se musica attiva
;		bne.s	IMnomod			; Se no, salta
		beq.s	IMnomod			; Se no, salta
		lea	$dff000,a6
		jsr	P61_End
		GETDBASE
IMnomod		clr.b	MusicState(a5)
		clr.w	P61_Play
		clr.w	MusicOnOff(a5)
		clr.b	AUD0_priority(a5)
		clr.b	AUD1_priority(a5)
		clr.b	AUD2_priority(a5)
		move.b	#%1111,FreeChannels(a5)
IMout
		movem.l	(sp)+,d0-d7/a0-a6
		rts

;***********************************************************************
;* Ferma emissione suoni

		xdef	StopAudio
StopAudio
		lea	_custom,a0
		move.w	#DMAF_AUD0+DMAF_AUD1+DMAF_AUD2+DMAF_AUD3,dmacon(a0)	;Ferma DMA
		move.w	#INTF_AUD0+INTF_AUD1+INTF_AUD2+INTF_AUD3,intena(a0)	;Ferma IRQ

		rts

;***********************************************************************
;* Routine di interrupt audio

		xdef	AudioIRQ0

AudioIRQ0
		tst.b	AUD0_status(a1)		;Deve fermare il canale ?
		beq.s	A0status1		; Se no, salta
;		move.w	#INTF_AUD0,intena(a0)	;Ferma IRQ
		tst.w	pause(a1)		;Se il gioco  in pausa
		bne.s	A0stopdma		; Ferma suoni in loop
		tst.b	AUD0_loop(a1)		;Se c' loop non ferma il DMA
		bne.s	A0out
A0stopdma	move.w	#DMAF_AUD0,dmacon(a0)	;Ferma DMA
		move.w	#INTF_AUD0,intena(a0)	;Ferma IRQ
		tst.l	AUD0_sample(a1)
		bne.s	A0out
		clr.b	AUD0_priority(a1)
		clr.l	AUD0_sound(a1)
		bset	#0,FreeChannels(a1)
		move.l	AUD0_code(a1),d0	;Code=0 ?
		beq.s	A0out			; Se si, salta
		tst.b	AUD0_type(a1)		;Sound object ?
		bne.s	A0out			; Se no, salta
		move.l	d0,a6
		bclr	#7,obj_subtype(a6)	;Segnala all'oggetto che il suono  terminato
		clr.l	AUD0_code(a1)
		bra.s	A0out
A0status1	move.b	#1,AUD0_status(a1)
		move.w	AUD0_looplen(a1),aud0+ac_len(a0)
		move.l	AUD0_loopptr(a1),aud0+ac_ptr(a0)
A0out
		move.w	#INTF_AUD0,intreq(a0)	;Clear IRQ bit
		rts

;-----

		xdef	AudioIRQ1

AudioIRQ1
		tst.b	AUD1_status(a1)		;Deve fermare il canale ?
		beq.s	A1status1		; Se no, salta
;		move.w	#INTF_AUD1,intena(a0)	;Ferma IRQ
		tst.w	pause(a1)		;Se il gioco  in pausa
		bne.s	A1stopdma		; Ferma suoni in loop
		tst.b	AUD1_loop(a1)		;Se c' loop non ferma il DMA
		bne.s	A1out
A1stopdma	move.w	#DMAF_AUD1,dmacon(a0)	;Ferma DMA
		move.w	#INTF_AUD1,intena(a0)	;Ferma IRQ
		tst.l	AUD1_sample(a1)
		bne.s	A1out
		clr.b	AUD1_priority(a1)
		clr.l	AUD1_sound(a1)
		bset	#1,FreeChannels(a1)
		move.l	AUD1_code(a1),d0	;Code=0 ?
		beq.s	A1out			; Se si, salta
		tst.b	AUD1_type(a1)		;Sound object ?
		bne.s	A1out			; Se no, salta
		move.l	d0,a6
		bclr	#7,obj_subtype(a6)	;Segnala all'oggetto che il suono  terminato
		clr.l	AUD1_code(a1)
		bra.s	A1out
A1status1	move.b	#1,AUD1_status(a1)
		move.w	AUD1_looplen(a1),aud1+ac_len(a0)
		move.l	AUD1_loopptr(a1),aud1+ac_ptr(a0)
A1out
		move.w	#INTF_AUD1,intreq(a0)	;Clear IRQ bit
		rts

;-----

		xdef	AudioIRQ2

AudioIRQ2
		tst.b	AUD2_status(a1)		;Deve fermare il canale ?
		beq.s	A2status1		; Se no, salta
;		move.w	#INTF_AUD2,intena(a0)	;Ferma IRQ
		tst.w	pause(a1)		;Se il gioco  in pausa
		bne.s	A2stopdma		; Ferma suoni in loop
		tst.b	AUD2_loop(a1)		;Se c' loop non ferma il DMA
		bne.s	A2out
A2stopdma	move.w	#DMAF_AUD2,dmacon(a0)	;Ferma DMA
		move.w	#INTF_AUD2,intena(a0)	;Ferma IRQ
	move.w	#3-1,P61_channels
		tst.l	AUD2_sample(a1)
		bne.s	A2out
		clr.b	AUD2_priority(a1)
		clr.l	AUD2_sound(a1)
		bset	#2,FreeChannels(a1)
		move.l	AUD2_code(a1),d0	;Code=0 ?
		beq.s	A2out			; Se si, salta
		tst.b	AUD2_type(a1)		;Sound object ?
		bne.s	A2out			; Se no, salta
		move.l	d0,a6
		bclr	#7,obj_subtype(a6)	;Segnala all'oggetto che il suono  terminato
		clr.l	AUD2_code(a1)
		bra.s	A2out
A2status1	move.b	#1,AUD2_status(a1)
		move.w	AUD2_looplen(a1),aud2+ac_len(a0)
		move.l	AUD2_loopptr(a1),aud2+ac_ptr(a0)
A2out
		move.w	#INTF_AUD2,intreq(a0)	;Clear IRQ bit
		rts

;-----

		xdef	AudioIRQ3

AudioIRQ3
		tst.b	AUD3_status(a1)		;Deve fermare il canale ?
		beq.s	A3status1		; Se no, salta
;		move.w	#INTF_AUD3,intena(a0)	;Ferma IRQ
		tst.w	pause(a1)		;Se il gioco  in pausa
		bne.s	A3stopdma		; Ferma suoni in loop
		tst.b	AUD3_loop(a1)		;Se c' loop non ferma il DMA
		bne.s	A3out
A3stopdma	move.w	#DMAF_AUD3,dmacon(a0)	;Ferma DMA
		move.w	#INTF_AUD3,intena(a0)	;Ferma IRQ
		tst.l	AUD3_sample(a1)
		bne.s	A3out
		clr.b	AUD3_priority(a1)
		clr.l	AUD3_sound(a1)
		bset	#3,FreeChannels(a1)
		move.l	AUD3_code(a1),d0	;Code=0 ?
		beq.s	A3out			; Se si, salta
		tst.b	AUD3_type(a1)		;Sound object ?
		bne.s	A3out			; Se no, salta
		move.l	d0,a6
		bclr	#7,obj_subtype(a6)	;Segnala all'oggetto che il suono  terminato
		clr.l	AUD3_code(a1)
		bra.s	A3out
A3status1	move.b	#1,AUD3_status(a1)
		move.w	AUD3_looplen(a1),aud3+ac_len(a0)
		move.l	AUD3_loopptr(a1),aud3+ac_ptr(a0)
A3out
		move.w	#INTF_AUD3,intreq(a0)	;Clear IRQ bit
		rts


;****************************************************************************

;sound		MACRO
;		dc.l	\1	;snd_pointer
;		dc.w	\2>>1	;snd_length
;		dc.w	\3	;snd_period
;		dc.w	\4	;snd_volume
;		dc.w	\5	;snd_loop
;		dc.b	\6	;snd_priority
;		dc.b	%\7	;snd_mask
;		dc.b	0,0
;		ENDM
;
;		;	pointer,length,period,volume,loop,priority,mask
;SampleTable
;		sound	sample1,09600,0447,64,00000,1,0001
;		sound	sample2,04004,0650,64,00000,2,1110
;		sound	sample3,13282,0325,64,09364,2,0100
;		sound	sample4,03404,0500,64,00000,2,0100
;		sound	sample5,01996,0284,64,00000,2,1111
;		sound	sample6,02084,0498,50,00000,3,1001
;		sound	sample7,01970,1712,64,00000,3,1111
;		sound	sample8,01452,0360,64,00000,3,1111
;
;;****************************************************************************
;
;	section	sss,DATA_C
;
;sample1		incbin	'Samples/Explosion1'
;sample2		incbin	'Samples/Explosion5'
;sample3		incbin	'Samples/LiftBegRun01'
;sample4		incbin	'Samples/LiftEnd01'
;sample5		incbin	'Samples/Switch6'
;sample6		incbin	'Samples/Scream6'
;sample7		incbin	'Samples/Transporter02'
;sample8		incbin	'Samples/Item02'

;****************************************************************************

	section	__MERGED,BSS

		cnop	0,4

		xdef	SoundsNumber

SoundsNumber	ds.l	1	;Numero di suoni del livello corrente

ABufPunIn	ds.l	1
ABufPunOut	ds.l	1

AudioBuffer	ds.b	12*64	;Buffer per le richieste di suonare un sample
EndAudioBuffer:

BPSFXsemaphore	ds.b	1	;Semaforo per l'uso delle routine di play bufferizzato da IRQ
				;Se<>0, la routine  in esecuzione

		xdef	MusicFade

MusicFade	ds.b	1	;Se<>0, effettua il fadeout della musica
ritfade		ds.b	1	;Contatore di ritardo per fade



;*** AUDx_priority: Priorita' dei sample dei canali audio.
;*** Assumono valori tra 0 (canale libero) e 7 (massima priorita')

;*** AUDx_status: usati dalle routine di play dei sample e dagli IRQ audio.
;*** Assumono i seguenti valori, nell'ordine riportato:
;***		-1 : deve resettare il canale
;***		 1 : deve inserire i dati del sample nei registri HW
;***		 0 : deve fermare i sample


AUD0_sound	ds.l	1	;Pun. al sound attuale (viene azzerato solo quando il suono  finito)
AUD0_sample	ds.l	1	;Pun. al sound da suonare (viene azzerato appena il sample viene messo in play)
AUD0_status	ds.b	1	;Stato
AUD0_priority	ds.b	1	;Priorita'
AUD0_volume	ds.w	1	;Volume
AUD0_loopptr	ds.l	1	;Pun. al loop
AUD0_looplen	ds.w	1	;Lunghezza del loop
AUD0_loop	ds.b	1	;Flag loop (se=0, non c'e' loop)
AUD0_type	ds.b	1	;Tipo suono (0=object; 1=altro)
AUD0_code	ds.l	1	;Usato per suonare i suoni composti sempre sullo stesso canale (vedi Door e lift)
				; e per controllare che un oggetto emetta al massimo un suono alla volta

AUD1_sound	ds.l	1	;Pun. al sound attuale (viene azzerato solo quando il suono  finito)
AUD1_sample	ds.l	1	;Pun. al sound da suonare (viene azzerato appena il sample viene messo in play)
AUD1_status	ds.b	1	;Stato
AUD1_priority	ds.b	1	;Priorita'
AUD1_volume	ds.w	1	;Volume
AUD1_loopptr	ds.l	1	;Pun. al loop
AUD1_looplen	ds.w	1	;Lunghezza del loop
AUD1_loop	ds.b	1	;Flag loop (se=0, non c'e' loop)
AUD1_type	ds.b	1	;Tipo suono (0=object; 1=altro)
AUD1_code	ds.l	1	;Usato per suonare i suoni composti sempre sullo stesso canale (vedi Door e lift)
				; e per controllare che un oggetto emetta al massimo un suono alla volta

AUD2_sound	ds.l	1	;Pun. al sound attuale (viene azzerato solo quando il suono  finito)
AUD2_sample	ds.l	1	;Pun. al sound da suonare (viene azzerato appena il sample viene messo in play)
AUD2_status	ds.b	1	;Stato
AUD2_priority	ds.b	1	;Priorita'
AUD2_volume	ds.w	1	;Volume
AUD2_loopptr	ds.l	1	;Pun. al loop
AUD2_looplen	ds.w	1	;Lunghezza del loop
AUD2_loop	ds.b	1	;Flag loop (se=0, non c'e' loop)
AUD2_type	ds.b	1	;Tipo suono (0=object; 1=altro)
AUD2_code	ds.l	1	;Usato per suonare i suoni composti sempre sullo stesso canale (vedi Door e lift)
				; e per controllare che un oggetto emetta al massimo un suono alla volta

AUD3_sound	ds.l	1	;Pun. al sound attuale (viene azzerato solo quando il suono  finito)
AUD3_sample	ds.l	1	;Pun. al sound da suonare (viene azzerato appena il sample viene messo in play)
AUD3_status	ds.b	1	;Stato
AUD3_priority	ds.b	1	;Priorita'
AUD3_volume	ds.w	1	;Volume
AUD3_loopptr	ds.l	1	;Pun. al loop
AUD3_looplen	ds.w	1	;Lunghezza del loop
AUD3_loop	ds.b	1	;Flag loop (se=0, non c'e' loop)
AUD3_type	ds.b	1	;Tipo suono (0=object; 1=altro)
AUD3_code	ds.l	1	;Usato per suonare i suoni composti sempre sullo stesso canale (vedi Door e lift)
				; e per controllare che un oggetto emetta al massimo un suono alla volta



FreeChannels	ds.b	4	;Ogni bit a 1 corrisponde ad una canale libero

		cnop	0,4
