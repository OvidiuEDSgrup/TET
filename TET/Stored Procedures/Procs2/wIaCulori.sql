--***
create procedure wIaCulori @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@utilizator varchar(50), @f_culoare varchar(20),
		@f_denculoare varchar(50)
	
	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output
	
	select
		@f_culoare = isnull(@parXML.value('(/row/@f_culoare)[1]', 'varchar(20)'), ''),
		@f_denculoare = isnull(@parXML.value('(/row/@f_denculoare)[1]', 'varchar(50)'), '')

	select
		row_number() over (order by c.Cod_culoare) as nr,
		rtrim(c.Cod_culoare) as culoare,
		rtrim(c.Denumire) as denculoare
	from Culori c
	where (@f_culoare = '' or c.Cod_culoare like '%' + @f_culoare + '%')
		and (@f_denculoare = '' or c.Denumire like '%' + @f_denculoare + '%')
	order by c.Cod_culoare
	for xml raw

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
