--***
Create procedure wACTarifeSA @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)

set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 ltrim(CONVERT(varchar(20), convert(decimal(17, 5), c.Tarif*
	(case when c.Valuta='' then 1 else isnull((select top 1 curs from curs where valuta=c.Valuta and 
	data<=getdate() order by valuta, DATA desc),0) end)))) /*(rtrim(c.cod))*/ as cod, 
	ltrim(CONVERT(varchar(20), convert(decimal(17, 5), c.Tarif*
	(case when c.Valuta='' then 1 else isnull((select top 1 curs from curs where valuta=c.Valuta and 
	data<=getdate() order by valuta, DATA desc),0) end)))) /*(rtrim(c.Denumire))*/ as denumire, 
	(rtrim(c.Cod))+' '+(rtrim(c.Denumire))/*+' '+ltrim(CONVERT(varchar(20), convert(decimal(17, 5), 
	c.Tarif)))+' '+(case when c.Valuta='' then 'RON' else c.Valuta end) */as info
from tarifemanopera c
	--inner join pozdevauto p on c.Cod=p.Cod_deviz
	--inner join devauto on devauto.Cod_deviz=p.Cod_deviz 
where (c.Denumire like '%'+@searchText+'%') 
	or (c.Cod like @searchText+'%')
order by cod

for xml raw
