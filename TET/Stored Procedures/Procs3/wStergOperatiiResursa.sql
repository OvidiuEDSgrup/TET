

create procedure wStergOperatiiResursa @sesiune varchar(50), @parXML XML
as
begin try
	declare @idRes int, @codOp varchar(20), @mesaj varchar(max)
	
	set @idRes=isnull(@parXML.value('(/row/@id)[1]','int'),-1)
	set @codOp=isnull(@parXML.value('(/row/row/@cod)[1]','varchar(20)'),'')
	
	delete from OpResurse where idRes=@idRes and cod=@codOp
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+  ' (wStergPozLansari)' 
	raiserror(@mesaj, 11, 1)
end catch
