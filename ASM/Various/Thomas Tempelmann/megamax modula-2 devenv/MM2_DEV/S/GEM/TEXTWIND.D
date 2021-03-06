DEFINITION MODULE TextWindows;


(*  System              : Megamax Modula-2 (MOS 2.0)
 *  Autor & Copyright   : Manuel Chakravarty
 *  Vertrieb            : Application Systems Heidelberg
 *  Version             : 2.9
 *)


(*      Diese Modul bietet die M�glichkeit zur einfachen, aber dennoch
 *      komfortablen Nutzung der vom AES bereitgestellten Fensterroutinen.
 *      Jede aus dem Modul 'Terminal' bekannte Routine ist auch in diesem
 *      Modul zu finden. Dadurch ist es ohne gro�en Aufwand m�glich die
 *      Ein- und Ausgaben eines, urspr�nglich f�r den TOS-Bildschirm kon-
 *      zipierten Programmes auf die Textfenster umzulenken. Von dieser
 *      M�glichkeit macht auch das MOS einige Male Gebrauch.
 *      Des weiteren erlaubt die Prozedur 'DetectChar', da� der Anwender
 *      innerhalb eines Textfensters, mit Hilfe der Maus, ein beliebiges
 *      Zeichen ausw�hlt.
 *
 *      Die Fensterverwaltung ist weitgehend automatisch, da� hei�t bei
 *      �nderungen der Position, Gr��e oder des sichtbaren Ausschnitts
 *      des Fensters wird das Anwenderprogramm nicht ben�tigt, dies wird
 *      genauso wie das eventuelle Neuzeichnen von Teile des Fensterin-
 *      halts selbst�ndig von 'TextWindows' erledigt.
 *      Lediglich bei komplexeren Aktionen, wie dem Ausw�hlen von Zeichen
 *      innerhalb des Fensters mit der Maus, oder dem mehr oder weniger
 *      beliebigen Schlie�en des Fensters, durch das Schlie�symbol, mu�
 *      die Anwendung dem Modul ein wenig unter die Arme greifen.
 *
 *      Au�erdem wird von den Ausgaberoutinen des Moduls auch der VT-52
 *      Emulator unterst�tzt. Dieser kann aber auch unterdr�ckt werden.
 *
 *      Erweiterung des VT-52-Emulators:
 *
 *              ESC+CTRL-E  -- Schaltet 'EnhancedOutput' an
 *              ESC+CTRL-F  -- Schaltet 'EnhancedOutput' aus
 *              ESC+CTRL-P  -- Flush
 *
 *          (siehe Funktionen 'EnhancedOutput' und 'FlushPipe')
 *
 *
 *      Bei jeder Eingabe, zum Beispiel mittels 'ReadString', kann der
 *      Anwender auch die Fensterelemente manipulieren und damit bei-
 *      spielsweise die Fenstergr��e oder den sichtbaren Ausschnitt
 *      �ndern. Falls allerdings l�ngere Zeit keine Eingabe stattfindet
 *      und trotzdem eine Bedienung der Fensterelemente gew�nscht ist,
 *      kann dies mit wiederholten Aufrufen von 'EventHandler.FlushEvents'
 *      erm�glicht werden.
 *)
 

FROM MOSGlobals IMPORT Key;

FROM GEMGlobals IMPORT GemChar, SpecialKeySet;

FROM GrafBase   IMPORT Point, Rectangle;


