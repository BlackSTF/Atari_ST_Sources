DEFINITION MODULE AESObjects;


(*  Megamax-Modula 2 GEM-Library :  Die AES Objektfunktionen
 *
 *  Autor: Manuel Chakravarty           Erstellt :  05.11.87
 *
 *  Version   2.2     V#0010
 *)
 
(*      In diesem Modul befinden sich die AES Routinen, die zur allgemeinen
 *      Manipulation von Objektb�umen dienen.
 *)
 
 
FROM    GrafBase   IMPORT Point, Rectangle;

FROM    GEMGlobals IMPORT PtrObjTree, OStateSet, GemChar;
 
 
                (*  Object Manager  *)
                (*  ==============  *)

PROCEDURE AddObject (tree: PtrObjTree; parent, child: CARDINAL);

        (*  Ein Objekt wird in die Nachfolgerliste eines anderen
         *  eingereiht.
         *
         *  Eingabeparameter
         *  ----------------
         *
         *  'child'     -- Index des Objekts, das in die Nachfolger-
         *                 liste von
         *  'parent'    -- eingereiht wird.
         *  'tree'      -- Sowohl 'parent' als auch 'child' mu�
         *                 Element diese Objekbaumes sein.
         *)
        
PROCEDURE DeleteObject (tree: PtrObjTree; index: CARDINAL);

        (*  Ein Objekt wird aus einem Objektbaum entfernt.
         *
         *  'index'     -- Das zu entferndende Objekt
         *  'tree'      -- Der Objektbaum, dessen Element 'index' sein mu�.
         *)

PROCEDURE DrawObject (tree       : PtrObjTree;
                      start,depth: CARDINAL;
                      frame      : Rectangle);
                      
        (*  Ein Objektbaum wird bis zu der gew�nschten Tiefe auf dem
         *  Bildschirm dargestellt. Es werden nur die Teile sichtbar,
         *  die sich innerhalb eines angegebenen Rahmens befinden.
         *  Diese Routine dient zum Beispiel zum Zeichnen von Dialogboxen.
         *
         *  'tree'      -- Der darzustellende Baum
         *  'start'     -- Der Index, ab dem der Baum dargestellt werden
         *                 soll.
         *  'depth'     -- Bis zu dieser Tiefe wird der Baum dargestellt.
         *  'frame'     -- Es werden die Teile sichtbar, die in diesem
         *                 Rahmen liegen.
         *
         *  F�r 'depth' gilt:
         *
         *      0          -- Es wird nur das Startobjekt untersucht
         *      1          -- Startobjekt und die erste Ebene von Nachfolgern
         *      .
         *      .
         *      .
         *  'MaxDepth'     -- Maximale Tiefe
         *
         *  'MaxDepth' kann aus 'GEMGlobals' importiert werden.
         *)
        
PROCEDURE FindObject (tree        : PtrObjTree;
                      start, depth: CARDINAL;
                      spot        : Point     ): CARDINAL;
                      
        (*  Diese Prozedur sucht ein Objekt in einem Baum, das sich beim
         *  darstellen des Baumes an einer bestimmten Stellen auf dem
         *  Bildschirm befindet. Als Ergebnis wird der Index des Objekts
         *  geliefert.
         *
         *  'tree'      -- Der Objektbaum
         *  'spot'      -- Bezeichnet die Stelle, an der das Objekt auf
         *                 dem Bildschirm befindet.
         *  'start'     -- Die Suche im Baum beginnt bei diesem Index
         *  'depth'     -- Die Suchtiefe
         *
         *  Wird 'GEMGlobals.NoObject' zur�ckgegeben, so befindet sich
         *  an dieser Stelle kein Objekt. Zu 'depth' siehe 'DrawObject'.
         *)

PROCEDURE ObjectOffset (tree: PtrObjTree; index: CARDINAL): Point;

        (*  Diese Funktion liefert die Bildschirmposition auf der ein
         *  Objekt beim Zeichnen seines Baumes dargestellt wird.
         *
         *  'index'     -- Index des Objekts
         *  'tree'      -- der Objektbaum
         *)

PROCEDURE ObjectOrder (tree  : PtrObjTree;
                       index : CARDINAL;
                       newPos: INTEGER   );
                       
        (*  Ein Objekt wird in seiner Nachfolgerliste an ein neue Posi-
         *  tion bewegt.
         *
         *  'tree'      -- der Objektbaum
         *  'index'     -- das Objekt
         *
         *  Die Position wird von 'newPos' folgenderma�en bestimmt:
         *
         *    0    -- An die erste Stelle
         *    1    -- An die zweite Stelle
         *   usw.
         *
         *   -1    -- An die letzte Stelle
         *)
        

TYPE    EditObjMode     = (startEdit, initEdit, charEdit, endEdit);
        
PROCEDURE EditObjText (    tree   : PtrObjTree;
                           index  : CARDINAL;
                           ch     : GemChar;
                       VAR charPos: CARDINAL;
                           edKind : EditObjMode);
                      
        (*  Diese Routine macht einen Teil der Arbeit, die bei Edieren
         *  eines Edit-Feldes vom Anwender anf�llt.
         *
         *  'tree'      -- der Objektbaum
         *  'index'     -- das zu edierende Objekt
         *
         *  Weiter sind vier Modi zu unterscheiden:
         *  'startEdit' -- Wird in dieser GEM Version nicht unterst�tzt
         *  'initEdit'  -- Objektzeichenketten formatieren und Textcursor
         *                 einschalten
         *  'charEdit'  -- Ein Zeichen verarbeiten und dabei die Zeichen-
         *                 ketten und den Bildschirm aktuallisieren
         *  'endEdit'   -- Ende des Ediervorganges
         *
         *  Vor dem Aufruf dieser Routine mu� sich das Objekt schon auf
         *  dem Bildschirm befinden. Au�erdem mu� es vom Typ 'fText'
         *  oder 'fBoxText' sein.
         *  Im 'charEdit'-Modus mu� in 'ch' das Zeichen �bergeben werden,
         *  das an der Position 'charPos' in die Textzeichenkette des
         *  Objektes, eingef�gt werden soll. Bei der R�ckkehr steht in
         *  'charPos' daraufhin die Zeichenposition, in die als n�chste
         *  etwas geschrieben werden sollte. Die Routine wertet auch
         *  teilweise Tasten wie zum Beispiel Escape und Backspace aus.
         *)
        
PROCEDURE ChangeObjState (tree    : PtrObjTree;
                          index   : CARDINAL;
                          frame   : Rectangle;
                          newState: OStateSet;
                          redraw  : BOOLEAN);
                         
        (*  Diese Prozedur dient zum �ndern des Objektstatus eines Objektes
         *
         *  'index'     -- Index des Objekts
         *  'tree'      -- der Objektbaum
         *  'newState'  -- der neue Status
         *  'reDraw'    -- 'TRUE': das Objekt wird zus�tzlich neu gezeichnet
         *                 es sollte sich aber in diesem Fall schon auf dem
         *                 Bildschirm befinden.
         *
         *  Es ist darauf zu achten, da� pro Aufruf dieser Routine nur ein
         *  Element der Statusmenge ge�ndert wird.
         *)
        

END AESObjects.