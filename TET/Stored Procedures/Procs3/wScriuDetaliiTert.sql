create procedure wScriuDetaliiTert @sesiune varchar(50), @parXML xml
as
begin try
	declare @mesaj varchar(max), @update int

	set @update=1
	set @parXML.modify ('insert attribute update {sql:variable("@update")} into (/row)[1]')

	exec wScriuTerti @sesiune=@sesiune, @parXML=@parXML
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wScriuDetaliiTert)'
	raiserror(@mesaj, 11, 1)
end catch
