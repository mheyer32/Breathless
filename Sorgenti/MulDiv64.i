                IFEQ __CPU-68060
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

                IFD     USEFPU

DIVS64          MACRO
                tst.l   \3
                bpl.b   .pos\@
                addq.l  #1,\2 ; add 2**32 (can't overflow if result is <= 2**31)
.pos\@
                fmove.l \2,fp0
                fmul.x  fp6,fp0 ; 1<<32
                fadd.l  \3,fp0
                fdiv.l  \1,fp0
                fintrz.x fp0
                fmove.l fp0,\3
                ENDM


FIXMUL          MACRO
                fmove.l \1,fp0
                fmul.l  \3,fp0
                fmul.x  fp7,fp0 ; fp7=1/65536
                fmove.l fp0,\3
                ENDM

                ELSE    ; USEFPU

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


; NOTE: Only used as DIVS d2,d3,dx (where x is not d0/d1)
; Remained is not used
DIVS64		MACRO
                IFNC \1,d2
                ERROR Only works with \1=d2!
                ENDC
                movem.l d0/d1,-(sp)
                move.l  \2,d1
                move.l  \3,d0
                bsr     SDiv64
                move.l  d1,\2
                move.l  d0,\3
                movem.l (sp)+,d0/d1
		ENDM

; \3 = (\1*\3) >> 16, \4-\8 scratch registers (preserved), \2 trashed
FIXMUL          MACRO
                ; MULS64
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
                ; >>= 16
                move.w  \2,\3
                swap    \3
                ENDM

                ENDC    ; USEFPU

                ELSE    ; 68060

MULU64          MACRO
                mulu.l  \1,\2:\3
                ENDM

DIVS64          MACRO
                divs.l  \1,\2:\3
                ENDM

FIXMUL          MACRO
                muls.l  \1,\2:\3
                move.w  \2,\3
                swap    \3
                ENDM

                ENDC    ; 68060

