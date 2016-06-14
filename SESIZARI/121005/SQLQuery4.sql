declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="1" data="10/05/2012" inXML="0" UID="96DC6297-3DFB-EA11-13FC-2FF06BBF41FF" categoriePret="1" tert="1760421312965" searchText=""/>')
exec wIaComenziDeFacturat @sesiune='41464695C9314',@parXML=@p2