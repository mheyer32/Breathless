;****************************************************************************
;*
;*	SecurityCode2.asm
;*
;*		Gestione codice di sicurezza 2
;*
;****************************************************************************

		include 'TMap.i'

;****************************************************************************
;* Genera codice sicurezza 2 in base ai parametri:
;*
;*	d1.l = colonna
;*	d3.l = riga
;*
;* Restituisce:
;*
;*	d0.l = codice

		xdef	seccode2

seccode2	dc.l	0

		xdef	SecurityCode2

SecurityCode2	movem.l d1-d7/a0-a6,-(sp)

		addq.w	#1,d3
		move.l	d3,d4
		addq.w	#1,d4
		subq.w	#1,d1
SC2loop		muls.l	d4,d3
		dbra	d1,SC2loop
		roxl.l	#8,d3
		eori.l  #$c4b13928,d3
		roxl.w	#7,d3
		roxr.l	#5,d3


		add.l   d3,d3
		bhi.s   SC2Over
		eori.l  #$2b411d87,d3
SC2Over
		divul.l	divis,d0:d3	;Divide by range


			;*** Converte nel codice
		lea	seccode2+4,a0
		moveq	#10,d2
		moveq	#97,d4
		moveq	#3,d5
SC2cloop	divul.l	d2,d3:d0
;		add.w	d4,d3
		move.b	d3,-(a0)
		dbra	d5,SC2cloop

		move.l	seccode2,d0

		movem.l (sp)+,d1-d7/a0-a6
		rts

divis		dc.l	10000

