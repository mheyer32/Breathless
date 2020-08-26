* An example of how to use Copper-Interrupt bit to wait for specified line
* Also AGA-compatible init


* For use with CIA-version of the Player 6.1A

	section	"CIA-Example",code

	movem.l	d0-a6,-(sp)
	move	$dff002,-(sp)		;Old DMA
	lea	gfxname(pc),a1		;Open graphics.library
	moveq	#0,d0
	move.l	4.w,a6
	jsr	-$228(a6)
	move.l	d0,a6
	move.l	34(a6),-(sp)		;Old view
	move.l	a6,-(sp)
	sub.l	a1,a1
	jsr	-$de(a6)		;LoadView
	jsr	-$10e(a6)		;WaitTOF
	jsr	-$10e(a6)		;WaitTOF

	lea	$dff000,a6
	move	#$7ff,$96(a6)		;Disable DMAs
	move	#%1000001111000000,$96(a6) ;Master,Copper,Blitter,Bitplanes
	move	$1c(a6),-(sp)		;Old IRQ
	move	#$7fff,$9a(a6)		;Disable IRQs
	move	#$e000,$9a(a6)		;Master and lev6
					;NO COPPER-IRQ!
	moveq	#0,d0
	move	d0,$106(a6)		;Disable AGA/ECS-stuff
	move	d0,$1fc(a6)

;	Call P61_Init here!

	move.l	#copper,$80(a6)

wait	move	$1e(a6),d0		;Wait for Copper-bit in INTREQR
	and.l	#$10,d0
	beq.b	wait

	move	#$10,$9c(a6)		;Clear the bit

	move	#$f00,$180(a6)		;Some funny colors...

; Do your stuff here!

	move	#3,$180(a6)

	btst	#6,$bfe001
	bne	wait
	
exit	btst	#14,2(a6)		;Wait for blitter to finish
	bne.b	exit

; Call P61_End here!

	move	#$7fff,$9a(a6)		;Restore system status
	move	#$7ff,$96(a6)

	move	(sp)+,d7		;Old IRQs

	move.l	(sp)+,a6
	move.l	(sp)+,a1
	jsr	-$de(a6)		;Old view
	move.l	38(a6),d3		;Old Copper1
	move.l	a6,a1
	move.l	4.w,a6
	jsr	-$19e(a6)		;CLOSE graphics.library

	lea	$dff000,a6
	move.l	d3,$80(a6)		;Set old Copper
	move	d3,$88(a6)		;Trigger

	or	#$8000,d7
	move	d7,$9a(a6)		;Old IRQs

	move	(sp)+,d7
	or	#$8000,d7
	move	d7,$96(a6)		;Old DMAs
	movem.l	(sp)+,d0-a6
	moveq	#0,d0			;No error code
	rts

gfxname	dc.b	`graphics.library`,0
	even

	section	"Copper",data_c
copper	dc	$100,$0200
	dc	$180,3
	dc	$800f,-2		;The line to wait to
	dc	$9c,$8010		;Set Copper-bit in INTREQ
	dc.l	-2
