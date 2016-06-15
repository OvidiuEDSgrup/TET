--***
Create procedure wIaCategoriiSalarizare @sesiune varchar(50), @parXML xml
as
declare @filtruDenumire varchar(30)
set @filtruDenumire = isnull(@parXML.value('(/row/@denumire)[1]','varchar(30)'),'')

select top 100 rtrim(c.Categoria_salarizare) as categsal, rtrim(c.descriere) as descriere, convert(decimal(12,3),c.salar_orar) as salarorar, convert(decimal(12),c.salar_lunar) as salarlunar
from categs c
where rtrim(c.Descriere) like '%'+@filtruDenumire+'%' 
order by c.Categoria_salarizare, c.Descriere
for xml raw
