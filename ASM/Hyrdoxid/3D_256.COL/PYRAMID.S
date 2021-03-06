nbpts=	3

 	LEA.L 	PILE,SP
	CLR.L	-(SP)
	MOVE.W	#$20,-(SP)
	TRAP	#1
	ADDQ.L	#2,SP
	CLR.B	$484.W
	MOVE.B	#18,$FFFFFC02.W
	MOVE.B	#21,$FFFFFC02.W
	move.l	$70.w,OLD_VBL
	move.l	#NEW_VBL,$70.w
	BSR	INITS
 	BSR	CLS
	BSR	CLR_REGISTERS
	BSR	MAKE_YTABLE
	BSR	CLR_REGISTERS
	bsr	GEN_CODE
	BSR	PREP_TAB
	clr	X_ANGLE
	clr	Y_ANGLE
	clr	Z_ANGLE
	MOVE	#192+384+384,ADD
	MOVE.L	#$44000044,$FFFF9804
	MOVE.L	#$66000066,$FFFF9808
	MOVE.L	#$44000044,$FFFF980C
	MOVE.L	#$88000088,$FFFF9810
	MOVE.L	#$66000066,$FFFF9814
	MOVE.L	#$66000066,$FFFF9818
	MOVE.L	#$66000066,$FFFF981C
LOOP
	BSR	VBL
	bsr	test_face
	MOVE.L	#$44440044,$FFFF9800
	SUBQ	#1,ADD
	CMPI	#192,ADD
	BNE.S	.NO_ADD
	MOVE	#192+384*2,ADD
.NO_ADD
	BSR	EFFA_PYRAMID
	BSR	MAKE_PYRAMID
	BSR	TRACE_PYRAMID
	MOVE.L	AFFECR,A1
	MOVE.L	WORKECR,A2
	MOVE.L	A2,AFFECR
	MOVE.L	A1,WORKECR
	SUB.L	#384*50*2+384,A1
	MOVE.L	A1,WORKECR2
	move.b 	affecr+1,$ffff8201.w
	move.b 	affecr+2,$ffff8203.w
	move.b 	affecr+3,$ffff820d.w
	CMPI.B	#56,$FFFFC02
	bne.s	no_alt
	move.l	#$ff,$ffff9800
no_alt
	CMPI.B	#57,$FFFFC02
	BNE	LOOP
	BRA	SORTIE
*********************
MAKE_PYRAMID
	ADD.W	#4,X_ANGLE
	CMPI.W	#720,X_ANGLE
	BLT.S	.NO_STOP
	CLR.W	X_ANGLE
.NO_STOP
	ADD.W	#4,Y_ANGLE
	CMPI.W	#720,Y_ANGLE
	BLT.S	.NO_STOP2 
	CLR.W	Y_ANGLE
.NO_STOP2
	BSR	TRIGO
	LEA	XE1_PYRAMIDE,A0
	LEA	DX,A5
	LEA	DY,A4
	MOVE	#3,D0
	MOVE.L	#$3111,D6		;cache on
	MOVEC.L	D6,CACR
	MOVEQ.W	#9,D6
