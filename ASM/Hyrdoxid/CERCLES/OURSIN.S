;'oursin' made with 32 lines and 1 big circle
;by Hawkmoon/Hydroxid
;last update 18/02/95
points=	32*2

	section 	TEXT

 	LEA.L 	PILE,SP
	CLR.L	-(SP)
	MOVE.W	#$20,-(SP)
	TRAP	#1
	ADDQ.L	#2,SP
	CLR.B	$484.W
	MOVE.B	#18,$FFFFC02
	BSR	INITS
	move.l	$70.w,OLD_VBL
	move.l	#NEW_VBL,$70.w
	move.b	$ffffa09,OLD_A09
	move.b	#$40,$ffffa09
 	BSR	CLS
	BSR	CLR_REGISTERS
	BSR	GEN_CODE
	bsr	PREC_CERCLE
	BSR	MAKE_YTABLE
	BSR	CLR_REGISTERS
	move	#180,X_ANGLE
	bsr	DO_PAL
LOOP
	MOVE.L	#$00550077,$FFFF9800
	CMPI.W	#116,ZDEP
	BGT.S	NO_ZOOM
	ADDQ	#4,ZDEP
NO_ZOOM
	BSR	Effa
	cmpi.b	#56,$ffffc02
	bne.s	NO_ALT2
	MOVE.L	#$550000,$FFFF9800
NO_ALT2
	bsr	MAKE_DOTS
	bsr	MAKE_LINE
	bsr	Make_Pts
	bsr	Calc_Rayon
	move	DX,CX 
	move	DY,CY 
	move	Ray1,Rayon
	move	#0,PLAN
	move	DY,d4
	move	RAYON,d5
	sub	d5,d4
	move	d4,YMIN
	bsr	REMPLI
	bsr	SYNCHRO
	CMPI.B	#56,$FFFFC02
	BNE.S	NO_ALT
	MOVE.L	#$00FF,$FFFF9800
NO_ALT
	BSR	VBL
	
	CMPI.B	#57,$FFFFC02
	BNE	LOOP
	BRA	SORTIE
******************************************************************
PREC_CERCLE
	MOVE.L	#$3111,D7		;active cache
	MOVEC.L	D7,CACR
	move.w	#14,RAYON
	lea	XMAX1,a1
	lea	XMIN1,a2
	lea	XMAX_AD,a6
	lea	XMIN_AD,a4			
	move	#120-15-1,d3
	lea	14*4(a6),a6
	lea	14*4(a4),a4
BOUCLE_CERCLE
	move.w	RAYON,d0
	moveq	#0,d1
	moveq	#0,d2		;y=d2
	move	#3,a5
	sub.w	d1,a5		;c=d3
	move	#192,d1		;centre x 
	move	RAYON,a0		;centre y
**
Loop_Trace
	cmp.w	d2,d0		;si y#x
	beq.s	Equal
	move	d1,d6
	add	d0,d6
	move	a0,d7
	add	d2,d7
 	move	d6,(a1,d7.w*2)		;sauve x/y
	move	d1,d6
	add	d2,d6
	move	a0,d7
	sub	d0,d7
	move	d6,(a1,d7.w*2)		;sauve x/y
	move	d1,D6
	sub	d0,d6
	move	a0,D7
	sub	d2,d7
	move	d6,(a2,d7.w*2)		;sauve x/y
	move	d1,D6
	sub	d2,d6
	move	a0,D7
	add	d0,d7
	move	d6,(a2,d7.w*2)		;sauve x/y
Equal
	tst.w	d2			;si y#0
	beq.s	Equal2
	move	d1,d6
	add	d0,d6
	move	a0,d7
	sub	d2,d7
	move	d6,(a1,d7.w*2)		;sauve x/y
	move	d1,d6
	sub	d2,d6
	move	a0,d7
	sub	d0,d7
	move	d6,(a2,d7.w*2)		;sauve x/y
	move	d1,d6
	sub	d0,d6
	move	a0,d7
	add	d2,d7
	move	d6,(a2,d7.w*2)		;sauve x/y
	move	d1,D6
	add	d2,d6
	move	a0,D7
	add	d0,d7
	move	d6,(a1,d7.w*2)		;sauve x/y
