
create procedure wStergDocumentePersonal @sesiune varchar(30), @parXML XML
as

declare
	@mesaj varchar(max), @idDocument int

begin try
	select @idDocument = isnull(@parXML.value('(/row/row/@idDocument)[1]','int'),0)
	
	delete from DocumentePersonal where idDocument=@idDocument
end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
