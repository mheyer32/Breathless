;****************************************************************************
;*
;*	Moltiplicazione e divisione a 64 bit
;*
;****************************************************************************

;****************************************************************************
;* La moltiplicazione viene eseguita in questo modo:
;*
;* $aaaabbbb * $ccccdddd =
;* = $dddd*$bbbb + ($dddd*$aaaa)<<16 + ($cccc*$bbbb)<<16 + ($cccc*$aaaa)<<32
;*	
;****************************************************************************

;****************************************************************************
;* Emula l'istruzione: mulu.l <ea>,dr1:dr2
;* Parametri :
;*	\1 : <ea>
;*	\2 : dr1 (un registro dati)
;*	\3 : dr2 (un registro dati)
;*	\4 : dr3 (registro dati di scratch)
;*	\5 : dr4 (registro dati di scratch)
;*	\6 : dr5 (registro dati di scratch)

MULU64		MACRO

		movem.l	\4/\5/\6,-(sp)

		moveq	#0,\6

		move.l	\1,\4
		mulu.w	\3,\4		;\4 = dddd*bbbb

		move.l	\1,\2
		swap	\2
		mulu.w	\3,\2		;\2 = dddd*aaaa

		swap	\3
		move.l	\1,\5
		mulu.w	\3,\5		;\5 = cccc*bbbb

		add.l	\2,\5		;\5 = dddd*aaaa + cccc*bbbb
		bcc.s	M64j1\@		;Salta se non c' riporto
		move.l	#$10000,\6
M64j1\@
		move.l	\1,\2
		swap	\2
		mulu.w	\3,\2		;\2 = cccc*aaaa

		move.l	\5,\3
		swap	\5
		clr.w	\5
		add.l	\5,\4

		addx.l	\6,\2

		clr.w	\3
		swap	\3

		add.l	\3,\2		;\2 = Parte alta del risultato

		move.l	\4,\3		;\3 = Parte bassa del risultato

		movem.l	(sp)+,\4/\5/\6

		ENDM

;****************************************************************************
;* Emula l'istruzione: muls.l <ea>,dr1:dr2
;* Parametri :
;*	\1 : <ea>
;*	\2 : dr1 (un registro dati)
;*	\3 : dr2 (un registro dati)
;*	\4 : dr3 (registro dati di scratch)
;*	\5 : dr4 (registro dati di scratch)
;*	\6 : dr5 (registro dati di scratch)
;*	\7 : dr6 (registro dati di scratch)
;*	\8 : dr7 (registro dati di scratch)

MULS64		MACRO

		movem.l	\4/\5/\6/\7/\8,-(sp)

			;*** Negazione dei due moltiplicandi
		moveq	#0,\8
		move.l	\1,\7
		bpl.s	M64n1\@
		neg.l	\7
		moveq	#1,\8
M64n1\@		tst.l	\3
		bpl.s	M64n2\@
		neg.l	\3
		eor.b	#1,\8		;\8 = flag di segno del risultato
M64n2\@

		moveq	#0,\6

		move.l	\7,\4
		mulu.w	\3,\4		;\4 = dddd*bbbb

		move.l	\7,\2
		swap	\2
		mulu.w	\3,\2		;\2 = dddd*aaaa

		swap	\3
		move.l	\7,\5
		mulu.w	\3,\5		;\5 = cccc*bbbb

		add.l	\2,\5		;\5 = dddd*aaaa + cccc*bbbb
		bcc.s	M64j1\@		;Salta se non c' riporto
		move.l	#$10000,\6
M64j1\@
		move.l	\7,\2
		swap	\2
		mulu.w	\3,\2		;\2 = cccc*aaaa

		move.l	\5,\3
		swap	\5
		clr.w	\5
		add.l	\5,\4

		addx.l	\6,\2

		clr.w	\3
		swap	\3

		add.l	\3,\2		;\2 = Parte alta del risultato

		move.l	\4,\3		;\3 = Parte bassa del risultato

		tst.b	\8		;Il risultato  negativo ?
		beq.s	M64n3\@		; se no, salta
		neg.l	\3		;Nega il risultato
		negx.l	\2
M64n3\@
		movem.l	(sp)+,\4/\5/\6/\7/\8

		ENDM

;****************************************************************************
;* La moltiplicazione viene eseguita con il metodo classico dei
;* quozienti parziali
;****************************************************************************

;****************************************************************************
;* Emula l'istruzione: divu.l <ea>,dr1:dr2
;* Parametri :
;*	\1 : <ea>
;*	\2 : dr1 (un registro dati)
;*	\3 : dr2 (un registro dati)
;*	\4 : dr3 (registro dati di scratch)
;*	\5 : dr4 (registro dati di scratch)
;*	\6 : dr4 (registro dati di scratch)


DIVU64		MACRO

		movem.l	\4/\5/\6,-(sp)

		moveq	#64-1,\6		;\6 = contatore iterazioni
		move.l	\1,\5			;\5 = divisore
		move.l	\2,\4
		moveq	#0,\2

D64loop\@	add.l	\3,\3
		addx.l	\4,\4
		addx.l	\2,\2
		cmp.l	\2,\5
		bhi.s	D64nosub\@
		sub.l	\5,\2
		addq.l	#1,\3
D64nosub\@	dbra	\6,D64loop\@

		movem.l	(sp)+,\4/\5/\6

		ENDM


;****************************************************************************
;* Emula l'istruzione: divs.l <ea>,dr1:dr2
;*
;* N.B.:
;*	Il resto ha il segno sbagliato in alcuni casi, ma siccome
;*	del resto non mi frega nulla, lo lascio stare cosi'.
;*
;* Parametri :
;*	\1 : <ea>
;*	\2 : dr1 (un registro dati)
;*	\3 : dr2 (un registro dati)
;*	\4 : dr3 (registro dati di scratch)
;*	\5 : dr4 (registro dati di scratch)
;*	\6 : dr4 (registro dati di scratch)


DIVS64		MACRO

		movem.l	\4/\5/\6,-(sp)

			;*** Negazione dei due operandi
		moveq	#0,\6
		move.l	\1,\5			;\5 = divisore
		bpl.s	D64n1\@
		neg.l	\5
		moveq	#1,\6
D64n1\@		tst.l	\2
		bpl.s	D64n2\@
		neg.l	\3
		negx.l	\2
		eor.b	#1,\6		;\6 = flag di segno del risultato
D64n2\@
		swap	\6

		move.w	#64-1,\6		;\6 = contatore iterazioni
		move.l	\2,\4
		moveq	#0,\2

D64loop\@	add.l	\3,\3
		addx.l	\4,\4
		addx.l	\2,\2
		cmp.l	\2,\5
		bhi.s	D64nosub\@
		sub.l	\5,\2
		addq.l	#1,\3
D64nosub\@	dbra	\6,D64loop\@

		swap	\6
		tst.w	\6		;Il risultato  negativo ?
		beq.s	D64n3\@		; se no, salta
		neg.l	\3		;Nega il risultato
D64n3\@
		movem.l	(sp)+,\4/\5/\6

		ENDM