Equal2
	tst.w	a5
;si c<0 c=c+4*y+6
	bpl.s	Great
	lea	6(a5,d2.w*4),a5
	bra.s	Less
Great
;sinon c=c-4*x+4*y+10=c+4(y-x)+10  y=d2 x=d0
	move	d2,d4
	sub	d0,d4
	lea	10(a5,d4.w*4),a5
;x=x-1
	subq	#1,d0
Less
;y=y+1
	addq	#1,d2
	cmp	d2,d0
	bge	Loop_Trace
	
	moveq	#0,d0
	move.l	a1,(a6)+
	move.l	a2,(a4)+
	move.w	RAYON,d0
	lea	(a1,d0.w*4),a1
	lea	(a2,d0.w*4),a2
	addq	#1,RAYON
	dbf	d3,BOUCLE_CERCLE
	MOVE.L	#$2510,D0		;coupe cache
	MOVEC.L	D0,CACR
	rts
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
*	MOVE	#192,$FFFF820E.W	;TAILLE EN MOT
	MOVE	#16,$FFFF8266.W	;16=VGA & 256=TC
	MOVE	#254,$FFFF8282.W	;NBRE DE DEMI-LINES
	MOVE	#203-10,$FFFF8284.W	;FIN LIGNE HORIZONTALE
	MOVE	#47-10,$FFFF8286.W	;DEBUT LIGNE HORIZONTALE
	MOVE	#764,$FFFF8288.W	;FULL GAUCHE	
	MOVE	#157,$FFFF828A.W	;FULL DROIT
	MOVE	#216,$FFFF828C.W	;SYNCHRO HORIZONTAL
	MOVE	#625,$FFFF82A2.W	;NBRE DE CHAMPS
	MOVE	#613,$FFFF82A4.W	;FIN SCREEN
	MOVE	#47,$FFFF82A6.W	;DEBUT ECRAN
	MOVE	#85,$FFFF82A8.W	;FULL HAUT
	MOVE	#566,$FFFF82AA.W	;FULL BAS
	MOVE	#619,$FFFF82AC.W	;SYNCHRO VERTICAL
	MOVE	#385,$FFFF82C0.W	;????
	CLR	$FFFF82C2.W	;PIXEL OPTIONS	
	RTS
*******************************SOUS ROUTINES*****************************************
DO_PAL
	lea	$ffff9800,a0
;plan1
	move.l	#$99000099,4(a0)
;plan2
	move.l	#$77ee0077,2*4(a0)
	move.l	#$77880077,3*4(a0)
;plan3
	move.l	#$77ee0077,4*4(a0)
	move.l	#$77ee0077,5*4(a0)
	move.l	#$77ee0077,6*4(a0)
	move.l	#$77ee0077,7*4(a0)
	rts
MAKE_LINE
	lea	DX2,a0
	lea	DY2,a1
	lea	DX2+64,a2
	lea	DY2+128,a3
	move	DY+2,d3
	move	#(points/2)-1,d0
BOUCLE_LINE
	move	(a0)+,CX1
	move	(a1)+,CY1
	move	(a1)+,d1
	move	(a2)+,CX2
	move	(a3)+,CY2
	move	(a3)+,d1
	cmp	d3,d1
	bgt.s	PLAN1
	moveq	#2,d4
	bra.s	PLAN2
PLAN1
	moveq	#4,d4
PLAN2
	movem.l	d3-d4/d0/a0-a3,-(sp)
	bsr	LINE
	movem.l	(sp)+,d3-d4/d0/a0-a3
	dbf	d0,BOUCLE_LINE
	rts
MAKE_DOTS
*	ADD.W	#4,X_ANGLE
*	CMPI.W	#720,X_ANGLE
*	BLT.S	NO_STOP
*	CLR.W	X_ANGLE
*NO_STOP
	ADD.W	#6,Y_ANGLE
	CMPI.W	#720,Y_ANGLE
	BLT.S	NO_STOP2
	CLR.W	Y_ANGLE
