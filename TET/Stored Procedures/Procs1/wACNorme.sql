--***
Create procedure wACNorme @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100), @codMasina varchar(20), @tipMasina varchar(20)

set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')
set @tipMasina=ISNULL(@parXML.value('(/row/@tipMasina)[1]', 'varchar(20)'), '')

select top 100 
(rtrim(e.Cod))as cod, 
(rtrim(e.Denumire)) as denumire 
              
from elemente e
inner join elemtipm et on et.Element=e.Cod
left outer join coefmasini c on e.Cod=c.Coeficient and c.Masina=@codMasina
	WHERE Tip='I' and (e.Cod like @searchText+'%' or e.Denumire like '%'+@searchtext+'%')
				  and et.Tip_masina=@tipMasina

order by cod
for xml raw
