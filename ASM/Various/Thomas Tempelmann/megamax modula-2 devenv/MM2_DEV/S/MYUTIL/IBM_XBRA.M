
(* TO DO
- F�lle in 'test' �berdenken: Ist es sinnvoll, daf�r Funktionen bereitzustellen?
  Ansonsten: Dokumentieren, wie Vorg�nger (�ber Carrier.prev) aufgerufen wird.
- Query-Funktion
*)

MODULE XBRA;

FROM SYSTEM IMPORT ADR, ADDRESS, FLAT, PTR, BYTE, SEG, OFS;

FROM InOut IMPORT Write, WriteString, WriteLn, WriteCard, WriteHex, Read;



MODULE X;

IMPORT ADR, ADDRESS, FLAT, PTR, BYTE;

EXPORT Str4, Carrier, QueryProc,
       Install, Installed, Create, Remove, Query;

CONST Magic = 'XBRA';

TYPE
      Str4 = ARRAY [0..3] OF CHAR;

      JmpCarrier = RECORD
                     instruction: BYTE;
                     operand: ADDRESS
                   END;

      Carrier = RECORD
                  magic: Str4;                 (* CONST 'XBRA' *)
                  name : Str4;                 (* individuelle ID *)
                  prev : ADDRESS;              (* voriger Vektor *)
                  entry: JmpCarrier;
                END;

      QueryProc = PROCEDURE ( (* name:   *) Str4,
                              (* call:   *) ADDRESS,
                              (* prev:   *) ADDRESS  ): BOOLEAN;

VAR   entryOffs: CARDINAL;

VAR   magic: Str4;

PROCEDURE equal (VAR s1, s2: Str4): BOOLEAN;
  BEGIN
    RETURN (s1[0]=s2[0]) AND (s1[1]=s2[1]) AND
           (s1[2]=s2[2]) AND (s1[3]=s2[3]);
  END equal;

PROCEDURE sub (p: ADDRESS; n: CARDINAL): ADDRESS;
  BEGIN
    RETURN PTR (FLAT (p) - LONG (n))
  END sub;

PROCEDURE Installed (name: Str4; vector: ADDRESS; VAR at: ADDRESS): BOOLEAN;
  (*
   * Wird 'name' in Kette ab 'vector' gefunden, enth�lt 'at' die Adresse
   * des Vektors auf den Funktionseinsprung (welcher Teil von 'Carrier' ist).
   * Wird 'name' nicht gefunden, ist 'at'=vector
   *)
  VAR c: POINTER TO Carrier; p: POINTER TO ADDRESS;
  BEGIN
    at:= vector; (* Vorwahl f�r RETURN FALSE *)
    p:= vector;
    LOOP
      IF p^ = NIL THEN RETURN FALSE END;
      c:= sub (p^, entryOffs);
      (* hier Exceptions abfangen (aber pr�fen, ob vector=exc-vektor ist) *)
      IF equal (c^.magic, magic) THEN
        (* XBRA-Kennung gefunden *)
        IF equal (c^.name, name) THEN
          (* Ende, da Name gefunden *)
          at:= p;
          RETURN TRUE
        ELSE
          (* Vorg�nger pr�fen *)
          p:= ADR (c^.prev)
        END
      ELSE
        (* Ende, da XBRA-Kette zuende *)
        RETURN FALSE
      END;
    END;
  END Installed;

PROCEDURE Create (VAR use: Carrier; name: Str4; call: PROC;
                  VAR entry: ADDRESS);
  (*
   * entry:= <Einsprungadresse der Routine f�r einen Vektor>
   *)
  BEGIN
    use.name:= name;
    use.magic:= magic;
    use.prev:= NIL;
    use.entry.instruction:= VAL (BYTE, 0EAH);
    use.entry.operand:= ADDRESS (call);
    entry:= ADR (use.entry.instruction)
  END Create;

PROCEDURE Install (entry: ADDRESS; at: ADDRESS);
  (*
   * Wenn 'entry'=NIL oder 'at'=NIL, wird ein Laufzeitfehler ausgel�st.
   *)
  VAR c: POINTER TO Carrier; p: POINTER TO ADDRESS;
  BEGIN
    IF (entry = NIL) OR (at = NIL) THEN
      HALT
    ELSE
      c:= sub (entry, entryOffs);
      p:= at;
      c^.prev:= p^;
      p^:= entry;
    END
  END Install;