NO_STOP2
*	ADD.W	#4,Z_ANGLE
*	CMPI.W	#720,Z_ANGLE
*	BLT.S	NO_STOP3
*	CLR.W	Z_ANGLE
*NO_STOP3
	BSR	TRIGO
	LEA	COORD,A0
	LEA	DX2,A5
	LEA	DY2,A4
	LEA	VAR_3D,A6
	MOVE	#points-1,D0
	MOVE.L	#$3111,D6		;cache on
	MOVEC.L	D6,CACR
	MOVEQ.W	#9,D6
LOOP_TRIGO
	MOVE.W	(A0)+,A1
	MOVE.W	(A0)+,D1
	MOVE.W	(A0)+,D2
	MOVE.W	ZDEP,D5
	ASL.L	D6,D5		;zdep*512
	MOVE.L	D5,A3

	MOVE.W	A1,D3
	MOVE.W	D1,D4
	MOVE.W	D2,D5

	MULS	(A6),D3		;d3=c*xe*512
	MULS	2(A6),D4		;d4=f*ye*512
	MULS	4(A6),D5		;d5=i*ze*512
	ADD.L	D4,D5		;+f*ye*512
	ADD.L	D3,D5		;+c*xe*512
	ADD.L	A3,D5		;+zdep*512
	ASR.L	#8,D5
	MOVE	D5,NEW_ZE
	
	MOVE.W	#512,D7
	SUB.W	D5,D7		;d7=512*q
				;d7=512*(1-new_ze/z_pt_fuite)
	MOVE.W	A1,D3		;d3=xe
	MOVE.W	D1,D4		;d4=ye
	MOVE.W	D2,D5		;d5=ze

	MULS	6(A6),D3		;d3=a*xe*512
	MULS	8(A6),D4		;d4=d*ye*512
	MULS	10(A6),D5		;d5=g*ze*512
	ADD.L	D4,D5		
	ADD.L	D3,D5
	DIVS	D7,D5		;d5=new_xe/q

	MULS	16(A6),D2		;d2=h*ze*512
	DIVS	D7,D2		;d2=new_ye/q
	ADD.W	#192,D5	
	ADD.W	#120,D2
	MOVE.W	D5,(A5)+
	MOVE.W	D2,(A4)+
	MOVE.W	NEW_ZE,(A4)+
	DBF	D0,LOOP_TRIGO
	MOVE.L	#$2510,D0		;coupe cache
	MOVEC.L	D0,CACR
	RTS
NEW_VBL
	addq.l	#1,$466
	rte
CALC_RAYON
	move	DY,d1
	move	DY+4,d2
	sub	d1,d2
	move	d2,RAY1
	rts
EFFA
	move.l	WORKECR,a0
*	lea	384*10(a0),a0
	moveq	#0,d1
	move	#239,d0
	moveq	#0,d7
	movec	d7,CACR
	MOVE.L	#$3111,D7		;active cache
	MOVEC.L	D7,CACR
CLR_3PL
ASM	set	32
	rept	20
	move.l	d1,ASM(a0)
	move	d1,ASM+4(a0)
ASM	set	ASM+16
	endr
	lea	384(a0),a0
	dbf	d0,CLR_3PL
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
	movem.l	clr,d0-d6/a0-a6
	rts
MAKE_YTABLE
	LEA	Y_TABLE,A1
	MOVE	#280,D1
	MOVEQ.L	#0,D2
MAKE
	MOVE.L	D2,(A1)+
	ADD.L	#384,D2
	DBF	D1,MAKE
	RTS
MAKE_PTS
	ADD.W	#6,Y_ANGLE2
	CMPI.W	#720,Y_ANGLE2
	BLT.S	NO_STOP4
	CLR.W	Y_ANGLE2
NO_STOP4
*	ADD.W	#4,Z_ANGLE2
*	CMPI.W	#720,Z_ANGLE2
*	BLT.S	NO_STOP3
*	CLR.W	Z_ANGLE2
*NO_STOP3 
	BSR	TRIGO2
	LEA	XC,A0
	LEA	YC,A1
	LEA	ZC,A2
	LEA	DX,A5
	LEA	DY,A4
	MOVE	#1,D0
	MOVE.L	#$3111,D6		;cache on
	MOVEC.L	D6,CACR
	MOVEQ.W	#9,D6
