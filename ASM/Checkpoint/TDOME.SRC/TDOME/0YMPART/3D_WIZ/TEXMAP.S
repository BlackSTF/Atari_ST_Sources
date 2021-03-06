;------------------------------------------------------------
                move.l  #zero_base,D0
                clr.w   D0
                lea     c2p_adr,A4
                move.l  D0,(A4)+        ;c2p_adr1
                add.l   #65536,D0
                move.l  D0,(A4)+        ;c2p_adr2
                add.l   #65536,D0

                add.l   #65536,D0       ; 64k space before texture
                move.l  D0,texture_adr

; Init texturemapper
                bsr     init_polydiv_table2

                movea.l texture_adr(PC),A1
                bsr     init_texture
;------------------------------------------------------------

divtable_polygon:DS.W 512

polydiv_table2_neg:DS.W 1024
polydiv_table2: DS.W 1024
polydiv_table2_end:DS.W 1


                DS.L 65536/4    ;; FOR A 65536 BOUNDARY!!
zero_base:
c2p_table32:    DS.L 65536/4    ;C2P
c2p_table10:    DS.L 65536/4    ;C2P

                DS.B 256*256
***** TEXTURE
                DS.B 256*256    ;128*128  but stored as 256*128

                DS.B 256*256


;-------------------------------------------------------------------------------
init_texture:   >PART
                moveq   #128-1,D7
ity:
                movem.l A0-A1,-(SP)
                moveq   #128-1,D6
itx:
                move.b  (A0)+,D4
                lsl.b   #2,D4
*      move.b  D4,128(A1)
                move.b  D4,(A1)+
                dbra    D6,itx
                movem.l (SP)+,A0-A1

                lea     128(A0),A0
                lea     256(A1),A1

                dbra    D7,ity
                rts
                ENDPART
;-------------------------------------------------------------------------------
init_divtable_polygon:>PART

*   DC.L $4AFC4E71

                lea     divtable_polygon,A0
                move.w  #$7FFF,(A0)+    ; 0
                moveq   #1,D0
                move.w  #512-1-1,D7
idp:
                move.l  #$00007FFF,D5
                divu    D0,D5
                move.w  D5,(A0)+
                addq.w  #1,D0
                dbra    D7,idp
                rts
                ENDPART
;-------------------------------------------------------------------------------
init_polydiv_table2:>PART

*    DC.L $4AFC4E71

                lea     polydiv_table2_neg,A0
                lea     polydiv_table2_end+2,A1
                movea.l #EXT_*EXT_,A2
                move.w  #-1024,D6
                move.w  #1024-1,D7
ipdt2:
                move.l  A2,D0
                divs    D6,D0
                move.w  D0,(A0)+
                neg.w   D0
                move.w  D0,-(A1)
                addq.w  #1,D6
                dbra    D7,ipdt2
                rts
                ENDPART
;-------------------------------------------------------------------------------

TRI_MAP:        >PART
;;;;;;;##### triangle texture mapping routine ...
; A1 A2 A3  points
; struct point { short y; short x; short u; short v; }
                RSSET 0
y:              RS.W 1
x:              RS.W 1
u:              RS.W 1
v:              RS.W 1

EXT_            SET 128
EF_             SET 7

                move.w  (A2),D0         ;y2
                cmp.w   (A1),D0         ;y1
                bge.s   y1_lt_y2
                exg     A1,A2           ; Tausch wenn y2<y1
y1_lt_y2:
                move.w  (A3),D0         ;y3
                cmp.w   (A1),D0         ;y1
                bge.s   y1_lt_y3
                exg     A1,A3           ; Tausch wenn y3<y1
y1_lt_y3:
                move.w  (A3),D0         ;y3
                cmp.w   (A2),D0         ;y2
                bge.s   y2_lt_y3
                exg     A2,A3           ; Tausch wenn y3<y2
