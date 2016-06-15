--***
CREATE procedure wACCoduriVamale @sesiune varchar(50), @parXML XML
as
set transaction isolation level read uncommitted
if exists (select * from sysobjects where name='wACCoduriVamaleSP' and type='P')      
begin
	exec wACCoduriVamaleSP @sesiune, @parXML
	return 0
end
declare @searchText varchar(80)

set @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
set @searchText=REPLACE(@searchText, ' ', '%')

select top 100 rtrim(Cod) as cod, rtrim(Denumire) as denumire
from codvama
where (cod like replace(@searchText,' ','%')+'%' or denumire like '%'+@searchText+'%')
order by rtrim(denumire)
for xml raw
