IMPLEMENTATION MODULE ScsiCD;

(****************************************************************************
 *
 *
 * $Source: E:\HM2\LIB\se\rcs\scsicd.m,v $
 *
 * $Revision: 1.1 $
 *
 * $Author: S_Engel $
 *
 * $Date: 1996/02/03 19:33:52 $
 *
 * $State: Exp $
 *
 *****************************************************************************
 * History:
 *
 * $Log: scsicd.m,v $
 * Revision 1.1  1996/02/03  19:33:52  S_Engel
 * Initial revision
 *
 *
 *
 ****************************************************************************)


(* Systemabh�ngiges *)
(* IMPLEMENTATION F�R  >>> H�nisch-Modula-2 <<< *)
(*                                              *)
(* Durchgef�hrt von Steffen Engel               *)
(*                                              *)
(*$S-   Stack-Checks                            *)
(*$I-   keine Variablen-Initialisierung         *)
(*$V-   keine arithmetischen Kontrollen         *)
(*$T-   kein Bereichstest                       *)
(*$Y-   keine Laufzeittests auf RETURN und CASE *)
(*                                              *)
(*----------------------------------------------*)

FROM SYSTEM IMPORT ADDRESS, BYTE;

FROM Portab IMPORT UChar, Char;



IMPORT SYSTEM, System;

(* Standard HM2-Libs *)

(* Eigene Libs *)

(* Projektlibs *)
IMPORT ScsiIO, Scsi;
FROM Scsi IMPORT Cmd6, Cmd10, Cmd12, SetCmd6, SetCmd10, SetCmd12, SetCmd,
          BlockLen, MaxDmaLen, LogicalUnit;


(***************************************************************************)
(*-                                                                       -*)
(*- CD-ROM Devices                                                        -*)
(*-                                                                       -*)
(***************************************************************************)

PROCEDURE PauseResume(Pause : BOOLEAN) : BOOLEAN;

  BEGIN
    SetCmd10(04BH, 0, 0);
    IF Pause
      THEN
        Cmd10.LenLow := 0;
      ELSE
        Cmd10.LenLow := 1;
      END;
    RETURN ScsiIO.In(SetCmd(Cmd10, NIL, 0, ScsiIO.DefTimeout)) = 0;
  END PauseResume;


PROCEDURE PlayAudio(BlockAdr, TransLength : LONGINT) : BOOLEAN;

  BEGIN
    SetCmd12(0A5H, BlockAdr, TransLength);
    RETURN ScsiIO.In(SetCmd(Cmd12, NIL, 0, ScsiIO.DefTimeout)) = 0;
  END PlayAudio;


PROCEDURE PlayAudioMSF(Start, Stop : tMSF) : BOOLEAN;
VAR   Cmd : RECORD
             Code     : BYTE;
             Lun      : BYTE;
             Startmsf : tMSF;
             Stopm    : UChar;
             Stops    : UChar;
             Stopf    : UChar;
             Flags    : BYTE;
           END;
  BEGIN
    WITH Cmd DO
      Code      := BYTE(47H);
      Lun       := BYTE(0);
      Startmsf  := Start;
      Stopm     := Stop.M;
      Stops     := Stop.S;
      Stopf     := Stop.F;
      Flags     := BYTE(0);
    END;

    RETURN ScsiIO.In(SetCmd(Cmd, NIL, 0, ScsiIO.DefTimeout)) = 0;
  END PlayAudioMSF;


PROCEDURE PlayAudioTrack(StartTrack, StartIndex, EndTrack, EndIndex : SHORTCARD) : BOOLEAN;
VAR   Cmd : RECORD
             Code     : BYTE;
             Lun      : BYTE;
             Res2     : BYTE;
             Res3     : BYTE;
             StartTr  : BYTE;
             StartIn  : BYTE;
             Res6     : BYTE;
             StopTr   : BYTE;
             StopIn   : BYTE;
             Flags    : BYTE;
           END;
  BEGIN
    WITH Cmd DO
      Code    := BYTE(48H);
      Lun     := BYTE(0);
      Res2    := BYTE(0);
      Res3    := BYTE(0);
      StartTr := VAL(BYTE, StartTrack MOD 100H);
      StartIn := VAL(BYTE, StartIndex MOD 100H);
      StopTr  := VAL(BYTE, EndTrack MOD 100H);
      StopIn  := VAL(BYTE, EndIndex MOD 100H);
      Res6    := BYTE(0);
      Flags   := BYTE(0);
    END;

    RETURN ScsiIO.In(SetCmd(Cmd, NIL, 0, ScsiIO.DefTimeout)) = 0;
  END PlayAudioTrack;