PROCEDURE Remove (at: ADDRESS);
  (*
   * Wenn 'at'=NIL, wird ein Laufzeitfehler ausgel�st.
   *)
  VAR c: POINTER TO Carrier; p: POINTER TO ADDRESS;
  BEGIN
    IF at = NIL THEN
      HALT
    ELSE
      p:= at;
      c:= sub (p^, entryOffs);
      IF equal (c^.magic, magic) THEN
        p^:= c^.prev
      ELSE
        HALT
      END
    END
  END Remove;

PROCEDURE Query (vector: ADDRESS; with: QueryProc);
  VAR c: POINTER TO Carrier; p: POINTER TO ADDRESS;
  BEGIN
    p:= vector;
    LOOP
      IF p^ = NIL THEN RETURN END;
      c:= sub (p^, entryOffs);
      IF equal (c^.magic, magic) THEN
        IF NOT with (c^.name, c^.entry.operand, c^.prev) THEN RETURN END;
        p:= ADR (c^.prev)
      ELSE
        IF with ('????', p^, NIL) THEN (* dummy *) END;
        RETURN
      END
    END;
  END Query;

PROCEDURE Call (entry: ADDRESS);
  (*
   * F�r einfachen Unterprogrammaufruf des Vorg�ngers von der installierten
   * Routine aus.
   *)
  BEGIN
    HALT
  END Call;

VAR testCarr: Carrier;
BEGIN
  magic:= Magic;
  entryOffs:= SHORT (  FLAT (ADR (testCarr.entry.instruction))
                     - FLAT (ADR (testCarr)) )
END X; (* local module *)

PROCEDURE norm (a: ADDRESS): ADDRESS;
  BEGIN
    RETURN PTR (FLAT (a))
  END norm;

PROCEDURE info (s: ARRAY OF CHAR);
  BEGIN
    WriteString (s);
    WriteLn;
  END info;

PROCEDURE WriteAddr (a: ADDRESS);
  BEGIN
    WriteHex (a.SEG,4);
    Write (':');
    WriteHex (a.OFS,4);
  END WriteAddr;

PROCEDURE step (name: Str4; proc, prev: ADDRESS): BOOLEAN;
  BEGIN
    WriteString (name);
    WriteString (' at: ');
    WriteAddr (norm(proc));
    WriteString (', prev: ');
    WriteAddr (prev);
    WriteLn;
    RETURN TRUE
  END step;

PROCEDURE check;
  BEGIN
    WriteLn;
    Query (ADR (v), step)
  END check;

PROCEDURE test;
  (*
   * Verschiedene F�lle:
   *   1. kein Aufruf vorher installierter Routinen
   *   2. Aufruf des Vorg�ngers als Unterprogramm
   *   3. Aufruf des Vorg�ngers am Ende.
   * Ma�nahmen
   *   f�r 2.: Carrier.prev einfach per 'Jump to subroutine' aufrufen
   *   f�r 3.: CPU-Register wiederherstellen, 'Jump' ausf�hren.
   *)
  BEGIN
    info ('Dies ist die Test-Routine 1')
  END test;

PROCEDURE test2;
  BEGIN
    info ('Dies ist die Test-Routine 2')
  END test2;

VAR v: PROC;
    at, entry: ADDRESS;
    removable, ok: BOOLEAN;
    carr2, carrier: Carrier;

BEGIN
  v:= test2;
  check;
  IF NOT Installed ('Test', ADR (v), at) THEN
    info ('Installiere');
    Create (carrier, 'Test', test, entry);
    Install (entry, at)
  END;
  check;
  info ('Aufruf');
  v;
  IF NOT Installed ('Tes2', ADR (v), at) THEN
    info ('Installiere 2');
    Create (carr2, 'Tes2', test2, entry);
    Install (entry, at)
  END;
  check;
  info ('Aufruf');
  v;
  IF Installed ('Tes2', ADR (v), at) THEN
    info ('2 Wird entfernt');
    Remove (at)
  ELSE
    info ('2 Nicht installiert')
  END;
  check;
  info ('Aufruf');
  v;
  IF Installed ('Test', ADR (v), at) THEN
    info ('1 Wird entfernt');
    Remove (at)
  ELSE
    info ('1 Nicht installiert')
  END;
  check
END XBRA.
]);
  END equal;

PROCEDURE sub (p: ADDRESS 