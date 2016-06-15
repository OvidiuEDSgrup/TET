--***
/* Procedura pt. stergere calificative */
Create 
procedure wRUStergCalificative @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergCalificativeSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergCalificativeSP @sesiune, @parXML output
	return @returnValue
end
DECLARE @id_calificativ int, @mesajeroare varchar(500)      

begin try          
	select
		@id_calificativ = isnull(@parXML.value('(/row/@id_calificativ)[1]','int'),0)         

	delete from RU_calificative where ID_calificativ=@id_calificativ
end try

begin catch
	set @mesajeroare = '(wRUStergCalificative) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
