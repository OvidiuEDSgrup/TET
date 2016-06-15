
create procedure wScriuLeaduri @sesiune varchar(50), @parXML XML
as
begin try
	declare
		@idLead int,@topic varchar(2000),@nume varchar(300),@domeniu_activitate varchar(200),@email varchar(100),@note varchar(4000),@telefon varchar(50),@denumire_firma varchar(200),@stare varchar(100),@supervizor varchar(200),
		@detalii xml, @update bit, @utilizator varchar(100)

	select
		@idLead=@parXML.value('(/*/@idLead)[1]','int'),
		@topic=@parXML.value('(/*/@topic)[1]','varchar(2000)'),
		@nume=@parXML.value('(/*/@nume)[1]','varchar(300)'),
		@domeniu_activitate=@parXML.value('(/*/@domeniu_activitate)[1]','varchar(200)'),
		@email=@parXML.value('(/*/@email)[1]','varchar(100)'),
		@note=@parXML.value('(/*/@note)[1]','varchar(4000)'),
		@telefon=@parXML.value('(/*/@telefon)[1]','varchar(50)'),
		@denumire_firma=@parXML.value('(/*/@dentert)[1]','varchar(200)'),
		@stare=@parXML.value('(/*/@stare)[1]','varchar(100)'),
		@supervizor=@parXML.value('(/*/@supervizor)[1]','varchar(200)'),
		@update=ISNULL(@parXML.value('(/*/@update)[1]','int'),0)

		if @parXML.exist('(/*/detalii)[1]')=1
			SET @detalii = @parXML.query('(/*/detalii/row)[1]')
	


	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @update=0	
		insert into Leaduri(topic, nume, domeniu_activitate, email, note, telefon, denumire_firma, data_operarii, stare, supervizor, detalii)
		select @topic,@nume,@domeniu_activitate, @email, @note, @telefon, @denumire_firma, GETDATE(),@stare, @utilizator, @detalii
	ELSE
		update Leaduri
			set topic=@topic,nume=@nume, domeniu_activitate=@domeniu_activitate, email=@email, telefon=@telefon, denumire_firma=@denumire_firma, stare=@stare, detalii=@detalii, note=@note
		where idLEad=@idLead

end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
