--/*
declare @sesiune varchar(50), @parXML xml, @numeTabelTemp varchar(1000), @maxrand int
set @sesiune='3A98BF98F6AA3' 
set @parXML='<row subunitate="1" tip="RE" cont="5311.1" dencont="Casa in lei Sediu" data="03/17/2014" valuta="" curs="0.0000" marca="" denmarca="" decont="" tert="" dentert="" efect="" totalplati="2363.00" totalplativaluta="0.00" totalincasari="2333.54" totalincasarivaluta="0.00" totalsold="3417.50" soldinitial="3446.96" soldinitialvaluta="0.00" rulajdebit="2333.54" rulajcredit="2363.00" soldfinal="3417.50" soldfinalvaluta="0.00" numarpozitii="10" tipdocument="PI" nrdocument="5311.1" nrform="DISPPLDOC"><row subunitate="1" tip="RE" cont="5311.1" dencont="Casa in lei Sediu" data="03/17/2014" subtip="PF" numar="88" plataincasare="PF" tert="RO15807344" dentert="KAMENA SRL" factura="92" contcorespondent="401.3" dencontcorespondent="Furnizori servicii Ron" suma="288.00" valuta="" denvaluta="" curs="0.0000" sumavaluta="0.00" cotatva="24" sumatva="0.00" explicatii="KAMENA SRL" lm="1" comanda="" indbug="" denlm="TRUST" dencomanda="" numarpozitie="300816" contdifcurs="" dencontdifcurs="" sumadifcurs="0.00" jurnal="" denmarca="" datascadentei="01/01/1901" denbancatert=" - " utilizator="ALUCAI" data_operarii="21/03/2014" tipTVA="" denTiptva="" culoare="#000000" idPozPlin="57730"/></row>' 
set @numeTabelTemp='##raspASIS' 
set @maxrand=0 
--*/
drop table ##raspASIS
exec formDispozitiePI @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
select * from ##raspASIS