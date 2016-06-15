
create procedure wStergExceptiiSoldTert @sesiune varchar(50), @parXML XML
as

declare
	@mesaj varchar(max), @idExceptie int

begin try
	select
		@idExceptie = @parXML.value('(/row/row/@idExceptie)[1]','int')

	delete from ExceptiiSoldTert where idExceptie=@idExceptie
end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 16, 1)
end catch
