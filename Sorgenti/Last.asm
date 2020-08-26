;****************************************************************************
;*
;*	Last.asm
;*		Questo sorgente serve solo per definire
;*		l'ultima variabile della section __MERGED,BSS.
;*		L'oggetto corrispondente (Last.o) deve essere
;*		linkato per ultimo.
;*		Serve per permettere a TMap.asm di azzerare
;*		tutta la section BSS
;*
;****************************************************************************

	include 'TMap.i'


	section	__MERGED,BSS

		xdef	LastBSSdata

LastBSSdata	ds.l	1	;Definisce l'ultimo puntatore della section
