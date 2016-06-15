create PROCEDURE [dbo].[wUAACLocalitati]  
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER  
AS  
declare @searchText varchar(100),@judet char(30)  
select @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%'),
	@judet=isnull(@parXML.value('(/row/@judet)[1]','varchar(100)'),'')
  
select top 100 rtrim(l.cod_oras) as cod,rtrim(l.oras)+' Jud '+rtrim(j.denumire) as denumire  
from localitati l
     left outer join Judete j on l.cod_judet=j.cod_judet  
where cod_oras like @searchText+'%' or oras like '%'+@searchText+'%'
and (l.cod_judet=@judet or @judet='')
order by rtrim(oras)  
for xml raw  
  
  --select * from localitati