TYPE    Window;
        
        (*  Legt das Verhalten eines Fensters bei einer Ausgabe fest.
         *
         *    'noForce'     -- Kein besonderes Verhalten.
         *    'forceTop'    -- Das Fenster wird bei jeder Ausgabe zum ober-
         *                     sten Fenster gemacht.
         *    'forceLine'   -- Das Fenster wird zum obersten Fenster und zu-
         *                     s�tzlich in der Vertikalen derart gescrollt,
         *                     da� die Zeile in der sich der Cursor befindet
         *                     sichtbar ist.
         *    'forceCursor' -- Das Fenster wird zum obersten Fesnter und
         *                     au�erdem in der Vertikalen und Horizontalen
         *                     derart gescrollt, da� der Cursor sichtbar
         *                     ist.
         *)
        ForceMode       = (noForce, forceTop, forceLine, forceCursor);
        
        (*  Legt das Aussehen und die M�glichkeiten eines Fensters fest.
         *
         *  'movable'   -- Das Fenster kann vom Anwender verschoben
         *                 werden.
         *  'closable'  -- Das Fenster besitzt ein Schlie�feld.
         *  'dynamic'   -- Das Fenster kann sowohl vom Anwender gescrollt,
         *                 als auch in der Gr��e ver�ndert werden.
         *  'titled'    -- Das Fenster besitzt eine Titelzeile.
         *)
        WindowQuality   = (movable, closable, dynamic, titled);
        WQualitySet     = SET OF WindowQuality;
        
        (*  Legt fest ob ein Fenster bei seiner Erzeugung sofort ge�ffnet
         *  wird.
         *
         *  'noHideWdw' -- Das Fenster wird ge�ffnet.
         *  'hideWdw'   -- Das Fenster wird nicht ge�ffnet.
         *)
        ShowMode        = (noHideWdw, hideWdw);


CONST    (*  Bezeichnet eine unbesetzte Fensterkennung.
          *)
         NoWind          = Window (NIL);

        CenterWindow    = -1;
        MaxWindow       = -1;


                (*  Fensterverwaltungsprozeduren  *)
                (*  ============================  *)

PROCEDURE Open (VAR hdl            : Window;
                    columns, rows  : CARDINAL;
                    qualitys       : WQualitySet;
                    mode           : ShowMode;
                    force          : ForceMode;
                    wName          : ARRAY OF CHAR;
                    colOrg, rowOrg,
                    wOrg, hOrg     : INTEGER;
                VAR success        : BOOLEAN);
               
        (*  Diese relativ komplexe Routine erf�llt im wesentlichen nur einen
         *  Zweck, sie erzeugt ein neues Fenster. Da hierbei schon der Grund-
         *  stein f�r das sp�tere Verhalten des Fensters gelegt wird, m�ssen
         *  einige Parameter �bergeben werden.
         *  'columns' und 'rows' bestimmen die Anzahl der f�r dieses Fen-
         *  ster verwendeten Spalten und Zeilen. Die einzige Beschr�nkung
         *  f�r diese zwei Werte ist, da� ihr Produkt nicht in die N�he von
         *  'MaxCard' kommen darf.
         *  'qualitys' gliedert sich wie folgt:
         *
         *  'movable'  -- Der Anwender darf die Position des Fensters auf
         *                dem Bildschirm mit der Maus ver�ndern
         *  'closable' -- In der linken, oberen Ecke des Fensters erscheint
         *                ein Symbol, das es dem Anwender erlauben soll das
         *                Fenster zu schlie�en. Nach dem Anklicken des Sym-
         *                bols gilt: 'WasClosed(hdl) = TRUE' (Siehe Unten)
         *                Achtung: F�r das eigentliche Schlie�en des Fen-
         *                         sters mu� das Anwendungsprogramm sorgen.
         *  'dynamic'  -- Ein Fenster mit diesem Feature kann vom Anwender
         *                zum einen in seiner Gr��e ver�ndert werden, zum
         *                anderen kann er mit den Fensterschiebern w�hlen
         *                welchen Ausschnitt des Fensterinhaltes er be-
         *                trachten will.
         *  'titled'   -- Solch ein Fenster besitzt einen Fensternamen.
         *
         *  Die einzelnen Elemente sind beliebig kombinierbar.
         *
         *  'show' bestimmt ob das Fenster sofort auf dem Bildschirm sicht-
         *  bar gemacht werden soll.
         *  'force' bestimmt auf welche Art und Weise das Fenster bei Ausga-
         *  ben reagieren soll.
         *  'wName' ist nichts weiter als der Fenstername oder -titel, er
         *  erscheint in einem Balken �ber dem Arbeitsbereich des Fensters.
         *  Die Zeichenkette wird nur ber�cksichtigt, falls 'titled' Element
         *  von 'qualitys' ist.
         *  'colOrg' und 'rowOrg' bestimmen die Startposition, 'wOrg' und
         *  'hOrg' die Startgr��e des Fensters. Diese Angaben werden alle
         *  in Zeichenkoordinaten (nicht Pixelkoordinaten) gemacht. Ist
         *  eine der Positionen 'CenterWdw', so wird das Fenster in dieser
         *  Achse auf dem Bildschirm mittig dargestellt. Ist eine Gr��enangabe
         *  gleich 'MaxWdw', so wird dort die Maximalgr��e gew�hlt.
         *
         *  Ist 'success = TRUE', so konnte das Fenster korrekt erzeugt
         *  werden und 'hdl' enth�lt die Fensterkennung.
         *
         *  Bei jedem 'Open' erh�lt der Mauszeiger die Pfeilform.
         *
         *  'columns * rows' darf 65535 nicht �berschreiten, sonst
         *  wird 'success = FALSE' geliefert.
         *
         *  Bei sehr kleinen Fenster, die Slider besitzen, kann es passieren,
         *  da� der Arbeitsbereich des Fensters gr��er ist als der Textpuffer.
         *  Das Modul benutzt dann nur den linken oberen Bereich.
         *)
         
