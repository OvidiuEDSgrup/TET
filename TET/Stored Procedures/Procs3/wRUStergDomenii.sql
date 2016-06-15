--***
/** procedura pentru stergere domenii **/
Create procedure wRUStergDomenii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergDomeniiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergDomeniiSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_domeniu int, @mesajeroare varchar(500) 
begin try          
	select
		@id_domeniu = isnull(@parXML.value('(/row/@id_domeniu)[1]','int'),0)         

	delete from RU_domenii where ID_domeniu=@id_domeniu
end try

begin catch
	set @mesajeroare = '(wRUStergDomenii) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch