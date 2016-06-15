/* Procedura pentru stergere descriere calificative */
Create procedure wRUStergDescriereCalificative @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergDescriereCalificativeSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergDescriereCalificativeSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_descriere int, @mesajeroare varchar(500) 
begin try          
	select 
		@id_descriere = isnull(@parXML.value('(/row/row/@id_descriere)[1]','int'),0)         
	
	delete from RU_descriere_calificative where ID_descriere=@id_descriere
end try

begin catch
	set @mesajeroare = '(wRUStergDescriereCalificative) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch