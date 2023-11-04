                xref c2p1x1_8_c5_040_init
                xref c2p1x1_8_c5_040

; void __asm c2p8_init (register __a0 UBYTE *chunky,	// pointer to chunky data
;			register __a1 ULONG mode,	// conversion mode
;			register __d0 ULONG signals1,	// 1 << sigbit1
;			register __d1 ULONG signals2,	// 1 << sigbit2
;			register __d2 ULONG width,      // window width
;			register __d3 ULONG height,     // window height
;			register __d4 ULONG offset,     // byte offset into plane
;			register __d5 UBYTE *buff2,	// Chip buffer width*height
;			register __d6 UBYTE *buff3,	// Chip buffer width*height
;			register __d7 ULONG scrwidth,   // screen width
;			register __a3 struct GfxBase *GfxBase);

; 320x200
;  D0 80000000   D1 40000000   D2 00000140   D3 000000C8
;  D4 00000000   D5 00006A08   D6 00016408   D7 00000140
;  A0 10099B70   A1 00000000   A2 1001E99C   A3 1000499C
;  A4 100AA0DC   A5 10089E8E   A6 100A9574   A7 10099ADC

c2p8_init::
        tst.l   d2
        beq     .out
        tst.l   d3
        beq     .out
        movem.l	d2-d7/a2-a6,-(sp)

        lea     chunky(pc),a2
        move.l  a0,(a2)

        move.l  d2,d0
        move.l  d3,d1
        moveq   #0,d2
        moveq   #0,d3
        move.l  d0,d4
        lsr.l   #3,d4
        move.l  d0,d5
        mulu.w  d1,d5
        lsr.l   #3,d5
        move.l  d0,d6

        bsr     c2p1x1_8_c5_040_init
        movem.l	(sp)+,d2-d7/a2-a6
.out:
        rts

; void c2p8_go(register __a0 PLANEPTR *planes, // pointer to planes
;		);
c2p8_go::
        movem.l d0-d7/a0-a6,-(sp)
        move.l  (a0),a1
        move.l  chunky(pc),a0
        bsr     c2p1x1_8_c5_040
        movem.l (sp)+,d0-d7/a0-a6
        rts

c2p8_waitblitter::
        rts

        cnop    0,4
chunky  ds.l    1
