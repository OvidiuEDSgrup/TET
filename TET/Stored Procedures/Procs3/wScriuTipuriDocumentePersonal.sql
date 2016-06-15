
create procedure wScriuTipuriDocumentePersonal @sesiune varchar(30), @parXML XML
as

declare
	@mesaj varchar(max), @tipdoc varchar(100), @valabilitate_standard int, @descriere varchar(300), @cod_functie varchar(20), @idTipDocument int, @update bit
	
begin try

	select
		@tipdoc = @parXML.value('(/row/@tipdoc)[1]','varchar(100)'),
		@valabilitate_standard = isnull(@parXML.value('(/row/@valabilitate_standard)[1]','int'),12),
		@descriere = isnull(@parXML.value('(/row/@descriere)[1]','varchar(300)'),''),
		@cod_functie = @parXML.value('(/row/@cod_functie)[1]','varchar(20)'),
		@idTipDocument = isnull(@parXML.value('(/row/@idTipDocument)[1]','int'),0),
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0)

	if isnull(@tipdoc,'')=''
		raiserror('Completati tipul documentului.',16,1)

	if isnull(@cod_functie,'')=''
		raiserror('Completati codul functiei.',16,1)

	if (@update=0)
	begin
		insert into TipuriDocumentePersonal(tip,valabilitate_standard,descriere,cod_functie)
		select rtrim(@tipdoc),@valabilitate_standard,rtrim(@descriere),rtrim(@cod_functie)
	end
	else
	begin
		update TipuriDocumentePersonal
		set
			tip=rtrim(@tipdoc),
			valabilitate_standard=@valabilitate_standard,
			descriere=rtrim(@descriere),
			cod_functie=rtrim(@cod_functie)
		where idTipDocument=@idTipDocument
	end

end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
