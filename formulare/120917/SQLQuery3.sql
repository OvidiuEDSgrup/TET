declare @p2 xml
set @p2=convert(xml,N'<row tipdocument="AP" serie="TET" numarinferior="9430001" numarsuperior="9439999" ultimulnumar="9430178" denumire="Avize produse" denserieinnumar="Nu" serieinnumar="0" idPlaja="1" tip="PJ" tipMacheta="C" codMeniu="PJ" TipDetaliere="PJ" subtip="LL"/>')
exec yso_wOPListareLipsaPlajeDocumente @sesiune='DDC9AE51E2C81',@parXML=@p2