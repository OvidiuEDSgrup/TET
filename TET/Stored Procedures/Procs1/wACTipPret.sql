--***
create procedure wACTipPret @sesiune varchar(50), @parXML XML
as
	declare @searchText varchar(100)
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
	set @searchText=REPLACE(@searchText, ' ', '%')

	select top 100 
	TipPret as cod,rtrim(denumire) as denumire
	from dbo.fTipPret()
	where denumire like '%' + @searchText + '%'
	order by 1
	for xml raw
