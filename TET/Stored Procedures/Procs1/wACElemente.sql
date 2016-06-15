--***
create procedure wACElemente @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wACElementeSP' and type='P')
	exec wACElementeSP @sesiune,@parXML      
else      
begin

	declare @searchText varchar(80), @tip varchar(2), @meniu varchar(2), @raport varchar(30),
			@tipElement varchar(1)

	select	@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
			@meniu=ISNULL(@parXML.value('(/row/@codMeniu)[1]', 'varchar(2)'), ''),
			@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
			@tipelement=ISNULL(@parXML.value('(/row/@tipelement)[1]', 'varchar(2)'), ''),
			@raport=ISNULL(@parXML.value('(/row/@raport)[1]', 'varchar(30)'), '')

	set @searchText=REPLACE(@searchText, ' ', '%')

	select top 100
	RTRIM(e.Cod) as cod, 
	RTRIM(e.Denumire) as denumire
	from elemente e
		where (e.Denumire like '%'+@searchText+'%' or e.Cod like @searchText+'%')
		and (@tipElement='' or e.Tip=@tipElement)
	order by patindex('%'+@searchText+'%',e.Denumire),1
	for xml raw

end
