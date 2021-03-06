/*
   Modul: M_ADVANC (Headerdatei)

   geschrieben von:
   
   Thomas K�nneth
   Friedrich-Neuper-Str. 2b
   90552 R�thenbach

	und
	
	Dirk Stadler
	Friedrich-K�nig Weg 4
	90513 Zirndorf
	
   Diese Datei ist Bestandteil der C-Version von Magic 4.0 von
   Peter Hellinger und Thomas K�nneth und darf nur gem�� den
   Nutzungsbedingungen von Magic f�r C verwendet werden

   Alle Rechte bei den Autoren
*/

#ifndef _MPADVANC_
#define _MPADVANC_

#ifndef _MAGICTYP_
#include <magic\m_types.h>
#endif

/* Modus-flags */

                              /* Generelle Flags                                 */
                              /*-------------------------------------------------*/
#define fbRedraw     lBit0;   /* List- bzw. Dropbox nach dem F�llen neu anzeigen */
#define fbOneSpace   lBit1;   /* 1 Leerzeichen vor dem Eintrag lassen            */
#define fbTwoSpace   lBit2;   /* 2 Leerzeichen vor dem Eintrag lassen            */

                              /* Bits f�r Fillfontbox                            */
                              /*-------------------------------------------------*/
#define fbAll        lBit8;   /* Alle Fonts in die Listbox                       */
#define fbBitmap     lBit9;   /* Nur Bitmapfonts in die Listbox                  */
#define fbSpeedo     lBit10;  /* Nur Speedofonts in die Listbox                  */
#define fbTTF        lBit11;  /* Nur Truetypefonts in die Listbox                */
#define fbType1      lBit12;  /* Nur Postscriptfonts in die Listbox              */
#define fbMono       lBit13;  /* Nur monospaced Fonts in die Listbox             */
#define fbMarkMono   lBit14;  /* monospaced speziell Markieren                   */

                              /* Bits f�r Fillcolorbox                           */
                              /*-------------------------------------------------*/
#define fbEnglish    lBit8;   /* Texte in englischer Sprache                     */



void FillFontbox(OBJECT *tree, int item, int ws, int Default, LONGBITSET mode);
/* F�llt eine List- oder Dropbox mit eine Liste von Fonts 
 *
 * tree = Adresse des Objektbaums der Listbox 
 * item = Objektnummer der Listbox 
 * ws =   Handle der Workstation
 * mode = Modus
 *
 * Wenn man den Inhalt eines Listboxeintrags einer mit dieser Funktion
 * gef�llten Listbox mit GetEntry abfragt, erh�lt man im Parameter 'data'
 * einen Zeiger auf ein Datenfeld vom Typ PtrFONT.
 */

void FillDriverbox(OBJECT *tree, int item, Device dev, int Default, LONGBITSET mode);
/* F�llt eine List- oder Dropbox mit eine Liste von VDI-Treibern 
 *
 * tree = Adresse des Objektbaums der Listbox 
 * item = Objektnummer der Listbox 
 * dev =  Device das behandelt werden soll
 * mode = Nur allgemeine Funktionen
 *
 * Wenn man den Inhalt eines Listboxeintrags einer mit dieser Funktion
 * gef�llten Listbox mit GetEntry abfragt, erh�lt man im Parameter 'data'
 * gewandelt in ein INTEGER (physnum:= INTEGER (data);) die physikalische 
 * Devicenummer.  Diese braucht man zum gezielten �ffnen des jeweiligen Ger�ts!
 */

void FillFilebox(OBJECT *tree, int item, int Default, char *path, LONGBITSET mode);
/*
 * NOCH NICHT IMPLEMENTIERT!!!
 *
 * F�llt eine List- oder Dropbox mit eine Liste von Files 
 *
 * tree = Adresse des Objektbaums der Listbox 
 * item = Objektnummer der Listbox 
 * path = Laufwerk und Pfad, das behandelt werden soll
 * mode = Nur allgemeine Funktionen
 *
 * Wenn man den Inhalt eines Listboxeintrags einer mit dieser Funktion
 * gef�llten Listbox mit GetEntry abfragt, erh�lt man im Parameter 'data'
 * einen Zeiger auf folgende Struktur:
 */

void FillColorbox(OBJECT *tree, int item, int Default, LONGBITSET mode);

#endif /*_MPADVANC_*/