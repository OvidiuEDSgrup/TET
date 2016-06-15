
create procedure wStergTipuriDocumentePersonal @sesiune varchar(30), @parXML XML
as

declare
	@mesaj varchar(max), @idTipDocument int

begin try
	select @idTipDocument = isnull(@parXML.value('(/row/@idTipDocument)[1]','int'),0)

	delete from TipuriDocumentePersonal where idTipDocument=@idTipDocument
end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
