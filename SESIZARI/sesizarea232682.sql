/*
Acesta este apelul procedurii de refacere care da eroarea 
Msg 50000, Level 16, State 1, Procedure wOPRefacACTE, Line 223
validareStocNegativ:Violare integritate date. Documentul ar genera stoc negativ. Gestiune: 211.1, cod: 4300902006021!(wOPRefacACTE)
Procedura a fost rulata pt a descarca bonul ramas agatat in bt,la cererea clientului care tocmai facea un inventar si avea nevoie 
sa fie stocurile la zi.
Eroarea insa apare de la alta bon,descarcat deja, dar de pe aceeasi gestiune si aceeasi data cu cel ramas in bt: 
bonul 1 de la casa 1 din 2012-07-13 de pe gestiune 211.1.
*/

declare @p2 xml
set @p2=convert(xml,N'<parametri gestiune="213.1" stergere="1" generare="1" o_gestiune="211.1" o_stergere="1" o_generare="1" update="1" 
datajos="10/01/2012" datasus="10/10/2012" tipMacheta="O" codMeniu="RF" debug="1"/>')
exec wOPRefacACTE @sesiune='',@parXML=@p2
go
--aici am cautat pozitia bonului care da acea eroare la incercarea de stergere din pozdoc
select * from pozdoc p  where p.Tip='AC' and p.Cod='EFC-T12' and p.Data>='2012-10-01'

--aici am cautat sa vad toate iesirile cu minus(care de fapt sunt intrari) pe acel cod intrare in acea gestiune,
--si am gasit transferul aferent acelei pozitii de AC.
select * from pozdoc p where p.Cod='4300902006021       ' and 'IMPL1AA' in (p.Cod_intrare,p.Grupa) 
and '211.1' in (p.Gestiune,p.Gestiune_primitoare)

--aici am cautat sa vad daca totusi stergerea te-ului inaintea ac-ului ar putea rezolva situatia si am gasit ca nu, fiindca din acel stoc 
--creat de te-ul automat in gest 211 s-au facut ulterior alte iesiri prin te-urile 10008 din 2012-07-20 si  10002 din 2012-08-01 
select * from pozdoc p where p.Cod='4300902006021       ' and 'IMPL1AAA' in (p.Cod_intrare,p.Grupa) 
and '211' in (p.Gestiune,p.Gestiune_primitoare)

--select * from pozdoc p where p.ge