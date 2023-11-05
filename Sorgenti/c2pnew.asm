                section .text,code
                xref c2p2x1_8_c5_bm

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

; 160x100
;  D0 80000000   D1 40000000   D2 000000A0   D3 00000064
;  D4 00000000   D5 00006A08   D6 00016408   D7 00000140
;  A0 10099B78   A1 00000000   A2 1001E99C   A3 1000499C
;  A4 100AA0E4   A5 10089E96   A6 100A957C   A7 10099AE4

c2p8_init::
        move.l  a0,chunky
        move.l  d2,cwidth
        move.l  d3,cheight
        rts

; void c2p8_go(register __a0 PLANEPTR *planes, // pointer to planes
;		);
c2p8_go::
        movem.l d2-d3,-(sp)
        lea     -8(a0),a1              ; Move offset to bitmap
        movem.l cwidth(pc),d0/d1/a0
        move.w  #320,d2
        move.w  #200,d3
        sub.w   d0,d2
        sub.w   d1,d3
        lsr.w   #1,d2
        lsr.w   #1,d3
        bsr     c2p1x1_8_c5_bm_040
        movem.l (sp)+,d2-d3
        rts

c2p8_waitblitter::
        rts

        cnop    0,4
cwidth  ds.l    1
cheight ds.l    1
chunky  ds.l    1
