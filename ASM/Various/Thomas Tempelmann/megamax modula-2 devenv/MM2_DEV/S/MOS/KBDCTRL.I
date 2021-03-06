IMPLEMENTATION MODULE KbdCtrl;
(*$Y+,C-,N+,L-*)

(*
  17.07.90: Look/Get/PushKey-Routinen korrigiert bzgl. Supexec-Aufruf
  04.11.90: Supervisor-Modus ganz raus bei allen Kbd-Puffer-Zugriffen.
            Allerdings k�nnen dadurch die Interrupts nicht mehr gesperrt
            werden!
  14.02.92 TT  GEMDOS.Super-Aufrufe statt Supexec wg. MinT.
*)

FROM SYSTEM IMPORT ASSEMBLER;
FROM SYSTEM IMPORT ADDRESS, ADR, TSIZE, BYTE, WORD, LONGWORD;
FROM SysUtil2 IMPORT EnterSupervisorMode, LeaveSupervisorMode;
FROM ResCtrl IMPORT RemovalCarrier, CatchRemoval;
FROM MOSGlobals IMPORT MemArea, Key, CtrlKey, CtrlSet;
FROM MOSSupport IMPORT ToSuper, ToUser;

VAR remc: RemovalCarrier;

TYPE KbdRecT= RECORD
                buf:  ADDRESS;
                size: CARDINAL;
                head: CARDINAL;      (* hiernach steht die n�chste Taste an *)
                tail: CARDINAL;      (* hier hinter kommt n�chste Taste rein *)
              END;

PROCEDURE KeysAvail (): CARDINAL;
  BEGIN
    ASSEMBLER
        MOVE.L  KbdRec,A0
        MOVE    KbdRecT.tail(A0),D0
        SUB     KbdRecT.head(A0),D0
        BCC     e
        ADD     KbdRecT.size(A0),D0
     e: LSR     #2,D0           ; DIV 4
        MOVE    D0,(A3)+
    END
  END KeysAvail;

PROCEDURE KeyBufferSize (): CARDINAL;
  BEGIN
    ASSEMBLER
        MOVE.L  KbdRec,A0
        MOVE    KbdRecT.size(A0),D0
        LSR     #2,D0           ; DIV 4
        MOVE    D0,(A3)+
    END
  END KeyBufferSize;

PROCEDURE asn;
  BEGIN
    ASSEMBLER
        MOVE.B  D0,Key.ch(A2)
        SWAP    D0
        CLR     D1
        MOVE.B  D0,D1
        MOVE    D1,Key.scan(A2)
        LSR     #8,D0
        LSR     #1,D0
        BCC     n
        BSET    #0,D0
     n: ANDI    #1111%,D0
        MOVE.B  D0,Key.ctrl(A2)
    END
  END asn;

PROCEDURE LookMostRecentKey ( VAR k: Key; VAR ok: BOOLEAN );
  BEGIN
    ASSEMBLER
        MOVE.L  -(A3),A1        ; ok
        MOVE.L  -(A3),A2        ; k
        MOVE.L  KbdRec,A0
        MOVE    KbdRecT.tail(A0),D0
        CMP     KbdRecT.head(A0),D0
        BEQ     n
        MOVE.L  KbdRecT.buf(A0),A0
        MOVE.L  0(A0,D0.W),D0
        MOVE    #1,(A1)
        JMP     asn
     n: CLR.L   (A2)
        CLR     (A1)
    END
  END LookMostRecentKey;

PROCEDURE LookKey (VAR k: Key; VAR ok: BOOLEAN);
  BEGIN
    ASSEMBLER
        MOVE.L  -(A3),A1        ; ok
        MOVE.L  -(A3),A2        ; k
        MOVE.L  KbdRec,A0
        MOVE    KbdRecT.head(A0),D0
        CMP     KbdRecT.tail(A0),D0
        BEQ     n
        MOVE.L  KbdRecT.buf(A0),A0
        MOVE.L  4(A0,D0.W),D0
        MOVE    #1,(A1)
        JMP     asn
     n: CLR.L   (A2)
        CLR     (A1)
    END
  END LookKey;

PROCEDURE GetKey (VAR k: Key; VAR ok: BOOLEAN);
  BEGIN
    ASSEMBLER
        MOVE.L  -(A3),A1        ; ok
        MOVE.L  -(A3),A2        ; k
        MOVE.L  KbdRec,A0
        MOVE    KbdRecT.head(A0),D1
        CMP     KbdRecT.tail(A0),D1
        BEQ     n
        MOVE    #1,(A1)
        ADDQ    #4,D1
        CMP     KbdRecT.size(A0),D1
        BCS     o
        CLR     D1
     o: MOVE    D1,KbdRecT.head(A0)
        MOVE.L  KbdRecT.buf(A0),A1
        MOVE.L  0(A1,D1.W),D0
        JMP     asn
     n: CLR.L   (A2)
        CLR     (A1)
    END
  END GetKey;

PROCEDURE put;
  BEGIN
    ASSEMBLER
        MOVE.B  Key.ctrl(A2),D0
        LSL     #1,D0
        MOVE.B  D0,(A1)+
        MOVE.B  Key.scan+1(A2),(A1)
        MOVE.B  Key.ch(A2),2(A1)
    END
  END put;

