--***
create PROCEDURE  [dbo].[wUAACUtilizatori] @sesiune varchar(50), @parXML xml
AS
if exists(select * from sysobjects where name='wUAACUtilizatoriSP' and type='P')      
	exec wUAACUtilizatoriSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80),@codcasier varchar(10)

select @codcasier=ISNULL(@parXML.value('(/row/@codcasier)[1]', 'varchar(10)'), '') ,
       @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') 
		
set @searchText=REPLACE(@searchText, ' ', '%')

select top 100 rtrim(nume) as cod, rtrim(nume) as denumire
from utilizatori
where (ID like @searchText + '%' or nume like '%' + @searchText + '%') and (id=@codcasier or id='')
order by rtrim(ID)  
for xml raw
end
