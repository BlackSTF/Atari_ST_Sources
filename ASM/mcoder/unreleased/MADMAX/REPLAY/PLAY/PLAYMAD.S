MUS=1
BASE=$40000
INITMUS=BASE
PLAYMUS=BASE+8

	MOVE	SR,D0
	AND	#$2000,D0
	BNE.S	SUPER
	CLR.L	-(SP)
	MOVE	#$20,-(SP)
	TRAP	#1
	ADDQ	#6,SP
SUPER:
	MOVEQ	#MUS,D0
	JSR	INITMUS
LOOP:
	MOVE	#37,-(SP)
	TRAP	#14
	ADDQ	#2,SP
	MOVE	#5000,D0
WAIT:	DBRA	D0,WAIT
	MOVE	#$700,$FFFF8240.W
	JSR	PLAYMUS
	CLR	$FFFF8240.W

	MOVE	#$FF,-(SP)
	MOVE	#6,-(SP)
	TRAP	#1
	ADDQ	#4,SP
	TST	D0
	BEQ.S	LOOP
	ILLEGAL
