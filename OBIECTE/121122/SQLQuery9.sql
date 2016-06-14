declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="9" data="11/22/2012" inXML="0" UID="D7CC5C44-8379-5682-6F5E-26F74E04A8BD" categoriePret="1" tert="1710605126190" searchText=""/>')
exec wIaComenziDeFacturat @sesiune='D50C1C0E89A87',@parXML=@p2