--***
Create procedure wACFunctii @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wACFunctiiSP' and type='P')
	exec wACFunctiiSP @sesiune, @parXML
else      
Begin
	declare @searchText varchar(100)
	set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

	select top 100 rtrim(cod_functie) as cod, rtrim(denumire) as denumire
	from functii
	where (cod_functie like @searchText+'%' or denumire like '%'+@searchText+'%')
	order by cod_functie
	for xml raw
end
