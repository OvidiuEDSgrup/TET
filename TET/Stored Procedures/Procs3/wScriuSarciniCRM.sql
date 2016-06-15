
CREATE PROCEDURE wScriuSarciniCRM @sesiune VARCHAR(50), @parXML XML
AS
begin try
	declare
		@idSarcina int,@idSesizare int,@idPotential int,@idOportunitate int,@prioritate int,@termen datetime,@data datetime,@tip_sarcina varchar(100),@marca varchar(20),@descriere varchar(200),@utilizator varchar(100),@stare varchar(20),@detalii xml,
		@update bit

	select
		@idSarcina=@parXML.value('(/*/@idSarcina)[1]','int'),
		@idSesizare=@parXML.value('(/*/@idSesizare)[1]','int'),
		@idPotential=@parXML.value('(/*/@idPotential)[1]','int'),
		@idOportunitate=@parXML.value('(/*/@idOportunitate)[1]','int'),
		@prioritate=@parXML.value('(/*/@prioritate)[1]','int'),
		@termen=@parXML.value('(/*/@termen)[1]','datetime'),
		@data=@parXML.value('(/*/@data)[1]','datetime'),
		@tip_sarcina=@parXML.value('(/*/@tip_sarcina)[1]','varchar(100)'),
		@marca=@parXML.value('(/*/@marca)[1]','varchar(20)'),
		@descriere=@parXML.value('(/*/@descriere)[1]','varchar(200)'),
		@stare=ISNULL(NULLIF(@parXML.value('(/*/@stare)[1]','varchar(20)'),''),'N'),
		@update=ISNULL(@parXML.value('(/*/@update)[1]','bit'),0)
		
	if @parXML.exist('(/*/detalii)[1]')=1
		SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	IF ISNULL(@idOportunitate,0) <>0 OR ISNULL(@idSesizare,0)<>0
		set @idPotential = null
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @update=0
	begin
		insert into SarciniCRM (idSesizare, idPotential, idOportunitate, tip_sarcina, marca, descriere, termen, prioritate, utilizator, stare, data, detalii)
		select @idSesizare, @idPotential, @idOportunitate, @tip_sarcina, @marca, @descriere, @termen, @prioritate, @utilizator, @stare,@data, @detalii

		select @idSarcina = IDENT_CURRENT('SarciniCRM')
	end
	else 
		IF @update=0

			update SarciniCRM
				set descriere=@descriere, marca=@marca, termen=@termen, stare=@stare
					
			where idSarcina=@idSarcina

	declare @msg varchar(1000)

	IF @update=0
	BEGIN	
		select 
			@msg='S-a atribuit sarcina ' + convert(varchar(10),@idSarcina) + ' angajatului '+ rtrim(Nume) + ' !'
		from Personal where marca=@marca

		select
			@msg textMesaj, 'Notificare' titluMesaj
		for xml raw, root('Mesaje')
	END
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