PROCEDURE SysOpen (VAR hdl           : Window;
                       columns, rows : CARDINAL;
                       qualitys      : WQualitySet;
                       mode          : ShowMode;
                       force         : ForceMode;
                       wName         : ARRAY OF CHAR;
                       colOrg, rowOrg: INTEGER;
                       wOrg, hOrg    : INTEGER;
                   VAR success       : BOOLEAN);
                   
        (*  Entspricht 'Open' vollst�ndig.
         *  Diese Routine ist f�r das Fenster�ffnen durch Systemroutinen,
         *  oder residente Routine gedacht.
         *)
                  
PROCEDURE ReSpecify (hdl           : Window;
                     columns, rows : CARDINAL; wName : ARRAY OF CHAR;
                     VAR success   : BOOLEAN);
                     
        (*  Mit dieser Prozedur k�nnen sowohl der Name als auch die Ausma�e
         *  eines Fensters oder der Zeichensatz (Font) ge�ndert werden.
         *  Mit den Ausma�en ist in diesem Fall nicht die Gr��e des
         *  sichtbaren Fensters, sondern die des Textpuffers, von dem man
         *  in der Regel nur einen Ausschnitt sieht, gemeint.
         *  'wName', das den Fensternamen enth�lt, wird nur ber�cksichtigt,
         *  falls das Fenster beim �ffnen die 'WindowQuality' 'title'
         *  erhalten hat.
         *  Wird die Puffergr��e ge�ndert, so geht dabei der aktuelle Inhalt
         *  des Fensters verloren.
         *
         *  Um den Font zu setzen, ist f�r "columns" eine Null zu �bergeben.
         *  'rows' bestimmt dann die Zeichenh�he in Punkt (s. SetPtsTHeight)
         *  und 'wName' bestimmt den Namen des Fonts.
         *  Wird 'NoWind' in 'hdl' �bergeben, wird der Default-Font bestimmt,
         *  der beim �ffnen (Open()) aller neuen Fenster benutzt wird.
         *  Ansonsten wird der aktuelle Font des anggebenen Fensters ersetzt.
         *)
                     
PROCEDURE Close (VAR hdl: Window);

        (*  Mit dieser Routine wird ein Fenster geschlossen, genauer ge-
         *  l�scht. Das bedeutet, da� es vom Bildschirm genommen und seine
         *  Fensterkennung freigegeben wird.
         *  Wird die Kennung danach noch einmal benutzt, so l��t dies einen
         *  Laufzeitfehler aus.
         *)

PROCEDURE Hide (hdl: Window);

        (*  Das Fenster wird unsichtbar, ist aber nach wie vor im Speicher
         *  vorhanden und sowohl Ausgabe- als auch Eingabeoperationen k�n-
         *  nen get�tigt werden. Bei Letzterem kann der Anwender aber nicht
         *  kontollieren, was er tut.
         *)

PROCEDURE Show (hdl: Window);

        (*  Das Fenster wird, falls es versteckt war, wieder sichtbar
         *  gemacht.
         *)