y2_lt_y3:
                move.w  (A3),D2         ;y3       = max_y
                sub.w   (A1),D2         ;y1       = min_y
                beq     no_polygon

                move.w  D2,delta_y      ;; y3 - y1  = max_y_size

                lea     polydiv_table2,A4

                move.w  (A2),D0         ; y2
                sub.w   (A1),D0         ;-y1
                move.w  D0,dy1

                move.w  (A3),D0         ; y3
                sub.w   (A2),D0         ;-y2
                move.w  D0,dy2


                move.w  (A2),D1         ; y2
                sub.w   (A1),D1         ;-y1

*   muls    #EXT_,D1        ; EXT
*   divs    D2,D1           ; / delta_y
*   move.w  D1,y_faktor

; NEW:
;  move.l  #EXT_*EXT_,D7
;  divu    D2,D7
;  mulu    D7,D1
                add.w   D2,D2
                muls    0(A4,D2.w),D1   ; polydiv_table2
                asr.l   #EF_,D1
                move.w  D1,y_faktor

; x3 - x1
                move.w  x(A3),D0        ;x3
                sub.w   x(A1),D0        ;x1
                muls    D1,D0           ; (y2-y1)*EXT/(y3-y1) * (x3-x1)

; x1 - x2
                move.w  x(A1),D1        ;x1
                sub.w   x(A2),D1        ;x2
                muls    #EXT_,D1        ; EXT

                add.l   D1,D0
                asr.l   #EF_,D0         ; <<EXT

*      tst.w   D0
*      beq     no_polygon
                tst.w   D0
                bne.s   xf_nz
                moveq   #1,D0
xf_nz:
                move.w  D0,x_faktor
                ENDPART
;;;;;;;;;;
                >PART
                move.w  u(A3),D1        ; u3
                sub.w   u(A1),D1        ;-u1
                muls    y_faktor(PC),D1

                move.w  u(A1),D5        ; u1
                sub.w   u(A2),D5        ;-u2
                muls    #EXT_,D5        ; EXT
                add.l   D1,D5

*   divs    x_faktor(PC),D5
*   ext.l   D5
*   muls    #65536/EXT_,D5  ;auf 2^16

; NEW:
;  move.l  #EXT_*EXT_,D7
;  divs    x_faktor(PC),D7
                move.w  x_faktor(PC),D7
                add.w   D7,D7
                move.w  0(A4,D7.w),D7   ; polydiv_table2

                muls    D7,D5
                asr.l   #5,D5

;;;;;;;;;;
                move.w  v(A3),D1        ; v3
                sub.w   v(A1),D1        ;-v1
                muls    y_faktor(PC),D1

                move.w  v(A1),D4        ; v1
                sub.w   v(A2),D4        ;-v2
                muls    #EXT_,D4        ; EXT
                add.l   D1,D4

*   divs    x_faktor(PC),D4
*   ext.l   D4
*   muls    #65536/EXT_,D4  ;auf 2^16

; NEW:
                muls    D7,D4
                asr.l   #5,D4
;;;;;;;;;;

                move.w  x_faktor(PC),D0
                bpl.s   pos_dx
                neg.w   D0
pos_dx:
                moveq   #0,D1           ;U
                moveq   #0,D2           ;V

;;          lea     uv_x_offsets,A6

                addq.w  #1,D0           ******

                lea     render_x_code+2(PC),A6
calc_uv_x_offsets:
                swap    D1
                swap    D2
                move.b  D2,(A6)+        ;V
                move.b  D1,(A6)+        ;U
                addq.l  #2,A6           ;opcode �berspringen!

                swap    D1
                swap    D2
                add.l   D5,D1           ;U_INC
                add.l   D4,D2           ;V_INC
                dbra    D0,calc_uv_x_offsets

                lea     colorram,A6
                move.w  (A1),D0         ;y1
                muls    #CRAM_X,D0
                adda.l  D0,A6

                move.w  x_faktor(PC),D0
                bmi     umgekehrt

                ENDPART

