create procedure wScriuResurse  @sesiune varchar(50), @parXML XML  
as
begin try
	declare		
		@idRes int, @tipRes varchar(10), @descriereRes varchar(80), @codRes varchar(20),
		@update bit,@detalii xml, @mesaj varchar(500)
	
	set @idRes=ISNULL(@parXML.value('(/row/@id)[1]','int'),0)
	set @tipRes=ISNULL(@parXML.value('(/row/@tipR)[1]','varchar(10)'),'')
	set @descriereRes = ISNULL(@parXML.value('(/row/@descriere)[1]','varchar(80)'),'')
	set @codRes= ISNULL(@parXML.value('(/row/@cod)[1]','varchar(10)'),'')
	set @update =ISNULL(@parXML.value('(/row/@update)[1]','bit'),0) 
	SET @detalii = @parXML.query('(row/detalii/row)[1]')
	
	if @tipRes = '' or @codRes= ''
	begin
		raiserror('Existe elemente cu valori necompletate!',11,1)
	end
	
	if @descriereRes=''
	begin
		if @tipRes='A'
			set @descriereRes= ( select nume from personal where Marca=@codRes)
		else if @tipRes='U'
			set @descriereRes=(select denumire from masini where cod_masina=@codRes)
		else if @tipRes='L'
			set @descriereRes=(select denumire from lm where cod=@codRes)
		else if @tipRes='E'
			set @descriereRes=(select denumire from terti where tert=@codRes)
	end			
	if @update = 0
	begin
		insert into resurse (descriere,tip,cod,detalii)
				values(@descriereRes,@tipRes,@codRes,@detalii)
	end	
	else 
		if @update=1
		begin
			update resurse set descriere =@descriereRes , detalii=@detalii, cod=@codRes where id=@idRes
		end
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+  ' (wScriuResurse)'
	raiserror(@mesaj, 11, 1)
end catch
		
	