PROCEDURE GetPosAndSize (hdl: Window; VAR col, row, w, h: INTEGER);

        (*  Erfragt sowohl Position, als auch Gr��e des Fensters mit
         *  der Kennung 'hdl'. Die Angaben werden in Zeichenkoordina-
         *  ten gemacht.
         *)

PROCEDURE SetPosAndSize (hdl: Window; col, row, w, h: INTEGER);

        (*  Setzt Position und Gr��e des Fensters.
         *
         *  Die Angaben m�ssen in Zeichenkoordinaten gemacht werden.
         *)

PROCEDURE IsTop (hdl: Window): BOOLEAN;

        (*  Liefert den Wert 'TRUE', falls das angegebene Fenster das
         *  Oberste aller Fenster ist.
         *)

PROCEDURE PutOnTop (hdl: Window);

        (*  Macht das Fenster zum Obersten und damit auch zum aktiven
         *  Fenster.
         *)

PROCEDURE WasClosed (hdl: Window): BOOLEAN;

        (*  Falls das Fenster die 'WindowQuality' 'closable' besitzt und
         *  der Anwender das Schlie�symbol des Fensters angeklickt hat,
         *  so ist das Ergebnis 'TRUE'.
         *
         *  Hinweis: Durch das Anklicken verschwindet das Fenster noch
         *           nicht vom Bildschirm, dazu mu� erst die Prozedur
         *           'Hide' oder 'Close' aufgerufen werden.
         *)


                        (*  Allgemeine Ein-/Ausgabeprozeduren  *)
                        (*  =================================  *)

PROCEDURE Write (hdl: Window; ch: CHAR);

        (*  Das Zeichen 'ch' wird im Fenster, das die Kennung 'hdl' besitzt,
         *  an der Cursorposition ausgegeben.
         *)

PROCEDURE WriteString (hdl: Window; REF str: ARRAY OF CHAR);

        (*  Die komplette Zeichenkette 'str' wird in das Fenster mit der
         *  Kennung 'hdl' ausgegeben.
         *)

PROCEDURE WriteLn (hdl: Window);

        (*  Schickt einen Zeilenvorschub- und einen Wagenr�cklaufbefehl
         *  an das angegebene Fenster (ASCII 10 und 13).
         *)

PROCEDURE WritePg (hdl: Window);

        (*  Der Inhalt des Fensters mit der Kennung 'hdl' wird gel�scht.
         *  Der Cursor steht danach in der linken oberen Ecke.
         *)

PROCEDURE GotoXY (hdl: Window; column, row: CARDINAL);

        (*  Der Textcursor des Fensters 'hdl' wird in die Spalte 'column'
         *  und die Zeile 'row' positioniert.
         *)


PROCEDURE Read (hdl: Window; VAR ch: CHAR);

        (*  Es wird ein Zeichen 'ch' gelesen, dabei wird der Cursor im
         *  Fenster 'hdl' sichtbar gemacht und das Zeichen wird in diesem
         *  Fenster an der Cursorposition dargestellt.
         *  Wurden vorher Ausgaben durch den Enhanced-Modus unterdr�ckt,
         *  so werden sie hier automatisch nachgeholt.
         *)

PROCEDURE ReadLine (hdl: Window; VAR str: ARRAY OF CHAR);

        (*  Es wird eine Zeichenkette, von der Tastatur gelesen. Das
         *  Echo wird in dem Fenster mit der Kennung 'hdl' ausgegeben,
         *  au�erdem l��t sich die Zeichenkette editieren.
         *  Nachdem ein <Return> die Eingabe beendet hat, wird der
         *  Cursor an das Ende der eingegebene Zeichenkette gestellt.
         *  Abbruch m�glich mit Undo-Taste - dann wird ein Leerstring
         *  in 'str' geliefert und 'Done' liefert FALSE.
         *  Es k�nnen nur soviele Zeichen eingegeben werden, wie 'str'
         *  fassen kann.
         *  Ist der Modus 'writeCtrl' (s. Funktion 'SetCtrlMode') aktiv,
         *  k�nnen auch Control-Zeichen sichtbar eingegeben werden.
         *)

