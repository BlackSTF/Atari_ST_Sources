************************************************
* BHDI.S - Interface-Programm f�r ACSI-Ger�te  *
* aus "SCHEIBENKLEISTER"                       *
* V1.3, 21.1.90                                *
* Written & (C) 1989/90 by Claus Brod,         *
*      Am Felsenkeller 2, 8772 Marktheidenfeld *
*                                              *
* V0.1: READ und STDCMD begonnen               *
* V0.2: DMA-Modus-Bit 7 entr�tselt             *
* V0.3: neue Routinen sd2to5, sd1to5, sd1to6;  *
*       Statusdaten immer nach buf2            *
* V0.4: mdselect, mdsense eingebaut            *
* V0.5: Neue Routinen f�r Request Sense, Mode  *
*       Sense, Translate, Read/Reset Usage     *
*       Counter, Read Data Buffer, Write Data  *
*       Buffer, Set Error Threshold, Receive/  *
*       Send Diagnostic; read/write allgemeiner*
* V0.6: send diagnostic und format entwanzt    *
* V0.7: In Source+Kommentar aufger�umt         *
* V0.8: Vorbereitungen f�r CD-Programmierung   *
* V0.9: Alle CDAR504-Kommandos provisorisch    *
*       implementiert, READ-Kommandos nicht    *
*       komplett; sd1to5, sd2to5, sd1to6 umge- *
*       �ndert in sd1tox, sd2tox, sd2toend;    *
*       d3.w jetzt global; sd2tox verbessert   *
* V1.0: CDAR-Kommandos �berarbeitet            *
* V1.1: Flexible Sektorgr��en im HD-Teil       *
* V1.2: Anpassung an HYPERCACHE, Sprungtabellen*
*       statt Abfragekaskaden, cleanup         *
* V1.3: getdiag korrigiert                     *
************************************************

    debug   = 0

    dlow    = $ffff860d         ; DMA-Adre�z�hler, Lowbyte
    dmid    = $ffff860b         ; DMA-Adre�z�hler, Midbyte
    dhigh   = $ffff8609         ; DMA-Adre�z�hler, Highbyte
    gpip    = $fffffa01         ; GPIP-Register des MFP
    daccess = $ffff8604         ; DMA-Access-Register
    dmodus  = $ffff8606         ; DMA-Modus-Register
    vbl     = $43e              ; Floppy-VBL-Sperre
    hz_200  = $4ba              ; 200-Hz-Z�hler

start:
   bra.s    main                ; zum Programmanfang


buffer:   .dc.l 0               ; Zeiger auf DMA-Puffer
buf2:     .dc.l 0               ; Zeiger auf Reservepuffer
modus:    .dc.l 0               ; Modus
                                ; (0=SH205/SH204,
                                ;  1=CDAR504,
                                ;  alle anderen Werte reserviert)
comblock: .dc.w 0,0,0           ; Puffer f�r Kommandoblock

status:   .dc.l 0               ; Status (bei CD-ROM auch Puffer f�r
                                ; die letzten 4 Kommandobytes)
timeflag: .dc.l 0               ; Timeout-Flag
dmaend:   .dc.l 0               ; Ende der DMA-�bertragung

ext1:     .dc.l 0,0,0,0,0,0,0,0 ; 8 Erweiterungsworte
                                ; f�r die Zukunft

save_ssp:  .dc.l 0              ; Ein Platz f�r Tiere

***************************
* main: Hauptprogramm
* Aktiviert Supervisormodus, analysiert
* Modus-Langwort und verteilt danach;
* terminiert nach Umschalten in Usermodus
****************************
main:
    movem.l d0-a6,-(sp)         ; Register retten

    moveq.l #0,d0               ; Userstack wird Supervisorstack
    bsr     super               ; in den Supervisormodus
    lea     save_ssp(pc),a2     ; Stackpointer retten
    move.l  d0,(a2)
    lea     timeflag(pc),a2     ; Timeout-Flag l�schen
    clr.l   (a2)

    st      vbl                 ; Floppy-VBL sperren

    clr.w   d4                  ; Ende-Flag l�schen
    clr.w   d3                  ; 6-Byte-Kommandos