;       A1
;       /\
;      /  \
;     /   _\ A3
;    / __/
;   /_/
;  //
; A2
                >PART           ;*DONE*
                move.w  dy1(PC),D7
                beq     y1_equal_y2
                subq.w  #1,D7

*    DC.L $4AFC4E71

                movem.l A2-A3,-(SP)     ; p2  p3  sichern

                move.w  x(A1),D0
                swap    D0
                clr.w   D0              ;x_links
                move.l  D0,D1           ;x_rechts

                move.w  u(A1),D2
                swap    D2
                clr.w   D2              ;U

                move.w  v(A1),D3
                swap    D3
                clr.w   D3              ;V
; X Steigung Links:
                move.w  x(A2),D4
                sub.w   x(A1),D4        ;x2 - x1
*   move.w  dy1(PC),D6      ;y2 - y1
*   move.l  #$00007FFF,D5
*   divu    D6,D5           ;1/(y2-y1)
*   muls    D5,D4           ;(x2-x1) / (y2-y1)
*   add.l   D4,D4

                lea     divtable_polygon,A4
                move.w  dy1(PC),D6      ;y2 - y1
                add.w   D6,D6
                add.w   D4,D4
                move.w  0(A4,D6.w),D5   ; 1/(y2-y1)
                muls    D5,D4           ; (x2-x1) / (y2-y1)

                movea.l D4,A0           ;x_links_increment
; U Steigung:
                move.w  u(A2),D4
                sub.w   u(A1),D4        ;U2 - U1
                muls    D5,D4           ;(U2-U1) / (y2-y1)
                add.l   D4,D4
; movea.l D4,A2           ;U_increment
                move.l  D4,-(SP)        ;U_INC

; V Steigung:
                move.w  v(A2),D4
                sub.w   v(A1),D4        ;V2 - V1
                muls    D5,D4           ;(V2-V1) / (y2-y1)
                add.l   D4,D4
                move.l  D4,-(SP)        ;A3      V_INC

; X Steigung Rechts:
                move.w  x(A3),D4
                sub.w   x(A1),D4        ;x3 - x1
*    move.w  delta_y(PC),D6
*    move.l  #$00007FFF,D5
*    divu    D6,D5           ;1/(y3-y1)
*    muls    D5,D4           ;(x3-x1) / (y3-y1)
*    add.l   D4,D4

                lea     divtable_polygon,A4
                move.w  delta_y(PC),D6
                add.w   D6,D6
                add.w   D4,D4
                muls    0(A4,D6.w),D4   ;(x3-x1) / (y3-y1)

                movea.l D4,A1           ;x_rechts_increment

                movea.l (SP)+,A3        ;V_INC
                movea.l (SP)+,A2        ;U_INC

                bsr     RENDER_TRI

                movem.l (SP)+,A2-A3     ;p2  p3  wiederholen

                move.w  dy2(PC),D7
FIX0:
**  subq.w  #1,D7
**  bmi     no_poly_y23     ; y2 = y3

;; Strecke P2 --> P3
                move.w  x(A2),D0        ;x2
                swap    D0
                clr.w   D0              ;x_links

                move.w  u(A2),D2        ;U
                swap    D2
                clr.w   D2

                move.w  v(A2),D3        ;V
                swap    D3
                clr.w   D3

                move.w  x(A3),D4
                sub.w   x(A2),D4        ;x3 - x2
*    move.w  dy2(PC),D6      ;y3 - y2
*    move.l  #$00007FFF,D5
*    divu    D6,D5           ;1/(y3-y2)
*    muls    D5,D4           ;(x3-x2) / (y3-y2)
*    add.l   D4,D4

                lea     divtable_polygon,A4
                move.w  dy2(PC),D6      ;y3 - y2
                add.w   D6,D6
                add.w   D4,D4
                move.w  0(A4,D6.w),D5   ;1/(y3-y2)
                muls    D5,D4           ;(x3-x2) / (y3-y2)


                movea.l D4,A0           ;x_links_increment

                move.w  u(A3),D4
                sub.w   u(A2),D4        ;u3 - u2
                muls    D5,D4           ;(u3-u2) / (y3-y2)
                add.l   D4,D4
