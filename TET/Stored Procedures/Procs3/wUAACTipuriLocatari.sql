/****** Object:  StoredProcedure [dbo].[wUAACTipuriLocatari]    Script Date: 01/05/2011 23:41:36 ******/
--***
create PROCEDURE  [dbo].[wUAACTipuriLocatari] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wUAACTipuriLocatariSP' and type='P')      
	exec wUAACTipuriLocatariSP @sesiune,@parXML      
else      
begin
declare  @searchText varchar(80)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') 
		
set @searchText=REPLACE(@searchText, ' ', '%')

select top 100 rtrim(tip) as cod, rtrim(Denumire) as denumire,RTRIM(explicatii) as info
from tipLocatariUA
where tip like @searchText + '%' or denumire like '%' + @searchText + '%'
order by rtrim(tip)  
for xml raw
end