PROCEDURE EditLine (hdl: Window; VAR str: ARRAY OF CHAR);

        (*  Wie ReadLine, jedoch mu� 'str' schon beim Aufruf einen String
         *  enthalten, der dann angezeigt und editiert werden kann.
         *)

PROCEDURE ReadToken (hdl: Window; VAR str: ARRAY OF CHAR);

        (*  Wie ReadLine, jedoch kann nur ein Wort ("Token") eingeben werden:
         *  F�hrende Leerzeichen (und Control-Zeichen) werden ignoriert,
         *  nach Eingabe eines g�ligen Zeichens wird beim n�chsten Leer- oder
         *  Control-Zeichen die Eingabe beendet.
         *  Das Terminierungszeichen kann durch Aufrufe von
         *   'UndoRead' und 'GetChar' ermittelt werden.
         *)

PROCEDURE ReadString (hdl: Window; VAR str: ARRAY OF CHAR);

        (*  Identisch mit 'ReadLine'.
         *)

PROCEDURE Done (hdl: Window): BOOLEAN;

      (*  Liefert FALSE nach Aufrufen der String-Eingabefunktionen (Read...,
       *  Edit...), wenn Undo gedr�ckt wurde.
       *  Hat keine Wirkung bei Einzel-Eingaben, wie Read, BusyRead, usw.
       *)


PROCEDURE AbortRead (hdl: Window);

        (*  Diese Funktion kann in "WatchDog"-Routinen (s. EventHandler)
         *  aufgerufen werden, um die evtl. zu der Zeit auf Eingaben
         *  wartende Read-Funktion (Read, ReadString, EditLine, usw.)
         *  zum Abbruch zu veranlassen. Wird dann der aufgetretene Event,
         *  �ber den der WatchDog wachte, durchgelassen, kann die Read-
         *  Funktion zur�ckkehren - Done ist dann FALSE, ein leerer
         *  String (bzw 0C bei Read) wird zur�ckgegeben, so, als wenn
         *  der Anwender die Undo-Taste gedr�ckt h�tte.
         *
         *  Zur Anwendung kommt diese Funktion in Accessories, die
         *  die Read-Funktionen von TextWindows verwenden. Denn es ist
         *  dann m�glich, w�hrend z.B. ReadString auf die Eingabe wartet,
         *  da� der Anwender ein Fenster der Hauptanwendung anklick und
         *  dann das Hauptprogramm zum Beenden veranla�t. Dann schlie�t
         *  das GEM automatisch das Fenster des Accessories, soda� dessen
         *  Read-Eingabe nicht mehr abgeschlossen werden kann. Hier mu�
         *  deshalb ein WatchDog vom ACC installiert sein, der darauf
         *  achtet, ob ein Message-Event an das ACC gesendet wird, wonach
         *  es nun seine Fenster zu schlie�en hat. In diesem Fall mu� dann
         *  AbortRead auf das Fenster der laufenden Eingabe angewendet
         *  werden.
         *
         *  Ist das Fenster 'hdl' nicht offen oder findet z.Zt. keine
         *  Eingabe darin statt, wird der Aufruf ignoriert.
         *)


(*      Die folgenden Routinen stellen reine Eingabeoperationen dar,
 *      sie ver�ndern den Bildschirminhalt nicht. Deshalb mu� auch keine
 *      Fensterkennung angegeben werden.
 *)

PROCEDURE UndoRead;

        (*  (Auch "ReadAgain" in anderen Dialekten)
         *  Das zuletzt gelesene Zeichen wird bei der n�chsten Abfrage
         *  nochmal geliefert.
         *)

PROCEDURE KeyPressed (): BOOLEAN;

        (*  Liefert diese Funktion den Wert 'TRUE', so wurde eine Taste
         *  gedr�ckt.
         *)

PROCEDURE CondRead (VAR ch: CHAR; VAR success: BOOLEAN);

        (*  Falls eine Taste ger�ckt wurde, so wird diese in 'ch' gelesen.
         *  Ist 'success = TRUE', so ist der Wert von 'ch' g�ltig.
         *)

PROCEDURE BusyRead (VAR ch: CHAR);

        (*  Falls eine Taste ger�ckt wurde, so wird diese in 'ch' gelesen,
         *  sonst kehrt die Routine sofort zur�ck und liefert 0C. Kein Echo.
         *)