LOOP_TRIGO2
	MOVEM.L	D0/A0-A2,-(SP)		
	MOVE.W	(A0),D0
	MOVE.W	(A1),D1
	MOVE.W	(A2),D2
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
	ASR.L	#8,D5
	MOVE	D5,NEW_ZE
	
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
	ADD.W	#192,D5	
	ADD.W	#120,D2
	MOVEM.L	(SP)+,D0/A0-A2
	ADDQ	#6,A0
	ADDQ	#6,A1
	ADDQ	#6,A2
	MOVE.W	D5,(A5)+
	MOVE.W	D2,(A4)+
	MOVE	NEW_ZE,(A4)+
	DBF	D0,LOOP_TRIGO2
	MOVE.L	#$2510,D0		;coupe cache
	MOVEC.L	D0,CACR
	RTS
REMPLI
	lea	Y_TABLE,a4
	move.l	WORKECR,a2
	add	PLAN,a2
	move	RAYON,d1
	lea	XMAX_AD,a0
	lea	XMIN_AD,a5
	move.l	(a0,d1.w*4),a3
	move.l	(a5,d1.w*4),a1
	move.w	YMIN,d0
	add.l	(a4,d0.w*4),a2	;pos y de depart du polygone
	sub	#192,CX
	move	CX,d2
	move.l	a2,d3
	cmpi.w	#0,d1
	bgt.s	REMPLI_OK
	rts
REMPLI_OK
	asl	d1
	lea	RETOUR,a2
	lea	ADR_TAB,a5
	lea	PIX_TAB,a6
	MOVE.L	#$3111,D6		;cache on		
	MOVEC.L	D6,CACR
*********************
AFF_FACE2
	move.l	d3,a0		;restitue adresse ecran
	move.w	(a3)+,d7		;xmax
	move.w	(a1)+,d6		;xmin
	add	d2,d7
	add	d2,d6
****
	move	d6,d4
	sub.w	d6,d7

	andi.w	#$fff0,d6	
	andi.w	#$f,d4		;valeur du bloc de depart
	add.w	(a6,d4.w*2),d7	;fixe pixel de depart
	add.w	d6,a0
	move.l	(a5,d7.w*4),a4
	jmp	(a4.l)
RETOUR
	add.l	#384,d3		;new ligne
	dbf	d1,AFF_FACE2
	MOVE.L	#$2510,D6		;cache off	
	MOVEC.L	D6,CACR		
	rts
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

	LEA	VAR_3D,A6	;zone sauvegarde calc intermediaire
	MOVEQ.W	#9,D7		;nombre de decalages pour/512

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
TRIGO2
	MOVEM.L	D0-D7/A4-A6,-(SP)
	LEA	COS_TAB,A4
	LEA	SIN_TAB,A5
	LEA	X_ANGLE2,A6
	MOVE.W	(A6)+,D2	;d2=x angle
	MOVE.W	(A6)+,D1	;d1=y ...
	MOVE.W	(A6)+,D0	;d0=z ...

	MOVE.W	(A5,D2.W),D5	;d5=sinx
	MOVE.W	(A4,D2.W),D4	;d4=cosx
	MOVE.W	(A5,D1.W),D3	;d3=siny
	MOVE.W	(A4,D1.W),D2	;d2=cosy
	MOVE.W	(A5,D0.W),D1	;d1=sinz
	MOVE.W	(A4,D0.W),D0	;d0=cosz

	LEA	VAR_3D,A6	;zone sauvegarde calc intermediaire
	MOVEQ.W	#9,D7		;nombre de decalages pour/512

	;**********CALCUL DE C************
SP_C2
	MOVE.W	D3,D6		;siny
	NEG.W	D6		;-siny	
	MOVE.W	D6,(A6)+
	;**********CALCUL DE F************
SP_F2	
	MOVE.W	D2,D6		;cosy
	MULS	D5,D6		;cosy*sinx
	ASR.L	D7,D6		;/512
	MOVE.W	D6,(A6)+
	;**********CALCUL DE I************