LOOP_TRIGO_PYRAMID
	MOVEM.L	D0/A1-A2,-(SP)		
	MOVE.W	(A0)+,D0
	MOVE.W	(A0)+,D1
	MOVE.W	(A0)+,D2
	LEA	XDEP,A3
	MOVEM.W	(A3)+,D3-D5
	ASL.L	D6,D3		;xdep*512
	ASL.L	D6,D4		;ydep*512
	ASL.L	D6,D5		;zdep*512
	MOVE.L	D3,A1
	MOVE.L	D4,A2
	MOVE.L	D5,A3

	LEA	VAR_3D,A6
	MOVE.W	D0,D3
	MOVE.W	D1,D4
	MOVE.W	D2,D5

	MULS	(A6)+,D3		;d3=c*xe*512
	MULS	(A6)+,D4		;d4=f*ye*512
	MULS	(A6)+,D5		;d5=i*ze*512
	ADD.L	D4,D5		;+f*ye*512
	ADD.L	D3,D5		;+c*xe*512
	ADD.L	A3,D5		;+zdep*512
	ASR.L	d6,D5
	
	MOVE.W	#512,D7
	SUB.W	D5,D7		;d7=512*q
				;d7=512*(1-new_ze/z_pt_fuite)
	MOVE.W	D0,D3		;d3=xe
	MOVE.W	D1,D4		;d4=ye
	MOVE.W	D2,D5		;d5=ze

	MULS	(A6)+,D3		;d3=a*xe*512
	MULS	(A6)+,D4		;d4=d*ye*512
	MULS	(A6)+,D5		;d5=g*ze*512
	ADD.L	D4,D5		
	ADD.L	D3,D5
	ADD.L	A1,D5
	DIVS	D7,D5		;d5=new_xe/q

	MULS	(A6)+,D0		;d0=b*xe*512
	MULS	(A6)+,D1		;d1=e*ye*512
	MULS	(A6)+,D2		;d2=h*ze*512
	ADD.L	D0,D1		
	ADD.L	D1,D2
	ADD.L	A2,D2
	DIVS	D7,D2		;d2=new_ye/q
	ADD.W	ADD,D5	
	ADD.W	#120+50,D2
	MOVEM.L	(SP)+,D0/A1-A2
	MOVE.W	D5,(A5)+
	MOVE.W	D2,(A4)+
	DBF	D0,LOOP_TRIGO_PYRAMID
	MOVE.L	#$2510,D0		;coupe cache
	MOVEC.L	D0,CACR
	RTS
***************************************************************************************************
***************************INITIALISATIONS*********************************************************
***************************************************************************************************
INITS
	MOVEC.L	CACR,D0			
	MOVE.L	D0,OLD_CACR
	MOVE.L	#$2510,D0		;coupe cache
	MOVEC.L	D0,CACR
	
	MOVE.W	#-1,-(SP)		
	MOVE.W	#88,-(SP)		
	TRAP	#14			
	ADDQ.L	#4,SP			
	MOVE.W	D0,OLDMODECODE	

	move.l	$44E.W,OLDXBIOS2
	
	MOVE.L	#XBIOS2,D0
	ANDI.L	#$FFFFFFFF-2,D0
	MOVE.L	D0,AFFECR

	MOVE.L	#XBIOS3,D0
	ANDI.L	#$FFFFFFFF-2,D0
	MOVE.L	D0,WORKECR
	SUB.L	#50*384*2,D0
	MOVE.L	D0,WORKECR2

	BSR	SYNCHRO
	BSR	VGA
	RTS
SYNCHRO:
	MOVE.L	AFFECR,D0
	MOVE.L	WORKECR,AFFECR
	MOVE.L	D0,WORKECR

	move.b AFFECR+1,$ffff8201.w
	move.b AFFECR+2,$ffff8203.w
	move.b AFFECR+3,$ffff820D.w
	RTS
VGA:
	MOVE	#192,$FFFF8210.W	;TAILLE EN MOT
	MOVE	#192,$FFFF820E.W	;TAILLE EN MOT
	MOVE	#16,$FFFF8266.W	;16=VGA & 256=TC
	MOVE	#254,$FFFF8282.W	;NBRE DE DEMI-LINES
	MOVE	#203-10,$FFFF8284.W	;FIN LIGNE HORIZONTALE
	MOVE	#47-10,$FFFF8286.W	;DEBUT LIGNE HORIZONTALE
	MOVE	#764,$FFFF8288.W	;FULL GAUCHE	
	MOVE	#157,$FFFF828A.W	;FULL DROIT
	MOVE	#216,$FFFF828C.W	;SYNCHRO HORIZONTAL
	MOVE	#625,$FFFF82A2.W	;NBRE DE CHAMPS
	MOVE	#613-78,$FFFF82A4.W	;FIN SCREEN
	MOVE	#47+78,$FFFF82A6.W	;DEBUT ECRAN
	MOVE	#85,$FFFF82A8.W	;FULL HAUT
	MOVE	#566,$FFFF82AA.W	;FULL BAS
	MOVE	#619,$FFFF82AC.W	;SYNCHRO VERTICAL
	MOVE	#385,$FFFF82C0.W	;????
	CLR	$FFFF82C2.W	;PIXEL OPTIONS	
	RTS
