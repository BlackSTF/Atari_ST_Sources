DEFINITION MODULE GEMEnv;


(*      Megamax Modula-2 GEM Library: Diverse Kontrollfunktionen
 *
 *      Autor: Manuel Chakravarty       Erstellt: M�rz-Oktober 1987
 *
 *      Version 2.2     V#0062
 *)

(*      Mit den Routinen dieses Moduls kann sich eine Anwendung beim GEM
 *      An- und Abmelden, au�erdem erfolgt hier die Anmeldung weiterer
 *      VDI-Ger�te.
 *)
 
 
FROM GrafBase IMPORT Point, Rectangle;

FROM GEMGlobals IMPORT TEffectSet;


                        (*  Kontroll Funktionen  *)
                        (*  ===================  *)
                
                
TYPE    GemHandle;      (*  Dient zur Identifizierung einer kompletten
                         *  Anmeldung (per 'InitGem') beim GEM.
                         *  (GEM-Referenz)
                         *)

        DeviceHandle;   (*  Dient zur Identifizierung eines VDI-Ger�tes.
                         *  Siehe auch 'OpenDevice'. (Ger�te-Referenz)
                         *)
                         
                         
CONST   NoDevice        = DeviceHandle (NIL);   (* Wert f�r ein nicht besetz-
                                                 * tes Ger�te-handle
                                                 *)

        NDC             = 0;             (*  Normalisierte Koordinaten  *)
        RC              = 2;             (*  Raster Koordinaten  *)


PROCEDURE InitGem (    sysKoor: CARDINAL;
                   VAR handle : DeviceHandle;
                   VAR success: BOOLEAN);

        (*  Anmeldung einer Application beim GEM und Er�ffnen einer
         *  virtuellen Bildschirmarbeitsstation.
         *
         *  'sysKoor' -- Bestimmt das zu benutzenden Koordinatensystem,
         *               dabei steht 'RC' f�r Rasterkoordinaten und NDC
         *               f�r normalisierte Koordinaten.
         *  'handle'  -- Liefert die Ger�tereferenz der virtuellen Bild-
         *               schirmarbeitsstation. Diese Referenz mu� bei
         *               jedem VDI-Aufruf als erster Parameter angege-
         *               ben werden.
         *  'success' -- Meldet ob die Anmeldung erfolgreich verlaufen
         *               ist. Ist dies nicht der Fall, so ist auch der
         *               Wert von 'handle' ung�ltig.
         *
         *  Ein Aufruf dieser Prozedur sollte am Anfang jeder Benutzung
         *  der GEM Bibliothek stehen. Wird er nicht durchgef�hrt, so
         *  kann es zum Absturz des Systems kommen.
         *  Alternativ kann aber, wenn keine VDI-Funktionen ben�tigt
         *  werden, 'InitApplication' (s.u.) aufgerufen werden.
         *
         *  Falls die Prozedur 'GemActive' den Wert 'TRUE' liefert,
         *  sind AES-Aufruf ohne jede Vorbereitung und VDI-Aufruf nach
         *  dem Erzeugen einer (virtuellen) Arbeitstation mit 'OpenDevice'
         *  ohne Benutzung von 'InitGem' m�glich. Doch sollte
         *  diese Vorgehensweise nur in Ausnahmef�llen gew�hlt werden,
         *  da dann z.B. keine autom. Abmeldung von Fenstern u.�. bei
         *  Prozessende durchgef�hrt wird.
         *
         *  Die Variablen des Moduls 'PathEnv' werden zudem initialisiert:
         *
         *  'HomePath' wird in der Regel mit dem Pfad besetzt, von dem dies
         *  Programm stammt. Dies erlaubt dann z.B. die Verwendung von '*'
         *  (HomeSymbol) in Pfadlisten f�r 'Paths.SearchFile'. Siehe dazu
         *  die Hinweise im PathEnv-Modul!
         *
         *  'SelectFile' erh�lt je nach GEM-Version die Funktion 'SelectFile'
         *  bzw. 'SelectFileExtended' aus dem Modul 'AESMisc' zugewiesen.
         *
         *  ACHTUNG: Alle bisherigen GEM Versionen unterst�tzen nur
         *           Rasterkoordinaten um normalisierte Koordinaten
         *           benutzen zu k�nnen, mu� das GDOS geladen werden.
         *)

