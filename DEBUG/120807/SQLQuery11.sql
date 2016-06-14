declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="2" data="08/07/2012" inXML="0" UID="035FE755-6C25-12CD-48EF-00E5372D1F07" categoriePret="4" tert="2810824124246" searchText=""/>')
exec wIaComenziDeFacturat @sesiune='74DF8CC622E52',@parXML=@p2