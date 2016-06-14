declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="1" data="06/07/2012" inXML="0" UID="DCD39FC1-82A9-9913-0568-C61F4463D8A0" categoriePret="4" searchText=""/>')
exec wIaComenziDeFacturat @sesiune='6803E3C339407',@parXML=@p2