* d4.w = 0: nach Kommando nicht auf IRQ warten
* d4.w = 1: nach Kommando auf IRQ warten
* d3.w = 0: 6-Byte-Kommandos
* d3.w = 1: 10-Byte-Kommandos

    lea     comblock(pc),a0     ; Adresse von comblock
    moveq.l #0,d0               ; d0.l l�schen

    lea     sh205(pc),a6        ; Default: SH205-Modus
    move.l  modus(pc),d1        ; Modus holen
    subq.l  #1,d1               ; CD-ROM-Aufruf?
    bne.s   dispatch            ; nein, weiter
    lea     cdar504(pc),a6      ; Tabelle f�r CDAR-Kommandos

dispatch:
    move.b  (a0),d0             ; Kommando holen
    and     #31,d0              ; untere 5 Bit isolieren

    lsl.w   #1,d0               ; mal 2
    move.w  0(a6,d0.w),d0       ; relative Startadresse
    lea     start(pc),a6        ; Start des Programms
    jsr     0(a6,d0.w)          ; Routine anspringen

************************
* exitus: Interface beendet die Arbeit
************************
exitus:
    clr     vbl                 ; Floppy-VBL freigeben

    move.l  save_ssp(pc),d0     ; Stackpointer zur�ckholen
    bsr     super               ; in den Usermodus
    movem.l (sp)+,d0-a6         ; Register zur�ckholen

    rts                         ; raus hier

sh205:
    .dc.w stdcmd-start,stdcmd-start,stdcmd-start,reqsense-start
    .dc.w fmtdrive-start,stdcmd-start,stdcmd-start,stdcmd-start,read-start
    .dc.w stdcmd-start,write-start,stdcmd-start,stdcmd-start
    .dc.w stdcmd-start,stdcmd-start,translate-start
    .dc.w threshold-start,rdusage-start,stdcmd-start,wrbuf-start
    .dc.w rdbuf-start,modeselect-start,stdcmd-start,stdcmd-start
    .dc.w stdcmd-start,stdcmd-start,modesense-start,stdcmd-start
    .dc.w getdiag-start,senddiag-start,stdcmd-start,stdcmd-start

cdar504:
    .dc.w stdcmd-start,stdcmd-start,stdcmd-start,cdreqsense-start
    .dc.w stdcmd-start,stdcmd-start,stdcmd-start,stdcmd-start
    .dc.w cdread-start,stdcmd-start,stdcmd-start,stdcmd-start
    .dc.w stdcmd-start,stdcmd-start,stdcmd-start,stdcmd-start
    .dc.w stdcmd-start,cdaudprg-start,cdinquire-start,stdcmd-start
    .dc.w stdcmd-start,stdcmd-start,stdcmd-start,stdcmd-start
    .dc.w cdextread-start,cdrdtoc-start,cdmdsense-start
    .dc.w cdextseek-start,stdcmd-start,stdcmd-start
    .dc.w stdcmd-start,stdcmd-start

*************************
* stdcmd: Schickt Standard-Kommandoblock
* IN: a0.l Zeiger auf comblock
*************************
stdcmd:
    move.w  #$8a,d1             ; DMA-Modus
    bsr     sd1toend            ; Kommandoblock schicken

    move.w  #$8a,dmodus         ; ACSI-Bus selektieren
    bra     getstatus           ; Status holen

**************************
* reqsense
**************************
reqsense:
    moveq.l #3,d6               ; Z�hler f�r 4 Durchl�ufe
    moveq.l #1,d5               ; Blockanzahl

