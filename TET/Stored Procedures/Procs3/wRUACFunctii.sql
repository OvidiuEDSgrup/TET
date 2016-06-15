--***
Create procedure wRUACFunctii @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100), @id_domeniu int
select @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%'), 
	@id_domeniu=@parXML.value('(/row/linie/@id_domeniu)[1]','int')
	
select top 100 rtrim(f.cod_functie) as cod, rtrim(f.Denumire) as denumire, rtrim(d.Denumire) as info
from functii f
	left outer join proprietati p on p.tip='FUNCTII' and p.Cod_proprietate='DOMENIU' and p.Cod=f.Cod_functie
	left outer join RU_domenii d on d.ID_domeniu=p.Valoare
where (cod_functie like @searchText+'%' or f.Denumire like '%'+@searchText+'%')
	and (isnull(@id_domeniu,0)=0 or p.Valoare=@id_domeniu)
order by cod_functie
for xml raw