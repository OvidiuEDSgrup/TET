/** Procedura pentru stergere cursuri pe functii **/
Create procedure wRUStergCursuriFunctii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergCursuriFunctiiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergCursuriFunctiiSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_curs_functie int, @mesajeroare varchar(500)      
begin try          
	select
		@id_curs_functie = isnull(@parXML.value('(/row/row/@id_curs_functie)[1]','int'),0)         

	delete from RU_cursuri_functii where ID_curs_functie=@id_curs_functie
end try

begin catch
	set @mesajeroare = '(wRUStergCursuriFunctii) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