**************************
* rqentry: Einsprung f�r Reqsense-�hnliche
* Kommandos
* IN: d6.w Z�hler, d5.w Blockanzahl
**************************
rqentry:
    bsr     rdtoggle            ; DMA-Status/Puffer l�schen

    move.l  buf2(pc),d0         ; Startadresse des Statuspuffers
    bsr     setdma              ; in DMA-Z�hlerregister

rq2entry:
    move.w  d5,daccess          ; Blockanzahl in Sektorz�hler

rqlp:
    move.w  #$8a,d1             ; Moduswort $8A
    clr.w   d0                  ; d0 l�schen
    bsr     sd1tox              ; die ersten f�nf Kommandobytes
    bmi     rwerr               ; Timeout?

    move.l  #$0a,daccess        ; letztes Kommandobyte, DMA starten
    bsr     waitforcom          ; �bertragung abwarten
    bmi     rwerr               ; Timeout?

    move.w  #$8a,dmodus         ; Bus selektieren
    nop
    move.w  daccess,d0          ; CS low, ACK bleibt High, R/W auf R
    btst    #1,d0               ; Fehler?
    bne.s   rwerr2              ; jawohl

    move.l  hz_200,d2           ; Systemzeit holen
    addq.l  #2,d2               ; 2 Ticks warten
as_time_goes_by:
    cmp.l   hz_200,d2           ; zwei Ticks weiter?
    bne.s   as_time_goes_by     ; nein, warten

    dbf     d6,rqlp             ; next one

    move.w  #$8a,dmodus         ; Bus selektieren

rwerr2:
    bra     getst2              ; Status holen

**************************
* translate
* read/reset usage counter
* modesense
**************************
translate:
rdusage:
modesense:
    moveq.l #1,d6               ; Kommando zweimal schicken
    moveq.l #1,d5               ; Blockanzahl 1
    bra     rqentry             ; Reqsense-�hnliches Kommando

******************
* receive diagnostic
******************
getdiag:
    moveq.l #2,d5               ; 2 Bl�cke
    move.l  buf2(pc),d6         ; DMA-Start
    bsr     rdkern              ; Read-�hnliches Kommando

    move.w  #$8a,dmodus         ; Bus selektieren
    nop
    move.w  daccess,d0          ; CS low, ACK bleibt High, R/W auf R
    btst    #1,d0               ; Fehler?
    bne     rwerr2              ; jawohl

    move.l  hz_200,d2           ; Systemzeit holen
    addq.l  #2,d2               ; 2 Ticks warten
getdlp:
    cmp.l   hz_200,d2           ; zwei Ticks weiter?
    bne.s   getdlp              ; nein, warten

    move.b  (a0),d0             ; Targetnummer
    and.w   #$E0,d0             ; ausmaskieren
    or.b    #3,d0               ; REQUEST SENSE
    move.b  d0,(a0)+
    move.b  (a0),d0             ; Ger�tenummer
    and.b   #$E0,d0             ; ausmaskieren
    move.b  d0,(a0)+
    clr.l   (a0)                ; Rest l�schen
    move.b  #4,2(a0)            ; L�nge der �bertragung
    lea     comblock(pc),a0

    moveq.l #3,d6               ; Kommando viermal schicken
    moveq.l #2,d5               ; Blockanzahl 1
    bra     rq2entry            ; Reqsense-�hnliches Kommando

******************
* fmtdrive: Formatiert die ganze Platte
******************
fmtdrive:
    move.w  #$18a,d1            ; DMA-Modus
    bsr     sd1tox              ; Kommandobytes 1 bis 5 schicken
    bmi     rwerr               ; Timeout?

    move.b  5(a0),d0            ; letztes Kommandobyte
    swap    d0                  ; Worth�lften vertauschen
    move.w  #$18a,d0            ; Moduswort
wrlast:
    move.l  d0,daccess          ; und weg damit
wtfmt:
    btst    #5,gpip             ; auf Ende warten
    bne     wtfmt
    bra     getstatus           ; und Sense

*****************
* set error threshold
* mode select
*****************
threshold:
modeselect:
    moveq.l #1,d5               ; Blockanzahl 1
    bra.s   wrbufentry

