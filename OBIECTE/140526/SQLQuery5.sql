declare @p2 xml
set @p2=convert(xml,N'<row tip="BY" numar="2" data="04/30/2013" dengestiune="NT BON FISCAL PIATRA NEAMT" gestiune="210.NT" dentert="BERBECE IORDACHE" tert="1340322040019" factura="9411135" data_facturii="04/30/2013" valoare="3976.48" tva="962.06" valtotala="4938.54" numarpozitii="9" vanzator="MAGAZIN_NT" casam="1" ora="13:16" idantetbon="2237" culoare="#2A8E82" _nemodificabil="1" nrdoc="9411135" tipdoc="AP" datadoc="2013-04-30T00:00:00" _refresh="0"/>')
exec wIaPozBonuri @sesiune='868ED247159D2',@parXML=@p2

--exec RefacereStocuri null,null,null,null,null,null
--select * from stocuri s where s.Cod='12300'