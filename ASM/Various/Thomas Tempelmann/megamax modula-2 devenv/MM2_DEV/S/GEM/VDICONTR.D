DEFINITION MODULE VDIControls;


(*  Megamax-Modula 2 GEM-Library :  Die VDI Kontrollfunktionen
 *
 *  Autor: Manuel Chakravarty           Erstellt :  29.10.87
 *
 *  Version   2.2     V#0015
 *)
 
FROM    SYSTEM   IMPORT WORD;

FROM    GrafBase IMPORT Rectangle;
 
FROM    GEMEnv   IMPORT DeviceHandle;
 
 
PROCEDURE ClearWorkstation (handle: DeviceHandle);

        (*  L�scht den Arbeitsbereich oder l�st zum Beispiel bei Druckern
         *  einen Seitenvorschub aus.
         *)
                
PROCEDURE UpdateWorkstation (handle: DeviceHandle);

        (*  Ist f�r Bildschirmarbeitsstationen irrelevant, bei Arbeits-
         *  stationen, die die Ausgaben erst puffern (z.B.: Drucker)
         *  werden durch diesem Aufruf alle gepufferten Aktionen ausge-
         *  f�hrt.
         *)

PROCEDURE LoadFonts (    handle: DeviceHandle;
                         select: WORD;
                     VAR loaded: CARDINAL);

        (*  Damit k�nnen gem�� der Datei 'ASSIGN.SYS' (geh�rt zum optionalen
         *  GDOS) zus�tzliche Zeichens�tze geladen werden.
         *  'loaded' gibt an, wieviele Zeichens�tze nachgeladen wurden.
         *  'select' wird bisher nicht unterst�tzt.
         *  Im DEMO-Modul "TextDemo" finden Sie ein Beispiel, wie
         *  diese GDOS-Fonts benutzt werden.
         *)

PROCEDURE UnloadFonts (handle: DeviceHandle; select: WORD);

        (*  Die mit 'LoadFonts' nachgeladenen Zeichens�tze werden
         *  wieder aus dem Speicher entfernt. Die Zeichens�tze werden
         *  allerdings erst aus dem Speicher gel�scht, nachdem sie
         *  von allen Arbeitsstationen freigegeben wurden.
         *)

PROCEDURE SetClipping (handle: DeviceHandle; frame: Rectangle);

        (*  Mit dieser Procedur kann man erreichen, da� alle Ausgaben
         *  au�erhalb eines bestimmten Rechteckbereichs ('frame') unter-
         *  dr�ckt werden.
         *  Dabei ist zu beachten, da� dies bei den Rasterkopierroutinen
         *  nur f�r Speicherbereiche funktioniert, deren Startadresse mit
         *  'NIL' besetzt wurde. (siehe auch 'GEMRasters')
         *)
        
PROCEDURE DisableClipping (handle: DeviceHandle);

        (*  Hiernach werden alle Ausgaben wieder vollst�ndig durch-
         *  gef�hrt.
         *)
        
END VDIControls.