****************
* write data buffer
****************
wrbuf:
    moveq.l #2,d5               ; Blockanzahl 2
wrbufentry:
    move.l  buf2(pc),d0         ; DMA-Startadresse
    bra.s   wrentry             ; Write-�hnliches Kommando

*****************
* write: Schreibt Sektoren auf Platte
*****************
write:
    clr.w   d0
    move.b  4(a0),d0            ; Sektoranzahl holen
    bsr     calcblk             ; Anzahl der DMA-Bl�cke berechnen
    move.l  buffer(pc),d0       ; DMA-Startadresse

******************
* wrentry: Einsprungpunkt f�r
* Write-�hnliche Kommandos
* IN: d0.l DMA-Start, d5 Sektoranzahl
*     d4.w Flag f�r Timeoutbehandlung (<>0=bis IRQ warten)
******************
wrentry:
    bsr     setdma              ; DMA-Start setzen

    move.w  #$88,dmodus         ; HDC-Zugriff
    moveq.l #0,d0               ; d0 l�schen
    move.b  comblock(pc),d0     ; Kommando und Target holen
    swap    d0                  ; Worth�lften vertauschen
    move.w  #$8a,d0             ; Modus einkopieren
    move.l  d0,daccess          ; und alles auf den Bus
    bsr     zeiteisen           ; auf Best�tigung warten
    bmi.s   rwerr               ; Fehler?

    move.w  #$18a,d1            ; DMA-Modus
    bsr     sd2tox              ; Bytes 2 bis x schicken
    bmi.s   rwerr               ; Fehler?

    bsr     wrtoggle            ; DMA-Status/Puffer l�schen
wrcnt:
    move.w  d5,daccess          ; Sektoranzahl an DMA-Chip
    nop
    move.w  #$18a,dmodus        ; HDC selektieren
    nop
    move.l  #$10a,daccess       ; �bertragung starten
    tst.w   d4                  ; mit Timeout beim letzten Byte?
    bne.s   wrlp                ; nein, dann weiter
    bsr     waitforcom          ; auf Kommandoende warten
    bra.s   wrst

wrlp:
    btst    #5,gpip             ; bis ultimo auf IRQ warten
    bne     wrlp

wrst:
    move.w  #$18a,dmodus        ; HDC selektieren
    nop
    bra     getstatus           ; mit Statussequenz fortfahren

*****************
* send diagnostic
*****************
senddiag:
    moveq.l #1,d5               ; Blockanzahl 1
    move.l  buf2(pc),d0         ; DMA-Start
    move.l  d0,a1
    cmp.b   #$60,(a1)           ; REINITIALIZE?
    bne     wrentry             ; nein, weiter
    st      d4                  ; jawohl, auf IRQ am Ende warten
    bra     wrentry

****************
* read data buffer
****************
rdbuf:
    moveq.l #2,d5               ; 2 Bl�cke
    move.l  buf2(pc),d6         ; DMA-Start
    bra.s   rdentry             ; Read-�hnliches Kommando

*****************
* read: Liest Sektoren von Festplatte
*****************
read:
    moveq.l #0,d0               ; d0.l l�schen
    move.b  4(a0),d0            ; Sektoranzahl
    bsr     calcblk             ; Anzahl der DMA-Bl�cke ausrechnen
    move.l  buffer(pc),d6       ; DMA-Startadresse

******************
* rdentry: Einsprungpunkt f�r
* Read-�hnliche Kommandos
* IN: d6.l DMA-Start, d5 Sektoranzahl
*******************
rdentry:
    bsr.s   rdkern
    move.w  #$8a,dmodus         ; HDC selektieren
    nop
rwerr:
    bra     getstatus