*******************************SOUS ROUTINES*****************************************
PREP_TAB:
	MOVEM	CLR,D0-D7/A0-A6
	LEA	TAB,A0
	MOVE.W	#25000,(A0)+

	MOVE.l	#25000-390,D0

	MOVEQ	#64-1,D1
.LOOP:
	MOVE.W	D0,(A0)+
	SUB.W	#390,D0
	DBF	D1,.LOOP
	RTS
TEST_FACE
	MOVE.W	DX,X1
	MOVE.W	DY,Y1
	MOVE.W	DX+4,X2
	MOVE.W	DY+4,Y2
	MOVE.W	DX+2,X3
	MOVE.W	DY+2,Y3
	BSR	CACHE
	BGT	NO_COLOR
	BSR	TEST_COL_PLAN1
NO_COLOR
	MOVE.W	DX,X1
	MOVE.W	DY,Y1
	MOVE.W	DX+6,X2
	MOVE.W	DY+6,Y2
	MOVE.W	DX+4,X3
	MOVE.W	DY+4,Y3
	BSR	CACHE
	BGT	NO_COLOR2
	BSR	TEST_COL_PLAN2
NO_COLOR2
	MOVE.W	DX,X1
	MOVE.W	DY,Y1
	MOVE.W	DX+2,X2
	MOVE.W	DY+2,Y2
	MOVE.W	DX+6,X3
	MOVE.W	DY+6,Y3
	BSR	CACHE
	BGT	NO_COLOR3
	BSR	TEST_COL_PLAN3
NO_COLOR3
	rts

TEST_COL_PLAN1
	neg	d3
	lea	TAB,a0
	LEA	$FFFF9804.W,A1
	MOVE.L	#$FF,D4

	MOVEQ	#9,D0
	MOVEC	D0,CACR

	MOVEQ	#64-1,D0
.LOOP:
	cmp2	(a0),d3
	bcc.s	.NO_COL1
	move.l	D4,(A1)
	RTS
.NO_COL1	SUBQ	#4,D4
	ADDQ	#2,A0
	DBF	D0,.LOOP

	MOVEQ	#0,D0
	MOVEC	D0,CACR	
	RTS

TEST_COL_PLAN2
	neg	d3
	lea	TAB,a0
	LEA	$FFFF9808.W,A1
	LEA	$FFFF980C.W,A2
	MOVE.L	#$FF,D4

	MOVEQ	#9,D0
	MOVEC	D0,CACR

	MOVEQ	#64-1,D0
.LOOP:
	cmp2	(a0),d3
	bcc.s	.NO_COLO1
	move.l	D4,(A1)
	move.l	D4,(A2)
	RTS
.NO_COLO1	ADDQ	#2,A0
	SUBQ	#4,D4
	DBF	D0,.LOOP

	MOVEQ	#0,D0
	MOVEC	D0,CACR	
	RTS
TEST_COL_PLAN3
	neg	d3
	lea	TAB,a0
	LEA	$FFFF9810.W,A1
	LEA	$FFFF9814.W,A2
	LEA	$FFFF9818.W,A3
	LEA	$FFFF981C.W,A4
	MOVE.L	#$FF,D4

	MOVEQ	#9,D0
	MOVEC	D0,CACR

	MOVEQ	#64-1,D0
.LOOP:
	cmp2	(a0),d3
	bcc.s	.NO_COLO1
	move.l	D4,(A1)
	move.l	D4,(A2)
	move.l	D4,(A3)
	move.l	D4,(A4)
	RTS
.NO_COLO1	ADDQ	#2,A0
	SUBQ	#4,D4
	DBF	D0,.LOOP

	MOVEQ	#0,D0
	MOVEC	D0,CACR	
	RTS
NEW_VBL
	addq	#1,$466.w
	rte

