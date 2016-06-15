--***
create procedure wACTipuriMasini @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wACTipuriMasiniSP' and type='P')      
	exec wTipuriMasiniSP @sesiune,@parXML      
else      
begin

	declare @searchText varchar(80)

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
	set @searchText=REPLACE(@searchText, ' ', '%')

	select RTRIM(t.Cod) as cod,
		   RTRIM(t.Denumire) as denumire,
		   (case t.Tip_activitate when 'P' then 'Transport' when 'L' then 'Utilaj' else 'Error' end ) as info
	from tipmasini t
	where t.denumire like '%'+@searchText+'%'
	order by patindex('%'+@searchText+'%',t.Denumire),1
	for xml raw
end