PROCEDURE PlayAudioRelative(StartTrack : SHORTCARD; RelAdr, Len : LONGCARD): BOOLEAN;

  BEGIN
    SetCmd12(0A9H, RelAdr, Len);
    Cmd12.Reserved := VAL(BYTE, StartTrack MOD 100H);
    RETURN ScsiIO.In(SetCmd(Cmd12, NIL, 0, ScsiIO.DefTimeout)) = 0;
  END PlayAudioRelative;


PROCEDURE ReadHeader(MSF : BOOLEAN; BlockAdr : LONGCARD;
                     VAR Mode : BYTE; VAR AbsoluteAdr : tMSF) : BOOLEAN;
VAR Ok : BOOLEAN;
    Data :ARRAY [0..1] OF LONGCARD;

  BEGIN
    SetCmd10(044H, BlockAdr, SIZE(Data));

    IF MSF
      THEN
        Cmd10.Lun := BYTE(2);
      END;

    Ok := ScsiIO.In(SetCmd(Cmd10, SYSTEM.ADR(Data), SIZE(Data), ScsiIO.DefTimeout)) = 0;

    Mode := VAL(BYTE, Data[0] DIV 1000000H);
    AbsoluteAdr.long := Data[1];
    RETURN Ok;
  END ReadHeader;


PROCEDURE ReadSubChannel(MSF, SUBQ : BOOLEAN;
                         SubFormat, Track : SHORTCARD;
                         Data : ADDRESS; Len : SHORTCARD) : BOOLEAN;
VAR Cmd : RECORD
            opcode    : BYTE;
            lun       : BYTE;
            subq      : BYTE;
            subform   : BYTE;
            res       : SHORTCARD;
            track     : BYTE;
            lenhigh   : BYTE;
            lenlow    : BYTE;
            flag      : BYTE;
          END;

  BEGIN
    WITH Cmd DO
      opcode := BYTE(042H);
      IF MSF
        THEN
          lun := BYTE(2);
        ELSE
          lun := BYTE(0);
        END;
      IF SUBQ
        THEN
          subq := BYTE(40H);
        ELSE
          subq := BYTE(0);
        END;
      subform := VAL(BYTE, SubFormat);
      res := 0;
      track := VAL(BYTE, Track);
      lenlow := VAL(BYTE, Len MOD 100H);
      lenhigh := VAL(BYTE, Len DIV 100H);
      flag := BYTE(0);
    END;

    RETURN ScsiIO.In(SetCmd(Cmd, Data, Len, ScsiIO.DefTimeout)) = 0;

  END ReadSubChannel;


PROCEDURE ReadTOC(MSF : BOOLEAN; StartTrack : SHORTCARD;
                  Buffer : ADDRESS; Len : SHORTCARD) : BOOLEAN;

  BEGIN
    SetCmd10(043H, 0, Len);
    IF MSF
      THEN
        Cmd10.Lun := VAL(BYTE, LogicalUnit + 2);
      END;

    Cmd10.Reserved := StartTrack;

    RETURN ScsiIO.In(SetCmd(Cmd10, Buffer, Len, ScsiIO.DefTimeout)) = 0;

  END ReadTOC;


PROCEDURE ToshibaReadDiscInfo(mode : SHORTCARD; VAR BlockAdr : LONGCARD) : BOOLEAN;

  BEGIN
    SetCmd10(0C7H, 0, 0);
    Cmd10.Lun := VAL(BYTE, mode+LogicalUnit*020H);
    RETURN ScsiIO.In(SetCmd(Cmd10, SYSTEM.ADR(BlockAdr), SIZE(BlockAdr),
                            ScsiIO.DefTimeout)) = 0;
  END ToshibaReadDiscInfo;


END ScsiCD.
