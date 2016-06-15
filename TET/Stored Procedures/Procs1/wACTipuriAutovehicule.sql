--***
Create procedure wACTipuriAutovehicule @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)

set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 
	(rtrim(t.Cod))as cod, rtrim(t.Model)+ ' '+rtrim(t.Versiune)+' '+ rtrim(t.Marca) as denumire, 
	(rtrim(t.Tip_motor)+' '+ RTRIM(t.Putere) +' '+ RTRIM(t.Capacitate)+' '+RTRIM(t.Grupa))as info
from tipauto t
where (t.Cod like @searchText+'%' or rtrim(t.Model)+ ' '+rtrim(t.Versiune)+' '+ rtrim(t.Marca) like 
'%'+@searchText+'%')
order by cod
for xml raw