;         movea.l D4,A2           ;U increment
                move.l  D4,-(SP)        ;U_INC

                move.w  v(A3),D4
                sub.w   v(A2),D4        ;v3 - v2
                muls    D5,D4           ;(v3-v2) / (y3-y2)
                add.l   D4,D4
                movea.l D4,A3           ;V increment

                movea.l (SP)+,A2        ;U_INC

                bsr     RENDER_TRI
no_poly_y23:
                rts
                ENDPART
y1_equal_y2:    >PART           ;*DONE*
;A2______A1
;  \    /
;   \  /
;    \/
;    A3

                move.w  x(A2),D0        ;x_links
                swap    D0
                clr.w   D0

                move.w  x(A1),D1        ;x_rechts
                swap    D1
                clr.w   D1

                move.w  u(A2),D2
                swap    D2
                clr.w   D2              ;U

                move.w  v(A2),D3
                swap    D3
                clr.w   D3              ;V
; X Steigung Links:
                move.w  x(A3),D4
                sub.w   x(A2),D4        ;x3 - x2
*   move.w  delta_y(PC),D6  ;y3 - y2   = delta_y
*   move.l  #$00007FFF,D5
*   divu    D6,D5           ;1/(y3-y2)
*   muls    D5,D4           ;(x3-x2) / (y3-y2)
*   add.l   D4,D4
*   movea.l D4,A0           ;x_links_increment

                lea     divtable_polygon,A4
                move.w  delta_y(PC),D6  ;y3 - y2   = delta_y
                add.w   D6,D6
                add.w   D4,D4
                move.w  0(A4,D6.w),D5   ;1/(y3-y2)
                muls    D5,D4           ;(x3-x2) / (y3-y2)
                movea.l D4,A0           ;x_links_increment

; U Steigung:
                move.w  u(A3),D4
                sub.w   u(A2),D4        ;U3 - U2
                muls    D5,D4           ;(U3-U2) / (y3-y2)
                add.l   D4,D4
;         movea.l D4,A2           ;U_increment
                move.l  D4,-(SP)        ;U_INC

; V Steigung:
                move.w  v(A3),D4
                sub.w   v(A2),D4        ;V3 - V2
                muls    D5,D4           ;(V3-V2) / (y3-y2)
                add.l   D4,D4
                move.l  D4,-(SP)        ;A3      V_INC

; X Steigung Rechts:
                move.w  x(A3),D4
                sub.w   x(A1),D4        ;x3 - x1
                move.w  delta_y(PC),D6
                move.l  #$00007FFF,D5
                divu    D6,D5           ;1/(y3-y1)
                muls    D5,D4           ;(x3-x1) / (y3-y1)
                add.l   D4,D4
                movea.l D4,A1           ;x_rechts_increment

                movea.l (SP)+,A3        ;V_INC
                movea.l (SP)+,A2        ;U_INC

                move.w  delta_y(PC),D7
                subq.w  #1,D7

                bsr     RENDER_TRI
                rts
                ENDPART


umgekehrt:
;       A1
;       /\
;      /  \
;     /   _\ A2
;    / __/
;   /_/
;  //
; A3
                >PART
                move.w  dy1(PC),D7
                beq     y1_equal_y2_U
                subq.w  #1,D7

                movem.l A2-A3,-(SP)     ; p2  p3  sichern

                move.w  x(A1),D0
                swap    D0
                clr.w   D0              ;x_links
                move.l  D0,D1           ;x_rechts

                move.w  u(A1),D2
                swap    D2
                clr.w   D2              ;U

                move.w  v(A1),D3
                swap    D3
                clr.w   D3              ;V
; X Steigung Links:
                move.w  x(A3),D4
                sub.w   x(A1),D4        ;x3 - x1