SP_I2
	MOVE.W	D2,D6		;cosy
	MULS	D4,D6		;cosy*cosx
	ASR.L	D7,D6		;/512
	MOVE.W	D6,(A6)+		
	;**********CALCUL DE A************
SP_A2
	MOVE.W	D0,D6		;cosz
	MULS	D2,D6		;cosz*cosy
	ASR.L	D7,D6		
	MOVE.W	D6,(A6)+
	;**********CALCUL DE D************
SP_D2
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
SP_G2
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
SP_B2
	MOVE.W	D1,D6		;sinz		
	MULS	D2,D6		;sinz*cosy
	ASR.L	D7,D6
	MOVE.W	D6,(A6)+
	;**********CALCUL DE E************
SP_E2
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
SP_H2
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
	MOVE.L	OLD_CACR,D0
	MOVEC.L	D0,CACR
	move.b	OLD_A09,$ffffa09
	move.l	OLD_VBL,$70.w
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

	INCLUDE	"C:\UTILS\CODE_UTI.LS\GEN_ASM\FULLFACE\NEW_FACE\GEN_04.S"
	INCLUDE	"C:\UTILS\CODE_UTI.LS\GEN_ASM\LINEROUT\LINE_256.S"
	SECTION DATA	
CX1		DC.W	0
CY1		DC.W	0
CX2		DC.W	0
CY2		DC.W	0
IND		DC.B	0
OLD_VBL		DC.L	0
OLD_A09		DC.B	0
PLAN		DC.W	0
X_ANGLE		DC.W	0
Y_ANGLE		DC.W	0
Z_ANGLE		DC.W	0
X_ANGLE2		DC.W	0
Y_ANGLE2		DC.W	0
Z_ANGLE2		DC.W	0
XDEP		DC.W	0
YDEP		DC.W	0
ZDEP		DC.W	-500
******
XC		DC.W	0
YC		DC.W	0
ZC		DC.W	0 
X1		DC.W	0
Y1		DC.W	50
Z1		DC.W	0 
******
NEW_ZC		DC.W	0
NEW_ZE		DC.W	0
CX		DC.W	0
CY		DC.W	0
YMIN		DC.W	0
HAUTEUR		DC.W	0
RAYON		DC.W	0
RAY1		DC.W	0
OLD_CACR		DC.L	0
AFFECR:		DC.L 	1
WORKECR:		DC.L 	1
OLDXBIOS2:		DC.L	1
OLDMODECODE	DC.W	1
SCREEN_ADD		DC.L	0
FORME		INCBIN	"C:\UTILS\CODE_UTI.LS\GEN_ASM\MULTIPAR.T\V.INL"
COORD		INCBIN	"C:\UTILS\CODE_UTI.LS\GFABASIC\COORD6.INL"
COORD2		INCBIN	"C:\UTILS\CODE_UTI.LS\GFABASIC\COORD7.INL"
COS_TAB		INCBIN	"C:\UTILS\CODE_UTI.LS\GFABASIC\COSIN.DAT"
SIN_TAB		EQU	COS_TAB+720	
TAB	
OXO	SET	0	
	REPT	24
	DC	32768,OXO,16384,OXO,8192,OXO,4096,OXO
	DC	2048,OXO,1024,OXO,512,OXO,256,OXO
	DC	128,OXO,64,OXO,32,OXO,16,OXO
	DC	8,OXO,4,OXO,2,OXO,1,OXO
OXO	SET	OXO+8
	ENDR
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
GEN		DS.B	485000
		DS.B	10
ADR_TAB		DS.B	25000
DX		DS.W	50
DY		DS.W	50
DX2		DS.W	300
DY2		DS.W	300
VAR_3D		DS.W	9
Y_TABLE		DS.L	300
CLR		DS.L	17
		DS.L	2000
PILE		DS.L	10
		DS.B	4
XBIOS2:		DS.B	768*242
		DS.B	4
XBIOS3:		DS.B	768*242
XMAX		DS.W	500
XMIN		DS.W	500
XP		DS.W	0
YP		DS.W	0
XMAX_AD		DS.B	150*4
XMIN_AD		DS.B	150*4
XMAX1		DS.B	30000
XMIN1		DS.B	30000
	END
																						