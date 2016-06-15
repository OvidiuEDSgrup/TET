CREATE  procedure wCalculezIndicatori_p  @sesiune varchar(50), @parXML XML
as
if exists (select 1 from sysobjects where type='P' and name='wCalculezIndicatori_pSP')
begin
		exec wCalculezIndicatori_pSP @sesiune, @parXML
		return
end

select convert(char(10),dbo.BOY(getdate()),101) dataJos, convert(char(10),dbo.EOY(getdate()),101) dataSus
for xml raw, root('Date')