*  move.w  delta_y(PC),D6  ;y3 - y1   = delta_y
*  move.l  #$00007FFF,D5
*  divu    D6,D5           ;1/(y3-y1)
*  muls    D5,D4           ;(x3-x1) / (y3-y1)
*  add.l   D4,D4

                lea     divtable_polygon,A4
                move.w  delta_y(PC),D6  ;y3 - y1   = delta_y
                add.w   D6,D6
                add.w   D4,D4
                move.w  0(A4,D6.w),D5   ;1/(y3-y1)
                muls    D5,D4           ;(x3-x1) / (y3-y1)

                movea.l D4,A0           ;x_links_increment
; U Steigung:
                move.w  u(A3),D4
                sub.w   u(A1),D4        ;U3 - U1
                muls    D5,D4           ;(U3-U1) / (y3-y1)
                add.l   D4,D4
;         movea.l D4,A2           ;U_increment
                move.l  D4,-(SP)        ;U_INC

; V Steigung:
                move.w  v(A3),D4
                sub.w   v(A1),D4        ;V3 - V1
                muls    D5,D4           ;(V3-V1) / (y3-y1)
                add.l   D4,D4
                move.l  D4,-(SP)        ;A3      V_INC

; X Steigung Rechts:
                move.w  x(A2),D4
                sub.w   x(A1),D4        ;x2 - x1
*  move.w  dy1(PC),D6
*  move.l  #$00007FFF,D5
*  divu    D6,D5           ;1/(y2-y1)
*  muls    D5,D4           ;(x2-x1) / (y2-y1)
*  add.l   D4,D4

                lea     divtable_polygon,A4
                move.w  dy1(PC),D6
                add.w   D6,D6
                add.w   D4,D4
                move.w  0(A4,D6.w),D5   ;1/(y2-y1)
                muls    D5,D4           ;(x2-x1) / (y2-y1)

                movea.l D4,A1           ;x_rechts_increment

                movea.l (SP)+,A3        ;V_INC
                movea.l (SP)+,A2        ;U_INC

                bsr     RENDER_TRI

                movem.l (SP)+,A1/A4     ;p2  p3  wiederholen
; A1 p2   A4 p3
                move.w  dy2(PC),D7
FIX1:
** beq     no_poly_y23_U   ; y2 = y3
** subq.w  #1,D7

;; Strecke A2 --> A3  RECHTS!
                move.w  x(A1),D1        ;x2        A2
                swap    D1
                clr.w   D1              ;x_rechts

                move.w  x(A4),D4        ;          A3
                sub.w   x(A1),D4        ;x3 - x2   A2
*  move.w  dy2(PC),D6      ;y3 - y2
*  move.l  #$00007FFF,D5
*  divu    D6,D5           ;1/(y3-y2)
*  muls    D5,D4           ;(x3-x2) / (y3-y2)
*  add.l   D4,D4

                lea     divtable_polygon,A4
                move.w  dy2(PC),D6      ;y3 - y2
                add.w   D6,D6
                add.w   D4,D4
                move.w  0(A4,D6.w),D5   ;1/(y3-y2)
                muls    D5,D4

                movea.l D4,A1           ;x_rechts_increment

                bsr     RENDER_TRI
no_poly_y23_U:
                rts
                ENDPART
y1_equal_y2_U:  >PART
;A1______A2
;  \    /
;   \  /
;    \/
;    A3

                move.w  x(A1),D0
                swap    D0
                clr.w   D0              ;x_links

                move.w  x(A2),D1
                swap    D1
                clr.w   D1              ;x_rechts

                move.w  u(A1),D2
                swap    D2
                clr.w   D2              ;U

                move.w  v(A1),D3
                swap    D3
                clr.w   D3              ;V
; X Steigung Links:
                move.w  x(A3),D4
                sub.w   x(A1),D4        ;x3 - x1