TRACE_PYRAMID
	MOVE.W	DX,X1
	MOVE.W	DY,Y1
	MOVE.W	DX+4,X2
	MOVE.W	DY+4,Y2
	MOVE.W	DX+2,X3
	MOVE.W	DY+2,Y3
	BSR	CACHE
	CMPI.L	#0,D3
	BGT	.NO_FACE
	MOVE.W	DY,PTS
	MOVE.W	DY+2,PTS+2
	MOVE.W	DY+4,PTS+4
	BSR	INIT_FACE
	MOVE.W	DX,CX1
	MOVE.W	DY,CY1
	MOVE.W	DX+2,CX2
	MOVE.W	DY+2,CY2
	BSR	TRACE_FACE
	MOVE.W	DX+4,CX1
	MOVE.W	DY+4,CY1
	MOVE.W	DX+2,CX2
	MOVE.W	DY+2,CY2
	BSR	TRACE_FACE
	MOVE.W	DX+4,CX1
	MOVE.W	DY+4,CY1
	MOVE.W	DX,CX2
	MOVE.W	DY,CY2
	BSR	TRACE_FACE
	MOVEQ	#0,D4
	BSR	REMPLI
.NO_FACE
	MOVE.W	DX,X1
	MOVE.W	DY,Y1
	MOVE.W	DX+6,X2
	MOVE.W	DY+6,Y2
	MOVE.W	DX+4,X3
	MOVE.W	DY+4,Y3
	BSR	CACHE
	CMPI.L	#0,D3
	BGT	.NO_FACE2
;face2
	MOVE.W	DY,PTS
	MOVE.W	DY+4,PTS+2
	MOVE.W	DY+6,PTS+4
	BSR	INIT_FACE
	MOVE.W	DX,CX1
	MOVE.W	DY,CY1
	MOVE.W	DX+4,CX2
	MOVE.W	DY+4,CY2
	BSR	TRACE_FACE
	MOVE.W	DX+4,CX1
	MOVE.W	DY+4,CY1
	MOVE.W	DX+6,CX2
	MOVE.W	DY+6,CY2
	BSR	TRACE_FACE
	MOVE.W	DX+6,CX1
	MOVE.W	DY+6,CY1
	MOVE.W	DX,CX2
	MOVE.W	DY,CY2
	BSR	TRACE_FACE
	MOVEQ	#2,D4
	BSR	REMPLI
.NO_FACE2
	MOVE.W	DX,X1
	MOVE.W	DY,Y1
	MOVE.W	DX+2,X2
	MOVE.W	DY+2,Y2
	MOVE.W	DX+6,X3
	MOVE.W	DY+6,Y3
	BSR	CACHE
	CMPI.L	#0,D3
	BGT	.NO_FACE3
;face3
	MOVE.W	DY,PTS
	MOVE.W	DY+6,PTS+2
	MOVE.W	DY+2,PTS+4
	BSR	INIT_FACE
	MOVE.W	DX,CX1
	MOVE.W	DY,CY1
	MOVE.W	DX+6,CX2
	MOVE.W	DY+6,CY2
	BSR	TRACE_FACE
	MOVE.W	DX+2,CX1
	MOVE.W	DY+2,CY1
	MOVE.W	DX+6,CX2
	MOVE.W	DY+6,CY2
	BSR	TRACE_FACE
	MOVE.W	DX+2,CX1
	MOVE.W	DY+2,CY1
	MOVE.W	DX,CX2
	MOVE.W	DY,CY2
	BSR	TRACE_FACE
	MOVEQ	#4,D4
	BSR	REMPLI
.NO_FACE3
	MOVE.W	DX+2,X1
	MOVE.W	DY+2,Y1
	MOVE.W	DX+6,X2
	MOVE.W	DY+6,Y2
	MOVE.W	DX+4,X2
	MOVE.W	DY+4,Y2
	BSR	CACHE
	CMPI.L	#0,D3
	BGT	.NO_FACE4
