-- ***

create procedure wScriuCorespondenteNomenclator   @sesiune varchar(30), @parXML XML
as
begin try
	declare 
		@update bit, @cod varchar(20), @codcoresp varchar(20), @old_cod varchar(20), @old_codcoresp varchar(20), @detalii XML,
		@mesaj varchar(500)
		
	select  
		@cod = upper(@parXML.value('(/row/@cod)[1]','varchar(20)')),
		@codcoresp = upper(@parXML.value('(/row/row/@codcoresp)[1]', 'varchar(20)')),
		@old_cod = upper(@parXML.value('(/row/@o_cod)[1]', 'varchar(20)')),
		@old_codcoresp = upper(@parXML.value('(/row/@o_codcoresp)[1]', 'varchar(20)')),
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0)
	
	if @parXML.exist('(/row/row/detalii)[1]')=1
		SET @detalii = @parXML.query('(/row/row/detalii/row)[1]')

	if @cod=@codcoresp
		raiserror('Nu se poate face asociere intre un produs si codul sau.', 11, 1)

	if @update=0 -- adaugare
	begin
		insert into Corespondente(Tip, cod, Cod_corespondent)
			values('NOMCOR', @cod, @codcoresp)
	end
	else -- modificare
		update Corespondente set Tip='NOMCOR', cod=@cod, Cod_corespondent=@codcoresp
			where cod=@cod
end try	
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