PROCEDURE PushBackKey (VAR k: Key; VAR ok: BOOLEAN);
  BEGIN
    ASSEMBLER
        MOVE.L  -(A3),A1        ; ok
        MOVE.L  -(A3),A2        ; k
        MOVE.L  KbdRec,A0
        MOVE    KbdRecT.head(A0),D0
        MOVE    D0,D1
        SUBQ    #4,D0
        BCC     o
        MOVE    KbdRecT.size(A0),D0
        SUBQ    #4,D0
     o: CMP     KbdRecT.tail(A0),D0
        BEQ     n
        MOVE    D0,KbdRecT.head(A0)
        MOVE    #1,(A1)
        MOVE.L  KbdRecT.buf(A0),A1
        ADDA.W  D1,A1
        JMP     put
     n: CLR     (A1)
     e:
    END
  END PushBackKey;

PROCEDURE PutKey (VAR k: Key; VAR ok: BOOLEAN);
  BEGIN
    ASSEMBLER
        MOVE.L  -(A3),A1        ; ok
        MOVE.L  -(A3),A2        ; k
        MOVE.L  KbdRec,A0
        MOVE    KbdRecT.tail(A0),D0
        ADDQ    #4,D0
        CMP     KbdRecT.size(A0),D0
        BCS     o
        CLR     D0
     o: CMP     KbdRecT.head(A0),D0
        BEQ     n
        MOVE    #1,(A1)
        MOVE    D0,KbdRecT.tail(A0)
        MOVE.L  KbdRecT.buf(A0),A1
        ADDA.W  D0,A1
        JMP     put
     n: CLR     (A1)
    END
  END PutKey;

PROCEDURE ClrKeyBuffer;
  BEGIN
    ASSEMBLER
        MOVE.L  KbdRec,A0
        MOVE    KbdRecT.tail(A0),KbdRecT.head(A0)
    END
  END ClrKeyBuffer;

PROCEDURE LockKeyBuffer (VAR hdl: LONGCARD);
  BEGIN
    ASSEMBLER
        SUBQ.L  #4,A7
        MOVE.L  A7,(A3)+
        JSR     EnterSupervisorMode
        MOVE.L  -(A3),A0
        MOVE    SR,(A0)
        ORI     #$0700,SR
        MOVE.L  A7,(A3)+
        JSR     LeaveSupervisorMode
        ADDQ.L  #4,A7
    END
  END LockKeyBuffer;

PROCEDURE UnlockKeyBuffer (hdl: LONGCARD);
  BEGIN
    ASSEMBLER
        SUBQ.L  #4,A7
        MOVE.L  A7,(A3)+
        JSR     EnterSupervisorMode
        SUBQ.L  #2,A3
        MOVE    -(A3),SR
        MOVE.L  A7,(A3)+
        JSR     LeaveSupervisorMode
        ADDQ.L  #4,A7
    END
  END UnlockKeyBuffer;

PROCEDURE SetExtMode ( VAR lastMode: BOOLEAN );
  BEGIN
    ASSEMBLER
        SUBQ.L  #4,A7
        JSR     ToSuper
        BSET    #3,$484
        SNE     D0
        ANDI    #1,D0
        MOVE.L  -(A3),A0
        MOVE    D0,(A0)
        JSR     ToUser
        ADDQ.L  #4,A7
    END
  END SetExtMode;

PROCEDURE CurrentMode (): BOOLEAN;
  BEGIN
    ASSEMBLER
        SUBQ.L  #4,A7
        JSR     ToSuper
        BTST    #3,$484
        SNE     D0
        ANDI    #1,D0
        MOVE    D0,(A3)+
        JSR     ToUser
        ADDQ.L  #4,A7
    END
  END CurrentMode;

PROCEDURE SetMode ( extended: BOOLEAN );
  BEGIN
    ASSEMBLER
        SUBQ.L  #4,A7
        JSR     ToSuper
        TST     -(A3)
        BNE     setit
        BCLR    #3,$484
        BRA     ret
  setit BSET    #3,$484
  ret:  JSR     ToUser
        ADDQ.L  #4,A7
    END
  END SetMode;

PROCEDURE removal;
  BEGIN
    ASSEMBLER
        MOVE    PreviousMode,(A3)+
        JMP     SetMode
    END
  END removal;

VAR wsp: MemArea;

BEGIN
  ASSEMBLER
        ; I/O-Buffer f. Tastatur ermitteln
        MOVE    #1,-(A7)
        MOVE    #14,-(A7)
        TRAP    #14         ; iorec (kbd)
        ADDQ.L  #4,A7
        MOVE.L  D0,KbdRec
  END;
  SetExtMode (PreviousMode);
  CatchRemoval (remc, removal, wsp);
END KbdCtrl.
 
(* $00001109$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$000002C6$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F$FFF6BC2F�$00001907T.......T.......T.......T.......T.......T.......T.......T.......T.......T.......$00001932$00000281$000018E4$00001907$00001614$FFEFB5B0$00001774$000016BB$000017FD$000017C8$00001691$00001744$FFEFB5B0$00001892$0000189B$000017D2���*)
