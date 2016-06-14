declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="1" data="08/01/2012" inXML="0" UID="E84B9F64-E0C4-D053-2B00-E16C8DFD0F0C" categoriePret="4" tert="2810824124246" searchText=""/>')
exec wIaComenziDeFacturat @sesiune='97A00A5451E54',@parXML=@p2