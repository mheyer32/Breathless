;****************************************************************************
;*
;*	SecurityCode1.asm
;*
;*		Gestione codice di sicurezza 1
;*
;****************************************************************************

		include 'TMap.i'

;****************************************************************************
;* Genera codice sicurezza 1 in base ai parametri:
;*
;*	d1.l = colonna
;*	d2.l = riga
;*
;* Restituisce:
;*
;*	d0.l = codice

	;*** !!!PROTEZIONE!!!

		xdef	SecurityCode1,SecurityCode1End

SecurityCode1	movem.l d1-d7/a0-a6,-(sp)

		move.l	d2,d3
		subq.w	#1,d1
		addq.w	#1,d3
SC1loop		mulu.l	d3,d2
		dbra	d1,SC1loop
		swap	d2
		eori.l  #$d37db49,d2
		roxr.w	#3,d2
		roxl.l	#5,d2


		add.l   d2,d2
		bhi.s   SC1Over
		eori.l  #$1d872b41,d2
SC1Over
		divul.l	#10000,d0:d2	;Divide by range


			;*** Converte nel codice
		moveq	#10,d2
		lea	seccode1+4(pc),a0
		divul.l	d2,d3:d0
		move.b	d3,-(a0)
		divul.l	d2,d3:d0
		move.b	d3,-(a0)
		divul.l	d2,d3:d0
		move.b	d3,-(a0)
		divul.l	d2,d3:d0
		move.b	d3,-(a0)

		move.l	seccode1(pc),d0

		movem.l (sp)+,d1-d7/a0-a6
		rts
SecurityCode1End


seccode1	dc.l	0

		cnop	0,8

	;*** !!!FINE PROTEZIONE!!!
