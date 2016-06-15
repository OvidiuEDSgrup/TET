
create procedure wStergButoanePV @sesiune varchar(50), @parXML xml
as

declare
	@mesaj varchar(max), @codButon varchar(50)

begin try
	select
		@codButon = @parXML.value('(/row/@codButon)[1]','varchar(50)')

	delete from butoanePV where codButon=@codButon
end try

begin catch
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