PROCEDURE GemActive (): BOOLEAN;

        (*  Erfragt, ob ein anderes Modul schon einen 'InitGem'- oder
         *  'InitApplication'-Aufruf get�tigt hat, d.h. ob ein benutz-
         *  barer 'GemHandle' vorhanden ist. (Siehe auch 'InitGem')
         *)

PROCEDURE ExitGem (VAR handle: GemHandle);

        (*  Dient zum Abmelden einer Application beim GEM.
         *
         *  Es werden autom. alle noch offenen Fenster geschlossen, alle
         *  angemeldeten Ger�te beim VDI abgemeldet und eventuell noch
         *  nicht r�ckg�nig gemachte 'HideCursor', 'WindowUpdate' etc.
         *  Aufrufe zur�ckgesetzt.
         *  Sobald ein Modul terminiert wird f�r jedes auf dieser Modul-
         *  ebene durchgef�hrten 'InitGem', welches noch nicht r�ckg�ngig
         *  gemacht wurde, ein 'ExitGem' durchgef�hrt, dies gilt insbe-
         *  sondere f�r Laufzeitfehler.
         *)


PROCEDURE InitApplication (VAR success: BOOLEAN);  (* "appl_init" *)

        (*  Wie 'InitGem', jedoch werden weder eine virtuelle "Workstation"
         *  mit 'OpenDevice' ge�ffnet, noch die PathEnv-Variablen initiali-
         *  siert. Diese Funktion kann statt 'InitGem' aufgerufen werden,
         *  wenn keine VDI-Funktionen benutzt werden. Dies ist beispielsweise
         *  bei vielen Accessories der Fall. Die Abmeldung kann mit
         *  'ExitGem (gemHandle)', wobei 'gemHandle' die mit 'CurrGemHandle'
         *  erfragte Referenz enthalten mu� oder mit 'ExitApplication'
         *  durchgef�hrt werden.
         *)

PROCEDURE ExitApplication ();  (* "appl_exit" *)

        (*  Abmeldung der mit 'InitApplication' durchgef�hrten AES-Anmeldung.
         *)


PROCEDURE GrafHandle (VAR charW, charH,
                          cellW, cellH: CARDINAL;
                      VAR hdl         : CARDINAL);

        (*  Ermittelt die VDI-Referenz, welche das AES bei seinem 'Open
         *  Workstation' Aufruf erhalten hat. Zus�tzlich werden noch die
         *  Ausma�e eines Zeichens des Systemzeichensatzes zur�ckgegeben.
         *
         *  'charW', 'charH',
         *  'cellW', 'cellH'  -- Ausma�e eines Zeichens des Systemzeichen-
         *                       satzes.
         *  'hdl'             -- VDI-Referenz des AES. Hiermit kann man
         *                       mit 'OpenDevice' weitere virtuelle Bild-
         *                       schirmarbeitsstationen er�ffnen.
         *
         *  ACHTUNG: Die Werte von 'charW', 'charH', 'cellW', cellH'
         *           werden vom GEM nicht korrekt geliefert. Daher
         *           ist von ihrer Verwendung abzuraten.
         *)


CONST   NonVirtual      = 0;    (*  Ger�t soll mit Open Workstation ge�ffnet
                                 *  werden.
                                 *)

PROCEDURE OpenDevice (dev, sysKoor, mode: CARDINAL; VAR hdl: DeviceHandle);

        (*  Dient zum �ffnen einer (virtuellen) Arbeitsstation.
         *
         *  Eingabeparameter:
         *  -----------------
         *
         *  'dev'     -- Gibt das zu �ffnende Ger�t an. Entspricht der
         *               in 'ASSIGN.SYS' angegebenen Ger�tenummer.
         *  'sysKoor' -- Bestimmt das zu benutzenden Koordinatensystem,
         *               dabei steht 'RC' f�r Rasterkoordinaten und NDC
         *               f�r normalisierte Koordinaten.
         *  'mode'    -- Wird hier 'NonVirtual' angegeben, so wird ein
         *               eine neue Arbeitsstation er�ffnet. Wird aber
         *               das VDI-Handle einer Arbeitsstation (z.B. mit
         *               'GrafHandle' ermittelt) �bergeben, so wird zu
         *               dieser Arbeitsstation eine virtuelle Arbeits-
         *               station ge�ffnet.
         *
         *  Ausgabeparameter:
         *  -----------------
         *
         *  'hdl'     -- Die neue Ger�tereferenz. Sie mu� bei jedem VDI-
         *               Aufruf, der an dieses Ger�t gehen soll als erster
         *               Parameter �bergeben werden.
         *
         *  ACHTUNG: Das �ffnen weitere nicht virtueller Arbeitsstationen
         *           ist nur mit geledenem GDOS m�glich.
         *)
         
