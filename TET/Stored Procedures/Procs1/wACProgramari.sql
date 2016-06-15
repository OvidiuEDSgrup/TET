--***
create procedure wACProgramari @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@searchText varchar(100)

	set @searchText = replace(isnull(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), '%'), ' ', '%')

	select top 100
		rtrim(Numar_curent) as cod,
		rtrim(Descriere_problema) as denumire,
		rtrim(nr_inmatriculare_prog) + ' - ' + rtrim(nume_prog) as info 
	from Programator
	where (Numar_curent like '%' + @searchText + '%' or Descriere_problema like '%' + @searchText + '%')
		and Deviz = '' -- punem asa ca sa nu aducem programarile care au deja deviz
	order by Data desc
	for xml raw

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
