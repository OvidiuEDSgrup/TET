Create procedure  wScriuCodFurnizor   @sesiune varchar(30), @parXML XML
as
begin try
	
	declare 
		@cod varchar(20), @xml xml
	
	select
		@cod = upper(isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),'')),
		@xml= @parXML.query('/row/row[1]')

	set @xml.modify('insert attribute cod {sql:variable("@cod")} into (/row)[1]')

	exec wScriuFurnizoriArticol @Sesiune=@Sesiune, @parXML=@xml

end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