rdkern:
    move.w  #$88,dmodus         ; Busanforderung
    moveq.l #0,d0               ; d0 l�schen
    move.b  comblock(pc),d0     ; Kommando und Target holen
    swap    d0                  ; Worth�lften vertauschen
    move.w  #$8a,d0             ; Modus einkopieren
    move.l  d0,daccess          ; und alles auf den Bus
    bsr     zeiteisen           ; auf Best�tigung warten
    bmi.s   rwxit               ; Timeout?

    move.l  d6,d0               ; Pufferadresse
    bsr     setdma              ; als DMA-Startadresse
    move.w  #$8a,d1             ; DMA-Modus
    bsr.s   sd2tox              ; Kommandobytes 2 bis x �bergeben
    bmi.s   rwxit               ; Fehler?

    bsr     rdtoggle
rdcnt:
    move.w  d5,daccess          ; Sektoranzahl an DMA-Sektorz�hler
    nop
    move.w  #$8a,dmodus         ; HDC wieder selektieren
    nop
    move.l  #$a,daccess         ; �bertragung starten
    bsr.s   waitforcom          ; auf Kommandoende warten

rwxit:
    rts

**********************
* sdbyte: Byte in d0 an HDC schicken
* IN:  d0.l wie folgt:
*      -------------------------
*      | X.b | X.b | 0.b | CB.b|
*      -------------------------
*      CB=Commandbyte
*      d1.w DMA-Modus ($8A/$18A)
***********************
sdbyte:
    swap    d0                  ; Worth�lften vertauschen
    move.w  d1,d0               ; DMA-Modus einschieben
    move.l  d0,daccess          ; Byte auf Bus und Modus an DMA-Chip
    bra.s   zeiteisen           ; und warten

**********************
* sd2tox: Schickt die Kommandobytes 2 bis x
* auf den ACSI-Bus (per sdbyte)
* IN: a0.l Zeiger auf comblock
*     d1.w DMA-Modus
*     d3.w = 0: 6-Byte-Kommando (x=5)
*          = 1: 10-Byte-Kommando (x=9)
* OUT: N-Flag gesetzt, wenn Timeout
**********************
sd2tox:
    movem.l d0/d2,-(sp)         ; d0 und d2 retten
    moveq.l #0,d0               ; d0.l l�schen
    clr.w   d2                  ; d2.w initialisieren
    lea     ende(pc),a1
    move.w  #4,(a1)
    tst.w   d3                  ; 10-Byte-Kommando?
    beq.s   sdloop
    move.w  #8,(a1)

sdloop:
    addq.w  #1,d2               ; d2++
    move.b  0(a0,d2),d0         ; Kommandobyte holen
    bsr     sdbyte              ; und auf Bus legen
    bmi.s   sd2err              ; Timeout?

    cmp.w   (a1),d2             ; schon 4 bzw. 8 Bytes �bertragen?
    bne     sdloop              ; nein, weitermachen

sd2err:
    movem.l (sp)+,d0/d2         ; d0 und d2 zur�ckholen
    rts                         ; und raus

ende:
    .dc.w 0                     ; Anzahl zu �bertragender Bytes+1

**********************
* sd1tox: Schickt Kommandobytes 1 bis x auf ACSI-Bus
* (per sdbyte)
* IN: a0.l Zeiger auf comblock
*     d1.w DMA-Modus
*     d3 = 0: 6-Byte-Kommando
*     d3 = 1: 10-Byte-Kommando
* OUT: N-Flag gesetzt, wenn Timeout
***********************
sd1tox:
    clr.w   d0                  ; d0.w l�schen
    move.w  #$88,dmodus         ; ACSI-Bus wachr�tteln
    move.b  (a0),d0             ; erstes Kommandobyte holen
    bsr     sdbyte              ; und auf ACSI-Bus legen
    bmi.s   sd1err              ; Timeout?
    bsr     sd2tox              ; Kommandobytes 2 bis 5 schicken
sd1err:
    rts