PROCEDURE CloseDevice (handle: DeviceHandle);

        (*  Die (virtuelle) Arbeitsstation wird geschlossen.
         *
         *  Bei einem Aufruf von 'ExitGem', werden alle Ger�te, die unter
         *  dem abgemeldeten 'GemHandle' ge�ffnet wurden autom. geschlossen.
         *)
         
        
TYPE    GDPAttribute = (lineOp, markerOp, textOp, fillOp, noAttribute,
                        notAvaible);
        GDPFkt       = (barGDP, arcGDP, pieGDP, circleGDP, ellipseGDP,
                        eArcGDP,  ePieGDP, rRectGDP, fRectGDP, jTextGDP);
        InputDev     = (keybd, other);
        DeviceType   = (outDev, inDev, inoutDev, reservedDev, metafile);
        ScreenType   = (noScreen, difCtrlDifScrn, difCtrlSamScrn,
                        samCtrlDifMem, samCtrlSamMem);
        TextRotType  = (noTextRot, step90, everyDirec);
        
        PtrDevParm   = POINTER TO DevParm;
        DevParm      = RECORD
        
                         (*  Diese 4 Werte entsprechen den von
                          *  'GrafHandle' gelieferten Werten.
                          *)
                         charWidth, charHeight,
                         cellWidth, cellHeight,
                         
                         (*  Breite und H�he des Pixelrasters
                          *  [0..rasterWidth] und [0..rasterHeight]
                          *)
                         rasterWidth, rasterHeight,
                         
                         (*  Breite und H�he eines Pixels in mm/1000
                          *)
                         pointWidth, pointHeight,
                         
                         (*  Anzahl der Schriftgr��en (0 bed. kontinuierlich)
                          *)
                         fontSizes,
                         
                         (*  Anzahl der Linienarten und -st�rken
                          *  (bei Letzterem bedeutet 0 kontinuierlich)
                          *)
                         lTypes, lWidths,
                         
                         (*  Anzahl der Makierungsarten und -gr��en
                          *  (bei Letzterem bedeutet 0 kontinuierlich)
                          *)
                         mTypes, mSizes,
                         
                         (*  Anzahl der verf�gbaren Zeichens�tze
                          *)
                         fonts,
                         
                         (*  Anzahl der F�llmuster und Schraffuren
                          *)
                         fPatterns, fHatchings,
                         
                         (*  Anzahl der gleichzeitig darstellbaren Farben
                          *)
                         noColors,
                         
                         (*  Minimale und maximale Zeichenbreite und -h�he
                          *)
                         minWChar, maxWChar,
                         minHChar, maxHChar,
                         
                         (*  Minimale und maximale Zeilenbreite
                          *)
                         minWRow, maxWRow,
                         
                         (*  Minimale und maximale Breite und H�he
                          *  von Makierungen
                          *)
                         minWMark, maxWMark,
                         minHMark, maxHMark,
                         
                         (*  Anzahl der verf�gbaren Hintergrundfarben
                          *)
                         bgColors,
                         
                         (*  Anzahl der Farbebenen (planes)
                          *)
                         maxRasterPls,
                         
                         (*  Anzahl der 16x16 Pixel Rasteroperationen pro sec.
                          *)
                         op16PerSec,
                         
                         (*  Anzahl der Schreibmodi
                          *)
                         noWrtModes,
                         
                         (*  H�chster Eingabemodus (0 ~ keine Eingabe,
                          *  1 ~ Nachfragemodus, 2 ~ Testmodus)
                          *)
                         maxInMode,
                         
                         (*  Maximale Anzahl von Punkten in einem
                          *  Punkte-Array und maximale Anzahl von
                          *  Zeichen in einem Zeichen-Array
                          *)
                         maxMarker, maxStrLen,
                         
                         (*  Anzahl der Mauskn�pfe
                          *)
                         noMButts,
                         
                         (*  Anzahl der Zeichenmodi f�r verbreiterte Linien
                          *)
                         thickLnModes : CARDINAL;
                         
                         (*  Gibt die verf�gbaren grafischen
                          *  Grundfunktionen an
                          *)
                         possibleGDPs : ARRAY GDPFkt OF GDPAttribute;
                         
                         (*  Folgende Flags bestimmen ob gewisse
                          *  Operationen mit dem beschriebenen
                          *  Ger�t m�glich sind und zwar:
                          *)
                         color,         (*  Farbe                       *)
                         fill,          (*  F�llmuster                  *)
                         cArray,        (*  Cell-Arrays                 *)
                         zooming,       (*  Skalierung von Rastern      *)
                         lookUpTab,     (*  Color Look Up Table (CLUT)  *)
                         textJust,      (*  Textausrichtung             *)
                         contFill,      (*  contour fill                *)
                         penChange,     (*  Plotterstift austauschen    *)
                         colorRibbon,   (*  Farbband (Drucker)          *)
                         thickLnTyps    (*  verbreiterte Linientypen    *)
                                      : BOOLEAN;
                         
                         (*  Folgende Variable bestimmen das Eingabeger�t
                          *  f�r diverse Arten der Eingabe und zwar f�r:
                          *)
                         grafCCtrl,     (*  grafische Eingaben        *)
                         valueIn,       (*  Werteingaben              *)
                         caseIn,        (*  Auswahleingaben           *)
                         alphanumIn     (*  alphanumerische Eingaben  *)
                                      : InputDev;
                         
                         (*  Typ des beschriebenen Ger�tes
                          *)
                         deviceType   : DeviceType;
                         
                         (*  Art des Bildschirms
                          *)
                         screen       : ScreenType;
                         
                         (*  Unterst�tzte Texteffekte
                          *)
                         useTEffects  : TEffectSet;
                         
                         (*  Art der unterst�tzten Textrotation
                          *)
                         textRot      : TextRotType;
                         
                       END;
     
