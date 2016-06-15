
create procedure wStergCorespondenteNomenclator @sesiune varchar(50), @parXML xml
as
begin try

	declare 
		@cod varchar(20), @codcoresp varchar(20), @mesajeroare varchar(100)
	
	select 
		@cod = upper(@parXML.value('(/row/@cod)[1]','varchar(20)')),
		@codcoresp = upper(@parXML.value('(/row/row/@codcoresp)[1]', 'varchar(20)'))

	delete from Corespondente where cod=@cod and Cod_corespondent=@codcoresp

end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
