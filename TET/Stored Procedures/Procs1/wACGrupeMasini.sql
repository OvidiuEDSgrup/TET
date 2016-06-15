--***
create procedure wACGrupeMasini @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wACGrupeMasiniSP' and type='P')      
	exec wACGrupeMasiniSP @sesiune,@parXML      
else      
begin

	declare @subunitate varchar(9), @searchText varchar(80)

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
	set @searchText=REPLACE(@searchText, ' ', '%')

	select RTRIM(g.Grupa) as cod, 
	RTRIM(g.Denumire) as denumire,
	'Tip'+rtrim(g.tip_masina) as info
	from grupemasini g
		 where g.denumire like '%'+@searchText+'%'
	order by patindex('%'+@searchText+'%',g.Denumire),1
	for xml raw

end
 
