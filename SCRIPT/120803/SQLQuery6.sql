declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="2" data="08/03/2012" inXML="0" UID="63A908EF-FDB2-CCDB-3A74-EAD5A771623E" categoriePret="4" tert="2810824124246" searchText=""/>')
exec wIaComenziDeFacturat @sesiune='199149E4AB8E5',@parXML=@p2