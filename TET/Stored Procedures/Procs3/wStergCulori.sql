--***
create procedure wStergCulori @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@culoare varchar(20)
	
	select
		@culoare = isnull(@parXML.value('(/row/@culoare)[1]', 'varchar(20)'), '')

	if @culoare = ''
		raiserror('Culoarea nu a fost identificata!', 16, 1)

	if exists (select 1 from [auto] a where a.Culoare = @culoare)
		raiserror('Culoarea este asociata autovehiculelor!', 16, 1)

	delete from Culori
	where Cod_culoare = @culoare

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