***********************
* sd1toend: Schickt Kommandobytes 1 bis 6 bzw. 10 auf ACSI-Bus
* (per sdbyte)
* IN: a0.l Zeiger auf comblock
*     d1.w DMA-Modus
*     d3 = 0: 6-Byte-Kommando
*     d3 = 1: 10-Byte-Kommando
* OUT: N-Flag f�r Timeout
***********************
sd1toend:
    bsr     sd1tox              ; Kommandobytes 1 bis x schicken
    bmi.s   sderr               ; Timeout?
    move.b  5(a0),d0            ; letztes Kommandobyte holen
    tst.w   d3                  ; 10-Byte-Kommando?
    beq.s   sdlast              ; nein, weiter
    move.b  9(a0),d0            ; letztes Kommandobyte holen
sdlast:
    swap    d0                  ; Worth�lften vertauschen
    move.w  d1,d0               ; DMA-Modus
    move.l  d0,daccess          ; auf Bus damit
    bsr.s   waitforcom          ; auf Kommandoende warten
sderr:
    rts

**********************
* waitforcom: Wartet nach Kommandoblock auf Kommandoende
* USES: d0,d1,a2
**********************
waitforcom:
    movem.l d0/d1/a2,-(sp)
    moveq.l #0,d0               ; Default-Fehler
    moveq.l #100,d1             ; Timeout = 100...
    asl.w   #3,d1               ; ...*8 = 800 (k�rzer als move.l #800,d1)
    bra.s   gettimer            ; und warten

*********************
* zeiteisen: Wartet auf IRQ des HDC
* USES: d0,d1,a2
*********************
zeiteisen:
    movem.l d0/d1/a2,-(sp)

    moveq.l #0,d0               ; Fehler-Default
    moveq   #20,d1              ; 20 Ticks warten
gettimer:
    add.l   hz_200,d1           ; d1 plus 200Hz-Z�hler
zeita:
    btst    #5,gpip             ; auf HDC-IRQ testen
    beq.s   fix_und_fertig      ; ist angekommen, fertig
    cmp.l   hz_200,d1           ; Timer-Zielwert erreicht?
    bne     zeita               ; nein, weiter

    lea     timeflag(pc),a2
    moveq   #-1,d0              ; Fehler �bermitteln
    move.l  d0,(a2)             ; Timeout-Flag setzen
fix_und_fertig:
    tst.l   d0                  ; N-Flag aktualisieren
    movem.l (sp)+,d0/d1/a2
    rts                         ; und raus

********************
* setdma: DMA-Startadresse setzen
* IN: D0.L Pufferadresse
********************
setdma:
    move.b  d0,dlow             ; Lowbyte
    asr.l   #8,d0
    move.b  d0,dmid             ; Midbyte
    asr.l   #8,d0
    move.b  d0,dhigh            ; Highbyte
    rts

********************
* getdma: DMA-Adresse lesen und in dmaend
* ablegen
********************
getdma:
    clr.w   d0
    move.b  dhigh,d0            ; Highbyte lesen
    asl.l   #8,d0               ; mal 256
    move.b  dmid,d0             ; Midbyte
    asl.l   #8,d0               ; mal 256
    move.b  dlow,d0             ; Lowbyte
    lea     dmaend(pc),a0       ; Adresse von dmaend
    move.l  d0,(a0)             ; DMA-Adresse ablegen
    rts                         ; und raus

*********************
* rdtoggle: DMA-Puffer und DMA-Status l�schen
* Sektorz�hler selektieren, Datenrichtung auf lesen
*********************
rdtoggle:
    move.w  #$98,dmodus
    nop
tglentry:
    move.w  #$198,dmodus
    nop
    move.w  #$98,dmodus
    rts

********************
* wrtoggle, wie oben, nur f�r Datenrichtung Schreiben
********************
wrtoggle:
    bsr     tglentry
    move.w  #$198,dmodus
    rts

**************************
* getstatus: Liest Statusbyte
* deselektiert HDC
* ACSI-Bus mu� bereits selektiert sein ($8a oder $18a nach dmodus)
* OUT: Status in status
* USES: d0,a2
**************************
getstatus:
    move.w  daccess,d0          ; Status holen

