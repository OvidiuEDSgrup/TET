--***
create procedure wScriuCulori @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@culoare varchar(20), @denculoare varchar(50), @update bit,
		@o_culoare varchar(20)

	select
		@culoare = isnull(@parXML.value('(/row/@culoare)[1]', 'varchar(20)'), ''),
		@denculoare = isnull(@parXML.value('(/row/@denculoare)[1]', 'varchar(50)'), ''),
		@update = isnull(@parXML.value('(/row/@update)[1]', 'bit'), 0),
		@o_culoare = isnull(@parXML.value('(/row/@o_culoare)[1]', 'varchar(20)'), '')

	if @culoare = '' or @denculoare = ''
		raiserror('Completati ambele campuri!', 16, 1)

	if @update = 1
	begin
		if exists (select 1 from Culori where Cod_culoare = @culoare) and (@culoare <> @o_culoare)
		begin
			raiserror('Culoarea exista deja!', 16, 1)
			return -1
		end
	end

	if @update = 0
	begin
		if exists (select 1 from Culori where Cod_culoare = @culoare)
		begin
			raiserror('Culoarea introdusa exista deja!', 16, 1)
			return -1
		end
		insert into Culori (Cod_culoare, Denumire)
		select rtrim(@culoare), rtrim(@denculoare)
	end
	else
	begin
		update Culori
		set Cod_culoare = @culoare, Denumire = @denculoare
		where Cod_culoare = @o_culoare

		/** Daca se schimba codul, (ex. din ALB in ALBA) sa faca update si la autovehiculele care au codul respectiv. */
		update [auto]
		set Culoare = @culoare
		where Culoare = @o_culoare
	end

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
