create procedure wStergUMProdus @sesiune varchar(50), @parxml xml
as
begin try	
	declare 
		@cod varchar(50),@um varchar(50)
	
	SELECT
		@cod = rtrim(@parXML.value('(/row/@cod)[1]','varchar(20)')),
		@um = rtrim(@parXML.value('(/row/row/@um)[1]','varchar(20)'))

	delete umprodus where cod=@cod and um=@um

END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
