declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="1" data="07/13/2012" inXML="0" UID="B5775D28-7160-ED8D-9BDD-7F456D679456" categoriePret="4" cod="BHRS5019" cantitate="1"/>')
exec wUnCodNomenclator @sesiune='4D41C5E3DAD12',@parXML=@p2