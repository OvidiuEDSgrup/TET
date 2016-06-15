--***
create procedure wScriuWebTraduceri @sesiune varchar(50), @parXML xml
as
begin try

	declare
		@utilizator varchar(20), @mesajEroare varchar(500), @Limba varchar(50),
		@Textoriginal varchar(500), @Texttradus varchar(500),
		@o_Limba varchar(50), @o_Textoriginal varchar(500), @update bit

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		@Limba = isnull(@parXML.value('(/row/@Limba)[1]', 'varchar(50)'), ''),
		@Textoriginal = isnull(@parXML.value('(/row/@Textoriginal)[1]', 'varchar(500)'), ''),
		@Texttradus = isnull(@parXML.value('(/row/@Texttradus)[1]', 'varchar(500)'), ''),
		@o_Limba = isnull(@parXML.value('(/row/@o_Limba)[1]', 'varchar(500)'), ''),
		@o_Textoriginal = isnull(@parXML.value('(/row/@o_Textoriginal)[1]', 'varchar(500)'), ''),
		@update = isnull(@parXML.value('(/row/@update)[1]', 'bit'), 0)

	if @Limba = '' or @Textoriginal = '' or @Texttradus = ''
		raiserror('Completati toate campurile!', 16, 1)
	
	if @update = 1
	begin
		if exists (select 1 from webTraduceri where Limba = @Limba and Textoriginal = @Textoriginal)
			and (@Limba <> @o_Limba or @Textoriginal <> @o_Textoriginal)
		begin
			raiserror('Limba si textul original exista deja!', 16, 1)
			return -1
		end
	end

	if @update = 0
	begin
		if exists (select 1 from webTraduceri where Limba = @Limba and Textoriginal = @Textoriginal)
		begin
			raiserror('Limba si textul original introduse exista deja!', 16, 1)
			return -1
		end
		insert into webTraduceri (Limba, Textoriginal, Texttradus)
		select @Limba, @Textoriginal, @Texttradus
	end
	else
		update webTraduceri
		set Limba = @Limba, Textoriginal = @Textoriginal, Texttradus = @Texttradus
		where Limba = @o_Limba and Textoriginal = @o_Textoriginal 

end try
begin catch
	set @mesajEroare = ERROR_MESSAGE() + ' (wScriuWebTraduceri)'
	raiserror(@mesajEroare, 16, 1)
end catch
