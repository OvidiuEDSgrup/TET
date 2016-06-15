--***
create procedure wACCaleFormular @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@searchText varchar(100)

	set @searchText = replace(isnull(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), '%'), ' ', '%')

	-- Tipuri obiecte ReportServer:
	-- 1 = Folder
	-- 2 = Report
	-- 3 = Resources
	-- 4 = Linked Report
	-- 5 = Data Source
	-- 6 = Report Model
	--
	-- Pentru ca autocomplete-ul sa aduca formularele propriu-zise (nu folderele) vom filtra pe tipul '2'

	select top 100
		rtrim([Path]) as cod,
		rtrim([Path]) as denumire,
		--rtrim(Name)
		'' as info
	from ReportServer.dbo.Catalog
	where [Type] = '2'
		and [Path] like '%' + @searchText + '%'
	for xml raw

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
