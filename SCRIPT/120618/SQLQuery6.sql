declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="1" data="06/18/2012" inXML="0" UID="43780721-13FC-EC6E-C406-FF0A9A3DCCAC" categoriePret="4" tert="1550813120664" searchText=""/>')
exec wIaComenziDeFacturat @sesiune='0A2E854E98163',@parXML=@p2