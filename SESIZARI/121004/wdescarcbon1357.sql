/*
Apelul de mai jos se face pt un bon ramas agatat in bt, si sa urmatoarea eroare:
Msg 50000, Level 11, State 1, Procedure wDescarcBon, Line 713
Acest produs(PKKP500/1000) nu a fost vandut din gestiunile (;211.1;)! Nu se poate identifica pozitia pentru incarcarea stocului.. (idAntetBon=1357) (wDescarcBon)
*/
declare @p xml='<row idAntetBon="1357"/>'
exec wDescarcbon '',@p

--Problema din cate am vazut vine de la faptul ca in stocuri nu exista nici o pozitie cu acest cod in gest 211.1:
select * from stocuri s where Cod like 'PKKP500/1000'

--Dar daca verificam in bonuri putem vedea bonul de vanzare pt acest retur exista:
select * from bp where bp.Cod_produs like 'PKKP500/1000' and bp.Casa_de_marcat=1

--Si daca verificam in pozdoc vedem ca el a fost si descarcat, ceea ce implica faptul ca miscare prin stocuri s-a facut:
select * from pozdoc p where p.Data='2012-07-09' and p.Numar like 1*10000+2 and p.Cod like 'PKKP500/1000'

--Deci se pare ca nu se poate deloc verifica cu stocurile daca un produs a fost vandut din gestiunea in care se incearca sa se faca retur