CREATE procedure wScriuActivitatiCRM  @sesiune varchar(50), @parXML xml  
as 
begin try
	declare 
		@idActivitate int,@idSarcina int,@idOportunitate int,@idPotential int,@data datetime,@termen datetime,@marca varchar(20),@tip_activitate varchar(100),@note varchar(2000),@utilizator varchar(200),@detalii xml,
		@update bit
	select
		@idActivitate=@parXML.value('(//@idActivitate)[1]','int'),
		@idSarcina=@parXML.value('(/*/@idSarcina)[1]','int'),
		@idOportunitate=@parXML.value('(/*/@idOportunitate)[1]','int'),
		@idPotential=@parXML.value('(/*/@idPotential)[1]','int'),

		@update=COALESCE(@parXML.value('(/*/*/@update)[1]','int'),@parXML.value('(/*/@update)[1]','int'),0),
		
		@data=@parXML.value('(//@data)[1]','datetime'),
		@termen=@parXML.value('(//@termen)[1]','datetime'),
		@marca=@parXML.value('(//@marca)[1]','varchar(20)'),
		@tip_activitate=@parXML.value('(//@tip_activitate)[1]','varchar(100)'),
		@note=@parXML.value('(//@note)[1]','varchar(2000)')
		
		if @parXML.exist('(//detalii)[1]')=1
			SET @detalii = @parXML.query('(//detalii/row)[1]')
	

	if ISNULL(@idSarcina,0)=0 and ISNULL(@idOportunitate,0)=0 and ISNULL(@idPotential,0)=0
		raiserror('Anterior introducerii unei activitati selectati una din urmatoarele: oportunitate, sarcina sau client potential',15,1)
		
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator

	if @update=0
	begin
		insert into ActivitatiCRM( idSarcina, idOportunitate, idPotential, marca, data, termen, tip_activitate, note, utilizator, detalii)
		select @idSarcina, @idOportunitate, @idPotential,@marca, @data, @termen, @tip_activitate, @note, @utilizator, @detalii

		select @idActivitate=IDENT_CURRENT('activitatiCRM')
	end
	else
		update ActivitatiCRM
			set note=@note, utilizator=@utilizator, tip_activitate=@tip_activitate, data=@data, marca=@marca
		where idActivitate=@idActivitate

	set @parXML=(select @idSarcina idSarcina, @idPotential idPotential, @idOportunitate idOportunitate for xml raw)
	exec wIaActivitatiCRM @sesiune=@sesiune, @parXML=@parXML
	
	
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
