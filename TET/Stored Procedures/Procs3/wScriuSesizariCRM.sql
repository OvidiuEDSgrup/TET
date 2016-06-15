CREATE procedure wScriuSesizariCRM @sesiune varchar(50), @parXML xml  
as 
 begin try

	declare
		@idSesizare int,@idPotential int,@data datetime,@tert varchar(200),@tip_sesizare varchar(20),@descriere varchar(500),@note varchar(2000),@supervizor varchar(100),@stare varchar(200),@detalii xml,
		@update bit

	select
		@idSesizare=@parXML.value('(/*/@idSesizare)[1]','int'),
		@idPotential=@parXML.value('(/*/@idPotential)[1]','int'),
		@update=ISNULL(@parXML.value('(/*/@update)[1]','int'),0),
		@data=@parXML.value('(/*/@data)[1]','datetime'),
		@tert=@parXML.value('(/*/@tert)[1]','varchar(200)'),
		@tip_sesizare=@parXML.value('(/*/@tip_sesizare)[1]','varchar(20)'),
		@descriere=@parXML.value('(/*/@descriere)[1]','varchar(500)'),
		@note=@parXML.value('(/*/@note)[1]','varchar(2000)'),
		@stare=ISNULL(NULLIF(@parXML.value('(/*/@stare)[1]','varchar(200)'),''),'N')
		
		
		if @parXML.exist('(/*/detalii)[1]')=1
			SET @detalii = @parXML.query('(/*/detalii/row)[1]')


	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@supervizor OUTPUT
	IF @update=0
	begin
		insert into SesizariCRM(tert, idPotential, tip_sesizare, descriere, note, supervizor, data, stare, detalii)
		select  @tert, @idPotential, @tip_sesizare, @descriere, @note,@supervizor, @data,@stare, @detalii

		select @idSesizare=IDENT_CURRENT('SESIZARICRM')
	end
	else
		update SesizariCRM
			set descriere=@descriere, note=@note
		where idSesizare=@idSesizare

	set @parXML=(select @idSesizare idSesizare, @idPotential idPotential, @tert tert for xml raw)
	exec wIaSesizariCRM @sesiune=@sesiune,@parXML=@parXML

	--select 0 as 'close' for xml raw, root('Mesaje')

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
