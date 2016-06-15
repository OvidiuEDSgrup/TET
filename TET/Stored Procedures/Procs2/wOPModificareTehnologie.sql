
create procedure wOPModificareTehnologie @sesiune varchar(50), @parXML xml
as

declare
	@mesaj varchar(max), @cod varchar(20), @denumire varchar(100), @o_cod_tehn varchar(20), @detalii xml

begin try
	
	select
		@cod = @parXML.value('(/*/@cod_tehn)[1]','varchar(20)'),
		@denumire = @parXML.value('(/*/@denumire)[1]','varchar(100)'),
		@o_cod_tehn = @parXML.value('(/*/@o_cod_tehn)[1]','varchar(20)')

	select @detalii =  @parXML.query('/*/detalii/row')
	
	if isnull(@cod,'')=''
		raiserror('Completati codul tehnologiei!',16,1)

	if isnull(@denumire,'')=''
		raiserror('Completati denumirea tehnologiei',16,1)
	
	update poztehnologii set cod=@cod where cod=@o_cod_tehn
	update tehnologii set cod=@cod, denumire=@denumire, detalii=@detalii where cod=@o_cod_tehn

end try

begin catch
	set @mesaj = error_message() + ' (' + object_name(@@procid) + ')'
	raiserror(@mesaj,16,1)
end catch
