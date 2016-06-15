--***
create procedure wACTrasee @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wACTraseeSP' and type='P')      
	exec wTraseeSP @sesiune,@parXML      
else      
begin

	declare @searchText varchar(80)

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
	set @searchText=REPLACE(@searchText, ' ', '%')

	select RTRIM(t.Cod) as cod, 
	RTRIM(t.Plecare)+' - '+RTRIM(t.Sosire) as denumire,
	RTRIM(t.Via) as info
	from trasee t
		where RTRIM(t.Plecare)+' - '+RTRIM(t.Sosire) like '%'+@searchText+'%'
	order by patindex('%'+@searchText+'%',RTRIM(t.Plecare)+' - '+RTRIM(t.Sosire)),1
	for xml raw
end

