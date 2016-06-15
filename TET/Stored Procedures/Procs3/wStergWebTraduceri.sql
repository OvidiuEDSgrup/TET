--***
create procedure wStergWebTraduceri @sesiune varchar(50), @parXML xml
as
begin try

	declare
		@utilizator varchar(20), @mesajEroare varchar(500), @Limba varchar(50),
		@Textoriginal varchar(500)

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		@Limba = @parXML.value('(/row/@Limba)[1]', 'varchar(50)'),
		@Textoriginal = @parXML.value('(/row/@Textoriginal)[1]', 'varchar(500)')

	if @Limba is null or @Textoriginal is null
	begin
		raiserror('Nu s-a identificat linia!', 16, 1)
		return -1
	end

	delete from webTraduceri
	where Limba = @Limba and Textoriginal = @Textoriginal

end try
begin catch
	set @mesajEroare = ERROR_MESSAGE() + ' (wStergWebTraduceri)'
	raiserror(@mesajEroare, 16, 1)
end catch
