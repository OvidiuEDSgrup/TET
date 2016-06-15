--***
Create procedure wACComponenteCheltsal @sesiune varchar(50), @parXML XML
as
	declare @datajos datetime, @datasus datetime, @searchText varchar(100)
	
	set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')
	
	select @datajos=xA.row.value('@datajos', 'datetime'), @datasus=xA.row.value('@datasus', 'datetime')
	from @parXML.nodes('row') as xA(row)

	select max(ltrim(rtrim(cont))+'|'+rtrim(ltrim(componenta))) cod, max(ltrim(Rtrim(componenta))+' ('+ltrim(rtrim(cont))+')') as denumire from cheltcomp
	where data between @datajos and @datasus
	group by cont
	union all
	select ltrim(rtrim(cont))+'|'+rtrim(ltrim(denumire_cont)) cod, ltrim(rtrim(denumire_cont))+' ('+ltrim(rtrim(cont))+')' as denumire from conturi 
	where cont in (select distinct cont_debitor from pozncon where numar like 'SAL%' and data between @datajos and @datasus)
	order by 1,2
	for xml raw