PROCEDURE FlushKbd;

        (*  L�scht den Tastaturpuffer.
         *)

PROCEDURE GetChar (VAR ch: CHAR);

        (*  Wartet bis eine Taste gedr�ckt wird und liefert deren Wert.
         *  Kein Echo.
         *)

PROCEDURE GetGemChar (VAR ch: GemChar; VAR specials: SpecialKeySet);
PROCEDURE GetKey (VAR k: Key);

        (*  Warten auf einen Tastendruck und liefert ASCII- und Scancode,
         *  sowie die Sondertasten.
         *)


                (*  Spezielle Textfensterprozeduren  *)
                (*  ===============================  *)

PROCEDURE GetPos (hdl: Window; VAR column, row: CARDINAL);

        (*  Ermittelt die Position des Cursors im Fenster mit der Kennung
         *  'hdl'. 'column' enth�lt die Spalte und 'row' die Zeile.
         *)

TYPE    CtrlMode        = (interpretCtrl, writeCtrl);

PROCEDURE SetCtrlMode (hdl: Window; mode: CtrlMode);

        (*  Hiermit stellt man den Modus f�r die Ausgabe von Kontrollzeichen
         *  in das Fenster mit der Kennung 'hdl' ein. Dabei gilt:
         *
         *  'interpretCtrl' -- Die ASCII-Zeichen mit einer Ordinalzahl klei-
         *                     ner 32 werden als Steuerzeichen interpretiert.
         *                     Dies ist der Standardwert.
         *  'writeCtrl'     -- Zu jedem ASCII-Wert wird das im Zeichensatz
         *                     zugeh�rige Zeichen ausgegeben.
         *)

PROCEDURE GetCtrlMode (hdl: Window; VAR mode: CtrlMode);

        (*  Erfragt den mit 'SetCtrlMode' gesetzten Wert.
         *)


TYPE    EchoMode        = (fullEcho, restrictedEcho, noEcho);

PROCEDURE SetEchoMode (hdl: Window; mode: EchoMode);

        (*  Hier mit wird die Art und Weise des Echos bei Eingaberoutinen
         *  festgelegt. 'mode' kann folgende Werte annehmen:
         *
         *  'fullEcho'       -- Zu jedem eingegebenen Zeichen wird ein Echo
         *                      ausgegeben. Also auch bei Steuerzeichen.
         *  'restrictedEcho' -- Bei jedem Zeichen, dessen Ordinalzahl gr��er
         *                      als 32 ist, wird ein Echo ausgegeben.
         *                      Dies ist der Standardwert.
         *  'noEcho'         -- Es wird grunds�tzlich kein Echo ausgegege-
         *                      ben.
         *)

PROCEDURE GetEchoMode (hdl: Window; VAR mode: EchoMode);

        (*  Diese Funktion liefert den mit 'SetEchoMode' eingestellten Wert.
         *)


PROCEDURE EnhancedOutput (hdl: Window; start: BOOLEAN);

        (*  Diese Routine erm�glicht es, gr��ere Zeichenmengen beschleunigt
         *  auszugeben.
         *  Dazu mu� diese Prozedur vor der Ausgabe mit 'start = TRUE'
         *  und nach Beendigung der Ausgabe mit 'FALSE' aufgerufen werden.
         *  W�hrend dieser Zeit ist der Anwender nicht in der Lage Fenster-
         *  elemente, oder eine eventuell vorhandene Menuzeile zu manipu-
         *  lieren. Auch werden im ung�nstigsten Fall erst zum Ende die
         *  bis dahin ausgegebenen Zeichen angezeigt.
         *  Wird eine Routine aufgerufen, die auf eine Eingabe wartet
         *  (Read, ReadString, ReadLine, ReadToken, EditLine, jedoch
         *  nicht CondRead, BusyRead), dann wird automatisch 'FlushPipe'
         *  (s.u.) aufgerufen, dieser spezielle 'Enhanced'- Ausgabemodus
         *  bleibt aber intakt.
         *
         *  Ein Programm kann auch einmal zu Beginn den "Enhanced"-Modus
         *  aktivieren und dann nicht mehr abschalten. Es bleibt dann
         *  immer aktiv, bei Eingaben oder durch 'FlushPipe' kann trotzdem
         *  alles Ausgegebene zwischendurch sichtbar werden.
         *
         *  Die Ausgabe von ESC und Ctrl-E/-F haben dieselbe Wirkung
         *)

