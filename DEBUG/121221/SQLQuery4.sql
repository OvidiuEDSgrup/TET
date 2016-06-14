declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="1" data="12/20/2012" inXML="0" UID="56E1C674-B8FC-0610-0653-B7D0F934EF12" categoriePret="1" cod="510842" cantitate="1"/>')
exec wUnCodNomenclator @sesiune='6856ED4011C90',@parXML=@p2