getst2:
    swap    d0                  ; Worth�lften tauschen
    move.w  dmodus,d0           ; DMA-Status holen
    lea     status(pc),a2
    and.l   #$ff0007,d0         ; ausmaskieren
    move.l  d0,(a2)             ; in status ablegen

    move.w  #$80,dmodus         ; FDC selektieren
    bra     getdma              ; DMA-Adresse holen

********************
* super: Zwischen Super- und Usermode umschalten
* IN: D0 neuer Stack
* OUT: D0 alter Stack
* USES: D0, D1, A0, A1 (GEMDOS)
********************
super:
    move.l  d0,-(sp)            ; neue Stackadresse
    move.w  #32,-(sp)           ; SUPER
    trap    #1                  ; GEMDOS
    addq.l  #6,sp               ; Stack s�ubern
    rts                         ; raus

************************** Ab hier folgen die Routinen f�r die
************************** CD-ROM-Programmierung

**********************
* cdreqsense: REQUEST SENSE f�r CD
* IN: A0.L -> Kommandoblock
**********************
cdreqsense:
    moveq.l #0,d6               ; Z�hler f�r 1 Durchlauf
    moveq.l #1,d5               ; Blockanzahl
    bra     rqentry

**********************
* cdread: READ f�r CD
* IN: A0.L -> Kommandoblock
**********************
cdread:
    moveq.l #0,d0
    move.b  4(a0),d0            ; Blockanzahl holen
cdr1:
    bsr.s   calcblk             ; Anzahl der DMA-Blocks ausrechnen
    move.l  buffer(pc),d6       ; -> Puffer
    bra     rdentry

**********************
* cdextread: EXTENDED READ f�r CD
**********************
cdextread:
    moveq.l #0,d0
    move.b  7(a0),d0            ; MSB der Blockanzahl
    lsl.w   #8,d0               ; mal 256
    move.b  8(a0),d0            ; LSB der Blockanzahl
    moveq.l #1,d3               ; 10-Byte-Kommando
    bra     cdr1                ; weiter wie bei READ

**********************
* cdextseek: EXTENDED SEEK f�r CD
* cdaudprg: AUDIO PROGRAM f�r CD
**********************
cdextseek:
cdaudprg:
    moveq.l #1,d3               ; 10-Byte-Kommando
    bra     stdcmd

**********************
* cdrdtoc: READ TOC f�r CD
**********************
cdrdtoc:
    moveq.l #1,d5               ; 1 Block �bertragen
    move.l  buffer(pc),d6       ; ->Puffer
    bra     rdentry             ; und lesen

**********************
* cdmdsense: MODE SENSE f�r CD
* cdinquire: INQUIRE
**********************
cdmdsense:
cdinquire:
    moveq.l #1,d5               ; 1 Block �bertragen
    move.l  buf2(pc),d6         ; ->Reservepuffer
    bra     rdentry             ; und los geht's

**********************
* calcblk: Errechnet die Anzahl der
* zu �bertragenden DMA-Blocks (512 Bytes)
* IN:  d0.w Blockanzahl (aus Kommando)
*      buf2(pc) -> logische Blockgr��e in Bytes (Langwort)
* OUT: d5.w Anzahl der DMA-Blocks
* USES: d6.l
**********************
calcblk:
    move.l  buf2(pc),a1         ; -> Reservepuffer
    move.l  (a1),d5             ; Blockgr��e holen
    mulu.w  d0,d5               ; mal Blockanzahl

    divu    #512,d5             ; in DMA-Blocks umrechnen
    move.l  d5,d6               ; Ergebnis nach d6
    swap    d6                  ; Worth�lften tauschen
    tst.w   d6                  ; Division mit Rest?
    beq.s   calc1               ; nein
    addq.w  #1,d5               ; ein Block mehr
calc1:
    rts

