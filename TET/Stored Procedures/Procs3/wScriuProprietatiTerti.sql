--***
create procedure wScriuProprietatiTerti @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@tert varchar(20), @proprietateTert varchar(100),
		@valoare varchar(200), @valoare_tupla varchar(200),
		@update bit

	select
		@tert = @parXML.value('(/*/@tert)[1]', 'varchar(20)'),
		@proprietateTert = isnull(@parXML.value('(/*/*/@codproprietate)[1]', 'varchar(100)'), ''),
		@valoare = isnull(@parXML.value('(/*/*/@valoare)[1]', 'varchar(200)'), ''),
		@valoare_tupla = isnull(@parXML.value('(/*/*/@valoare_tupla)[1]', 'varchar(200)'), ''),
		@update = isnull(@parXML.value('(/*/*/@update)[1]', 'bit'), 0)

	if @update = 1
	begin
		update proprietati
		set Valoare = @valoare, Valoare_tupla = @valoare_tupla
		where tip = 'TERT' and cod = @tert and cod_proprietate = @proprietateTert
	end
	else
	begin
		insert into proprietati (tip, cod, cod_proprietate, valoare, valoare_tupla)
		select
			'TERT', @tert, @proprietateTert, @valoare, @valoare_tupla
		where not exists (select 1 from proprietati where tip = 'TERT' and cod = @tert
			and cod_proprietate = @proprietateTert and valoare = @valoare)
	end

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
