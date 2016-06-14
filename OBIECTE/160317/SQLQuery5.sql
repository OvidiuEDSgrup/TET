declare @p2 xml
set @p2=convert(xml,N'<row tip="AP" data="02/16/2016" numar="4143567" idPozDocSursa="562816" tipS="AP" dataS="02/17/2016" numarS="4143571" denTipS="Factura" culoare="#000000" idPozDocStorno="563004"><row tip="AP" data="02/16/2016" numar="4143567" idPozDocSursa="562817" cod="100-ISO4-16-BL" denumire="HE-Tub 16x2 Standard cu izolatie bleu 6 mm (colaci 100m)" codintrare="AILOC21050" cantitate="-200.00" pret="8.68" valoare="-1736.00" culoare="#000000" idPozDocStorno="563003"/><row tip="AP" data="02/16/2016" numar="4143567" idPozDocSursa="562816" cod="100-ISO4-16-RO" denumire="HE-Tub 16x2 Standard cu izolatie rosie 6 mm (colaci 100m)" codintrare="AILOC21045" cantitate="-200.00" pret="8.68" valoare="-1736.00" culoare="#000000" idPozDocStorno="563004"/><row tip="AP" data="02/16/2016" numar="4143567" idPozDocSursa="562819" cod="50-ISO4-20-BL" denumire="HE-Tub 20x2 Standard cu izolatie bleu 6 mm (colaci 50m)" codintrare="AILOC21028" cantitate="-200.00" pret="11.66" valoare="-2332.00" culoare="#000000" idPozDocStorno="563006"/><row tip="AP" data="02/16/2016" numar="4143567" idPozDocSursa="562818" cod="50-ISO4-20-RO" denumire="HE-Tub 20x2 Standard cu izolatie rosie 6 mm (colaci 50m)" codintrare="AILOC21023" cantitate="-200.00" pret="11.66" valoare="-2332.00" culoare="#000000" idPozDocStorno="563007"/></row>')
exec yso_wStergLegaturiStornare @sesiune='',@parXML=@p2
--select @p2

--insert StariDocumente (tipDocument,stare,denumire,culoare,modificabil,detalii,inCurs,initializare)
--select tipDocument=t.tip,stare,denumire,culoare,modificabil,detalii,inCurs,initializare
--from StariDocumente s join dbo.wfIaTipuriDocumente(NULL) t on t.meniu='DO' and t.tip<>s.tipDocument

