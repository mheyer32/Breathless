                section .text,code
                xref c2p1x1_8_c5_bm_040
                xref c2p2x1_8_c5_bm
                xref c2p2x2_8_c5_bm

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

; Mode (a1) bit 0: double x, bit 1: double y
c2p8_init::
        move.l  a0,chunky
        move.l  d2,cwidth
        move.l  d3,cheight

        move.l  a1,d0
        btst.l  #0,d0
        beq     .nodblx
        add.l   d2,d2
.nodblx:
        btst.l  #1,d0
        beq     .nodbly
        add.l   d3,d3
.nodbly:
        move.l  #320,d0
        move.l  #200,d1

        sub.l   d2,d0
        sub.l   d3,d1
        lsr.l   #1,d0
        lsr.l   #1,d1
        move.l  d0,sxofs
        move.l  d1,syofs
        move.l  a1,d0
        and.w   #3,d0
        move.l  .c2pfuncs(pc,d0.w*4),c2pfunc
        rts
.c2pfuncs:
        dc.l    c2p1x1_8_c5_bm_040      ; 1x1
        dc.l    c2p2x1_8_c5_bm          ; 2x1
        dc.l    c2p8_1x2                ; 1x2
        dc.l    c2p2x2_8_c5_bm          ; 2x2

c2p8_1x2:
        ; HACK: Double BytesPerRow per row (and restore)
        move.l  a1,a2
        lsl.l   (a2)
        jsr     c2p1x1_8_c5_bm_040
        lsr.r   (a2)
        rts

; void c2p8_go(register __a0 PLANEPTR *planes, // pointer to planes
;		);
c2p8_go::
        movem.l d2-d3/a2,-(sp)
        lea     -8(a0),a1              ; Move offset to bitmap
        movem.l cwidth(pc),d0-d3/a0/a2
        jsr     (a2)
        movem.l (sp)+,d2-d3/a2
        rts

c2p8_waitblitter::
        rts

        ; Keep in order of arguments for c2p routine
        cnop    0,4
cwidth  ds.l    1
cheight ds.l    1
sxofs   ds.l    1
syofs   ds.l    1
chunky  ds.l    1
c2pfunc ds.l    1
