--***
/** procedura pentru stergere cursuri **/
Create procedure wRUStergCursuri @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergCursuriSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergIndicatoriSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_curs int, @mesajeroare varchar(500)  
begin try          
	select
		@id_curs = isnull(@parXML.value('(/row/@id_curs)[1]','int'),0)         

	delete from RU_cursuri where ID_curs=@id_curs

end try

begin catch
	set @mesajeroare = '(wRUStergCursuri) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch