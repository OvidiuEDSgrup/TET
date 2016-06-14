--delete docfiscalerezervate go
SELECT 'script',* from docfiscalerezervate
go
declare @p2 xml
set @p2=convert(xml,N'<row subunitate="1" tip="TE" numar="21" numarf="21" data="11/23/2012" dataf="11/23/2012" dengestiune="DEPOZIT CJ" gestiune="212" dentert="" tert="378.0" factura="9820633" contract="" denlm="MKT-PCT LUCRU CJ" lm="1MKT20" dencomanda="MOLDOVAN AUREL" comanda="1710605126190" indbug="" gestprim="700" dengestprim="AVIZE INSTALATORI PCT LUCRU" punctlivrare="" denpunctlivrare="" valuta="" denvaluta="" curs="0.0000" valoare="-115.75" tva11="0.00" tva22="0.00" tvatotala="0.00" valtotala="-115.75" valoarevaluta="0.00" totalvaloare="-115.75" valvalutacutva="0.00" categpret="0" facturanesosita="0" aviznefacturat="0" cotatva="0.00" discount="0.00" sumadiscount="0.00" tiptva="0" denTiptva="" explicatii="" numardvi="" proforma="0" tipmiscare="E" contfactura="4428" dencontfactura="4428-TVA neexigibila" contcorespondent="357" dencontcorespondent="Marfuri in custod.sau consig." contvenituri="378.0" dencontvenituri="Diferente de pret la marfuri" datafacturii="11/23/2012" datascadentei="11/23/2012" zilescadenta="0" jurnal="" numarpozitii="3" valamcatprimitor="0" numedelegat="" seriabuletin="" numarbuletin="" eliberat="" mijloctp="" nrmijloctp="" dataexpedierii="11/23/2012" oraexpedierii="000000" observatii="" punctlivareexped="" contractcor="" stare="8" denStare="Operat" culoare="#FF0000" _nemodificabil="0" tipdocument="TE" nrdocument="21" tipMacheta="D" codMeniu="DO" TipDetaliere="TE" subtip="SS"/>')
exec wOPStornareDocument_p @sesiune='AA29AB73CC322',@parXML=@p2
go
		select top 1 numar 
		from docfiscalerezervate 
		where idPlaja=26 and getdate()>expirala
go
SELECT * from docfiscalerezervate