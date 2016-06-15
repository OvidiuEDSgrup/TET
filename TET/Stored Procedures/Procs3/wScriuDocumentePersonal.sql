
create procedure wScriuDocumentePersonal @sesiune varchar(30), @parXML XML
as

declare
	@mesaj varchar(max), @idTipDocument int, @marca varchar(20), @numar varchar(100), @serie varchar(100), @data_emiterii datetime, @valabilitate datetime,
	@observatii varchar(500), @fisier varchar(255), @update bit, @idDocument int

begin try
	select
		@marca = @parXML.value('(/row/@marca)[1]','varchar(20)'),
		@idDocument = @parXML.value('(/row/row/@idDocument)[1]','int'),
		@idTipDocument = @parXML.value('(/row/row/@idTipDocument)[1]','int'),
		@numar = @parXML.value('(/row/row/@numar)[1]','varchar(100)'),
		@serie = @parXML.value('(/row/row/@serie)[1]','varchar(100)'),
		@data_emiterii = isnull(@parXML.value('(/row/row/@data_emiterii)[1]','datetime'),convert(varchar(10),getdate(),101)),
		@valabilitate = isnull(@parXML.value('(/row/row/@valabilitate)[1]','datetime'),convert(varchar(10),getdate(),101)),
		@observatii = isnull(@parXML.value('(/row/row/@observatii)[1]','varchar(500)'),''),
		@fisier = @parXML.value('(/row/row/@fisier)[1]','varchar(255)'),
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0)

	if isnull(@marca,'') = ''
		raiserror('Selectati marca pe care se adauga documentul.',16,1)

	if isnull(@idTipDocument,0) = 0
		raiserror('Completati tipul documentului.',16,1)

	if isnull(@numar,'')=''
		raiserror('Completati numarul documentului.',16,1)

	--if isnull(@serie,'')=''
	--	raiserror('Completati seria documentului.',16,1)

	if (@update=0)
	begin
		insert into DocumentePersonal(idTipDocument,marca,numar,serie,data_emiterii,valabilitate,observatii,fisier)
		select @idTipDocument,rtrim(@marca),rtrim(@numar),rtrim(@serie),@data_emiterii,@valabilitate,rtrim(@observatii),@fisier
	end
	else
	begin
		update DocumentePersonal
		set
			idTipDocument=@idTipDocument,
			numar=rtrim(@numar),
			serie=rtrim(@serie),
			data_emiterii=@data_emiterii,
			valabilitate=@valabilitate,
			observatii=rtrim(@observatii),
			fisier=(case when isnull(@fisier,'')='' then fisier else rtrim(@fisier) end)
		where idDocument=@idDocument
	end

end try


begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
