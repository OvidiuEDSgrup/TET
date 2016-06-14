declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="8" data="10/29/2013" inXML="0" UID="1C6273D6-BF13-7635-0BC9-038456FC90F7" categoriePret="1" tert="1770314264407" searchText=""/>')
exec wIaComenziDeFacturat @sesiune='',@parXML=@p2