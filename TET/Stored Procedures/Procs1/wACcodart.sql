--***
create procedure wACcodart @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100), @tipresursa varchar(100), @codresursa varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')
Set @tipresursa = isnull(@parXML.value('(/row/@tipresursa)[1]','varchar(100)'),'')
Set @codresursa = isnull(@parXML.value('(/row/@codresursa)[1]','varchar(100)'),'')


select top 100 
(rtrim(n.Cod_resursa))as cod, (rtrim(n.Denumire))as denumire, (rtrim(n.tip_resursa)) as info
             
from nomres n
left outer join pozart pa  on pa.Cod_resursa=n.cod_resursa
--left outer join nomres n on pa.cod_resursa=n.cod_resursa 

where (n.denumire like @searchText+'%' or n.cod_resursa like @searchText+'%')
       and n.tip_resursa=@tipresursa
order by cod
for xml raw
