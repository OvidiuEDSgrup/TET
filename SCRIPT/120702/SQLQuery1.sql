declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="1" data="07/02/2012" inXML="0" UID="4FED1559-F457-A480-D1B1-495AC9AF8D67" categoriePret="4" tert="1550813120664" searchText=""/>')
exec wIaComenziDeFacturat @sesiune='999E0451715A2',@parXML=@p2