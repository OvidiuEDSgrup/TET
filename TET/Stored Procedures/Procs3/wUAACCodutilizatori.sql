/****** Object:  StoredProcedure [dbo].[wUAACCodutilizatori]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wUAACCodutilizatori] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wUAACUtilizatoriSP' and type='P')      
	exec wUAACUtilizatoriSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') 
		
set @searchText=REPLACE(@searchText, ' ', '%')

select top 100 rtrim(ID) as cod, rtrim(id) as denumire
from utilizatori
where ID like @searchText + '%' or nume like '%' + @searchText + '%'
order by rtrim(ID)  
for xml raw
end
--select * from utilizatori