;face4
	MOVE.W	DY+2,PTS
	MOVE.W	DY+4,PTS+2
	MOVE.W	DY+6,PTS+4
	BSR	INIT_FACE
	MOVE.W	DX+2,CX1
	MOVE.W	DY+2,CY1
	MOVE.W	DX+4,CX2
	MOVE.W	DY+4,CY2
	BSR	TRACE_FACE
	MOVE.W	DX+4,CX1
	MOVE.W	DY+4,CY1
	MOVE.W	DX+6,CX2
	MOVE.W	DY+6,CY2
	BSR	TRACE_FACE
	MOVE.W	DX+6,CX1
	MOVE.W	DY+6,CY1
	MOVE.W	DX+2,CX2
	MOVE.W	DY+2,CY2
	BSR	TRACE_FACE
	MOVEQ	#2,D4
	BSR	REMPLI
.NO_FACE4
	rts
EFFA_PYRAMID
	move.l	WORKECR,a0
	lea	20*768(a0),a0
	moveq	#0,d1
	move	#204,d0
	MOVE.L	#$3111,D7		;active cache
	MOVEC.L	D7,CACR
.CLR_3PL
ASM	set	0
	rept	24
	move.l	d1,ASM(a0)
	move.w	d1,ASM+4(a0)
ASM	set	ASM+16
	endr
	lea	768(a0),a0
	dbf	d0,.CLR_3PL
	MOVE.L	#$2510,D0		;coupe cache
	MOVEC.L	D0,CACR
	rts
VBL:
	MOVE.L	D0,-(SP)
	move.l	$466.w,d0		
VSYNC:	cmp.l	$466.w,d0
	BEQ.S	VSYNC
	MOVE.L	(SP)+,D0
	RTS
CLS
	MOVEM.L	D0/A0-a1,-(SP)
	MOVE.L	AFFECR,A0
	move.l 	workecr,a1
	MOVE.W	#(11520*2)-1,D0
	MOVEQ	#0,D1
	MOVE.L	#$3111,D6		;cache on
	MOVEC.L	D6,CACR
OK
	MOVE.L	D1,(A0)+
	MOVE.L 	D1,(a1)+
	DBF	D0,OK
	MOVE.L	#$2510,D6		;cache off
	MOVEC.L	D6,CACR		
	MOVEM.L	(SP)+,D0/A0-a1
	RTS
CLR_REGISTERS
	movem.l	clr,d0-d7/a0-a6
	rts
MAKE_YTABLE
	LEA	Y_TABLE,A1
	MOVE.B	#250,D1
	MOVEQ.L	#0,D2
MAKE
	MOVE.L	D2,(A1)+
	ADD.L	#384*2,D2
	DBF	D1,MAKE
	RTS
****************************ROUTINE DE CALCUL************************************
********************************************************
*precalculs trigonometriques			*
*en entree:x_angle,y_angle,z_angle(angles de rotation) *	
*en sortie:(A,B,C,D,E,F,G,H,I)*512		*				
********************************************************


TRIGO
	MOVEM.L	D0-D7/A4-A6,-(SP)
	LEA	COS_TAB,A4
	LEA	SIN_TAB,A5
	LEA	X_ANGLE,A6
	MOVE.W	(A6)+,D2	;d2=x angle
	MOVE.W	(A6)+,D1	;d1=y ...
	MOVE.W	(A6)+,D0	;d0=z ...

	MOVE.W	(A5,D2.W),D5	;d5=sinx
	MOVE.W	(A4,D2.W),D4	;d4=cosx
	MOVE.W	(A5,D1.W),D3	;d3=siny
	MOVE.W	(A4,D1.W),D2	;d2=cosy
	MOVE.W	(A5,D0.W),D1	;d1=sinz
	MOVE.W	(A4,D0.W),D0	;d0=cosz

	LEA	VAR_3D,A6		;zone sauvegarde calc intermediaire
	MOVEQ	#9,D7
	;**********CALCUL DE C************
SP_C
	MOVE.W	D3,D6		;siny
	NEG.W	D6		;-siny	
	MOVE.W	D6,(A6)+
	;**********CALCUL DE F************
SP_F	
	MOVE.W	D2,D6		;cosy
	MULS	D5,D6		;cosy*sinx
	ASR.L	D7,D6		;/512
	MOVE.W	D6,(A6)+
	;**********CALCUL DE I************
