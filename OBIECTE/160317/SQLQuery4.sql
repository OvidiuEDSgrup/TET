declare @p2 xml
set @p2=convert(xml,N'<row tip="AP" data="02/16/2016" numar="4143567" idPozDocSursa="562822" tipS="AP" dataS="02/16/2016" numarS="4143566" denTipS="Factura" cod="17PK-2606" denumire="HE-Racord drept 26x1&quot;&quot; T, press" codintrare="AILOC16085" cantitate="-4.00" pret="25.00" valoare="-100.00" culoare="#000000" idPozDocStorno="562785"/>')
exec yso_wStergLegaturiStornare @sesiune='',@parXML=@p2
--select @p2