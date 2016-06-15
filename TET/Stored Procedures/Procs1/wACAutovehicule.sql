--***
Create procedure wACAutovehicule @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(t.Cod) as cod, 
	rTrim(t.Nr_circulatie)+' - '+rTrim(t.Marca)+' '+rTrim(t.Model) as denumire, 
	rtrim(t.Versiune)+' '+rtrim(t.Tip_motor)+' '+RTRIM(t.Putere_motor) +' '+ RTRIM(t.Cilindree)+' ' 
	as info
from auto t
where (cod like @searchText+'%' or rTrim(t.Nr_circulatie)+' - '+rTrim(t.Marca)+' '+rTrim(t.Model)
like '%'+@searchText+'%')
order by cod
for xml raw