PROCEDURE DeviceParameter (handle: DeviceHandle): PtrDevParm;

        (*  Liefert die Ger�teparameter eines ge�ffneten Ger�tes.
         *
         *  'handle' -- Ger�tereferenz des Ger�tes von dem die Parameter
         *              ermittelt werden sollen.
         *)


PROCEDURE CurrGemHandle (): GemHandle;

        (*  Ermittelt die aktuelle GEM-Referenz ('GemHandle').
         *)

PROCEDURE SetCurrGemHandle (handle: GemHandle; VAR success: BOOLEAN);

        (*  Setzt die aktuelle GEM-Refrenz.
         *
         *  'handle'  -- Neu zu setzende GEM-Referenz.
         *  'success' -- Wird hier 'FALSE' geliefert, so ist 'handle'
         *               keine g�ltige GEM-Referenz und die aktuelle
         *               Refrenz wurde nicht ver�ndert.
         *)
         

                        (*  Fehlerbehandlung  *)
                        (*  ================  *)

VAR     ErrorProc: PROC;

PROCEDURE GemError (): BOOLEAN;

        (*  Ermittelt, ob beim letzten Aufruf einer GEM-Routine ein
         *  Fehler aufgetretten ist.
         *
         *  Tritt ein Fehler auf, der nicht mittels dieser Prozedur
         *  erfragt wird, so ruft die GEM-Bibliothek beim n�chsten
         *  Aufruf einer GEM-Routine die Prozedur 'ErrorProc' auf.
         *  Ist letztere von der Applikation nicht ver�ndert worden,
         *  so wird die Modula-Standardprozedur 'HALT' aufgerufen.
         *)

PROCEDURE ErrorNumber (): INTEGER;

        (*  Ermittelt im Fehlerfall den Fehler ausl�senden Wert.
         *
         *  Ist 'GemError () = TRUE', so liefert diese Funktion
         *  den INTEGER-Wert, der von der zuletzt benutzten ROM-
         *  Routine geliefert wurde, um den Fehler anzuzeigen.
         *)

VAR ErrHdlProc: PROC;

        (*  Wird bei Auftreten eines Fehlers aufgerufen.
         *  Die normalerweise hier installierte Routine tut nichts.
         *  Wenn aber �ber die 'ErrorProc' der Fehler gemeldet wird,
         *  kann hier�ber herausgefunden werden, _wo_ der Fehler
         *  auftrat.
         *)


                        (*   Nachfragefunktionen  *)
                        (*   ===================  *)
         
