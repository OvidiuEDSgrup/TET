--***
/** procedura pentru stergere persoane **/
Create procedure wRUStergPersoane @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUStergPersoaneSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUStergPersoaneSP @sesiune, @parXML output
	return @returnValue
end

DECLARE @id_pers int, @mesajeroare varchar(500)       
begin try              
    select
        @id_pers = @parXML.value('(/row/@id_pers)[1]','int')         

	delete from ru_persoane where ID_pers=@id_pers
end try

begin catch
	set @mesajeroare = '(wRUStergPersoane) '+ERROR_MESSAGE()
end catch
if LEN(@mesajeroare)>0
	raiserror(@mesajeroare, 11, 1)
	