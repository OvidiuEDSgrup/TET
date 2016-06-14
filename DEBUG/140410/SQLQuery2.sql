declare @p2 xml
set @p2=convert(xml,N'<row f_numar="SV980580" tip="BK" datajos="2014/01/01" datasus="2014/04/30"/>')
exec wIaCon @sesiune='3BB902BD44673',@parXML=@p2
--select dbo.f_areLMFiltru('asis')