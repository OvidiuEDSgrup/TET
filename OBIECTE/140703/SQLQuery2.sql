declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="20" data="07/03/2014" inXML="0" UID="9F626BD1-9060-7D93-3075-FC6E3F0DBAFB" categoriePret="1" tert="1820710035335" searchText=""/>')
exec wIaComenziDeFacturat @sesiune='18683BC3D60B3',@parXML=@p2