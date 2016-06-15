CREATE procedure wScriuOportunitate @sesiune varchar(50), @parXML xml  
as 

begin try
	declare 
		@idOportunitate int,@idLead int,@idPotential int,@data_inchiderii_estimata datetime,@data_operarii datetime,@vanzare_estimata float,@probabilitate float,@descriere varchar(2000),@topic varchar(200),@rating varchar(100),@valuta varchar(100),
		@stare varchar(100),@supervizor varchar(200),@detalii xml, @update bit

	select
		@idOportunitate=@parXML.value('(/*/@idOportunitate)[1]','int'),
		@idLead=@parXML.value('(/*/@idLead)[1]','int'),
		@idPotential=@parXML.value('(/*/@idPotential)[1]','int'),
		@data_inchiderii_estimata=@parXML.value('(/*/@termen)[1]','datetime'),
		@vanzare_estimata=ISNULL(@parXML.value('(/*/@vanzare_estimata)[1]','float'),0),
		@probabilitate=@parXML.value('(/*/@probabilitate)[1]','float'),
		@descriere=@parXML.value('(/*/@descriere)[1]','varchar(2000)'),
		@topic=@parXML.value('(/*/@topic)[1]','varchar(200)'),
		@rating=@parXML.value('(/*/@rating)[1]','varchar(100)'),
		@valuta=@parXML.value('(/*/@valuta)[1]','varchar(100)'),
		@stare=@parXML.value('(/*/@stare)[1]','varchar(100)'),
		@supervizor=@parXML.value('(/*/@supervizor)[1]','varchar(200)'),
		@update=ISNULL(@parXML.value('(/*/@update)[1]','BIT'),0)

		if @parXML.exist('(/*/detalii)[1]')=1
			SET @detalii = @parXML.query('(/*/detalii/row)[1]')

		select @data_operarii=getdate()
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@supervizor OUTPUT

		select @update
		if @update=0
		BEGIN
			insert into Oportunitati( idLead, idPotential, descriere, topic, data_inchiderii_estimata, vanzare_estimata, probabilitate, rating, valuta, stare, data_operarii, supervizor, detalii)
			select @idLead, @idPotential, @descriere, @topic, @data_inchiderii_estimata, @vanzare_estimata, @probabilitate, ISNULL(@rating,'C'), ISNULL(@valuta, 'RON'), ISNULL(@stare, 'D'), @data_operarii, @supervizor, @detalii

			select @idOportunitate=IDENT_CURRENT('Oportunitati')
		END
		else
			update Oportunitati
				set stare=@stare, descriere=@descriere, topic=@topic, data_inchiderii_estimata=@data_inchiderii_estimata, vanzare_estimata=@vanzare_estimata, rating=@rating
			where idOportunitate=@idOportunitate	


		set @parXML=(select @idOportunitate idOportunitate, @idLead idLead, @idPotential idPotential for xml raw)
		exec wIaOportunitati @sesiune=@sesiune, @parXML=@parXML

		select (case when @update=1 then 0 end) as 'close' for xml raw, root('Mesaje')
end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