PROCEDURE GEMAvailable (): BOOLEAN;

        (*  Erfragt, ob das GEM schon initalisiert ist.
         *
         *  Dies ist zum Beispiel bei Auto-Ordner-Programmen nicht der
         *  Fall.
         *  Solange diese Routine kein 'TRUE' liefert ist eine Anmeldung
         *  mittels 'InitGem' sinnlos.
         *)

PROCEDURE GDOSAvailable (): BOOLEAN;

        (*  Liefert 'TRUE', sobald ein GDOS-Treiber vorhanden ist.
         *  Ber�cksichtigt auch das GEM 2.1 (liefert dort immer TRUE).
         *)

PROCEDURE GEMVersion (): CARDINAL;

        (*  Liefert die Versionsnummer, die das GEM beim Anmelden einer
         *  Applikation zur�ckgibt.
         *
         *  Das zuerst von Atari ausgelieferte TOS und das Blitter-TOS
         *  liefern den Wert $120, das TOS 1.4 den Wert $140.
         *
         *  ACHTUNG: Damit diese Routine funktionieren kann mu� die
         *           Funktionsprozedur 'GemActive' den Wert 'TRUE'
         *           liefern, also schon ein 'InitGem' durchgef�hrt
         *           sein.
         *)

PROCEDURE ApplicationID (): CARDINAL;

        (*  Liefert die GEM-Identifikationsnummer der aktuellen
         *  GEM-Refrenz.
         *)

PROCEDURE MaxPoints (): CARDINAL;

        (*  Liefert die maximale Anzahl der Punkte, die in einem Aufruf
         *  von 'PolyLine', 'PolyMarker', etc. verarbeitet werden k�nnen.
         *  Ein Wert von 0 bedeutet, da� die Anzahl nicht begrenzt ist.
         *)
         
         
(*   Jede der nachfolgenden Routinen erlaubtes einen Status abzufragen,
 *   der f�r Module die ihrerseits andere GEM benutzende Module aufrufen
 *   von Interesse sein kann. Ist z.B. 'NoUpdateWindow () # 0', so ist
 *   es nicht m�glich eine Menuzeile zu benutzen, man mu� also erst die
 *   entsprechende Anzahl von 'UpdateWindow (FALSE)' durchf�hren.
 *)
         
PROCEDURE NoHideCursor (device: DeviceHandle): CARDINAL;

        (*  Liefert die Anzahl der 'HideCursor'-Aufrufe, die noch nicht
         *  mit 'ShowCursor' r�ckg�nig gemacht wurden.
         *)

PROCEDURE NoGrafMouseOff (): CARDINAL;

        (*  Liefert die Anzahl der 'GrafMouse (mouseOff, NIL)'-Aufrufe,
         *  die noch nicht mit 'GrafMouse (mouseOn, NIL)' r�ckg�nig ge-
         *  macht wurden.
         *)

PROCEDURE NoUpdateWindow (): CARDINAL;

        (*  Liefert die Anzahl der 'UpdateWindow (TRUE)'-Aufrufe, die noch
         *  nicht mit 'UpdateWindow (FALSE)' r�ckg�nig gemacht wurden.
         *)

PROCEDURE NoMouseControl (): CARDINAL;

        (*  Liefert die Anzahl der 'MouseControl (TRUE)-Aufrufe, die noch
         *  nicht mit 'MouseControl (FALSE)' r�ckg�nig gemacht wurden.
         *)

PROCEDURE MouseInput (start: BOOLEAN);

        (*  Sorgt daf�r, da� der Mauszeiger, unabh�nig von seinem aktuellen
         *  Zustand, sichtbar wird. Dies ist zum Beispiel vor dem Benutzen
         *  einer Dialogbox sinnvoll.
         *
         *  TRUE  -- Der Mauszeiger wird sichtbar
         *  FALSE -- Der Mauszeiger erh�lt seinen alten Status wieder
         *
         *  HINWEIS: Diese Routine sollte normallerweise nicht benutzt
         *           werden. Sie ist systeminternen Funktionen vorbehalten.
         *)



PROCEDURE SysInitGem (    sysKoor: CARDINAL;
                      VAR handle : DeviceHandle;
                      VAR success: BOOLEAN);

PROCEDURE SysInitApplication (VAR success: BOOLEAN);

END GEMEnv.