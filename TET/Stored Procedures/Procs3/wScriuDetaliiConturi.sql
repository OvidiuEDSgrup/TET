create procedure wScriuDetaliiConturi @sesiune varchar(50), @parXML xml
as
begin try
	declare @mesaj varchar(max), @update int

	set @update=1
	set @parXML.modify ('insert attribute update {sql:variable("@update")} into (/row)[1]')

	exec wScriuConturi @sesiune=@sesiune, @parXML=@parXML
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wScriuDetaliiConturi)'
	raiserror(@mesaj, 11, 1)
end catch
