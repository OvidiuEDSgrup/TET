--***
create procedure wStergProprietatiTerti @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@tert varchar(20), @proprietateTert varchar(100), @valoare varchar(200)

	select
		@tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(20)'), ''),
		@proprietateTert = isnull(@parXML.value('(/*/*/@codproprietate)[1]', 'varchar(100)'), ''),
		@valoare = isnull(@parXML.value('(/*/*/@valoare)[1]', 'varchar(200)'), '')

	if @tert = ''
		raiserror('Tertul nu poate fi identificat!', 16, 1)

	delete from proprietati
	where Tip = 'TERT'
		and Cod = @tert
		and Cod_proprietate = @proprietateTert
		and Valoare = @valoare
		
end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
