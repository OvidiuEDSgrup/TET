declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="9" data="04/11/2013" inXML="0" UID="FE155008-656E-B89B-5D69-F8644B5E79CE" categoriePret="1" cod="3251162282504" cantitate="1"/>')
exec wUnCodNomenclator @sesiune='EE5F1F4D58EB7',@parXML=@p2