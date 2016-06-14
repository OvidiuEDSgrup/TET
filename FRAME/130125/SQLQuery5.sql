declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="9" data="01/25/2013" inXML="0" UID="2CD2A008-696C-E42A-0719-71F44E9548F7" categoriePret="1" cod="1-1604A" cantitate="1" durataInput="601" clipboardIsSimilar="1"/>')
exec wUnCodNomenclator @sesiune='46728EBB104F0',@parXML=@p2