SP_I
	MOVE.W	D2,D6		;cosy
	MULS	D4,D6		;cosy*cosx
	ASR.L	D7,D6		;/512
	MOVE.W	D6,(A6)+		
	;**********CALCUL DE A************
SP_A
	MOVE.W	D0,D6		;cosz
	MULS	D2,D6		;cosz*cosy
	ASR.L	D7,D6		
	MOVE.W	D6,(A6)+
	;**********CALCUL DE D************
SP_D
	MOVE.W	D1,D6		;sinz	
	MULS	D4,D6		;sinz*cosx
	ASR.L	D7,D6
	MOVE.W	D6,A4

	MOVE.W	D0,D6		;cosz
	MULS	D3,D6		;cosz*siny
	ASR.L	D7,D6		
	MULS	D5,D6		;cosz*siny*sinx
	ASR.L	D7,D6
	SUB.W	A4,D6		;(cosz*siny*sinx)-(sinz*cosx)
	MOVE.W	D6,(A6)+
	;**********CALCUL DE G************
SP_G
	MOVE.W	D7,D6		;sinz
	MULS	D5,D6		;sinz*sinx
	ASR.L	D7,D6
	MOVE.W	D6,A4

	MOVE.W	D0,D6		;cosz
	MULS	D3,D6		;cosz*siny
	ASR.L	D7,D6
	MULS	D4,D6		;cosz*siny*cosx
	ASR.L	D7,D6
	ADD.W	A4,D6		;(cosz*siny*cosx)+(sinz*sinx)
	MOVE.W	D6,(A6)+
	;**********CALCUL DE B************
SP_B
	MOVE.W	D1,D6		;sinz		
	MULS	D2,D6		;sinz*cosy
	ASR.L	D7,D6
	MOVE.W	D6,(A6)+
	;**********CALCUL DE E************
SP_E
	MOVE.W	D0,D6		;cosz
	MULS	D4,D6		;cosz*cosx
	ASR.L	D7,D6
	MOVE.W	D6,A4

	MOVE.W	D1,D6		;sinz
	MULS	D3,D6		;sinz*siny
	ASR.L	D7,D6
	MULS	D5,D6		;sinz*siny*sinx
	ASR.L	D7,D6
	ADD.W	A4,D6		;(sinz*siny*sinx)+(cosz*cosx)
	MOVE.W	D6,(A6)+	
	;**********CALCUL DE H*************
SP_H
	MOVE.W	D0,D6		;cosz
	MULS	D5,D6		;cosz*sinx
	ASR.L	D7,D6	
	MOVE.W	D6,A4

	MOVE.W	D1,D6		;sinz
	MULS	D3,D6		;sinz*siny		
	ASR.L	D7,D6
	MULS	D4,D6		;sinz*siny*cosx
	ASR.L	D7,D6
	SUB.W	A4,D6		;(sinz*siny*cosx)-(cosz*sinx)
	MOVE.W	D6,(A6)+
	MOVEM.L	(SP)+,D0-D7/A4-A6
	RTS
SORTIE
	MOVE.L	OLD_VBL,$70.w
	CLR	$FFFF8264.W
	MOVE.L	OLD_CACR,D0
	MOVEC.L	D0,CACR
	CLR	$FFFF8264.W
	MOVE.B	#15,$484.W
	MOVE.B	#8,$FFFFC02
	MOVE.W	OLDMODECODE,-(SP)
	MOVE.W	#3,-(SP)	
	MOVE.L	OLDXBIOS2,-(SP)
	MOVE.L	OLDXBIOS2,-(SP)
	MOVE.W	#5,-(SP)
	TRAP	#14
	LEA	14(SP),SP		
	MOVE.W	#$20,-(SP)
	TRAP	#1
	ADDQ.L	#2,SP
	CLR.W	-(SP)
	TRAP	#1
CACHE
	MOVEM.L	CLR,D0-D5
	MOVE.W	X1,D0		
	MOVE.W	X3,D1
	MOVE.W	Y1,D2
	MOVE.W	Y2,D3
