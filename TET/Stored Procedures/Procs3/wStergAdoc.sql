--***
CREATE procedure wStergAdoc @sesiune varchar(50), @parXML xml
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wStergAdocSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wStergAdocSP @sesiune, @parXML output
	return @returnValue
end
declare @subunitate char(9), @tip varchar(2), @numar varchar(8), @data datetime, @mesaj varchar(255), @eroare xml 
begin try
	select @subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), ''),
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(8)'), ''),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901')
		
	if exists (select 1 from pozadoc where subunitate = @subunitate and tip = @tip and Numar_document = @numar and data = @data )
		raiserror('Documentul are pozitii!',11,1)

	delete adoc
	where subunitate = @subunitate and tip = @tip and Numar_document = @numar and data = @data 
end try
begin catch
	set @mesaj = '(wStergAdoc)'+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