PROCEDURE FlushPipe (hdl: Window);

        (*  Erzwingt die Ausgabe alle Zeichen, die bisher gepuffert wurden,
         *  der Pufferungs-Modus ("Enhanced") bleibt weiterhin aktiv.
         *
         *  Ausgabe von ESC & Ctrl-P hat die gleiche Wirkung.
         *)


TYPE    DetectMode      = (takePnt, requestPnt);
        DetectResult    = (foundNothing, foundWindow, foundChar);

PROCEDURE DetectChar (REF targets: ARRAY OF Window;
                          noTrg  : CARDINAL;
                          mode   : DetectMode;
                      VAR p      : Point;
                      VAR hdl    : Window;
                      VAR column,
                          row    : CARDINAL;
                      VAR box    : Rectangle;
                      VAR result : DetectResult);
                    
        (*  Diese Routine erlaubt es beliebige Bildschirmpositionen darauf-
         *  hin zu untersuchen, ob sich dort ein Fenster oder sogar ein Zei-
         *  chen befindet.
         *  In 'targets' werden die Kennungen aller Fenster abgelegt, die
         *  untersucht werden sollen. 'noTrg' gibt an, wieviele Elemente
         *  in 'targets' enthalten sind. Ist 'noTrg' gleich Null, so werden
         *  alle Feldelemente ausgewertet.
         *  'mode' bestimmt, ob die Anwendung der Routine einen Punkt in 'p'
         *  �bergibt, der ausgewertet werden soll ('mode = takePnt') oder
         *  ob die Prozedur selber auf einen Druck der linken Maustaste
         *  wartet und die Position des Mauszeigers f�r den Suchvorgang be-
         *  nutzt und anschlie�end in 'p' zur�ckliefert ('requestPnt').
         *  Das Ergebenis ('result') unterscheidet drei M�glichkeiten:
         *
         *  'foundNothing' -- An der Stelle 'p' befindet sich "nichts".
         *  'foundWindow'  -- Es befindet sich dort ein beliebiges Fenster.
         *                    Dies Fenster mu� nicht in 'targets' enthalten
         *                    sein.
         *  'foundChar'    -- An dem Ort 'p' befindet sich erstens ein Fen-
         *                    ster aus 'targets' und zweitens Zeichen, das
         *                    in dem Fenster steht.
         *
         *  Befindet sich der Stelle 'p' ein Fenster, das in 'targets' aufge-
         *  f�hrt ist, gleichg�ltig ob Fensterinneres oder -au�enbereich, so
         *  liefert 'hdl' die Kennung dieses Fensters, sonst ist 'hdl =
         *  NoWind'. Ist 'result = foundChar', so liefert 'column' die Spal-
         *  te und 'row' die Zeile des gefundenen Zeichens, innerhalb des
         *  Fensters 'hdl'. Au�erdem enth�lt 'box' die, das Zeichen umge-
         *  bende Zeichenzelle.
         *)

PROCEDURE ReadTextBuffer (    wdw     : Window;
                              startCol,
                              startRow,
                              amount  : CARDINAL;
                          VAR buffer  : ARRAY OF CHAR;
                          VAR nextCol,
                              nextRow : CARDINAL);

        (*  Lie�t den Puffer ab 'startCol/startRow' aus und schreibt ihn
         *  in 'buffer'. Sind 'amount' Zeichen gelesen, oder ist das Puffer-
         *  ende erreicht, ohne das 'buffer' zu Ende ist, so wird ein 0C
         *  geschrieben. Die Zeilenenden sind durch CR+LF gekennzeichnet,
         *  wobei white spaces unterdr�ckt werden. Ein Wechsel von inverser
         *  auf normale Darstellungsart und umgekehrt wird durch die VT52
         *  ESC-Sequenzen angezeigt.
         *)
         
         
END TextWindows.