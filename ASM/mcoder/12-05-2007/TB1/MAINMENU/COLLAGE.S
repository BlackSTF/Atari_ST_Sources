	LEA	$70000,A6

	LEA	$40000,A0
	BSR	COPY
	LEA	$50000,A0
	BSR	COPY
	LEA	$60000,A0
	BSR	COPY
	ILLEGAL
COPY:
	ADDQ	#2,A0
	MOVE	(A0)+,D7
LIG:
	MOVEQ	#160/4-1,D6
COL:	MOVE.L	(A0)+,(A6)+
	DBRA	D6,COL
	DBRA	D7,LIG
	RTS
