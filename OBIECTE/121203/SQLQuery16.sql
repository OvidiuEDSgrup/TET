declare @p2 xml
set @p2=convert(xml,N'<row tipdocument="AP" serie="TET" numarinferior="9410001" numarsuperior="9419999" ultimulnumar="9410745" denumire="Avize" denserieinnumar="Nu" serieinnumar="0" idPlaja="6" datajos="11/01/2012" datasus="11/23/2012" scotformulare="0" tip="PJ" tipMacheta="C" codMeniu="PJ" TipDetaliere="PJ" subtip="LL"/>')
exec yso_wOPListareLipsaPlajeDocumente @sesiune='4FE6B8EC04F75',@parXML=@p2