*  move.w  delta_y(PC),D6  ;y3 - y1   = delta_y
*  move.l  #$00007FFF,D5
*  divu    D6,D5           ;1/(y3-y1)
*  muls    D5,D4           ;(x3-x1) / (y3-y1)
*  add.l   D4,D4

                lea     divtable_polygon,A4
                move.w  delta_y(PC),D6  ;y3 - y1   = delta_y
                add.w   D6,D6
                add.w   D4,D4
                move.w  0(A4,D6.w),D5   ;1/(y3-y1)
                muls    D5,D4           ;(x3-x1) / (y3-y1)

                movea.l D4,A0           ;x_links_increment
; U Steigung:
                move.w  u(A3),D4
                sub.w   u(A1),D4        ;U3 - U1
                muls    D5,D4           ;(U3-U1) / (y3-y1)
                add.l   D4,D4
;   movea.l D4,A2           ;U_increment
                move.l  D4,-(SP)        ;U_INC

; V Steigung:
                move.w  v(A3),D4
                sub.w   v(A1),D4        ;V3 - V1
                muls    D5,D4           ;(V3-V1) / (y3-y1)
                add.l   D4,D4
                move.l  D4,-(SP)        ;A3      V_INC

; X Steigung Rechts:
                move.w  x(A3),D4
                sub.w   x(A2),D4        ;x3 - x2
                muls    D5,D4           ;(x3-x2) / delta_y
                add.l   D4,D4
                movea.l D4,A1           ;x_rechts_increment

                movea.l (SP)+,A3        ;V_INC
                movea.l (SP)+,A2        ;U_INC

                move.w  delta_y(PC),D7
                subq.w  #1,D7

                bsr     RENDER_TRI
                rts
                ENDPART

no_polygon:
                rts

RENDER_TRI:     >PART
; DC.L $4AFC4E71

                add.l   #$00010000,D1   ; x_rechts++
RT_loop:
                move.l  D0,D4           ;x_links
                move.l  D1,D5           ;x_rechts

                swap    D4
                swap    D5

                sub.w   D4,D5           ;delta_X
                bmi.s   no_fill_dy1

*    bpl.s   delta_x_ok
*    DC.L $4AFC4E71
*    bra.s   no_fill_dy1

delta_x_ok:
                pea     (A6)            ; save scanline pos.
                adda.w  D4,A6           ; X_START = x_links

                move.l  D3,D4           ;V
                clr.w   D4
                swap    D4
                lsl.l   #8,D4

                swap    D2              ;U
                move.b  D2,D4           ;V*256 + U
                swap    D2

;;; and.w   #$7F7F,D4
                add.l   texture_adr(PC),D4
                movea.l D4,A5

                lea     render_x_code(PC),A4
*   lea     normal_draw(PC),A4

                add.w   D5,D5
                add.w   D5,D5
                adda.w  D5,A4

                move.w  (A4),-(SP)      ; NUR ZUM TESTEN !!
                move.w  #$4E75,(A4)     ;RTS
                bsr     render_x_code
*   bsr     normal_draw

                move.w  (SP)+,(A4)      ; NUR ZUM TESTEN !!

                movea.l (SP)+,A6        ;restore scanline pos.
no_fill_dy1:
                add.l   A0,D0           ;x_links  inc
                add.l   A1,D1           ;x_rechts inc
                add.l   A2,D2           ;U Inc
                add.l   A3,D3           ;V Inc
                lea     CRAM_X(A6),A6   ;next line in colorbuffer

                dbra    D7,RT_loop

                sub.l   #$00010000,D1   ; x_rechts-- (restore)

                rts

                REPT 100
                rts
                rts
                ENDR

render_x_code:
                REPT 160
                move.b  0(A5),(A6)+     ;1CED 0000
                ENDR
                REPT 100
                rts
                rts
                ENDR

                REPT 100
                rts
                rts
                ENDR
normal_draw:
                REPT 160
                move.b  #6*4,(A6)+
                ENDR
                rts
                rts

                ENDPART

delta_y:        DC.W 0
dy1:            DC.W 0          ;y2-y1
dy2:            DC.W 0          ;y3-y2

x_faktor:       DC.W 0
y_faktor:       DC.W 0
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------