;
	SUB	D0,D1	;X3-X1
	SUB	D2,D3	;Y2-Y1
	MULS	D1,D3	
;
	MOVE	X2,D4
	MOVE	Y3,D5
	SUB	D0,D4	;X2-X1
	SUB	D2,D5	;Y3-Y1
	MULS	D4,D5
;
	SUB.L	D5,D3
	RTS

	INCLUDE	"C:\UTILS\CODE_UTI.LS\GEN_ASM\FULLFACE\NEW_FACE\GEN_04.S"
	INCLUDE	"C:\UTILS\CODE_UTI.LS\GEN_ASM\FULLFACE\NEW_FACE\REMPLI04.S"

	SECTION DATA
OLD_VBL		DC.L	0 
X1		DC.W	0
Y1		DC.W	0
Z1		DC.W	0
X2		DC.W	0
Y2		DC.W	0
Z2		DC.W	0
X3		DC.W	0
Y3		DC.W	0
Z3		DC.W	0
OLD_CACR		DC.L	0
SAV_CY1		DC.W	0
IND		DC.B	0
AFFECR:		DC.L 	0
WORKECR:		DC.L 	0
WORKECR2:		DC.L 	0
OLDXBIOS2:		DC.L	0
OLDMODECODE	DC.W	0
COS_TAB		INCBIN	"C:\UTILS\CODE_UTI.LS\GFABASIC\COSIN.DAT"
SIN_TAB		EQU	COS_TAB+720	
****GRAND CUBE**********
XE1_PYRAMIDE	DC.W	0
		DC.W	0
		DC.W	80
		DC.W	0
		DC.W	60
		DC.W	-40
		DC.W	60
		DC.W	-60
		DC.W	-40
		DC.W	-60
		DC.W	-60
		DC.W	-40
*****************
XE		DC.W	0
YE		DC.W	0
ZE		DC.W	0
XDEP		DC.W	0
YDEP		DC.W	0
ZDEP		DC.W	235
X_ANGLE		DC.W	0
Y_ANGLE		DC.W	0
Z_ANGLE		DC.W	0
CX1		DC.W	0
CX2		DC.W	0
CY1		DC.W	0
CY2		DC.W	0
YMAX		DC.W	0
YMIN		DC.W	0
HAUTEUR		DC.W	0
PIX_TAB		
		DC.W	0
		DC.W	385
		DC.W	(385+384)
		DC.W	(385+384+383)
		DC.W	(385+384+383+382)
		DC.W	(385+384+383+382+381)
		DC.W	(385+384+383+382+381+380)
		DC.W	(385+384+383+382+381+380+379)
		DC.W	(385+384+383+382+381+380+379+378)
		DC.W	(385+384+383+382+381+380+379+378+377)
		DC.W	(385+384+383+382+381+380+379+378+377+376)
		DC.W	(385+384+383+382+381+380+379+378+377+376+375)
		DC.W	(385+384+383+382+381+380+379+378+377+376+375+374)
		DC.W	(385+384+383+382+381+380+379+378+377+376+375+374+373)
		DC.W	(385+384+383+382+381+380+379+378+377+376+375+374+373+372)
		DC.W	(385+384+383+382+381+380+379+378+377+376+375+374+373+372+370)
	SECTION	BSS
TAB:		DS.W	65
GEN		DS.B	485000
ADR_TAB		DS.B	1000*25
DX		DS.W	50
DY		DS.W	50
ADD		DS.W	1
XP		DS.W	1
YP		DS.W	1
SAVE_VBL:		DS.L	1
VAR_3D		DS.W	9
COMPT_HBL:		DS.W	1
COMPT_LINE:	DS.B	1
CLR		DS.L	17
		DS.L	2000
PILE		DS.L	10
		EVEN
		DS.B	4
XBIOS2:		DS.B	768*242
		DS.B	4
XBIOS3:		DS.B	768*242
		DS.L	500
XMAX1		DS.W	300
		DS.L	500
XMIN1		DS.W	300
Y_TABLE		DS.L	300
PTS		DS.W	10
		END											  																																																																																					  																									  																																												  																														
																																																										  																									  																																												  																														