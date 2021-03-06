var anzahl,zahl,i : integer;
    muenze : array [1..8] of integer;
procedure zerlege (zahl : integer;maximum : integer);
  var i,m : integer;
  begin
    for i:=2 to maximum do
      if zahl-muenze[i]>=0 then
      BEGIN
        anzahl:=anzahl+1;
        zerlege(zahl-muenze[i],i);
      END;
  end;
begin
  muenze[1]:=1;muenze[2]:=2;muenze[3]:=5;muenze[4]:=10;muenze[5]:=50;
  muenze[6]:=100;muenze[7]:=200;muenze[8]:=500;
  write('-> Summe in Pf ');readln(zahl);anzahl:=0; 
  zerlege(zahl,8);
  writeln('<- Es gibt ',anzahl+1,' M�glichkeiten ');
end.

{ Problemstellung :
  
  Wenn Sie gen�gend viele 1pf,2pf,5pf,10pf,50pf,1dm,5dm-St�cke zu Verf�gung
  haben, so k�nnen Sie einen bestimmten Betrag mit mehreren M�glichkeiten
  bezahlen. Z.B. 10 Pf : Es gibt 11 M�glichkeiten : 1*10;2*5;1*5+2*2+1*1;
  1*5+1*2+3*2;1*5+5*1;5*2;4*2+2*1;3*2+4*1;2*2+8*1;1*2+8*1;10*1 (sonst geht
  nix mehr). Die Anzahl M�glichkeiten w�chst �berproportional zum Geldwert.
  Maximal k�nnen 499 Pf berechnet werden (!).
  
  Beispiel :
  
  200 Pf (=2 DM-St�ck !) ergibt 29605 M�lichkeiten.
  
  Hinweise :
  
   Rekursion, Variablenz�hlung. 
}
  