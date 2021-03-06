Was es derzeit zu Manitor zu sagen gibt:
=======================================

Manitor protokolliert folgende Systemaufrufe, sowie deren Returncodes
in einem Logfile:

- AES
- VDI
- Gemdos
- Xbios
- Bios
- 2 Bomben Exception (Bus Error)
- 3 Bomben Exception (Address Error)
- 4 Bomben Exception (Illegal Opcode)
- 5 Bomben Exception (Division by Zero)

Au�erdem k�nnen Messages, die per appl_write verschickt werden, oder
per evnt_mesag/evnt_multi empfangen wurden im Klartext ausgegeben
werden.

Per Default wird als Logfile "C:\MANITOR.LOG" genommen. Ist die
Environmentvariable $MANITORLOG gesetzt, so wird die dort angegebene
Datei als Default-Logfile verwendet.

Da so ein Logfile sehr schnell anw�chst, wenn man alle Systemaufrufe
protokolliert, gibt es diverse Filter, die man aktivieren kann. Die
Konfiguration von Manitor erfolgt derzeit �ber GEMScript, also am
besten mit Scripter.

Wird Manitor manuell gestartet, so tut er zun�chst gar nichts. Er
wartet auf Konfiguration und Aktivierung �ber GEMScript. Daf�r ist
Scripter von Holger Weets zu empfehlen.

Im Ordner SCRIPTS gibt es folgende Beispiel-Scripte:

  START.SIC:    Logging starten
  STOP.SIC:     Logging stoppen
  TERM.SIC:     Manitor beenden

  ALL.SIC:      Alles protokollieren

  AES.SIC:      Nur AES+Messages
  VDI.SIC:      Nur VDI
  GEMDOS.SIC:   Nur Gemdos
  XBIOS.SIC:    Nur Xbios
  BIOS.SIC:     Nur Bios

  MESSAGES.SIC: Alle Messages protokollieren
  OLGA.SIC:     OLGA-Messages protokollieren
  AVPROTO.SIC:  AV-Protokoll-Messages protokollieren
  GSCRIPT.SIC:  GEMScript-Messages protokollieren

  ALLJINN.SIC:  Alles von jinnee protokollieren

Manitors GEMScript-Kommandos sind in MAN_GSCR.TXT erkl�rt.

Manitor kann auch (eingeschr�nkt) interaktiv benutzt werden, wenn man
Dock von Holger Weets verwendet. Manitor installiert in Dock einige
Buttons.

Im Logfile wird am Anfang der Zeile der 200Hz-Counter ausgegeben
(Z�hlung beginnt ab Protokoll-Start). Danach folgt in eckigen Klammern
immer der Proze�name und bei AES-Funktionen au�erdem noch AES-ID und
Applikationsname. Zu beachten ist, da� der Name aus einer internen
Liste gesucht wird, die nicht immer aktuell sein mu�.

Manitor sollte man immer nur �ber AP_TERM oder das Kommando
terminate() beenden (also nicht brutal rausschmei�en). Nicht wundern,
wenn er sich dabei manchmal nicht sofort beendet - in diesem Falle mu�
er noch im Speicher verbleiben, weil eine Funktion, deren Returncode
zu protokollieren war (und somit die Returnadresse verbogen wurde),
noch nicht zur�ckgekehrt ist. Ein wartender Manitor ist bereits aus
allen Vektoren ausgeklinkt, mu� aber eben im Speicher bleiben, da eine
Funktion noch "in ihn" zur�ckspingt. Ein so wartender Manitor kann
jederzeit neu aktiviert werden, st�rt also in keiner Weise.

"Kickt" man Manitor brutal aus dem Speicher, zieht er sich zwar auch
�ber etv_term aus seinen Vektoren zur�ck, aber dennoch kommt es danach
aus o.g. Grund oft zu Abst�rzen, da Manitor nicht auf die R�ckkehr
aller Funktionen warten kann.


Was noch fehlt:
==============

- Bei vielen VDI-Funktionen fehlt noch die Ausgabe der Ein- und
  Ausgabe-Parameter.

- Beim Ausklinken aus den Vektoren wird die XBRA-Kette nicht verfolgt.
